if vim.g.vscode then
  return {}
end

return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" }, -- auto-format before save
  cmd = { "ConformInfo" },
  opts = {
    format_on_save = {
      timeout_ms = 500,
      lsp_format = "fallback",
    },
    formatters_by_ft = {},
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({ async = true })
        end,
        mode = "",
        desc = "Format buffer",
      },
    },
  },
}
