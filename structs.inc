; MIT License
;
; Copyright (c) 2018-2024 Eldred Habert and contributors
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



def STRUCTS_VERSION equs "4.1.0"
MACRO structs_assert
	assert (\1), "rgbds-structs {STRUCTS_VERSION} bug. Please report at https://github.com/ISSOtm/rgbds-structs, and share the above stack trace *and* your code there!"
ENDM


; Call with the expected RGBDS-structs version string to ensure your code
; is compatible with the INCLUDEd version of RGBDS-structs.
; Example: `rgbds_structs_version 2.0.0`
MACRO rgbds_structs_version ; version_string
	def CURRENT_VERSION EQUS STRRPL("{STRUCTS_VERSION}", ".", ",")

	; Undefine `EXPECTED_VERSION` if it does not match `CURRENT_VERSION`
	def EXPECTED_VERSION EQUS STRRPL("\1", ".", ",")
	check_ver {EXPECTED_VERSION}, {CURRENT_VERSION}

	IF !def(EXPECTED_VERSION)
		fail "rgbds-structs version \1 is required, which is incompatible with current version {STRUCTS_VERSION}"
	ENDC

	purge CURRENT_VERSION, EXPECTED_VERSION
ENDM

; Checks whether trios of version components match.
; Used internally by `rgbds_structs_version`.
MACRO check_ver ; expected major, minor, patch, current major, minor, patch
	IF (\1) != (\4) || (\2) > (\5) || (\3) > (\6)
		purge EXPECTED_VERSION
	ENDC
ENDM


; Begins a struct declaration.
MACRO struct ; struct_name
	IF def(STRUCT_NAME) || def(NB_FIELDS)
		fail "Please close struct definitions using `end_struct`"
	ENDC

	; Define two internal variables for field definitions
	def STRUCT_NAME EQUS "\1"
	def NB_FIELDS = 0
	def NB_NONALIASES = 0

	; Initialize _RS to 0 for defining offset constants
	RSRESET
ENDM

; Ends a struct declaration.
MACRO end_struct
	; Define the number of fields and size in bytes
	def {STRUCT_NAME}_nb_fields EQU NB_FIELDS
	def {STRUCT_NAME}_nb_nonaliases EQU NB_NONALIASES
	def sizeof_{STRUCT_NAME}    EQU _RS

	IF def(STRUCTS_EXPORT_CONSTANTS)
		EXPORT {STRUCT_NAME}_nb_fields, sizeof_{STRUCT_NAME}
	ENDC

	; Purge the internal variables defined by `struct`
	purge STRUCT_NAME, NB_FIELDS, NB_NONALIASES
ENDM


; Defines a field of N bytes.
MACRO bytes
	new_field rb, \#
ENDM
MACRO words
	new_field rw, \#
ENDM
MACRO longs
	new_field rl, \#
ENDM
MACRO alias
	new_field rb,0, \#
ENDM

; Extends a new struct by an existing struct, effectively cloning its fields.
MACRO extends ; struct_type[, sub_struct_name]
	IF !def(\1_nb_fields)
		fail "Struct \1 isn't defined!"
	ENDC
	IF _NARG != 1 && _NARG != 2
		fail "Invalid number of arguments, expected 1 or 2"
	ENDC
	FOR FIELD_ID, \1_nb_fields
		def EXTENDS_FIELD EQUS "\1_field{d:FIELD_ID}"
		get_nth_field_info {STRUCT_NAME}, NB_FIELDS

		IF _NARG == 1
			def {STRUCT_FIELD_NAME} EQUS "{{EXTENDS_FIELD}_name}"
		ELSE
			def {STRUCT_FIELD_NAME} EQUS "\2_{{EXTENDS_FIELD}_name}"
		ENDC
		def {STRUCT_FIELD} RB {EXTENDS_FIELD}_size
		IF def(STRUCTS_EXPORT_CONSTANTS)
			EXPORT {STRUCT_FIELD}
		ENDC
		def {STRUCT_NAME}_{{STRUCT_FIELD_NAME}} EQU {STRUCT_FIELD}
		def {STRUCT_FIELD_SIZE} EQU {EXTENDS_FIELD}_size
		def {STRUCT_FIELD_TYPE} EQUS "{{EXTENDS_FIELD}_type}"

		purge_nth_field_info

		def NB_FIELDS += 1
		IF {EXTENDS_FIELD}_size != 0
			def NB_NONALIASES += 1
		ENDC
		purge EXTENDS_FIELD
	ENDR
