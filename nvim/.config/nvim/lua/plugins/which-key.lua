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
