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
    config = function(_, opts)
      require("mason-lspconfig").setup(opts)
    end,
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

  -- Symbol highlighting
  {
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      providers = {
        "lsp",
        "treesitter",
        "regex",
      },
      delay = 120,
      filetype_overrides = {},
      filetypes_denylist = {
        "dirvish",
        "fugitive",
      },
      under_cursor = true,
      large_file_cutoff = nil,
      large_file_overrides = nil,
      min_count_to_highlight = 1,
    },
    config = function(_, opts)
      require("illuminate").configure(opts)
    end,
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
      vim.diagnostic.config({
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.INFO] = "",
            [vim.diagnostic.severity.HINT] = "",
          },
        },
      })

      -- always reserve two sign columns
      vim.o.signcolumn = "auto:2"

      -- LSP keymaps
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local opts = { buffer = ev.buf, silent = true }

          -- Enable document highlighting
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client and client.server_capabilities.documentHighlightProvider then
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = ev.buf,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = ev.buf,
              callback = vim.lsp.buf.clear_references,
            })
          end

          -- Code actions
          vim.keymap.set(
            "n",
            "<leader>cr",
            vim.lsp.buf.rename,
            vim.tbl_extend("force", opts, { desc = "Rename symbol" })
          )
          vim.keymap.set(
            "n",
            "<leader>ca",
            vim.lsp.buf.code_action,
            vim.tbl_extend("force", opts, { desc = "Code actions" })
          )
          vim.keymap.set(
            "n",
            "<leader>ch",
            vim.lsp.buf.signature_help,
            vim.tbl_extend("force", opts, { desc = "Signature help" })
          )
          vim.keymap.set(
            "n",
            "<leader>ci",
            function() require('util.lsp').incoming_calls_with_fzf({ jump1 = true }) end,
            vim.tbl_extend("force", opts, { desc = "Incoming calls" })
          )
          vim.keymap.set(
            "n",
            "<leader>co",
            function() require('util.lsp').outgoing_calls_with_fzf({ jump1 = true }) end,
            vim.tbl_extend("force", opts, { desc = "Outgoing calls" })
          )

          -- Navigation
          vim.keymap.set(
            "n",
            "gd",
            "<cmd>FzfLua lsp_definitions jump1=true<cr>",
            vim.tbl_extend("force", opts, { desc = "Go to definition" })
          )
          vim.keymap.set(
            "n",
            "gD",
            "<cmd>FzfLua lsp_declarations jump1=true<cr>",
            vim.tbl_extend("force", opts, { desc = "Go to declaration" })
          )
          vim.keymap.set(
            "n",
            "gi",
            "<cmd>FzfLua lsp_implementations jump1=true<cr>",
            vim.tbl_extend("force", opts, { desc = "Go to implementation" })
          )
          vim.keymap.set(
            "n",
            "gr",
            "<cmd>FzfLua lsp_references jump1=true<cr>",
            vim.tbl_extend("force", opts, { desc = "Go to references" })
          )
          vim.keymap.set(
            "n",
            "gt",
            "<cmd>FzfLua lsp_typedefs jump1=true<cr>",
            vim.tbl_extend("force", opts, { desc = "Go to type definition" })
          )
          vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover documentation" }))
          vim.keymap.set(
            "n",
            "<C-k>",
            vim.lsp.buf.signature_help,
            vim.tbl_extend("force", opts, { desc = "Signature help" })
          )

          -- Diagnostics
          vim.keymap.set(
            "n",
            "[d",
            vim.diagnostic.goto_prev,
            vim.tbl_extend("force", opts, { desc = "Previous diagnostic" })
          )
          vim.keymap.set(
            "n",
            "]d",
            vim.diagnostic.goto_next,
            vim.tbl_extend("force", opts, { desc = "Next diagnostic" })
          )
          vim.keymap.set(
            "n",
            "<leader>cd",
            vim.diagnostic.open_float,
            vim.tbl_extend("force", opts, { desc = "Show diagnostic" })
          )
          vim.keymap.set(
            "n",
            "<leader>cq",
            vim.diagnostic.setloclist,
            vim.tbl_extend("force", opts, { desc = "Diagnostics to loclist" })
          )
        end,
      })

      -- setup each LSP server
      local lspconfig = require("lspconfig")
      for server, server_opts in pairs(opts.servers) do
        server_opts.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server_opts.capabilities or {})
        lspconfig[server].setup(server_opts)
      end
    end,
  },
}
