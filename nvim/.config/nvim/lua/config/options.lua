-- don't sync with clipboard by default
vim.opt.clipboard = ""

vim.opt.colorcolumn = "+1"
vim.opt.mouse = "a"

-- enable automatic text wrapping
vim.o.formatoptions = vim.o.formatoptions .. "t"
vim.opt.textwidth = 80

-- configure line wrapping
-- only configures line wrapping, but you need to `set wrap`
-- to enable it in the current buffer; by default, it is off
-- and only configured for certain file types, see autocmds.lua
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.showbreak = "↳ "

vim.opt.listchars = { tab = "→ ", trail = "⋅" }
vim.opt.list = true

-- don't use relative line numbers by default
vim.opt.number = true
vim.opt.relativenumber = false

-- open vertical splits to the right
vim.opt.splitright = true

-- spell file configuration
-- First file (local): machine-specific words (not committed)
-- Second file (committed): shared words across all machines
-- zg adds to the first writable file in the list
local data_dir = vim.fn.stdpath("data")
vim.opt.spellfile = {
  data_dir .. "/spell/en.utf-8.add", -- local dictionary (per-machine)
  vim.fn.stdpath("config") .. "/spell/en.utf-8.add", -- shared dictionary (committed)
}