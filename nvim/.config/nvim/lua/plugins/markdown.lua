if vim.g.vscode then
  return {}
end

-- set vimwiki path from an environment variable with a fallback of "~/wiki/"
vim.g.vimwiki_list = {
  {
    path = vim.env.VIMWIKI_PATH or "~/wiki/",
    syntax = "markdown",
    ext = ".md",
    diary_rel_path = "",
  },
}

return {
  {
    "vimwiki/vimwiki",
    dependencies = { "folke/which-key.nvim" },
    ft = { "vimwiki" },
    keys = {
      { "<leader>v", desc = "+vimwiki" },
      { "<leader>vd", desc = "+diary" },
      { "<leader>vw", "<cmd>VimwikiIndex<cr>", desc = "Vimwiki index" },
      { "<leader>vdi", "<cmd>VimwikiDiaryIndex<cr>", desc = "Vimwiki diary index" },
      { "<leader>vdg", "<cmd>VimwikiDiaryGenerateLinks<cr>", desc = "Vimwiki diary generate links" },
      { "<leader>vdd", "<cmd>VimwikiMakeDiaryNote<cr>", desc = "Vimwiki current date diary note" },
      { "<leader>vdy", "<cmd>VimwikiMakeYesterdayDiaryNote<cr>", desc = "Vimwiki yesterday diary note" },
      { "<leader>vdt", "<cmd>VimwikiMakeTomorrowDiaryNote<cr>", desc = "Vimwiki tomorrow diary note" },
    },
  },
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
            backgrounds = {},
          },
          -- Code block highlighting
          code = "RenderMarkdownCode",
          -- Bullet point highlighting
          bullet = "RenderMarkdownBullet",
        },
        heading = {
          sign = true,
          width = "block",
          -- min_width = 40,
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
        -- Bullet point settings
        bullet = {
          -- Enable bullet point rendering
          enabled = true,
          -- Different icons for different levels
          -- icons = { "●", "○", "◆", "◇" },
          icons = { "∙" },
        },
        -- Wiki link configuration for vimwiki
        link = {
          wiki = {
            icon = "󱗖 ",
            body = function()
              return nil
            end,
          },
        },
        -- Checkbox configuration
        checkbox = {
          enabled = true,
          bullet = true, -- Preserve bullet points with checkboxes
          -- Custom checkboxes for different states
          unchecked = { icon = "[ ]", highlight = "RenderMarkdownUnchecked" },
          checked = { icon = "[✖︎]", highlight = "RenderMarkdownDone" },
          custom = {
            todo = { raw = "[-]", rendered = "[⁃]", highlight = "RenderMarkdownInProgress" },
          },
        },
      })
    end,
    ft = { "markdown", "md", "vimwiki" },
  },
  {
    "jakewvincent/mkdnflow.nvim",
    ft = { "markdown", "md", "vimwiki" },
    config = function()
      require("mkdnflow").setup({
        -- Links and paths
        links = {
          style = "markdown",
          name_is_source = false,
          conceal = false,
          context = 0,
          implicit_extension = nil,
          transform_implicit = false,
          transform_explicit = function(text)
            text = text:gsub(" ", "-")
            text = text:lower()
            return text
          end,
        },
        -- To-do lists
        to_do = {
          symbols = { " ", "-", "X" }, -- [ ], [-], [X]
          update_parents = true,
          not_started = " ",
          in_progress = "-",
          complete = "X",
        },
        -- Mappings
        mappings = {
          MkdnEnter = { { "n", "v" }, "<CR>" },
          MkdnTab = false,
          MkdnSTab = false,
          MkdnNextLink = { "n", "<Tab>" },
          MkdnPrevLink = { "n", "<S-Tab>" },
          MkdnNextHeading = { "n", "]]" },
          MkdnPrevHeading = { "n", "[[" },
          MkdnGoBack = { "n", "<BS>" },
          MkdnGoForward = { "n", "<Del>" },
          MkdnCreateLink = false,
          MkdnCreateLinkFromClipboard = { { "n", "v" }, "<leader>p" },
          MkdnFollowLink = { "n", "<CR>" },
          MkdnDestroyLink = { "n", "<M-CR>" },
          MkdnTagSpan = { "v", "<M-CR>" },
          MkdnMoveSource = { "n", "<F2>" },
          MkdnYankAnchorLink = { "n", "yaa" },
          MkdnYankFileAnchorLink = { "n", "yfa" },
          MkdnIncreaseHeading = { "n", "+" },
          MkdnDecreaseHeading = { "n", "-" },
          MkdnToggleToDo = { { "n", "v" }, "<C-Space>" },
          MkdnNewListItem = false,
          MkdnNewListItemBelowInsert = { "n", "o" },
          MkdnNewListItemAboveInsert = { "n", "O" },
          MkdnExtendList = false,
          MkdnUpdateNumbering = { "n", "<leader>nn" },
          MkdnTableNextCell = { "i", "<Tab>" },
          MkdnTablePrevCell = { "i", "<S-Tab>" },
          MkdnTableNextRow = false,
          MkdnTablePrevRow = { "i", "<M-CR>" },
          MkdnTableNewRowBelow = { "n", "<leader>ir" },
          MkdnTableNewRowAbove = { "n", "<leader>iR" },
          MkdnTableNewColAfter = { "n", "<leader>ic" },
          MkdnTableNewColBefore = { "n", "<leader>iC" },
          MkdnFoldSection = { "n", "<leader>f" },
          MkdnUnfoldSection = { "n", "<leader>F" },
        },
      })
    end,
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
      -- Disable ltex-ls as it's causing Java XML parsing errors
      opts.servers.ltex = false
    end,
  },
}
