return {
  {
    "simrat39/symbols-outline.nvim",
    cmd = "SymbolsOutline",
    keys = { { "<leader>us", "<cmd>SymbolsOutline<cr>", desc = "Symbols Outline" } },
    config = true,
    opts = {
      symbols = {
        Function = { icon = "󰊕", hl = "@function" },
      },
    },
  },
}
