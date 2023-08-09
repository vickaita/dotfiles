return {
  {
    "tpope/vim-eunuch",
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "bash-language-server",
        "shellcheck",
        "shellharden",
        "shfmt",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {},
      },
    },
  },
  {
    "jose-elias-alvarez/null-ls.nvim",
    opts = function(_, opts)
      local nls = require("null-ls")
      table.insert(opts.sources, nls.builtins.formatting.shellharden)
      table.insert(
        opts.sources,
        nls.builtins.formatting.shfmt.with({
          extra_args = { "--indent", "4" },
        })
      )
      table.insert(opts.sources, nls.builtins.diagnostics.shellcheck)
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
      },
    },
  },
}
