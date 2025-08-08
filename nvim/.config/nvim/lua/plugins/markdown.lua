if vim.g.vscode then
  return {}
end

return {
  {
    "MeanderingProgrammer/markdown.nvim",
    name = "render-markdown",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("render-markdown").setup({
        -- Enable concealment for markdown syntax
        concealment = {
          enabled = true,
          -- Only conceal when cursor is not on the line
          only_when_cursor_is_off_line = true,
        },
        heading = {
          backgrounds = {},
          -- icons = { "♔ ", "♛ ", "♜ ", "♝ ", "♞ ", "♟ " },
          -- icons = { "󰇊 ", "󰇋 ", "󰇌 ", "󰇍 ", "󰇎 ", "󰇏 " },
          -- icons = { "󰫎 " },
          icons = {
            "󰫎 ",
            "󰫎󰫎 ",
            "󰫎󰫎󰫎 ",
            "󰫎󰫎󰫎󰫎 ",
            "󰫎󰫎󰫎󰫎󰫎 ",
            "󰫎󰫎󰫎󰫎󰫎󰫎 ",
          },
          position = "inline",
          sign = true,
          signs = { "♔", "♛", "♜", "♝", "♞", "♟" },
        },
        -- Code block settings
        code = {
          -- Show language name in code blocks
          sign = true,
          -- Width of the code block
          width = "block",
          -- Minimum width for code blocks
          min_width = 80,
          -- Border around code blocks
          border = "thick",
          -- left_pad = 4,
          -- right_pad = 4,
        },
        -- Bullet point settings
        bullet = {
          -- Enable bullet point rendering
          enabled = true,
          -- Different icons for different levels
          -- icons = { "●", "○", "◆", "◇" },
          icons = { "•" },
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
    ft = { "markdown", "md" },
    config = function()
      require("mkdnflow").setup({
        -- Links and paths
        links = {
          style = "markdown",
          name_is_source = false,
          conceal = true,
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
      opts.servers.markdown_oxide = {}

      -- Create autocmd to register markdown-oxide commands when LSP attaches
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.name == "markdown_oxide" then
            vim.api.nvim_create_user_command("Daily", function(args)
              vim.lsp.buf.execute_command({ command = "jump", arguments = { args.args } })
            end, { desc = "Open daily note", nargs = "*" })

            vim.api.nvim_create_user_command("Today", function()
              vim.lsp.buf.execute_command({ command = "jump", arguments = { "today" } })
            end, { desc = "Jump to today's daily note" })

            vim.api.nvim_create_user_command("Tomorrow", function()
              vim.lsp.buf.execute_command({ command = "jump", arguments = { "tomorrow" } })
            end, { desc = "Jump to tomorrow's daily note" })

            vim.api.nvim_create_user_command("Yesterday", function()
              vim.lsp.buf.execute_command({ command = "jump", arguments = { "yesterday" } })
            end, { desc = "Jump to yesterday's daily note" })
          end
        end,
      })
      -- Disable ltex-ls as it's causing Java XML parsing errors
      opts.servers.ltex = false
    end,
  },
}
