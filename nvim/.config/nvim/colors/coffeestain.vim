" Name:         Teahouse
" Description:  A light theme based on colors inspired by tea.
" Author:       Vick Aita <vickaita@gmail.com>
" Maintainer:   Vick Aita <vickaita@gmail.com>
" Website:      https://github.com/vickaita/teahouse.vim
" License:      MIT

" set background=light

" hi clear

" if exists('g:syntax_on')
"   syntax reset
" endif

let g:colors_name = 'teahouse'

" Function for creating a highlight group
"
" We use this function so we can use variables in our highlight groups, instead
" of having to repeat the same color codes in a bunch of places.
function! s:Hi(group, fg_name, bg_name, gui, ...)
  if a:fg_name == 'NONE'
    let fg = a:fg_name
  else
    let fg = s:colors[a:fg_name]
  endif

  if a:bg_name == 'NONE'
    let bg = a:bg_name
  else
    let bg = s:colors[a:bg_name]
  endif

  if empty(a:gui)
    let style = 'NONE'
  else
    let style = a:gui
  endif

  if a:0 == 1 && !empty(a:1)
    let sp = s:colors[a:1]
  else
    let sp = 'NONE'
  endif

  exe 'hi ' . a:group . ' guifg=' . fg . ' guibg=' . bg . ' gui=' . style . ' guisp=' . sp
endfunction

" A temporary command is used to make it easier/less verbose to define highlight
" groups. This command is removed at the end of this file.
command! -nargs=+ Hi call s:Hi(<f-args>)

let s:colors = {
\  'black':         '#381217',
\  'darkest_grey':  '#452124',
\  'darker_grey':   '#512F31',
\  'dark_grey':     '#694B4B',
\  'grey':          '#9A847F',
\  'light_grey':    '#CBBDB3',
\  'lighter_grey':  '#E4DACD',
\  'lightest_grey': '#F0E8DA',
\  'white':         '#FCF6E6',
\  'dark_purple':   '#832A6B',
\  'purple':        '#CD42BF',
\  'light_purple':  '#E59CD3',
\  'dark_red':      '#832A2C',
\  'red':           '#CD4240',
\  'light_red':     '#E59C93',
\  'dark_orange':   '#834A2C',
\  'orange':        '#CD8240',
\  'light_orange':  '#E5BC93',
\  'dark_yellow':   '#836A2C',
\  'yellow':        '#CDC240',
\  'light_yellow':  '#E5DC93',
\  'dark_green':    '#436A2C',
\  'green':         '#4DC240',
\  'light_green':   '#A5DC93',
\  'dark_cyan':     '#436A6B',
\  'cyan':          '#4DC2BF',
\  'light_cyan':    '#A5DCD3',
\  'dark_blue':     '#432A6B',
\  'blue':          '#4D42BF',
\  'light_blue':    '#A59CD3',
\ }

" We require/expect true colour support, and make no attempt at supporting UIs
" that don't have true colour support. We also require support for italics.
if has('nvim')
  let g:terminal_color_0 = s:colors['black']
  let g:terminal_color_1 = s:colors['red']
  let g:terminal_color_2 = s:colors['green']
  let g:terminal_color_3 = s:colors['yellow']
  let g:terminal_color_4 = s:colors['blue']
  let g:terminal_color_5 = s:colors['purple']
  let g:terminal_color_6 = s:colors['cyan']
  let g:terminal_color_7 = s:colors['light_grey']
  let g:terminal_color_8 = s:colors['dark_grey']
  let g:terminal_color_9 = s:colors['red']
  let g:terminal_color_10 = s:colors['green']
  let g:terminal_color_11 = s:colors['yellow']
  let g:terminal_color_12 = s:colors['blue']
  let g:terminal_color_13 = s:colors['purple']
  let g:terminal_color_14 = s:colors['cyan']
  let g:terminal_color_15 = s:colors['light_grey']
