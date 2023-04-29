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
	_tags = nil		// Message tags

	// Allow both properties to be set by the constructor
	construct(v, pri?) {
		msg = v;
		priority = ((pri != nil) ? pri : 0);
	}

	// Just print the message.
	output() { "<<msg>> "; }

	// Add a tag (a text literal) to this message.  Used for sorting
	// and filtering.
	addTag(v) {
		if(_tags == nil) _tags = new Vector();
		_tags.append(v);
	}

	// Returns boolean true if this message has the given tag, nil
	// otherwise.
	checkTag(v) {
		if(_tags == nil) return(nil);
		return(_tags.indexOf(v) != nil);
	}
;

// Class for messages that are only displayed when the source is
// in the player's sense context.
class MsgQueueMsgSense: MsgQueueMsg
	src = nil		// Source of the message
	sense = nil		// Sense to use to check context

	construct(v, pri, a, s?) {
		inherited(v, pri);
		src = ((a != nil) ? a : nil);
		sense = ((s != nil) ? s : sight);
	}

	// Returns boolean true if the given actor is in the same
	// sense context as the message source, nil otherwise.
	// If no actor is specified, uses gPlayerChar.
	checkSenseContext(actor?) {
		return((actor ? actor : gPlayerChar)
			.senseObj(sense, src).trans != opaque);
	}

	output() {
		// If we don't have a source, bail.
		if(src == nil)
			return;

		// Only display the message if the player is in the same
		// sense context as the message source.
		if(checkSenseContext())
			callWithSenseContext(src, sense, {: "<<msg>> " });
	}
;

// Class for messages that display one message when the source is in the
// player's sense context and a different message when the source is not
// in the player's sense context.
class MsgQueueMsgSenseDual: MsgQueueMsgSense
	msgOutOfContext = nil	// Message used when out of context

	construct(v0, v1, pri, a, s?) {
		inherited(v0, pri, a, s);
		msgOutOfContext = ((v1 != nil) ? v1 : nil);
	}

	output() {
		// We're the same as MsgQueueMsgSense.output() until the end.
		if(src == nil)
			return;

		if(checkSenseContext())
			callWithSenseContext(src, sense, {: "<<msg>> " });

		// If we've reached this point, the message source isn't
		// in the same sense context as the player.  So if we don't
		// have an out-of-context message, bail.
		if(msgOutOfContext == nil)
			return;

		// Just output the message.
		callWithSenseContext(nil, nil, {: "<<msgOutOfContext>> " });
	}
;

class MsgQueueMsgSensePOV: MsgQueueMsgSense
	msgParamSub() {
		local msgSrc;

		if((msgSrc = src) != nil)
			gMessageParams(msgSrc);

		return(msg);
	}

	output() {
		// If we don't have a source, bail.
		if(src == nil)
			return;

		// Only display the message if the player is in the same
		// sense context as the message source.
		if(checkSenseContext())
			callWithSenseContext(src, sense,
				{: "<<msgParamSub>> " });
	}
;
