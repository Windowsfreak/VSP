-module(server).
-compile([export_all]).

start() ->
	Pid = spawn(server, loop, []),
	register(node2, Pid),
	Pid.

loop() ->
loop(node2, [{node1, 2, basic}, {node3, 3, basic}, {node4, 4, basic}, {node5, 1, basic}], sleeping, 0, -1).

loop(NodeName, EdgeList, NodeState, Level, FragmentID) ->
	receive
		{initiate, NewLevel, NewFragmentID, NewNodeState, Edge } ->
			Remote = findRemoteNode(Edge, NodeName),
			NewEdgeList = updateEdgeList({Remote, -1, branch}, EdgeList),
			sendInitiate(NodeName, Remote, NewLevel, NewFragmentID, NewNodeState, NewEdgeList),
			loop(NodeName, NewEdgeList, NewNodeState, NewLevel, NewFragmentID);
		{params, ClientPID} ->
			ClientPID ! {params, [NodeName, EdgeList, NodeState, Level, FragmentID]},
			loop(NodeName, EdgeList, NodeState, Level, FragmentID)
	end.

test(ServerPID) ->
	ServerPID ! {params, self()},
	receive
		{params, Params} -> Params
	end.
	
findWeight({Weight, _, _}) -> Weight.

findRemoteNode({_, NodeName, Remote}, NodeName) -> Remote;
findRemoteNode({_, Remote, NodeName}, NodeName) -> Remote.

updateEdgeList(_, []) -> throw("edge unknown");
updateEdgeList({Remote, _, Type}, [{Remote, Weight, _} | EdgeList]) ->
	[{Remote, Weight, Type}] ++ EdgeList;
updateEdgeList(Triple, [{Remote, Weight, Type} | EdgeList]) ->
	[{Remote, Weight, Type}] ++ updateEdgeList(Triple, EdgeList).
	
sendInitiate(_NodeName, _Source, _Level, _FragmentID, _NodeState, []) ->
	log("server.log", "Last edge processed, entering tail recursion...~n", []),
	{-1, false, []};
sendInitiate(NodeName, Source, Level, FragmentID, NodeState, [{Source, Weight, Type} | EdgeList]) -> 
	log("server.log", "skipping Source Edge: ~s~n", [Source]),
	sendInitiate(NodeName, Source, Level, FragmentID, NodeState, EdgeList);
sendInitiate(NodeName, Source, Level, FragmentID, NodeState, [{Remote, Weight, rejected} | EdgeList]) -> 
	log("server.log", "skipping Rejected Edge: ~s~n", [Remote]),
	sendInitiate(NodeName, Source, Level, FragmentID, NodeState, EdgeList);
sendInitiate(NodeName, Source, Level, FragmentID, NodeState, [{Remote, Weight, branch} | EdgeList]) -> 
	log("server.log", "send initiate to ~s: ~p~n", [Remote, {initiate, Level, FragmentID, NodeState, {Weight, NodeName, Remote}}]),
	ReturnedData = sendInitiate(NodeName, Source, Level, FragmentID, NodeState, EdgeList),
	log("server.log", "entering receiveReport for ~s or substitute, returned data: ~p~n", [Remote, ReturnedData]),
	ReportedData = receiveReport(NodeName),
	log("server.log", "leaving  receiveReport, received data: ~p~n", [ReceivedData]),
	selectReturnValue(ReturnedData, ReportedData);
sendInitiate(NodeName, Source, Level, FragmentID, NodeState, [{Remote, Weight, basic} | EdgeList]) -> 
	log("server.log", "send test to ~s: ~p~n", [Remote, {test, Level, FragmentID, {Weight, NodeName, Remote}}]),
	ReturnedData = sendInitiate(NodeName, Source, Level, FragmentID, NodeState, EdgeList),
	log("server.log", "entering receiveReport for ~s or substitute, returned data: ~p~n", [Remote, ReturnedData]),
	ReportedData = receiveReport(NodeName),
	log("server.log", "leaving  receiveReport, received data: ~p~n", [ReceivedData]),
	selectReturnValue(ReturnedData, ReportedData).

receiveReport(NodeName) ->
	receive
		{accept, Edge} -> {findWeight(Edge), Edge};
		{reject, Edge} -> {-1, Edge};
		{report, Weight, Edge} -> {Weight, Edge};
		{params, ClientPID} ->
			ClientPID ! {params, [NodeName, 'Hey, I am in receiveReport and have no additional information available.']},
			receiveReport(NodeName)
	end.

selectReturnValue(ReturnedData, ReportedData) ->
	{ReturnedWeight, ReturnedEdge, RejectedEdges} = ReturnedData,
	{ReportedWeight, ReportedEdge} = ReportedData,
	if
		(ReportedWeight = -1) ->
			{ReturnedWeight, ReturnedEdge, RejectedEdges ++ [ReportedEdge]};
		(ReportedWeight < ReturnedWeight) ->
			{ReportedWeight, ReportedEdge, RejectedEdges};
		true ->
			{ReturnedWeight, ReturnedEdge, RejectedEdges}
	end.


format(Text, Params) -> lists:flatten(io_lib:format(Text, Params)).
log(File, Text, Params) -> werkzeug:logging(File, format(Text, Params)).