-module(client).
-compile([export_all]).

loop() ->
	
	true. % TODO

sendMsgs(ServerPID, NnrList, Delay, Count) ->
	[Nnr, NewNnrList] = requestNnr(ServerPID, NnrList),
	timer:sleep(Delay * 1000),
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
	end. % TODO

isKnown(_Nnr, []) -> false;
isKnown(Nnr, [Nnr | _List]) -> true;
isKnown(Nnr, [_Nnr | List]) -> isKnown(Nnr, List).
% lol