return {
  {
    "MeanderingProgrammer/markdown.nvim",
    name = "render-markdown",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    config = function()
      require("render-markdown").setup({
        -- Enable concealment for markdown syntax
        concealment = {
          enabled = true,
          -- Only conceal when cursor is not on the line
          only_when_cursor_is_off_line = true,
        },
        -- Highlight settings
        highlights = {
          heading = {
            -- Background colors for headers
            -- backgrounds = { "RenderMarkdownH1Bg", "RenderMarkdownH2Bg" },
            -- Foreground colors for headers
            foregrounds = {
              "RenderMarkdownH1",
              "RenderMarkdownH2",
              "RenderMarkdownH3",
              "RenderMarkdownH4",
              "RenderMarkdownH5",
              "RenderMarkdownH6",
            },
          },
          -- Code block highlighting
          code = "RenderMarkdownCode",
          -- Bullet point highlighting
          bullet = "RenderMarkdownBullet",
        },
        heading = {
          enabled = false,
        },
        -- Code block settings
        code = {
          -- Show language name in code blocks
          sign = true,
          -- Width of the code block
          width = "block",
          -- Minimum width for code blocks
          min_width = 60,
          -- Border around code blocks
          border = "thin",
        },
        -- Checkbox settings
        checkbox = {
          enabled = false,
          -- Custom checkboxes
          custom = {
            todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
          },
        },
        -- Bullet point settings
        bullet = {
          -- Enable bullet point rendering
          enabled = false,
          -- Different icons for different levels
          -- icons = { "●", "○", "◆", "◇" },
          icons = { "∙" },
        },
      })
    end,
    ft = { "markdown", "md" },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "markdown",
        "markdown_inline",
      })
      return opts
    end,
  },
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "markdown-oxide" })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.markdown_oxide = {
        capabilities = {
          workspace = {
            didChangeWatchedFiles = {
              dynamicRegistration = true,
            },
          },
        },
        on_attach = function(client, bufnr)
          -- Refresh codelens on TextChanged and InsertLeave events
          vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave", "CursorHold", "LspAttach" }, {
            buffer = bufnr,
            callback = function()
              if client.supports_method("textDocument/codeLens") then
                vim.lsp.codelens.refresh()
              end
            end,
          })
        end,
      }
    end,
  },
}
