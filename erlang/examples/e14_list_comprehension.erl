-module(e14_list_comprehension).
-export([pythagorean/1, cartesian/2]).

pythagorean(Limit) when is_integer(Limit), Limit > 0 ->
    [{A, B, C}
     || A <- lists:seq(1, Limit),
        B <- lists:seq(A, Limit),
        C <- lists:seq(B, Limit),
        A * A + B * B =:= C * C].

cartesian(As, Bs) when is_list(As), is_list(Bs) ->
    [{A, B} || A <- As, B <- Bs].

