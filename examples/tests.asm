
; This file isn't particularly meant to contain examples,
; but everything here is tested to work fine.
; Use it as inspiration if you want.

INCLUDE "../structs.asm"


SECTION "Stats", ROM0

	struct Stats
	bytes 8, FirstName
	bytes 8, LastName
	bytes 1, HP
	bytes 1, MaxHP
	end_struct

	dstruct Stats, _PartyMember, "foo", "bar", 100, 100
	dstruct Stats, _PartyMember2, .FirstName="foo", .LastName="bar", .HP=100, .MaxHP=100
	dstruct Stats, _PartyMember3, .HP=100, .LastName="bar", .MaxHP=100, .FirstName="foo"


	struct Multi
	bytes 2, test
	end_struct

	dstruct Multi, Anon, 1\, 2
	dstruct Multi, Named, .test=1\, 2

	struct Extended
	bytes 27, FirstField
	extends Stats
	extends Stats, Player
	end_struct

	dstruct Extended, _MyExtendedStruct
	dstruct Extended, _MyExtendedStruct2, "debug test", "foo", "bar", 100, 100, "foo", "bar", 100, 100
	dstruct Extended, _MyExtendedStruct3, .FirstField="debug test", .HP=100, .LastName="bar", .MaxHP=100, .FirstName="foo", .Player_FirstName="foo", .Player_LastName="bar", .Player_HP=100, .Player_MaxHP=100

	ASSERT Extended_FirstName == 27
	ASSERT Extended_Player_FirstName == 27 + sizeof_Stats

    struct Actor
        longs 0, Position
        words 1, YPos
        words 1, XPos
        alias Money
        words 1, Target
    end_struct

    ASSERT Actor_Position == Actor_YPos
    ASSERT Actor_Money == Actor_Target
    ASSERT sizeof_Actor == 6

    dstruct Actor, _Test
    dstruct Actor, _Test2, 1, 2, 3
    dstruct Actor, _Test3, .Target=3, .XPos=2, .YPos=1

    ASSERT _Test == _Test_Position
    ASSERT _Test_Position == _Test_YPos
