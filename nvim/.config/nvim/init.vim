if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

let g:coc_global_extensions = [
      \ 'coc-conjure',
      \ 'coc-css',
      \ 'coc-diagnostic',
      \ 'coc-eslint',
      \ 'coc-elixir',
      \ 'coc-html',
      \ 'coc-jest',
      \ 'coc-json',
      \ 'coc-prettier',
      \ 'coc-tabnine',
      \ 'coc-tsserver',
      \ 'coc-rls',
      \ 'coc-yaml',
      \ ]

call plug#begin('~/.config/nvim/plugged')
Plug 'HerringtonDarkholme/yats.vim'
Plug 'LnL7/vim-nix'
Plug 'airblade/vim-gitgutter'
Plug 'alx741/vim-hindent' " Optional
Plug 'cespare/vim-toml'
Plug 'elixir-editors/vim-elixir'
Plug 'jiangmiao/auto-pairs'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'lifepillar/vim-solarized8'
Plug 'neoclide/coc.nvim', {'branch': 'release', 'do': {-> coc#util#install()}}
Plug 'neovimhaskell/haskell-vim'
Plug 'preservim/tagbar'
Plug 'simnalamburt/vim-mundo'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'vim-nerdtree/nerdtree'
Plug 'vim-test/vim-test'
Plug 'vimwiki/vimwiki'
call plug#end()

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

set background=light
colorscheme solarized8_flat
let g:airline_theme='solarized'

" Quickly time out on keycodes, but never time out on mappings
set notimeout ttimeout ttimeoutlen=10

" Suppress bell
set visualbell
set vb t_vb=

" FZF
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview('up:60%')
  \           : fzf#vim#with_preview('right:50%:hidden', '?'),
  \   <bang>0)
nnoremap <C-x><C-b> :Buffers<CR>
nnoremap <C-x><C-f> :Files<CR>
nnoremap <C-x><C-g> :GFiles<CR>

" NERDTree
nnoremap <leader>n :NERDTreeToggle<CR>

" Coc.nvim
" Use `[g` and `]g` to navigate diagnostics
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
nmap <silent> ge <Plug>(coc-diagnostic-info)

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Highlight symbol under cursor on CursorHold
autocmd CursorHold * silent call CocActionAsync('highlight')

" Remap for rename current word
nmap <leader>rn <Plug>(coc-rename)

" Remap for format selected region
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

" Coc Prettier
command! -nargs=0 Prettier :CocCommand prettier.formatFile

" Oraganize imports
command! -nargs=0 OrganizeImports :CocCommand tsserver.organizeImports

" Cleanup
nmap <leader>c :Prettier<CR>OrganizeImports<CR>

" Run jest for current project
command! -nargs=0 Jest :call  CocAction('runCommand', 'jest.projectTest')

" Run jest for current file
command! -nargs=0 JestCurrent :call  CocAction('runCommand', 'jest.fileTest', ['%'])

" Run jest for current test
nnoremap <leader>te :call CocAction('runCommand', 'jest.singleTest')<CR>

" Init jest in current cwd, require global jest command exists
command! JestInit :call CocAction('runCommand', 'jest.init')
" end Coc.nvim

" Vimwiki
let g:vimwiki_list = [{'path': '~/vimwiki/', 'syntax': 'markdown', 'ext': '.md'}]

set shiftwidth=2 tabstop=8 softtabstop=2 autoindent expandtab

autocmd FileType css        setlocal shiftwidth=2 tabstop=2 softtabstop=2 autoindent expandtab
autocmd FileType html       setlocal shiftwidth=2 tabstop=2 softtabstop=2 autoindent expandtab
autocmd FileType javascript setlocal shiftwidth=2 tabstop=2 softtabstop=2 autoindent expandtab
autocmd FileType ruby       setlocal shiftwidth=2 tabstop=2 softtabstop=2 autoindent expandtab
autocmd FileType typescript setlocal shiftwidth=2 tabstop=2 softtabstop=2 autoindent expandtab
autocmd FileType yaml       setlocal shiftwidth=2 tabstop=2 softtabstop=2 autoindent expandtab
