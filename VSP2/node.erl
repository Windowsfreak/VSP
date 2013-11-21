-module(node).
-compile([export_all]).

%% RemoteEdge = {Weight, Node1, Node2}
%% TestEdge = {Weight, Node1, Node2} | false % {Remote, Weight, _IGNORE_STATE_} | false
%% BestEdge = {Weight, Node1, Node2} | false % Remote | false

%% infinite is an atom, atoms are always greater than numbers

loop(NodeName, EdgeList, NodeLevel, NodeState, NodeFragment, FindCount, InBranch, TestEdge, BestEdge, BestWeight) ->
	receive
  
		{connect, RemoteLevel, RemoteEdge} -> % 3
			if
				NodeState == sleeping ->
					{NewEdgeList, NewNodeLevel, NewNodeState, NewFindCount} = wakeup(EdgeList);
				true ->
					{NewEdgeList, NewNodeLevel, NewNodeState, NewFindCount} = {EdgeList, NodeLevel, NodeState, FindCount}
			end,
			Tmp1 = findType(findRemoteEdgeList(RemoteEdge, NewEdgeList)),
			if
				RemoteLevel < NewNodeLevel ->
					NewNewEdgeList = updateEdgeList(NodeName, RemoteEdge, branch, NewEdgeList),
					sendInitiate(RemoteEdge, NewNodeLevel, NodeFragment, NewNodeState),
					if
						NewNodeState == find ->
							NewNewFindCount = NewFindCount + 1;
						true ->
							NewNewFindCount = NewFindCount
					end,
					loop(NodeName, NewNewEdgeList, NewNodeLevel, NewNodeState, NodeFragment, NewNewFindCount, InBranch, TestEdge, BestEdge, BestWeight);
				Tmp1 == basic ->
					% sleep einbauen?
					self() ! {connect, RemoteLevel, RemoteEdge},
					loop(NodeName, NewEdgeList, NewNodeLevel, NewNodeState, NodeFragment, NewFindCount, InBranch, TestEdge, BestEdge, BestWeight);
				true ->
					sendInitiate(RemoteEdge, NewNodeLevel + 1, findWeight(RemoteEdge), find),
					loop(NodeName, NewEdgeList, NewNodeLevel, NewNodeState, NodeFragment, NewFindCount, InBranch, TestEdge, BestEdge, BestWeight)
			end;

		{initiate, RemoteLevel, RemoteFragment, RemoteState, RemoteEdge} -> % 4
			NewNodeLevel = RemoteLevel,
			NewNodeFragment = RemoteFragment,
			NewNodeState = RemoteState,
			NewInBranch = RemoteEdge,
			NewBestEdge = false,
			NewBestWeight = infinite,
			
			{NewFindCount} = sendAllInitiate(NodeName, RemoteEdge, EdgeList, FindCount, RemoteLevel, RemoteFragment, RemoteState),
			% BLÖDE BEKNACKTE FOR SCHLEIFE Send Initiate(Remote, Remote, Remote, Remote) on all branches, not source
			% NewFindCount = ... return value,

			if
				RemoteState == find ->
					{NewNewNodeState, NewTestEdge} = test(NodeName, EdgeList, NewNodeState, NewNodeLevel, NewNodeFragment, NewFindCount, NewInBranch, NewBestWeight);
				true ->
					{NewNewNodeState, NewTestEdge} = {NewNodeState, TestEdge}
			end,
			loop(NodeName, EdgeList, NewNodeLevel, NewNewNodeState, NewNodeFragment, NewFindCount, NewInBranch, NewTestEdge, NewBestEdge, NewBestWeight);
  
		{test, RemoteLevel, RemoteFragment, RemoteEdge} -> % 6
			if
				NodeState == sleeping ->
					{NewEdgeList, NewNodeLevel, NewNodeState, NewFindCount} = wakeup(EdgeList);
				true ->
					{NewEdgeList, NewNodeLevel, NewNodeState, NewFindCount} = {EdgeList, NodeLevel, NodeState, FindCount}
			end,
			if
				RemoteLevel > NodeLevel ->
					% sleep einbauen?
					self() ! {test, RemoteLevel, RemoteFragment, RemoteEdge},
					loop(NodeName, NewEdgeList, NewNodeLevel, NewNodeState, NodeFragment, NewFindCount, InBranch, TestEdge, BestEdge, BestWeight);
				true ->
					Tmp2 = compareNodes(RemoteFragment, NodeFragment),
					if
						Tmp2 == false ->
							sendAccept(RemoteEdge),
							loop(NodeName, NewEdgeList, NodeLevel, NewNodeState, NodeFragment, NewFindCount, InBranch, TestEdge, BestEdge, BestWeight);
						true ->
							Tmp3 = findType(findRemoteEdgeList(RemoteEdge, NewEdgeList)),
							if
								Tmp3 == basic ->
									NewEdgeList = updateEdgeList(NodeName, RemoteEdge, rejected, EdgeList),
									Tmp4 = compareNodes(TestEdge, RemoteEdge),
									if
										Tmp4 == false ->
											sendReject(RemoteEdge),
											{NewNewNodeState, NewTestEdge} = {NewNodeState, TestEdge};
										true ->
											{NewNewNodeState, NewTestEdge} = test(NodeName, NewEdgeList, NewNodeState, NewNodeLevel, NodeFragment, NewFindCount, InBranch, BestWeight)
									end,
									loop(NodeName, NewEdgeList, NodeLevel, NewNewNodeState, NodeFragment, FindCount, InBranch, NewTestEdge, BestEdge, BestWeight)
							end
					end
			end;

		{accept, RemoteEdge} -> % 7
			NewTestEdge = false,
			Tmp5 = findWeight(RemoteEdge),
			if
				Tmp5 < BestWeight ->
					NewBestEdge = RemoteEdge,
					NewBestWeight = findWeight(RemoteEdge);
				true ->
					NewBestEdge = BestEdge,
					NewBestWeight = BestWeight
			end,
			{NewNodeState} = report(NodeState, FindCount, InBranch, NewTestEdge, NewBestWeight),
			loop(NodeName, EdgeList, NodeLevel, NewNodeState, NodeFragment, FindCount, InBranch, NewTestEdge, NewBestEdge, NewBestWeight);

		{reject, RemoteEdge} -> % 8
			Tmp6 = findType(findRemoteEdgeList(RemoteEdge, EdgeList)),
			if
				Tmp6 == basic ->
					NewEdgeList = updateEdgeList(NodeName, RemoteEdge, rejected, EdgeList),
					{NewNodeState, NewTestEdge} = test(NodeName, NewEdgeList, NodeState, NodeLevel, NodeFragment, FindCount, InBranch, BestWeight),
					loop(NodeName, NewEdgeList, NodeLevel, NewNodeState, NodeFragment, FindCount, InBranch, NewTestEdge, BestEdge, BestWeight);
				true ->
					loop(NodeName, EdgeList, NodeLevel, NodeState, NodeFragment, FindCount, InBranch, TestEdge, BestEdge, BestWeight)
			end;

		{report, RemoteWeight, RemoteEdge} -> % 10
			Tmp7 = compareNodes(RemoteEdge, InBranch),
			if
				Tmp7 == false ->
					NewFindCount = FindCount - 1,
					if
						RemoteWeight < BestWeight ->
							NewBestWeight = RemoteWeight,
							NewBestEdge = RemoteEdge;
						true ->
							NewBestWeight = BestWeight,
							NewBestEdge = BestEdge
					end,
					{NewNodeState} = report(NodeState, NewFindCount, InBranch, TestEdge, NewBestWeight),
					loop(NodeName, EdgeList, NodeLevel, NewNodeState, NodeFragment, NewFindCount, InBranch, TestEdge, NewBestEdge, NewBestWeight);
				NodeState == find ->
					% sleep einbauen?
					self() ! {report, RemoteWeight, RemoteEdge},
					loop(NodeName, EdgeList, NodeLevel, NodeState, NodeFragment, FindCount, InBranch, TestEdge, BestEdge, BestWeight);
				RemoteWeight > BestWeight ->
					{NewEdgeList} = changeRoot(NodeName, EdgeList, BestEdge, NodeLevel),
					loop(NodeName, NewEdgeList, NodeLevel, NodeState, NodeFragment, FindCount, InBranch, TestEdge, BestEdge, BestWeight);
				(RemoteWeight == infinite) and (BestWeight == infinite) ->
					% exit(),
					{true} % equivalent to exit!
			end;

		{changeroot, _Edge} -> % 12
			{NewEdgeList} = changeRoot(NodeName, EdgeList, BestEdge, NodeLevel),
			loop(NodeName, NewEdgeList, NodeLevel, NodeState, NodeFragment, FindCount, InBranch, TestEdge, BestEdge, BestWeight);

		wakeup -> % 1
			{NewEdgeList, NewNodeLevel, NewNodeState, NewFindCount} = wakeup(EdgeList),
			loop(NodeName, NewEdgeList, NewNodeLevel, NewNodeState, NodeFragment, NewFindCount, InBranch, TestEdge, BestEdge, BestWeight);

		{params, ClientPid} -> % 0
			ClientPid ! {params, [NodeName, EdgeList, NodeLevel, NodeState, NodeFragment, FindCount, InBranch, TestEdge, BestEdge, BestWeight]},
			loop(NodeName, EdgeList, NodeLevel, NodeState, NodeFragment, FindCount, InBranch, TestEdge, BestEdge, BestWeight)
			
	end.

