-- Remap Ctrl-Z to use nvim's :suspend command for better terminal state handling
-- This is especially important when using terminal multiplexers like Zellij
vim.keymap.set("n", "<C-z>", "<cmd>suspend<cr>", { desc = "Suspend nvim properly" })

-- Send visual selection to the agent pane (Zellij or cmux side-by-side layout).
-- Zellij: targets the pane in the configured direction (default: right).
--   Override direction with: vim.g.agent_direction = "left" | "right" | "up" | "down"
-- cmux: targets the first surface in the workspace that is not the current one.
--   Override target with: vim.g.cmux_target_surface = "surface:2"
local function send_selection_to_agent()
  -- '< and '> are only set on visual mode EXIT, but this callback fires while still in
  -- visual mode. Use "v" (anchor) and "." (cursor) which work during visual mode.
  local start_line = vim.fn.line("v")
  local end_line   = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  local filepath = vim.fn.expand("%:p")
  local lines    = vim.fn.getline(start_line, end_line)
  local ft       = vim.bo.filetype

  local content = string.format(
    "File: %s (lines %d-%d)\n```%s\n%s\n```\n",
    filepath, start_line, end_line, ft, table.concat(lines, "\n")
  )

  if vim.env.ZELLIJ_SESSION_NAME then
    local direction = vim.g.agent_direction or "right"
    -- Table form passes args directly to the OS — no shell, no escaping issues
    vim.fn.system({ "zellij", "action", "move-focus", direction })
    vim.fn.system({ "zellij", "action", "write-chars", content })

  elseif vim.env.CMUX_SURFACE_ID then
    local target = vim.g.cmux_target_surface
    if not target then
      -- Find the first non-focused pane (the focused pane is marked with "*")
      local panes_out = vim.fn.system({ "cmux", "list-panes" })
      local other_pane
      for line in panes_out:gmatch("[^\n]+") do
        if not line:match("^%*") then
          other_pane = line:match("(pane:%d+)")
          if other_pane then break end
        end
      end
      if not other_pane then
        vim.notify("cmux: no other pane found", vim.log.levels.WARN)
        return
      end
      -- Pick the [selected] surface in that pane, or fall back to the first
      local surfs_out = vim.fn.system({ "cmux", "list-pane-surfaces", "--pane", other_pane })
      local first_surf, selected_surf
      for line in surfs_out:gmatch("[^\n]+") do
        local surf = line:match("(surface:%d+)")
        if surf then
          if not first_surf then first_surf = surf end
          if line:match("%[selected%]") then selected_surf = surf end
        end
      end
      target = selected_surf or first_surf
    end
    if not target then
      vim.notify("cmux: no surface found in adjacent pane", vim.log.levels.WARN)
      return
    end
    vim.fn.system({ "cmux", "send", "--surface", target, content })

  else
    vim.notify("Not running inside Zellij or cmux", vim.log.levels.WARN)
  end
end

vim.keymap.set("v", "<leader>as", send_selection_to_agent, { desc = "Send to agent" })
