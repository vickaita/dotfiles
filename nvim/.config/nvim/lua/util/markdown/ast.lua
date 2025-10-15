-- AST Core functionality for markdown list processing
-- Handles parsing, building, and rendering of markdown list ASTs

local config = require("util.markdown.config").config

local parse_line_info

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
    indent_string = opts.indent_string or string.rep(" ", opts.indent or 0),
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
--- @param text string
--- @return string
local function lstrip(text)
  if not text or text == "" then
    return text or ""
  end
  local first_non_space = text:match("^%s*()") or 1
  return text:sub(first_non_space)
end

--- Get leading whitespace for a line
--- @param line string
--- @return string
local function get_indent_string(line)
  if not line then
    return ""
  end
  return line:match("^(%s*)") or ""
end

--- Strip list markers and optional checkbox from the first line content
--- @param line string
--- @return string
local function strip_marker_from_line(line)
  if not line or line == "" then
    return ""
  end

  local result = line
  -- Unordered with checkbox
  result = result:gsub("^%s*[%-%*%+]%s+%[.%]%s*", "", 1)
  -- Ordered with checkbox
  result = result:gsub("^%s*%d+[%.)]%s+%[.%]%s*", "", 1)
  -- Unordered without checkbox
  result = result:gsub("^%s*[%-%*%+]%s+", "", 1)
  -- Ordered without checkbox
  result = result:gsub("^%s*%d+[%.)]%s+", "", 1)

  return lstrip(result)
end

--- Combine first line content and continuation lines into a single string
--- First line is expected to be stripped of markers already,
--- continuation lines are included verbatim to preserve formatting.
--- @param lines string[]
--- @param start_line number
--- @param end_line number
--- @param first_line_content string
--- @return string
local function build_content_value(lines, start_line, end_line, first_line_content)
  local parts = {}
  table.insert(parts, first_line_content or "")

  if lines and end_line and end_line > start_line then
    for idx = start_line + 1, end_line do
      table.insert(parts, lines[idx] or "")
    end
  end

  return table.concat(parts, "\n")
end

--- Determine the last line (inclusive) that belongs to a list item for fallback parsing
--- Uses indentation heuristics similar to the previous implementation while preserving blank lines.
--- @param lines string[]
--- @param start_line number
--- @param base_indent number
--- @param stop_lines table<number, boolean>|nil
--- @return number
local function find_fallback_content_end(lines, start_line, base_indent, stop_lines)
  local end_line = start_line
  if not lines then
    return end_line
  end

  for j = start_line + 1, #lines do
    local current = lines[j]
    if not current then
      break
    end

    if stop_lines and stop_lines[j] then
      break
    end

    local handled = false

    local next_info = parse_line_info(current, j)
    if next_info then
      if not stop_lines then
        break
      end

      if stop_lines[j] then
        break
      end

      if next_info.indent <= base_indent then
        break
      else
        end_line = j
        handled = true
      end
    end

    if not handled then
      if current:match("^%s*$") then
        -- Blank line: include and continue scanning
        end_line = j
      else
        local current_indent = #(current:match("^(%s*)") or "")
        if current_indent > base_indent then
          end_line = j
        else
          break
        end
      end
    end
  end

  return end_line
end

--- Parse a single line to extract list information
--- @param line string: the line to parse
--- @param line_number number: line number for reference
--- @return table|nil: parsed line info or nil if not a list item
parse_line_info = function(line, line_number)
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

