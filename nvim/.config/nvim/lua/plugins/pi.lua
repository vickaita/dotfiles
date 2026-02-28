if vim.g.vscode then
  return {}
end

return {
  {
    "pablopunk/pi.nvim",
    keys = {
      { "<leader>ai", ":PiAsk<CR>", desc = "Ask pi", mode = "n" },
      { "<leader>ai", ":PiAskSelection<CR>", desc = "Ask pi (selection)", mode = "v" },
    },
    config = function()
      require("pi").setup()
    end,
  },
}
