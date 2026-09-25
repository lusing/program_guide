%% ============================================================
%% 28_dets_mnesia 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/28_dets_mnesia examples/28_dets_mnesia/*_tests.erl
%%   erl -noshell -pa build/28_dets_mnesia -eval "eunit:test('28_dets_mnesia_tests'), halt()."
%% ============================================================
-module('28_dets_mnesia_tests').

-include_lib("eunit/include/eunit.hrl").

test_file(Name) ->
    Dir = '28_dets_mnesia':sandbox(),
    ok = filelib:ensure_path(Dir),
    filename:join(Dir, Name).

dets_roundtrip_test() ->
    F = test_file("t_roundtrip.dets"),
    {ok, Ref} = dets:open_file(t_roundtrip, [{file, F}, {type, set}]),
    try
        ok = dets:insert(Ref, [{a, 1}, {b, 2}]),
        %% lookup 返回列表；条数看 size（no_items 是 undefined）
        ?assertEqual([{a, 1}], dets:lookup(Ref, a)),
        ?assertEqual([], dets:lookup(Ref, zzz)),
        ?assertEqual(2, dets:info(Ref, size)),
        ?assertEqual(undefined, dets:info(Ref, no_items))
    after
        dets:close(Ref)
    end.

dets_types_test() ->
    %% set 覆盖 / bag 去完全重复 / duplicate_bag 全保留
    Expect = [{set, [{k, 2}]},
              {bag, [{k, 1}, {k, 2}]},
              {duplicate_bag, [{k, 1}, {k, 1}, {k, 2}]}],
    lists:foreach(
      fun ({Type, Expected}) ->
              ?assertEqual(Expected, lists:sort(lookup_type(Type)))
      end, Expect).

lookup_type(Type) ->
    F = test_file(atom_to_list(Type) ++ "_t.dets"),
    _ = file:delete(F),                       %% dets 文件跨测试累积——先清
    {ok, Ref} = dets:open_file(list_to_atom("tt_" ++ atom_to_list(Type)),
                               [{file, F}, {type, Type}]),
    ok = dets:insert(Ref, [{k, 1}, {k, 1}, {k, 2}]),
    L = dets:lookup(Ref, k),
    dets:close(Ref),
    L.

dets_persistence_test() ->
    F = test_file("t_persist.dets"),
    _ = file:delete(F),
    {ok, Ref} = dets:open_file(t_persist, [{file, F}, {type, set}]),
    ok = dets:insert(Ref, {keep, <<" survives ">>}),
    ok = dets:close(Ref),
    {ok, Re} = dets:open_file(t_persist2, [{file, F}, {type, set}]),
    ?assertEqual([{keep, <<" survives ">>}], dets:lookup(Re, keep)),
    dets:close(Re).

dets_garbage_test() ->
    F = test_file("t_garbage.dets"),
    ok = file:write_file(F, <<"not a dets file">>),
    ?assertMatch({error, {not_a_dets_file, _}},
                 dets:open_file(t_garbage, [{file, F}, {type, set}])).

mnesia_txn_test() ->
    logger:remove_handler(default),   %% mnesia 启停的报告带时间戳
    Dir = filename:join('28_dets_mnesia':sandbox(), "t_mnesia"),
    _ = file:del_dir_r(Dir),          %% schema 目录也是跨测试残留
    ok = filelib:ensure_path(Dir),
    ok = application:set_env(mnesia, dir, Dir),
    ok = mnesia:create_schema([node()]),
    ok = mnesia:start(),
    try
        {atomic, ok} = mnesia:create_table(kv_t,
                                           [{ram_copies, [node()]},
                                            {attributes, [key, val]}]),
        Write = fun () -> mnesia:write({kv_t, a, 1}), mnesia:write({kv_t, b, 2}) end,
                ?assertEqual({atomic, ok}, mnesia:transaction(Write)),
                ?assertEqual([{kv_t, b, 2}], mnesia:dirty_read({kv_t, b})),
        %% abort 整体回滚
        Abort = fun () -> mnesia:write({kv_t, c, 3}), mnesia:abort(why) end,
                ?assertEqual({aborted, why}, mnesia:transaction(Abort)),
                ?assertEqual([], mnesia:dirty_read({kv_t, c})),
                %% 索引
        {atomic, ok} = mnesia:add_table_index(kv_t, val),
        ?assertEqual([{kv_t, a, 1}], mnesia:dirty_index_read(kv_t, 1, val))
    after
        stopped = mnesia:stop(),
        ok = mnesia:delete_schema([node()])
    end.
