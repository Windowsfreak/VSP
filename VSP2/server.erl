-module(server).
-compile([export_all]).

start() ->
	Pid = spawn(server, loop, []),
	register(node2, Pid),
	Pid.

loop() ->
loop(node2, [{node1, 2, basic}, {node3, 3, basic}, {node4, 4, basic}, {node5, 1, basic}], sleeping, 0, -1).

loop(NodeName, EdgeList, NodeState, Level, FragmentID) ->
	% in diesem Codeabschnitt wäre der State "sleeping"
	receive
		% test
		{test, RemoteLevel, FragmentID, Edge} ->
			% send a reject!
			% on connect
			% also send a reject!
			;
		{test, RemoteLevel, RemoteFragmentID, Edge} when (RemoteLevel < Level) ->
			% send an accept!
			;
		{test, RemoteLevel, RemoteFragmentID, Edge} when (RemoteLevel > Level) ->
			% on connect
			% delay response!
			;
		{test, RemoteLevel, RemoteFragmentID, Edge} when (RemoteLevel == Level) ->
			% on connect
			% increase level and
			% issue a changeRoot!
			;
		% connect
			% if level == level, then wait until you send a connect. if you send a connect, wait until you receive a connect.
			% then increase level by 1 and continue sending initiate
		% changeRoot
		% reject (?)
		{initiate, NewLevel, NewFragmentID, NewNodeState, Edge } ->
			Remote = findRemoteNode(Edge, NodeName),
			NewEdgeList = updateEdgeList({Remote, findWeight(Edge), branch}, EdgeList), % findWeight can be substituted by -1 without side effect
			% in diesem Codeabschnitt wäre der State "find"
			{BestWeight, BestEdge, RejectedEdges} = sendInitiate(NodeName, Remote, NewLevel, NewFragmentID, NewNodeState, NewEdgeList),
			NewerEdgeList = multipleUpdateEdgeList(RejectedEdges, NewEdgeList),
			% in diesem Codeabschnitt wäre der State weiterhin "find"
			sendReport(NodeName, BestWeight, Edge),
			% Todo: merke dir, wo sich die BestEdge befindet!!!
			loop(NodeName, NewerEdgeList, NewNodeState, NewLevel, NewFragmentID);
			
			% weiß noch nicht, wo folgendes hingehört:
			% ... sendConnect, set as branch, go in found state
			% after sending report, you also go in found state
		{params, ClientPID} ->
			ClientPID ! {params, [NodeName, EdgeList, NodeState, Level, FragmentID]},
			loop(NodeName, EdgeList, NodeState, Level, FragmentID)
		% Todo: Folie 64 core exchange reports
		% Todo: Folie 71 verstehen
		
		% bekommen wir ein ChangeRoot
		% senden wir ChangeRoot an BestEdge (siehe initiate oben)
		% ist BestEdge jedoch basic, senden wir ein Connect!
		
		% wenn ein anderer Knoten beitritt, und state == Found, dann sende initiate mit state == Found
		% wenn ein anderer Knoten beitritt, und state == Find, siehe receiveReport, dann sende initiate mit state == Find
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
updateEdgeList({Remote, _Weight, Type}, [{Remote, Weight, _Type} | EdgeList]) ->
	[{Remote, Weight, Type}] ++ EdgeList;
updateEdgeList(Triple, [{Remote, Weight, Type} | EdgeList]) ->
	[{Remote, Weight, Type}] ++ updateEdgeList(Triple, EdgeList).

multipleUpdateEdgeList([], EdgeList) ->
	EdgeList;
multipleUpdateEdgeList([Elem | UpdateList], EdgeList) ->
	multipleUpdateEdgeList(UpdateList, updateEdgeList(Elem, EdgeList)).
	
sendInitiate(_NodeName, _Source, _Level, _FragmentID, _NodeState, []) ->
	log("server.log", "Last edge processed, entering tail recursion...~n", []),
	{-1, false, []};
