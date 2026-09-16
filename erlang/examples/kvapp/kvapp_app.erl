%% ============================================================
%% kvapp_app —— 应用回调模块（-behaviour(application)）
%%
%% `.app` 文件里的 {mod, {kvapp_app, []}} 就是指向这里。
%% OTP 启动这个应用时会按顺序调：
%%   start/2        （必须——由它启动监督树，返回 {ok, Pid} | {ok, Pid, State}
%%                    | {error, Reason}）
%%   prep_stop/1    （可选——开始关闭之前调，可以在这里做落盘；返回值会成为 stop/1 的参数）
%%   stop/1         （必须——监督树已经关完了，这里只做收尾，不能假定还有活进程）
%%   config_change/3（可选——**只有发布升级（release upgrade）时才会被调**）
%%
%% 关于 config_change/3 —— 这条很容易误解，实测确认过：
%%   `application:set_env/3` **不会**触发它。OTP 源码里它唯一的调用点是
%%   application_controller:do_config_change/3，而那个函数只被
%%   application_controller:config_change/1 调用，后者只有 release_handler
%%   在做发布升级时才会走。完整流程是：
%%     release_handler 先把所有在跑应用的 env 拍一个「升级前」快照
%%       （application_controller:prep_config_change/0），
%%     再装载新的 .app / sys.config，
%%     然后调 application_controller:config_change(EnvBefore) 让每个应用自己比差异。
%%   对比时用的是 lists:sort 之后的 env 列表，所以三个参数里：
%%     Changed / New 是 [{Key, Value}]（已排序），
%%     Removed 只有**键名**（[Key]），没有值 —— 因为值已经不存在了。
%%   顺序搞反（先改配置再拍快照）就永远比不出差异，回调静默不执行。
%%   本仓库的 23-application.erl 用这两个（内部）函数把这条链路真的跑了一遍。
%%
%% start/2 的第一个参数 StartType 实际取值：
%%   normal    普通启动（application:start/1,2）
%%   {takeover, Node}   从另一个节点接管
%%   {failover, Node}   另一个节点挂了，本节点顶上
%% 单机程序里永远是 normal —— 所以本示例把它原样透传下去演示形状。
%% ============================================================
-module(kvapp_app).

-behaviour(application).

-export([start/2, prep_stop/1, stop/1, config_change/3]).

%% 返回 {ok, SupPid} 表示启动成功；监督树的所有者是应用主进程（application master），
%% 所以这里只要把监督树的 pid 交上去就行，不需要自己保存。
start(StartType, StartArgs) ->
    io:format("    [kvapp_app:start/2] StartType=~p StartArgs=~p~n",
              [StartType, StartArgs]),
    kvapp_sup:start_link().

%% prep_stop/1 在「开始关监督树之前」被调用，是**最后**能安全读写自己状态的机会。
%% 返回值会被原样交给 stop/1。
prep_stop(State) ->
    io:format("    [kvapp_app:prep_stop/1] 关闭前最后一刻，State=~p~n", [State]),
    State.

stop(_State) ->
    io:format("    [kvapp_app:stop/1] 监督树已经关完了，这里只能做收尾~n"),
    ok.

%% Changed / New / Removed 都是列表。
%% **实测**：set_env/3 不会调到这里（见文件头说明），只有发布升级会。
%% 所以本回调平时基本不会被执行 —— 但发布系统（reltool / relx）依赖它来热更新配置，
%% 真要做可热更新的系统就得实现。
config_change(Changed, New, Removed) ->
    io:format("    [kvapp_app:config_change/3] 被调到了：~n"),
    io:format("        Changed = ~p~n", [Changed]),
    io:format("        New     = ~p~n", [New]),
    io:format("        Removed = ~p~n", [Removed]),
    ok.
