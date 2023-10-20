-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Remove some LazyVim keymaps that I don't use
-- --------------------------------------------

-- LazyVim adds these keymaps for moving between windows, but I don't use them
vim.keymap.del({ "n" }, "<C-h>")
vim.keymap.del({ "n" }, "<C-j>")
vim.keymap.del({ "n" }, "<C-k>")
vim.keymap.del({ "n" }, "<C-l>")

-- LazyVim adds these keymaps for moving between buffers, but I don't use them
vim.keymap.del({ "n" }, "<S-h>")
vim.keymap.del({ "n" }, "<S-l>")
