-- Remap Ctrl-Z to use nvim's :suspend command for better terminal state handling
-- This is especially important when using terminal multiplexers like Zellij
vim.keymap.set("n", "<C-z>", "<cmd>suspend<cr>", { desc = "Suspend nvim properly" })
