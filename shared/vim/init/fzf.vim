" " FZF
" command! -bang -nargs=* Rg
"   \ call fzf#vim#grep(
"   \   'rg --column --line-number --no-heading --color=always '.shellescape(<q-args>), 1,
"   \   <bang>0 ? fzf#vim#with_preview('up:60%')
"   \           : fzf#vim#with_preview('right:50%:hidden', '?'),
"   \   <bang>0)
" nnoremap <C-x><C-b> :Buffers<CR>
" nnoremap <C-x><C-f> :Files<CR>
" nnoremap <C-x><C-g> :GFiles<CR>

" Telescope
nnoremap <C-x><C-b> :Telescope buffers<CR>
nnoremap <C-x><C-f> :Telescope find_files<CR>
nnoremap <C-x><C-g> :Telescope grep_string<CR>
