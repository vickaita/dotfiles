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
        "<leader>m",
        desc = "+split/join",
      },
      {
        "<leader>mm",
        function()
          require("treesj").toggle()
        end,
        desc = "Toggle Split",
      },
      {
        "<leader>mj",
        function()
          require("treesj").join()
        end,
        desc = "Join",
      },
      {
        "<leader>ms",
        function()
          require("treesj").split()
        end,
        desc = "Split",
      },
    },
  },
}
