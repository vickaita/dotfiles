-- Tree operations for AST structures
-- Handles status propagation, pruning, and tree comparison

--- Propagate checkbox status from children to parents
--- Rules: if all children are todo -> parent is todo
---        if all children are done -> parent is done
---        otherwise (mixed) -> parent is progress
---        if no children with status -> keep original status
--- @param ast ASTNode: root node of the AST (modified in place)
--- @return ASTNode: the modified AST
function propagate_checkbox_status(ast)
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
function prune_completed_branches(ast)
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

--- Compare two ASTs and find differences
--- @param old_ast ASTNode: previous AST state
--- @param new_ast ASTNode: current AST state
--- @return table[]: array of changes with type: "added", "removed", "status_changed", "parent_activity"
function diff_trees(old_ast, new_ast)
  if not new_ast then
    return {}
  end

  local old_items = old_ast and flatten_ast(old_ast) or {}
  local new_items = flatten_ast(new_ast)

  local changes = {}

  -- Create maps for efficient lookup
  local old_map = {}
  for _, item in ipairs(old_items) do
    if item.content and item.content ~= "" then
      old_map[item.content:lower()] = item
    end
  end

  local new_map = {}
  for _, item in ipairs(new_items) do
    if item.content and item.content ~= "" then
      new_map[item.content:lower()] = item
    end
  end

  -- Find new items and status changes
  for _, new_item in ipairs(new_items) do
    if new_item.content and new_item.content ~= "" then
      local normalized_content = new_item.content:lower()
      local old_item = old_map[normalized_content]

      if not old_item then
        -- New item
        table.insert(changes, {
          content = new_item.content,
          status = new_item.status,
          indent = new_item.indent,
          line_number = new_item.line_number,
          type = "added",
          change_type = "added",
        })
      elseif old_item.status ~= new_item.status and new_item.type == "checkbox" then
        -- Status changed
        table.insert(changes, {
          content = new_item.content,
          status = new_item.status,
          prev_status = old_item.status,
          indent = new_item.indent,
          line_number = new_item.line_number,
          type = "status_changed",
          change_type = "status_changed",
        })
      end
    end
  end

  -- Find removed items
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

  -- Find all ancestor items with child activity
  local parent_activity = {}
  for _, change in ipairs(changes) do
    if change.indent > 0 then
      -- This is a child item that changed, find all its ancestors in the hierarchical parent chain
      -- An ancestor is any item that:
      -- 1. Has lower indentation than the changed item
      -- 2. Appears before the changed item in the document
      -- 3. Is in the direct hierarchical path (no sibling at same level between them)
      
      local change_line = change.line_number or 0
      for _, potential_ancestor in ipairs(new_items) do
        local ancestor_line = potential_ancestor.line_number or 0
        if potential_ancestor.indent < change.indent and 
           potential_ancestor.content and potential_ancestor.content ~= "" and
           ancestor_line < change_line then
          
          -- Check if this is a true ancestor by ensuring no sibling blocks the path
          local is_true_ancestor = true
          for _, other_item in ipairs(new_items) do
            local other_line = other_item.line_number or 0
            -- A sibling would have the same indentation level and come between ancestor and change
            if other_item.indent == potential_ancestor.indent and 
               other_line > ancestor_line and other_line < change_line then
              is_true_ancestor = false
              break
            end
          end
          
          if is_true_ancestor then
            local parent_key = potential_ancestor.content:lower()
            if not parent_activity[parent_key] then
              -- Check if this ancestor already has a change recorded
              local already_has_change = false
              for _, existing_change in ipairs(changes) do
                if existing_change.content:lower() == parent_key then
                  already_has_change = true
                  break
                end
              end

              if not already_has_change then
                parent_activity[parent_key] = {
                  content = potential_ancestor.content,
                  status = potential_ancestor.status,
                  indent = potential_ancestor.indent,
                  line_number = potential_ancestor.line_number,
                  type = "parent_activity",
                  change_type = "child_activity",
                }
              end
            end
          end
        end
      end
    end
  end

  -- Add parent activity changes
  for _, activity in pairs(parent_activity) do
    table.insert(changes, activity)
  end

  -- Sort changes to maintain document order and hierarchical structure
  table.sort(changes, function(a, b)
    -- First sort by line number to maintain document order
    local line_a = a.line_number or 0
    local line_b = b.line_number or 0
    
    if line_a ~= line_b then
      return line_a < line_b
    end
    
    -- For items at the same line (ancestors/descendants), sort by indent (shallowest first)
    return a.indent < b.indent
  end)
  
  -- Debug output (temporary)
  if vim.g.debug_compare_daily then
    print("=== DEBUG: Changes after sorting ===")
    for i, change in ipairs(changes) do
      print(string.format("%2d: '%s' (indent=%d, line=%s, type=%s)", 
        i, change.content, change.indent, 
        tostring(change.line_number), change.change_type))
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

