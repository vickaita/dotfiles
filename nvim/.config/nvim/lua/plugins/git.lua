if vim.g.vscode then
  return {}
end

return {
  {
    "tpope/vim-fugitive",
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("custom_close_with_q", { clear = true }),
        pattern = {
          "fugitiveblame",
          "gitsigns-blame",
        },
        callback = function(event)
          vim.bo[event.buf].buflisted = false
          vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
        end,
      })
    end,
    keys = {},
    lazy = false,
  },
  {
    "lewis6991/gitsigns.nvim",
    -- event = "LazyFile",
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      signs_staged = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      -- bump this above your LSP priority
      sign_priority = 10000,
      -- ensure that space is always reserved for the signs
      -- signcolumn = true,
      on_attach = function(buffer)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
        end

        -- stylua: ignore start
        map("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "Next Hunk")
        map("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "Prev Hunk")
        map("n", "]H", function() gs.nav_hunk("last") end, "Last Hunk")
        map("n", "[H", function() gs.nav_hunk("first") end, "First Hunk")
        map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
        map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
        map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
        map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
        map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
        map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
        map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame Line")
        map("n", "<leader>gB", function() gs.blame() end, "Blame Buffer")
        map("n", "<leader>ub", gs.toggle_current_line_blame, "Toggle current line blame")
        map("n", "<leader>ghd", gs.diffthis, "Diff This")
        map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
      end,
    },
  },
  {
    "kdheepak/lazygit.nvim",
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
    },
  },
  {
    "sindrets/diffview.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      local actions = require("diffview.actions")
      
      require("diffview").setup({
        diff_binaries = false,
        enhanced_diff_hl = false,
        git_cmd = { "git" },
        use_icons = true,
        show_help_hints = true,
        watch_index = true,
        icons = {
          folder_closed = "",
          folder_open = "",
        },
        signs = {
          fold_closed = "",
          fold_open = "",
          done = "✓",
        },
        view = {
          default = {
            layout = "diff2_horizontal",
            disable_diagnostics = false,
            winbar_info = false,
          },
          merge_tool = {
            layout = "diff3_horizontal",
            disable_diagnostics = true,
            winbar_info = true,
          },
          file_history = {
            layout = "diff2_horizontal",
            disable_diagnostics = false,
            winbar_info = false,
          },
        },
        file_panel = {
          listing_style = "tree",
          tree_options = {
            flatten_dirs = true,
            folder_statuses = "only_folded",
          },
          win_config = {
            position = "left",
            width = 35,
            win_opts = {},
          },
        },
        file_history_panel = {
          log_options = {
            git = {
              single_file = {
                diff_merges = "combined",
              },
              multi_file = {
                diff_merges = "first-parent",
              },
            },
          },
          win_config = {
            position = "bottom",
            height = 16,
            win_opts = {},
          },
        },
        default_args = {
          DiffviewOpen = { "--imply-local" },
          DiffviewFileHistory = {},
        },
        keymaps = {
          disable_defaults = false,
          view = {
            { "n", "<tab>", actions.select_next_entry, { desc = "Open the diff for the next file" } },
            { "n", "<s-tab>", actions.select_prev_entry, { desc = "Open the diff for the previous file" } },
            { "n", "[F", actions.select_first_entry, { desc = "Open the diff for the first file" } },
            { "n", "]F", actions.select_last_entry, { desc = "Open the diff for the last file" } },
            { "n", "gf", actions.goto_file_edit, { desc = "Open the file in the previous tabpage" } },
            { "n", "<C-w><C-f>", actions.goto_file_split, { desc = "Open the file in a new split" } },
            { "n", "<C-w>gf", actions.goto_file_tab, { desc = "Open the file in a new tabpage" } },
            { "n", "<leader>e", actions.focus_files, { desc = "Bring focus to the file panel" } },
            { "n", "<leader>b", actions.toggle_files, { desc = "Toggle the file panel" } },
            { "n", "g<C-x>", actions.cycle_layout, { desc = "Cycle through available layouts" } },
            { "n", "[x", actions.prev_conflict, { desc = "In the merge-tool: jump to the previous conflict" } },
            { "n", "]x", actions.next_conflict, { desc = "In the merge-tool: jump to the next conflict" } },
            { "n", "<leader>co", actions.conflict_choose("ours"), { desc = "Choose the OURS version of a conflict" } },
            { "n", "<leader>ct", actions.conflict_choose("theirs"), { desc = "Choose the THEIRS version of a conflict" } },
            { "n", "<leader>cb", actions.conflict_choose("base"), { desc = "Choose the BASE version of a conflict" } },
            { "n", "<leader>ca", actions.conflict_choose("all"), { desc = "Choose all the versions of a conflict" } },
            { "n", "dx", actions.conflict_choose("none"), { desc = "Delete the conflict region" } },
          },
          file_panel = {
            { "n", "j", actions.next_entry, { desc = "Bring the cursor to the next file entry" } },
            { "n", "<down>", actions.next_entry, { desc = "Bring the cursor to the next file entry" } },
            { "n", "k", actions.prev_entry, { desc = "Bring the cursor to the previous file entry" } },
            { "n", "<up>", actions.prev_entry, { desc = "Bring the cursor to the previous file entry" } },
            { "n", "<cr>", actions.select_entry, { desc = "Open the diff for the selected entry" } },
            { "n", "o", actions.select_entry, { desc = "Open the diff for the selected entry" } },
            { "n", "l", actions.select_entry, { desc = "Open the diff for the selected entry" } },
            { "n", "<2-LeftMouse>", actions.select_entry, { desc = "Open the diff for the selected entry" } },
            { "n", "-", actions.toggle_stage_entry, { desc = "Stage / unstage the selected entry" } },
            { "n", "s", actions.toggle_stage_entry, { desc = "Stage / unstage the selected entry" } },
            { "n", "S", actions.stage_all, { desc = "Stage all entries" } },
            { "n", "U", actions.unstage_all, { desc = "Unstage all entries" } },
            { "n", "X", actions.restore_entry, { desc = "Restore entry to the state on the left side" } },
            { "n", "L", actions.open_commit_log, { desc = "Open the commit log panel" } },
            { "n", "zo", actions.open_fold, { desc = "Expand fold" } },
            { "n", "h", actions.close_fold, { desc = "Collapse fold" } },
            { "n", "zc", actions.close_fold, { desc = "Collapse fold" } },
            { "n", "za", actions.toggle_fold, { desc = "Toggle fold" } },
            { "n", "zR", actions.open_all_folds, { desc = "Expand all folds" } },
            { "n", "zM", actions.close_all_folds, { desc = "Collapse all folds" } },
            { "n", "<c-b>", actions.scroll_view(-0.25), { desc = "Scroll the view up" } },
            { "n", "<c-f>", actions.scroll_view(0.25), { desc = "Scroll the view down" } },
            { "n", "<tab>", actions.select_next_entry, { desc = "Open the diff for the next file" } },
            { "n", "<s-tab>", actions.select_prev_entry, { desc = "Open the diff for the previous file" } },
            { "n", "[F", actions.select_first_entry, { desc = "Open the diff for the first file" } },
            { "n", "]F", actions.select_last_entry, { desc = "Open the diff for the last file" } },
            { "n", "gf", actions.goto_file_edit, { desc = "Open the file in the previous tabpage" } },
            { "n", "<C-w><C-f>", actions.goto_file_split, { desc = "Open the file in a new split" } },
            { "n", "<C-w>gf", actions.goto_file_tab, { desc = "Open the file in a new tabpage" } },
            { "n", "i", actions.listing_style, { desc = "Toggle between 'list' and 'tree' views" } },
            { "n", "f", actions.toggle_flatten_dirs, { desc = "Flatten empty subdirectories in tree listing style" } },
            { "n", "R", actions.refresh_files, { desc = "Update stats and entries in the file list" } },
            { "n", "<leader>e", actions.focus_files, { desc = "Bring focus to the file panel" } },
            { "n", "<leader>b", actions.toggle_files, { desc = "Toggle the file panel" } },
            { "n", "g<C-x>", actions.cycle_layout, { desc = "Cycle available layouts" } },
            { "n", "[x", actions.prev_conflict, { desc = "Go to the previous conflict" } },
            { "n", "]x", actions.next_conflict, { desc = "Go to the next conflict" } },
            { "n", "g?", actions.help("file_panel"), { desc = "Open the help panel" } },
          },
          file_history_panel = {
            { "n", "g!", actions.options, { desc = "Open the option panel" } },
            { "n", "<C-A-d>", actions.open_in_diffview, { desc = "Open the entry under the cursor in a diffview" } },
            { "n", "y", actions.copy_hash, { desc = "Copy the commit hash of the entry under the cursor" } },
            { "n", "L", actions.open_commit_log, { desc = "Show commit details" } },
            { "n", "X", actions.restore_entry, { desc = "Restore file to the state from the selected entry" } },
            { "n", "zo", actions.open_fold, { desc = "Expand fold" } },
            { "n", "zc", actions.close_fold, { desc = "Collapse fold" } },
            { "n", "h", actions.close_fold, { desc = "Collapse fold" } },
            { "n", "za", actions.toggle_fold, { desc = "Toggle fold" } },
            { "n", "zR", actions.open_all_folds, { desc = "Expand all folds" } },
            { "n", "zM", actions.close_all_folds, { desc = "Collapse all folds" } },
            { "n", "j", actions.next_entry, { desc = "Bring the cursor to the next file entry" } },
            { "n", "<down>", actions.next_entry, { desc = "Bring the cursor to the next file entry" } },
            { "n", "k", actions.prev_entry, { desc = "Bring the cursor to the previous file entry" } },
            { "n", "<up>", actions.prev_entry, { desc = "Bring the cursor to the previous file entry" } },
            { "n", "<cr>", actions.select_entry, { desc = "Open the diff for the selected entry" } },
            { "n", "o", actions.select_entry, { desc = "Open the diff for the selected entry" } },
            { "n", "l", actions.select_entry, { desc = "Open the diff for the selected entry" } },
            { "n", "<2-LeftMouse>", actions.select_entry, { desc = "Open the diff for the selected entry" } },
            { "n", "<c-b>", actions.scroll_view(-0.25), { desc = "Scroll the view up" } },
            { "n", "<c-f>", actions.scroll_view(0.25), { desc = "Scroll the view down" } },
            { "n", "<tab>", actions.select_next_entry, { desc = "Open the diff for the next file" } },
            { "n", "<s-tab>", actions.select_prev_entry, { desc = "Open the diff for the previous file" } },
            { "n", "[F", actions.select_first_entry, { desc = "Open the diff for the first file" } },
            { "n", "]F", actions.select_last_entry, { desc = "Open the diff for the last file" } },
            { "n", "gf", actions.goto_file_edit, { desc = "Open the file in the previous tabpage" } },
            { "n", "<C-w><C-f>", actions.goto_file_split, { desc = "Open the file in a new split" } },
            { "n", "<C-w>gf", actions.goto_file_tab, { desc = "Open the file in a new tabpage" } },
            { "n", "g?", actions.help("file_history_panel"), { desc = "Open the help panel" } },
          },
          option_panel = {
            { "n", "<tab>", actions.select_entry, { desc = "Change the current option" } },
            { "n", "q", actions.close, { desc = "Close the panel" } },
            { "n", "g?", actions.help("option_panel"), { desc = "Open the help panel" } },
          },
          help_panel = {
            { "n", "q", actions.close, { desc = "Close help menu" } },
            { "n", "<esc>", actions.close, { desc = "Close help menu" } },
          },
        },
      })
    end,
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview" },
      { "<leader>gf", "<cmd>DiffviewFileHistory %<cr>", desc = "File History (Current)" },
      { "<leader>gF", "<cmd>DiffviewFileHistory<cr>", desc = "File History (All)" },
    },
  },
}
