-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Bash/Shell
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "bash", "sh" },
  command = "setlocal shiftwidth=4 tabstop=4",
})

-- Make
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "make", "Makefile" },
  command = "setlocal noexpandtab tabstop=8 shiftwidth=8",
})

-- Vimwiki
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "vimwiki", "wiki" },
  command = "setlocal textwidth=80 shiftwidth=4 tabstop=4",
})

-- Automatically set the colorcolumn based on textwidth
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  callback = function()
    vim.o.colorcolumn = tostring(vim.o.textwidth + 1)
  end,
})
