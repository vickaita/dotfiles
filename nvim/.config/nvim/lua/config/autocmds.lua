-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- set textwidth to 80 in vimwiki files
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "vimwiki", "wiki" },
  command = "setlocal textwidth=80 shiftwidth=4 tabstop=4",
})
