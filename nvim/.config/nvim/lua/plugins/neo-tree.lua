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
    },
    config = function(_, opts)
      require("neo-tree").setup(opts)
      
      -- Open neo-tree by default
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          if vim.fn.argc() == 0 then
            vim.schedule(function()
              vim.cmd("Neotree show")
            end)
          end
        end,
      })
    end,
  },
}
