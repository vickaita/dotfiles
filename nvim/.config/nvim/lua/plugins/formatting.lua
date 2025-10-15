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
        -- Toggle the global variable (will be saved per-session by auto-session)
        vim.g.disable_autoformat = not vim.g.disable_autoformat
        if vim.g.disable_autoformat then
          vim.notify("Format on save disabled (saved in session)", vim.log.levels.INFO)
        else
          vim.notify("Format on save enabled (saved in session)", vim.log.levels.INFO)
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

      -- Check for project-specific disable setting via neoconf
      local ok, neoconf = pcall(require, "neoconf")
      if ok and neoconf.get("custom.disable_autoformat") then
        return
      end

      return {
        timeout_ms = 500,
        lsp_format = "fallback",
      }
    end,
    formatters_by_ft = (function()
      -- Helper function to check if biome.json exists in current working
      -- directory
      local function has_biome_config()
        local cwd = vim.fn.getcwd()
        local biome_config = cwd .. "/biome.json"
        return vim.uv.fs_stat(biome_config) ~= nil
      end

      -- Choose formatters based on whether biome config exists
      local js_formatters = has_biome_config() and { "biome", "prettier", stop_after_first = true } or { "prettier" }
      local json_formatters = has_biome_config() and { "biome", "prettier", stop_after_first = true } or { "prettier" }

      return {
        lua = { "stylua" },
        python = { "isort", "black" },
        javascript = js_formatters,
        typescript = js_formatters,
        javascriptreact = js_formatters,
        typescriptreact = js_formatters,
        vue = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        less = { "prettier" },
        html = { "prettier" },
        json = json_formatters,
        jsonc = json_formatters,
        yaml = { "prettier" },
        markdown = { "prettier" },
        graphql = { "prettier" },
        handlebars = { "prettier" },
        go = { "goimports", "gofmt" },
        rust = { "rustfmt" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
      }
    end)(),
  },
}
