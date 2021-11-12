" Vimwiki
let g:vimwiki_list = [{'path': '~/vimwiki/'}]

"" So that list completion will work with hard returns
autocmd FileType vimwiki inoremap <silent><buffer> <CR> <C-]><Esc>:VimwikiReturn 3 5<CR>
autocmd FileType vimwiki inoremap <silent><buffer> <S-CR> <Esc>:VimwikiReturn 2 2<CR>

