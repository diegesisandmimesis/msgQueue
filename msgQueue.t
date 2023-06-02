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

	_simpleFilters = perInstance(new Vector())

	// Initialize the daemon if it isn't already running.
	initDaemon() {
		if(_daemon != nil) return;
		_daemon = new Daemon(self, &runDaemon, 1);
	}

	// Add a filter.
	addFilter(obj) {
		if((obj == nil) || !obj.ofKind(MsgQueueFilter))
			return(nil);

		if(obj.ofKind(MsgQueueFilterSimple))
			_simpleFilters.append(obj);
		else
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
		
		return(m);
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
	// We do this instead of, for example, going through the message
	// list and calling filters on individual messages because we
	// might have filters that want to act on the entire queue.  E.g.,
	// combining messages.
	runFilters() {
		// Handle the "regular" filters.
		_filters.forEach(function(o) { o.filter(); });

		// Handle the "simple" filters.
		_queue.forEach(function(o) {
			_simpleFilters.forEach(function(f) {
				f.simpleFilter(o);
			});
		});
		_fifo.forEach(function(o) {
			_simpleFilters.forEach(function(f) {
				f.simpleFilter(o);
			});
		});
	}

	// Go through all messages, calling the passed callback for each
	// one.
	traverseMessages(cb) {
		if(cb == nil) return;
		_queue.forEach(function(o) { (cb)(o); });
		_fifo.forEach(function(o) { (cb)(o); });
	}

	// Go through all messages, returning a list of all the ones
	// for which the passed callback returns boolean true.
	searchMessages(cb) {
		local r;

		// Make sure we have a callback.
		if(cb == nil)
			return(nil);

		// Results vector.  We use the queue length as a guesstimate
		// of the results vector length.
		r = new Vector(_queue.length);

		// Check the queue.
		_queue.forEach(function(o) {
			if((cb)(o) == true)
				r.append(o);
		});

		// Check the FIFO.
		_fifo.forEach(function(o) {
			if((cb)(o) == true)
				r.append(o);
		});

		// Return the results.
		return(r);
	}

	// Instead of removing the message from the queue, just mark it
	// inactive.
	// This saves us having to shuffle the message vector during
	// filtering, allows filters to potentially override each other
	// (although *maybe* that's a misfeature), and the entire queue
	// gets flushed every turn anyway.
	removeMessage(obj) { obj.deactivate(); }

	_checkSenseContext(msg) {
		if((msg == nil) || (msg.sense == nil)) return(-1);
		return(msg.checkSenseContext());
	}

	// Summarize messages, maybe.  Indended to be kinda-sorta like
	// CommandTranscript.summarizeAction().
	// Args are both functions.  Usage is:
	//	cond	is called with a message as the argument, and
	//		the message is included in the summary list
	//		if cond() returns boolean true.
	//	report	is called with the summary list as the first
	//		argument and a boolean indicating whether all
	//		the messages are "in" the player's sense context
	//		or out of it
	summarizeMessages(cond, report) {
		local ctx, i, r;

		// Get a list of all the messages for which the first
		// callback returns boolean true.
		r = searchMessages(cond);

		// If we have less than two messages, nothing to summarize.
		if(r.length < 2)
			return(nil);

		// Get the sense context flag of the first message.  This
		// will be nil (player not in the same sense context as
		// the source of the message), true (player is in the same
		// sense context as the source of the message), or -1 (the
		// message doesn't check sense context).
		ctx = _checkSenseContext(r[1]);

		// Now make sure all the other messages in our list
		// have the same flag.
		for(i = 2; i <= r.length; i++) {
			if(r[i].checkSenseContext() != ctx)
				return(nil);
		}

		// If we made it this far, we're going to combine the messages
		// so we go through our list and deactivate the original
		// messages.
		r.forEach(function(o) { o.deactivate(); });

		// Now call the report callback with the list of matching
		// messages and the context flag.
		report(r, ctx);

		return(true);
	}
;

// Default global message queue daemon.
// This is just an instance of our abstract message queue daemon class.
msgQueueDaemon: MsgQueueDaemon, InitObject
	execute() {
		forEachInstance(MsgQueueFilter, function(o) {
			if(o.autoAdd != true)
				return;
			addFilter(o);
		});
	}
;

// Resolve a message text as if it was passed to a reporting macro, e.g.
// defaultReport().
//
// 	local txt = resolveMsg(&mustBeVisibleMsg, pebble);
//
// ...will save to txt whatever would be output if you used
//
//	defaultReport(&mustBeVisibleMsg, pebble);
//
// instead.  This handles actor-specific action message objects, setting
// the object and direct object for message parameter substitution, and so
// on.
resolveMsg(msg, [params]) {
	return(new MessageResult(msg, params...).messageText_);
}
