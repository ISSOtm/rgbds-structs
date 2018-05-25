
INCLUDE "../structs.asm"

    ; Struct declarations (ideally in a separate file, but grouped here for simplicity)
    ; Note that everything is happening outside of a `SECTION`


    ; Defines a sprite as it is in OAM
    struct Sprite
    bytes 1, YPos ; Indenting is optional, but recommended
    bytes 1, XPos
    bytes 1, Tile
    bytes 1, Attr
    end_struct

    ; Defines an NPC, as I used in Aevilia (https://github.com/ISSOtm/Aevilia-GB/blob/master/macros/memory.asm#L10-L25)
    struct Sprite
        words 1, YPos
        words 1, XPos
        bytes 1, YBox
        bytes 1, XBox
        bytes 1, InteractID

; Empty lines are fine as well

        bytes 1, Sprite
        bytes 1, Palettes

        bytes 1, Steps
        bytes 1, MovtFlags
        bytes 1, Speed
        bytes 1, YDispl
        bytes 1, Unused
        bytes 1, XDispl
    end_struct

    ; Defines a 3-byte CGB palette
    struct RawPalette
        bytes 3, Color0
        bytes 3, Color1
        bytes 3, Color2
        bytes 3, Color3
    end_struct


SECTION "Code", ROM0

    ; Using struct offsets
    ld de, wPlayer
    ld hl, NPC_InteractID
    add hl, de
    xor a
    ld [hl], a

    ld de, NPC_Steps
    add hl, de
    ld [hli], a
    ld [hl], a


    ; Using variable members
    ld hl, wPlayer_YPos
    ld c, wPlayer_InteractID - wPlayer_YPos
    ; xor a
.clearPosition
    ld [hli], a
    dec c
    jr nz, .clearPosition


    ; Using sizeof
    ld hl, wBGPalette0
    ld de, DefaultPalette
    ld c, sizeof_RawPalette ; Using the struct's size
    call memcpy_small

    ld hl, wOBJPalette0
    ld de, DefaultPalette
    ld c, sizeof_wOBJPalette ; Using the variable's size
    call memcpy_small

    ; ...

DefaultPalette:
    db $00, $00, $00
    db $0A, $0A, $0A
    db $15, $15, $15
    db $1F, $1F, $1F


memcpy_small:
    ld a, [de]
    ld [hli], a
    inc de
    dec c
    jr nz, memcpy_small
    ret


SECTION "Structs", WRAM0 ; But it can be HRAM, WRAMX, or SRAM, too!

    dstruct NPC, wPlayer

    dstruct RawPalette, wBGPalette0
    dstruct RawPalette, wOBJPalette0