else
  let g:terminal_ansi_colors = [
  \   s:colors['black'],
  \   s:colors['red'],
  \   s:colors['green'],
  \   s:colors['yellow'],
  \   s:colors['blue'],
  \   s:colors['purple'],
  \   s:colors['cyan'],
  \   s:colors['light_grey'],
  \   s:colors['dark_grey'],
  \   s:colors['red'],
  \   s:colors['green'],
  \   s:colors['yellow'],
  \   s:colors['blue'],
  \   s:colors['purple'],
  \   s:colors['cyan'],
  \   s:colors['light_grey']
  \ ]
endif

" Set up all highlight groups.
"
" We use the custom Hi command for this. The syntax of this command is as
" follows:
"
"     Hi NAME FG BG GUI GUISP
"
" Where NAME is the highlight name, FG the foreground color, BG the background
" color, and GUI the settings for the `gui` option (e.g. bold). Since Hi is a
" command and not a function, quotes shouldn't be used. To refer to a color,
" simply use its name (e.g. "black").

" UI Elements

" Generic highlight groups
Hi Bold black NONE bold
Hi ColorColumn NONE lightest_grey NONE
Hi Comment grey NONE italic
Hi Conceal NONE NONE NONE
Hi Constant black NONE NONE
Hi Cursor NONE lighter_grey NONE
Hi CursorLine NONE NONE NONE
Hi CursorLineNR black NONE bold
Hi Directory dark_purple NONE bold
Hi ErrorMsg red NONE bold
Hi FoldColumn black white NONE
Hi Identifier dark_grey NONE NONE
Hi IncSearch NONE light_yellow NONE
Hi Include red NONE bold
Hi Keyword darker_grey NONE bold
Hi LineNr dark_grey white NONE
Hi Macro orange NONE NONE
Hi MatchParen NONE NONE bold
Hi MoreMsg black NONE NONE
Hi NonText white NONE NONE
Hi Normal black white NONE
Hi NormalFloat black light_grey NONE
Hi Number blue NONE NONE
Hi Operator black NONE NONE
Hi Pmenu black lighter_grey NONE
Hi PmenuSel black light_grey bold
Hi PreProc black NONE NONE
Hi Question black NONE NONE
Hi Regexp orange NONE NONE
Hi Search NONE yellow NONE
Hi Special black NONE NONE
Hi SpellBad red NONE bold,undercurl
Hi SpellCap purple NONE undercurl
Hi SpellLocal green NONE undercurl
Hi SpellRare purple NONE undercurl
Hi StatusLine black lighter_grey NONE
Hi StatusLineNC black lighter_grey NONE
Hi String dark_green NONE NONE
Hi Structure dark_purple NONE NONE
Hi TabLine dark_grey light_grey NONE
Hi TabLineFill black light_grey NONE
Hi TabLineSel black white bold
Hi Title black NONE bold
Hi Todo grey NONE bold
Hi Underlined NONE NONE underline
Hi VertSplit light_grey NONE NONE
Hi WarningMsg orange NONE bold

Hi Boolean orange NONE NONE
Hi Type blue NONE NONE
Hi Visual NONE yellow NONE

hi! link Character String
hi! link Error ErrorMsg
hi! link Folded Comment
hi! link Label Keyword
hi! link PmenuThumb PmenuSel
hi! link PreCondit Macro
hi! link SignColumn FoldColumn
hi! link SpecialKey Number
hi! link Statement Keyword
hi! link StorageClass Keyword
hi! link WildMenu PmenuSel

" These highlight groups can be used for statuslines, for example when
" displaying ALE warnings and errors.
Hi WhiteOnOrange white orange NONE
Hi WhiteOnYellow white yellow NONE
Hi WhiteOnRed white red NONE
Hi BlackOnLightYellow black light_yellow NONE
Hi Yellow yellow NONE bold

" ALE
Hi ALEError red NONE bold
Hi ALEErrorSign red NONE bold
Hi ALEWarning orange NONE bold
Hi ALEWarningSign orange NONE bold

" CSS
hi! link cssClassName Keyword
hi! link cssColor Number
hi! link cssIdentifier Keyword
hi! link cssImportant Keyword
hi! link cssProp Identifier
hi! link cssTagName Keyword

