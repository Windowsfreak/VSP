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
	
hbqInsert(HBQ, Message, DLQ, MaxLength, DLQLength) ->
	{Nnr, _Msg} = Message,
	MaxDLQ = werkzeug:maxNrSL(DLQ),
	if Nnr > MaxDLQ ->
		NewHBQ = queueInsert(HBQ,Message),
		hbqClean(NewHBQ, DLQ, MaxLength, DLQLength);
	true ->
		[HBQ,DLQ]
	end.
	
hbqClean(HBQ, DLQ, MaxLength, DLQLength) ->
	[NewHBQ, NewDLQ] = hbqCrop(HBQ, DLQ, DLQLength),
	Length = werkzeug:lengthSL(NewHBQ),
	if Length > MaxLength ->
		MinHBQ = werkzeug:minNrSL(NewHBQ),
		hbqClean(NewHBQ, dlqInsert(NewDLQ, {MinHBQ - 1, "Fehlernachricht für eine Lücke"}, DLQLength), MaxLength, DLQLength);
	true ->
		[NewHBQ, NewDLQ]
	end.
	
hbqCrop(HBQ, DLQ, DLQLength) ->
	MinHBQ = werkzeug:minNrSL(HBQ),
	MaxDLQ = werkzeug:maxNrSL(DLQ),
	if MaxDLQ + 1 == MinHBQ ->
		Elem = werkzeug:findSL(HBQ, MinHBQ),
		hbqCrop(werkzeug:popSL(HBQ), dlqInsert(DLQ, Elem, DLQLength), DLQLength);
	true -> 
		[HBQ, DLQ]
	end.
		
	
	
	
	
	
	
	