-module(e21_monitor_demo).
-export([start_worker/0, stop_and_wait/1]).

start_worker() ->
    spawn(fun() ->
        receive
            stop -> ok
        end
    end).

stop_and_wait(Pid) when is_pid(Pid) ->
    Ref = erlang:monitor(process, Pid),
    Pid ! stop,
    receive
        {'DOWN', Ref, process, Pid, Reason} ->
            {ok, Reason}
    after 2000 ->
        timeout
    end.

