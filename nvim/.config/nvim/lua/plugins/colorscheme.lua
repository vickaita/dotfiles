local colorscheme = os.getenv("NEOVIM_COLORSCHEME") or "duskfox"

if colorscheme == "solarized8_flat" then
  vim.o.background = "light"
end

return {
  { "EdenEast/nightfox.nvim" },
  { "catppuccin/nvim" },
  { "ellisonleao/gruvbox.nvim" },
  { "embark-theme/vim" },
  { "folke/tokyonight.nvim", lazy = false, priority = 1000, opts = {} },
  { "lifepillar/vim-solarized8" },
  { "rafamadriz/neon" },
  { "sainnhe/everforest" },
  { "sainnhe/sonokai" },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = colorscheme,
    },
  },
}
