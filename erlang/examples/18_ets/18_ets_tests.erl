%% ============================================================
%% 18_ets 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/18_ets examples/18_ets/*_tests.erl
%%   erl -noshell -pa build/18_ets -eval "eunit:test('18_ets_tests'), halt()."
%% ============================================================
-module('18_ets_tests').

-include_lib("eunit/include/eunit.hrl").

new_table() -> ets:new(t, [set, public]).

basic_ops_test() ->
    T = new_table(),
    ?assertEqual(true, ets:insert(T, {a, 1})),   %% insert 返回 true
    ?assertEqual([{a, 1}], ets:lookup(T, a)),
    %% lookup 不存在的键：空列表，不报错（与 maps:find 不同）
    ?assertEqual([], ets:lookup(T, zzz)),
    %% set 语义：同键 insert 覆盖
    ets:insert(T, {a, 999}),
    ?assertEqual([{a, 999}], ets:lookup(T, a)),
    %% 计数用 ets:info(T, size)——ets:size/1 不存在
    ?assertEqual(1, ets:info(T, size)),
    true = ets:delete(T).

four_types_test() ->
    %% set/ordered_set 同键覆盖（最后写入者胜）；bag 去完全重复；duplicate_bag 全保留
    [{set, [{k, 1}]},
     {ordered_set, [{k, 1}]},
     {bag, [{k, 1}, {k, 2}]},
     {duplicate_bag, [{k, 1}, {k, 1}, {k, 2}]}] =
        [{Type, lists:sort(lookup(Type))}
         || Type <- [set, ordered_set, bag, duplicate_bag]],
    %% bag 去完全相同的重复项，duplicate_bag 不去
    T1 = ets:new(t, [bag, public]), ets:insert(T1, [{k, 1}, {k, 1}]),
    ?assertEqual([{k, 1}], lists:sort(ets:lookup(T1, k))),
    true = ets:delete(T1).

lookup(Type) ->
    T = ets:new(t, [Type, public]),
    ets:insert(T, [{k, 1}, {k, 2}, {k, 1}]),
    L = ets:lookup(T, k),
    true = ets:delete(T),
    L.

match_vs_match_object_test() ->
    T = new_table(),
    ets:insert(T, [{a, 1}, {b, 2}]),
    %% match 返回**变量绑定列表**：'$1' 绑到键 → [[b]]；无变量时是 [[]]
    ?assertEqual([[b]], ets:match(T, {'$1', 2})),
    ?assertEqual([[]], ets:match(T, {'_', 2})),
    %% match_object 返回**对象本身**
    ?assertEqual([{b, 2}], ets:match_object(T, {'_', 2})),
    ?assertEqual([1, 2], lists:sort(lists:flatten(ets:match(T, {'_', '$1'})))),
    true = ets:delete(T).

select_body_forms_test() ->
    T = ets:new(t, [ordered_set, public]),
    ets:insert(T, [{a, 1}, {b, 5}]),
    %% guard 里 '>' 是字面量原子
    ?assertEqual([{b, 5}],
                 ets:select(T, [{{'$1', '$2'}, [{'>', '$2', 1}], [{{'$1', '$2'}}]}])),
    %% body 是表达式列表：['$2'] 拿值
    ?assertEqual([1, 5], ets:select(T, [{{'$1', '$2'}, [], ['$2']}])),
    %% 单元素元组 body 会被当 action → badarg
    ?assertException(error, _, ets:select(T, [{{'$1', '$2'}, [], [{'$2'}]}])),
    true = ets:delete(T).

update_counter_test() ->
    T = new_table(),
    ets:insert(T, {hits, 10}),
    ?assertEqual(11, ets:update_counter(T, hits, 1)),
    ?assertEqual(9, ets:update_counter(T, hits, -2)),
    %% {Pos, Incr, Threshold, SetValue}：自增结果 >= 门槛则重置为 SetValue
    ets:insert(T, {hits, 95}),
    ?assertEqual(100, ets:update_counter(T, hits, {2, 10, 100, 100})),
    ?assertEqual([{hits, 100}], ets:lookup(T, hits)),
    true = ets:delete(T).

owner_death_kills_table_test() ->
    _ = logger:remove_handler(default),
    Self = self(),
    %% 不带 heir：owner 一死表就没了
    {P, MRef} = spawn_monitor(fun() ->
                                      _ = ets:new(no_heir_tab, [named_table, public]),
                                      Self ! ready,
                                      receive stop -> ok end
                              end),
    receive ready -> ok after 2000 -> ok end,
    exit(P, kill),
    receive {'DOWN', MRef, process, _, _} -> ok after 2000 -> ok end,
    ?assertEqual(undefined, ets:info(no_heir_tab)).

heir_receives_table_test() ->
    _ = logger:remove_handler(default),
    Self = self(),
    {P, MRef} = spawn_monitor(fun() ->
                                      _ = ets:new(heir_tab, [named_table, public,
                                                             {heir, Self, data}]),
                                      Self ! ready2,
                                      receive stop -> ok end
                              end),
    receive ready2 -> ok after 2000 -> ok end,
    exit(P, kill),
    receive {'DOWN', MRef, process, _, _} -> ok after 2000 -> ok end,
    %% heir 收到 ETS-TRANSFER，表活下来了
    ?assertMatch({'ETS-TRANSFER', _, _, data},
                 receive M = {'ETS-TRANSFER', _, _, _} -> M after 2000 -> timeout end),
    ?assertNotEqual(undefined, ets:info(heir_tab)),
    true = ets:delete(heir_tab).

option_shapes_test() ->
    %% 裸原子开关 vs {键,值} 对；写混是运行期 badarg
    ?assertMatch([_|_], begin T = ets:new(t, [set, compressed, public]),
                            true = ets:delete(T), [ok] end),
    ?assertException(error, _, ets:new(t, [set, {compressed, true}])),
    ?assertException(error, _, ets:new(t, [set, {named_table, true}])).
