if vim.g.vscode then
  return {}
end

return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        astro = { "prettier" },
      },
      formatters = {
        prettier = {
          prepend_args = function(_, ctx)
            if vim.bo[ctx.buf].filetype ~= "astro" then
              return {}
            end
            -- Walk up from file directory to find installed plugin
            local dir = ctx.dirname
            while dir and dir ~= "/" do
              local plugin = dir .. "/node_modules/prettier-plugin-astro/dist/index.js"
              if vim.uv.fs_stat(plugin) then
                return { "--plugin", plugin }
              end
              dir = vim.fn.fnamemodify(dir, ":h")
            end
            -- Fall back to global npm root
            local global_root = vim.fn.system("npm root -g 2>/dev/null"):gsub("\n", "")
            if global_root ~= "" then
              local global_plugin = global_root .. "/prettier-plugin-astro/dist/index.js"
              if vim.uv.fs_stat(global_plugin) then
                return { "--plugin", global_plugin }
              end
            end
            return {}
          end,
        },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        astro = {},
      },
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = { "astro" },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "astro" },
    },
  },
}
