; mtok.nas: tokenizer for Minhi.
; Copyright (c) 2018 cxw42.  Licensed MIT.

.include ../minhi-constants.nas

; === Globals ============================================================= {{{1

:state
    .data 0

; ASCII value of the most-recently read (current) character
:curr_char
    .data 0

; Pointer to the location in curr_token at which the next character should
; be written
:curr_token_ptr
    .data 0

; }}}1
; === Language ============================================================ {{{1

; TODO add a branch that accepts EOF

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
; === https://cyberzhg.github.io/toolbox/nfa2dfa?regex=U0ErfEQrfFFRfDo6fDw9PnwtPnw8PXw+PXw9PXw8Pnw8fD58PXxQfC18Vys=

; }}}1
; === State -> token mapping ============================================== {{{1
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

; }}}1
; === State machine and emitters ===========================================

.include state-machine.geninc

; === Get character class ================================================= {{{1

:get_cclass     ; char ]

    ; Bounds check
    dup         ; char char ]
    lt 0        ; char flag ]
    cjump &no_cclass    ; char ]
    dup
    gt 127
    cjump &no_cclass

    ; Get the value from the table
    lit &cctable   ; char baseaddr ]
    add         ; ofs ]
    fetch       ; cclass ]
    return

:no_cclass
    end
; end get_cclass()

; Character class table.  Generated by hand in Excel/Vim. {{{2
; Character classes are the nfa2dfa output column number minus 4
; (e.g., column D = class 0).
:cc_minus_1     ; character class for -1 = EOF
    .data 11    ; same as Ctl-D
:cctable
    .data 11
    .data 11
    .data 11
    .data 11
    .data 11    ; ctl-D
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
; end cctable }}}2

; }}}1
; === Main ================================================================ {{{1

:main_is_done   ; Whether the current time through the loop is our last
    .data false

:main

    ; Initialize: start in state A
    lit S_A
    store &state
    lit &curr_token             ; &curr_token[0] ]
    store &curr_token_pointer   ; ] - curr_token_pointer := &curr_token[0]

    jump &main_next  ; condition is at the bottom of the loop

:main_loop           ; char ]

    ; Get the character class
    call &get_cclass    ; cclass ]

    ; Check state transitions: get the state to which the current character
    ; took us, or COMPLETE/ERROR if that character isn't a valid transition
    ; from this state.
    fetch &state            ; cclass state ]
;    out '[ ; DEBUG
;    dup
;    numout
;    out ']
    call &get_next_state    ; next_state ]

;    dup     ; DEBUG
;    numout  ; DEBUG

    ; Did we finish a token?
    dup                 ; next_state next_state ]
    eq S_COMPLETE       ; next_state flag ]
    cjump &main_emit    ; next_state ]

    ; Was it an error?
    dup
    eq S_ERROR
    cjump &main_error       ; next_state ]

    ; If we get here, we have a good next state
    store &state            ; ]

    ; FALL THROUGH to &main_next

:main_next

    ; If that was the last time through, we're done.
    fetch &main_is_done     ; flag ]
    cjump &main_done        ; ]

;    out T_IGNORE    ; say we're ready
;    out 'A          ; zero-length token follows

    ; Get the next char of input
    in                      ; char ]
;    out '>  ; DEBUG
;    dup
;    out
;    out '<

    ; Save the current character in &curr_char.
    dup                     ; char char ]
    store &curr_char        ; char ]

    ; Always add the char to the buffer - we will undo it later if necessary
    call &stash_curr_char

    ; Handle EOF
    iseof                   ; char flag ]
    cjump &main_last_time   ; char ]

    jump &main_loop

:main_done
    out T_EOF
    out 'A                  ; == numout 0 => no token data

    end

; We saw an EOF, so run the loop one last time to flush the last token
:main_last_time             ; char ]
;    out '}  ; DEBUG
    drop                    ; ] - ignore the actual EOF (could be 4 or -1)
    lit 4                   ; curr char (always ^D) ]

    ; Make the end of the saved-token buffer a ^D
    dup                     ; ^D ^D ]
    call &replace_last_saved_char       ; ^D ]

    ; Mark that we're almost done
    lit true                ; ^D flag ]
    store &main_is_done     ; ^D ]

    ; Last time through the loop
    jump &main_loop         ; ^D ]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

