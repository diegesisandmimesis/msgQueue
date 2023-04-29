#charset "us-ascii"
//
// msgQueueActor.t
//
#include <adv3.h>
#include <en_us.h>

#include "msgQueue.h"

modify Actor
	selfFidget(msg, pri?) { povFidget(msg, pri, self); }
;

modify AgendaItem
	selfFidget(msg, pri?) { getActor().selfFidget(msg, pri); }
;
