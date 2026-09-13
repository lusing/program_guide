-module(e06_error_handling).
-export([safe_div/2, safe_apply/2]).

safe_div(_, 0) ->
    {error, divide_by_zero};
safe_div(A, B) ->
    {ok, A / B}.

safe_apply(Fun, Arg) when is_function(Fun, 1) ->
    try Fun(Arg) of
        Value -> {ok, Value}
    catch
        Class:Reason ->
            {error, {Class, Reason}}
    end.