ENDM


; Defines EQUS strings pertaining to a struct's Nth field.
; Used internally by `new_field` and `dstruct`.
MACRO get_nth_field_info ; struct_name, field_id
	def STRUCT_FIELD      EQUS "\1_field{d:\2}"       ; prefix for other EQUS
	def STRUCT_FIELD_NAME EQUS "{STRUCT_FIELD}_name"  ; field's name
	def STRUCT_FIELD_TYPE EQUS "{STRUCT_FIELD}_type"  ; type ("b", "l", or "l")
	def STRUCT_FIELD_SIZE EQUS "{STRUCT_FIELD}_size"  ; sizeof(type) * nb_el
ENDM

; Purges the variables defined by `get_nth_field_info`.
; Used internally by `new_field` and `dstruct`.
MACRO purge_nth_field_info
	purge STRUCT_FIELD, STRUCT_FIELD_NAME, STRUCT_FIELD_TYPE, STRUCT_FIELD_SIZE
ENDM

; Defines a field with a given RS type (`rb`, `rw`, or `rl`).
; Used internally by `bytes`, `words`, `longs`, and `alias`.
MACRO new_field ; rs_type, nb_elems, field_name
	IF !def(STRUCT_NAME) || !def(NB_FIELDS)
		fail "Please start defining a struct, using `struct`"
	ENDC

	get_nth_field_info {STRUCT_NAME}, NB_FIELDS

	; Set field name
	def {STRUCT_FIELD_NAME} EQUS "\3"
	; Set field offset
	def {STRUCT_FIELD} \1 (\2)
	IF def(STRUCTS_EXPORT_CONSTANTS)
		EXPORT {STRUCT_FIELD}
	ENDC
	; Alias this in a human-comprehensible manner
	def {STRUCT_NAME}_\3 EQU {STRUCT_FIELD}
	; Compute field size
	def {STRUCT_FIELD_SIZE} EQU _RS - {STRUCT_FIELD}
	; Set properties
	def {STRUCT_FIELD_TYPE} EQUS STRSLICE("\1", 1)

	purge_nth_field_info

	def NB_FIELDS += 1
	IF \2 != 0
		def NB_NONALIASES += 1
	ENDC
ENDM


