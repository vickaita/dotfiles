-- AST Core functionality for markdown list processing
-- Handles parsing, building, and rendering of markdown list ASTs

local config = require("util.markdown.config").config

--- AST Node Structure and Constructors
---
--- AST node represents a single list item in the markdown document
--- @class ASTNode
--- @field type string: "checkbox" | "list" | "root"
--- @field content string: the text content after the list marker
--- @field status string|nil: "todo" | "progress" | "done" (only for checkbox items)
--- @field indent number: indentation level in spaces
--- @field list_type string: "unordered" | "ordered"
--- @field marker string: the actual list marker used ("*", "-", "+", "1.", "2.", etc.)
--- @field children ASTNode[]: array of child nodes
--- @field parent ASTNode|nil: reference to parent node
--- @field line_number number: original line number in source
--- @field raw_line string: the original full line content

--- Create a new AST node
--- @param node_type string: "checkbox" | "list" | "root"
--- @param content string: text content
--- @param opts table|nil: optional parameters
--- @return ASTNode
local function create_ast_node(node_type, content, opts)
  opts = opts or {}
  return {
    type = node_type,
    content = content or "",
    status = opts.status,
    indent = opts.indent or 0,
    list_type = opts.list_type or "unordered",
    marker = opts.marker or "-",
    children = {},
    parent = nil,
    line_number = opts.line_number or 0,
    raw_line = opts.raw_line or "",
  }
end

--- Create a checkbox AST node
--- @param content string: text content after the checkbox
--- @param status string: "todo" | "progress" | "done"
--- @param opts table|nil: optional parameters
--- @return ASTNode
local function create_checkbox_node(content, status, opts)
  opts = opts or {}
  opts.status = status
  return create_ast_node("checkbox", content, opts)
end

--- Create a regular list AST node
--- @param content string: text content after the list marker
--- @param opts table|nil: optional parameters
--- @return ASTNode
local function create_list_node(content, opts)
  return create_ast_node("list", content, opts)
end

--- Create a root AST node (container for the entire tree)
--- @return ASTNode
local function create_root_node()
  return create_ast_node("root", "")
end

--- Add a child node to a parent, setting up the parent-child relationship
--- @param parent ASTNode
--- @param child ASTNode
local function add_child(parent, child)
  table.insert(parent.children, child)
  child.parent = parent
end

--- Validate input parameters
--- @param lines string[]|nil
--- @param buffer_id number|nil
--- @return boolean, string|nil
local function validate_input(lines, buffer_id)
  if lines and type(lines) ~= "table" then
    return false, "Lines must be a table"
  end
  if buffer_id and type(buffer_id) ~= "number" then
    return false, "Buffer ID must be a number"
  end
  return true
end

