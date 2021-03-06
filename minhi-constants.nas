; minhi-constants.nas: constants for Minhi.
; Copyright (c) 2018 cxw42.  Licensed MIT.

; === Token types output by mtok ========================================= {{{1

; Literals
.const T_EOF    'E  ; End of input
.const T_IGNORE 'R  ; A "Ready" output from the tokenizer.  The parser
                    ; should ignore this whenever it occurs.

.const T_IDENT  'I      ; any identifier, with sigil
.const T_BAREWORD 'B    ; any bareword, i.e., an identifier not preceded
                        ; by a sigil
.const T_NUM    'N  ; literal number
    ; TODO? base-N literals with this, or separate?

;.const T_STRING 'S  ; literal string   ; XXX Not yet implemented

; Operators

; <operpunc>: These stand for themselves
.const T_LPAR   '(
.const T_RPAR   ')
.const T_QUOTE  '"
.const T_LBRAK  '[
.const T_RBRAK  ']
.const T_DEREF  '^
.const T_MUL    '*
.const T_IDIV   '/
.const T_ADD    '+
.const T_COMMA  ',
.const T_SEMI   ';
.const T_ADDR   '\

; Standalone operators

.const T_TERN1  '?  ; first part of the ternary operator (??)
.const T_TERN2  ':  ; second part " (::)

.const T_MINUS  '-  ; it's up to the parser whether it's a sub or a unary minus
.const T_LE     '{
.const T_GE     '}
.const T_LT     '<
.const T_GT     '>
.const T_EQ     '~  ; test for equality
.const T_NE     '!
.const T_SSHIP  's  ; <=>
.const T_ARROW  'w
.const T_ASSIGN '=

; Other
.const T_ERROR  'X  ; An invalid token was seen

; }}}1
; === Token types output by mtok2 ======================================== {{{1
; mtok2 can output anything output by mtok, plus the following.

; Barewords that are actually operators

.const T_VAR    'v
.const T_MOD    '%
.const T_NOT    'n
.const T_AND    'a  ; &&
.const T_OR     'o  ; ||

