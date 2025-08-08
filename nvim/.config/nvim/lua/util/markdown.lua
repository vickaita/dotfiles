-- Utilities for managing Markdown checkbox lists in daily notes.
--
-- This module focuses on three workflows:
-- 1) Normalizing checkbox symbols in-place based on descendants.
-- 2) Removing completed subtrees conservatively.
-- 3) Carrying the current day's content forward to a new file.
local M = {}

--- Configuration for checkbox symbols and patterns
local config = {
  symbols = {
    todo = "[ ]",
    progress = "[-]",
    done = "[x]",
  },
  bullet_pattern = "[%-%*%+]",
  list_pattern = "[%-%*%+]|%d+%.",
  date_pattern = "^(%d%d%d%d)%-(%d%d)%-(%d%d)%.md$",
  supported_filetypes = { "markdown" },
}

--- Validate input parameters
-- @param lines string[]|nil
-- @param buffer_id number|nil
-- @return boolean, string|nil
local function validate_input(lines, buffer_id)
  if lines and type(lines) ~= "table" then
    return false, "Lines must be a table"
  end
  if buffer_id and type(buffer_id) ~= "number" then
    return false, "Buffer ID must be a number"
  end
  return true
end

--- Detect the checkbox status for a single list item line.
--
-- Recognizes bullets `-`, `*`, `+` and numbered lists `1.` followed by a checkbox `[ ]`, `[-]`, `[X]`/`[x]`.
--
-- @param line string: a single line of text
-- @return 'done'|'progress'|'todo'|nil: checkbox status, or nil if not a checkbox item
local function detect_status(line)
  if not line or type(line) ~= "string" then
    return nil
  end

  -- Match both bullet points and numbered lists
  local ch = line:match("^[%s]*" .. config.bullet_pattern .. " +%[(.)%]") or line:match("^[%s]*%d+%. +%[(.)%]")
  if ch == "x" or ch == "X" then
    return "done"
  end
  if ch == "-" then
    return "progress"
  end
  if ch == " " then
    return "todo"
  end
  return nil
end

