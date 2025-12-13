--[[
WORKAROUND: fzf-lua LSP Call Hierarchy Integration

This module provides wrapper functions for LSP incoming/outgoing calls that display
results in fzf-lua instead of the default quickfix window.

WHY THIS WORKAROUND EXISTS:
- fzf-lua's native `lsp_incoming_calls` and `lsp_outgoing_calls` functions fail with
  "Method not found: callHierarchy/incomingCalls" errors
- The standard `vim.lsp.buf.incoming_calls()` works correctly but opens quickfix window
- This wrapper bridges the gap: uses working LSP functions, displays in fzf-lua

HOW IT WORKS:
1. Sets up a FileType autocmd to detect when quickfix window opens
2. Calls vim.lsp.buf.incoming_calls() which populates quickfix and opens the window
3. When quickfix window opens (FileType qf event), immediately closes it
4. Reads the quickfix list contents and displays them in fzf-lua's quickfix picker
5. Uses vim.schedule() to defer operations and avoid buffer editing conflicts

TODO: Check if fzf-lua has fixed the native implementation
To test if this workaround is still needed:

1. Check fzf-lua updates:
   - Run: :Lazy update fzf-lua
   - Check GitHub: https://github.com/ibhagwan/fzf-lua/issues
   - Search for issues related to "incoming_calls" or "callHierarchy"

2. Test the native implementation:
   In a test file, try calling directly:
   :lua require('fzf-lua').lsp_incoming_calls()

   If it works without "Method not found" errors, the bug is fixed!

3. Once fixed, replace this workaround with direct fzf-lua calls:

   In lua/plugins/lsp.lua, change:
   FROM:
     vim.keymap.set("n", "<leader>ci",
       function() require('util.lsp').incoming_calls_with_fzf({ jump1 = true }) end,
       { desc = "Incoming calls" })

   TO:
     vim.keymap.set("n", "<leader>ci",
       "<cmd>FzfLua lsp_incoming_calls jump1=true<cr>",
       { desc = "Incoming calls" })

   (Same for <leader>co with lsp_outgoing_calls)

4. Then delete this util/lsp.lua file as it's no longer needed.
--]]

local M = {}

--- Wrapper for vim.lsp.buf.incoming_calls that displays results in fzf-lua
---
--- This is a workaround because fzf-lua's native lsp_incoming_calls gives
--- "Method not found" errors. We use vim.lsp.buf.incoming_calls (which works)
--- and intercept the quickfix window to redirect results to fzf-lua.
---
--- @param opts table|nil Options table with optional jump1 boolean
function M.incoming_calls_with_fzf(opts)
  opts = opts or {}

  -- Clear quickfix to ensure fresh results
  vim.fn.setqflist({}, 'r')

  -- Create autocmd to intercept quickfix window opening
  local augroup = vim.api.nvim_create_augroup('LspIncomingCallsToFzf', { clear = true })

  vim.api.nvim_create_autocmd('FileType', {
    group = augroup,
    pattern = 'qf',
    once = true,
    callback = function()
      -- Defer all operations to avoid "not allowed to edit another buffer" error
      vim.schedule(function()
        -- Close quickfix window
        vim.cmd('cclose')

        -- Get the populated quickfix list
        local qf_list = vim.fn.getqflist()

        if #qf_list == 0 then
          vim.notify('No incoming calls found', vim.log.levels.INFO)
        elseif opts.jump1 and #qf_list == 1 then
          -- Jump directly to single result
          local item = qf_list[1]
          vim.cmd('edit ' .. vim.fn.bufname(item.bufnr))
          vim.api.nvim_win_set_cursor(0, {item.lnum, item.col - 1})
        else
          -- Open fzf-lua quickfix picker
          require('fzf-lua').quickfix()
        end

        -- Cleanup
        pcall(vim.api.nvim_del_augroup_by_id, augroup)
      end)
    end,
  })

  -- Fallback timeout to cleanup if autocmd never fires
  vim.defer_fn(function()
    pcall(vim.api.nvim_del_augroup_by_id, augroup)
  end, 5000)

  -- Call the LSP function
  vim.lsp.buf.incoming_calls()
end

--- Wrapper for vim.lsp.buf.outgoing_calls that displays results in fzf-lua
---
--- This is a workaround because fzf-lua's native lsp_outgoing_calls gives
--- "Method not found" errors. We use vim.lsp.buf.outgoing_calls (which works)
--- and intercept the quickfix window to redirect results to fzf-lua.
---
--- @param opts table|nil Options table with optional jump1 boolean
function M.outgoing_calls_with_fzf(opts)
  opts = opts or {}

  vim.fn.setqflist({}, 'r')

  local augroup = vim.api.nvim_create_augroup('LspOutgoingCallsToFzf', { clear = true })

  vim.api.nvim_create_autocmd('FileType', {
    group = augroup,
    pattern = 'qf',
    once = true,
    callback = function()
      -- Defer all operations to avoid "not allowed to edit another buffer" error
      vim.schedule(function()
        -- Close quickfix window
        vim.cmd('cclose')

        local qf_list = vim.fn.getqflist()

        if #qf_list == 0 then
          vim.notify('No outgoing calls found', vim.log.levels.INFO)
        elseif opts.jump1 and #qf_list == 1 then
          local item = qf_list[1]
          vim.cmd('edit ' .. vim.fn.bufname(item.bufnr))
          vim.api.nvim_win_set_cursor(0, {item.lnum, item.col - 1})
        else
          require('fzf-lua').quickfix()
        end

        pcall(vim.api.nvim_del_augroup_by_id, augroup)
      end)
    end,
  })

  vim.defer_fn(function()
    pcall(vim.api.nvim_del_augroup_by_id, augroup)
  end, 5000)

  vim.lsp.buf.outgoing_calls()
end

return M
