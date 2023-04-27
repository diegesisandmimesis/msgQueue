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
	msg = nil		// Text literal of message, in context
	priority = nil		// Message priority

	// Allow both properties to be set by the constructor
	construct(v, pri?) {
		msg = v;
		priority = ((pri != nil) ? pri : 0);
	}

	output() { "<<msg>> "; }
;

class MsgQueueMsgSense: MsgQueueMsg
	src = nil		// Optional source of the message
	sense = nil		// Sense to use for context

	construct(v, pri?, a?, s?) {
		inherited(v, pri);
		src = ((a != nil) ? a : nil);
		sense = ((s != nil) ? s : nil);
	}

	output() {
		local s;

		s = (sense ? sense : sight);
		if(src == nil) {
		 	"<<msg>> ";
			return;
		}
		if(gPlayerChar.senseObj(s, src).trans != opaque)
			callWithSenseContext(src, sense, {: "<<msg>> " });
	}
;

class MsgQueueMsgSenseDual: MsgQueueMsgSense
	msgOutOfContext = nil	// Message when out of context

	construct(v0, v1?, pri?, a?, s?) {
		inherited(v0, pri, a, s);
		msgOutOfContext = ((v1 != nil) ? v1 : nil);
	}
	output() {
		local s;

		s = (sense ? sense : sight);
		if(src == nil) {
		 	"<<msg>> ";
			return;
		}
		if(gPlayerChar.senseObj(s, src).trans != opaque) {
			callWithSenseContext(src, sense, {: "<<msg>> " });
			return;
		}

		if(msgOutOfContext == nil)
			return;
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
