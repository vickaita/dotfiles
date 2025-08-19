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
        markdown = { "dprint", "prettier", stop_after_first = true },
        graphql = { "prettier" },
        handlebars = { "prettier" },
        go = { "goimports", "gofmt" },
        rust = { "rustfmt" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
      }
    end)(),
    formatters = {
      dprint = {
        condition = function(self, ctx)
          -- Check if dprint.json exists in project or use inline config
          local cwd = vim.fn.getcwd()
          local config_path = cwd .. "/dprint.json"
          return vim.uv.fs_stat(config_path) ~= nil
        end,
        args = function(self, ctx)
          -- If no config file, use inline config for markdown
          local cwd = vim.fn.getcwd()
          local config_path = cwd .. "/dprint.json"
          if vim.uv.fs_stat(config_path) then
            return { "fmt", "--stdin", ctx.filename }
          else
            return {
              "fmt",
              "--stdin",
              ctx.filename,
              "--config",
              vim.json.encode({
                lineWidth = vim.bo.textwidth > 0 and vim.bo.textwidth or 80,
                markdown = {
                  textWrap = "maintain", -- preserve checkbox formatting
                },
                includes = { "**/*.md" },
                plugins = { "https://plugins.dprint.dev/markdown-0.15.3.wasm" },
              }),
            }
          end
        end,
      },
    },
  },
}
