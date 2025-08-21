-- Daily notes functionality for markdown processing
-- Handles carry over, normalization, pruning, and comparison operations

local config = require("util.markdown.config").config
local buffer = require("util.markdown.buffer")
local ast = require("util.markdown.ast")
local operations = require("util.markdown.operations")

--- Create today's daily note beside the current dated note, copying content unchanged.
---
--- Validates that the current buffer name matches `YYYY-MM-DD.md`, then writes a new file for
--- today in the same directory without overwriting existing files, and opens it.
---
--- @param buffer_id number|nil
--- @return boolean -- success
local function carry_over_today(buffer_id)
  buffer_id = buffer_id or 0
  local valid, err = buffer.validate_markdown_buffer(buffer_id)
  if not valid then
    vim.notify("CarryOverToday: " .. err, vim.log.levels.ERROR)
    return false
  end

  local bufname = vim.api.nvim_buf_get_name(buffer_id)

  local fname = vim.fn.fnamemodify(bufname, ":t")
  local dir = vim.fn.fnamemodify(bufname, ":h")

  -- Expect filenames like YYYY-MM-DD.md
  local y, m, d = fname:match(config.date_pattern)
  if not y then
    vim.notify("Filename must be YYYY-MM-DD.md to carry over", vim.log.levels.WARN)
    return false
  end

  local today = os.date("%Y-%m-%d")
  if fname:sub(1, 10) == today then
    vim.notify("Already on today's note", vim.log.levels.INFO)
    return true
  end

  local newpath = dir .. "/" .. today .. ".md"
  if vim.loop.fs_stat(newpath) then
    vim.cmd("edit " .. vim.fn.fnameescape(newpath))
    return true
  end

  local lines = vim.api.nvim_buf_get_lines(buffer_id, 0, -1, false)

  -- Update date header if present
  if lines and #lines > 0 and lines[1]:match("^# %d%d%d%d%-%d%d%-%d%d$") then
    lines[1] = "# " .. today
  end

  local ok, write_err = pcall(function()
    vim.fn.writefile(lines, newpath)
  end)
  if not ok then
    vim.notify("Failed to create today's note: " .. tostring(write_err), vim.log.levels.ERROR)
    return false
  end

  -- Verify file was written successfully
  if not vim.loop.fs_stat(newpath) then
    vim.notify("Failed to verify today's note was created", vim.log.levels.ERROR)
    return false
  end

  vim.cmd("edit " .. vim.fn.fnameescape(newpath))
  return true
end

--- Normalize checkbox markers in the current buffer in place.
---
--- Applies the same logic as `update_checkboxes_lines`, then replaces buffer contents.
---
--- @param buffer_id number|nil
--- @return boolean -- success
local function normalize_checkboxes(buffer_id)
  buffer_id = buffer_id or 0
  local valid, err = buffer.validate_markdown_buffer(buffer_id)
  if not valid then
    vim.notify("NormalizeCheckboxes: " .. err, vim.log.levels.ERROR)
    return false
  end

  local lines = vim.api.nvim_buf_get_lines(buffer_id, 0, -1, false)

  -- Parse to AST, propagate status, and convert back to lines
  local parsed_ast = ast.parse_to_ast(lines, buffer_id)
  operations.propagate_checkbox_status(parsed_ast)
  local processed = ast.ast_to_lines(parsed_ast)

  -- Replace non-list lines in their original positions
  local final_lines = {}
  local ast_line_idx = 1

  for i, original_line in ipairs(lines) do
    local line_info = ast.parse_line_info(original_line, i)
    if line_info then
      -- This is a list line, use the processed version
      if ast_line_idx <= #processed then
        table.insert(final_lines, processed[ast_line_idx])
        ast_line_idx = ast_line_idx + 1
      else
        table.insert(final_lines, original_line)
      end
    else
      -- Not a list line, keep original
      table.insert(final_lines, original_line)
    end
  end

  vim.api.nvim_buf_set_lines(buffer_id, 0, -1, false, final_lines)
  return true
end

