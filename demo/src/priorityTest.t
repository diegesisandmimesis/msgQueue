#charset "us-ascii"
//
// priorityTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the msgQueue library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f priorityTest.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>

#include "msgQueue.h"

versionInfo:    GameID
        name = 'msgQueue Library Demo Game'
        byline = 'Diegesis & Mimesis'
        desc = 'Demo game for the msgQueue library. '
        version = '1.0'
        IFID = '12345'
	showAbout() {
		"Identical to the demo in sample.t, but with explicit message
		priorities given.  Order should be Carol, Bob, Alice.
		<.p>
		Consult the README.txt document distributed with the library
		source for a quick summary of how to use the library in your
		own games.
		<.p>
		The library source is also extensively commented in a way
		intended to make it as readable as possible. ";
	}
;

startRoom:      Room 'Void'
        "This is a featureless void.  Alice's room is to the north,
		Bob's is to the south, and Carol's is to the east."
	north = aliceRoom
	south = bobRoom
	east = carolRoom
;
+ me:     Person;

aliceRoom:	Room 'A Different Void'
	"This is also a featureless void, but a different one."
	south = startRoom
;
+ alice:	Person 'alice' 'Alice'
	"She looks like the first person you'd turn to in a problem."
	isHer = true
	isProperName = true
;
++ aliceAgenda: AgendaItem
	initiallyActive = true
	isReady = true
	invokeItem() { fidget('Alice fidgets.', 1); }
;

bobRoom:	Room 'Another Different Void'
	"This is also a featureless void, but a southern one."
	north = startRoom
;
+ bob:	Person 'bob' 'Bob'
	"He looks like a Robert, only shorter. "
	isProperName = true
;
++ bobAgenda: AgendaItem
	initiallyActive = true
	isReady = true
	invokeItem() { fidget('Bob fidgets.', 50); }
;

carolRoom:	Room 'One More Different Void'
	"This is also a featureless void, but an eastern one."
	west = startRoom
;
+ carol:	Person 'carol' 'Carol'
	"A nice person, but kinda a third wheel. "
	isHer = true
	isProperName = true
;
++ carolAgenda: AgendaItem
	initiallyActive = true
	isReady = true
	invokeItem() { fidget('Carold fidgets.', 100); }
;

gameMain: GameMainDef initialPlayerChar = me;
