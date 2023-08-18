-- set vimwiki path from an environment variable with a fallback of "~/wiki/"
vim.g.vimwiki_list = { { path = vim.env.VIMWIKI_PATH or "~/wiki/" } }

return {
  {
    "vimwiki/vimwiki",
    dependencies = { "folke/which-key.nvim" },
    ft = { "vimwiki" },
    keys = {
      { "<leader>v", desc = "+vimwiki" },
      { "<leader>vd", desc = "+diary" },
      { "<leader>vw", "<cmd>VimwikiIndex<cr>", desc = "Vimwiki index" },
      { "<leader>vdi", "<cmd>VimwikiDiaryIndex<cr>", desc = "Vimwiki diary index" },
      { "<leader>vdg", "<cmd>VimwikiDiaryGenerateLinks<cr>", desc = "Vimwiki diary generate links" },
      { "<leader>vdd", "<cmd>VimwikiMakeDiaryNote<cr>", desc = "Vimwiki current date diary note" },
      { "<leader>vdy", "<cmd>VimwikiMakeYesterdayDiaryNote<cr>", desc = "Vimwiki yesterday diary note" },
      { "<leader>vdt", "<cmd>VimwikiMakeTomorrowDiaryNote<cr>", desc = "Vimwiki tomorrow diary note" },
    },
  },
}
