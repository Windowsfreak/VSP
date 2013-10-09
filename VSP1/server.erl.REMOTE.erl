-module(server).
-compile([export_all]).

loop(HBQ, DLQ, Clients, NextNnr) ->
	true. % TODO
	
queueInsert(Queue, Message) ->
	NewQueue = werkzeug:pushSL(Queue, Message),
	NewQueue.
	
queueCrop(Queue, MaxLength) when werkzeug:lengthSL(Queue) > MaxLength ->
	queueCrop(popSL(Queue), MaxLength);
queueCrop(Queue, MaxLength) ->
	Queue.
	
dlqInsert(DLQ, Message, MaxLength) ->
	queueCrop(queueInsert(DLQ, Message), MaxLength).
	

	
	
	
