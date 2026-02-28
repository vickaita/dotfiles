if vim.g.vscode then
  return {}
end

return {
  "chentoast/marks.nvim",
  event = "VeryLazy",
  config = function()
    require("marks").setup({})
  end,
}
