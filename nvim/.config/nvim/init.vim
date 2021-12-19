" Edit this file
command! EditVimConfig :edit ~/.config/nvim/init.vim
command! EditLuaConfig :edit ~/.config/nvim/lua/plugins.lua

lua require('plugins')

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
