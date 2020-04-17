
; MIT License
;
; Copyright (c) 2018-2019 Eldred Habert
; Originally hosted at https://github.com/ISSOtm/rgbds-structs
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.


; !!! WARNING ABOUT READABILITY OF THIS CODE !!!
;
; RGBDS, being the venerable/old/decrepit (pick on depending on mood) assembler that it is, requires
; all label, variable etc. definitions to be on column 0. As in, no whitespace allowed (otherwise, syntax error)
; Meanwhile, these macros tend to use a lot of nesting (requiring indenting for readability),
; as well as variable definitions (requiring none to work).
; As you can probably tell, those two conflict and result in very poor readability
; Sadly, there is nothing I can do against that short of using a special preprocessor,
; which I refuse to do for usability's sake.
; You have all my apologies, how little they may matter, if you are trying to read this code
; I still did my best to use explicit comments and variable names, hope they will help!



; strreplace variable_name, original_char, new_char
strreplace: MACRO
DOT_POS = STRIN("{\1}", \2)
    IF DOT_POS != 0
TMP equs STRCAT(STRSUB("{\1}", 1, DOT_POS + (-1)), STRCAT(\3, STRSUB("{\1}", DOT_POS + 1, STRLEN("{\1}") - DOT_POS)))
        PURGE \1
\1 equs "{TMP}"
        PURGE TMP
        strreplace \1, \2, \3
    ENDC
    IF DEF(DOT_POS)
        PURGE DOT_POS
    ENDC
ENDM


; rgbds_structs_version version_string
; Call with the expected version string to ensure you're using a compatible version
; Example: rgbds_structs_version 1.0.0
rgbds_structs_version: MACRO
CURRENT_VERSION equs "1,2,1"
EXPECTED_VERSION equs "\1"
    strreplace EXPECTED_VERSION, ".", "\,"
check_ver: MACRO
    IF \1 != \4 || \2 > \5 || \3 > \6
        PURGE EXPECTED_VERSION
    ENDC
ENDM

CHECK_VER_CALL equs "check_ver {EXPECTED_VERSION},{CURRENT_VERSION}"
    CHECK_VER_CALL
    IF !DEF(EXPECTED_VERSION)
        strreplace CURRENT_VERSION, "\,", "."
        FAIL "RGBDS-structs version \1 is required, which is incompatible with current version {CURRENT_VERSION}"
    ENDC
    PURGE CHECK_VER_CALL
    PURGE check_ver
    PURGE CURRENT_VERSION
    PURGE EXPECTED_VERSION
ENDM


; struct struct_name
; Begins a struct declaration
struct: MACRO
    IF DEF(NB_FIELDS)
        FAIL "Please close struct definitions using `end_struct`"
    ENDC

STRUCT_NAME equs "\1"

NB_FIELDS = 0
    RSRESET
ENDM

; end_struct
; Ends a struct declaration
end_struct: MACRO
    ; Set nb of fields
STRUCT_NB_FIELDS equs "{STRUCT_NAME}_nb_fields"
STRUCT_NB_FIELDS = NB_FIELDS
    PURGE STRUCT_NB_FIELDS

    ; Set size of struct
STRUCT_SIZEOF equs "sizeof_{STRUCT_NAME}"
STRUCT_SIZEOF RB 0
    PURGE STRUCT_SIZEOF

    PURGE NB_FIELDS
    PURGE STRUCT_NAME
ENDM


; get_nth_field_info field_id
; Defines EQUS strings pertaining to a struct's Nth field
; For internal use, please do not use externally
get_nth_field_info: MACRO
    ; Field's name
STRUCT_FIELD equs "{STRUCT_NAME}_field{d:\1}"
STRUCT_FIELD_NAME equs "{STRUCT_FIELD}_name"
STRUCT_FIELD_TYPE equs "{STRUCT_FIELD}_type"
STRUCT_FIELD_NBEL equs "{STRUCT_FIELD}_nb_el" ; Number of elements
STRUCT_FIELD_SIZE equs "{STRUCT_FIELD}_size" ; sizeof(type) * nb_el
ENDM


; new_field nb_elems, rs_type, field_name
; For internal use, please do not use externally
new_field: MACRO
    IF !DEF(STRUCT_NAME) || !DEF(NB_FIELDS)
        FAIL "Please start defining a struct, using `define_struct`"
    ENDC

    get_nth_field_info NB_FIELDS
    ; Set field name (keep in mind `STRUCT_FIELD_NAME` is *itself* an EQUS!)
STRUCT_FIELD_NAME equs "\"\3\""
    PURGE STRUCT_FIELD_NAME

    ; Set field offset
