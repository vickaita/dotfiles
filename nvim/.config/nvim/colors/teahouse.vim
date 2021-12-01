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

" Available colors

"" Greys, from oldlace (lightest) to darkpurple (darkest)
let s:oldlace             = '#fcf6e6'
let s:cornsilk            = '#faf0d3'
let s:champagne           = '#f3e9cc'
let s:dutchwhite          = '#ded1b7'
let s:khakiweb            = '#c2b4a2'
let s:rocketmetalic       = '#8a7a77'
let s:eggplant            = '#53414d'
let s:darkpurple          = '#1b0722'

"" Reds
let s:venetianred         = '#c51e1a'
let s:apricot             = '#f6bfa6'

"" Browns
let s:liverorgan          = '#61210f'
let s:beaver              = '#ae8971'
let s:tan                 = '#d4bda2'

"" Purples
" let s:palatinatepurple    = '#623465'
let s:maximumpurple       = '#943E9D'

"" Oranges
" let s:flame               = '#ec5d2f'
let s:orangecrayola       = '#EC6D34'
" let s:sunray              = '#edae49'

"" Yellows
let s:jasmine             = '#f9df74'
let s:mediumchampagne     = '#fae8a4'

"" Greens
let s:celedongreen        = '#258575'
let s:polishedpine        = '#68a691'

"" Blues
" let s:celticblue          = '#1967cc'
let s:brightnavyblue      = '#2371D6'
let s:azure               = '#2d7be0'

let s:cyan                = '#168dc0'

let s:colors = {
\  'black': s:darkpurple,
\  'dark_grey': s:eggplant,
\  'grey': s:rocketmetalic,
\  'light_grey': s:khakiweb,
\  'lighter_grey': s:dutchwhite,
\  'lightest_grey': s:champagne,
\  'background': s:oldlace,
\  'white': s:oldlace,
\  'blue': s:brightnavyblue,
\  'light_blue': s:azure,
\  'green': s:celedongreen,
\  'light_green': s:polishedpine,
\  'red': s:venetianred,
\  'light_red': s:apricot,
\  'yellow': s:jasmine,
\  'light_yellow': s:mediumchampagne,
\  'orange': s:orangecrayola,
\  'purple': s:maximumpurple,
\  'cyan': s:cyan,
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
  let g:terminal_color_7 = s:colors['lightest_grey']
  let g:terminal_color_8 = s:colors['dark_grey']
  let g:terminal_color_9 = s:colors['red']
  let g:terminal_color_10 = s:colors['green']
  let g:terminal_color_11 = s:colors['yellow']
  let g:terminal_color_12 = s:colors['blue']
  let g:terminal_color_13 = s:colors['purple']
  let g:terminal_color_14 = s:colors['cyan']
  let g:terminal_color_15 = s:colors['lightest_grey']
else
  let g:terminal_ansi_colors = [
  \   s:colors['black'],
  \   s:colors['red'],
  \   s:colors['green'],
  \   s:colors['yellow'],
  \   s:colors['blue'],
  \   s:colors['purple'],
  \   s:colors['cyan'],
  \   s:colors['lightest_grey'],
  \   s:colors['dark_grey'],
  \   s:colors['red'],
  \   s:colors['green'],
  \   s:colors['yellow'],
  \   s:colors['blue'],
  \   s:colors['purple'],
  \   s:colors['cyan'],
  \   s:colors['lightest_grey']
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
Hi ColorColumn NONE lightest_grey NONE
Hi Comment grey NONE italic
Hi Conceal NONE NONE NONE
Hi Constant dark_grey NONE NONE
Hi Cursor NONE light_grey NONE
Hi CursorColumn NONE lightest_grey NONE
Hi CursorLine NONE NONE NONE
Hi CursorLineNR black NONE bold
Hi Directory blue NONE bold
Hi ErrorMsg red NONE bold
Hi FoldColumn black background NONE
Hi Identifier blue NONE NONE
Hi Include red NONE bold
Hi Keyword black NONE bold
Hi LineNr dark_grey background NONE
Hi Macro orange NONE NONE
Hi MatchParen NONE NONE bold
Hi MoreMsg black NONE NONE
Hi NonText green NONE NONE
Hi Normal dark_grey background NONE
" Hi NormalFloat black lighter_grey NONE
hi! link NormalFloat Pmenu
Hi Bold black NONE bold
Hi Number blue NONE NONE
Hi Operator black NONE NONE
Hi Pmenu lightest_grey dark_grey NONE
Hi PmenuSel black yellow bold
Hi PreProc red NONE NONE
Hi Question black NONE NONE
Hi Regexp green NONE NONE
Hi Search NONE light_yellow NONE
Hi IncSearch NONE yellow NONE
Hi Special black NONE NONE
Hi SpellBad red NONE bold,undercurl
Hi SpellCap purple NONE undercurl
Hi SpellLocal green NONE undercurl
Hi SpellRare purple NONE undercurl
Hi StatusLine white dark_grey NONE
Hi StatusLineNC black light_grey NONE
Hi String green NONE NONE
Hi Structure purple NONE NONE
Hi TabLine dark_grey lighter_grey NONE
Hi TabLineFill black lighter_grey NONE
Hi TabLineSel black background bold
Hi Title black NONE bold
Hi Todo grey NONE bold
Hi VertSplit lighter_grey NONE NONE
Hi WarningMsg orange NONE bold
Hi Underlined NONE NONE underline

" hi! link Boolean Keyword
Hi Boolean blue NONE NONE
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
" hi! link Type Keyword
Hi Type purple NONE NONE
" hi! link Visual Cursor
Hi Visual NONE light_yellow NONE
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
Hi DiffDelete red light_red NONE
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

" IndentLine
Hi IndentLine lightest_grey NONE NONE

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
hi! link pythonType Type

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
hi! link typescriptIdentifierName Identifier
hi! link typescriptLogicSymbols Operator
hi! link typescriptRegexpString Regexp

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
