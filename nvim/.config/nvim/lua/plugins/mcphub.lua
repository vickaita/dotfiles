if vim.g.vscode then
  return {}
end

return {
  {
    "ravitemer/mcphub.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    -- Use bundled local installation (no global npm install needed)
    build = "bundled_build.lua",
    opts = {
      -- Use the bundled binary instead of global install
      use_bundled_binary = true,

      -- MCP servers configuration
      -- Start with empty array - add servers as needed
      mcp_servers = {},

      -- Example MCP servers (commented out):
      -- mcp_servers = {
      --   -- Filesystem MCP
      --   {
      --     name = "filesystem",
      --     command = "npx",
      --     args = { "@modelcontextprotocol/server-filesystem", vim.fn.expand("~") },
      --   },
      --
      --   -- Web search (requires BRAVE_API_KEY)
      --   {
      --     name = "brave-search",
      --     command = "npx",
      --     args = { "@modelcontextprotocol/server-brave-search" },
      --     env = {
      --       BRAVE_API_KEY = vim.env.BRAVE_API_KEY,
      --     },
      --   },
      --
      --   -- GitHub MCP (requires GITHUB_TOKEN)
      --   {
      --     name = "github",
      --     command = "npx",
      --     args = { "@modelcontextprotocol/server-github" },
      --     env = {
      --       GITHUB_TOKEN = vim.env.GITHUB_TOKEN,
      --     },
      --   },
      -- },

      -- Server management settings
      auto_start = true, -- Auto-start MCP servers
      log_level = "info", -- Logging level: "debug", "info", "warn", "error"
    },

    keys = {
      { "<leader>aM", "<cmd>MCPHub<cr>", desc = "MCP Hub Manager" },
      { "<leader>aS", "<cmd>MCPHubStatus<cr>", desc = "MCP Status" },
    },

    config = function(_, opts)
      require("mcphub").setup(opts)
    end,
  },
}