STRUCT_FIELD \2 (\1)
    ; Alias this in a human-comprehensive manner
STRUCT_FIELD_NAME equs "{STRUCT_NAME}_\3"
STRUCT_FIELD_NAME = STRUCT_FIELD

    ; Compute field size
CURRENT_RS RB 0
STRUCT_FIELD_SIZE = CURRENT_RS - STRUCT_FIELD

    ; Set properties
STRUCT_FIELD_NBEL = \1
STRUCT_FIELD_TYPE equs STRSUB("\2", 2, 1)

    PURGE STRUCT_FIELD
    PURGE STRUCT_FIELD_NAME
    PURGE STRUCT_FIELD_TYPE
    PURGE STRUCT_FIELD_NBEL
    PURGE STRUCT_FIELD_SIZE
    PURGE CURRENT_RS

NB_FIELDS = NB_FIELDS + 1
ENDM

; bytes nb_bytes, field_name
; Defines a field of N bytes
bytes: MACRO
    new_field \1, RB, \2
ENDM

; words nb_words, field_name
; Defines a field of N*2 bytes
words: MACRO
    new_field \1, RW, \2
ENDM

; longs nb_longs, field_name
; Defines a field of N*4 bytes
longs: MACRO
    new_field \1, RL, \2
ENDM


; dstruct struct_type, INSTANCE_NAME[, ...]
; Allocates space for a struct in memory
; If no further arguments are supplied, the space is simply allocated (using `ds`)
; Otherwise, the data is written to memory using the appropriate types
; For example, a struct defined with `bytes 1, Field1` and `words 3, Field2` would have four extra arguments, one byte then three words.
dstruct: MACRO
NB_FIELDS equs "\1_nb_fields"
    IF !DEF(NB_FIELDS)
        FAIL "Struct \1 isn't defined!"
    ELIF _NARG != 2 && _NARG != NB_FIELDS + 2 ; We must have either a RAM declaration (no data args) or a ROM one (RAM args + data args)
EXPECTED_NARG = 2 + NB_FIELDS
        FAIL "Invalid number of arguments, expected 2 or {d:EXPECTED_NARG} but got {d:_NARG}"
    ENDC

    ; Define the two fields required by `get_nth_field_info`
STRUCT_NAME   equs "\1" ; Which struct `get_nth_field_info` should pull info about
INSTANCE_NAME equs "\2" ; The instance's base name


    ; RGBASM always expands `\X` macro args, so `IF _NARG > 2 && STRIN("\3", "=")` will error out when there are only 2 args
    ; Therefore, the condition is checked here (we can't nest the `IF`s over there because that doesn't translate well to `ELSE`)
IS_NAMED_INVOCATION = 0
    IF _NARG > 2
        IF STRIN("\3", "=")
IS_NAMED_INVOCATION = 1
        ENDC
    ENDC

    IF IS_NAMED_INVOCATION
        ; This is a named instantiation, translate that to an ordered one
        ; This is needed because data has to be laid out in order, so some translation is needed anyways
        ; And finally, it's better to re-use the existing code at the cost of a single nested macro, I believe
MACRO_CALL equs "dstruct \1, \2" ; This will be used later, but define it now because `SHIFT` will be run
        ; In practice `SHIFT` has no effect outside of one when invoked inside of a REPT block, but I hope this behavior is changed (causes a problem elsewhere)

ARG_NUM = 3
        REPT NB_FIELDS
            ; Find out which argument the current one is
CUR_ARG equs "\3"
            ; Remove all whitespace to obtain something like ".name=value" (whitespace are unnecessary and complexify parsing)
            strreplace CUR_ARG, " ",  ""
            strreplace CUR_ARG, "\t", ""

EQUAL_POS = STRIN("{CUR_ARG}", "=")
            IF EQUAL_POS == 0
                FAIL "Argument #{ARG_NUM} (\3) does not contain an equal sign in this named instantiation"
            ELIF STRCMP(STRSUB("{CUR_ARG}", 1, 1), ".")
                FAIL "Argument #{ARG_NUM} (\3) does not start with a period"
            ENDC

FIELD_ID = -1
CUR_FIELD_ID = 0
            REPT NB_FIELDS

                ; Get the name of the Nth field and compare
TMP equs "{STRUCT_NAME}_field{d:CUR_FIELD_ID}_name"
CUR_FIELD_NAME equs TMP
                PURGE TMP

                IF !STRCMP(STRUPR("{CUR_FIELD_NAME}"), STRUPR(STRSUB("{CUR_ARG}", 2, EQUAL_POS - 2)))
                    ; Match found!
                    IF FIELD_ID == -1
