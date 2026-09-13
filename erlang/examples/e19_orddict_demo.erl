-module(e19_orddict_demo).
-export([from_list/1, put/3, get/2]).

from_list(Pairs) ->
    lists:foldl(fun({K, V}, Acc) -> orddict:store(K, V, Acc) end, orddict:new(), Pairs).

put(Key, Value, Dict) ->
    orddict:store(Key, Value, Dict).

get(Key, Dict) ->
    case orddict:find(Key, Dict) of
        {ok, Value} -> {ok, Value};
        error -> {error, not_found}
    end.