--- Remove completed subtrees from the current buffer in place.
---
--- Uses `remove_completed_lines` and replaces buffer contents.
---
--- @param buffer_id number|nil
--- @return boolean -- success
local function remove_completed(buffer_id)
  buffer_id = buffer_id or 0
  local valid, err = buffer.validate_markdown_buffer(buffer_id)
  if not valid then
    vim.notify("RemoveCompleted: " .. err, vim.log.levels.ERROR)
    return false
  end

  local lines = vim.api.nvim_buf_get_lines(buffer_id, 0, -1, false)

  -- Parse to AST, prune completed branches, and convert back to lines
  local parsed_ast = ast.parse_to_ast(lines, buffer_id)
  operations.prune_completed_branches(parsed_ast)
  local processed_list_lines = ast.ast_to_lines(parsed_ast)

  -- Rebuild the document, replacing only list lines with processed versions
  local final_lines = {}
  local processed_idx = 1

  for i, original_line in ipairs(lines) do
    local line_info = ast.parse_line_info(original_line, i)
    if line_info then
      -- This was a list line in the original
      -- Check if it survived the pruning
      if processed_idx <= #processed_list_lines then
        -- We have a processed line to use
        local processed_line = processed_list_lines[processed_idx]
        -- Check if this processed line corresponds to the original line
        local processed_info = ast.parse_line_info(processed_line, processed_idx)
        if processed_info and processed_info.content == line_info.content then
          table.insert(final_lines, processed_line)
          processed_idx = processed_idx + 1
        else
          -- This original line was pruned, skip it
        end
      else
        -- No more processed lines, this was pruned
      end
    else
      -- Not a list line, keep original
      table.insert(final_lines, original_line)
    end
  end

  vim.api.nvim_buf_set_lines(buffer_id, 0, -1, false, final_lines)
  return true
end

--- Remove all "Changes since" sections from document
--- @param lines table -- document lines
--- @return table -- document lines without changes sections
local function remove_changes_sections(lines)
  if not lines or #lines == 0 then
    return lines
  end

  local updated_lines = {}
  local i = 1

  while i <= #lines do
    local line = lines[i]

    -- Check if this line is a "Changes since" header
    if line:match("^## Changes since ") then
      -- Skip this section entirely - find the end
      local section_end = #lines -- Default to end of document

      -- Look for the next heading at any level
      for j = i + 1, #lines do
        local next_line = lines[j]
        if next_line:match("^#+ ") then
          section_end = j - 1
          break
        end
      end

      -- Skip past the entire changes section
      i = section_end + 1
    else
      -- Keep this line
      table.insert(updated_lines, line)
      i = i + 1
    end
  end

  return updated_lines
end

--- Remove all "Changes since" sections from the current buffer
--- @param buffer_id number|nil
--- @return boolean -- success
local function remove_changes_sections_buffer(buffer_id)
  buffer_id = buffer_id or 0
  local valid, err = buffer.validate_markdown_buffer(buffer_id)
  if not valid then
    vim.notify("RemoveChangesSections: " .. err, vim.log.levels.ERROR)
    return false
  end

  local lines = vim.api.nvim_buf_get_lines(buffer_id, 0, -1, false)
  local processed = remove_changes_sections(lines)
  vim.api.nvim_buf_set_lines(buffer_id, 0, -1, false, processed)
  return true
end

--- Parse date from filename in YYYY-MM-DD.md format
--- @param filename string
--- @return number, number, number|nil -- year, month, day or nil if invalid
local function parse_date_from_filename(filename)
  if not filename then
    return nil
  end
  local y, m, d = filename:match(config.date_pattern)
  if y and m and d then
    return tonumber(y), tonumber(m), tonumber(d)
  end
  return nil
end

--- Subtract days from a date string
--- @param date_string string in YYYY-MM-DD format
--- @param days number of days to subtract
--- @return string|nil -- new date in YYYY-MM-DD format or nil if invalid
local function subtract_days(date_string, days)
  local y, m, d = date_string:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
  if not y or not m or not d then
    return nil
  end

  local time = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d) })
  local new_time = time - (days * 24 * 60 * 60)
  local new_date = os.date("*t", new_time)

  return string.format("%04d-%02d-%02d", new_date.year, new_date.month, new_date.day)
end

--- Find the most recent previous date file that exists
--- @param current_file string -- current filename (YYYY-MM-DD.md)
--- @param dir string -- directory path
--- @return string|nil, string|nil -- previous filename, previous path or nil if not found
local function get_previous_date_file(current_file, dir)
  local y, m, d = parse_date_from_filename(current_file)
  if not y or not m or not d then
    return nil
  end

  local current_date = string.format("%04d-%02d-%02d", y, m, d)

  -- Check up to 14 days back to handle weekends and gaps
  for i = 1, 14 do
    local prev_date = subtract_days(current_date, i)
    if not prev_date then
      break
    end

    local prev_file = prev_date .. ".md"
    local prev_path = dir .. "/" .. prev_file

    if vim.loop.fs_stat(prev_path) then
      return prev_file, prev_path
    end
  end

  return nil