wakeup(EdgeList) -> % 2
	MinEdge = findMinimumBasicEdge(EdgeList),
	NewEdgeList = updateEdgeList(MinEdge, branch, EdgeList),
	NodeLevel = 0,
	NodeState = found,
	FindCount = 0,
	sendConnect(MinEdge, 0),
	{NewEdgeList, NodeLevel, NodeState, FindCount}.

test(NodeName, EdgeList, NodeState, NodeLevel, NodeFragment, FindCount, InBranch, BestWeight) -> % 5
	TestEdge = exportEdge(NodeName, findMinimumBasicEdge(EdgeList)),
	if
		TestEdge /= false ->
			sendTest(TestEdge, NodeLevel, NodeFragment),
			{NodeState, TestEdge};
		true ->
			{NewNodeState} = report(NodeState, FindCount, InBranch, TestEdge, BestWeight),
			{NewNodeState, TestEdge}
	end.

report(NodeState, FindCount, InBranch, TestEdge, BestWeight) -> % 9
	if
		(FindCount == 0) and (TestEdge == false) ->
			sendReport(InBranch, BestWeight),
			NewNodeState = found,
			{NewNodeState};
		true ->
			{NodeState}
	end.

changeRoot(NodeName, EdgeList, BestEdge, NodeLevel) -> % 11
	Tmp8 = findType(findRemoteEdgeList(BestEdge, EdgeList)),
	if
		Tmp8 == branch ->
			sendChangeRoot(BestEdge),
			{EdgeList};
		true ->
			sendConnect(BestEdge, NodeLevel),
			NewEdgeList = updateEdgeList(NodeName, BestEdge, branch, EdgeList),
			{NewEdgeList}
	end.

