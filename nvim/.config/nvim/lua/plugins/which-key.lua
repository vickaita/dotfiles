if vim.g.vscode then
  return {}
end

return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      plugins = { spelling = true },
      spec = {
        {
          mode = { "n", "v" },
          { "g", group = "goto" },
          { "gs", group = "surround" },
          { "]", group = "next" },
          { "[", group = "prev" },
          { "<leader><tab>", group = "tabs" },
          { "<leader>b", group = "buffer" },
          { "<leader>c", group = "code" },
          { "<leader>f", group = "find" },
          { "<leader>g", group = "git" },
          { "<leader>gh", group = "hunks" },
          { "<leader>q", group = "quit/session" },
          { "<leader>s", group = "search" },
          { "<leader>t", group = "test", icon = "󰙨" },
          { "<leader>u", group = "ui" },
          {
            "<leader>uf",
            desc = function()
              local disabled = vim.g.disable_autoformat or false
              -- Check neoconf setting if available
              local ok, neoconf = pcall(require, "neoconf")
              if ok then
                local neoconf_setting = neoconf.get("custom.disable_autoformat")
                if neoconf_setting ~= nil then
                  disabled = neoconf_setting
                end
              end
              return disabled and "Enable format on save" or "Disable format on save"
            end,
            icon = function()
              local disabled = vim.g.disable_autoformat or false
              -- Check neoconf setting if available
              local ok, neoconf = pcall(require, "neoconf")
              if ok then
                local neoconf_setting = neoconf.get("custom.disable_autoformat")
                if neoconf_setting ~= nil then
                  disabled = neoconf_setting
                end
              end
              if disabled then
                return { icon = "", color = "red" }
              else
                return { icon = "", color = "green" }
              end
            end,
          },
          {
            "<leader>un",
            function()
              require("util.ui").toggle_line_numbers()
            end,
            desc = function()
              if not vim.opt.number:get() then
                return "Enable line numbers"
              elseif vim.opt.relativenumber:get() then
                return "Switch to regular line numbers"
              else
                return "Switch to relative line numbers"
              end
            end,
            icon = function()
              if not vim.opt.number:get() then
                return { icon = "", color = "red" }
              else
                return { icon = "", color = "green" }
              end
            end,
          },
          {
            "<leader>ur",
            function()
              require("util.ui").toggle_vertical_ruler()
            end,
            desc = function()
              return vim.opt.colorcolumn:get()[1] and "Hide vertical ruler" or "Show vertical ruler"
            end,
            icon = function()
              if vim.opt.colorcolumn:get()[1] then
                return { icon = "", color = "green" }
              else
                return { icon = "", color = "red" }
              end
            end,
          },
          {
            "<leader>uw",
            function()
              require("util.ui").toggle_text_wrap()
            end,
            desc = function()
              return vim.opt.wrap:get() and "Disable text wrapping" or "Enable text wrapping"
            end,
            icon = function()
              if vim.opt.wrap:get() then
                return { icon = "", color = "green" }
              else
                return { icon = "", color = "red" }
              end
            end,
          },
          {
            "<leader>uh",
            function()
              require("util.ui").toggle_overflow_highlighting()
            end,
            desc = function()
              return vim.w.overflow_match and "Disable overflow highlighting" or "Enable overflow highlighting"
            end,
            icon = function()
              if vim.w.overflow_match then
                return { icon = "", color = "green" }
              else
                return { icon = "", color = "red" }
              end
            end,
          },
          {
            "<leader>ui",
            desc = function()
              local enabled = vim.g.auto_import_folding_enabled
              return enabled and "Disable auto import folding" or "Enable auto import folding"
            end,
            icon = function()
              local enabled = vim.g.auto_import_folding_enabled
              if enabled then
                return { icon = "", color = "green" }
              else
                return { icon = "", color = "red" }
              end
            end,
          },
          {
            "<leader>uc",
            function()
              require("treesitter-context").toggle()
            end,
            desc = function()
              local ok, ctx = pcall(require, "treesitter-context")
              if ok and ctx.enabled() then
                return "Disable treesitter context"
              else
                return "Enable treesitter context"
              end
            end,
            icon = function()
              local ok, ctx = pcall(require, "treesitter-context")
              if ok and ctx.enabled() then
                return { icon = "", color = "green" }
              else
                return { icon = "", color = "red" }
              end
            end,
          },
          {
            "<leader>uE",
            function()
              vim.g.neo_tree_auto_close = not vim.g.neo_tree_auto_close
            end,
            desc = function()
              return vim.g.neo_tree_auto_close and "Disable neo-tree auto-close" or "Enable neo-tree auto-close"
            end,
            icon = function()
              if vim.g.neo_tree_auto_close then
                return { icon = "", color = "green" }
              else
                return { icon = "", color = "red" }
              end
            end,
          },
          { "<leader>v", group = "vimwiki" },
          { "<leader>vd", group = "diary" },
          { "<leader>w", group = "workspace", icon = "󰷉" },
          {
            "<leader>wa",
            "<cmd>AutoSession toggle<cr>",
            desc = function()
              local config = require("auto-session.config")
              return config.auto_save and "Disable session auto-save" or "Enable session auto-save"
            end,
            icon = function()
              local config = require("auto-session.config")
              if config.auto_save then
                return { icon = "", color = "green" }
              else
                return { icon = "", color = "red" }
              end
            end,
          },
          { "<leader>x", group = "diagnostics" },
          { "<leader>a", group = "ai" },
          { "<leader>i", group = "insert" },
          { "<leader>m", group = "split/join" },
          { "<leader>n", group = "numbering" },
          { "<leader>p", group = "paste/link" },
        },
      },
    },
  },
}
