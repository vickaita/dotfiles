local colorscheme = os.getenv("NEOVIM_COLORSCHEME") or "duskfox"

-- check to see if the colorscheme contains the word "light" or "solarized"
if colorscheme:match("light") or colorscheme:match("solarized") then
  vim.o.background = "light"
end

return {
  {
    "EdenEast/nightfox.nvim",
    lazy = false, -- make sure we load this during startup
    priority = 1000, -- make sure to load this before all the other plugins
    config = function()
      -- load the colorscheme here
      vim.cmd([[colorscheme duskfox]])
    end,
  },
  -- { "catppuccin/nvim" },
  -- { "ellisonleao/gruvbox.nvim" },
  -- { "embark-theme/vim" },
  -- { "folke/tokyonight.nvim", lazy = false, priority = 1000, opts = {} },
  -- { "ishan9299/nvim-solarized-lua" },
  -- { "lifepillar/vim-solarized8" },
  -- { "rafamadriz/neon" },
  -- { "sainnhe/everforest" },
  -- { "sainnhe/sonokai" },
}
