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
	_active = true		// Should message be output?

	// Allow both properties to be set by the constructor
	construct(v, pri?) {
		msg = v;
		priority = ((pri != nil) ? pri : 0);
	}

	// Just print the message.
	output() { if(isActive()) "<<msg>> "; }

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

	// Methods for marking and checking the message's status.
	// We do this (instead of actually removing messages from the
	// queue) to avoid having to shuffle the queue, possibly multiple
	// times, when filtering.  All messages get flushed at the end
	// of every turn anyway, so there's we don't have to fret over
	// housekeeping too much.
	activate() { _active = true; }
	deactivate() { _active = nil; }
	isActive() { return(_active == true); }
;

// Class for messages that are only displayed when the source is
// in the player's sense context.
class MsgQueueMsgSense: MsgQueueMsg
	src = nil		// Source of the message
	sense = nil		// Sense to use to check context

	_senseCheck = -1	// Used to cache sense check result
	_senseCheckActor = nil	// Actor used for sense check

	construct(v, pri, a, s?) {
		inherited(v, pri);
		src = ((a != nil) ? a : nil);
		sense = ((s != nil) ? s : sight);
	}

	// Returns boolean true if the given actor is in the same
	// sense context as the message source, nil otherwise.
	// If no actor is specified, uses gPlayerChar.
	// We cache the result because filters might want to do multiple
	// sense checks and since messages are ephemeral (we go away at
	// the end of the turn one way or another) the results of the
	// check shouldn't vary unless something very weird is going on.
	checkSenseContext(actor?) {
		actor = (actor ? actor : gPlayerChar);
		if((_senseCheck != -1) && (_senseCheckActor == actor))
			return(_senseCheck);
		_senseCheckActor = actor;
		return(_senseCheck =
			(actor.senseObj(sense, src).trans != opaque));
	}

	output() {
		// Only output if we're marked "active".
		if(!isActive())
			return;

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
		// Only output if we're marked "active".
		if(!isActive())
			return;

		// We're the same as MsgQueueMsgSense.output() until the end.
		if(src == nil)
			return;

		if(checkSenseContext()) {
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

class MsgQueuePOV: object
	msgParamSub(m?) {
		local msgSrc;

		if(m == nil)
			m = msg;

		if((msgSrc = src) != nil)
			gMessageParams(msgSrc);

		return(m);
	}
;

class MsgQueueMsgSensePOV: MsgQueueMsgSense, MsgQueuePOV

	output() {
		// Only output if we're marked "active".
		if(!isActive())
			return;

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

class MsgQueueMsgSenseDualPOV: MsgQueueMsgSenseDual, MsgQueuePOV
	output() {
		if(!isActive())
			return;

		if(src == nil)
			return;

		if(checkSenseContext()) {
			callWithSenseContext(src, sense,
				{: "<<msgParamSub>> " });
			return;
		}

		// If we've reached this point, the message source isn't
		// in the same sense context as the player.  So if we don't
		// have an out-of-context message, bail.
		if(msgOutOfContext == nil)
			return;

		// Just output the message.
		callWithSenseContext(nil, nil,
			{: "<<msgParamSub(msgOutOfContext)>> " });
	}
;
