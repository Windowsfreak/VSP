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
	
findRemoteNode({_, NodeName, Remote}, NodeName) -> Remote;
findRemoteNode({_, Remote, NodeName}, NodeName) -> Remote.

updateEdgeList(_, []) -> throw("edge unknown");
updateEdgeList({Remote, _, Type}, [{Remote, Weight, _} | EdgeList]) ->
	[{Remote, Weight, Type}] ++ EdgeList;
updateEdgeList(Triple, [{Remote, Weight, Type} | EdgeList]) ->
	[{Remote, Weight, Type}] ++ updateEdgeList(Triple, EdgeList).
	
sendInitiate(_NodeName, _Source, _Level, _FragmentID, _NodeState, []) -> false;
sendInitiate(NodeName, Source, Level, FragmentID, NodeState, [{Source, Weight, Type} | EdgeList]) -> 
	sendInitiate(NodeName, Source, Level, FragmentID, NodeState, EdgeList).
sendInitiate(NodeName, Source, Level, FragmentID, NodeState, [{Remote, Weight, rejected} | EdgeList]) -> 
	sendInitiate(NodeName, Source, Level, FragmentID, NodeState, EdgeList).
sendInitiate(NodeName, Source, Level, FragmentID, NodeState, [{Remote, Weight, branch} | EdgeList]) -> 
%	if
%		((Remote /= Source) and (Type == branch)) ->
			log("server.log", "send initiate to ~s~n", [Remote]),
%		true ->
%			Test = "hallo"
%	end,
	sendInitiate(NodeName, Source, Level, FragmentID, NodeState, EdgeList).
sendInitiate(NodeName, Source, Level, FragmentID, NodeState, [{Remote, Weight, basic} | EdgeList]) -> 
%	if
%		((Remote /= Source) and (Type == branch)) ->
%			log("server.log", "send initiate to ~s~n", [Remote]);
%		true ->
			Test = "hallo",
%	end,
	sendInitiate(NodeName, Source, Level, FragmentID, NodeState, EdgeList).
	
format(Text, Params) -> lists:flatten(io_lib:format(Text, Params)).
log(File, Text, Params) -> werkzeug:logging(File, format(Text, Params)).