end

--- Get action description based on status change
--- @param from_status string|nil
--- @param to_status string
--- @param change_type string|nil
--- @return string
local function get_action_description(from_status, to_status, change_type)
  if change_type == "child_activity" then
    -- Parent activity due to child changes
    if to_status == "progress" then
      return "Progress on"
    elseif to_status == "done" then
      return "Completed"
    else
      return ""
    end
  elseif not from_status then
    -- New item
    if to_status == "done" then
      return "Completed"
    elseif to_status == "progress" then
      return "Started"
    else
      return ""
    end
  else
    -- Status change
    if from_status == "todo" and to_status == "progress" then
      return "Started"
    elseif from_status == "todo" and to_status == "done" then
      return "Completed"
    elseif from_status == "progress" and to_status == "done" then
      return "Completed"
    elseif from_status == "progress" and to_status == "todo" then
      return "Reset to todo"
    elseif from_status == "done" and to_status == "todo" then
      return "Reopened"
    elseif from_status == "done" and to_status == "progress" then
      return "Reopened and started"
    else
      return "Changed"
    end
  end
end

--- Find existing changes section in document
--- @param lines table -- document lines
--- @param previous_date string -- the previous date to look for
--- @return number|nil, number|nil -- start_line, end_line (1-based) or nil if not found
local function find_changes_section(lines, previous_date)
  if not lines or not previous_date then
    return nil, nil
  end

  local section_header = "## Changes since " .. previous_date
  local start_line = nil
  local end_line = nil

  -- Find the start of the changes section
  for i, line in ipairs(lines) do
    if line == section_header then
      start_line = i
      break
    end
  end

  if not start_line then
    return nil, nil
  end

  -- Find the end of the changes section (next heading at any level or end of document)
  end_line = #lines -- Default to end of document
  for i = start_line + 1, #lines do
    local line = lines[i]
    if line:match("^#+ ") then
      end_line = i - 1
      break
    end
  end

  return start_line, end_line
end

--- Update document with changes section (replace existing or append new)
--- @param lines table -- current document lines
--- @param new_section_lines table -- new section content
--- @param previous_date string -- previous date for section matching
--- @return table -- updated document lines
local function update_changes_section(lines, new_section_lines, previous_date)
  if not lines or not new_section_lines then
    return lines or {}
  end

  local start_line, end_line = find_changes_section(lines, previous_date)

  if start_line and end_line then
    -- Replace existing section
    local updated_lines = {}

    -- Add lines before the changes section
    for i = 1, start_line - 1 do
      table.insert(updated_lines, lines[i])
    end

    -- Add new section content
    for _, line in ipairs(new_section_lines) do
      table.insert(updated_lines, line)
    end

    -- Add blank line separation if there's content after the changes section
    if end_line + 1 <= #lines then
      table.insert(updated_lines, "")
    end

    -- Add lines after the changes section
    for i = end_line + 1, #lines do
      table.insert(updated_lines, lines[i])
    end

    return updated_lines
  else
    -- Append new section at the end
    local updated_lines = {}

    -- Copy all existing lines
    for _, line in ipairs(lines) do
      table.insert(updated_lines, line)
    end

    -- Add blank line before new section if document doesn't end with blank line
    if #updated_lines > 0 and updated_lines[#updated_lines] ~= "" then
      table.insert(updated_lines, "")
    end

    -- Add new section
    for _, line in ipairs(new_section_lines) do
      table.insert(updated_lines, line)
    end

    return updated_lines
  end
end

