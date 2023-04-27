#charset "us-ascii"
//
// msgQueueMsg.t
//
#include <adv3.h>
#include <en_us.h>

#include "msgQueue.h"

// Class for messages with specific priorities.
class MsgQueueMsg: object
	msg = nil		// Text literal of message
	priority = nil		// Message priority

	// Allow both properties to be set by the constructor
	construct(v, pri?) {
		msg = v;
		priority = ((pri != nil) ? pri : 0);
	}

	// Just print the message.
	output() { "<<msg>> "; }
;

// Class for messages that are only displayed when the source is
// in the player's sense context.
class MsgQueueMsgSense: MsgQueueMsg
	src = nil		// Source of the message
	sense = nil		// Sense to use to check context

	construct(v, pri?, a?, s?) {
		inherited(v, pri);
		src = ((a != nil) ? a : nil);
		sense = ((s != nil) ? s : nil);
	}

	output() {
		local s;

		// If we don't have a source, bail.
		if(src == nil)
			return;

		// If we have a sense defined, used it.  Otherwise use
		// sight.
		s = (sense ? sense : sight);

		// Only display the message if the player is in the same
		// sense context as the message source.
		if(gPlayerChar.senseObj(s, src).trans != opaque)
			callWithSenseContext(src, sense, {: "<<msg>> " });
	}
;

// Class for messages that display one message when the source is in the
// player's sense context and a different message when the source is not
// in the player's sense context.
class MsgQueueMsgSenseDual: MsgQueueMsgSense
	msgOutOfContext = nil	// Message used when out of context

	construct(v0, v1?, pri?, a?, s?) {
		inherited(v0, pri, a, s);
		msgOutOfContext = ((v1 != nil) ? v1 : nil);
	}

	output() {
		local s;

		// We're the same as MsgQueueMsgSense.output() until the end.
		if(src == nil)
			return;

		s = (sense ? sense : sight);

		if(gPlayerChar.senseObj(s, src).trans != opaque) {
			callWithSenseContext(src, sense, {: "<<msg>> " });
			return;
		}

		// If we've reached this point, the message source isn't
		// in the same sense context as the player.  So if we don't
		// have an out-of-context message, bail.
		if(msgOutOfContext == nil)
			return;

		// Just output the message.
		callWithSenseContext(nil, nil, {: "<<msgOutOfContext>> " });
	}
;
