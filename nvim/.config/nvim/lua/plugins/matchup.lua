return {
  {
    "andymass/vim-matchup",
    event = "VeryLazy",
    init = function()
      -- Disable built-in matchparen (the slow one)
      vim.g.loaded_matchparen = 1
    end,
    config = function()
      -- Show offscreen closing match in popup window
      vim.g.matchup_matchparen_offscreen = { method = "popup" }

      -- Enable deferred highlighting for better performance
      vim.g.matchup_matchparen_deferred = 1

      -- Set timeout to prevent blocking (in milliseconds)
      vim.g.matchup_matchparen_timeout = 300
      vim.g.matchup_matchparen_insert_timeout = 60

      -- Disable matchparen in insert mode for better performance
      vim.g.matchup_matchparen_nomode = "i"

      -- Optional: Customize highlight colors
      -- vim.g.matchup_matchparen_hi_surround_always = 1
    end,
  },
}
