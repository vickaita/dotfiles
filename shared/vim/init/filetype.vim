set shiftwidth=4 tabstop=4 softtabstop=4 autoindent expandtab

autocmd BufNewFile,BufRead *.mdx set filetype=markdown

autocmd FileType css        setlocal shiftwidth=2 tabstop=2 softtabstop=2
autocmd FileType elixir     setlocal shiftwidth=2 tabstop=2 softtabstop=2
autocmd FileType html       setlocal shiftwidth=2 tabstop=2 softtabstop=2
autocmd FileType javascript setlocal shiftwidth=2 tabstop=2 softtabstop=2
autocmd FileType lua        setlocal shiftwidth=2 tabstop=2 softtabstop=2
autocmd FileType markdown   setlocal textwidth=80 formatoptions+=t spell
autocmd FileType python     let b:indent_blankline_enabled = 1
autocmd FileType ruby       setlocal shiftwidth=2 tabstop=2 softtabstop=2
autocmd FileType typescript setlocal shiftwidth=2 tabstop=2 softtabstop=2
autocmd FileType yaml       setlocal shiftwidth=2 tabstop=2 softtabstop=2
autocmd FileType clojure    nnoremap <buffer> <C-j> :Eval<CR>
