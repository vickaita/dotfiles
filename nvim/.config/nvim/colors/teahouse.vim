" Name:         Teahouse
" Description:  A light theme based on colors inspired by tea.
" Author:       Vick Aita <vickaita@gmail.com>
" Maintainer:   Vick Aita <vickaita@gmail.com>
" Website:      https://github.com/vickaita/teahouse.vim
" License:      MIT

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
let s:oldlace             = '#fcf6e6' " hsl(44, 79%, 95%)
let s:cornsilk            = '#faf0d3' " hsl(45, 80%, 90%)
let s:champagne           = '#f3e9cc' " hsl(45, 62%, 88%)
let s:dutchwhite          = '#ded1b7' " hsl(40, 37%, 79%)
let s:khakiweb            = '#c2b4a2' " hsl(34, 21%, 70%)
let s:rocketmetalic       = '#8a7a77' " hsl(9, 8%, 50%)
let s:eggplant            = '#53414d' " hsl(320, 12%, 29%)
let s:darkpurple          = '#1b0722' " hsl(284, 66%, 8%)

"" Reds
let s:persianplum         = '#70131E'
let s:venetianred         = '#c51e1a'
let s:apricot             = '#f6bfa6'

"" Browns
let s:liverorgan          = '#61210f'
let s:beaver              = '#ae8971'
let s:tan                 = '#d4bda2'

"" Purples
let s:palatinatepurple    = '#623465'
let s:maximumpurple       = '#943E9D'
let s:lilac               = '#C797B8'

"" Oranges
" let s:burntumber          = '#843A2B'
" let s:chestnut            = '#9E472E'
let s:rust                = '#B85430'
let s:orangecrayola       = '#EC6D34'
let s:deepchampagne       = '#F4CF8E'

"" Yellows
let s:sunray              = '#edae49'
let s:jasmine             = '#f9df74'
let s:mediumchampagne     = '#fae8a4'

"" Greens
let s:celedongreen        = '#258575'
let s:polishedpine        = '#68a691'
let s:laurelgreen         = '#C5D6BC'

"" Blues
let s:celticblue          = '#1967cc'
let s:brightnavyblue      = '#2371D6'
let s:azure               = '#2d7be0'
let s:aero                = '#8FB1D5'

let s:dark_cyan           = '#194A71'
let s:cyan                = '#168dc0'
let s:light_cyan          = '#88BFCA'

let s:colors = {
\  'black': s:darkpurple,
\  'dark_grey': s:eggplant,
\  'grey': s:rocketmetalic,
\  'light_grey': s:khakiweb,
\  'lighter_grey': s:dutchwhite,
\  'lightest_grey': s:champagne,
\  'white': s:oldlace,
\  'background': s:oldlace,
\  'dark_blue': s:celticblue,
\  'blue': s:brightnavyblue,
\  'light_blue': s:aero,
\  'dark_green': s:celedongreen,
\  'green': s:polishedpine,
\  'light_green': s:laurelgreen,
\  'dark_red': s:persianplum,
\  'red': s:venetianred,
\  'light_red': s:apricot,
\  'dark_yellow': s:sunray,
\  'yellow': s:jasmine,
\  'light_yellow': s:mediumchampagne,
\  'dark_orange': s:rust,
\  'orange': s:orangecrayola,
\  'light_orange': s:deepchampagne,
\  'dark_purple': s:palatinatepurple,
\  'purple': s:maximumpurple,
\  'light_purple': s:lilac,
\  'dark_cyan': s:dark_cyan,
\  'cyan': s:cyan,
\  'light_cyan': s:light_cyan,
\ }

" TODO: light and dark cyan colors

