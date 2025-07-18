return {
  {
    "Wansmer/treesj",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("treesj").setup({
        use_default_keybindings = false,
      })
    end,
    keys = {
      {
        "<leader>ct",
        function()
          require("treesj").toggle()
        end,
        desc = "Toggle Split/Join",
      },
      {
        "<leader>cj",
        function()
          require("treesj").join()
        end,
        desc = "Join",
      },
      {
        "<leader>cs",
        function()
          require("treesj").split()
        end,
        desc = "Split",
      },
    },
  },
}
