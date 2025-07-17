-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- import your plugins
    { import = "plugins" },
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "duskfox" } },
  -- automatically check for plugin updates
  checker = { enabled = true },
})

-- local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
-- if not vim.loop.fs_stat(lazypath) then
--   -- bootstrap lazy.nvim
--   -- stylua: ignore
--   vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
-- end
-- vim.opt.rtp:prepend(vim.env.LAZY or lazypath)
--
-- require("lazy").setup({
--   spec = {
--     -- from init.lua
--     { "folke/lazy.nvim", version = "*" },
--     -- {
--     --   "folke/snacks.nvim",
--     --   priority = 1000,
--     --   lazy = false,
--     --   opts = {},
--     --   config = function(_, opts)
--     --     local notify = vim.notify
--     --     require("snacks").setup(opts)
--     --     -- HACK: restore vim.notify after snacks setup and let noice.nvim take over
--     --     -- this is needed to have early notifications show up in noice history
--     --     if LazyVim and LazyVim.has and LazyVim.has("noice.nvim") then
--     --       vim.notify = notify
--     --     end
--     --   end,
--     -- },
--
--     -- -- from compat/nvim-0_9.lua
--     -- { "garymjr/nvim-snippets", enabled = false },
--     -- { "akinsho/bufferline.nvim", enabled = false },
--     -- { "folke/flash.nvim", enabled = false },
--     { "folke/which-key.nvim", enabled = false },
--     -- { "folke/legendary.nvim", enabled = false },
--     -- { "folke/edgy.nvim", enabled = false },
--     -- { "folke/minitest.nvim", enabled = false },
--     -- { "folke/neo-tree.nvim", enabled = false },
--     -- { "folke/tokyonight.nvim", enabled = false },
--     -- { "nvim-treesitter/nvim-treesitter", enabled = false },
--
--     -- -- from coding.lua
--     -- { "mhartington/formatter.nvim" },
--     -- { "smjonas/inc-rename.nvim" },
--     -- { "zbirenbaum/copilot.lua" },
--     -- { "zbirenbaum/copilot-cmp" },
--     -- { "gbprod/yanky.nvim" },
--     -- { "nvim-treesitter/nvim-treesitter-textobjects" },
--     -- { "nvim-treesitter/playground" },
--     -- { "lewis6991/gitsigns.nvim" },
--     -- { "windwp/nvim-ts-autotag" },
--     -- { "JoosepAlviste/nvim-ts-context-commentstring" },
--
--     -- -- from colorscheme.lua
--     { "EdenEast/nightfox.nvim" },
--     { "catppuccin/nvim", name = "catppuccin" },
--     { "folke/tokyonight.nvim", config = true },
--
--     -- -- from editor.lua
--     -- { "kevinhwang91/nvim-ufo" },
--     -- { "kevinhwang91/promise-async" },
--     -- { "echasnovski/mini.pairs" },
--     -- { "echasnovski/mini.surround" },
--     -- { "echasnovski/mini.comment" },
--     -- { "echasnovski/mini.files" },
--     -- { "ojroques/nvim-osc52" },
--     -- { "nvim-lua/plenary.nvim" },
--     { "nvim-tree/nvim-tree.lua" },
--     -- { "akinsho/bufferline.nvim" },
--     -- { "nvim-lualine/lualine.nvim" },
--
--     -- -- from formatting.lua
--     -- { "jose-elias-alvarez/null-ls.nvim" },
--     -- { "jay-babu/mason-null-ls.nvim" },
--
--     -- -- from linting.lua
--     -- { "mfussenegger/nvim-lint" },
--     -- { "linty-org/key-menu.nvim" },
--
--     -- -- from treesitter.lua
--     -- { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
--     -- { "nvim-treesitter/nvim-treesitter-context" },
--     -- { "nvim-treesitter/nvim-treesitter-refactor" },
--
--     -- -- from ui.lua
--     -- { "nvim-neo-tree/neo-tree.nvim" },
--     -- { "stevearc/dressing.nvim" },
--     -- { "nvim-lua/plenary.nvim" },
--     -- { "MunifTanjim/nui.nvim" },
--     -- { "folke/noice.nvim" },
--     -- { "rcarriga/nvim-notify" },
--     -- { "akinsho/bufferline.nvim" },
--     -- { "famiu/bufdelete.nvim" },
--
--     -- -- from util.lua
--     -- { "nvim-lua/plenary.nvim", lazy = true },
--
--     -- -- from lsp/init.lua
--     -- --  { "neovim/nvim-lspconfig", event = "LazyFile", dependencies = { "mason.nvim", { "williamboman/mason-lspconfig.nvim", config = function() end } }, opts = function() /* omitted for brevity */ end },
--
--     -- -- Extras
--     -- -- from extras/ai/copilot.lua
--     -- { "zbirenbaum/copilot.lua", cmd = "Copilot", event = "VimEnter", opts = {} },
--     -- -- from extras/ai/copilot-chat.lua
--     -- { "zbirenbaum/copilot-chat.nvim", cmd = "CopilotChat", dependencies = { "zbirenbaum/copilot.lua" }, opts = {} },
--     -- -- from extras/coding/yanky.lua
--     -- { "gbprod/yanky.nvim", keys = "yank" },
--     -- -- from extras/dap/core.lua
--     -- {
--     --   "mfussenegger/nvim-dap",
--     --   config = function()
--     --     require("dap").setup()
--     --   end,
--     -- },
--     -- -- from extras/dap/nlua.lua
--     -- { "mfussenegger/nvim-dap-python", ft = "python", opts = {} },
--     -- -- from extras/formatting/prettier.lua
--     -- { "jose-elias-alvarez/null-ls.nvim", ft = { "javascript", "typescript" }, opts = {} },
--     -- -- from extras/lang/docker.lua
--     -- { "stevearc/docker.nvim", cmd = "Docker" },
--     -- -- from extras/lang/elixir.lua
--     -- { "elixir-tools/elixir-tools.nvim", ft = "elixir" },
--     -- -- from extras/lang/rust.lua
--     -- { "simrat39/rust-tools.nvim", ft = "rust" },
--     -- -- from extras/lang/tailwind.lua
--     -- {
--     --   "akinsho/toggleterm.nvim",
--     --   config = function()
--     --     require("toggleterm").setup({})
--     --   end,
--     -- },
--     -- -- from extras/lang/terraform.lua
--     -- { "hashivim/vim-terraform", ft = "terraform" },
--     -- -- from extras/lang/typescript.lua
--     -- { "jose-elias-alvarez/typescript.nvim", ft = { "typescript", "javascript" } },
--     -- -- from extras/linting/eslint.lua
--     -- { "mfussenegger/nvim-lint", ft = { "javascript", "typescript" } },
--     -- -- from extras/test/core.lua
--     -- { "nvim-neotest/neotest", ft = "test" },
--   },
--   defaults = { lazy = true, version = "*" },
--   install = { colorscheme = { "catppuccin", "tokyonight" } },
--   checker = { enabled = true },
--   performance = { rtp = { disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" } } },
-- })
