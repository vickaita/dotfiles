lua require('plugins')

set nocompatible
set expandtab
set encoding=utf-8
set showcmd
set showmatch
set mouse=a
set hlsearch
set incsearch
set ignorecase
set smartcase
set number
set ruler
set colorcolumn=81
highlight ColorColumn term=reverse ctermbg=7
set listchars=tab:▸\ ,trail:•
set list!
set wildmenu
set undofile
set undodir=~/.vimundo
set nomodeline
set hidden
set termguicolors
set laststatus=2
filetype plugin on
filetype indent on

" Quickly time out on keycodes, but never time out on mappings
set notimeout ttimeout ttimeoutlen=10

" Suppress bell
set visualbell
set vb t_vb=

source ~/.config/nvim/colorscheme.vim
source ~/.config/nvim/coc.vim
source ~/.config/nvim/fzf.vim
source ~/.config/nvim/vimwiki.vim
source ~/.config/nvim/ctags.vim

" Autopairs
let g:AutoPairsFlyMode = 0

" NERDTree
nnoremap <leader>n :NERDTreeToggle<CR>

" Edit this file
command! EditConfig :edit ~/.config/nvim/init.vim

set shiftwidth=4 tabstop=4 softtabstop=4 autoindent expandtab

autocmd BufNewFile,BufRead *.mdx set filetype=markdown

autocmd FileType css        setlocal shiftwidth=2 tabstop=2 softtabstop=2 autoindent expandtab
autocmd FileType html       setlocal shiftwidth=2 tabstop=2 softtabstop=2 autoindent expandtab
autocmd FileType javascript setlocal shiftwidth=2 tabstop=2 softtabstop=2 autoindent expandtab
autocmd FileType markdown   setlocal textwidth=80 formatoptions+=t spell
autocmd FileType ruby       setlocal shiftwidth=2 tabstop=2 softtabstop=2 autoindent expandtab
autocmd FileType typescript setlocal shiftwidth=2 tabstop=2 softtabstop=2 autoindent expandtab
autocmd FileType yaml       setlocal shiftwidth=2 tabstop=2 softtabstop=2 autoindent expandtab
autocmd FileType clojure    nnoremap <buffer> <C-j> :Eval<CR>
autocmd BufRead,BufNewFile *.am set filetype=ambient