if has('nvim')
  let g:terminal_color_0 = s:colors['black']
  let g:terminal_color_1 = s:colors['red']
  let g:terminal_color_2 = s:colors['dark_green']
  let g:terminal_color_3 = s:colors['yellow']
  let g:terminal_color_4 = s:colors['blue']
  let g:terminal_color_5 = s:colors['purple']
  let g:terminal_color_6 = s:colors['cyan']
  let g:terminal_color_7 = s:colors['lightest_grey']
  let g:terminal_color_8 = s:colors['dark_grey']
  let g:terminal_color_9 = s:colors['red']

  let g:terminal_color_11 = s:colors['yellow']
  let g:terminal_color_12 = s:colors['blue']
  let g:terminal_color_13 = s:colors['purple']
  let g:terminal_color_14 = s:colors['cyan']
  let g:terminal_color_15 = s:colors['lightest_grey']
else
  let g:terminal_ansi_colors = [
  \   s:colors['black'],
  \   s:colors['red'],
  \   s:colors['dark_green'],
  \   s:colors['yellow'],
  \   s:colors['blue'],
  \   s:colors['purple'],
  \   s:colors['cyan'],
  \   s:colors['lightest_grey'],
  \   s:colors['dark_grey'],
  \   s:colors['red'],
  \   s:colors['dark_green'],
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

" == Base fonts ==
Hi Normal dark_grey background NONE
Hi Bold black NONE bold
Hi Italic dark_grey NONE italic
Hi Strikethrough dark_grey NONE strikethrough
Hi Underlined dark_grey NONE underline
Hi InvertedNormal lighter_grey dark_grey NONE
Hi InvertedBold lighter_grey dark_grey bold
Hi InvertedItalic lighter_grey dark_grey italic
Hi InvertedStrikethrough lighter_grey dark_grey strikethrough
Hi InvertedUnderline lighter_grey dark_grey underline

" == Code Elements ==

" === Comment ===
Hi Comment grey NONE italic
Hi InvertedComment grey NONE italic

" === Constant ===
Hi Boolean purple NONE NONE
Hi Character dark_green NONE NONE
Hi Constant purple NONE NONE
Hi Float cyan NONE NONE
Hi Number cyan NONE NONE
Hi Regexp dark_green NONE NONE
Hi String dark_green NONE NONE
Hi InvertedBoolean light_purple NONE NONE
Hi InvertedCharacter light_green NONE NONE
Hi InvertedConstant light_purple NONE NONE
Hi InvertedFloat light_cyan NONE NONE
Hi InvertedNumber light_cyan NONE NONE
Hi InvertedRegexp light_green NONE NONE
Hi InvertedString light_green NONE NONE

" === Identifier ===
Hi Builtin red NONE NONE
Hi Function blue NONE italic
Hi Identifier blue NONE NONE
Hi Method blue NONE italic
Hi Namespace blue NONE NONE
Hi Parameter dark_grey NONE italic
Hi ParameterReference red NONE bold,italic
Hi InvertedBuiltin light_red NONE NONE
Hi InvertedFunction light_blue NONE italic
Hi InvertedIdentifier light_blue NONE NONE
Hi InvertedMethod light_blue NONE italic
Hi InvertedNamespace light_blue NONE NONE
Hi InvertedParameter light_grey NONE italic
Hi InvertedParameterReference light_red NONE bold,italic

" === Statement ===
Hi Conditional dark_grey NONE bold
Hi Exception dark_grey NONE bold
Hi Include dark_grey NONE bold
Hi Keyword dark_grey NONE bold
Hi Label dark_grey NONE bold
Hi Operator dark_grey NONE NONE
Hi Repeat dark_grey NONE bold
Hi Statement dark_grey NONE bold
Hi InvertedConditional lightest_grey NONE bold
Hi InvertedException lightest_grey NONE bold
Hi InvertedInclude lightest_grey NONE bold
Hi InvertedKeyword lightest_grey NONE bold
Hi InvertedLabel lightest_grey NONE bold
Hi InvertedOperator lightest_grey NONE NONE
Hi InvertedRepeat lightest_grey NONE bold
Hi InvertedStatement lightest_grey NONE bold

" === PreProc ===
Hi Macro red NONE NONE
Hi PreProc red NONE NONE
Hi Define red NONE NONE
Hi PreCondit red NONE NONE
Hi InvertedMacro light_red NONE NONE
Hi InvertedPreProc light_red NONE NONE
Hi InvertedDefine light_red NONE NONE
Hi InvertedPreCondit light_red NONE NONE

" === Type ===
Hi StorageClass purple NONE NONE
Hi Structure purple NONE NONE
Hi Type purple NONE NONE
Hi Typedef purple NONE NONE
Hi InvertedStorageClass light_purple NONE NONE
Hi InvertedStructure light_purple NONE NONE
Hi InvertedType light_purple NONE NONE
Hi InvertedTypedef light_purple NONE NONE

" == Special ==
Hi Special black NONE NONE
Hi SpecialChar black NONE NONE
Hi Tag black NONE NONE
Hi Delimiter black NONE NONE
Hi SpecialComment black NONE NONE
Hi Debug black NONE NONE
Hi InvertedSpecial white NONE NONE
Hi InvertedSpecialChar white NONE NONE
Hi InvertedTag white NONE NONE
Hi InvertedDelimiter white NONE NONE
Hi InvertedSpecialComment white NONE NONE
Hi InvertedDebug white NONE NONE

" == UI Elements ==
Hi ColorColumn NONE lightest_grey NONE
Hi Conceal NONE NONE NONE
Hi Cursor NONE light_grey NONE
Hi CursorColumn NONE lightest_grey NONE
Hi CursorLine NONE lightest_grey NONE
Hi CursorLineNR black NONE NONE
Hi LineNr grey background NONE
Hi FoldColumn black background NONE

" Messaging
Hi NoteMsg NONE NONE bold
Hi ErrorMsg red NONE bold
Hi MoreMsg black NONE NONE
Hi Title black NONE bold
Hi Todo red NONE bold
Hi WarningMsg dark_orange NONE bold
Hi InvertedTitle white NONE bold

" Generic highlight groups
Hi Directory blue NONE bold
Hi Link blue NONE NONE
Hi MatchParen NONE NONE bold
Hi NonText NONE NONE NONE
" Hi NormalFloat black lighter_grey NONE
hi! link NormalFloat Pmenu
Hi Pmenu lighter_grey dark_grey NONE
Hi PmenuSel black yellow bold
Hi Question black NONE NONE
Hi Search black light_yellow NONE
Hi IncSearch black yellow NONE
Hi SpellBad red NONE bold,undercurl
Hi SpellCap purple NONE undercurl
Hi SpellLocal dark_green NONE undercurl
Hi SpellRare purple NONE undercurl
Hi StatusLine white dark_grey NONE
Hi StatusLineNC black light_grey NONE
Hi TabLine dark_grey lighter_grey NONE
Hi TabLineFill black lighter_grey NONE
Hi TabLineSel black background bold
Hi VertSplit lighter_grey NONE NONE
Hi Visual NONE light_yellow NONE

hi! link Error ErrorMsg
hi! link Folded Comment
hi! link PmenuThumb PmenuSel
hi! link SignColumn FoldColumn
hi! link SpecialKey Number
hi! link WildMenu PmenuSel

" Custom

" Treesitter highlight groups
hi! link TSAttribute PreProc
hi! link TSBoolean Boolean
hi! link TSCharacter Character
hi! link TSComment Comment
hi! link TSConditional Conditional
hi! link TSConstant Constant
hi! link TSConstBuiltin PreProc
hi! link TSConstMacro Constant
hi! link TSConstructor Structure
hi! link TSError Error
hi! link TSException Exception
hi! link TSField Normal
hi! link TSFloat Float
hi! link TSFunction Function
hi! link TSFuncBuiltin Builtin
hi! link TSFuncMacro Macro
hi! link TSInclude Include
hi! link TSKeyword Keyword
hi! link TSKeywordFunction Keyword
hi! link TSKeywordOperator Operator
hi! link TSKeywordReturn Keyword
hi! link TSLabel Label
hi! link TSMethod Method
hi! link TSNamespace Namespace
" TSNone
hi! link TSNumber Number
hi! link TSOperator Operator
hi! link TSParameter Parameter
hi! link TSParameterReference ParameterReference
hi! link TSProperty TSField
hi! link TSPunctDelimiter Normal
hi! link TSPunctBracket Normal
hi! link TSPunctSpecial Normal
hi! link TSRepeat Repeat
hi! link TSString String
hi! link TSStringRegex Regexp
hi! link TSStringEscape String
hi! link TSStringSpecial String
hi! link TSSymbol Macro
hi! link TSTag Normal
hi! link TSTagAttribute TSAttribute
hi! link TSTagDelimiter Normal
hi! link TSText Normal
hi! link TSStrong Bold
hi! link TSEmphasis Italic
hi! link TSUnderline Underlined
hi! link TSStrike Strikethrough
hi! link TSTitle Title
hi! link TSLiteral Normal
hi! link TSURI String
hi! link TSMath Number
hi! link TSTextReference Normal
hi! link TSEnvironment Normal
hi! link TSEnvironmentName Namespace
hi! link TSNote NoteMsg
hi! link TSWarning WarningMsg
hi! link TSDanger ErrorMsg
hi! link TSType Type
hi! link TSTypeBuiltin Type
hi! link TSVariable Identifier
hi! link TSVariableBuiltin Structure


" Coc
hi! link CocFloating NormalFloat
Hi CocErrorFloat light_red dark_grey NONE
Hi CocWarningFloat orange dark_grey NONE
hi! link CocInfoFloat NormalFloat
hi! link CocHintFloat NormalFloat
Hi CocInfoSign orange NONE NONE
Hi CocHintSign green NONE NONE
Hi CocWarningSign orange NONE NONE
Hi CocErrorSign red NONE NONE
hi! link CocBold Bold
hi! link CocItalic Italic
hi! link CocUnderline Underline
hi! link CocStrikeThrough Strikethrough
hi! link CocMarkdownCode Normal
hi! link CocMarkdownHeader Title
hi! link CocMarkdownLink Link


Hi CocSem_keyword red green bold

  " `hi default link CocSem_namespace Identifier`
  " `hi default link CocSem_type Type`
  " `hi default link CocSem_class Structure`
  " `hi default link CocSem_enum Type`
  " `hi default link CocSem_interface Type`
  " `hi default link CocSem_struct Structure`
  " `hi default link CocSem_typeParameter Type`
  " `hi default link CocSem_parameter Identifier`
  " `hi default link CocSem_variable Identifier`
  " `hi default link CocSem_property Identifier`
  " `hi default link CocSem_enumMember Constant`
  " `hi default link CocSem_event Identifier`
  " `hi default link CocSem_function Function`
  " `hi default link CocSem_method Function`
  " `hi default link CocSem_macro Macro`
  " `hi default link CocSem_keyword Keyword`
  " `hi default link CocSem_modifier StorageClass`
  " `hi default link CocSem_comment Comment`
  " `hi default link CocSem_string String`
  " `hi default link CocSem_number Number`
  " `hi default link CocSem_regexp Normal`
  " `hi default link CocSem_operator Operator`





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
Hi DiffAdd dark_green light_green NONE
Hi DiffChange dark_orange light_orange NONE
Hi DiffDelete red light_red NONE
Hi DiffText NONE light_green NONE
Hi diffFile black NONE bold
Hi diffLine blue NONE NONE
hi! link diffAdded DiffAdd
hi! link diffChanged DiffChange
hi! link diffRemoved DiffDelete
hi! link dotKeyChar Operator

" GitSigns
" Hi GitSignsAdd dark_green light_green NONE
" Hi GitSignsAddNr dark_grey light_green NONE
" GitSignsAddLn
" GitSignsChange
" GitSignsChangeNr
" GitSignsChangeLn
" GitSignsDelete
" GitSignsDeleteNr
" GitSignsDeleteLn
" GitSignsDelete
" GitSignsDeleteNr
" GitSignsDeleteLn
" GitSignsChange
" GitSignsChangeNr
" GitSignsChangeLn

" Fugitive
Hi FugitiveblameTime blue NONE NONE
Hi FugitiveblameHash purple NONE NONE
hi! link gitCommitOverflow ErrorMsg
hi! link gitCommitSummary String

" HTML
Hi htmlTag black NONE bold
hi! link htmlArg Identifier
hi! link htmlLink Link
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
hi! link pythonBuiltin InvertedFunction
hi! link pythonBuiltinObj InvertedPreProc
hi! link pythonBuiltinType InvertedType
hi! link pythonClass InvertedStructure
hi! link pythonClassVar InvertedStructure
hi! link pythonFunction InvertedFunction
hi! link pythonInclude InvertedInclude
hi! link pythonNumber InvertedNumber
hi! link pythonOperator InvertedKeyword
hi! link pythonQuotes InvertedString
hi! link pythonStatement InvertedStatement
hi! link pythonString InvertedString
hi! link pythonType InvertedType

" SASS
hi! link sassClass cssClassName
hi! link sassId cssIdentifier

" Shell
hi! link shFunctionKey Keyword

" SQL
hi! link sqlKeyword Keyword

" Typescript
hi! link typescriptAliasKeyword InvertedKeyword
hi! link typescriptAliasDeclaration InvertedIdentifier
hi! link typescriptArrayMethod InvertedIdentifier
hi! link typescriptCall InvertedNormal
hi! link typescriptClassKeyword InvertedKeyword
hi! link typescriptConsoleMethod InvertedFunction
hi! link typescriptBraces InvertedOperator
hi! link typescriptBOM InvertedStructure
hi! link typescriptBOMLocationMethod InvertedFunction
hi! link typescriptDOMFormProp InvertedIdentifier
hi! link typescriptEndColons InvertedOperator
hi! link typescriptExceptions InvertedKeyword
hi! link typescriptFuncKeyword InvertedKeyword
hi! link typescriptFuncName InvertedFunction
hi! link typescriptFuncType InvertedFunction
hi! link typescriptFuncTypeArrow InvertedFunction
hi! link typescriptFunction InvertedFunction
hi! link typescriptGlobal InvertedError
hi! link typescriptIdentifier InvertedIdentifier
hi! link typescriptIdentifierName InvertedIdentifier
hi! link typescriptInterfaceKeyword InvertedKeyword
hi! link typescriptInterfaceName InvertedType
hi! link typescriptInterfaceTypeParameter InvertedType
hi! link typescriptImport InvertedInclude
hi! link typescriptLogicSymbols InvertedOperator
hi! link typescriptNumber InvertedNumber
hi! link typescriptOperator InvertedOperator
hi! link typescriptProp InvertedIdentifier
hi! link typescriptParens InvertedNormal
hi! link typescriptPredefinedType InvertedType
hi! link typescriptRegexpString InvertedRegexp
hi! link typescriptString InvertedString
hi! link typescriptType InvertedType
hi! link typescriptTypeBracket InvertedType
hi! link typescriptTypeParameter InvertedType
hi! link typescriptTypeReference InvertedType
hi! link typescriptUnion InvertedOperator
hi! link typescriptVariable InvertedKeyword

" Vimscript
hi! link VimCommentTitle Todo
hi! link VimIsCommand Constant
hi! link vimGroup Constant
hi! link vimHiGroup Constant

" Vimwiki
Hi VimwikiHeader1 red NONE bold
Hi VimwikiHeader2 red NONE bold
Hi VimwikiHeader3 red NONE bold
Hi VimwikiHeader4 red NONE bold
Hi VimwikiHeader5 red NONE bold
Hi VimwikiHeader6 red NONE bold
hi! link VimwikiLink Link
Hi VimwikiListTodo dark_green NONE NONE
Hi VimwikiCode purple lightest_grey NONE
Hi VimwikiPre purple NONE NONE

" XML
hi! link xmlAttrib Identifier
hi! link xmlTag Identifier
hi! link xmlTagName Identifier

" YAML
hi! link yamlPlainScalar String

" NERDTree
hi link NERDTreeBookmarksLeader Normal
Hi NERDTreeBookmarksHeader dark_green NONE NONE

delcommand Hi
