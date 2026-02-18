" Move / Sui Move syntax highlighting
if exists("b:current_syntax")
    finish
endif

" Keywords
syntax keyword moveKeyword module use fun struct has store key drop copy phantom
syntax keyword moveKeyword public native friend acquires script const let mut
syntax keyword moveKeyword return abort break continue if else while loop for as
syntax keyword moveKeyword move entry

" Sui-specific keywords
syntax keyword moveSuiKeyword sui clock tx_context TxContext object uid transfer freeze share delete

" Types
syntax keyword moveType address signer u8 u16 u32 u64 u128 u256 bool vector String
syntax keyword moveSuiType ID UID Object Coin Balance Supply

" Built-in functions
syntax keyword moveBuiltin assert borrow borrow_mut move_to move_from exists

" Booleans
syntax keyword moveBoolean true false

" Numbers
syntax match moveNumber '\v<\d+>'
syntax match moveHex '\v0x[0-9a-fA-F]+'

" Strings
syntax region moveString start='"' end='"' contains=moveStringEscape
syntax match moveStringEscape '\v\\.' contained

" Comments
syntax region moveComment start='//' end='$' contains=moveTodo
syntax region moveBlockComment start='/\*' end='\*/' contains=moveTodo
syntax keyword moveTodo TODO FIXME NOTE XXX contained

" Attributes  (e.g. #[test], #[allow(...)])
syntax match moveAttribute '\v#\[.*\]'

" Module paths  (e.g. sui::object, tx_context::sender)
syntax match moveModulePath '\v[a-zA-Z_][a-zA-Z0-9_]*::[a-zA-Z_][a-zA-Z0-9_]*'

" Function calls
syntax match moveFunctionCall '\v[a-zA-Z_][a-zA-Z0-9_]*\ze\s*\('

" Highlight links
highlight link moveKeyword      Keyword
highlight link moveSuiKeyword   Special
highlight link moveType         Type
highlight link moveSuiType      Type
highlight link moveBuiltin      Function
highlight link moveBoolean      Boolean
highlight link moveNumber       Number
highlight link moveHex          Number
highlight link moveString       String
highlight link moveStringEscape SpecialChar
highlight link moveComment      Comment
highlight link moveBlockComment Comment
highlight link moveTodo         Todo
highlight link moveAttribute    PreProc
highlight link moveModulePath   Include
highlight link moveFunctionCall Function

let b:current_syntax = "move"
