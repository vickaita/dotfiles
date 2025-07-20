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
          { "<leader>t", group = "test" },
          { "<leader>u", group = "ui" },
          {
            "<leader>un",
            function()
              require("util.ui").toggle_line_numbers()
            end,
            desc = "Toggle relative/regular line numbers",
          },
          {
            "<leader>ur",
            function()
              require("util.ui").toggle_vertical_ruler()
            end,
            desc = "Toggle vertical ruler",
          },
          {
            "<leader>uw",
            function()
              require("util.ui").toggle_text_wrap()
            end,
            desc = "Toggle overflow text wrapping",
          },
          {
            "<leader>uh",
            function()
              require("util.ui").toggle_overflow_highlighting()
            end,
            desc = "Toggle overflow text highlighting",
          },
          { "<leader>v", group = "vimwiki" },
          { "<leader>vd", group = "diary" },
          { "<leader>w", group = "workspace" },
          { "<leader>x", group = "diagnostics" },
          { "<leader>a", group = "ai", icon = "󰚩" },
          { "<leader>i", group = "insert" },
          { "<leader>m", group = "split/join" },
          { "<leader>n", group = "numbering" },
          { "<leader>p", group = "paste/link" },
        },
      },
    },
  },
}
