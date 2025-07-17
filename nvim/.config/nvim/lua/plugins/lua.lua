-- plugins/lua.lua
if vim.g.vscode then
  return {}
end

return {
  -- 1) stylua in Conform
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.lua = opts.formatters_by_ft.lua or {}
      vim.list_extend(opts.formatters_by_ft.lua, { "stylua" })
      return opts
    end,
  },

  -- 2) stylua in Mason
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "stylua" })
      return opts
    end,
  },

  -- 3) lua_ls in mason-lspconfig
  {
    "williamboman/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "lua_ls" })
      return opts
    end,
  },

  -- 4) lua_ls settings in nvim-lspconfig
  {
    "neovim/nvim-lspconfig",
    dependencies = { "folke/neodev.nvim" },
    opts = function(_, opts)
      -- ensure the top-level `servers` table exists
      opts.servers = opts.servers or {}

      -- merge our lua_ls config into whatever was already there
      opts.servers.lua_ls = vim.tbl_deep_extend("force", opts.servers.lua_ls or {}, {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
            telemetry = { enable = false },
          },
        },
      })

      return opts
    end,
  },
}
