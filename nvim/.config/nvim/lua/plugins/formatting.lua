if vim.g.vscode then
  return {}
end

return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" }, -- auto-format before save
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>cf",
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
    {
      "<leader>un",
      function()
        if not vim.opt.number:get() then
          vim.opt.number = true
          vim.opt.relativenumber = false
        elseif vim.opt.relativenumber:get() then
          vim.opt.relativenumber = false
        else
          vim.opt.relativenumber = true
        end
      end,
      desc = "Toggle relative/regular line numbers",
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
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "isort", "black" },
      javascript = { "biome", "prettier", stop_after_first = true },
      typescript = { "biome", "prettier", stop_after_first = true },
      javascriptreact = { "biome", "prettier", stop_after_first = true },
      typescriptreact = { "biome", "prettier", stop_after_first = true },
      vue = { "prettier" },
      css = { "prettier" },
      scss = { "prettier" },
      less = { "prettier" },
      html = { "prettier" },
      json = { "biome", "prettier", stop_after_first = true },
      jsonc = { "biome", "prettier", stop_after_first = true },
      yaml = { "prettier" },
      markdown = { "prettier" },
      graphql = { "prettier" },
      handlebars = { "prettier" },
      go = { "goimports", "gofmt" },
      rust = { "rustfmt" },
      sh = { "shfmt" },
      bash = { "shfmt" },
      zsh = { "shfmt" },
    },
  },
}
