-module(e27_rand_demo).
-export([seeded_ints/2, pick_one/1]).

seeded_ints(Count, Max) when Count >= 0, Max > 0 ->
    _ = rand:seed(exsplus, {101, 202, 303}),
    [rand:uniform(Max) || _ <- lists:seq(1, Count)].

pick_one([]) ->
    {error, empty};
pick_one(List) ->
    _ = rand:seed(exsplus, {404, 505, 606}),
    Index = rand:uniform(length(List)),
    {ok, lists:nth(Index, List)}.

