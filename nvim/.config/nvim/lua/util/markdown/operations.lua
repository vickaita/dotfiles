-- Tree operations for AST structures
-- Handles status propagation, pruning, and tree comparison

--- Propagate checkbox status from children to parents
--- Rules: if all children are todo -> parent is todo
---        if all children are done -> parent is done
---        otherwise (mixed) -> parent is progress
---        if no children with status -> keep original status
--- @param ast ASTNode: root node of the AST (modified in place)
--- @return ASTNode: the modified AST
local function propagate_checkbox_status(ast)
  if not ast then
    return ast
  end

  --- Recursively compute and set new status for a node
  --- @param node ASTNode: the node to process
  --- @return string|nil: the computed status
  local function compute_status(node)
    if node.type ~= "checkbox" then
      -- Process children but don't change this node's status
      for _, child in ipairs(node.children) do
        compute_status(child)
      end
      return nil
    end

    -- If we already computed this node's status, return it
    if node.new_status then
      return node.new_status
    end

    local status_counts = { todo = 0, progress = 0, done = 0 }
    local children_with_status = 0

    -- Recursively compute children's status first
    for _, child in ipairs(node.children) do
      local child_status = compute_status(child)
      if child_status then
        children_with_status = children_with_status + 1
        status_counts[child_status] = status_counts[child_status] + 1
      end
    end

    -- Determine new status based on children
    if children_with_status > 0 then
      if status_counts.todo > 0 and status_counts.progress == 0 and status_counts.done == 0 then
        node.new_status = "todo"
      elseif status_counts.done > 0 and status_counts.progress == 0 and status_counts.todo == 0 then
        node.new_status = "done"
      else
        node.new_status = "progress"
      end
    else
      -- No children with status, keep original
      node.new_status = node.status
    end

    return node.new_status
  end

  -- Compute status for all nodes
  compute_status(ast)

  -- Apply the new status to all checkbox nodes
  local function apply_new_status(node)
    if node.type == "checkbox" and node.new_status then
      node.status = node.new_status
      node.new_status = nil -- Clear temporary field
    end

    for _, child in ipairs(node.children) do
      apply_new_status(child)
    end
  end

  apply_new_status(ast)
  return ast
end

--- Check if a node has any incomplete descendants (todo or progress)
--- @param node ASTNode: the node to check
--- @return boolean: true if any descendant is incomplete
local function has_incomplete_descendants(node)
  for _, child in ipairs(node.children) do
    if child.type == "checkbox" and (child.status == "todo" or child.status == "progress") then
      return true
    end
    if has_incomplete_descendants(child) then
      return true
    end
  end
  return false
end

--- Remove completed subtrees that have no incomplete descendants
--- A completed item is removed if:
--- 1. It has no incomplete descendants (todo/progress children)
--- 2. It's either top-level or its parent is also completed
--- If a completed item has incomplete descendants, it's converted to progress
--- @param ast ASTNode: root node of the AST (modified in place)
--- @return ASTNode: the modified AST
local function prune_completed_branches(ast)
  if not ast then
    return ast
  end

  --- Recursively process and prune nodes
  --- @param node ASTNode: current node to process
  --- @return boolean: true if this node should be kept
  local function should_keep_node(node)
    if node.type ~= "checkbox" then
      -- For non-checkbox nodes, process children and keep the node
      local children_to_keep = {}
      for _, child in ipairs(node.children) do
        if should_keep_node(child) then
          table.insert(children_to_keep, child)
        end
      end
      node.children = children_to_keep
      return true
    end

    -- For checkbox nodes
    if node.status ~= "done" then
      -- Not completed, process children and keep
      local children_to_keep = {}
      for _, child in ipairs(node.children) do
        if should_keep_node(child) then
          table.insert(children_to_keep, child)
        end
      end
      node.children = children_to_keep
      return true
    end

    -- This is a completed checkbox
    local has_incomplete = has_incomplete_descendants(node)

    if has_incomplete then
      -- Has incomplete descendants, convert to progress and keep
      node.status = "progress"
      local children_to_keep = {}
      for _, child in ipairs(node.children) do
        if should_keep_node(child) then
          table.insert(children_to_keep, child)
        end
      end
      node.children = children_to_keep
      return true
    end

    -- No incomplete descendants, check if we should remove
    local parent_completed = node.parent and node.parent.type == "checkbox" and node.parent.status == "done"
    local is_top_level = not node.parent or node.parent.type == "root"

    if is_top_level or parent_completed then
      -- Remove this entire subtree
      return false
    else
      -- Parent exists and is not completed, keep this node but process children
      local children_to_keep = {}
      for _, child in ipairs(node.children) do
        if should_keep_node(child) then
          table.insert(children_to_keep, child)
        end
      end
      node.children = children_to_keep
      return true
    end
  end

  -- Process all children of root
  local children_to_keep = {}
  for _, child in ipairs(ast.children) do
    if should_keep_node(child) then
      table.insert(children_to_keep, child)
    end
  end
  ast.children = children_to_keep

  return ast
