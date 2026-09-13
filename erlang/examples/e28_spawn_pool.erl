-module(e28_spawn_pool).
-export([pmap/2]).

pmap(Fun, List) when is_function(Fun, 1), is_list(List) ->
    Parent = self(),
    RefIndexPairs =
        [begin
             Ref = make_ref(),
             spawn(fun() -> Parent ! {Ref, Fun(X)} end),
             {Ref, I}
         end
         || {I, X} <- lists:zip(lists:seq(1, length(List)), List)],
    gather(RefIndexPairs, #{}).

gather([], AccMap) ->
    [V || {_I, V} <- lists:keysort(1, maps:to_list(AccMap))];
gather(RefIndexPairs, AccMap) ->
    receive
        {Ref, Value} ->
            case lists:keyfind(Ref, 1, RefIndexPairs) of
                {Ref, Index} ->
                    gather(lists:keydelete(Ref, 1, RefIndexPairs), maps:put(Index, Value, AccMap));
                false ->
                    gather(RefIndexPairs, AccMap)
            end
    end.