--- Attempt to parse markdown using Tree-sitter and build an AST
--- @param lines string[]|nil
--- @param buffer_id number|nil
--- @return ASTNode|nil, number -- AST root (or nil) and number of list items discovered
local function parse_with_treesitter(lines, buffer_id)
  local ok_ts, ts = pcall(require, "vim.treesitter")
  if not ok_ts then
    return nil, 0
  end

  buffer_id = buffer_id or 0

  local parser
  local source_for_text

  if buffer_id ~= 0 then
    local parser_ok, parsed = pcall(ts.get_parser, buffer_id, "markdown")
    if parser_ok and parsed then
      parser = parsed
      if not lines or #lines == 0 then
        local ok_lines, buf_lines = pcall(vim.api.nvim_buf_get_lines, buffer_id, 0, -1, false)
        if ok_lines then
          lines = buf_lines
        end
      end
      source_for_text = buffer_id
    end
  end

  if not parser then
    if not lines then
      return nil, 0
    end
    local text = table.concat(lines, "\n")
    local parser_ok, parsed = pcall(ts.get_string_parser, text, "markdown")
    if not parser_ok or not parsed then
      return nil, 0
    end
    parser = parsed
    source_for_text = text
  end

  local ok_parse, trees = pcall(function()
    return parser:parse()
  end)
  if not ok_parse or not trees or not trees[1] then
    return nil, 0
  end

  local tree = trees[1]
  local root = tree and tree:root()
  if not root then
    return nil, 0
  end

  if not lines and type(source_for_text) == "string" then
    lines = vim.split(source_for_text, "\n", { plain = true, trimempty = false })
  end
  lines = lines or {}

  local ast_root = create_root_node()
  local created_nodes = 0

  local function determine_status(marker_text)
    if not marker_text then
      return nil
    end
    if marker_text:match("%[[xX]%]") then
      return "done"
    elseif marker_text:match("%[%-%]") then
      return "progress"
    elseif marker_text:match("%[%s*%]") then
      return "todo"
    end
    return nil
  end

  local function make_list_item_node(ts_node)
    if not ts_node then
      return nil
    end

    local sr = ts_node:range()
    local start_line = sr + 1
    local raw_line = lines[start_line] or ""
    local line_info = parse_line_info(raw_line, start_line)

    local indent_string = line_info and line_info.indent_string or get_indent_string(raw_line)
    local indent = line_info and line_info.indent or #indent_string
    local list_type = line_info and line_info.list_type or "unordered"
    local marker = line_info and line_info.marker or "-"
    local status = line_info and line_info.status

    local marker_text
    local nested_start_lines = nil

    for child in ts_node:iter_children() do
      local child_type = child:type()
      if not marker_text and child_type:match("^list_marker") then
        marker_text = vim.treesitter.get_node_text(child, source_for_text) or ""
        marker_text = marker_text:gsub("%s+$", "")
      elseif child_type:match("^task_list_marker") then
        if not status then
          local marker_status = determine_status(vim.treesitter.get_node_text(child, source_for_text) or "")
          if marker_status then
            status = marker_status
          end
        end
      elseif child_type == "list" then
        local child_sr = child:range()
        nested_start_lines = nested_start_lines or {}
        nested_start_lines[child_sr + 1] = true
      end
    end

    if marker_text and (not line_info or not line_info.marker) then
      local numeric = marker_text:match("^(%d+)([%.%)])?")
      if numeric then
        list_type = "ordered"
        local suffix = marker_text:match("%d+([%.%)])")
        marker = numeric .. (suffix or ".")
      else
        local bullet = marker_text:match("[%-%*%+]")
        if bullet then
          marker = bullet
        end
        list_type = "unordered"
      end
    end

    local node_type = (status and "checkbox") or (line_info and line_info.type) or "list"

    local content_end_line = find_fallback_content_end(lines, start_line, indent, nested_start_lines)

    local first_content = (line_info and line_info.content) or strip_marker_from_line(raw_line)
    local content = build_content_value(lines, start_line, content_end_line, first_content)

    local ast_node = create_ast_node(node_type, content, {
      status = status,
      indent = indent,
      indent_string = indent_string,
      list_type = list_type,
      marker = marker,
      line_number = start_line,
      raw_line = raw_line,
    })

    created_nodes = created_nodes + 1
    return ast_node
  end

  local function process_nested_lists(ts_item, parent_ast)
    for child in ts_item:iter_children() do
      if child:type() == "list" then
        for nested_item in child:iter_children() do
          if nested_item:type() == "list_item" then
            local nested_ast = make_list_item_node(nested_item)
            if nested_ast then
              add_child(parent_ast, nested_ast)
              process_nested_lists(nested_item, nested_ast)
            end
          end
        end
      end
    end
  end

  local function process_list(ts_list, parent_ast)
    for item in ts_list:iter_children() do
      if item:type() == "list_item" then
        local ast_node = make_list_item_node(item)
        if ast_node then
          add_child(parent_ast, ast_node)
          process_nested_lists(item, ast_node)
        end
      end
    end
  end

  local function traverse(ts_node, parent_ast)
    if ts_node:type() == "list" then
      process_list(ts_node, parent_ast)
    else
      for child in ts_node:iter_children() do
        traverse(child, parent_ast)
      end
    end
  end

  traverse(root, ast_root)

  return ast_root, created_nodes
end

--- Fallback line-by-line parsing when Tree-sitter is unavailable
--- @param lines string[]
--- @return ASTNode
local function parse_to_ast_fallback(lines)
  if not lines or #lines == 0 then
    return create_root_node()
  end

  local nodes = {}
  local i = 1

  while i <= #lines do
    local line = lines[i]
    local line_info = parse_line_info(line, i)
    if line_info then
      line_info.indent_string = get_indent_string(line)
      local end_line = find_fallback_content_end(lines, i, line_info.indent)
      local content = build_content_value(lines, i, end_line, line_info.content)
      line_info.content = content

      local ast_node = create_ast_node(line_info.type, content, line_info)
      table.insert(nodes, ast_node)

      i = end_line + 1
    else
      i = i + 1
    end
  end

  return build_ast_tree(nodes)
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

  if lines and #lines == 0 then
    return create_root_node()
  end

  local ts_ast, created = parse_with_treesitter(lines, buffer_id)
  if ts_ast and created and created >= 0 then
    return ts_ast
  end

  return parse_to_ast_fallback(lines or {})
end

--- Render an AST node to markdown lines (can be multiple lines for multi-line content)
--- @param node ASTNode: the node to render
--- @return string[]: array of rendered markdown lines
local function render_ast_node(node)
  if node.type == "root" then
    return {}
  end

  local indent_str = node.indent_string or string.rep(" ", node.indent)
  local marker = node.marker or "-"
  local content_lines = {}

  local content_parts = vim.split(node.content or "", "\n", { plain = true, trimempty = false })
  if #content_parts == 0 then
    table.insert(content_parts, "")
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
    local first_line = indent_str .. marker .. " " .. checkbox_symbol
    if first_content ~= "" then
      first_line = first_line .. " " .. first_content
    else
      first_line = first_line .. " "
    end
    table.insert(content_lines, first_line)

    -- Continuation lines maintain their original indentation
    for i = 2, #content_parts do
      table.insert(content_lines, content_parts[i])
    end
  elseif node.type == "list" then
    -- First line with list marker
    local first_content = content_parts[1] or ""
    local first_line = indent_str .. marker
    if first_content ~= "" then
      first_line = first_line .. " " .. first_content
    else
      first_line = first_line .. " "
    end
    table.insert(content_lines, first_line)

    -- Continuation lines maintain their original indentation
    for i = 2, #content_parts do
      table.insert(content_lines, content_parts[i])
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
