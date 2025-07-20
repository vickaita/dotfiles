local M = {}

-- Toggle line numbers between off, regular, and relative
function M.toggle_line_numbers()
  if not vim.opt.number:get() then
    vim.opt.number = true
    vim.opt.relativenumber = false
  elseif vim.opt.relativenumber:get() then
    vim.opt.relativenumber = false
  else
    vim.opt.relativenumber = true
  end
end

-- Toggle vertical ruler (colorcolumn)
function M.toggle_vertical_ruler()
  if vim.opt.colorcolumn:get()[1] then
    vim.opt.colorcolumn = ""
  else
    vim.opt.colorcolumn = "+1"
  end
end

-- Toggle text wrapping
function M.toggle_text_wrap()
  vim.opt.wrap = not vim.opt.wrap:get()
end

-- Toggle overflow text highlighting
function M.toggle_overflow_highlighting()
  local textwidth = vim.opt.textwidth:get()
  if textwidth == 0 then
    vim.notify("textwidth is not set", vim.log.levels.WARN)
    return
  end
  
  if vim.w.overflow_match then
    vim.fn.matchdelete(vim.w.overflow_match)
    vim.w.overflow_match = nil
  else
    vim.w.overflow_match = vim.fn.matchadd("ErrorMsg", "\\%>" .. textwidth .. "v.\\+")
  end
end

return M