sendInitiate(NodeName, Source, Level, FragmentID, NodeState, [{Source, _Weight, _Type} | EdgeList]) -> 
	log("server.log", "skipping Source Edge: ~s~n", [Source]),
	sendInitiate(NodeName, Source, Level, FragmentID, NodeState, EdgeList);
sendInitiate(NodeName, Source, Level, FragmentID, NodeState, [{Remote, _Weight, rejected} | EdgeList]) -> 
	log("server.log", "skipping Rejected Edge: ~s~n", [Remote]),
	sendInitiate(NodeName, Source, Level, FragmentID, NodeState, EdgeList);
sendInitiate(NodeName, Source, Level, FragmentID, NodeState, [{Remote, Weight, branch} | EdgeList]) -> 
	log("server.log", "send initiate to ~s: ~p~n", [Remote, {initiate, Level, FragmentID, NodeState, {Weight, NodeName, Remote}}]),
	ReturnedData = sendInitiate(NodeName, Source, Level, FragmentID, NodeState, EdgeList),
	log("server.log", "entering receiveReport for ~s or substitute, returned data: ~p~n", [Remote, ReturnedData]),
	ReportedData = receiveReport(NodeName),
	log("server.log", "leaving  receiveReport, received data: ~p~n", [ReportedData]),
	selectReturnValue(NodeName, ReturnedData, ReportedData);
sendInitiate(NodeName, Source, Level, FragmentID, NodeState, [{Remote, Weight, basic} | EdgeList]) -> 
	% todo: we must only send Test messages on Basic edges (MINIMAL first)...
	log("server.log", "send test to ~s: ~p~n", [Remote, {test, Level, FragmentID, {Weight, NodeName, Remote}}]),
	ReturnedData = sendInitiate(NodeName, Source, Level, FragmentID, NodeState, EdgeList),
	log("server.log", "entering receiveReport for ~s or substitute, returned data: ~p~n", [Remote, ReturnedData]),
	ReportedData = receiveReport(NodeName),
	log("server.log", "leaving  receiveReport, received data: ~p~n", [ReportedData]),
	selectReturnValue(NodeName, ReturnedData, ReportedData).

receiveReport(NodeName) ->
	receive
		% test !!!
		{accept, Edge} -> {findWeight(Edge), Edge};
		{reject, Edge} -> {-1, Edge};
		{report, Weight, Edge} -> {Weight, Edge};
		{params, ClientPID} ->
			ClientPID ! {params, [NodeName, 'Hey, I am in receiveReport and have no additional information available.']},
			receiveReport(NodeName)
		% if other node joins, send initiate... :-O
	end.

selectReturnValue(NodeName, ReturnedData, ReportedData) ->
	{ReturnedWeight, ReturnedEdge, RejectedEdges} = ReturnedData,
	{ReportedWeight, ReportedEdge} = ReportedData,
	if
		(ReportedWeight == -1) ->
			{ReturnedWeight, ReturnedEdge, RejectedEdges ++ [{findRemoteNode(ReportedEdge, NodeName), findWeight(ReportedEdge), rejected}]};
		(ReturnedWeight == -1) -> % -1 is smaller than 4 but we prefer 4 over -1
			{ReportedWeight, ReportedEdge, RejectedEdges};
		(ReportedWeight < ReturnedWeight) ->
			{ReportedWeight, ReportedEdge, RejectedEdges};
		true ->
			{ReturnedWeight, ReturnedEdge, RejectedEdges}
	end.
	
sendReport(NodeName, BestWeight, Edge) ->
	Remote = findRemoteNode(Edge, NodeName),
	log("server.log", "reporting best weight ~p to remote node ~s: ~p~n", [BestWeight, Remote, {report, BestWeight, Edge}]).

format(Text, Params) -> lists:flatten(io_lib:format(Text, Params)).
log(File, Text, Params) -> werkzeug:logging(File, format(Text, Params)).