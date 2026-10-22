local M = {}

function M.edit_selection(opts)
  opts = opts or {}
  local provider = opts.provider or "codex"
  local label = provider == "claude" and ("Claude (" .. opts.model .. ")") or "Codex"
  local function notify(message, level)
    vim.notify(label .. ": " .. message, level or vim.log.levels.INFO)
  end
  local mode = vim.fn.mode()
  if mode == "\22" then
    notify("block selections are not supported; use character or line selection", vim.log.levels.WARN)
    return
  end
  if mode ~= "v" and mode ~= "V" then
    notify("select text first", vim.log.levels.WARN)
    return
  end
  if vim.fn.executable(provider) ~= 1 then
    notify(provider .. " CLI is not on PATH", vim.log.levels.ERROR)
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  if not vim.bo[buf].modifiable then
    notify("buffer is not modifiable", vim.log.levels.WARN)
    return
  end
  -- Live visual positions are needed: '< and '> still refer to the previous selection.
  -- getregionpos handles reversed selections, 'selection=exclusive', and UTF-8 bytes.
  local regions = vim.fn.getregionpos(vim.fn.getpos("v"), vim.fn.getpos("."), {
    type = mode,
    exclusive = vim.o.selection == "exclusive",
  })
  local first, last = regions[1][1], regions[#regions][2]
  local start_row, start_col = first[2] - 1, first[3] - 1
  local end_row, end_col = last[2] - 1, last[3]
  local selected = mode == "V" and vim.api.nvim_buf_get_lines(buf, start_row, end_row + 1, false)
    or vim.api.nvim_buf_get_text(buf, start_row, start_col, end_row, end_col, {})
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local context = {
    file = vim.api.nvim_buf_get_name(buf),
    filetype = vim.bo[buf].filetype,
    buffer = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"),
    selection = table.concat(selected, "\n"),
    start_line = start_row + 1,
    end_line = end_row + 1,
    start_byte_column = start_col + 1,
    end_byte_column = end_col,
  }
  local cwd = context.file ~= "" and vim.fs.dirname(context.file) or vim.fn.getcwd()
  vim.cmd("normal! " .. string.char(27))

  vim.ui.input({ prompt = label .. " instruction: " }, function(instruction)
    if not instruction or vim.trim(instruction) == "" then return end
    if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_buf_get_changedtick(buf) ~= tick then
      notify("buffer changed; select the text again", vim.log.levels.WARN)
      return
    end
    context.instruction = instruction
    local schema_path, output_path = vim.fn.tempname(), vim.fn.tempname()
    local function cleanup()
      vim.fn.delete(schema_path)
      vim.fn.delete(output_path)
    end
    local ok, err = pcall(function()
      local schema = vim.json.encode({
        type = "object",
        properties = { replacement = { type = "string" } },
        required = { "replacement" },
        additionalProperties = false,
      })
      local command
      if provider == "claude" then
        command = {
          "claude", "--print",
          "--model", opts.model,
          "--output-format", "json",
          "--json-schema", schema,
          "--tools", "",
          "--strict-mcp-config", "--mcp-config", '{"mcpServers":{}}',
          "--permission-mode", "dontAsk",
          "--no-session-persistence",
        }
      else
        vim.fn.writefile({ schema }, schema_path)
        command = {
          "codex", "-a", "never", "exec",
          "--sandbox", "read-only",
          "--skip-git-repo-check",
          "--ephemeral",
          "--color", "never",
          "--output-schema", schema_path,
          "--output-last-message", output_path,
          "-",
        }
      end
      local prompt = table.concat({
        "Edit the selected code according to the instruction in the JSON below.",
        "Return only a JSON object with a replacement string containing the exact replacement text.",
        "Preserve indentation. Do not add Markdown fences or explanations.",
        "The replacement replaces only the selection, so preserve any surrounding code.",
        "Use the full unsaved buffer as context. Do not edit files or run commands.",
        vim.json.encode(context),
      }, "\n")
      notify("editing selection…")
      vim.system(command, { cwd = cwd, stdin = prompt, text = true, timeout = 180000 }, function(result)
        vim.schedule(function()
          local read_ok, response = pcall(function()
            if provider == "claude" then
              return vim.json.decode(result.stdout or "")
            end
            return vim.json.decode(table.concat(vim.fn.readfile(output_path), "\n"))
          end)
          cleanup()
          if result.code ~= 0 then
            local detail = vim.trim(result.stderr or "")
            if detail == "" and read_ok and type(response) == "table" then
              detail = tostring(response.result or response.subtype or "")
            end
            notify("edit failed: " .. detail .. " (exit " .. result.code .. ")", vim.log.levels.ERROR)
            return
          end
          if provider == "claude" and read_ok and type(response) == "table" then
            if response.is_error then
              notify("edit failed: " .. tostring(response.result or response.subtype or "Claude error"), vim.log.levels.ERROR)
              return
            end
            response = response.structured_output
          end
          if not read_ok or type(response) ~= "table" or type(response.replacement) ~= "string" then
            notify("invalid replacement returned by model", vim.log.levels.ERROR)
            return
          end
          if not vim.api.nvim_buf_is_loaded(buf) then
            notify("original buffer was closed; edit discarded", vim.log.levels.WARN)
            return
          end
          if vim.api.nvim_buf_get_changedtick(buf) ~= tick or not vim.bo[buf].modifiable then
            notify("buffer changed while editing; edit discarded, select the text again", vim.log.levels.WARN)
            return
          end
          local replacement = response.replacement == "" and {} or vim.split(response.replacement, "\n", { plain = true })
          vim.api.nvim_buf_call(buf, function()
            -- Close the previous undo block so one `u` restores the selection.
            vim.cmd("let &undolevels = &undolevels")
            if mode == "V" then
              vim.api.nvim_buf_set_lines(buf, start_row, end_row + 1, false, replacement)
            else
              vim.api.nvim_buf_set_text(buf, start_row, start_col, end_row, end_col, replacement)
            end
          end)
          notify("selection updated (u to undo)")
        end)
      end)
    end)
    if not ok then
      cleanup()
      notify("could not start edit: " .. tostring(err), vim.log.levels.ERROR)
    end
  end)
end

return M
