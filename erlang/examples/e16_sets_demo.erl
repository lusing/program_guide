-module(e16_sets_demo).
-export([new_from_list/1, union/2, contains/2]).

new_from_list(List) ->
    sets:from_list(List).

union(A, B) ->
    sets:to_list(sets:union(sets:from_list(A), sets:from_list(B))).

contains(SetList, Value) ->
    sets:is_element(Value, sets:from_list(SetList)).

