-module(client).
-compile([export_all]).

startDistributed(Number, ServerName) -> startMultiple(Number, {server, ServerName}).

startMultiple(0, _) -> true;
startMultiple(Count, ServerPID) ->
	start(Count, ServerPID),
	startMultiple(Count - 1, ServerPID).

start(Number, ServerPID) -> spawn(client, loop, [Number, ServerPID]).

loop(Number, ServerPID) ->
	{ok, ClientCfg} = file:consult("client.cfg"),
	{ok, Delay} = werkzeug:get_config_value(delay, ClientCfg),
	log(getFileName(Number), "~s-~p-~p-T3 C-Start: ~s~n", [pcName(), Number, self(), werkzeug:timeMilliSecond()]),
	loop(Number, ServerPID, [], Delay, ClientCfg).

loop(Number, ServerPID, NnrList, Delay, ClientCfg) ->
	{ok, MsgCount} = werkzeug:get_config_value(msgCount, ClientCfg),
	NewNnrList = sendMsgs(Number, ServerPID, NnrList, Delay, MsgCount),
	NewDelay = randomizeDelay(Delay),
	log(getFileName(Number), "Neues Intervall: ~p Sekunden~n", [NewDelay]),
	log(getFileName(Number), "Msg #~p um ~s vergessen zu senden~n", [requestNnr(ServerPID), werkzeug:timeMilliSecond()]),
	receiveMsgs(Number, ServerPID, NewNnrList),
	log(getFileName(Number), "ReceiveMsgs done~n", []),
	loop(Number, ServerPID, NewNnrList, NewDelay, ClientCfg).

sendMsgs(Number, ServerPID, NnrList, Delay, Count) ->
	[Nnr, NewNnrList] = requestNnr(ServerPID, NnrList),
	timer:sleep(round(Delay * 1000)),
	Message = format("~s-~p-~p-T3: Msg #~p, C-Out: ~s", [pcName(), Number, self(), Nnr, werkzeug:timeMilliSecond()]),
	ServerPID ! {dropmessage , {Message, Nnr}},
	log(getFileName(Number), "~s gesendet~n", [Message]),
	if Count > 1 ->
		sendMsgs(Number, ServerPID, NewNnrList, Delay, Count - 1);
	true ->
		NewNnrList
	end.

receiveMsgs(Number, ServerPID, NnrList) ->
    ServerPID ! {getmessages, self()},
	receive
		{reply, Nnr, Message, Terminated} ->
		Known = isKnown(Nnr, NnrList)
	end,
	if Known ->
		log(getFileName(Number), "~s******* C-In: ~s~n", [Message, werkzeug:timeMilliSecond()]);
		%io:format("Eigene Nachricht empfangen: ~s~n", [Message]);
	true ->
		log(getFileName(Number), "~s C-In: ~s~n", [Message, werkzeug:timeMilliSecond()])
		%io:format("Nachricht empfangen: ~s~n", [Message])
	end,
	if Terminated ->
		true;
	true ->
		receiveMsgs(Number, ServerPID, NnrList)
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
getFileName(Number) -> lists:flatten(["client", integer_to_list(Number), ".log"]).