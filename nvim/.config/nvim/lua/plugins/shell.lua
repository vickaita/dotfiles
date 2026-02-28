if vim.g.vscode then
  return {}
end

return {
  {
    "tpope/vim-eunuch",
  },
  {
    "williamboman/mason.nvim",
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "bash-language-server",
        "shellcheck", 
        "shellharden",
        "shfmt",
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    optional = true,
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.bashls = {}
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.sh = { "shellharden", "shfmt" }
      opts.formatters_by_ft.bash = { "shellharden", "shfmt" }
    end,
  },
  -- {
  --   "jose-elias-alvarez/none-ls.nvim",
  --   opts = function(_, opts)
  --     local nls = require("null-ls")
  --     table.insert(opts.sources, nls.builtins.formatting.shellharden)
  --     table.insert(
  --       opts.sources,
  --       nls.builtins.formatting.shfmt.with({
  --         extra_args = { "--indent", "4" },
  --       })
  --     )
  --     table.insert(opts.sources, nls.builtins.diagnostics.shellcheck)
  --   end,
  -- },
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "bash" })
    end,
  },
}
