#charset "us-ascii"
//
// combineTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the msgQueue library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f combineTest.t3m
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

class AliceCarolFidget: MsgQueueMsgSenseDualPOV
	combine = nil
;

class AliceCarolPerson: Person
	dualFidgetClass = AliceCarolFidget
;

startRoom: Room 'Void'
        "This is a featureless void.  Alice's room is to the north,
		Bob's is to the south, and Carol's is to the east."
	north = aliceRoom
	south = bobRoom
	east = carolRoom
;
+ me: Person;

aliceRoom: Room 'A Different Void'
	"This is also a featureless void, but a different one."
	south = startRoom
;
+ alice: AliceCarolPerson 'alice' 'Alice'
	"She looks like the first person you'd turn to in a problem."
	isHer = true
	isProperName = true
;
++ aliceAgenda: AgendaItem
	initiallyActive = true
	isReady = true
	invokeItem() {
		local obj;

		// Every other turn we output a message that can be
		// combined.  The combine flag is just a one-off property
		// only used by out bespoke filter.
		if(!(libGlobal.totalTurns % 2)) {
			obj = selfDualFidget('Alice fidgets combinatorially.',
				'Alice fidgets combinatorially in the
				distance.');
			obj.combine = true;
		} else {
			selfDualFidget('Alice fidgets locally.',
				'Alice fidgets in the distance.');
		}
	}
;

bobRoom: Room 'Another Different Void'
	"This is also a featureless void, but a southern one."
	north = startRoom
;
+ bob: Person 'bob' 'Bob'
	"He looks like a Robert, only shorter. "
	isProperName = true
;
++ bobAgenda: AgendaItem
	initiallyActive = true
	isReady = true
	invokeItem() {
		// Sandwich the "Bob" fidget between a couple "anonymous"
		// fidgets.  This is just to verify that the filtering
		// process doesn't drop/shuffle/whatever messages that
		// don't match the filter.
		fidget('Non-Bob fidget 1.', 76);

		selfDualFidget('Bob fidgets locally.',
			'Bob fidgets in the distance.', 75);
		selfDualFidget('Bob fidgets redudantly.',
			'Bob distantly fidgets redundantly.', 74);

		fidget('Non-Bob fidget 2.', 74);
	}
;

carolRoom: Room 'One More Different Void'
	"This is also a featureless void, but an eastern one."
	west = startRoom
;
+ carol: AliceCarolPerson 'carol' 'Carol'
	"A nice person, but kinda a third wheel. "
	isHer = true
	isProperName = true
;
++ carolAgenda: AgendaItem
	initiallyActive = true
	isReady = true
	invokeItem() {
		local obj;

		// Every third round we output a message that can be
		// combined.
		if(!(libGlobal.totalTurns % 3)) {
			obj = selfDualFidget('Carol fidgets combinatorially.',
				'Carol fidgets combinatorially in the
				distance.', 50);
			obj.combine = true;
		} else {
			selfDualFidget('Carol fidgets locally.',
				'Carol fidgets in the distance.', 50);
		}
	}
;

// A filter that will remove any fidgets made by Bob.  For some reason.
bobFilter: MsgQueueFilter
	filter() {
		filterMessages(function(obj) {
			if(obj.src != bob) return;
			obj.deactivate();
		});
	}
;

// A filter that combines Alice and Carol's messages when possible.
// Alice and Carol fidget every turn, but Alice's messages are only
// combine-able every other turn and Carol's only every third turn, and
// so the filter only applies every 6th turn.
aliceCarolFilter: MsgQueueFilter
	filter() {
		local ctx, i, r, v;

		// Get all of the combinable messages as an array.
		// The combine flag is just a one-off property we
		// use to differentiate between types of messages.
		r = searchMessages(function(obj) {
			return(obj.ofKind(AliceCarolFidget)
				&& (obj.combine == true));
		});

		// If we don't have at least two messages, we can't
		// combine anything:  bail.
		if(r.length < 2)
			return;

		// Now we make sure all the messages are EITHER all
		// "in" the same sense context as the player, or all of
		// are "out" of the player's sense context.  In our demo
		// we'll only pass this check when the player is not in
		// the same room with either Alice or Carol, meaning they're
		// both outputting "out of context" messages.
		// This is just so we don't combine "Alice fidgets" and
		// "Carol fidgets in the distance" and so on.
		// We start out by arbitrarily remembering the first sense
		// context flag and then verify that every other messages
		// in our list matches it, immediately returning if any
		// don't match.
		ctx = r[1].checkSenseContext();
		for(i = 2; i <= r.length; i++)
			if(r[i].checkSenseContext() != ctx)
				return;
		
		// Now we make a list of the names of the actors whose
		// messages we're combining this turn.
		// While we're traversing our list of matches anyway, we
		// deactivate each message, because if we've made it
		// this far we're going to combine them into a single
		// message.
		v = new Vector(r.length);
		r.forEach(function(o) {
			v.append(o.src.theName);
			o.deactivate();
		});

		// And finally we queue a new message combining all the
		// actor names.
		// In our demo we'll only ever use the second case (because
		// Alice and Carol are in different rooms, so if the player
		// is in context for one they're out of context for the 
		// other, so we'll never combine those messages.
		if(ctx)
			fidget('<<stringLister.makeSimpleList(v)>> fidget
				in context.');
		else
			fidget('<<stringLister.makeSimpleList(v)>> fidget
				out of context.');

	}
;

gameMain: GameMainDef
	initialPlayerChar = me
	newGame() {
		// Register the Bob filter.
		msgQueueDaemon.addFilter(bobFilter);

		// Register the Alice and Carol filter.
		msgQueueDaemon.addFilter(aliceCarolFilter);

		runGame(true);
	}
;