sendAllInitiate(_NodeName, _RemoteEdge, [], FindCount, _RemoteLevel, _RemoteFragment, _RemoteState) ->
	{FindCount};
sendAllInitiate(NodeName, RemoteEdge, [Edge | EdgeList], FindCount, RemoteLevel, RemoteFragment, RemoteState) ->
	Tmp9 = findType(Edge),
	Tmp10 = compareNodes(RemoteEdge, exportEdge(NodeName, Edge)),
	if
		Tmp10 == true ->
			sendAllInitiate(NodeName, RemoteEdge, EdgeList, FindCount, RemoteLevel, RemoteFragment, RemoteState);
		Tmp9 == branch ->
			sendInitiate(exportEdge(NodeName, Edge), RemoteLevel, RemoteFragment, RemoteState),
			sendAllInitiate(NodeName, RemoteEdge, EdgeList, FindCount, RemoteLevel, RemoteFragment, RemoteState) + 1;
		true ->
			sendAllInitiate(NodeName, RemoteEdge, EdgeList, FindCount, RemoteLevel, RemoteFragment, RemoteState)
	end.

sendInitiate(Edge, Level, Fragment, State) -> sendMessage(Edge, {initiate, Level, Fragment, State, Edge}).
sendAccept(Edge) -> sendMessage(Edge, {accept, Edge}).
sendReject(Edge) -> sendMessage(Edge, {reject, Edge}).
sendConnect(Edge, Level) -> sendMessage(Edge, {connect, Level, Edge}).
sendTest(Edge, Level, Fragment) -> sendMessage(Edge, {test, Level, Fragment, Edge}).
sendReport(Edge, Weight) -> sendMessage(Edge, {report, Weight, Edge}).
sendChangeRoot(Edge) -> sendMessage(Edge, {changeroot, Edge}).

