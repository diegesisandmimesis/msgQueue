#charset "us-ascii"
//
// filterTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the msgQueue library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f filterTest.t3m
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
		"This is a simple test game that demonstrates the features
		of the msgQueue library.
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
	invokeItem() {
		queueMsg(new MsgQueueMsgSenseDual(
			'Alice mutters <q>foo</q>.',
			'On the wind you hear someone mutter <q>foo</q>.',
			100, getActor(), sound));
	}
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
	invokeItem() {
		fidget('Non-Bob fidget 1.');

		queueMsg(new MsgQueueMsgSenseDual(
			'Bob says <q>bar</q>.',
			'Off in the distance you hear someone say <q>bar</q>.',
			75, getActor, sound));

		fidget('Non-Bob fidget 2.');
	}
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
	invokeItem() {
		queueMsg(new MsgQueueMsgSenseDual(
			'Carol casually mentions <q>baz</q>.',
			'You hear someone nearby mentioning <q>baz</q>.',
			50, getActor(), sound));
	}
;

// A filter that will remove any fidgets made by Bob.  For some reason.
bobFilter: MsgQueueFilter
	filter() {
		filterMessages(function(obj) {
			if(obj.src != bob) return;
			removeMessage(obj);
		});
	}
;

gameMain: GameMainDef
	initialPlayerChar = me
	newGame() {
		// Register the Bob filter.
		msgQueueDaemon.addFilter(bobFilter);
		runGame(true);
	}
;
