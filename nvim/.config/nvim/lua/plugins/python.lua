return {
  { import = "lazyvim.plugins.extras.lang.python" },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = { python = { "ruff_fix", "isort", "black" } },
    },
  },
}
