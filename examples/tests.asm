
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