--- Format the changes output for document insertion
--- @param changes table[]
--- @param previous_date string|nil
--- @return table -- lines to insert
local function format_changes_section(changes, previous_date)
  local lines = {}
  table.insert(lines, "## Changes since " .. (previous_date or "previous day"))
  table.insert(lines, "")

  if not changes or #changes == 0 then
    table.insert(lines, "No changes found since " .. (previous_date or "previous day"))
  else
    for _, change in ipairs(changes) do
      local prefix = string.rep("  ", math.floor(change.indent / 2)) -- Convert spaces to readable indentation
      local action = get_action_description(change.prev_status, change.status, change.change_type)

      -- Handle multi-line content by splitting on newlines
      if change.content and change.content ~= "" then
        local content_lines = {}
        for line in change.content:gmatch("[^\n]+") do
          table.insert(content_lines, line)
        end

        if #content_lines > 0 then
          -- First line with action prefix
          local action_prefix = action ~= "" and (action .. " ") or ""
          table.insert(lines, prefix .. "- " .. action_prefix .. content_lines[1])
          -- Additional lines with continuation indentation
          for i = 2, #content_lines do
            table.insert(lines, prefix .. "  " .. content_lines[i])
          end
        else
          -- Fallback for empty content
          local action_prefix = action ~= "" and (action .. " ") or ""
          table.insert(lines, prefix .. "- " .. action_prefix)
        end
      else
        -- Fallback for no content
        local action_prefix = action ~= "" and (action .. " ") or ""
        table.insert(lines, prefix .. "- " .. action_prefix)
      end
    end
  end

  return lines
end

--- Compare the current daily file with the previous day's file
--- @param buffer_id number|nil
--- @return boolean -- success
local function compare_daily_changes(buffer_id)
  buffer_id = buffer_id or 0
  local valid, err = buffer.validate_markdown_buffer(buffer_id)
  if not valid then
    vim.notify("CompareDaily: " .. err, vim.log.levels.ERROR)
    return false
  end

  local bufname = vim.api.nvim_buf_get_name(buffer_id)
  local fname = vim.fn.fnamemodify(bufname, ":t")
  local dir = vim.fn.fnamemodify(bufname, ":h")

  -- Validate filename format
  local y, m, d = parse_date_from_filename(fname)
  if not y then
    vim.notify("Filename must be YYYY-MM-DD.md to compare daily changes", vim.log.levels.WARN)
    return false
  end

  -- Find previous day's file
  local prev_fname, prev_path = get_previous_date_file(fname, dir)
  if not prev_fname then
    vim.notify("No previous daily file found to compare against", vim.log.levels.WARN)
    return false
  end

  -- Read current file content
  local current_lines = vim.api.nvim_buf_get_lines(buffer_id, 0, -1, false)
  current_lines = remove_changes_sections(current_lines)
  local current_ast = ast.parse_to_ast(current_lines, buffer_id)

  -- Read previous file content
  local prev_lines = vim.fn.readfile(prev_path)
  local previous_ast = ast.parse_to_ast(prev_lines, nil)

  -- Find changes using AST diff
  local changes = operations.diff_trees(previous_ast, current_ast)

  -- Get dates for section headers
  local prev_date = prev_fname:match("^(.-)%.md$") or prev_fname

  -- Format new section content
  local new_section_lines = format_changes_section(changes, prev_date)

  -- Update the document with the new section
  local updated_lines = update_changes_section(current_lines, new_section_lines, prev_date)

  -- Replace buffer content with updated lines
  vim.api.nvim_buf_set_lines(buffer_id, 0, -1, false, updated_lines)

  return true
end

--- Carry over current note to today, normalize checkboxes, then remove completed subtrees.
---
--- Steps:
--- 1. `compare_daily_changes()` - Add changes section to current file
--- 2. `carry_over_today()` - Create new file for today
--- 3. `remove_changes_sections()` - Remove changes sections from new file
--- 4. `normalize_checkboxes()` - Update checkbox states in new file
--- 5. `remove_completed()` - Remove completed items from new file
---
--- @param buffer_id number|nil
--- @return boolean -- success
local function carry_over_and_process(buffer_id)
  buffer_id = buffer_id or 0

  -- First, add changes comparison to the current file before carrying over
  if not compare_daily_changes(buffer_id) then
    vim.notify("Warning: Could not add changes section to current file", vim.log.levels.WARN)
    -- Continue anyway - this shouldn't block the carry over process
  end

  if not carry_over_today(buffer_id) then
    return false
  end

  -- After carry_over_today, the new buffer is opened (buffer 0)
  -- Remove any changes sections that were copied over
  if not remove_changes_sections_buffer(0) then
    return false
  end

  if not normalize_checkboxes(0) then
    return false
  end

  if not remove_completed(0) then
    return false
  end

  return true
end

-- Export public functions
local M = {}

M.carry_over_today = carry_over_today
M.normalize_checkboxes = normalize_checkboxes
M.remove_completed = remove_completed
M.remove_changes_sections = remove_changes_sections_buffer
M.compare_daily_changes = compare_daily_changes
M.carry_over_and_process = carry_over_and_process

return M
