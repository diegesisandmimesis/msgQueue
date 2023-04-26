#charset "us-ascii"
//
// msgQueue.t
//
//	A module implementing a very simple message queue with explicit message
//	priorities.
//
//	Usage:
//
//		msgQueue(msg0, msg1, actor, sense, priorty);
//
//	...where...
//
//		msg0 is the text literal to output if the emitting actor
//			(if given) is in the same sense context as the player.
//			if no actor is given, then this message will be
//			output regardless of context.
//		msg1 is the text literal to output if the emitting actor
//			is NOT in the same sense context as the player.  if
//			no actor is given, this will never be output.
//		actor is the actor emitting the message, if any.
//		sense is an optional sense to use to evaluate context,
//			defaulting to sight if none is given.
//		priority is an optional numeric priority, with higher priority
//			messages output before lower priority messages.  if no
//			priority is given, messages are output in the order
//			received.
//
//
//		// alice and bob are actor instances
//		methodName() {
//			// We queue our messages in reverse order entirely
//			// to illustrate how message priority works.
//			msgQueue('Bob yelps in pain.', 'You hear
//				Bob yelp in pain.', bob, sound, 75);
//			msgQueue('Alice yells <q>Zorch!</a> as flames
//				billow from her fingertips.', 'Off in the
//				distance you hear Alice yelling.', alice,
//				sound, 100);
//		}
//
//	In this example if the player is in the same room as Alice and Bob
//	they'll see:
//
//		Alice yells "Zorch!" as flams billow from her fingertips.
//		Bob yelps in pain.
//
//	And if they're not in the same room they'll get:
//
//		Off in the distance you hear Alice yelling.  You hear Bob
//		yelp in pain.
//
//	In the example everything happens in a single function, but it will
//	work with any actors/daemons/whatever that act/fire in a given turn.
//
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

modify Actor
	// Simple fidget, only ever emits anything if the player is
	// in the given sense context.
	fidget(v0, sense?) {
		callWithSenseContext(self, (sense ? sense : sight),
			{: "<<v0>> " });
	}

	// Generalized fidget method for actors.
	// Arguments are the message to show the player if the fidgeting
	// actor is in the same sense context as them, the message to show
	// if they AREN'T in the same context, and the sense to use
	// to evaluate the context (using sight if none is given).
	fidgetNearAndFar(v0, v1, sense?) {
		if(!sense)
			sense = sight;

		if(gPlayerChar.senseObj(sense, self).trans != opaque)
			callWithSenseContext(self, sense, {: "<<v0>> " });
		else
			callWithSenseContext(nil, nil, {: "<<v1>> "});
	}
;


// Class for messages with specific priorities.
class MsgQueueMsg: object
	msg0 = nil		// Text literal of message, in context
	msg1 = nil		// Text, out of context
	actor = nil		// Optional source of the message
	priority = nil		// Message priority
	sense = nil		// Sense to use for context

	// Allow both properties to be set by the constructor
	construct(v0, v1, a?, s?, pri?) {
		msg0 = v0;
		msg1 = v1;
		actor = ((a != nil) ? a : nil);
		sense = ((s != nil) ? s : nil);
		priority = ((pri != nil) ? pri : 0);
	}
;

// Simple output queue daemon for handling messages with explicit priorities.
// We also implement a non-sorted FIFO for messages without priorities.  Done
// mostly to make the semantics easier (can log messages the same way whether
// or not they need to be sorted).
msgQueueDaemon: object
	_daemon = nil		// T3 Daemon that gets called by the scheduler
	_queue = nil		// Queue for sortable messages
	_fifo = nil		// FIFO for messages without priorities

	// Initialize the daemon if it isn't already running.
	initDaemon() {
		if(_daemon) return;
		_daemon = new Daemon(self, &runDaemon, 1);
	}

	// Main entry point for external callers.  Args are the message itself
	// (a text literal) and the priority, if any, of the message.
	output(v0, v1, a?, s?, pri?) {
		local m;

		if(!_daemon)
			initDaemon();

		// Sanity check our environment
		if(_queue == nil)
			_queue = new Vector();
		if(_fifo == nil)
			_fifo = new Vector();
		
		// If we haven't been given a priority, log to the FIFO,
		// otherwise log to the queue.
		m = new MsgQueueMsg(v0, v1, a, s, pri);
		if(pri == nil)
			_fifo.append(m);
		else
			_queue.append(m);
	}

	// Output a single message.
	// If an actor is given, then we display the message as a fidget
	// by that actor.  If we don't have an actor, then we just output
	// the message.
	_output(v) {
		if((v == nil) || !v.ofKind(MsgQueueMsg)) return;
		if(v.actor)
			v.actor.fidgetNearAndFar(v.msg0, v.msg1, v.sense);
		else
			"<<v.msg0>> ";
	}

	// Called by T3/adv3 every turn.
	// This is where we flush the FIFO and sort and flush the message
	// queue.
	runDaemon() {
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
;