--- Extract full content from a range of lines for a list item
--- @param lines string[]: all document lines
--- @param start_line number: starting line (1-based)
--- @param end_line number: ending line (1-based)
--- @param base_indent number: base indentation of the list item
--- @return string: complete content including continuation lines
local function extract_full_content(lines, start_line, end_line, base_indent)
  if not lines or start_line > end_line then
    return ""
  end

  local content_parts = {}
  local first_line = lines[start_line] or ""

  -- Extract content from first line (after the list marker and checkbox)
  local first_content = first_line:match("^%s*[%-%*%+]%s+%[.%]%s*(.*)")
    or first_line:match("^%s*%d+%.%s+%[.%]%s*(.*)")
    or first_line:match("^%s*[%-%*%+]%s+(.*)")
    or first_line:match("^%s*%d+%.%s+(.*)")
    or ""

  table.insert(content_parts, first_content)

  -- Extract continuation lines
  for i = start_line + 1, end_line do
    local line = lines[i] or ""
    if line:match("%S") then -- Non-empty line
      local line_indent = #(line:match("^(%s*)") or "")
      if line_indent > base_indent then
        -- Check if this is another list item (even if it's indented more)
        local is_list_item = line:match("^%s*[%-%*%+]%s+") or line:match("^%s*%d+%.%s+")
        if not is_list_item then
          -- This is a continuation line, add it preserving relative indentation
          local continuation = line:match("^%s*(.*)")
          if continuation and continuation ~= "" then
            table.insert(content_parts, continuation)
          end
        else
          -- This is a child list item, stop collecting continuation lines
          break
        end
      else
        -- Content at same or lower indentation, stop
        break
      end
    end
  end

  return table.concat(content_parts, "\n")
end

--- Parse a single line to extract list information
--- @param line string: the line to parse
--- @param line_number number: line number for reference
--- @return table|nil: parsed line info or nil if not a list item
local function parse_line_info(line, line_number)
  if not line or type(line) ~= "string" then
    return nil
  end

  local indent = #(line:match("^(%s*)") or "")

  -- Try to match unordered list with checkbox
  local bullet_marker, checkbox, content = line:match("^(%s*[%-%*%+])%s+%[(.?)%]%s*(.*)")
  if bullet_marker and checkbox then
    local status = nil
    if checkbox == "x" or checkbox == "X" then
      status = "done"
    elseif checkbox == "-" then
      status = "progress"
    elseif checkbox == " " then
      status = "todo"
    end

    if status then
      return {
        type = "checkbox",
        content = content,
        status = status,
        indent = indent,
        list_type = "unordered",
        marker = bullet_marker:match("[%-%*%+]"),
        line_number = line_number,
        raw_line = line,
      }
    end
  end

  -- Try to match numbered list with checkbox
  local numbered_marker, checkbox2, content2 = line:match("^(%s*%d+%.)%s+%[(.?)%]%s*(.*)")
  if numbered_marker and checkbox2 then
    local status = nil
    if checkbox2 == "x" or checkbox2 == "X" then
      status = "done"
    elseif checkbox2 == "-" then
      status = "progress"
    elseif checkbox2 == " " then
      status = "todo"
    end

    if status then
      return {
        type = "checkbox",
        content = content2,
        status = status,
        indent = indent,
        list_type = "ordered",
        marker = numbered_marker:match("%d+%."),
        line_number = line_number,
        raw_line = line,
      }
    end
  end

  -- Try to match unordered list without checkbox
  local bullet_marker2, content3 = line:match("^(%s*[%-%*%+])%s+(.*)")
  if bullet_marker2 then
    return {
      type = "list",
      content = content3,
      status = nil,
      indent = indent,
      list_type = "unordered",
      marker = bullet_marker2:match("[%-%*%+]"),
      line_number = line_number,
      raw_line = line,
    }
  end

  -- Try to match numbered list without checkbox
  local numbered_marker2, content4 = line:match("^(%s*%d+%.)%s+(.*)")
  if numbered_marker2 then
    return {
      type = "list",
      content = content4,
      status = nil,
      indent = indent,
      list_type = "ordered",
      marker = numbered_marker2:match("%d+%."),
      line_number = line_number,
      raw_line = line,
    }
  end

  return nil
end

--- Build parent-child relationships in AST from flat list of nodes
--- @param nodes ASTNode[]: flat array of AST nodes
--- @return ASTNode: root node with children properly nested
local function build_ast_tree(nodes)
  if not nodes or #nodes == 0 then
    return create_root_node()
  end

  local root = create_root_node()
  local stack = { root }

  for _, node in ipairs(nodes) do
    -- Pop stack until we find appropriate parent
    while #stack > 1 do
      local top = stack[#stack]
      if top.indent < node.indent then
        break -- Found parent
      end
      table.remove(stack)
    end

    -- Add to current parent
    local parent = stack[#stack]
    add_child(parent, node)
    table.insert(stack, node)
  end

  return root
end

--- Parse markdown lines into an AST structure
--- Tries Tree-sitter first, falls back to line-by-line parsing
--- @param lines string[]: array of lines to parse
--- @param buffer_id number|nil: buffer ID for Tree-sitter parsing
--- @return ASTNode: root node of the AST
function parse_to_ast(lines, buffer_id)
  local valid, err = validate_input(lines, buffer_id)
  if not valid then
    vim.notify("Invalid input: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return create_root_node()
  end

  if not lines or #lines == 0 then
    return create_root_node()
  end

  buffer_id = buffer_id or 0
  local nodes = {}

  -- Try Tree-sitter first
  local ok_ts = pcall(require, "vim.treesitter")
  if ok_ts then
    local parser_ok, parser = pcall(vim.treesitter.get_parser, buffer_id, "markdown")
    if parser_ok and parser then
      local tree = parser:parse()[1]
      if tree then
        local root = tree:root()
        local query = vim.treesitter.query.parse("markdown", "(list_item) @item")
        local ts_items = {}

        for id, node in query:iter_captures(root, buffer_id, 0, -1) do
          if query.captures[id] == "item" then
            local sr, _, er, _ = node:range()
            local line = lines[sr + 1] or ""
            local line_info = parse_line_info(line, sr + 1)
            if line_info then
              -- Extract full multi-line content using the Tree-sitter range
              local base_indent = line_info.indent
              local full_content = extract_full_content(lines, sr + 1, er, base_indent)
              line_info.content = full_content -- Override with complete content

              table.insert(ts_items, {
                sr = sr,
                er = er,
                info = line_info,
              })
            end
          end
        end

        table.sort(ts_items, function(a, b)
          return a.sr < b.sr
        end)

        -- Convert Tree-sitter items to AST nodes
        for _, item in ipairs(ts_items) do
          local ast_node = create_ast_node(item.info.type, item.info.content, item.info)
          table.insert(nodes, ast_node)
        end

        -- Tree-sitter ranges can be unreliable, so we'll still fall back to line parsing
        -- but only if we didn't get reasonable results
        if #nodes > 0 then
          return build_ast_tree(nodes)
        end
      end
    end
  end

  -- Fallback: line-by-line parsing with multi-line content detection
  local i = 1
  while i <= #lines do
    local line = lines[i]
    local line_info = parse_line_info(line, i)
    if line_info then
      -- Find the end of this list item by looking for continuation lines
      local end_line = i
      local base_indent = line_info.indent

      -- Look ahead for continuation lines
      for j = i + 1, #lines do
        local next_line = lines[j]
        if not next_line or next_line:match("^%s*$") then
          -- Empty line, might continue
          goto continue_search
        end

        local next_line_info = parse_line_info(next_line, j)
        if next_line_info then
          -- This is another list item, stop here
          break
        end

        local next_indent = #(next_line:match("^(%s*)") or "")
        if next_indent > base_indent then
          -- This is a continuation line
          end_line = j
        else
          -- Content at same or lower indentation, stop
          break
        end

        ::continue_search::
      end

      -- Extract full content including continuation lines
      local full_content = extract_full_content(lines, i, end_line, base_indent)
      line_info.content = full_content

      local ast_node = create_ast_node(line_info.type, line_info.content, line_info)
      table.insert(nodes, ast_node)

      i = end_line + 1 -- Skip the lines we've processed
    else
      i = i + 1
    end
  end

  return build_ast_tree(nodes)
end

--- Render an AST node to markdown lines (can be multiple lines for multi-line content)
--- @param node ASTNode: the node to render
--- @return string[]: array of rendered markdown lines
local function render_ast_node(node)
  if node.type == "root" then
    return {}
  end

  local indent_str = string.rep(" ", node.indent)
  local marker = node.marker or "-"
  local content_lines = {}

  -- Split content by newlines if it's multi-line
  local content_parts = {}
  if node.content and node.content ~= "" then
    for line in node.content:gmatch("[^\n]+") do
      table.insert(content_parts, line)
    end
  end

  if node.type == "checkbox" then
    local checkbox_symbol = config.symbols.todo -- default
    if node.status == "done" then
      checkbox_symbol = config.symbols.done
    elseif node.status == "progress" then
      checkbox_symbol = config.symbols.progress
    end

    -- First line with list marker and checkbox
    local first_content = content_parts[1] or ""
    table.insert(content_lines, indent_str .. marker .. " " .. checkbox_symbol .. " " .. first_content)

    -- Continuation lines with increased indentation
    for i = 2, #content_parts do
      table.insert(content_lines, indent_str .. "      " .. content_parts[i])
    end
  elseif node.type == "list" then
    -- First line with list marker
    local first_content = content_parts[1] or ""
    table.insert(content_lines, indent_str .. marker .. " " .. first_content)

    -- Continuation lines with increased indentation
    for i = 2, #content_parts do
      table.insert(content_lines, indent_str .. "  " .. content_parts[i])
    end
  end

  return content_lines
end

--- Render an AST tree to markdown lines recursively
--- @param node ASTNode: the node to render
--- @param lines string[]: accumulator for rendered lines
local function render_ast_recursive(node, lines)
  if node.type ~= "root" then
    local node_lines = render_ast_node(node)
    for _, line in ipairs(node_lines) do
      if line and line ~= "" then
        table.insert(lines, line)
      end
    end
  end

  -- Render children
  for _, child in ipairs(node.children) do
    render_ast_recursive(child, lines)
  end
end

--- Convert an AST back to markdown lines
--- @param ast ASTNode: root node of the AST
--- @return string[]: array of markdown lines
function ast_to_lines(ast)
  if not ast then
    return {}
  end

  local lines = {}
  render_ast_recursive(ast, lines)
  return lines
end

--- Test round-trip conversion: lines -> AST -> lines
--- @param lines string[]: input lines
--- @param buffer_id number|nil: buffer ID for Tree-sitter parsing
--- @return boolean, string[]: success status and output lines
local function test_round_trip(lines, buffer_id)
  local ast = parse_to_ast(lines, buffer_id)
  local output_lines = ast_to_lines(ast)

  -- For debugging, we could compare line by line
  local success = true
  local differences = {}

  if #lines ~= #output_lines then
    success = false
    table.insert(differences, string.format("Line count mismatch: input=%d, output=%d", #lines, #output_lines))
  end

  local max_lines = math.max(#lines, #output_lines)
  for i = 1, max_lines do
    local input_line = lines[i] or ""
    local output_line = output_lines[i] or ""

    -- Only compare list items, skip non-list lines
    if parse_line_info(input_line, i) then
      if input_line ~= output_line then
        success = false
        table.insert(differences, string.format("Line %d: '%s' -> '%s'", i, input_line, output_line))
      end
    end
  end

  if not success then
    vim.notify("Round-trip test failed:\n" .. table.concat(differences, "\n"), vim.log.levels.WARN)
  end

  return success, output_lines
end

-- Export public functions
local M = {}

M.parse_to_ast = parse_to_ast
M.ast_to_lines = ast_to_lines
M.test_round_trip = test_round_trip
M.parse_line_info = parse_line_info
M.create_ast_node = create_ast_node
M.create_checkbox_node = create_checkbox_node
M.create_list_node = create_list_node
M.create_root_node = create_root_node
M.add_child = add_child

return M
