if vim.g.vscode then
  return {}
end

return {
  {
    "rmagatti/auto-session",
    lazy = false,
    dependencies = {
      "ibhagwan/fzf-lua",
    },
    keys = {
      { "<leader>wr", "<cmd>AutoSession search<cr>", desc = "Session search" },
      { "<leader>ws", "<cmd>AutoSession save<cr>", desc = "Save session" },
      { "<leader>wd", "<cmd>AutoSession delete<cr>", desc = "Delete current session" },
    },
    opts = {
      -- Saving / restoring
      enabled = true,
      auto_save = true,
      auto_restore = true,
      auto_create = true,
      show_auto_restore_notif = true,

      -- Filtering
      suppressed_dirs = {
        "~/",
        "~/Projects",
        "~/Downloads",
        "/",
      },
      bypass_save_filetypes = {
        "alpha",
        "dashboard",
        "lir",
        "Outline",
        "spectre_panel",
        "TelescopePrompt",
        "lazy",
        "mason",
        "neo-tree",
      },

      -- Git / Session naming
      git_use_branch_name = true,

      -- Session lens configuration - commented out to use vim.ui.select (fzf-lua)
      -- session_lens = {
      --   buftypes_to_ignore = {},
      --   load_on_setup = true,
      --   theme_conf = { border = true },
      --   previewer = false,
      -- },

      -- Pre and post session hooks
      pre_save_cmds = {
        function()
          -- Save autoformat setting to a file alongside the session
          local session_dir = vim.fn.stdpath("data") .. "/sessions"
          local cwd = vim.fn.getcwd()
          local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("\n", "")
          local session_name = cwd:gsub("/", "%%2F")
          if branch ~= "" then
            session_name = session_name .. "|" .. branch
          end

          local settings_file = session_dir .. "/" .. session_name .. ".settings.json"
          local settings = {
            disable_autoformat = vim.g.disable_autoformat or false,
            line_numbers = vim.opt.number:get(),
            relative_numbers = vim.opt.relativenumber:get(),
            colorcolumn = vim.opt.colorcolumn:get()[1] or "",
            wrap = vim.opt.wrap:get(),
            auto_import_folding_enabled = vim.g.auto_import_folding_enabled,
            user_disabled_wrap_for_text_filetypes = vim.g.user_disabled_wrap_for_text_filetypes,
          }

          vim.fn.writefile({ vim.fn.json_encode(settings) }, settings_file)
        end,
      },

      post_restore_cmds = {
        function()
          -- Restore autoformat setting from settings file
          local session_dir = vim.fn.stdpath("data") .. "/sessions"
          local cwd = vim.fn.getcwd()
          local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("\n", "")
          local session_name = cwd:gsub("/", "%%2F")
          if branch ~= "" then
            session_name = session_name .. "|" .. branch
          end

          local settings_file = session_dir .. "/" .. session_name .. ".settings.json"
          if vim.fn.filereadable(settings_file) == 1 then
            local content = vim.fn.readfile(settings_file)
            local settings = vim.fn.json_decode(table.concat(content, "\n"))

            if settings.disable_autoformat ~= nil then
              vim.g.disable_autoformat = settings.disable_autoformat
            end

            if settings.line_numbers ~= nil then
              vim.opt.number = settings.line_numbers
            end

            if settings.relative_numbers ~= nil then
              vim.opt.relativenumber = settings.relative_numbers
            end

            if settings.colorcolumn ~= nil then
              vim.opt.colorcolumn = settings.colorcolumn
            end

            if settings.wrap ~= nil then
              vim.opt.wrap = settings.wrap
            end

            if settings.auto_import_folding_enabled ~= nil then
              vim.g.auto_import_folding_enabled = settings.auto_import_folding_enabled
            end

            if settings.user_disabled_wrap_for_text_filetypes ~= nil then
              vim.g.user_disabled_wrap_for_text_filetypes = settings.user_disabled_wrap_for_text_filetypes
            end
          end
        end,
        function()
          -- Refresh git signs after restoring session
          if vim.fn.exists(":Gitsigns") > 0 then
            vim.cmd("Gitsigns refresh")
          end
        end,
      },
    },
  },
}
