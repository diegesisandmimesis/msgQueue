#charset "us-ascii"
//
// msgQueue.t
//
//	A TADS3 module that implements a simple message queue with
//	explicit message priorities.
//
//	This is intended to work somewhat like the command report system
//	in adv3, only not related to action processing.  This is to make it
//	easier to re-write and consolodate messages involving things like
//	NPC fidgets/barks and environmental effects.  This sort of thing
//	could theoretically be done via output filtering, but this message
//	queue system makes it easier to filter by message type, message
//	source, and so on.
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

// Abstract class implementing an output queue daemon for handling messages
// with explicit priorities.  We also implement a non-sorted FIFO for messages
// without priorities.  Done mostly to make the semantics easier (can log
// messages the same way whether or not they need to be sorted).
class MsgQueueDaemon: object
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

	// Add a filter.
	addFilter(obj) {
		if((obj == nil) || !obj.ofKind(MsgQueueFilter))
			return(nil);

		_filters.append(obj);

		return(true);
	}

	// Add a message to the queue (and/or FIFO).
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
	// This is *probably* superfluous, because we always just call
	// the output method on the message itself.  But we break this
	// out into its own method on the off-chance that we might
	// want to create other message queue types, and so structure
	// things this way so that runDaemon() is as generic as possible.
	handleMsg(v) {
		if((v == nil) || !v.ofKind(MsgQueueMsg)) return;
		v.output();
	}

	// Called by T3/adv3 every turn.
	// This is where we flush the FIFO and sort and flush the message
	// queue.
	runDaemon() {
		runFilters();

		// The messages of the FIFO are output in the order they were
		// added.
		if(_fifo != nil) {
			_fifo.forEach(function(o) { handleMsg(o); });
		}

		// Now we sort the queue by the numerical priority, and then
		// go through the sorted list in order and output everything.
		if(_queue != nil)
			_queue.sort(true, { a, b: a.priority - b.priority })
				.forEach(function(o) { handleMsg(o); });

		// Reset the FIFO and message queue.
		_queue.setLength(0);
		_fifo.setLength(0);
	}

	// Call all the registered filters.
	runFilters() {
		_filters.forEach(function(o) { o.filter(); });
	}
;

// Default global message queue daemon.
// This is just an instance of our abstract message queue daemon class.
msgQueueDaemon: MsgQueueDaemon;
