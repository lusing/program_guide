-module(e20_timer_timeout).
-export([wait_message/1, schedule_ping/1, drain_ping/0]).

wait_message(TimeoutMs) when is_integer(TimeoutMs), TimeoutMs >= 0 ->
    receive
        Msg -> {ok, Msg}
    after TimeoutMs ->
        timeout
    end.

schedule_ping(DelayMs) when is_integer(DelayMs), DelayMs >= 0 ->
    timer:send_after(DelayMs, self(), ping).

drain_ping() ->
    receive
        ping -> ok
    after 0 ->
        none
    end.

