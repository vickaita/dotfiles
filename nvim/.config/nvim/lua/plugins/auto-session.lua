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
      { "<leader>wr", "<cmd>SessionSearch<cr>", desc = "Session search" },
      { "<leader>ws", "<cmd>SessionSave<cr>", desc = "Save session" },
    },
    opts = {
      auto_session_suppress_dirs = {
        "~/",
        "~/Projects",
        "~/Downloads",
        "/",
      },
      auto_session_use_git_branch = true,
      auto_session_enabled = true,
      auto_save_enabled = true,
      auto_restore_enabled = true,
      auto_session_create_enabled = true,

      -- Session lens configuration - commented out to use vim.ui.select (fzf-lua)
      -- session_lens = {
      --   buftypes_to_ignore = {},
      --   load_on_setup = true,
      --   theme_conf = { border = true },
      --   previewer = false,
      -- },

      -- Configure which buffers to save in sessions
      bypass_session_save_file_types = {
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

      -- Pre and post session hooks
      pre_save_cmds = {},

      post_restore_cmds = {
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
