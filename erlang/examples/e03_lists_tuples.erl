-module(e03_lists_tuples).
-export([sum/1, first_two/1, demo/0]).

sum(List) when is_list(List) ->
    lists:sum(List).

first_two([A, B | _]) ->
    {A, B};
first_two(_) ->
    error.

demo() ->
    Total = sum([1, 2, 3, 4, 5]),
    Pair = first_two([x, y, z]),
    {Total, Pair}.

