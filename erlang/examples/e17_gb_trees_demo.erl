-module(e17_gb_trees_demo).
-export([new/0, put/3, find/2, to_list/1]).

new() ->
    gb_trees:empty().

put(Key, Value, Tree) ->
    gb_trees:enter(Key, Value, Tree).

find(Key, Tree) ->
    case gb_trees:lookup(Key, Tree) of
        {value, Value} -> {ok, Value};
        none -> {error, not_found}
    end.

to_list(Tree) ->
    gb_trees:to_list(Tree).

