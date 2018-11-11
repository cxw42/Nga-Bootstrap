; mtok.nas: tokenizer for Minhi.
; Copyright (c) 2018 cxw42.  Licensed MIT.

.include ../minhi-constants.nas

; Try 3
; This tokenizer recognizes the language:
;   <sigil><alpha>(<alpha>|<specialalpha...>|<digit>)*
; | <digit>+
; (future) | 0[obx]<digit>+
; | '(<alpha>|<specialalpha...>|<digit>|<other nonquote>)*'
;       (for now, no way to represent "'"!)
; | <=>                         (spaceship)
; | ?? | :: | -> | -
; | <= | >= | < | > | == | <> | =
; |
; | not | and | or | neg | mod
; | <operpunc>
;
; P: <operpunc> ::= [()"\[\]^*/+,;\\]
; D: digits ::= [0-9]
; S: sigil ::= [&$#!@%]
; specialalpha ::= n|o|t|a|d|r|e|g|m
;   (letters used in named operators)
; B: all other alpha
; N: other nonquote ::= all punc not otherwise accounted for, except "'"
;   = [`~_{}|. ]
; Q: [?]

; In https://cyberzhg.github.io/toolbox/nfa2dfa , that becomes:
; S(n|o|t|a|d|r|e|g|m|B)(n|o|t|a|d|r|e|g|m|B|D)*|D+|'(n|o|t|a|d|r|e|g|m|B|D|P|N)*'|QQ|::|<=>|->|<=|>=|==|<>|<|>|=|P|not|and|or|neg|mod
; with the result given in ./mtok.xlsx.

; Try 5: simpler version, with only alpha identifiers, without string
; literals, with all-punctuation operators, and without mod, and, or or
; (because & and % conflict between operators and sigils, in this
; simplified form).
; ASCII punc: !"#$%&'()*+,-./:;<=>?@[\]^_`{|}~
; Class:      SPSSSS'PPPPP-NP:P<=>QSPPPPNNNINN
; D ::= [0-9]
; A ::= [a-zA-Z]
; P ::= [()"\[\]^*/+,;\\] <operpunc>
; N ::= [`~_{}.]
; S ::= sigil ::= [&$#!@%]
; Q ::= [?]
; I ::= '|' (pipe char)
; W ::= [[:space:]]     ; mapped to T_IGNORE
; SA+|D+|QQ|::|<=>|->|<=|>=|==|<>|<|>|=|P|-|W+

; === State -> token mapping ===============================================
; This is read off the svg generated by nfa2dfa.  TODO automate this.
.const E_B T_MINUS
.const E_L T_ARROW
.const E_M T_TERN2
.const E_D T_LT
.const E_N T_LE
.const E_V T_SSHIP
.const E_O T_NE
.const E_E T_ASSIGN
.const E_P T_EQ
.const E_F T_GT
.const E_Q T_GE
.const E_G T_NUM    ; first digit
.const E_R T_NUM
.const E_H EMIT_CHAR    ; <operpunc>
.const E_S T_TERN1
.const E_T T_IDENT  ; sigil + 1 char
.const E_W T_IDENT
.const E_K T_IGNORE ; whitespace
.const E_U T_IGNORE ; ditto

; === State machine and emitters ===========================================

.include state-machine.geninc

; === Globals ==============================================================

:state
    .data 0

; ASCII values of the current and next char (if any)
;:char
;    .data 0
;:nextchar
;    .data 0

; Character classes of the current char
;:issigil
;    .data 0
;:isalpha
;    .data 0
;:isalnum
;    .data 0
;:isdigit
;    .data 0
;:isnonquote     ; valid in a string: [^']
;    .data 0
;:ispunc         ; single-char operator punctuation: [()"\[\]^-*/%+,;]
;    .data 0

; === Get character class ==================================================

:get_cclass     ; char ]

    ; Bounds check
    dup         ; char char ]
    lt 0        ; char flag ]
    cjump &no_cclass    ; char ]
    dup
    gt 127
    cjump &no_cclass

    ; Get the value from the table
    .lit &cctable   ; char baseaddr ]
    add         ; ofs ]
    fetch       ; cclass ]
    return

:no_cclass
    end
; end get_cclass()

; Character class table.  Generated by hand in Excel/Vim.
; Character classes are the nfa2dfa output column number minus 4
; (e.g., column D = class 0).
:cctable
    .data 11
    .data 11
    .data 11
    .data 11
    .data 10
    .data 11
    .data 11
    .data 10
    .data 11
    .data 11
    .data 10
    .data 11
    .data 11
    .data 10
    .data 11
    .data 11
    .data 11
    .data 11
    .data 11
    .data 11
    .data 11
    .data 11
    .data 11
    .data 11
    .data 11
    .data 11
    .data 11
    .data 11
    .data 11
    .data 11
    .data 11
    .data 11
    .data 10
    .data 9
    .data 7
    .data 9
    .data 9
    .data 9
    .data 9
    .data 11
    .data 7
    .data 7
    .data 7
    .data 7
    .data 7
    .data 0
    .data 11
    .data 7
    .data 6
    .data 6
    .data 6
    .data 6
    .data 6
    .data 6
    .data 6
    .data 6
    .data 6
    .data 6
    .data 1
    .data 7
    .data 2
    .data 3
    .data 4
    .data 8
    .data 9
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 7
    .data 7
    .data 7
    .data 7
    .data 11
    .data 11
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 5
    .data 11
    .data 11
    .data 11
    .data 11
    .data 11
; end cctable

; === Main =================================================================
:main

    ; Initialize
    .lit S_A
    store &state

    jump &next  ; condition is at the bottom of the loop

:loop           ; char ]

    ; Get the character class
    call &get_cclass    ; cclass ]

    ; Check state transitions
    fetch &state            ; cclass state ]
    call &get_next_state    ; next_state ]

    dup                 ; next_state next_state ]
    neq S_COMPLETE      ; next_state flag ]
    cjump &next         ; next_state ]

    ; a token is complete; emit it
    call &emit_token    ; ]

:next
    out T_IGNORE    ; say we're ready

    in          ; char ]
    iseof       ; char flag ]
    cjump &done ; char ]

    ;; Put the current character at TOS and in &char.
    ;dup             ; char char ]
    ;store &char     ; char ]

    jump &loop

:done
    out T_IGNORE    ; DEBUG - say we completed successfully
end

