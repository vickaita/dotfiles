if vim.g.vscode then
  return {}
end

return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = { python = { "ruff_organize_imports", "ruff_format" } },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "ruff",
        "pyrefly",
      },
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "pyright",
        "pyrefly",
      },
    },
  },
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      "nvim-neotest/neotest-python",
    },
    opts = {
      adapters = {
        ["neotest-python"] = {
          runner = "pytest",
          python = function()
            local cwd = vim.fn.getcwd()

            -- For Poetry projects, get the venv Python path
            if vim.fn.filereadable(cwd .. "/pyproject.toml") == 1 then
              local handle =
                io.popen("cd " .. vim.fn.shellescape(cwd) .. " && poetry env info --executable 2>/dev/null")
              if handle then
                local poetry_python = handle:read("*a"):gsub("\n", "")
                handle:close()
                if poetry_python and poetry_python ~= "" and vim.fn.executable(poetry_python) == 1 then
                  return poetry_python
                end
              end
            end

            return vim.fn.exepath("python3") or "python"
          end,
        },
      },
    },
  },
  -- {
  --   "nvim-treesitter/nvim-treesitter",
  --   opts = function(_, opts)
  --     vim.list_extend(opts.ensure_installed, {
  --       "python",
  --     })
  --   end,
  -- },
}
