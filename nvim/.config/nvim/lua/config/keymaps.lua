-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Remove some LazyVim keymaps that I don't use
-- --------------------------------------------

-- This was added to the default keymaps by LazyVim to
-- "Search word under cursor", but it conflicts with format text.
vim.keymap.del({ "n", "x" }, "gw")

-- LazyVim adds these keymaps for moving between windows, but I don't use them
-- vim.keymap.del({ "n" }, "<C-h>")
-- vim.keymap.del({ "n" }, "<C-j>")
-- vim.keymap.del({ "n" }, "<C-k>")
-- vim.keymap.del({ "n" }, "<C-l>")

-- Add some new keymaps
-- --------------------

vim.keymap.set({ "n", "x" }, "<leader>ci", function()
  if vim.lsp.buf.server_ready() then
    vim.diagnostic.open_float()
  end
end, { desc = "Show diagnostics" })
