-module(e15_proplists).
-export([get_timeout/1, merge_defaults/2, to_map/1]).

get_timeout(Props) ->
    proplists:get_value(timeout, Props, 5000).

merge_defaults(Props, Defaults) ->
    Merged = maps:merge(maps:from_list(Defaults), maps:from_list(Props)),
    maps:to_list(Merged).

to_map(Props) ->
    maps:from_list([{K, V} || {K, V} <- Props]).

