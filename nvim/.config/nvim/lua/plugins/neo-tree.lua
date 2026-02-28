if vim.g.vscode then
  return {}
end

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
      -- {"3rd/image.nvim", opts = {}}, -- Optional image support in preview window: See `# Preview Mode` for more information
    },
    lazy = false, -- neo-tree will lazily load itself
    keys = {
      { "<leader>ue", "<cmd>Neotree toggle<cr>", desc = "Toggle file explorer" },
    },
    ---@module "neo-tree"
    ---@type neotree.Config?
    opts = {
      open_files_do_not_replace_types = { "terminal", "trouble", "qf" },
      filesystem = {
        window = {
          position = "left",
          width = 60,
        },
      },
      event_handlers = {
        {
          event = "file_open_requested",
          handler = function()
            if vim.g.neo_tree_auto_close then
              require("neo-tree.command").execute({ action = "close" })
            end
          end,
        },
      },
      window = {
        position = "left",
        width = 60,
        mapping_options = {
          noremap = true,
          nowait = true,
        },
      },
      -- Enable mouse support
      enable_mouse_support = true,
    },
    config = function(_, opts)
      if vim.g.neo_tree_auto_close == nil then
        vim.g.neo_tree_auto_close = true
      end
      require("neo-tree").setup(opts)
      
      -- Open neo-tree by default if configured via neoconf
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          if vim.fn.argc() == 0 then
            -- Check neoconf setting, default to false (hidden)
            local ok, neoconf = pcall(require, "neoconf")
            local auto_open = false
            if ok then
              auto_open = neoconf.get("custom.file_explorer_auto_open", false)
            end
            
            if auto_open then
              vim.schedule(function()
                vim.cmd("Neotree show")
              end)
            end
          end
        end,
      })
    end,
  },
}
