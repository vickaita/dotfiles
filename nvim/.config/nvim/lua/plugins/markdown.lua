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
          min_width = vim.bo.textwidth > 0 and vim.bo.textwidth or 80,
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
          checked = { icon = "[✖]", highlight = "RenderMarkdownDone" },
          custom = {
            todo = {
              raw = "[-]",
              rendered = "[⁃]",
              highlight = "RenderMarkdownInProgress",
            },
          },
        },
        dash = {
          width = vim.bo.textwidth > 0 and vim.bo.textwidth or 80,
          -- icon = "≈",
          -- icon = "=",
          icon = "-",
        },
      })
    end,
    ft = { "markdown", "md" },
  },
  {
    "jakewvincent/mkdnflow.nvim",
    ft = { "markdown", "md" },
    config = function()
      -- Extends mkdnflow's link-following to support Obsidian block reference syntax.
      -- Standard markdown anchors target headings (e.g. #items), but Obsidian also
      -- supports block anchors: append `^blockid` to any line to create an anchor,
      -- then link to it with `#^blockid`. mkdnflow doesn't know this syntax, so we
      -- intercept <CR>, handle block refs ourselves, and fall back to MkdnEnter for
      -- everything else.
      local function follow_link()
        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2] + 1
        local start_pos = 1
        while true do
          local s, e, block_id = line:find("%[.-%]%(#%^([^%)]+)%)", start_pos)
          if not s then break end
          if col >= s and col <= e then
            local search_pat = "%^" .. vim.pesc(block_id) .. "%s*$"
            local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            for i, l in ipairs(buf_lines) do
              if l:match(search_pat) then
                vim.cmd("normal! m'")
                vim.api.nvim_win_set_cursor(0, { i, 0 })
                return
              end
            end
            vim.notify("Block anchor '^" .. block_id .. "' not found", vim.log.levels.WARN)
            return
          end
          start_pos = e + 1
        end
        vim.cmd("MkdnEnter")
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown", "md" },
        callback = function()
          vim.keymap.set("n", "<CR>", follow_link, { buffer = true, desc = "Follow markdown link" })
        end,
      })

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
          statuses = {
            not_started = { marker = " " },
            in_progress = { marker = "-" },
            complete = { marker = { "X", "x" } },
          },
          status_order = { "not_started", "in_progress", "complete" },
          status_propagation = {
            up = true,
          },
        },
        -- Mappings
        mappings = {
          MkdnEnter = false,
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
          MkdnFollowLink = false,
          MkdnDestroyLink = { "n", "<M-CR>" },
          MkdnTagSpan = { "v", "<M-CR>" },
          MkdnMoveSource = { "n", "<F2>" },
          MkdnYankAnchorLink = { "n", "yaa" },
          MkdnYankFileAnchorLink = { "n", "yfa" },
          MkdnIncreaseHeading = { "n", "+" },
          MkdnDecreaseHeading = { "n", "-" },
          MkdnToggleToDo = { { "n", "v" }, "<C-m>" },
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
      vim.list_extend(opts.ensure_installed, { "markdown-oxide", "dprint" })
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
              client:exec_cmd({
                command = "jump",
                title = "Jump to daily note",
                arguments = { args.args },
              }, { bufnr = event.buf })
            end, { desc = "Open daily note", nargs = "*" })

            vim.api.nvim_create_user_command("Today", function()
              client:exec_cmd({
                command = "jump",
                title = "Jump to today",
                arguments = { "today" },
              }, { bufnr = event.buf })
            end, { desc = "Jump to today's daily note" })

            vim.api.nvim_create_user_command("Tomorrow", function()
              client:exec_cmd({
                command = "jump",
                title = "Jump to tomorrow",
                arguments = { "tomorrow" },
              }, { bufnr = event.buf })
            end, { desc = "Jump to tomorrow's daily note" })

            vim.api.nvim_create_user_command("Yesterday", function()
              client:exec_cmd({
                command = "jump",
                title = "Jump to yesterday",
                arguments = { "yesterday" },
              }, { bufnr = event.buf })
            end, { desc = "Jump to yesterday's daily note" })

            -- Create today's note by copying current file unchanged
            vim.api.nvim_create_user_command("CarryOver", function()
              require("util.markdown").carry_over_today()
            end, { desc = "Create today's note by copying current buffer" })

            -- Update current buffer's checkboxes in-place
            vim.api.nvim_create_user_command("UpdateCheckboxes", function()
              require("util.markdown").normalize_checkboxes()
            end, {
              desc = "Normalize checkbox symbols based on descendants; no deletions",
            })

            -- Remove completed subtrees in-place
            vim.api.nvim_create_user_command("RemoveCompletedCheckboxes", function()
              require("util.markdown").remove_completed()
            end, {
              desc = "Remove all checkbox subtrees rooted at completed items",
            })

            -- Carry Over and then Update + Remove
            vim.api.nvim_create_user_command("CarryOverAndUpdate", function()
              require("util.markdown").carry_over_and_process()
            end, {
              desc = "CarryOver then UpdateCheckboxes and RemoveCompletedCheckboxes",
            })

            -- Compare daily changes
            vim.api.nvim_create_user_command("CompareDaily", function()
              require("util.markdown").compare_daily_changes()
            end, {
              desc = "Compare current day with previous day and show new items",
            })

            -- Test AST functions (for debugging/development)
            vim.api.nvim_create_user_command("TestMarkdownAST", function()
              require("util.markdown").test_ast_functions()
            end, {
              desc = "Test the new AST-based markdown processing functions",
            })
          end
        end,
      })
      -- Disable ltex-ls as it's causing Java XML parsing errors
      opts.servers.ltex = false
    end,
  },
}
