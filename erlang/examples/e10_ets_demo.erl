-module(e10_ets_demo).
-export([run/0]).

run() ->
    Tab = ets:new(score_tab, [set, public]),
    true = ets:insert(Tab, {alice, 100}),
    true = ets:insert(Tab, {bob, 95}),
    [{alice, AliceScore}] = ets:lookup(Tab, alice),
    All = ets:tab2list(Tab),
    ets:delete(Tab),
    #{alice => AliceScore, all => All}.

