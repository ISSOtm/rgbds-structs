
# RGBDS structs

An attempt at using macros to add struct-like functionality to RGBDS.


# Table of contents

- [Installing](#installing)
- [Usage](#usage)


# Installing

This doesn't actually require any installing, only to `INCLUDE` the file `structs.asm` in your project. Examples can be found in the `examples` folder. This project is licensed under the MIT license.

This is confirmed to work with RGBDS 0.3.7, but should also work with versions 0.3.3 and newer. If you find a compatibility issue, please file it [here](https://github.com/ISSOtm/rgbds-structs/issues/new).


# Usage

## Declaring a struct

Begin the declaration with `struct StructName`. This need not be in a `SECTION`, and it is rather recommended to declare structs in header files, as with C.

Then, declare each member; the declaration style is inspired by RGBDS' `_RS` command group: the macro name is the field type, the first argument dictates how many units the argument uses, and the second argument gives the field name.

Finally, you must close the declaration with `end_struct`. This is required to properly define all of the struct's variables, and to be able to declare another struct (which will otherwise fail with a descriptive error message). Please note that you can forget to add `end_struct` and not get any error messages, so please be careful.


Example of correct usage:
```
    ; Please ensure you put whitespace before the macro names, otherwise RGBDS will try to re-define them and error out
    struct NPC
    words 1, YPos         ; 2 bytes
    words 1, XPos         ; 2 bytes
    bytes 1, YBox         ; 1 byte
    bytes 1, XBox         ; 1 byte
    bytes 2, GfxID        ; 2 bytes
    longs 2, MovementData ; 8 bytes
    end_struct
```


## Defined variables

A struct declaration defines offsets for each member. Here, `NPC_YPos` would be 0, `NPC_XPos` would be 2, `NPC_YBox` would be 4, and so on. These are defined as constants, and thus will **not** be available at link time.

Additionally, two constants are defined: `sizeof_NPC` contains the struct's total size (here, 16), and `NPC_nb_fields` contains the number of fields (here, 6).

**Please do NOT `PURGE` any of these constants; this would break `dstruct`!!**


## Using a struct

To allocate a struct in memory, use the `dstruct StructName, VarName` macro. For example:
```
    ; Again, remember to put spacing before the macro name
    dstruct NPC, Player
```

This will define the following labels: `Player` (pointing to the struct's 1st byte), `Player_YPos`, `Player_XPos`, `Player_YBox`, etc. (all pointing to the struct's corresponding attribute). These are all declared as **exported** labels, and will thus be available at link time.

It is unnecessary to put a label right before `dstruct`, since a label is declared at the struct's root.


Two extra constants are declared, that mirror the struct's: `sizeof_Player` would be equal to `sizeof_NPC`, and `Player_nb_fields` would equal `NPC_nb_fields`. These constants will keep their values even if the originals, such as `sizeof_NPC`, are `PURGE`'d.



# Credits

Written by [ISSOtm](https://github.com/ISSOtm), with help from the GBDev Discord server (from [awesome-gbdev](https://github.com/avivace/awesome-gbdev)) and #gbdev on EFNet.
