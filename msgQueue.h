//
// msgQueue.h
//

// Uncomment to enable debugging options,
//#define __DEBUG_MSG_QUEUE

#define queueMsg msgQueueDaemon.addMsg
#define addMsgQueueFilter msgQueueDaemon.addFilter

#define fidget(msg, args...) \
	(msgQueueDaemon.addMsg(new MsgQueueMsg(msg, args)))

#define fidgetSense(msg, args...) \
	(msgQueueDaemon.addMsg(new MsgQueueMsgSense(msg, args)))

#define fidgetDualSense(msg0, msg1, args...) \
	(msgQueueDaemon.addMsg( \
		new MsgQueueMsgSenseDual(msg0, msg1, args)))

#define povFidget(msg, args...) \
	(msgQueueDaemon.addMsg(new MsgQueueMsgSensePOV(msg, args)))

#define povDualFidget(msg0, msg1, args...) \
	(msgQueueDaemon.addMsg(new MsgQueueMsgSenseDualPOV(msg0, msg1, args)))

#define filterMessages(cb) \
	(msgQueueDaemon.traverseMessages(cb))

#define searchMessages(cb) \
	(msgQueueDaemon.searchMessages(cb))

#define removeMessage(obj) \
	(msgQueueDaemon.removeMessage(obj))

#define summarizeMessages(cond, report) \
	(msgQueueDaemon.summarizeMessages(cond, report))
	
// For dependency checking, don't comment out.
#ifndef MSG_QUEUE_H
#define MSG_QUEUE_H
#endif // MSG_QUEUE_H
