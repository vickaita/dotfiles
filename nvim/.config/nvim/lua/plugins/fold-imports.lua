if vim.g.vscode then
  return {}
end

return {
  {
    "dmtrKovalenko/fold-imports.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("fold_imports").setup({
        auto_fold = false, -- disable automatic refolding
        fold_level = 0,
      })

      -- Track which buffers have had their imports folded
      local folded_buffers = {}

      -- Only fold imports when buffer is first opened
      vim.api.nvim_create_autocmd("BufReadPost", {
        callback = function(ev)
          local bufnr = ev.buf
          if not folded_buffers[bufnr] then
            vim.schedule(function()
              vim.cmd("FoldImports")
              folded_buffers[bufnr] = true
            end)
          end
        end,
      })

      -- Clean up tracking when buffer is deleted
      vim.api.nvim_create_autocmd("BufDelete", {
        callback = function(ev)
          folded_buffers[ev.buf] = nil
        end,
      })
    end,
  },
}
