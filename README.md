# RGBDS structs

A [RGBDS](https://rgbds.gbdev.io) macro pack that provides `struct`-like functionality.

## Download

Please select a version from [the releases](https://github.com/ISSOtm/rgbds-structs/releases), and download either of the "source code" links.
(If you do not know what a `.tar.gz` file is, download the `.zip` one.)

The [latest rgbds-structs version](https://github.com/ISSOtm/rgbds-structs/releases/latest) is **3.0.1**.
It will only work with RGBDS 0.5.1 and newer.
A previous version, [1.3.0](https://github.com/ISSOtm/rgbds-structs/releases/tag/v1.3.0), is confirmed to work with RGBDS 0.3.7, but should also work with versions 0.3.3 and newer.
If you find a compatibility issue, [please file it here](https://github.com/ISSOtm/rgbds-structs/issues/new).

## Installing

This doesn't actually require any installing, only to `INCLUDE` the file `structs.asm` in your project.
This project is licensed under [the MIT license](https://github.com/ISSOtm/rgbds-structs/blob/master/LICENSE), which allows including a copy of `structs.asm` in your project.
I only ask that you credit me, please :)

Examples can be found in [the `examples` folder](https://github.com/ISSOtm/rgbds-structs/tree/master/examples); both of what to do, and what not to do with explanations of the error messages you should get.

## Usage

Please do not rely on any macro or symbol not documented below, as they are not considered part of the API, and may unexpectedly break between releases.
RGBDS does not allow any scoping, so macros are "leaky"; apologies if you get name clashes.

### Ensuring version compatibility

rgbds-structs follows [semantic versioning](https://semver.org), so you can know if there are breaking changes between releases.
You can also easily enforce this in your code, using the `rgbds_structs_version` macro: simply call it with the version of rgbds-structs you require (`rgbds_structs_version 2.0.0`), and it will error out if a (potentially) incompatible version is used.

### Declaring a struct

1. Begin the declaration with `struct StructName`.
   This need not be in a `SECTION`, and it is rather recommended to declare structs in header files, as with C.
2. Then, declare each member, using the macros `bytes`, `words`, and `longs`.
   The declaration style is inspired by [RGBASM's `_RS` command family](https://rgbds.gbdev.io/docs/v0.5.2/rgbasm.5/#Offset_constants): the macro name gives the unit type, the first argument specifies how many units the member uses, and the second argument gives the member name.
3. Finally, you must close the declaration with `end_struct`.
   This is required to properly define all of the struct's constants, and to be able to declare another struct (which will otherwise fail with a descriptive error message).
   Please note that forgetting to add an `end_struct` does not always yield any error messages, so please be careful.

Please do not use anything other than the prescribed macros between `struct` and `end_struct` (especially the `_RS` family of directives), as this may break the macros' operation.

Example of correct usage:

```asm
    ; RGBASM requires whitespace before the macro name
    struct NPC
    words 1, YPos         ;  2 bytes
    words 1, XPos         ;  2 bytes
    bytes 1, YBox         ;  1 byte
    bytes 1, XBox         ;  1 byte
    bytes 6, Name         ;  6 bytes
    longs 4, MovementData ; 16 bytes
    end_struct
```

Note that no padding is inserted between members by rgbds-structs itself; insert "throwaway" members for that.

```asm
    struct Example
        bytes 3, First
        bytes 1, Padding  ; like this
        words 2, Second
    end_struct
```

(Some like to insert an extra level of indentation for member definitions. This is not required, but may help with readability.)

Note also that whitespace is **not** allowed in a struct or member's name.

Sometimes it's useful to give multiple names to the same area of memory, which can be accomplished with `alias`.

```asm
    struct Actor
        words 1, YPos
        words 1, XPos
        ; Since dunion is used, the following field will have 2 names
        alias Money ; If this actor is the player, store how much money they have.
        words 1, Target ; If this actor is an enemy, store their target actor.
    end_struct
```

Passing a size of 0 to any of `bytes`, `words`, or `longs` works the same.

`extends` can be used to nest a structure within another.

```asm
    struct Item
        words 1, Name
        words 1, Graphics
        bytes 1, Type
    end_struct

    struct HealingItem
        extends Item
        bytes Strength
    end_struct
```

This effectively copies the members of the source struct, meaning that you can now use `HealingItem_Name` as well as `HealingItem_Strength`.

If a second argument is provided, the copied members will be prefixed with this string.

```asm
    struct SaveFile
        longs 1, Checksum
        extends NPC, Player
    end_struct
```

This creates constants like `SaveFile_Player_Name`.

`extends` can be used as many times as you want, anywhere within the struct.

#### Defined constants

A struct's definition has one constant defined per member, which indicates its offset (in bytes) from the beginning of the struct.
For the `NPC` example above, `NPC_YPos` would be 0, `NPC_XPos` would be 2, `NPC_YBox` would be 4, and so on.

Two additional constants are defined: `sizeof_NPC` contains the struct's total size (here, 16), and `NPC_nb_fields` contains the number of members (here, 6).

Be careful that `dstruct` relies on all of these constants and a couple more; `dstruct` may break in unexpected ways if tampering with them, which includes `PURGE`.

None of these constants are exported by default, but you can [`export` them manually](https://rgbds.gbdev.io/docs/v0.5.2/rgbasm.5/#Exporting_and_importing_symbols), or `INCLUDE` the struct definition(s) everywhere the constants are to be used.
Since `dstruct` and family require the constants to be defined at assembling time, those macros require the former solution.
However, the latter solution may decrease build times if you have a lot of source files.

If you want the constants to be exported by default, define symbol `STRUCTS_EXPORT_CONSTANTS` before calling `struct`.

### Using a struct

**The following functionality requires the struct to have been defined earlier in the same RGBASM invocation (aka "translation unit").**

To allocate a struct in memory, use the `dstruct StructName, VarName` macro. For example:

```asm
    ; Again, remember to put whitespace before the macro name
    dstruct NPC, Player
```

This will define the following labels: `Player` (pointing to the struct's first byte), `Player_YPos`, `Player_XPos`, `Player_YBox`, etc. (all pointing to the struct's corresponding attribute).
These are all declared as **exported** labels, and will thus be available at link time.
(You can `PURGE` them if you do not want this.)

You can customize the label naming by defining the string equate `STRUCT_SEPARATOR`; it will replace the underscore in the above.
Of particular interest is `DEF STRUCT_SEPARATOR equs "."`, which causes members to be defined as local labels, but prevents the "root" label from itself being a local label.
(This is because `Player.YPos` is a valid RGBDS symbol name, but `.player.YPos` is not.)
`STRUCT_SEPARATOR` can be changed and even `PURGE`d between invocations of `dstruct` and family.

It is unnecessary to put a label right before `dstruct`, since a label is declared at the struct's root.

Two extra constants are declared, that mirror the struct's: `sizeof_Player` would be equal to `sizeof_NPC`, and `Player_nb_fields` would equal `NPC_nb_fields` (sse below).
These constants will keep their values even if the originals, such as `sizeof_NPC`, are `PURGE`'d.
Like structs' constants, these are not exported unless `STRUCTS_EXPORT_CONSTANTS` is defined.

#### Defining data from a struct

The use of `dstruct` described above makes it act like [`ds`](https://rgbds.gbdev.io/docs/v0.5.2/rgbasm.5/#Statically_allocating_space_in_RAM) (meaning, it can be used in RAM, and will be filled with padding bytes if used in ROM).
However, it is possible to use `dstruct` to define data without having to resort to piles of `db`s and `dw`s.

```asm
    dstruct NPC, Toad, 42, 69, 3, 2, "TOAD", $DEAD\, $BEEF
```

The syntax is the same, but add one argument ("initializer") per struct member.
`bytes` will be provided to `db`, `words` to `dw`, and `longs` to `dl`.
(Of course, this can only be used in ROM `SECTION`s.)
If you have more than one "unit" per member, you will likely want a list as a single initializer; to achieve this, you can escape commas like shown above.

If an initializer provides less units than specified (such as `"TOAD"` above being 4 bytes instead of 6), trailing padding bytes will be inserted.

Having to remember the order of arguments is tedious and nondescript, though, so rgbds-structs took a hint from C99/C++20 and supports "designated initializers":

```asm
    dstruct NPC, Toad, .YPos=42, .XPos=69, .YBox=3, .XBox=2, .Name="TOAD", .MovementData=$DEAD\, $BEEF
    ; or, equivalent:
    dstruct NPC, Toad, .Name="TOAD", .YPos=42, .XPos=69, .MovementData=$DEAD\, $BEEF, .YBox=3, .XBox=2
```

When using designated initializers, their order does not matter, but they must all be defined once and exactly once.

#### Defining an array of structs

It's possible to copy-paste a few calls to `dstruct` to create an array, but `dstructs` automates the task.
Its first argument is the number of structs to define, and the next two are passed as-is to `dstruct`, except that a decimal index is appended to the struct name.
`dstructs` does not support data arguments; make manual calls to `dstruct` for that—you would have to pass all the data arguments individually anyway.

## Credits

Written by [ISSOtm](https://github.com/ISSOtm) and [contributors](https://github.com/ISSOtm/rgbds-structs/graphs/contributors).
