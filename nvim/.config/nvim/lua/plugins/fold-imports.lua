if vim.g.vscode then
  return {}
end

-- Initialize global state early
if vim.g.auto_import_folding_enabled == nil then
  vim.g.auto_import_folding_enabled = true
end

return {
  {
    "dmtrKovalenko/fold-imports.nvim",
    event = { "BufReadPost", "BufNewFile" },
    keys = {
      {
        "<leader>ui",
        function()
          vim.g.auto_import_folding_enabled = not vim.g.auto_import_folding_enabled
          if vim.g.auto_import_folding_enabled then
            vim.notify("Auto import folding enabled", vim.log.levels.INFO)
          else
            vim.notify("Auto import folding disabled", vim.log.levels.INFO)
          end
        end,
        desc = "Toggle auto import folding",
      },
    },
    config = function()
      require("fold_imports").setup({
        auto_fold = false, -- disable automatic refolding
        fold_level = 0,
      })

      -- Track which buffers have had their imports folded
      local folded_buffers = {}

      -- Only fold imports when buffer is first opened
      local autocmd_id = vim.api.nvim_create_autocmd("BufReadPost", {
        callback = function(ev)
          if not vim.g.auto_import_folding_enabled then
            return
          end

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
