
; Common pitfalls when using rgbds-structs
; Resulting error messages included below the code snippet
; The same causes may cause error messages not included there, especially forgetting `end_struct`.



; Not including `structs.asm` (it happens!)
INCLUDE "../structs.asm"
; "Error: Unable to open included file '../structs.asm'"
; "Macro 'struct' not defined"

; Including `structs.asm` twice
INCLUDE "../structs.asm"
; A slew of "'xxx' already defined in structs.asm(yyy)" messages


; No spacing before macro names
struct Trimmed
; "Macro 'Universe' not defined"


; Not closing a struct declaration with `end_struct`
    struct Infinite
    bytes 1, Forever
; "Please close struct definitions using `end_struct`", when declaring another macro afterwards
; "'sizeof_Infinite' not defined", when trying to use sizeof_XXX or XXX_nb_fields


; Using illegal chars in struct names
    struct $Money$
    longs 1, MONEYYYY
    end_struct
; "syntax error" (VERY DESCRIPTIVE), will be located in macro `new_field`.

; Forgetting that the member declaration macros take plural
    struct Singular
    byte 1, TheChosenOne
    word 1, TheChosenOther
    end_struct
; "Macro 'byte' not defined", or 'word', or 'long', etc.

; Using dashes (-) instead of underscores (_)
    struct Dashing
    bytes 1, Foo
    end-struct
; "Macro 'end' not defined"
