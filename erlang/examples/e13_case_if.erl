-module(e13_case_if).
-export([classify/1, abs_value/1]).

classify(N) when is_integer(N) ->
    case N of
        X when X < 0 -> negative;
        0 -> zero;
        _ -> positive
    end.

abs_value(N) when is_number(N) ->
    if
        N < 0 -> -N;
        true -> N
    end.

