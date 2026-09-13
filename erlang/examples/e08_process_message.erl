-module(e08_process_message).
-export([start_worker/0, ask/2]).

start_worker() ->
    spawn(fun loop/0).

ask(Pid, Msg) ->
    Ref = make_ref(),
    Pid ! {self(), Ref, Msg},
    receive
        {Ref, Reply} -> {ok, Reply}
    after 1000 ->
        timeout
    end.

loop() ->
    receive
        {From, Ref, {echo, Value}} ->
            From ! {Ref, Value},
            loop();
        {From, Ref, stop} ->
            From ! {Ref, stopped};
        _Other ->
            loop()
    end.

