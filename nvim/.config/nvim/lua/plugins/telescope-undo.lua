return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "debugloop/telescope-undo.nvim",
    },
    config = function()
      require("telescope").setup({
        extensions = {
          undo = {
            -- side_by_side = true,
            -- layout_strategy = "vertical",
            -- layout_config = {
            --   preview_height = 0.8,
            -- },
          },
        },
      })
      require("telescope").load_extension("undo")
    end,
    -- keys = {
    --   { "<leader>uu", require("telescope").extensions.undo.undo(), desc = "Undo history" },
    -- },
  },
}
