return {
  {
    "folke/neodev.nvim",
    -- lazy.nvim will call `require("neodev").setup(opts)` for you
    opts = {
      library = {
        enabled = true,
        runtime = true,
        types = true,
        plugins = true,
      },
      lspconfig = true,
      pathStrict = true,
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- make sure it's a table
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "vim",
        "vimdoc",
      })
      return opts
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "lua_ls",
      },
    },
  },
}
