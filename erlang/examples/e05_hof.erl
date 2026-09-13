-module(e05_hof).
-export([square_all/1, even_only/1, sum_of_squares/1]).

square_all(List) ->
    lists:map(fun(X) -> X * X end, List).

even_only(List) ->
    lists:filter(fun(X) -> X rem 2 =:= 0 end, List).

sum_of_squares(List) ->
    lists:foldl(fun(X, Acc) -> X * X + Acc end, 0, List).

