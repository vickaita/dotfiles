-- Buffer operations for markdown processing
-- Handles validation, caching, and buffer interaction

local config = require("util.markdown.config").config

--- Check if current buffer is valid for markdown operations
--- @param buffer_id number|nil
--- @return boolean, string|nil -- success, error message
local function validate_markdown_buffer(buffer_id)
  buffer_id = buffer_id or 0
  local bufname = vim.api.nvim_buf_get_name(buffer_id)
  if not bufname or bufname == "" then
    return false, "No file associated with buffer"
  end

  local ft = vim.api.nvim_buf_get_option(buffer_id, "filetype")

  local is_supported = false
  for _, supported_ft in ipairs(config.supported_filetypes) do
    if ft == supported_ft then
      is_supported = true
      break
    end
  end

  if not is_supported then
    return false, "Only works on Markdown buffers"
  end

  return true, nil
end

--- Cached parsing results to avoid re-parsing
local parse_cache = {}

--- Get cached parse result
--- @param lines string[]
--- @param buffer_id number|nil
--- @return table|nil: cached result or nil if not found
local function get_cached_parse(lines, buffer_id)
  local cache_key = table.concat(lines, "\n") .. ":" .. (buffer_id or 0)
  return parse_cache[cache_key]
end

--- Set cached parse result
--- @param lines string[]
--- @param buffer_id number|nil
--- @param result table: result to cache
local function set_cached_parse(lines, buffer_id, result)
  local cache_key = table.concat(lines, "\n") .. ":" .. (buffer_id or 0)
  parse_cache[cache_key] = result

  -- Simple cache size management
  local count = 0
  for _ in pairs(parse_cache) do
    count = count + 1
  end
  if count > 10 then
    parse_cache = {} -- Clear cache when it gets too large
  end
end

--- Enhanced parse function with caching
--- @param lines string[]
--- @param buffer_id number|nil
--- @return table|nil, boolean
local function parse_markdown_items_cached(lines, buffer_id)
  local cached = get_cached_parse(lines, buffer_id)
  if cached then
    return cached.items, cached.used_ts
  end

  -- Use AST-based parsing
  local ast = require("util.markdown.ast")
  local parsed_ast = ast.parse_to_ast(lines, buffer_id)
  local items = {}

  -- Extract items from AST (simplified conversion)
  local function extract_items(node, items_list)
    if node.type == "checkbox" or node.type == "list" then
      table.insert(items_list, {
        content = node.content,
        status = node.status,
        indent = node.indent,
        type = node.type,
        line_number = node.line_number,
      })
    end
    for _, child in ipairs(node.children) do
      extract_items(child, items_list)
    end
  end

  extract_items(parsed_ast, items)

  if items and #items > 0 then
    set_cached_parse(lines, buffer_id, { items = items, used_ts = false })
  end

  return items, false -- second return indicates whether tree-sitter was used
end

--- Get buffer lines safely
--- @param buffer_id number|nil
--- @return string[], boolean: lines and validation success
local function get_buffer_lines(buffer_id)
  buffer_id = buffer_id or 0
  local valid, err = validate_markdown_buffer(buffer_id)
  if not valid then
    vim.notify("Buffer validation failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return {}, false
  end

  local lines = vim.api.nvim_buf_get_lines(buffer_id, 0, -1, false)
  return lines, true
end

--- Set buffer lines safely
--- @param buffer_id number|nil
--- @param lines string[]
--- @return boolean: success
local function set_buffer_lines(buffer_id, lines)
  buffer_id = buffer_id or 0
  local valid, err = validate_markdown_buffer(buffer_id)
  if not valid then
    vim.notify("Buffer validation failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return false
  end

  vim.api.nvim_buf_set_lines(buffer_id, 0, -1, false, lines)
  return true
end

-- Export public functions
local M = {}

M.validate_markdown_buffer = validate_markdown_buffer
M.get_cached_parse = get_cached_parse
M.set_cached_parse = set_cached_parse
M.parse_markdown_items_cached = parse_markdown_items_cached
M.get_buffer_lines = get_buffer_lines
M.set_buffer_lines = set_buffer_lines

return M

