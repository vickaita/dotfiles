command! EditVimConfig :edit ~/.config/nvim/init.vim

if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

let g:coc_global_extensions = [
      \ 'coc-css',
      \ 'coc-diagnostic',
      \ 'coc-eslint',
      \ 'coc-elixir',
      \ 'coc-html',
      \ 'coc-jest',
      \ 'coc-json',
      \ 'coc-prettier',
      \ 'coc-pyright',
      \ 'coc-spell-checker',
      \ 'coc-tabnine',
      \ 'coc-tsserver',
      \ 'coc-rls',
      \ 'coc-yaml',
      \ ]

call plug#begin('~/.vim/plugged')
Plug 'SirVer/ultisnips'
Plug 'airblade/vim-gitgutter'
Plug 'arcticicestudio/nord-vim'
Plug 'clojure-vim/vim-jack-in'
Plug 'eraserhd/parinfer-rust', {'do': 'cargo build --release'}
Plug 'honza/vim-snippets'
Plug 'jiangmiao/auto-pairs'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'lifepillar/vim-solarized8'
Plug 'neoclide/coc.nvim', {'branch': 'release', 'do': {-> coc#util#install()}}
Plug 'Olical/conjure', {'tag': 'v4.22.1'}
Plug 'preservim/tagbar'
Plug 'radenling/vim-dispatch-neovim' " Only in Neovim:
Plug 'simnalamburt/vim-mundo'
Plug 'sheerun/vim-polyglot'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-dispatch'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-fireplace'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-markdown'
Plug 'tpope/vim-surround'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'vim-nerdtree/nerdtree'
Plug 'vim-test/vim-test'
Plug 'vimwiki/vimwiki'
call plug#end()

" TODO: set the `.dotfiles` directory from the environment variable instead of
"       hard coding it.
source ~/.dotfiles/shared/vim/init/base.vim
source ~/.dotfiles/shared/vim/init/coc.vim
source ~/.dotfiles/shared/vim/init/colorscheme.vim
source ~/.dotfiles/shared/vim/init/ctags.vim
source ~/.dotfiles/shared/vim/init/filetype.vim
source ~/.dotfiles/shared/vim/init/fzf.vim
source ~/.dotfiles/shared/vim/init/nerdtree.vim
source ~/.dotfiles/shared/vim/init/vimwiki.vim

" Autopairs
let g:AutoPairsFlyMode = 0

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
