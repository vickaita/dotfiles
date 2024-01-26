-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Bash/Shell
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "bash", "sh" },
  command = "setlocal shiftwidth=4 tabstop=4",
})

-- gitcommit
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "gitcommit" },
  command = "setlocal spell shiftwidth=4 tabstop=8 expandtab softtabstop=4",
})

-- JavaScript/TypeScript
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascript", "typescript" },
  command = "setlocal textwidth=80 shiftwidth=2 tabstop=2",
})

-- Make
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "make", "Makefile" },
  command = "setlocal noexpandtab tabstop=8 shiftwidth=8",
})

-- Python
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python" },
  command = "setlocal textwidth=79 shiftwidth=4 tabstop=4",
})

-- Vimwiki
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "vimwiki", "wiki" },
  command = "setlocal textwidth=80 shiftwidth=4 tabstop=4",
})

-- Automatically set the colorcolumn based on textwidth
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  callback = function()
    -- Try to set the colorcolumn automatically based on textwidth, but only if
    -- textwidth is already set to a value greater than 0
    if vim.o.textwidth > 0 then
      vim.o.colorcolumn = tostring(vim.o.textwidth + 1)
    end
  end,
})
