-module(client).
-compile([export_all]).

start(ServerPID) -> spawn(client, loop, [ServerPID]).

loop(ServerPID) ->
	{ok, ClientCfg} = file:consult("client.cfg"),
	{ok, Delay} = werkzeug:get_config_value(delay, ClientCfg),
	log("client.log", "~s-~p-T3 C-Start: ~s~n", [pcName(), self(), werkzeug:timeMilliSecond()]),
	loop(ServerPID, [], Delay, ClientCfg).

loop(ServerPID, NnrList, Delay, ClientCfg) ->
	{ok, MsgCount} = werkzeug:get_config_value(msgCount, ClientCfg),
	NewNnrList = sendMsgs(ServerPID, NnrList, Delay, MsgCount),
	NewDelay = randomizeDelay(Delay),
	log("client.log", "Neues Intervall: ~p Sekunden~n", [NewDelay]),
	log("client.log", "Msg #~p um ~s vergessen zu senden~n", [requestNnr(ServerPID), werkzeug:timeMilliSecond()]),
	receiveMsgs(ServerPID, NewNnrList),
	log("client.log", "ReceiveMsgs done~n", []),
	loop(ServerPID, NewNnrList, NewDelay, ClientCfg).

sendMsgs(ServerPID, NnrList, Delay, Count) ->
	[Nnr, NewNnrList] = requestNnr(ServerPID, NnrList),
	timer:sleep(round(Delay * 1000)),
	Message = format("~s-~p-T3: Msg #~p, C-Out: ~s", [pcName(), self(), Nnr, werkzeug:timeMilliSecond()]),
	ServerPID ! {dropmessage , {Message, Nnr}},
	log("client.log", "~s gesendet~n", [Message]),
	if Count > 1 ->
		sendMsgs(ServerPID, NewNnrList, Delay, Count - 1);
	true ->
		NewNnrList
	end.

receiveMsgs(ServerPID, NnrList) ->
    ServerPID ! {getmessages, self()},
	receive
		{reply, Nnr, Message, Terminated} ->
		Known = isKnown(Nnr, NnrList)
	end,
	if Known ->
		log("client.log", "~s******* C-In: ~s~n", [Message, werkzeug:timeMilliSecond()]);
		%io:format("Eigene Nachricht empfangen: ~s~n", [Message]);
	true ->
		log("client.log", "~s C-In: ~s~n", [Message, werkzeug:timeMilliSecond()])
		%io:format("Nachricht empfangen: ~s~n", [Message])
	end,
	if Terminated ->
		true;
	true ->
		receiveMsgs(ServerPID, NnrList)
	end.


randomizeDelay(Delay) ->
	max(1, Delay * (random:uniform(2) * 2 - 1) / 2.0). % force float

requestNnr(ServerPID, NnrList) ->
	Nnr = requestNnr(ServerPID),
    [Nnr, lists:append(NnrList, [Nnr])].

requestNnr(ServerPID) ->
	ServerPID ! {getmsgid, self()},
	receive
		{nnr, Number} -> Number
	end.

isKnown(_Nnr, []) -> false;
isKnown(Nnr, [Nnr | _List]) -> true;
isKnown(Nnr, [_Nnr | List]) -> isKnown(Nnr, List).

pcName() ->
	{ok, Name} = inet:gethostname(),
	Name.
	
format(Text, Params) -> erlang:iolist_to_binary(io_lib:format(Text, Params)).
log(File, Text, Params) -> werkzeug:logging(File, format(Text, Params)).