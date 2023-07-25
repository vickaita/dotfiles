vim.g.vimwiki_list = { { path = "~/wiki/" } }

return {
  {
    "vimwiki/vimwiki",
    keys = {
      { "<leader>vw", "<cmd>VimwikiIndex<cr>", desc = "Vimwiki index" },
      { "<leader>vdi", "<cmd>VimwikiDiaryIndex<cr>", desc = "Vimwiki diary index" },
      { "<leader>vdg", "<cmd>VimwikiDiaryGenerateLinks<cr>", desc = "Vimwiki diary generate links" },
      { "<leader>vdd", "<cmd>VimwikiMakeDiaryNote<cr>", desc = "Vimwiki current date diary note" },
      { "<leader>vdy", "<cmd>VimwikiMakeYesterdayDiaryNote<cr>", desc = "Vimwiki yesterday diary note" },
      { "<leader>vdt", "<cmd>VimwikiMakeTomorrowDiaryNote<cr>", desc = "Vimwiki tomrrow diary note" },
    },
  },
}
