-module(server).
-compile([export_all]).


start() -> spawn(server, loop, []).

loop() ->
	{ok, ServerCfg} = file:consult("server.cfg"),
	%{ok, MaxLength} = werkzeug:get_config_value(maxLength, ServerCfg),
	loop(0,0,0,0,0). 
loop(HBQ, DLQ, Clients, NextNnr, ServerCfg) ->
	receive
		{getmsgid, ClientPID} -> 
			ClientPID ! {nnr, NextNnr},
			loop(HBQ, DLQ, Clients, NextNnr + 1, ServerCfg)
	end.

	
queueInsert(Queue, Message) ->
	NewQueue = werkzeug:pushSL(Queue, Message),
	NewQueue.
	
	
queueCrop(Queue, MaxLength) ->
	Length = werkzeug:lengthSL(Queue),
	if Length > MaxLength ->
		queueCrop(werkzeug:popSL(Queue), MaxLength);
	true -> 
		Queue
	end.

	
dlqInsert(DLQ, Message, MaxLength) ->
	queueCrop(queueInsert(DLQ, Message), MaxLength).