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
        "<leader>mm",
        function()
          require("treesj").toggle()
        end,
        desc = "Toggle Treesitter Matching",
      },
      {
        "<leader>mj",
        function()
          require("treesj").join()
        end,
        desc = "Join Treesitter Matching",
      },
      {
        "<leader>ms",
        function()
          require("treesj").split()
        end,
        desc = "Split Treesitter Matching",
      },
    },
  },
}
