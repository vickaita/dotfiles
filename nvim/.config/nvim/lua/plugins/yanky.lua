return {
  "gbprod/yanky.nvim",
  dependencies = { "ibhagwan/fzf-lua" },
  event = "VeryLazy",
  opts = {
    ring = { history_length = 100 },
    system_clipboard = {
      sync_with_ring = true,
    },
  },
  keys = {
    {
      "<leader>p",
      function()
        local history = require("yanky.history")
        local fzf = require("fzf-lua")

        local entries = {}
        local history_entries = history.all()

        for i, entry in ipairs(history_entries) do
          local content = entry.regcontents or ""
          if type(content) == "table" then
            content = table.concat(content, "\\n")
          end
          content = content:gsub("\n", "\\n")
          table.insert(entries, string.format("%d: %s", i, content))
        end

        fzf.fzf_exec(entries, {
          prompt = "Yank History> ",
          actions = {
            ["default"] = function(selected)
              if selected and #selected > 0 then
                local index = tonumber(selected[1]:match("^(%d+):"))
                if index and history_entries[index] then
                  vim.fn.setreg('"', history_entries[index].regcontents, history_entries[index].regtype)
                  vim.cmd('normal! ""p')
                end
              end
            end,
          },
        })
      end,
      desc = "Open Yank History",
    },
    { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank text" },
    { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put yanked text after cursor" },
    { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put yanked text before cursor" },
    { "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" }, desc = "Put yanked text after selection" },
    { "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" }, desc = "Put yanked text before selection" },
    { "<c-p>", "<Plug>(YankyPreviousEntry)", desc = "Select previous entry through yank history" },
    { "<c-n>", "<Plug>(YankyNextEntry)", desc = "Select next entry through yank history" },
    { "]p", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put indented after cursor (linewise)" },
    { "[p", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put indented before cursor (linewise)" },
    { "]P", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put indented after cursor (linewise)" },
    { "[P", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put indented before cursor (linewise)" },
    { ">p", "<Plug>(YankyPutIndentAfterShiftRight)", desc = "Put and indent right" },
    { "<p", "<Plug>(YankyPutIndentAfterShiftLeft)", desc = "Put and indent left" },
    { ">P", "<Plug>(YankyPutIndentBeforeShiftRight)", desc = "Put before and indent right" },
    { "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)", desc = "Put before and indent left" },
    { "=p", "<Plug>(YankyPutAfterFilter)", desc = "Put after applying a filter" },
    { "=P", "<Plug>(YankyPutBeforeFilter)", desc = "Put before applying a filter" },
  },
}

