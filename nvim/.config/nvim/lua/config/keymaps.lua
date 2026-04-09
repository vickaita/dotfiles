-- Remap Ctrl-Z to use nvim's :suspend command for better terminal state handling
-- This is especially important when using terminal multiplexers like Zellij
vim.keymap.set("n", "<C-z>", "<cmd>suspend<cr>", { desc = "Suspend nvim properly" })

-- Send visual selection to the agent pane (Zellij side-by-side layout)
-- Targets whichever pane is active in the configured direction (default: right).
-- In a pane stack, this means the last-focused pane in that stack.
-- Override direction with: vim.g.agent_direction = "left" | "right" | "up" | "down"
local function send_selection_to_agent()
  if not vim.env.ZELLIJ_SESSION_NAME then
    vim.notify("Not running inside Zellij", vim.log.levels.WARN)
    return
  end

  -- '< and '> are only set on visual mode EXIT, but this callback fires while still in
  -- visual mode. Use "v" (anchor) and "." (cursor) which work during visual mode.
  local start_line = vim.fn.line("v")
  local end_line   = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  local filepath = vim.fn.expand("%:p")
  local lines    = vim.fn.getline(start_line, end_line)
  local ft         = vim.bo.filetype

  local content = string.format(
    "File: %s (lines %d-%d)\n```%s\n%s\n```\n",
    filepath, start_line, end_line, ft, table.concat(lines, "\n")
  )

  local direction = vim.g.agent_direction or "right"

  -- Table form passes args directly to the OS — no shell, no escaping issues
  vim.fn.system({ "zellij", "action", "move-focus", direction })
  vim.fn.system({ "zellij", "action", "write-chars", content })
end

vim.keymap.set("v", "<leader>as", send_selection_to_agent, { desc = "Send to agent" })
