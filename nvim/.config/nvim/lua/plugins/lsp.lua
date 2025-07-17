if vim.g.vscode then
  return {}
end

return {
  -- Setup Mason first
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = {
      ensure_installed = { "stylua" },
      ui = {
        icons = {
          server_installed = "✓",
          server_pending = "➜",
          server_uninstalled = "✗",
        },
      },
    },
  },

  -- Make sure LSP servers get auto-installed
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "mason.nvim" },
    opts_extend = { "ensure_installed" }, -- allows merging from other plugin files
    opts = {
      ensure_installed = {}, -- start empty, language files will add to this
    },
  },

  -- Integrate LSP with completion
  {
    "saghen/blink.cmp",
    dependencies = {
      "rafamadriz/friendly-snippets",
      "Kaiser-Yang/blink-cmp-dictionary",
    },
    version = "1.*",
    opts = {
      keymap = { preset = "default" },
      completion = {
        ghost_text = { enabled = true },
        list = { selection = { auto_insert = false } },
        documentation = { auto_show = true, window = { border = "rounded" } },
        menu = {
          draw = {
            padding = 0,
            columns = { { "kind_icon", gap = 1 }, { gap = 1, "label" }, { "kind", gap = 2 } },
            components = {
              kind_icon = {
                text = function(ctx)
                  return " " .. ctx.kind_icon .. " "
                end,
                highlight = function(ctx)
                  return "BlinkCmpKindIcon" .. ctx.kind
                end,
              },
              kind = {
                text = function(ctx)
                  return " " .. ctx.kind .. " "
                end,
              },
            },
          },
        },
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer", "dictionary", "copilot" },
        providers = {
          dictionary = {
            module = "blink-cmp-dictionary",
            min_keyword_length = 3,
          },
          copilot = {
            name = "copilot",
            module = "blink-cmp-copilot",
            score_offset = 100,
            async = true,
          },
        },
      },
      fuzzy = { implementation = "prefer_rust" },
    },
    opts_extend = { "sources.default" },
  },

  -- Actual LSP client
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- "folke/neodev.nvim",
      "mason.nvim",
      "mason-lspconfig.nvim",
    },
    opts_extend = { "servers" },
    opts = {
      -- this gets merged by language-specific files
      servers = {},
    },
    config = function(_, opts)
      -- get capabilities
      local capabilities = vim.tbl_deep_extend(
        "force",
        {},
        vim.lsp.protocol.make_client_capabilities(),
        require("blink.cmp").get_lsp_capabilities() or {}
      )

      -- Customize diagnostic signs
      vim.fn.sign_define("DiagnosticSignError", { text = "", texthl = "DiagnosticSignError" })
      vim.fn.sign_define("DiagnosticSignWarn", { text = "", texthl = "DiagnosticSignWarn" })
      vim.fn.sign_define("DiagnosticSignInfo", { text = "", texthl = "DiagnosticSignInfo" })
      vim.fn.sign_define("DiagnosticSignHint", { text = "", texthl = "DiagnosticSignHint" })

      -- always reserve two sign columns
      vim.o.signcolumn = "yes:2"

      -- setup each LSP server
      local lspconfig = require("lspconfig")
      for server, server_opts in pairs(opts.servers) do
        server_opts.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server_opts.capabilities or {})
        lspconfig[server].setup(server_opts)
      end
    end,
  },
}
