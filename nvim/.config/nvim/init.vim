lua require('plugins')

" TODO: set the `.dotfiles` directory from the environment variable instead of
"       hard coding it.
source ~/.dotfiles/shared/vim/init/base.vim
source ~/.dotfiles/shared/vim/init/coc.vim
source ~/.dotfiles/shared/vim/init/colorscheme.vim
source ~/.dotfiles/shared/vim/init/ctags.vim
source ~/.dotfiles/shared/vim/init/fzf.vim
source ~/.dotfiles/shared/vim/init/nerdtree.vim
source ~/.dotfiles/shared/vim/init/vimwiki.vim

" Autopairs
" let g:AutoPairsFlyMode = 0

" Edit this file
command! EditConfig :edit ~/.config/nvim/init.vim

set shiftwidth=4 tabstop=4 softtabstop=4 autoindent expandtab

autocmd BufNewFile,BufRead *.mdx set filetype=markdown

autocmd FileType css        setlocal shiftwidth=2 tabstop=2 softtabstop=2
autocmd FileType html       setlocal shiftwidth=2 tabstop=2 softtabstop=2
autocmd FileType javascript setlocal shiftwidth=2 tabstop=2 softtabstop=2
autocmd FileType lua        setlocal shiftwidth=2 tabstop=2 softtabstop=2
autocmd FileType markdown   setlocal textwidth=80 formatoptions+=t spell
autocmd FileType python     let b:indent_blankline_enabled = 1
autocmd FileType ruby       setlocal shiftwidth=2 tabstop=2 softtabstop=2
autocmd FileType typescript setlocal shiftwidth=2 tabstop=2 softtabstop=2
autocmd FileType yaml       setlocal shiftwidth=2 tabstop=2 softtabstop=2
autocmd FileType clojure    nnoremap <buffer> <C-j> :Eval<CR>
