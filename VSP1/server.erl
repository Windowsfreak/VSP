-module(server).
-compile([export_all]).

{ok, ServerCfg} = file:consult("server.cfg"),
% {ok, MaxLength} = werkzeug:get_config_value(maxLength, ServerCfg),

loop(HBQ, DLQ, Clients, NextNnr, ServerCfg) ->
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