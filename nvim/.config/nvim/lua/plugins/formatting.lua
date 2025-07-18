if vim.g.vscode then
  return {}
end

return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" }, -- auto-format before save
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>f",
      function()
        require("conform").format({ async = true })
      end,
      mode = "",
      desc = "Format buffer",
    },
    {
      "<leader>uf",
      function()
        vim.g.disable_autoformat = not vim.g.disable_autoformat
        if vim.g.disable_autoformat then
          vim.notify("Format on save disabled", vim.log.levels.INFO)
        else
          vim.notify("Format on save enabled", vim.log.levels.INFO)
        end
      end,
      mode = "",
      desc = "Toggle format on save",
    },
  },
  opts = {
    format_on_save = function(bufnr)
      -- Disable format on save if vim.g.disable_autoformat is true
      if vim.g.disable_autoformat then
        return
      end
      return {
        timeout_ms = 500,
        lsp_format = "fallback",
      }
    end,
    formatters_by_ft = {},
  },
}
