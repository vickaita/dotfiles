if vim.g.vscode then
  return {}
end

local function show_git_hunks(diff_cmd, prompt)
  return function()
    local fzf = require("fzf-lua")
    local output = vim.fn.systemlist(diff_cmd)
    local hunks = {}
    local current_file = nil

    for _, line in ipairs(output) do
      if line:match("^%+%+%+ b/(.+)") then
        current_file = line:match("^%+%+%+ b/(.+)")
      elseif line:match("^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@(.*)") then
        local _, _, new_start, new_count, context = line:match("^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@(.*)")
        if current_file then
          table.insert(hunks, {
            filename = current_file,
            lnum = tonumber(new_start),
            text = context:gsub("^%s+", ""),
          })
        end
      end
    end

    local entries = {}
    for _, hunk in ipairs(hunks) do
      table.insert(entries, string.format("%s:%d: %s", hunk.filename, hunk.lnum, hunk.text))
    end

    -- Determine the git diff command for preview based on input
    local preview_diff_cmd = diff_cmd:gsub("--unified=0", "-U10")

    fzf.fzf_exec(entries, {
      prompt = prompt,
      actions = {
        ["default"] = function(selected)
          if selected and selected[1] then
            local file, lnum = selected[1]:match("^([^:]+):(%d+):")
            if file and lnum then
              vim.cmd("edit " .. file)
              vim.api.nvim_win_set_cursor(0, {tonumber(lnum), 0})
            end
          end
        end,
      },
      fzf_opts = {
        ["--preview"] = string.format([[
          file=$(echo {} | cut -d: -f1)
          line=$(echo {} | cut -d: -f2)
          %s -- "$file" | awk -v line="$line" '
            BEGIN { in_hunk=0; found=0 }
            /^@@/ {
              # Extract +start,count from hunk header like "@@ -10,5 +20,8 @@"
              for (i=1; i<=NF; i++) {
                if ($i ~ /^\+[0-9]/) {
                  split($i, parts, ",")
                  hunk_start = substr(parts[1], 2)
                  hunk_count = parts[2] ? parts[2] : 1
                  hunk_end = hunk_start + hunk_count - 1
                  break
                }
              }
              if (line >= hunk_start && line <= hunk_end) {
                in_hunk = 1
                found = 1
                print $0
                next
              }
              in_hunk = 0
            }
            in_hunk { print }
            END { if (!found) exit 1 }
          ' | delta --line-numbers
        ]], preview_diff_cmd),
      },
    })
  end
end

return {
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Live grep" },
      { "<leader>fG", function() require("fzf-lua").live_grep({ hidden = true, no_ignore = true }) end, desc = "Live grep (hidden + no ignore)" },
      { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
      { "<leader>fH", "<cmd>FzfLua help_tags<cr>", desc = "Help tags" },
      { "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Recent files" },
      { "<leader>fc", "<cmd>FzfLua commands<cr>", desc = "Commands" },
      { "<leader>fk", "<cmd>FzfLua keymaps<cr>", desc = "Keymaps" },
      { "<leader>fs", "<cmd>FzfLua lsp_document_symbols<cr>", desc = "Document symbols" },
      { "<leader>fw", "<cmd>FzfLua lsp_workspace_symbols<cr>", desc = "Workspace symbols" },
      { "<leader>fhu", show_git_hunks("git diff --unified=0", "Git Hunks (Unstaged)> "), desc = "Git hunks (unstaged)" },
      { "<leader>fhs", show_git_hunks("git diff --cached --unified=0", "Git Hunks (Staged)> "), desc = "Git hunks (staged)" },
      { "<leader>fha", show_git_hunks("git diff HEAD --unified=0", "Git Hunks (All)> "), desc = "Git hunks (all)" },
      { "<leader>fhf", "<cmd>FzfLua git_status<cr>", desc = "Git changed files" },
      { "<leader>fq", "<cmd>FzfLua quickfix<cr>", desc = "Quickfix list" },
    },
    config = function(_, opts)
      require("fzf-lua").setup(opts)
      require("fzf-lua").register_ui_select()
    end,
    opts = {
      winopts = {
        height = 0.85,
        width = 0.80,
        row = 0.35,
        col = 0.50,
        border = "rounded",
        preview = {
          scrollchars = { "┃", "" },
        },
      },
      keymap = {
        fzf = {
          ["ctrl-q"] = "select-all+accept",
        },
      },
      previewers = {
        cat = {
          cmd = "cat",
          args = "--number",
        },
        bat = {
          cmd = "bat",
          args = "--style=numbers,changes --color always",
        },
        head = {
          cmd = "head",
          args = nil,
        },
        git_diff = {
          cmd_deleted = "git show HEAD:{file}",
          cmd_modified = "git diff HEAD -- {file}",
          cmd_untracked = "git diff --no-index /dev/null {file}",
        },
      },
      files = {
        find_opts = [[-type f -not -path '*/\.git/*' -printf '%P\n']],
        rg_opts = "--color=never --files --hidden --follow -g '!.git'",
        fd_opts = "--color=never --type f --hidden --follow --exclude .git",
      },
      grep = {
        rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e",
        grep_opts = "--binary-files=without-match --line-number --recursive --color=auto --perl-regexp -e",
      },
    },
  },
}