sendMessage(_Edge, Payload) ->
	log("node.log", "sending message ~p~n", [Payload]).

findMinimumBasicEdge([]) -> false;
findMinimumBasicEdge([{Remote, Weight, basic} | EdgeList]) ->
	Edge = findMinimumBasicEdge(EdgeList),
	if
		Edge == false ->
			{Remote, Weight, basic};
		true ->
			{_Remote2, Weight2, basic} = Edge,
			if
				(Weight < Weight2) ->
					{Remote, Weight, basic};
				true ->
					Edge
			end
	end;
findMinimumBasicEdge([{_Remote, _Weight, _Type} | EdgeList]) -> findMinimumBasicEdge(EdgeList).

% uses {Weight, Node1, Node2}
findWeight({Weight, _, _}) -> Weight.

% uses {Remote, Weight, Type}
findType({_, _, Type}) -> Type.

% uses {Weight, Node1, Node2}
findRemoteNode({_, NodeName, Remote}, NodeName) -> Remote;
findRemoteNode({_, Remote, NodeName}, NodeName) -> Remote.

% converts {Remote, Weight, Type} in {Weight, Node1, Node2}
exportEdge(_, false) -> false;
exportEdge(NodeName, {Remote, Weight, _}) -> {Weight, Remote, NodeName}.

% dual-use, accepts Name and Edge
% findEdgeList(false, _) -> false;
% findEdgeList(_, []) -> throw("edge unknown");
% findEdgeList({Remote, _, _}, [{Remote, Weight, Type} | EdgeList]) -> {Remote, Weight, Type};
% findEdgeList(Remote, [{Remote, Weight, Type} | EdgeList]) -> {Remote, Weight, Type};
% findEdgeList(Edge, [_ | EdgeList]) -> findEdgeList(Edge, EdgeList).

% converts {Node1, Node2, Weight} in {Remote, Weight, Type}
findRemoteEdgeList(false, _) -> false;
findRemoteEdgeList(_, []) -> throw("edge unknown");
findRemoteEdgeList({_, Remote, _}, [{Remote, Weight, Type} | _EdgeList]) -> {Remote, Weight, Type};
findRemoteEdgeList({Remote, _, _}, [{Remote, Weight, Type} | _EdgeList]) -> {Remote, Weight, Type};
findRemoteEdgeList(Edge, [_ | EdgeList]) -> findRemoteEdgeList(Edge, EdgeList).

% uses {Weight, Node1, Node2}
% false and false are not equal here!
compareNodes({Weight, Node1, Node2}, {Weight, Node1, Node2}) -> true;
compareNodes({Weight, Node1, Node2}, {Weight, Node2, Node1}) -> true;
compareNodes(_, _) -> false.

updateEdgeList(_, []) -> throw("edge unknown");
updateEdgeList({Remote, _Weight, Type}, [{Remote, Weight, _Type} | EdgeList]) ->
	[{Remote, Weight, Type}] ++ EdgeList;
updateEdgeList(Triple, [{Remote, Weight, Type} | EdgeList]) ->
	[{Remote, Weight, Type}] ++ updateEdgeList(Triple, EdgeList).

updateEdgeList({Remote, _, _}, Type, EdgeList) ->
	updateEdgeList({Remote, -1, Type}, EdgeList).

updateEdgeList(NodeName, Edge, Type, EdgeList) ->
	Remote = findRemoteNode(Edge, NodeName),
	updateEdgeList({Remote, -1, Type}, EdgeList).

format(Text, Params) -> lists:flatten(io_lib:format(Text, Params)).
log(File, Text, Params) -> werkzeug:logging(File, format(Text, Params)).