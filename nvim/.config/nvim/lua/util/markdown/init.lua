-- Main orchestration module for markdown processing
-- Provides public API by delegating to specialized modules

local config = require("util.markdown.config").config
local buffer = require("util.markdown.buffer")
local ast = require("util.markdown.ast")
local operations = require("util.markdown.operations")
local daily = require("util.markdown.daily")

-- Re-export all public functions from modules
local M = {}

-- AST functions
M.parse_to_ast = ast.parse_to_ast
M.ast_to_lines = ast.ast_to_lines

-- Tree operations
M.propagate_checkbox_status = operations.propagate_checkbox_status
M.prune_completed_branches = operations.prune_completed_branches
M.diff_trees = operations.diff_trees

-- Daily notes functions
M.carry_over_today = daily.carry_over_today
M.normalize_checkboxes = daily.normalize_checkboxes
M.remove_completed = daily.remove_completed
M.remove_changes_sections = daily.remove_changes_sections
M.compare_daily_changes = daily.compare_daily_changes
M.carry_over_and_process = daily.carry_over_and_process

-- Buffer utilities (exposed for other modules if needed)
M.validate_markdown_buffer = buffer.validate_markdown_buffer
M.get_buffer_lines = buffer.get_buffer_lines
M.set_buffer_lines = buffer.set_buffer_lines

-- Legacy functions for backwards compatibility
--- Detect the checkbox status for a single list item line.
---
--- Recognizes bullets `-`, `*`, `+` and numbered lists `1.` followed by a checkbox `[ ]`, `[-]`, `[X]`/`[x]`.
---
--- @param line string: a single line of text
--- @return 'done'|'progress'|'todo'|nil: checkbox status, or nil if not a checkbox item
local function detect_status(line)
  if not line or type(line) ~= "string" then
    return nil
  end

  -- Match both bullet points and numbered lists
  local ch = line:match("^[%s]*" .. config.bullet_pattern .. " +%[(.)%]") or line:match("^[%s]*%d+%. +%[(.)%]")
  if ch == "x" or ch == "X" then
    return "done"
  elseif ch == "-" then
    return "progress"
  elseif ch == " " then
    return "todo"
  else
    return nil
  end
end

--- Replace checkbox in a line with new status.
--- @param line string: line containing a checkbox
--- @param new_status string: "todo", "progress", or "done"
--- @return string: updated line
local function replace_box(line, new_status)
  if not line or not new_status then
    return line
  end

  local symbol = config.symbols.todo
  if new_status == "done" then
    symbol = config.symbols.done
  elseif new_status == "progress" then
    symbol = config.symbols.progress
  end

  -- Replace checkbox in bullet or numbered list
  local updated = line:gsub("^([%s]*" .. config.bullet_pattern .. " +)%[.%]", "%1" .. symbol)
  if updated == line then
    -- Try numbered list pattern
    updated = line:gsub("^([%s]*%d+%. +)%[.%]", "%1" .. symbol)
  end

  return updated
end

--- Legacy function for processing lines (maintained for compatibility)
--- @param lines string[]
--- @param buffer_id number|nil
--- @return boolean: success
function M.process_lines(lines, buffer_id)
  if not lines or #lines == 0 then
    return false
  end

  -- Use AST-based processing
  local parsed_ast = ast.parse_to_ast(lines, buffer_id)
  operations.propagate_checkbox_status(parsed_ast)
  local processed = ast.ast_to_lines(parsed_ast)

  -- Update the buffer if buffer_id is provided
  if buffer_id then
    return buffer.set_buffer_lines(buffer_id, processed)
  end

  return true
end

--- Test AST functions (for debugging/development)
function M.test_ast_functions()
  local buffer_id = 0
  local lines, valid = buffer.get_buffer_lines(buffer_id)
  if not valid then
    vim.notify("Cannot test AST functions on invalid buffer", vim.log.levels.ERROR)
    return
  end

  vim.notify("Testing AST round-trip conversion...", vim.log.levels.INFO)

  local success, output_lines = ast.test_round_trip(lines, buffer_id)
  if success then
    vim.notify("AST round-trip test passed!", vim.log.levels.INFO)
  else
    vim.notify("AST round-trip test failed - check messages for details", vim.log.levels.WARN)
  end

  -- Test tree operations
  vim.notify("Testing tree operations...", vim.log.levels.INFO)
  local parsed_ast = ast.parse_to_ast(lines, buffer_id)
  local original_lines = ast.ast_to_lines(parsed_ast)

  operations.propagate_checkbox_status(parsed_ast)
  local propagated_lines = ast.ast_to_lines(parsed_ast)

  operations.prune_completed_branches(parsed_ast)
  local pruned_lines = ast.ast_to_lines(parsed_ast)

  vim.notify(
    string.format("Tree operations test: %d -> %d -> %d lines", #original_lines, #propagated_lines, #pruned_lines),
    vim.log.levels.INFO
  )
end

-- Expose legacy/internal functions for testing and backwards compatibility
M._detect_status = detect_status
M._replace_box = replace_box
M._config = config

-- For buffer.lua module that needs to import this temporarily during transition
M.parse_markdown_items = function(lines, buffer_id)
  -- This is a compatibility shim that converts old parse_markdown_items calls to AST calls
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

  return items, false -- second return indicates whether tree-sitter was used
end

return M

