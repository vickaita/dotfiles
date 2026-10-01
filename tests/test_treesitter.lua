-- Run from the repository root: nvim --headless -i NONE '+lua dofile("tests/test_treesitter.lua")'
local ok, err = pcall(function()
  vim.cmd.edit('README.markdown')
  local parser = assert(vim.treesitter.get_parser(0), 'Markdown parser missing')
  assert(#parser:parse(true) > 0, 'Markdown did not parse')
  assert(next(parser:children()), 'Fenced code injections missing')
  assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], 'Highlighting missing')
  vim.cmd.enew()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { '// comment', '{"enabled": true}' })
  vim.bo.filetype = 'jsonc'
  local json = assert(vim.treesitter.get_parser(0), 'JSONC parser missing')
  assert(not json:parse(true)[1]:root():has_error(), 'JSONC comments did not parse')
  vim.cmd.enew()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    'local function first(a, b)', '  return a + b', 'end',
    'local function second()', '  return 2', 'end',
  })
  vim.bo.filetype = 'lua'
  assert(vim.treesitter.get_parser(0):parse(true))
  assert(vim.bo.indentexpr ~= '', 'Treesitter indentation missing')
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.cmd.normal(']m')
  assert(vim.api.nvim_win_get_cursor(0)[1] == 4, 'Next-function motion failed')
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.cmd.normal('vaf')
  assert(vim.fn.mode() == 'v', 'Function textobject selection failed')
  assert(vim.api.nvim_win_get_cursor(0)[1] == 3, 'Function textobject selected wrong range')
end)
if not ok then
  io.stderr:write(tostring(err) .. '\n')
  vim.cmd.cquit()
end
print('Treesitter parsing, injections, highlighting, indentation, and textobjects passed')
vim.cmd('qa!')
