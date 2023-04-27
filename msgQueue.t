#charset "us-ascii"
//
// msgQueue.t
//
#include <adv3.h>
#include <en_us.h>

// Module ID for the library
msgQueueModuleID: ModuleID {
        name = 'Absent Output Library'
        byline = 'Diegesis & Mimesis'
        version = '1.0'
        listingOrder = 99
}

modify Thing
	// Generalized fidget method.
	// Arguments are the message to show the player if the fidgeting
	// thing is in the same sense context as them, the message to show
	// if they AREN'T in the same context, and the sense to use
	// to evaluate the context (using sight if none is given).
	fidgetWithSenseContext(v0, v1, sense?) {
		if(!sense)
			sense = sight;

		if(gPlayerChar.senseObj(sense, self).trans != opaque)
			callWithSenseContext(self, sense, {: "<<v0>> " });
		else
			callWithSenseContext(nil, nil, {: "<<v1>> "});
	}

	handleQueuedMessage(msg) {
		if((msg == nil) || !msg.ofKind(MsgQueueMsg))
			return(nil);
		return(true);
	}
;


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

// Class for message queue filters.
class MsgQueueFilter: object
	filter() {}
;

// Simple output queue daemon for handling messages with explicit priorities.
// We also implement a non-sorted FIFO for messages without priorities.  Done
// mostly to make the semantics easier (can log messages the same way whether
// or not they need to be sorted).
msgQueueDaemon: object
	// T3 Daemon that gets called by the scheduler
	_daemon = nil

	// Queue for sortable messages
	_queue = perInstance(new Vector())

	// FIFO for messages without priorities
	_fifo = perInstance(new Vector())

	// Registered filters
	_filters = perInstance(new Vector())

	// Initialize the daemon if it isn't already running.
	initDaemon() {
		if(_daemon != nil) return;
		_daemon = new Daemon(self, &runDaemon, 1);
	}

	addFilter(obj) {
		if((obj == nil) || !obj.ofKind(MsgQueueFilter))
			return(nil);
		_filters.append(obj);
		return(true);
	}

	addMsg(m) {
		if((m == nil) || !m.ofKind(MsgQueueMsg))
			return(nil);

		if(_daemon == nil)
			initDaemon();

		// If we haven't been given a priority, log to the FIFO,
		// otherwise log to the queue.
		if(m.priority == nil)
			_fifo.append(m);
		else
			_queue.append(m);
		
		return(true);
	}

	// Output a single message.
	// If an actor is given, then we display the message as a fidget
	// by that actor.  If we don't have an actor, then we just output
	// the message.
	_output(v) {
		if((v == nil) || !v.ofKind(MsgQueueMsg)) return;
		v.output();
/*
		if(v.src)
			v.src.handleQueuedMsg(v);
			//v.src.fidgetWithSenseContext(v.msg0, v.msg1, v.sense);
		else
			"<<v.msg>> ";
*/
	}

	// Called by T3/adv3 every turn.
	// This is where we flush the FIFO and sort and flush the message
	// queue.
	runDaemon() {
		runFilters();

		// The messages of the FIFO are output in the order they were
		// added.
		if(_fifo != nil) {
			_fifo.forEach(function(o) { _output(o); });
		}

		// Now we sort the queue by the numerical priority, and then
		// go through the sorted list in order and output everything.
		if(_queue != nil)
			_queue.sort(true, { a, b: a.priority - b.priority })
				.forEach(function(o) { _output(o); });

		// Reset the FIFO and message queue.
		_queue.setLength(0);
		_fifo.setLength(0);
	}

	runFilters() {
		_filters.forEach(function(o) { o.filter(); });
	}
;