end

--- Flatten an AST into a list of items for comparison
--- @param ast ASTNode: root node of the AST
--- @return table[]: array of flattened items with {content, status, indent, type}
local function flatten_ast(ast)
  local items = {}

  local function flatten_recursive(node)
    if node.type == "checkbox" or node.type == "list" then
      table.insert(items, {
        content = node.content,
        status = node.status,
        indent = node.indent,
        type = node.type,
        line_number = node.line_number,
      })
    end

    for _, child in ipairs(node.children) do
      flatten_recursive(child)
    end
  end

  flatten_recursive(ast)
  return items
end

--- Compare two ASTs and find differences using tree walking
--- @param old_ast ASTNode: previous AST state
--- @param new_ast ASTNode: current AST state
--- @return table[]: array of changes in hierarchical order
local function diff_trees(old_ast, new_ast)
  if not new_ast then
    return {}
  end

  -- Create lookup maps for efficient comparison
  local old_map = {}
  if old_ast then
    local old_items = flatten_ast(old_ast)
    for _, item in ipairs(old_items) do
      if item.content and item.content ~= "" then
        old_map[item.content:lower()] = item
      end
    end
  end

  local changes = {}

  -- First pass: determine which nodes have changes
  local node_changes = {}

  local function analyze_tree(node)
    local node_has_direct_changes = false
    local change_info = nil

    -- Check if this node itself has direct changes (only for list items)
    if (node.type == "checkbox" or node.type == "list") and node.content and node.content ~= "" then
      local normalized_content = node.content:lower()
      local old_item = old_map[normalized_content]

      if not old_item then
        -- New item
        change_info = {
          content = node.content,
          status = node.status,
          indent = node.indent,
          line_number = node.line_number,
          type = "added",
          change_type = "added",
        }
        node_has_direct_changes = true
      elseif old_item.status ~= node.status and node.type == "checkbox" then
        -- Status changed
        change_info = {
          content = node.content,
          status = node.status,
          prev_status = old_item.status,
          indent = node.indent,
          line_number = node.line_number,
          type = "status_changed",
          change_type = "status_changed",
        }
        node_has_direct_changes = true
      end
    end

    -- Recursively analyze children
    local any_child_changed = false
    for _, child in ipairs(node.children) do
      local child_changed = analyze_tree(child)
      if child_changed then
        any_child_changed = true
      end
    end

    -- Store change info for this node
    if node_has_direct_changes then
      node_changes[node] = change_info
    elseif
      any_child_changed
      and (node.type == "checkbox" or node.type == "list")
      and node.content
      and node.content ~= ""
    then
      node_changes[node] = {
        content = node.content,
        status = node.status,
        indent = node.indent,
        line_number = node.line_number,
        type = "parent_activity",
        change_type = "child_activity",
      }
    end

    return node_has_direct_changes or any_child_changed
  end

  -- Second pass: collect changes in pre-order traversal (parent before children)
  local function collect_changes(node)
    -- Add this node's change if it has one
    if node_changes[node] then
      table.insert(changes, node_changes[node])
    end

    -- Recursively collect children's changes
    for _, child in ipairs(node.children) do
      collect_changes(child)
    end
  end

  -- Run both passes
  analyze_tree(new_ast)
  collect_changes(new_ast)

  -- Find removed items (items that exist in old but not in new)
  if old_ast then
    local new_map = {}
    local new_items = flatten_ast(new_ast)
    for _, item in ipairs(new_items) do
      if item.content and item.content ~= "" then
        new_map[item.content:lower()] = item
      end
    end

    local old_items = flatten_ast(old_ast)
    for _, old_item in ipairs(old_items) do
      if old_item.content and old_item.content ~= "" then
        local normalized_content = old_item.content:lower()
        if not new_map[normalized_content] then
          table.insert(changes, {
            content = old_item.content,
            status = old_item.status,
            indent = old_item.indent,
            line_number = old_item.line_number,
            type = "removed",
            change_type = "removed",
          })
        end
      end
    end
  end

  return changes
end

-- Export public functions
local M = {}

M.propagate_checkbox_status = propagate_checkbox_status
M.prune_completed_branches = prune_completed_branches
M.diff_trees = diff_trees

return M
