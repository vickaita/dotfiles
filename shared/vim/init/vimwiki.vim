" Vimwiki
let g:vimwiki_list = [{'path': '~/wiki/'}]

"" So that list completion will work with hard returns
autocmd FileType vimwiki inoremap <silent><buffer> <CR> <C-]><Esc>:VimwikiReturn 3 5<CR>
autocmd FileType vimwiki inoremap <silent><buffer> <S-CR> <Esc>:VimwikiReturn 2 2<CR>

"" Open tagbar automatically in a vimwiki file
" autocmd FileType vimwiki nested :call tagbar#autoopen(0)


"" Fix the tab completion for vimwiki with copilot
autocmd FileType vimwiki imap <silent><script><expr> <C-J> copilot#Accept("\<CR>")
autocmd FileType vimwiki let g:copilot_no_tab_map = v:true
