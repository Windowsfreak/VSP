-module(server).
-compile([export_all]).


start() ->
	Pid = spawn(server, loop, []),
	register(server, Pid),
	Pid.

loop() ->
	{ok, ServerCfg} = file:consult("server.cfg"),
	{ok,Timer} = timer:send_after(86400000,stop), % do not stop before first client gets his message
	log("server.log", "~s-~p-T3 S-Start: ~s~n", [pcName(), self(), werkzeug:timeMilliSecond()]),
	loop([], [], [], 1, Timer, ServerCfg).

loop(HBQ, DLQ, ClientList, NextNnr, Timer, ServerCfg) ->
	receive
		stop ->
			log("server.log", "~s-~p-T3 S-Stop: ~s~n", [pcName(), self(), werkzeug:timeMilliSecond()]);
		{getmsgid, ClientPID} ->
			ClientPID ! {nid, NextNnr},
			log("server.log", "getMsgId by ~p - ~p~n", [ClientPID, NextNnr]),
			loop(HBQ, DLQ, ClientList, NextNnr + 1, Timer, ServerCfg);
		{dropmessage, {Message, Number}} ->
			{ok, MaxDLQLength} = werkzeug:get_config_value(maxDLQLength, ServerCfg),
			MaxHBQLength = MaxDLQLength / 2,
			[NewHBQ, NewDLQ] = hbqInsert(HBQ, {Number, Message}, DLQ, MaxHBQLength, MaxDLQLength),
			log("server.log", "dropMessage - ~p - ~s~n", [Number, Message]),
			loop(NewHBQ, NewDLQ, ClientList, NextNnr, Timer, ServerCfg);
		{getmessages, ClientPID} ->
			{ok, Timeout} = werkzeug:get_config_value(timeout, ServerCfg),
			NewTimer = werkzeug:reset_timer(Timer, Timeout, stop),
			{ok, MaxClientAge} = werkzeug:get_config_value(maxClientAge, ServerCfg),
			{LastNnr, _LastAccess} = findClient(ClientPID, ClientList, MaxClientAge),
			% io:format("LastNnr = ~p~n", [LastNnr]),
			MinDLQ = werkzeug:minNrSL(DLQ),
			if MinDLQ > LastNnr + 1 ->
				% this fixes odd behaviour, findneSL doesn't work as expected when no element is smaller than needle
				{Nnr, Message} = werkzeug:findSL(DLQ, MinDLQ);
			true ->
				{Nnr, Message} = werkzeug:findneSL(DLQ, LastNnr + 1)
			end,
			MaxDLQ = werkzeug:maxNrSL(DLQ),
			Terminated = (Nnr == -1) or (MaxDLQ == Nnr),
			ClientPID ! {reply, Nnr, Message, Terminated},
			log("server.log", "getMessage by ~p - ~p - ~s~n", [ClientPID, Terminated, Message]),
			NewClientList = updateClient(ClientPID, {Nnr, os:timestamp()}, ClientList),
			loop(HBQ, DLQ, NewClientList, NextNnr, NewTimer, ServerCfg);
		{params, ClientPID} ->
			ClientPID ! {params, [HBQ, DLQ, ClientList, NextNnr, ServerCfg]},
			loop(HBQ, DLQ, ClientList, NextNnr, Timer, ServerCfg)
	end.

test(ServerPID) ->
	ServerPID ! {params, self()},
	receive
		{params, Params} -> Params
	end.
	
stop(ServerPID) ->
	ServerPID ! stop.

findClient(ClientPID, ClientList, MaxClientAge) ->
	{_Nr, Result} = werkzeug:findSL(ClientList, ClientPID),
	if Result == nok ->
		{-1, os:timestamp()};
	true ->
		{_LastNnr, LastAccess} = Result,
		ClientAge = timer:now_diff(os:timestamp(), LastAccess),
		if ClientAge > MaxClientAge * 1000000 ->
			findClient(ClientPID, [], MaxClientAge);
		true ->
			Result
		end
	end.

updateClient(ClientPID, NewClient, ClientList) ->
	OldClient = werkzeug:findSL(ClientList, ClientPID),
	werkzeug:pushSL(lists:delete(OldClient, ClientList), {ClientPID, NewClient}).


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


dlqInsert(DLQ, Message, MaxDLQLength) ->
	queueCrop(queueInsert(DLQ, Message), MaxDLQLength).

hbqInsert(HBQ, Message, DLQ, MaxHBQLength, MaxDLQLength) ->
	{Nnr, Elem} = Message,
	MaxDLQ = werkzeug:maxNrSL(DLQ),
	if Nnr > MaxDLQ ->
		NewHBQ = queueInsert(HBQ,{Nnr, format("~s HBQ: ~s", [Elem, werkzeug:timeMilliSecond()])}),
		hbqClean(NewHBQ, DLQ, MaxHBQLength, MaxDLQLength);
	true ->
		[HBQ,DLQ]
	end.

hbqClean(HBQ, DLQ, MaxHBQLength, MaxDLQLength) ->
	[NewHBQ, NewDLQ] = hbqCrop(HBQ, DLQ, MaxDLQLength),
	Length = werkzeug:lengthSL(NewHBQ),
	if Length > MaxHBQLength ->
		MinHBQ = werkzeug:minNrSL(NewHBQ),
		MaxDLQ = werkzeug:maxNrSL(NewDLQ),
		log("server.log", "Luecke von ~p bis ~p geschlossen~n", [MaxDLQ + 1, MinHBQ - 1]),
		hbqClean(NewHBQ, dlqInsert(NewDLQ, {MinHBQ - 1, format("Fehlernachricht fuer Luecke von ~p bis ~p", [MaxDLQ + 1, MinHBQ - 1])}, MaxDLQLength), MaxHBQLength, MaxDLQLength);
	true ->
		[NewHBQ, NewDLQ]
	end.

hbqCrop(HBQ, DLQ, MaxDLQLength) ->
	MinHBQ = werkzeug:minNrSL(HBQ),
	MaxDLQ = werkzeug:maxNrSL(DLQ),
	if (MaxDLQ + 1 == MinHBQ) or (MaxDLQ == -1) ->
		{Nnr, Elem} = werkzeug:findSL(HBQ, MinHBQ),
		hbqCrop(werkzeug:popSL(HBQ), dlqInsert(DLQ, {Nnr, format("~s DLQ: ~s", [Elem, werkzeug:timeMilliSecond()])}, MaxDLQLength), MaxDLQLength);
	true ->
		[HBQ, DLQ]
	end.

pcName() ->
	{ok, Name} = inet:gethostname(),
	Name.

format(Text, Params) -> lists:flatten(io_lib:format(Text, Params)).
log(File, Text, Params) -> werkzeug:logging(File, format(Text, Params)).