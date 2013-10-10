-module(client).
-compile([export_all]).

start(ServerPID) -> spawn(client, loop, [ServerPID]).

loop(ServerPID) ->
	{ok, ClientCfg} = file:consult("client.cfg"),
	{ok, Delay} = werkzeug:get_config_value(delay, ClientCfg),
	loop(ServerPID, [], Delay, ClientCfg).

loop(ServerPID, NnrList, Delay, ClientCfg) ->
	{ok, MsgCount} = werkzeug:get_config_value(msgCount, ClientCfg),
	NewNnrList = sendMsgs(ServerPID, NnrList, Delay, MsgCount),
	NewDelay = randomizeDelay(Delay),
	requestNnr(ServerPID),
	receiveMsgs(ServerPID, NewNnrList),
	loop(ServerPID, NewNnrList, NewDelay, ClientCfg).

sendMsgs(ServerPID, NnrList, Delay, Count) ->
	[Nnr, NewNnrList] = requestNnr(ServerPID, NnrList),
	timer:sleep(round(Delay * 1000)),
	ServerPID ! {dropmessage , {"test", Nnr}},
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
		io:format("Eigene Nachricht empfangen: ~s\n", [Message]);
	true ->
		io:format("Nachricht empfangen: ~s\n", [Message])
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

log(File, Text, Params) -> werkzeug:logging(File, lists:concat(io_lib:format(Text, Params))).