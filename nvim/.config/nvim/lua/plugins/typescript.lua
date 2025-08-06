if vim.g.vscode then
  return {}
end

return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        javascript = { "prettier" },
        typescript = { "prettier" },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        vtsls = {},
        -- Disable ts_ls to avoid conflicts
        ts_ls = false,
      },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "prettier",
      },
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = { "vtsls", "biome" },
    },
  },
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      "marilari88/neotest-vitest",
      --     "nvim-neotest/neotest-jest",
    },
    opts = {
      adapters = {
        ["neotest-vitest"] = {
          cwd = function(file_path)
            -- Walk up from the test file to find the nearest workspace with vitest config
            local current_dir = vim.fn.fnamemodify(file_path, ":h")

            while current_dir ~= "/" do
              -- Check if this directory has both package.json AND vitest config
              local pkg_json = current_dir .. "/package.json"
              local vitest_config = current_dir .. "/vitest.config.ts"

              if vim.fn.filereadable(pkg_json) == 1 and vim.fn.filereadable(vitest_config) == 1 then
                return current_dir
              end

              current_dir = vim.fn.fnamemodify(current_dir, ":h")

              -- Stop if we reach the monorepo root (has workspaces in package.json)
              local root_pkg = current_dir .. "/package.json"
              if vim.fn.filereadable(root_pkg) == 1 then
                local content = vim.fn.readfile(root_pkg)
                local json_str = table.concat(content, "\n")
                if string.match(json_str, '"workspaces"') then
                  break
                end
              end
            end

            return vim.fn.getcwd()
          end,
        },
      },
    },
  },
}
