-module(worker).
-export([first_worker/2, generic_worker/3]).

first_worker(N, PidControl) when N > 1 ->
	GenericWorker = spawn(worker, generic_worker, [PidControl, self(), N-1]),
	dowork(PidControl, GenericWorker);

first_worker(_, PidControl) ->
	dowork(PidControl, self()).

generic_worker(PidControl, PidFirst, N) when N > 1 ->
	GenericWorker = spawn(worker, generic_worker, [PidControl, PidFirst, N-1]),	
	dowork(PidControl, GenericWorker);
	
generic_worker(PidControl, PidFirst, _) ->
	dowork(PidControl, PidFirst).					

dowork(PidControl, PidNext) ->
	receive
		token -> 
			PidControl ! { self() , eat },
			PidNext ! token,
			dowork(PidControl, PidNext);
		stop ->
			PidNext ! stop
	end.
