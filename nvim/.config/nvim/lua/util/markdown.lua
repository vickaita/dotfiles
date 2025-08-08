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
  local ch = line:match("^[%s]*" .. config.bullet_pattern .. " +%[(.)%]") or 
             line:match("^[%s]*%d+%. +%[(.)%]")
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
    local bullet_match = line:match("^(%s*)" .. config.bullet_pattern .. " +") or 
                        line:match("^(%s*)%d+%. +")
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
            local parent_indent = (lines[item.sr + 1] or ""):match("^(%s*)" .. config.bullet_pattern .. " +") or
                                  (lines[item.sr + 1] or ""):match("^(%s*)%d+%. +") or ""
            local parent_indent_len = #parent_indent
            local has_incomplete_text = false
            for r = item.sr + 1, item.er do
              local l = lines[r + 1] or ""
              local ind, ch = l:match("^(%s*)" .. config.bullet_pattern .. " +%[(.)%]") or
                              l:match("^(%s*)%d+%. +%[(.)%]")
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
      local ind = line:match("^(%s*)" .. config.bullet_pattern .. " +%[[xX]%]") or
                  line:match("^(%s*)%d+%. +%[[xX]%]")
      if ind then
        local base = #ind
        local has_incomplete = false
        local j = i + 1
        while j <= #lines do
          local lj = lines[j]
          local lj_bullet_ind = lj:match("^(%s*)" .. config.bullet_pattern .. " +") or
                                lj:match("^(%s*)%d+%. +")
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
      to_remove[line_idx + 1] = true  -- Convert to 1-based for array access
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
    vim.notify("Opened existing today's note", vim.log.levels.INFO)
    return true
  end

  local lines = vim.api.nvim_buf_get_lines(buffer_id, 0, -1, false)

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
  vim.notify("Created today's note from current", vim.log.levels.INFO)
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
  vim.notify("Normalized checkboxes", vim.log.levels.INFO)
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
  vim.notify("Removed completed subtrees", vim.log.levels.INFO)
  return true
end

--- Carry over current note to today, normalize checkboxes, then remove completed subtrees.
--
-- Steps:
-- 1. `carry_over_today()`
-- 2. `normalize_checkboxes()`
-- 3. `remove_completed()`
--
-- @param buffer_id number|nil
-- @return boolean -- success
function M.carry_over_and_process(buffer_id)
  buffer_id = buffer_id or 0

  if not M.carry_over_today(buffer_id) then
    return false
  end

  -- After carry_over_today, the new buffer is opened (buffer 0)
  if not M.normalize_checkboxes(0) then
    return false
  end

  if not M.remove_completed(0) then
    return false
  end

  return true
end

-- Expose utility functions for testing
M._detect_status = detect_status
M._replace_box = replace_box
M._parse_items = parse_markdown_items_cached
M._config = config

return M
