-module(control).
-export([go/2]).

% N is the number of ring processes
% M is the range of targets
% flush the mailbox to erase obsolet info,
% creates the first worker and starts the game
%
go(N, M) -> flush_mailbox(),
			TargetList = generate(M),
			io:format("~p~n", [TargetList]),
			FirstWorker = spawn(worker, first_worker, [N, self()]),
			FirstWorker ! token,
			ResultList = controlgame(TargetList, []),
			io:format("~w~n", [ResultList]),
			FirstWorker ! stop.

%generates a list of M random numbers in rtrange 1..M
generate(0) -> [];
generate(M) -> [rand:uniform(M)|generate(M-1)].

controlgame([], ResultList) -> ResultList;
controlgame(TargetList, ResultList) ->
	receive
		{Pid, eat} -> io:format("~w eats~n", [Pid]),
		[First|NewTargetList] = TargetList,
		NewResultList = [{Pid, First}|ResultList],
		controlgame(NewTargetList, NewResultList)
	end.

flush_mailbox() ->
	receive
		_Any -> flush_mailbox()
	after
		0 -> ok
	end.
