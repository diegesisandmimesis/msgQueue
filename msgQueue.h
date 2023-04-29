//
// msgQueue.h
//

// Uncomment to enable debugging options,
//#define __DEBUG_MSG_QUEUE

#define queueMsg msgQueueDaemon.addMsg
#define addMsgQueueFilter msgQueueDaemon.addFilter

#define fidget(msg, args...) \
	return(msgQueueDaemon.addMsg( \
		new MsgQueueMsg(msg args#ifnempty#, args#)))

#define fidgetSense(msg, pri, args...) \
	return(msgQueueDaemon.addMsg(new MsgQueueMsgSense(msg, pri, args)))

#define fidgetDualSense(msg0, msg1, pri, args...) \
	return(msgQueueDaemon.addMsg( \
		new MsgQueueMsgSenseDual(msg0, msg1, pri, args)))

#define povFidget(msg, args...) \
	return(msgQueueDaemon.addMsg(new MsgQueueMsgSensePOV(msg, args)))
	
// For dependency checking, don't comment out.
#ifndef MSG_QUEUE_H
#define MSG_QUEUE_H
#endif // MSG_QUEUE_H
