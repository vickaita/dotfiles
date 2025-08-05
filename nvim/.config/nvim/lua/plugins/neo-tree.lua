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
      filesystem = {
        window = {
          position = "left",
          width = 30,
        },
      },
      window = {
        position = "left",
        width = 30,
        mapping_options = {
          noremap = true,
          nowait = true,
        },
      },
      -- Enable mouse support
      enable_mouse_support = true,
    },
    config = function(_, opts)
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