FIELD_ID = CUR_FIELD_ID
                    ELSE
TMP equs "{STRUCT_NAME}_field{d:CUR_FIELD_ID}_name"
CONFLICTING_FIELD_NAME equs TMP
                        PURGE TMP
                        FAIL "Fields {CUR_FIELD_NAME} and {CONFLICTING_FIELD_NAME} have conflicting names (case-insensitive), cannot perform named instantiation"
                    ENDC
                ENDC

                PURGE CUR_FIELD_NAME
CUR_FIELD_ID = CUR_FIELD_ID + 1
            ENDR
            PURGE CUR_FIELD_ID

            IF FIELD_ID == -1
                FAIL "Argument #{d:ARG_NUM} (\3) does not match any field of the struct"
            ENDC

INITIALIZER_NAME equs "FIELD_{d:FIELD_ID}_INITIALIZER"
INITIALIZER_NAME equs STRSUB("{CUR_ARG}", EQUAL_POS + 1, STRLEN("{CUR_ARG}") - EQUAL_POS)
            PURGE INITIALIZER_NAME

            ; Go to next arg
ARG_NUM = ARG_NUM + 1
            SHIFT
            PURGE CUR_ARG

        ENDR

        ; Now that we matched each named initializer to their order, invoke the macro again but without names
FIELD_ID = 0
        REPT NB_FIELDS
TMP equs "{MACRO_CALL}"
            PURGE MACRO_CALL
GET_INITIALIZER_VALUE equs "INITIALIZER_VALUE equs \"\{FIELD_{d:FIELD_ID}_INITIALIZER\}\""
GET_INITIALIZER_VALUE
            PURGE GET_INITIALIZER_VALUE
MACRO_CALL equs "{TMP}, {INITIALIZER_VALUE}"
            PURGE TMP
            PURGE INITIALIZER_VALUE
FIELD_ID = FIELD_ID + 1
        ENDR

        PURGE FIELD_ID
        ; Clean up vars for nested invocation, otherwise some `equs` will be expanded
        PURGE INSTANCE_NAME
        PURGE STRUCT_NAME
        PURGE IS_NAMED_INVOCATION
        PURGE NB_FIELDS

        MACRO_CALL ; Now do call the macro
        PURGE MACRO_CALL


    ELSE


INSTANCE_NAME:: ; Declare the struct's root
        ; Define instance's properties from struct's
\2_nb_fields = NB_FIELDS
sizeof_\2 = sizeof_\1

        ; Start defining fields
FIELD_ID = 0
        REPT NB_FIELDS

            get_nth_field_info FIELD_ID

FIELD_NAME equs STRCAT("{INSTANCE_NAME}_", STRUCT_FIELD_NAME)
FIELD_NAME::

            ; We have defined a label, but now we also need the data backing it
            ; There are basically two options:
            IF _NARG == 2 ; RAM definition, no data
                ds STRUCT_FIELD_SIZE
            ELSE

DATA_TYPE equs STRCAT("D", {{STRUCT_FIELD_TYPE}})

                REPT STRUCT_FIELD_NBEL
                    DATA_TYPE \3
                    SHIFT
                ENDR
                PURGE DATA_TYPE
            ENDC

            ; Clean up vars for next iteration
            PURGE STRUCT_FIELD
            PURGE STRUCT_FIELD_NAME
            PURGE STRUCT_FIELD_TYPE
            PURGE STRUCT_FIELD_NBEL
            PURGE STRUCT_FIELD_SIZE
            PURGE FIELD_NAME

FIELD_ID = FIELD_ID + 1
        ENDR


        ; Clean up
        PURGE FIELD_ID
        ; Make sure to keep what's here in sync with cleanup at the end of a named invocation
        PURGE INSTANCE_NAME
        PURGE STRUCT_NAME
        PURGE IS_NAMED_INVOCATION
        PURGE NB_FIELDS
    ENDC
ENDM


; dstructs nb_structs, struct_type, INSTANCE_NAME
; Allocates space for an array of structs in memory
; Each struct will have the index appended to its name **as hex**
; (for example: `dstructs 32, NPC, wNPC` will define wNPC0, wNPC1, and so on until wNPC1F)
; This is a limitation because RGBASM does not provide an easy way to get the decimal representation of a number
; Does not support data declarations because I think each struct should be defined individually for that purpose
dstructs: MACRO
STRUCT_ID = 0
    REPT \1
        dstruct \2, \3{X:STRUCT_ID}
STRUCT_ID = STRUCT_ID + 1
    ENDR

    PURGE STRUCT_ID
ENDM
