//
// msgQueue.h
//

// Uncomment to enable debugging options,
//#define __DEBUG_MSG_QUEUE

#define queueMsg msgQueueDaemon.addMsg
#define addMsgQueueFilter msgQueueDaemon.addFilter

#define defaultFidget(msg, args...) \
	(msgQueueDaemon.addMsg(new MsgQueueMsg(msg, \
		args#ifempty#50# args#ifnempty#args#)))
#define fidgetBefore(msg, args...) \
	(msgQueueDaemon.addMsg(new MsgQueueMsg(msg, \
		args#ifempty#100# args#ifnempty#args#)))
#define fidgetAfter(msg, args...) \
	(msgQueueDaemon.addMsg(new MsgQueueMsg(msg, \
		args#ifempty#1# args#ifnempty#args#)))

#define fidget(msg, args...) \
	(msgQueueDaemon.addMsg(new MsgQueueMsg(msg args#ifnempty#, args#)))

#define fidgetDualSense(msg0, msg1, pri, args...) \
	(msgQueueDaemon.addMsg(new MsgQueueMsgSenseDual(msg0, msg1, pri, args)))
	
// For dependency checking, don't comment out.
#ifndef MSG_QUEUE_H
#define MSG_QUEUE_H
#endif // MSG_QUEUE_H
