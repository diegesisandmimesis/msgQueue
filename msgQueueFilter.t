#charset "us-ascii"
//
// msgQueueFilter.t
//
#include <adv3.h>
#include <en_us.h>

#include "msgQueue.h"

// Class for message queue filters.
class MsgQueueFilter: object
	// If true, filter will be automatically added to the main
	// message queue daemon at preinit time.
	autoAdd = nil

	// Stub method to be overwritten by actual filters.
	// The argument is the calling message queue.
	filter(q?) {}
;

// Class for filters that ONLY check single messages.  Instead of
// having their filter() method called, the simpleFilter() method will
// be called with each message in the queue.
class MsgQueueFilterSimple: MsgQueueFilter
	simpleFilter(obj) {}
;