--- Parse markdown list items using Tree-sitter or fallback to indentation
-- @param lines string[]
-- @param buffer_id number
-- @return table|nil, boolean -- items array and whether Tree-sitter was used
local function parse_markdown_items(lines, buffer_id)
  local valid, err = validate_input(lines, buffer_id)
  if not valid then
    vim.notify("Invalid input: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return nil, false
  end

  buffer_id = buffer_id or 0

  -- Try Tree-sitter first
  local ok_ts = pcall(require, "vim.treesitter")
  if ok_ts then
    local parser_ok, parser = pcall(vim.treesitter.get_parser, buffer_id, "markdown")
    if parser_ok and parser then
      local tree = parser:parse()[1]
      if tree then
        local root = tree:root()
        local query = vim.treesitter.query.parse("markdown", "(list_item) @item")
        local items = {}
        for id, node in query:iter_captures(root, buffer_id, 0, -1) do
          if query.captures[id] == "item" then
            local sr, _, er, _ = node:range()
            local line = lines[sr + 1] or ""
            local status = detect_status(line)
            local indent = #(line:match("^(%s*)") or "")
            table.insert(items, {
              sr = sr,
              er = er,
              status = status,
              indent = indent,
              line = line,
              children = {},
            })
          end
        end
        table.sort(items, function(a, b)
          return a.sr < b.sr
        end)
        -- Tree-sitter ranges for list_item can be inaccurate for our use case
        -- (they may include siblings that shouldn't be included)
        -- Fall back to indentation-based approach for more precise control
        if #items > 0 and false then
          return items, true
        end
      end
    end
  end

  -- Fallback to indentation-based parsing
  local items = {}
  for idx, line in ipairs(lines) do
    local bullet_match = line:match("^(%s*)" .. config.bullet_pattern .. " +") or line:match("^(%s*)%d+%. +")
    if bullet_match then
      table.insert(items, {
        start = idx,
        indent = #bullet_match,
        _end = nil,
        status = detect_status(line),
        line = line,
        children = {},
      })
    end
  end

  -- Calculate end positions for fallback items
  for i = 1, #items do
    local cur = items[i]
    local next_start = #lines + 1
    for j = i + 1, #items do
      if items[j].indent <= cur.indent then
        next_start = items[j].start
        break
      end
    end
    cur._end = next_start - 1
  end

  return items, false
end

--- Build parent-child relationships for items
-- @param items table[]
-- @param use_treesitter boolean
-- @return table[] -- items with parent/children populated
local function build_relationships(items, use_treesitter)
  if not items or #items == 0 then
    return items
  end

  local stack = {}

  for idx, item in ipairs(items) do
    if use_treesitter then
      -- Pop stack until we find a valid parent (proper containment + deeper indent)
      while #stack > 0 do
        local top = stack[#stack]
        local contains = item.sr > top.sr and item.er <= top.er
        local deeper = item.indent > top.indent
        if contains and deeper then
          break
        end
        table.remove(stack)
      end
    else
      -- Fallback: use range-based containment
      while #stack > 0 and item.start > stack[#stack]._end do
        table.remove(stack)
      end
    end

    if #stack > 0 then
      item.parent = stack[#stack]
      table.insert(stack[#stack].children, idx)
    end
    table.insert(stack, item)
  end

  return items
end

--- Replace a done checkbox `[x]` with in-progress `[-]` on a single line.
--
-- @param line string
-- @return string: the line with the first `[x]`/`[X]` replaced by `[-]` (if present)
local function replace_done_with_progress(line)
  if not line then
    return ""
  end
  -- Handle both bullet points and numbered lists
  local result = line:gsub("(%s*" .. config.bullet_pattern .. " +)%[[xX]%]", "%1" .. config.symbols.progress, 1)
  if result == line then
    result = line:gsub("(%s*%d+%. +)%[[xX]%]", "%1" .. config.symbols.progress, 1)
  end
  return result
end

--- Replace the checkbox marker on a list item line with a target status.
--
-- @param line string
-- @param target 'done'|'progress'|'todo'
-- @return string: the updated line
local function replace_box(line, target)
  if not line or not target then
    return line or ""
  end

  local sym = config.symbols[target]
  if not sym then
    return line
  end

  -- Handle both bullet points and numbered lists
  local result = line:gsub("(%s*" .. config.bullet_pattern .. " +)%[[ xX%-]%]", "%1" .. sym, 1)
  if result == line then
    result = line:gsub("(%s*%d+%. +)%[[ xX%-]%]", "%1" .. sym, 1)
  end
  return result
end

--- Compute new status for items based on children's status
-- @param items table[]
-- @return table[] -- items with new_status computed
local function compute_new_status_recursive(items)
  local function compute_new_status(item_idx)
    local node = items[item_idx]
    if node.new_status then
      return node.new_status
    end

    local saw = { todo = false, progress = false, done = false }
    local child_with_status = false

    for _, child_idx in ipairs(node.children) do
      local child_status = compute_new_status(child_idx)
      if child_status then
        child_with_status = true
        saw[child_status] = true
      end
    end

    if child_with_status then
      if saw.todo and not saw.done and not saw.progress then
        node.new_status = "todo"
      elseif saw.done and not saw.todo and not saw.progress then
        node.new_status = "done"
      else
        node.new_status = "progress"
      end
    else
      node.new_status = node.status
    end

    return node.new_status
  end

  for i = 1, #items do
    if not items[i].new_status then
      compute_new_status(i)
    end
  end

  return items
end

--- Remove completed items and their subtrees; toggle parents with incomplete descendants to `[-]`.
--
-- - Uses Tree‑sitter `markdown` to determine list_item ranges when available; otherwise
--   falls back to a conservative indentation heuristic.
-- - If a completed item has any descendant that is `[ ]` or `[-]`, the parent line is kept and
--   its box becomes `[-]`; its subtree is preserved.
-- - Otherwise the entire subtree is removed.
--
-- @param lines string[]: buffer content lines
-- @param buffer_id number|nil: buffer ID for Tree-sitter parsing
-- @return string[]: transformed lines
function M.process_lines(lines, buffer_id)
  if not lines then
    return {}
  end

  local items, used_ts = parse_markdown_items(lines, buffer_id)
  if not items then
    return lines
  end

  items = build_relationships(items, used_ts)
  local out = {}

  if used_ts then
    -- Mark items that have incomplete descendants
    for _, parent in ipairs(items) do
      if parent.status == "done" then
        local has_incomplete = false
        for _, child in ipairs(items) do
          if child.sr > parent.sr and child.er <= parent.er then
            if child.status == "todo" or child.status == "progress" then
              has_incomplete = true
              break
            end
          end
        end
        parent.has_incomplete_desc = has_incomplete
      end
    end

    local by_start = {}
    for idx, item in ipairs(items) do
      by_start[item.sr] = idx
    end

    local i = 0
    while i < #lines do
      local item_idx = by_start[i]
      if not item_idx then
        table.insert(out, lines[i + 1])
        i = i + 1
      else
        local item = items[item_idx]
        if item.status == "done" then
          if item.has_incomplete_desc then
            -- Toggle parent to in-progress; keep subtree
            local parent_line = replace_done_with_progress(lines[item.sr + 1] or "")
            table.insert(out, parent_line)
            for r = item.sr + 1, item.er do
              table.insert(out, lines[r + 1])
            end
            i = item.er + 1
          else
            -- Double-check via text scan for safety
            local parent_indent = (lines[item.sr + 1] or ""):match("^(%s*)" .. config.bullet_pattern .. " +")
              or (lines[item.sr + 1] or ""):match("^(%s*)%d+%. +")
              or ""
            local parent_indent_len = #parent_indent
            local has_incomplete_text = false
            for r = item.sr + 1, item.er do
              local l = lines[r + 1] or ""
              local ind, ch = l:match("^(%s*)" .. config.bullet_pattern .. " +%[(.)%]")
                or l:match("^(%s*)%d+%. +%[(.)%]")
              if ind and #ind > parent_indent_len and (ch == " " or ch == "-") then
                has_incomplete_text = true
                break
              end
            end
            if has_incomplete_text then
              local parent_line = replace_done_with_progress(lines[item.sr + 1] or "")
              table.insert(out, parent_line)
              for r = item.sr + 1, item.er do
                table.insert(out, lines[r + 1])
              end
              i = item.er + 1
            else
              i = item.er + 1
            end
          end
        else
          table.insert(out, lines[i + 1])
          i = i + 1
        end
      end
    end
  else
    -- Fallback: use parsed items with indentation logic
    local i = 1
    while i <= #lines do
      local line = lines[i]
      local ind = line:match("^(%s*)" .. config.bullet_pattern .. " +%[[xX]%]") or line:match("^(%s*)%d+%. +%[[xX]%]")
      if ind then
        local base = #ind
        local has_incomplete = false
        local j = i + 1
        while j <= #lines do
          local lj = lines[j]
          local lj_bullet_ind = lj:match("^(%s*)" .. config.bullet_pattern .. " +") or lj:match("^(%s*)%d+%. +")
          if lj_bullet_ind then
            local lj_ind = #lj_bullet_ind
            if lj_ind <= base then
              break
            end
            local st = detect_status(lj)
            if st == "todo" or st == "progress" then
              has_incomplete = true
            end
          else
            local nonempty = lj:match("%S") ~= nil
            local leading = lj:match("^(%s*)") or ""
            if nonempty and #leading <= base then
              break
            end
          end
          j = j + 1
        end
        if has_incomplete then
          local parent_line = replace_done_with_progress(line)
          table.insert(out, parent_line)
          for r = i + 1, j - 1 do
            table.insert(out, lines[r])
          end
          i = j
        else
          i = j
        end
      else
        table.insert(out, line)
        i = i + 1
      end
    end
  end

  return out
end

--- Update checkbox markers in memory, based on descendant states; do not remove lines.
--
-- Rules (conservative):
-- - If any descendant is `[-]`, set parent to `[-]`.
-- - Else if any descendant is `[ ]`, make parent `[ ]` if it was `[X]`, otherwise `[-]`.
-- - Parents with only done children remain unchanged.
--
-- @param lines string[]
-- @param buffer_id number|nil
-- @return string[]: lines with adjusted checkbox symbols only
local function update_checkboxes_lines(lines, buffer_id)
  if not lines then
    return {}
  end

  local items, used_ts = parse_markdown_items(lines, buffer_id)
  if not items then
    return lines
  end

  items = build_relationships(items, used_ts)
  items = compute_new_status_recursive(items)

  local out = {}

  if used_ts then
    local by_start = {}
    for idx, item in ipairs(items) do
      by_start[item.sr] = idx
    end

    local i = 0
    while i < #lines do
      local item_idx = by_start[i]
      if not item_idx then
        table.insert(out, lines[i + 1])
        i = i + 1
      else
        local item = items[item_idx]
        local new_line = lines[i + 1]
        if item.status and item.new_status and item.new_status ~= item.status then
          new_line = replace_box(new_line, item.new_status)
        end
        table.insert(out, new_line)
        i = i + 1
      end
    end
  else
    local by_start = {}
    for idx, item in ipairs(items) do
      by_start[item.start] = idx
    end

    for i = 1, #lines do
      local item_idx = by_start[i]
      local line = lines[i]
      if item_idx then
        local item = items[item_idx]
        if item.status and item.new_status and item.new_status ~= item.status then
          line = replace_box(line, item.new_status)
        end
      end
      table.insert(out, line)
    end
  end

  return out
end

--- Remove subtrees rooted at completed items at top-level or under completed parents.
--
-- A completed child under an incomplete or in-progress parent is kept (do not remove),
-- which matches the requested example behavior. Uses Tree‑sitter when available, otherwise
-- a conservative indentation fallback.
--
-- @param lines string[]
-- @param buffer_id number|nil
-- @return string[]: lines with qualifying completed subtrees removed
local function remove_completed_lines(lines, buffer_id)
  if not lines then
    return {}
  end

  local items, used_ts = parse_markdown_items(lines, buffer_id)
  if not items then
    return lines
  end

  items = build_relationships(items, used_ts)

  -- Mark items that have incomplete descendants
  for _, parent in ipairs(items) do
    if parent.status == "done" then
      local has_incomplete = false
      for _, child in ipairs(items) do
        if used_ts then
          if child.sr > parent.sr and child.er <= parent.er then
            if child.status == "todo" or child.status == "progress" then
              has_incomplete = true
              break
            end
          end
        else
          if child.start > parent.start and child._end <= parent._end then
            if child.status == "todo" or child.status == "progress" then
              has_incomplete = true
              break
            end
          end
        end
      end
      parent.has_incomplete_desc = has_incomplete
    end
  end

  -- Compute removal ranges - only remove completed items with no incomplete descendants
  local remove_ranges = {}
  for _, item in ipairs(items) do
    local parent_done = item.parent and item.parent.status == "done"
    local should_remove = item.status == "done" and (item.parent == nil or parent_done) and not item.has_incomplete_desc
    if should_remove then
      if used_ts then
        table.insert(remove_ranges, { s = item.sr, e = item.er })
      else
        local range = { s = item.start - 1, e = item._end - 1 }
        table.insert(remove_ranges, range)
      end
    end
  end
  table.sort(remove_ranges, function(a, b)
    return a.s < b.s
  end)

  local to_remove = {}
  for _, range in ipairs(remove_ranges) do
    for line_idx = range.s, range.e do
      to_remove[line_idx + 1] = true -- Convert to 1-based for array access
    end
  end

  local out = {}
  for i, line in ipairs(lines) do
    if not to_remove[i] then
      table.insert(out, line)
    end
  end

  return out
end

--- Check if current buffer is valid for markdown operations
-- @param buffer_id number|nil
-- @return boolean, string|nil -- success, error message
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
local function get_cached_parse(lines, buffer_id)
  local cache_key = table.concat(lines, "\n") .. ":" .. (buffer_id or 0)
  return parse_cache[cache_key]
end

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
-- @param lines string[]
-- @param buffer_id number|nil
-- @return table|nil, boolean
local function parse_markdown_items_cached(lines, buffer_id)
  local cached = get_cached_parse(lines, buffer_id)
  if cached then
    return cached.items, cached.used_ts
  end

  local items, used_ts = parse_markdown_items(lines, buffer_id)
  if items then
    set_cached_parse(lines, buffer_id, { items = items, used_ts = used_ts })
  end

  return items, used_ts
end

--- Create today's daily note beside the current dated note, copying content unchanged.
--
-- Validates that the current buffer name matches `YYYY-MM-DD.md`, then writes a new file for
-- today in the same directory without overwriting existing files, and opens it.
--
-- @param buffer_id number|nil
-- @return boolean -- success
function M.carry_over_today(buffer_id)
  buffer_id = buffer_id or 0
  local valid, err = validate_markdown_buffer(buffer_id)
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
--
-- Applies the same logic as `update_checkboxes_lines`, then replaces buffer contents.
--
-- @param buffer_id number|nil
-- @return boolean -- success
function M.normalize_checkboxes(buffer_id)
  buffer_id = buffer_id or 0
  local valid, err = validate_markdown_buffer(buffer_id)
  if not valid then
    vim.notify("NormalizeCheckboxes: " .. err, vim.log.levels.ERROR)
    return false
  end

  local lines = vim.api.nvim_buf_get_lines(buffer_id, 0, -1, false)
  local processed = update_checkboxes_lines(lines, buffer_id)

  vim.api.nvim_buf_set_lines(buffer_id, 0, -1, false, processed)
  return true
end

--- Remove completed subtrees from the current buffer in place.
--
-- Uses `remove_completed_lines` and replaces buffer contents.
--
-- @param buffer_id number|nil
-- @return boolean -- success
function M.remove_completed(buffer_id)
  buffer_id = buffer_id or 0
  local valid, err = validate_markdown_buffer(buffer_id)
  if not valid then
    vim.notify("RemoveCompleted: " .. err, vim.log.levels.ERROR)
    return false
  end

  local lines = vim.api.nvim_buf_get_lines(buffer_id, 0, -1, false)
  local processed = remove_completed_lines(lines, buffer_id)
  vim.api.nvim_buf_set_lines(buffer_id, 0, -1, false, processed)
  return true
end

--- Carry over current note to today, normalize checkboxes, then remove completed subtrees.
--
-- Steps:
-- 1. `compare_daily_changes()` - Add changes section to current file
-- 2. `carry_over_today()` - Create new file for today
-- 3. `remove_changes_sections()` - Remove changes sections from new file
-- 4. `normalize_checkboxes()` - Update checkbox states in new file
-- 5. `remove_completed()` - Remove completed items from new file
--
-- @param buffer_id number|nil
-- @return boolean -- success
function M.carry_over_and_process(buffer_id)
  buffer_id = buffer_id or 0

  -- First, add changes comparison to the current file before carrying over
  if not M.compare_daily_changes(buffer_id) then
    vim.notify("Warning: Could not add changes section to current file", vim.log.levels.WARN)
    -- Continue anyway - this shouldn't block the carry over process
  end

  if not M.carry_over_today(buffer_id) then
    return false
  end

  -- After carry_over_today, the new buffer is opened (buffer 0)
  -- Remove any changes sections that were copied over
  if not M.remove_changes_sections(0) then
    return false
  end

  if not M.normalize_checkboxes(0) then
    return false
  end

  if not M.remove_completed(0) then
    return false
  end

  return true
end

--- Remove all "Changes since" sections from document
-- @param lines table -- document lines
-- @return table -- document lines without changes sections
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
-- @param buffer_id number|nil
-- @return boolean -- success
function M.remove_changes_sections(buffer_id)
  buffer_id = buffer_id or 0
  local valid, err = validate_markdown_buffer(buffer_id)
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
-- @param filename string
-- @return number, number, number|nil -- year, month, day or nil if invalid
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
-- @param date_string string in YYYY-MM-DD format
-- @param days number of days to subtract
-- @return string|nil -- new date in YYYY-MM-DD format or nil if invalid
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
-- @param current_file string -- current filename (YYYY-MM-DD.md)
-- @param dir string -- directory path
-- @return string|nil -- previous filename or nil if not found
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

--- Extract checkbox items with their full text content
-- @param lines string[]
-- @param buffer_id number|nil
-- @return table[] -- array of {text, status, indent} items
local function extract_checkbox_items(lines, buffer_id)
  if not lines then
    return {}
  end

  local items = {}
  for idx, line in ipairs(lines) do
    local status = detect_status(line)
    if status then
      local indent = #(line:match("^(%s*)") or "")
      -- Extract the text content after the checkbox
      local text = line:match("%[.%]%s*(.*)") or ""
      table.insert(items, {
        text = text,
        status = status,
        indent = indent,
        line_num = idx,
        full_line = line,
      })
    end
  end

  return items
end

--- Compare current and previous items to find changes and additions
-- @param current_items table[]
-- @param previous_items table[]
-- @return table[] -- changes with type: "new", "status_change", or "new_with_status"
local function find_changes(current_items, previous_items)
  if not current_items then
    return {}
  end

  if not previous_items or #previous_items == 0 then
    -- All current items are new
    local changes = {}
    for _, item in ipairs(current_items) do
      if item.text and item.text ~= "" then
        table.insert(changes, {
          text = item.text,
          status = item.status,
          indent = item.indent,
          type = "new",
          change_type = "added",
        })
      end
    end
    return changes
  end

  local changes = {}
  local prev_items_map = {}

  -- Create a map of previous item texts to their status
  for _, prev_item in ipairs(previous_items) do
    if prev_item.text and prev_item.text ~= "" then
      prev_items_map[prev_item.text:lower()] = prev_item
    end
  end

  -- Check each current item
  for _, curr_item in ipairs(current_items) do
    if curr_item.text and curr_item.text ~= "" then
      local normalized_text = curr_item.text:lower()
      local prev_item = prev_items_map[normalized_text]

      if not prev_item then
        -- This is a new item
        table.insert(changes, {
          text = curr_item.text,
          status = curr_item.status,
          indent = curr_item.indent,
          type = "new",
          change_type = "added",
        })
      elseif prev_item.status ~= curr_item.status then
        -- This item exists but status changed
        table.insert(changes, {
          text = curr_item.text,
          status = curr_item.status,
          prev_status = prev_item.status,
          indent = curr_item.indent,
          type = "status_change",
          change_type = "status_changed",
        })
      end
    end
  end

  return changes
end

--- Get action description based on status change
-- @param from_status string|nil
-- @param to_status string
-- @return string
local function get_action_description(from_status, to_status)
  if not from_status then
    -- New item
    if to_status == "done" then
      return "Added and completed"
    elseif to_status == "progress" then
      return "Added and started"
    else
      return "Added"
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
-- @param lines table -- document lines
-- @param previous_date string -- the previous date to look for
-- @return number|nil, number|nil -- start_line, end_line (1-based) or nil if not found
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
-- @param lines table -- current document lines
-- @param new_section_lines table -- new section content
-- @param previous_date string -- previous date for section matching
-- @return table -- updated document lines
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
-- @param changes table[]
-- @param previous_date string|nil
-- @return table -- lines to insert
local function format_changes_section(changes, previous_date)
  local lines = {}
  table.insert(lines, "## Changes since " .. (previous_date or "previous day"))
  table.insert(lines, "")

  if not changes or #changes == 0 then
    table.insert(lines, "No changes found since " .. (previous_date or "previous day"))
  else
    for _, change in ipairs(changes) do
      local prefix = string.rep("  ", math.floor(change.indent / 2)) -- Convert spaces to readable indentation
      local action = get_action_description(change.prev_status, change.status)
      table.insert(lines, prefix .. "- " .. action .. " " .. change.text)
    end
  end

  return lines
end

--- Compare the current daily file with the previous day's file
-- @param buffer_id number|nil
-- @return boolean -- success
function M.compare_daily_changes(buffer_id)
  buffer_id = buffer_id or 0
  local valid, err = validate_markdown_buffer(buffer_id)
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
  local current_items = extract_checkbox_items(current_lines, buffer_id)

  -- Read previous file content
  local prev_lines = vim.fn.readfile(prev_path)
  local previous_items = extract_checkbox_items(prev_lines, nil)

  -- Find changes (new items and status changes)
  local changes = find_changes(current_items, previous_items)

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

-- Expose utility functions for testing
M._detect_status = detect_status
M._replace_box = replace_box
M._parse_items = parse_markdown_items_cached
M._config = config

return M
