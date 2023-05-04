#charset "us-ascii"
//
// msgQueueActor.t
//
#include <adv3.h>
#include <en_us.h>

#include "msgQueue.h"

modify Actor
	fidgetClass = nil
	dualFidgetClass = nil

	selfDualFidget(msg0, msg1, pri?, s?) {
		local obj;

		if(dualFidgetClass != nil) {
			obj = dualFidgetClass.createInstance(msg0, msg1,
				pri, self, s);
			//obj = msgQueueDaemon.addMsg(obj);
//aioSay('<<name>> in obj = <<toString(obj)>>\n ');
			return(msgQueueDaemon.addMsg(obj));
		}
		return(povDualFidget(msg0, msg1, pri, self, s));
	}

	selfFidget(msg, pri?, s?) {
		local obj;

		if(fidgetClass != nil) {
			obj = fidgetClass.createInstance(msg, pri, self);
			// Slight kludge;  allows us to work with classes
			// without having to figure out if their constructor
			// has an argument for the sense.
			if(s != nil)
				obj.sense = s;
			return(msgQueueDaemon.addMsg(obj));
		}
		return(povFidget(msg, pri, self));
	}
;

modify AgendaItem
	selfFidget(msg, pri?) { return(getActor().selfFidget(msg, pri)); }
	selfDualFidget(msg0, msg1, pri?) {
		return(getActor().selfDualFidget(msg0, msg1, pri));
	}
;
