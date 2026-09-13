-module(e18_queue_demo).
-export([build/1, pop/1, peek/1]).

build(List) ->
    lists:foldl(fun(Elem, Q) -> queue:in(Elem, Q) end, queue:new(), List).

pop(Q) ->
    case queue:out(Q) of
        {{value, Value}, Q2} -> {ok, Value, Q2};
        {empty, _} -> {error, empty}
    end.

peek(Q) ->
    case queue:peek(Q) of
        {value, Value} -> {ok, Value};
        empty -> {error, empty}
    end.