:main_emit              ; next_state == S_COMPLETE ]
    ; a token is complete; emit it
    drop                        ; ]

    ; Emit the token code
    fetch &curr_char            ; char ]
    fetch &state                ; char state ]
        ; Because the current state is the one that is done.
    call &emit_token            ; ]

    call &emit_curr_token_text  ; output the text we've built up, plus
                                ; its length.

    call &reset_token_buf_to_just_last_char

    ; FALL THROUGH to main_retry_a to process the current character as the
    ; start of a new token

:main_retry_a           ; ]
    ; Because COMPLETE only happens when we can't leave an accepting state,
    ; we know we are done.  Therefore, reset to state A and try again.

    ; However, if that was the last time through the loop, stop now.
    fetch &main_is_done
    cjump &main_done

    ; First, if we were in state A, abort, so that we don't get into an
    ; infinite loop.
    fetch &state        ; state ]
    eq S_A              ; flag ]
    cjump &main_done    ; ]

    ; TODO reset the curr_token buffer to contain the
    ; first character of the next token
    ;call &stash_curr_char

    ; Reset to state A and try again with the same character
;    out '% ; DEBUG
    lit S_A             ; S_A ]
    store &state        ; ]
    fetch &curr_char    ; char ]
;    out '1  ; DEBUG
;    dup
;    out
;    out '2

    jump &main_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Error-token handler
:main_error             ; next_state ]
    drop                ; ]
    out T_ERROR
    out 'A              ; == numout 0 => no token data

    call &reset_token_buf_to_just_last_char

    jump &main_retry_a  ; ] ; retry from state A

; }}}1
; === Utility routines ==================================================== {{{1

; ---------
; cjump &creturn == conditional return
;:creturn
;    ;out '|  ; DEBUG
;    ;out 'A  ; DEBUG - zero-length token data
;    return

; ---------
; *&curr_token_pointer++ = *&curr_char;
:stash_curr_char                ; ]
;    out 'S     ; DEBUG
    ; Assignment
    fetch &curr_char            ; char
    fetch &curr_token_pointer   ; char *char]
    store                       ; ]

    ; Increment
    fetch &curr_token_pointer   ; *char ]
    add 1                       ; *char ]
    store &curr_token_pointer   ; ]

    return

; ---------
; curr_token_pointer[-1] = pop
:replace_last_saved_char        ; new-char ]
    fetch &curr_token_pointer   ; new-char; ptr to next open spot ]
    sub 1                       ; new-char; ptr to last char written
    store                       ; ]
    return

; ---------
; *curr_token = curr_char; curr_token_pointer = curr_token+1
:reset_token_buf_to_just_last_char      ; ]
    ;; Get the last char - BUT we don't need to do this since it's in curr_char
    ;fetch &curr_token_pointer           ; ptr ]
    ;sub 1                               ; ptr-1 ]
    ;fetch                               ; char ] - the last char saved

    ; Reset the curr_token_pointer
    lit &curr_token                     ; char *buf ]
    store &curr_token_pointer           ; char ]

    ; Put the first char back
    call &stash_curr_char
    return

; ---------
; Emit the contents of curr_token as a length-delimited string.
; Doesn't change the stack; does reset curr_token_pointer.
:emit_curr_token_text
;    out '!  ; DEBUG
    fetch &curr_token_pointer   ; *last-char+1 ]
    sub 2                       ; now pointing to the last char of this token,
                                ; which is the one before the last char written.
    dup                         ; *lc *lc ]
    store &curr_token_pointer   ; *lc ] - since we use it as a termination test
;    dup     ; DEBUG
;    numout  ; DEBUG

    ; Count the number of entries
    lit &curr_token             ; *last-char, *first-char ]
;    dup     ; DEBUG
;    numout  ; DEBUG
    sub                         ; count-1 ]
    add 1                       ; count ]
    numout                      ; ]             tell the reader what to expect
    lit &curr_token             ; *first-char ]

:ectt_loop                      ; *curr ]
;    out '@  ; DEBUG
    ; Print the char
    dup                         ; *curr *curr ]
    fetch                       ; *curr char ]
    out                         ; *curr ]

    ; See if we're done
    dup                         ; *curr *curr ]
    fetch &curr_token_pointer   ; *curr *curr *end ]
    eq                          ; *curr flag ]
    cjump &ectt_done            ; *curr ]

    add 1                       ; *next ]
    jump &ectt_loop

:ectt_done
    drop                        ; ]
    lit &curr_token             ; reset the curr_token pointer
    store &curr_token_pointer

    return

; }}}1
; === Bulk storage ======================================================== {{{1

:curr_token_pointer
    .data 0

:curr_token
    .reserve 256

; }}}1
; vi: set fdm=marker fdl=1:
