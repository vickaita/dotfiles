if vim.g.vscode then
  return {}
end

return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  opts = {
    options = {
      icons_enabled = true,
      theme = "auto",
      --   component_separators = { left = "", right = "" },
      --   section_separators = { left = "", right = "" },
      disabled_filetypes = {
        statusline = {},
        winbar = {},
      },
      ignore_focus = {},
      always_divide_middle = true,
      globalstatus = false,
      refresh = {
        statusline = 1000,
        tabline = 1000,
        winbar = 1000,
      },
    },
    sections = {
      lualine_a = {
        {
          "mode",
          cond = function()
            return vim.bo.filetype ~= "neo-tree"
          end,
        },
      },
      lualine_b = {
        "branch",
        {
          "diff",
          cond = function()
            return vim.bo.filetype ~= "neo-tree"
          end,
        },
        {
          "diagnostics",
          cond = function()
            return vim.bo.filetype ~= "neo-tree"
          end,
        },
      },
      lualine_c = {
        {
          "filename",
          cond = function()
            return vim.bo.filetype ~= "neo-tree"
          end,
        },
      },
      lualine_x = {
        {
          "encoding",
          cond = function()
            return vim.bo.filetype ~= "neo-tree"
          end,
        },
        {
          "fileformat",
          cond = function()
            return vim.bo.filetype ~= "neo-tree"
          end,
        },
        {
          "filetype",
          cond = function()
            return vim.bo.filetype ~= "neo-tree"
          end,
        },
      },
      lualine_y = {
        {
          "progress",
          cond = function()
            return vim.bo.filetype ~= "neo-tree"
          end,
        },
      },
      lualine_z = {
        {
          "location",
          cond = function()
            return vim.bo.filetype ~= "neo-tree"
          end,
        },
        {
          function()
            local cwd = vim.fn.getcwd()
            if vim.fn.filereadable(cwd .. "/package.json") == 1 then
              return " JavaScript"
            elseif vim.fn.filereadable(cwd .. "/Cargo.toml") == 1 then
              return " Rust"
            elseif vim.fn.filereadable(cwd .. "/go.mod") == 1 then
              return " Go"
            elseif
              vim.fn.filereadable(cwd .. "/pyproject.toml") == 1
              or vim.fn.filereadable(cwd .. "/requirements.txt") == 1
            then
              return " Python"
            elseif vim.fn.filereadable(cwd .. "/Gemfile") == 1 then
              return " Ruby"
            elseif vim.fn.filereadable(cwd .. "/pom.xml") == 1 or vim.fn.filereadable(cwd .. "/build.gradle") == 1 then
              return " Java"
            end
            return " Directory"
          end,
          cond = function()
            return vim.bo.filetype == "neo-tree"
          end,
        },
      },
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {
        {
          "branch",
          cond = function()
            return vim.bo.filetype == "neo-tree"
          end,
        },
      },
      lualine_c = {
        {
          "filename",
          cond = function()
            return vim.bo.filetype ~= "neo-tree"
          end,
        },
      },
      lualine_x = {
        {
          "location",
          cond = function()
            return vim.bo.filetype ~= "neo-tree"
          end,
        },
      },
      lualine_y = {},
      lualine_z = {},
    },
    tabline = {},
    winbar = {},
    inactive_winbar = {},
    extensions = {},
  },
}
