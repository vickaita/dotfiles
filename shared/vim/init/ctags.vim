" Ctags

let g:rust_use_custom_ctags_defs = 1  " if using rust.vim
let g:tagbar_type_rust = {
            \ 'ctagsbin' : '/path/to/your/universal/ctags',
            \ 'ctagstype' : 'rust',
            \ 'kinds' : [
                \ 'n:modules',
                \ 's:structures:1',
                \ 'i:interfaces',
                \ 'c:implementations',
                \ 'f:functions:1',
                \ 'g:enumerations:1',
                \ 't:type aliases:1:0',
                \ 'v:constants:1:0',
                \ 'M:macros:1',
                \ 'm:fields:1:0',
                \ 'e:enum variants:1:0',
                \ 'P:methods:1',
                \ ],
                \ 'sro': '::',
                \ 'kind2scope' : {
                    \ 'n': 'module',
                    \ 's': 'struct',
                    \ 'i': 'interface',
                    \ 'c': 'implementation',
                    \ 'f': 'function',
                    \ 'g': 'enum',
                    \ 't': 'typedef',
                    \ 'v': 'variable',
                    \ 'M': 'macro',
                    \ 'm': 'field',
                    \ 'e': 'enumerator',
                    \ 'P': 'method',
                    \ },
                    \ }

let g:tagbar_type_elixir = {
            \ 'ctagstype' : 'elixir',
            \ 'kinds' : [
                \ 'p:protocols',
                \ 'm:modules',
                \ 'e:exceptions',
                \ 'y:types',
                \ 'd:delegates',
                \ 'f:functions',
                \ 'c:callbacks',
                \ 'a:macros',
                \ 't:tests',
                \ 'i:implementations',
                \ 'o:operators',
                \ 'r:records'
                \ ],
                \ 'sro' : '.',
                \ 'kind2scope' : {
                    \ 'p' : 'protocol',
                    \ 'm' : 'module'
                    \ },
                    \ 'scope2kind' : {
                        \ 'protocol' : 'p',
                        \ 'module' : 'm'
                        \ },
                        \ 'sort' : 0
                        \ }

let g:tagbar_type_vimwiki = {
          \   'ctagstype':'vimwiki'
          \ , 'kinds':['h:header']
          \ , 'sro':'&&&'
          \ , 'kind2scope':{'h':'header'}
          \ , 'sort':0
          \ , 'ctagsbin':'~/.config/nvim/vwtags.py'
          \ , 'ctagsargs': 'default'
          \ }
