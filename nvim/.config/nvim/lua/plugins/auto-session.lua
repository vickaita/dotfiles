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
