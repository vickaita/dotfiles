if vim.g.vscode then
  return {}
end

return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = { python = { "ruff_fix", "isort", "black" } },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "black",
        "isort",
        "ruff",
        "ruff_fix",
      },
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "pyright",
      },
    },
  },
  -- {
  --   "nvim-treesitter/nvim-treesitter",
  --   opts = function(_, opts)
  --     vim.list_extend(opts.ensure_installed, {
  --       "python",
  --     })
  --   end,
  -- },
}
