-- Bash/Shell
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "bash", "sh", "zsh" },
  command = "setlocal shiftwidth=4 tabstop=4 expandtab softtabstop=4",
})

-- gitcommit
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "gitcommit" },
  command = "setlocal spell shiftwidth=4 tabstop=8 expandtab softtabstop=4",
})

-- JavaScript/TypeScript
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascript", "typescript", "javascriptreact", "typescriptreact", "jsx", "tsx" },
  command = "setlocal textwidth=80 shiftwidth=2 tabstop=2 expandtab softtabstop=2",
})

-- Make
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "make", "Makefile" },
  command = "setlocal noexpandtab tabstop=8 shiftwidth=8",
})

-- Python
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python" },
  command = "setlocal textwidth=79 shiftwidth=4 tabstop=4 expandtab softtabstop=4",
})

-- Vimwiki
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "vimwiki", "wiki" },
  command = "setlocal textwidth=80 shiftwidth=4 tabstop=4",
})


-- Web Development
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "css", "scss", "sass", "less" },
  command = "setlocal shiftwidth=2 tabstop=2 expandtab softtabstop=2",
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "html", "xml", "xhtml" },
  command = "setlocal shiftwidth=2 tabstop=2 expandtab softtabstop=2",
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "vue", "svelte" },
  command = "setlocal shiftwidth=2 tabstop=2 expandtab softtabstop=2",
})

-- Configuration & Data
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "json", "jsonc" },
  command = "setlocal shiftwidth=2 tabstop=2 expandtab softtabstop=2 conceallevel=0",
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "yaml", "yml" },
  command = "setlocal shiftwidth=2 tabstop=2 expandtab softtabstop=2",
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "toml" },
  command = "setlocal shiftwidth=2 tabstop=2 expandtab softtabstop=2",
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "dockerfile" },
  command = "setlocal shiftwidth=2 tabstop=2 expandtab softtabstop=2",
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "terraform", "tf" },
  command = "setlocal shiftwidth=2 tabstop=2 expandtab softtabstop=2",
})

-- Lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "lua" },
  command = "setlocal shiftwidth=2 tabstop=2 expandtab softtabstop=2",
})

-- Documentation & Markup
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "md" },
  command = "setlocal spell textwidth=80 shiftwidth=4 tabstop=4 expandtab softtabstop=4",
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text", "gitcommit", "rst", "asciidoc" },
  command = "setlocal wrap"
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "rst" },
  command = "setlocal spell textwidth=79 shiftwidth=3 tabstop=3 expandtab softtabstop=3",
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "tex", "latex" },
  command = "setlocal spell textwidth=80 shiftwidth=2 tabstop=2 expandtab softtabstop=2",
})

-- Programming Languages
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "rust" },
  command = "setlocal textwidth=100 shiftwidth=4 tabstop=4 expandtab softtabstop=4",
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "go" },
  command = "setlocal noexpandtab tabstop=4 shiftwidth=4",
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp", "h", "hpp" },
  command = "setlocal shiftwidth=4 tabstop=4 expandtab softtabstop=4",
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "java" },
  command = "setlocal shiftwidth=4 tabstop=4 expandtab softtabstop=4",
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "ruby" },
  command = "setlocal shiftwidth=2 tabstop=2 expandtab softtabstop=2",
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "php" },
  command = "setlocal shiftwidth=4 tabstop=4 expandtab softtabstop=4",
})

-- Restore cursor position when opening file
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local last_pos = vim.fn.line("'\"")
    if last_pos > 1 and last_pos <= vim.fn.line("$") then
      vim.api.nvim_win_set_cursor(0, { last_pos, 0 })
    end
  end,
})

-- Terminal settings
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
  end,
})
