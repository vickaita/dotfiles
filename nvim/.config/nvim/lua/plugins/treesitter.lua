if vim.g.vscode then
  return {}
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    dependencies = {
      { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
      "nvim-treesitter/nvim-treesitter-context",
      "andymass/vim-matchup",
    },
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "diff",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
      },
      textobjects = {
        select = {
          lookahead = true, -- Automatically jump forward to textobj
          keymaps = {
            -- You can use the capture groups defined in textobjects.scm
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
            ["aa"] = "@parameter.outer",
            ["ia"] = "@parameter.inner",
            ["al"] = "@loop.outer",
            ["il"] = "@loop.inner",
            ["ai"] = "@conditional.outer",
            ["ii"] = "@conditional.inner",
            ["a/"] = "@comment.outer",
            ["i/"] = "@comment.inner",
            ["ab"] = "@block.outer",
            ["ib"] = "@block.inner",
            ["as"] = "@statement.outer",
            ["is"] = "@statement.inner",
            ["ad"] = "@assignment.outer",
            ["id"] = "@assignment.inner",
            ["sl"] = "@assignment.lhs",
            ["sr"] = "@assignment.rhs",
          },
        },
        move = {
          set_jumps = true, -- whether to set jumps in the jumplist
          goto_next_start = {
            ["]m"] = "@function.outer",
            ["]]"] = { query = "@class.outer", desc = "Next class start" },
            ["]o"] = { "@loop.inner", "@loop.outer" },
            ["]s"] = { query = "@local.scope", query_group = "locals", desc = "Next scope" },
            ["]z"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
          },
          goto_next_end = {
            ["]M"] = "@function.outer",
            ["]["] = "@class.outer",
          },
          goto_previous_start = {
            ["[m"] = "@function.outer",
            ["[["] = "@class.outer",
            ["[o"] = { "@loop.inner", "@loop.outer" },
            ["[s"] = { query = "@local.scope", query_group = "locals", desc = "Previous scope" },
            ["[z"] = { query = "@fold", query_group = "folds", desc = "Previous fold" },
          },
          goto_previous_end = {
            ["[M"] = "@function.outer",
            ["[]"] = "@class.outer",
          },
        },
        swap = {
          swap_next = {
            ["<leader>cn"] = "@parameter.inner",
          },
          swap_previous = {
            ["<leader>cp"] = "@parameter.inner",
          },
        },
      },
    },
    config = function(_, opts)
      local ts = require("nvim-treesitter")
      ts.setup({})
      -- The JSON grammar now includes comments; jsonc is no longer a separate parser.
      vim.treesitter.language.register("json", "jsonc")
      -- Keep ensure_installed as a local option so language specs can extend it.
      ts.install(opts.ensure_installed)

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("DotfilesTreesitter", { clear = true }),
        callback = function(event)
          local lang = vim.treesitter.language.get_lang(vim.bo[event.buf].filetype)
          if lang and vim.treesitter.language.add(lang) then
            vim.treesitter.start(event.buf, lang)
            vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })

      local objects = opts.textobjects
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = objects.select.lookahead },
        move = { set_jumps = objects.move.set_jumps },
      })
      for key, capture in pairs(objects.select.keymaps) do
        vim.keymap.set({ "x", "o" }, key, function()
          require("nvim-treesitter-textobjects.select").select_textobject(capture, "textobjects")
        end)
      end
      for _, method in ipairs({ "goto_next_start", "goto_next_end", "goto_previous_start", "goto_previous_end" }) do
        for key, mapping in pairs(objects.move[method]) do
          local capture = type(mapping) == "table" and mapping.query or mapping
          local group = type(mapping) == "table" and mapping.query_group or "textobjects"
          vim.keymap.set({ "n", "x", "o" }, key, function()
            require("nvim-treesitter-textobjects.move")[method](capture, group or "textobjects")
          end, { desc = type(mapping) == "table" and mapping.desc or nil })
        end
      end
      for _, method in ipairs({ "swap_next", "swap_previous" }) do
        for key, capture in pairs(objects.swap[method]) do
          vim.keymap.set("n", key, function()
            require("nvim-treesitter-textobjects.swap")[method](capture)
          end)
        end
      end
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    opts = {
      enable = true,
      max_lines = 0,
      min_window_height = 0,
      line_numbers = true,
      multiline_threshold = 20,
      trim_scope = "outer",
      mode = "topline",
      separator = nil,
      zindex = 20,
    },
  },
}

