" Minimal vim config - for quick, lightweight editing
" For full IDE features, use nvim

set nocompatible
filetype plugin indent on
syntax enable

" --- Core Settings ---
set encoding=utf-8
set hidden
set nomodeline
set mouse=a
set showcmd
set ruler
set laststatus=2
set wildmenu
set visualbell t_vb=

" --- Search ---
set hlsearch
set incsearch
set ignorecase
set smartcase

" --- Display ---
set number
set colorcolumn=81
set listchars=tab:→\ ,trail:⋅
set list
set showmatch

" --- Indentation (default: 4 spaces) ---
set expandtab
set shiftwidth=4
set tabstop=4
set softtabstop=4
set autoindent

" --- Undo ---
set undofile
set undodir=~/.vimundo

" --- Timing ---
set notimeout ttimeout ttimeoutlen=10

" --- Colorscheme ---
set termguicolors
silent! colorscheme catppuccin_mocha

" --- Keymaps ---
" Make Y behave like D and C (yank to end of line)
nnoremap Y y$

" Clear search highlighting
nnoremap <silent> <Esc> :nohlsearch<CR>

" --- Filetype-specific indentation ---
augroup filetypes
  autocmd!
  " 2-space indentation
  autocmd FileType astro,css,elixir,html,javascript,json,lua,ruby,typescript,typescriptreact,yaml
        \ setlocal shiftwidth=2 tabstop=2 softtabstop=2

  " Prose settings
  autocmd FileType markdown setlocal textwidth=80 formatoptions+=t spell
  autocmd FileType gitcommit setlocal spell

  " Recognize .mdx as markdown
  autocmd BufNewFile,BufRead *.mdx setfiletype markdown
augroup END
