-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.colorcolumn = "81"
vim.opt.conceallevel = 0
vim.opt.listchars = { tab = "▸ ", trail = "•" }

-- don't use relative line numbers by default
vim.opt.number = true
vim.opt.relativenumber = false

-- don't show tabs by default, but it can be toggled with <leader>ut
vim.opt.showtabline = 0
