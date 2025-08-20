-- Configuration for markdown checkbox processing
local M = {}

--- Configuration for checkbox symbols and patterns
M.config = {
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

return M

