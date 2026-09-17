%% ============================================================
%% 17_application 的 EUnit 测试（围绕 kvapp 的生命周期）
%%
%%   erlc -Werror -Wall -o build/17_application examples/17_application/*_tests.erl
%%   erl -noshell -pa build/17_application -eval "eunit:test('17_application_tests'), halt()."
%%
%% kvapp 是全局注册名单例（kvapp_sup / kvapp_store），测试串行跑，
%% 每个用例自己 start/stop，环境干净。
%% ============================================================
-module('17_application_tests').

-include_lib("eunit/include/eunit.hrl").

kvapp_up() ->
    _ = logger:remove_handler(default),
    {ok, _} = application:ensure_all_started(kvapp).

kvapp_down() ->
    ok = application:stop(kvapp).

%% load 已加载不算错（ensure_all_started 会留下 loaded 状态）
ensure_loaded() ->
    case application:load(kvapp) of
        ok -> ok;
        {error, {already_loaded, kvapp}} -> ok
    end.

lifecycle_test() ->
    kvapp_up(),
    %% 启动后服务可用
    ok = kvapp_store:put(alpha, 1),
    ?assertEqual({ok, 1}, kvapp_store:get(alpha)),
    ?assertEqual(1, kvapp_store:count()),
    %% 监督树形状（剥 pid）
    ?assertEqual([{kvapp_store, worker, [kvapp_store]}],
                 [{Id, Type, Mods} || {Id, _Pid, Type, Mods}
                                         <- supervisor:which_children(kvapp_sup)]),
    %% 顶层监督者反查
    ?assertEqual({ok, whereis(kvapp_sup)}, application:get_supervisor(kvapp)),
    kvapp_down().

ensure_all_started_idempotent_test() ->
    kvapp_up(),
    ?assertMatch({ok, Apps} when is_list(Apps) andalso length(Apps) >= 0,
                 application:ensure_all_started(kvapp)),
    %% start/1 不管"已在跑"——直接报 already_started
    ?assertMatch({error, {already_started, kvapp}},
                 application:start(kvapp)),
    kvapp_down().

env_is_init_snapshot_test() ->
    ok = ensure_loaded(),
    _ = application:set_env(kvapp, max_items, 100),
    kvapp_up(),
    %% capacity 返回 {容量, 存储模式}——init 时从 env 读一次的快照
    ?assertEqual({100, memory}, kvapp_store:capacity()),
    %% set_env 改了配置，但运行中的进程读的是 init 时的快照
    ok = application:set_env(kvapp, max_items, 2),
    ?assertEqual({100, memory}, kvapp_store:capacity()),
    %% 重启后新进程重新读 env（application:start 返回 ok，不是 {ok,Pid}）
    ok = application:stop(kvapp),
    ok = application:start(kvapp),
    ?assertEqual({2, memory}, kvapp_store:capacity()),
    ok = application:set_env(kvapp, max_items, 100),
    kvapp_down().

stop_keeps_env_test() ->
    ok = ensure_loaded(),
    _ = application:set_env(kvapp, max_items, 100),
    kvapp_up(),
    kvapp_down(),
    %% stop 只停进程树：env 还在，get_key 也还在
    ?assertEqual({ok, 100}, application:get_env(kvapp, max_items)),
    ?assertMatch({ok, _}, application:get_key(kvapp, vsn)),
    %% 彻底摘掉要 unload；之后 get_env 变 undefined
    ok = application:unload(kvapp),
    ?assertEqual(undefined, application:get_env(kvapp, max_items)).

capacity_limit_test() ->
    ok = ensure_loaded(),
    _ = application:set_env(kvapp, max_items, 2),
    kvapp_up(),
    ok = kvapp_store:put(k1, 1),
    ok = kvapp_store:put(k2, 2),
    %% 容量满：init 里读的 max_items=2，第三个被拒
    ?assertEqual({error, full}, kvapp_store:put(k3, 3)),
    ok = application:set_env(kvapp, max_items, 100),
    kvapp_down().