" Diffs
Hi DiffAdd NONE light_green NONE
Hi DiffChange NONE NONE NONE
Hi DiffDelete red NONE NONE
Hi DiffText NONE light_green NONE
Hi diffFile black NONE bold
Hi diffLine blue NONE NONE
hi! link diffAdded DiffAdd
hi! link diffChanged DiffChange
hi! link diffRemoved DiffDelete
hi! link dotKeyChar Operator

" Fugitive
Hi FugitiveblameTime blue NONE NONE
Hi FugitiveblameHash purple NONE NONE
hi! link gitCommitOverflow ErrorMsg
hi! link gitCommitSummary String

" HTML
Hi htmlTag black NONE bold
hi! link htmlArg Identifier
hi! link htmlLink Directory
hi! link htmlScriptTag htmlTag
hi! link htmlSpecialTagName htmlTag
hi! link htmlTagName htmlTag

" Java
hi! link javaAnnotation Directory
hi! link javaCommentTitle javaComment
hi! link javaDocParam Todo
hi! link javaDocTags Todo
hi! link javaExternal Keyword
hi! link javaStorageClass Keyword

" Javascript
hi! link JavaScriptNumber Number
hi! link javaScriptBraces Operator
hi! link javaScriptFunction Keyword
hi! link javaScriptIdentifier Keyword
hi! link javaScriptMember Identifier

" JSON
hi! link jsonKeyword String

" Lua
hi! link luaFunction Keyword

" LSP
Hi LspDiagnosticsUnderlineError NONE NONE undercurl red
Hi LspDiagnosticsUnderlineWarning NONE NONE undercurl yellow

" Make
hi! link makeTarget Function

" Markdown
hi! link markdownCode markdownCodeBlock
hi! link markdownCodeBlock Comment
hi! link markdownListMarker Keyword
hi! link markdownOrderedListMarker Keyword

" netrw
hi! link netrwClassify Identifier

" Perl
hi! link perlPackageDecl Identifier
hi! link perlStatementInclude Statement
hi! link perlStatementPackage Statement
hi! link podCmdText Todo
hi! link podCommand Comment
hi! link podVerbatimLine Todo

" Ruby
hi! link rubyAttribute Identifier
hi! link rubyClass Keyword
hi! link rubyClassVariable rubyInstancevariable
hi! link rubyConstant Constant
hi! link rubyDefine Keyword
hi! link rubyFunction Function
hi! link rubyInstanceVariable Directory
hi! link rubyMacro Identifier
hi! link rubyModule rubyClass
hi! link rubyRegexp Regexp
hi! link rubyRegexpCharClass Regexp
hi! link rubyRegexpDelimiter Regexp
hi! link rubyRegexpQuantifier Regexp
hi! link rubyRegexpSpecial Regexp
hi! link rubyStringDelimiter String
hi! link rubySymbol Regexp

" Rust
hi! link rustCommentBlockDoc Comment
hi! link rustCommentLineDoc Comment
hi! link rustFuncCall Identifier
hi! link rustModPath Identifier

" Python
hi! link pythonOperator Keyword

" SASS
hi! link sassClass cssClassName
hi! link sassId cssIdentifier

" Shell
hi! link shFunctionKey Keyword

" SQL
hi! link sqlKeyword Keyword

" Typescript
hi! link typescriptBraces Operator
hi! link typescriptEndColons Operator
hi! link typescriptExceptions Keyword
hi! link typescriptFuncKeyword Keyword
hi! link typescriptFunction Function
hi! link typescriptIdentifier Identifier
hi! link typescriptLogicSymbols Operator

" Vimscript
hi! link VimCommentTitle Todo
hi! link VimIsCommand Constant
hi! link vimGroup Constant
hi! link vimHiGroup Constant

" XML
hi! link xmlAttrib Identifier
hi! link xmlTag Identifier
hi! link xmlTagName Identifier

" YAML
hi! link yamlPlainScalar String

" NERDTree
hi link NERDTreeBookmarksLeader Normal
Hi NERDTreeBookmarksHeader green NONE NONE

delcommand Hi