; Strips whitespace from the left of a string.
; Used internally by `dstruct`.
MACRO lstrip ; string_variable
	FOR START_POS, STRLEN(#\1)
		IF STRFIND(" \t", STRSLICE(#\1, START_POS, START_POS + 1)) == -1
			break
		ENDC
	ENDR
	redef \1 EQUS STRSLICE(#\1, START_POS)
	purge START_POS
ENDM

; Allocates space for a struct in memory.
; If no further arguments are supplied, the space is allocated using `ds`.
; Otherwise, the data is written to memory using the appropriate types.
; For example, a struct defined with `bytes 1, Field1` and `words 3, Field2`
; could take four extra arguments, one byte then three words.
; Each such argument would have an equal sign between the name and value.
MACRO dstruct ; struct_type, instance_name[, ...]
	IF !def(\1_nb_fields)
		fail "Struct \1 isn't defined!"
	ELIF _NARG != 2 && _NARG != 2 + \1_nb_nonaliases
		; We must have either a RAM declaration (no data args)
		; or a ROM one (RAM args + data args)
		fail STRFMT("Expected 2 or %u args to `dstruct`, but got {d:_NARG}", 2 + \1_nb_nonaliases)
	ENDC

	; RGBASM always expands macro args, so `IF _NARG > 2 && STRFIND("\3", "=")`
	; would error out when there are only two args.
	; Therefore, the condition is checked here (we can't nest the `IF`s over
	; there because that would require a duplicated `ELSE`).
	def IS_NAMED_INSTANTIATION = 0
	IF _NARG > 2
		redef IS_NAMED_INSTANTIATION = !STRCMP(STRSLICE("\3", 0, 1), ".") && STRFIND("\3", "=") != -1
	ENDC

	IF IS_NAMED_INSTANTIATION
		; This is a named instantiation; translate that to an ordered one.
		; This is needed because data has to be laid out in order, so some translation is needed anyway.
		; And finally, I believe it's better to re-use the existing code at the cost of a single nested macro.

		FOR ARG_NUM, 3, _NARG + 1
			; Remove leading whitespace to obtain something like ".name=value"
			; (this enables a simple check for starting with a period)
			redef CUR_ARG EQUS "\<ARG_NUM>"
			lstrip CUR_ARG

			; Ensure that the argument has a name and a value,
			; separated by an equal sign
			def EQUAL_POS = STRFIND("{CUR_ARG}", "=")
			IF EQUAL_POS == -1
				fail "\"{CUR_ARG}\" is not a named initializer!"
			ELIF STRCMP(STRSLICE("{CUR_ARG}", 0, 1), ".")
				fail "\"{CUR_ARG}\" does not start with a period!"
			ENDC

			; Find out which field the current argument is
			FOR FIELD_ID, \1_nb_fields
				IF !STRCMP(STRSLICE("{CUR_ARG}", 1, EQUAL_POS), "{\1_field{d:FIELD_ID}_name}")
					IF \1_field{d:FIELD_ID}_size == 0
						fail "Cannot initialize an alias"
					ENDC
					break ; Match found!
				ENDC
			ENDR

			IF FIELD_ID == \1_nb_fields
				fail "\"{CUR_ARG}\" does not match any member of \1"
			ELIF def(FIELD_{d:FIELD_ID}_INITIALIZER)
				fail "\"{CUR_ARG}\" conflicts with \"{FIELD_{d:FIELD_ID}_ARG}\""
			ENDC

			; Save the argument to report in case a later argument conflicts with it
			def FIELD_{d:FIELD_ID}_ARG EQUS "{CUR_ARG}"

			; Enclose argument initializers in parentheses so any commas inside
			; it will not start a new argument
			def FIELD_{d:FIELD_ID}_INITIALIZER EQUS STRCAT("(", STRSLICE("{CUR_ARG}", EQUAL_POS + 1), ")")
		ENDR
		purge ARG_NUM, CUR_ARG

		; Now that we matched each named initializer to their order,
		; invoke the macro again but without names
		def ORDERED_ARGS EQUS "\1, \2"
		FOR FIELD_ID, \1_nb_fields
			IF \1_field{d:FIELD_ID}_size != 0
				redef ORDERED_ARGS EQUS "{ORDERED_ARGS}, {FIELD_{d:FIELD_ID}_INITIALIZER}"
				purge FIELD_{d:FIELD_ID}_ARG, FIELD_{d:FIELD_ID}_INITIALIZER
			ENDC
		ENDR
		purge FIELD_ID

		; Do the nested ordered instantiation
		def WAS_NAMED_INSTANTIATION = 1
		dstruct {ORDERED_ARGS}, ; purges IS_NAMED_INSTANTIATION
		purge ORDERED_ARGS, WAS_NAMED_INSTANTIATION

	ELSE
		; This is an ordered instantiation, not a named one.

		; Define the struct's root label unless it's anonymous.
		IF STRLEN("\2")
			\2::
		ENDC

		IF def(STRUCT_SEPARATOR)
			def DSTRUCT_SEPARATOR equs "{STRUCT_SEPARATOR}"
		ELSE
			def DSTRUCT_SEPARATOR equs "_"
		ENDC
		; Define each field
		def ARG_NUM = 3
		FOR FIELD_ID, \1_nb_fields
			get_nth_field_info \1, FIELD_ID

			IF STRLEN("\2")
				; Define the label for the field
				\2_{{STRUCT_FIELD_NAME}}::
				def STRUCT_FIELD_START EQUS "\2_{{STRUCT_FIELD_NAME}}"
			ELSE
				; Label the field anonymously for padding calculations
				:
				def STRUCT_FIELD_START EQUS ":-"
			ENDC

			IF STRUCT_FIELD_SIZE != 0 ; Skip aliases
				; Declare the space for the field
				IF ARG_NUM <= _NARG
					; ROM declaration; use `db`, `dw`, or `dl`
					def FIELD_INITIALIZER EQUS "\<ARG_NUM>"
					IF def(WAS_NAMED_INSTANTIATION)
						; Remove the parentheses that named instantiation placed around the field initializer.
						; This is necessary so that strings are correctly interpreted.
						redef FIELD_INITIALIZER EQUS STRSLICE("{FIELD_INITIALIZER}", 1, -2)
					ENDC
					d{{STRUCT_FIELD_TYPE}} {FIELD_INITIALIZER}
					purge FIELD_INITIALIZER
					def ARG_NUM += 1
				ENDC
				; Add padding as necessary after the provided initializer
				; (possibly all of it, especially for RAM use)
				IF {STRUCT_FIELD_SIZE} < @ - {STRUCT_FIELD_START}
					fail STRFMT("Initializer for %s is %u bytes, expected %u at most", "{STRUCT_FIELD_START}", @ - {STRUCT_FIELD_START}, {STRUCT_FIELD_SIZE})
				ENDC
				ds {STRUCT_FIELD_SIZE} - (@ - {STRUCT_FIELD_START})
			ENDC

			purge_nth_field_info
			purge STRUCT_FIELD_START
		ENDR
		purge FIELD_ID, ARG_NUM, DSTRUCT_SEPARATOR

		; Define instance's properties from struct's
		IF STRLEN("\2") && STRFIND("\2", ".") == -1
			def \2_nb_fields EQU \1_nb_fields
			def sizeof_\2    EQU @ - (\2)
			structs_assert sizeof_\1 == sizeof_\2

			IF def(STRUCTS_EXPORT_CONSTANTS)
				EXPORT \2_nb_fields, sizeof_\2
			ENDC
		ENDC

		purge IS_NAMED_INSTANTIATION
	ENDC
ENDM

; Allocates space for an anonymous struct in memory.
; Acts like `dstruct` but without defining any labels for the struct or its fields.
MACRO dstruct_anon ; struct_type[, ...]
	def DSTRUCT_ANON_NAME EQUS "\1"
	shift
	dstruct {DSTRUCT_ANON_NAME}, , \#
	purge DSTRUCT_ANON_NAME
ENDM


; Allocates space for an array of structs in memory.
; Each struct will have the index appended to its name **as decimal**.
; For example: `dstructs 32, NPC, wNPC` will define `wNPC0`, `wNPC1`, and so on until `wNPC31`.
; This is a change from the previous version of rgbds-structs, where the index was uppercase hexadecimal.
; If the third argument is not given, no names are defined, and the structs are anonymous.
; For example: `dstructs 32, NPC` will repeat `dstruct_anon NPC` 32 times.
; Does not support data declarations because I think each struct should be defined individually for that purpose.
MACRO dstructs ; nb_structs, struct_type[, instance_name]
	IF _NARG == 2
		REPT \1
			dstruct_anon \2
		ENDR
	ELIF _NARG == 3
		FOR STRUCT_ID, \1
			dstruct \2, \3{d:STRUCT_ID}
		ENDR
		purge STRUCT_ID
	ELSE
		fail "Expected 2 or 3 args to `dstructs`, but got {d:_NARG}"
	ENDC
ENDM
