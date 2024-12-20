-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- don't sync with clipboard by default
vim.opt.clipboard = ""

vim.opt.colorcolumn = "81"
vim.opt.conceallevel = 0

-- enable automatic text wrapping
vim.o.formatoptions = vim.o.formatoptions .. "t"
vim.opt.textwidth = 80

vim.opt.listchars = { tab = "→ ", trail = "⋅" }

-- don't use relative line numbers by default
vim.opt.number = true
vim.opt.relativenumber = false

-- turn off animations
vim.g.snacks_animate = false
