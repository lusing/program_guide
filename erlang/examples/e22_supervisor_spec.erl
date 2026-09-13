-module(e22_supervisor_spec).
-export([child_spec/3, simple_sup_spec/1]).

child_spec(Id, Mod, Args) ->
    #{
        id => Id,
        start => {Mod, start_link, Args},
        restart => permanent,
        shutdown => 5000,
        type => worker,
        modules => [Mod]
     }.

simple_sup_spec(Children) when is_list(Children) ->
    #{
        strategy => one_for_one,
        intensity => 5,
        period => 10,
        children => Children
     }.

