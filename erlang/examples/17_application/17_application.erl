%% ============================================================
%% 17_application —— 应用（Application）：把一整棵进程树打包成一个可启动的单元
%%
%%    前面 15/16 章讲的是「怎么组织进程」。这一章讲的是**怎么把它们装起来**。
%%
%%    OTP 的组织层次是：
%%        进程  →  监督树  →  **应用**  →  节点  →  发布（release）
%%    「应用」处在中间：它是**部署、启动、停止、配置的最小单元**。
%%    一个应用 = 一棵进程树（顶层一个监督者）+ 一个 `.app` 资源文件。
%%
%%    这一章会真的启动 本目录里那个最小 OTP 应用：
%%        kvapp.app        资源文件（描述 + 配置 + 回调模块）
%%        kvapp_app.erl    应用回调（start/2 / prep_stop/1 / stop/1 / config_change/3）
%%        kvapp_sup.erl    顶层监督者
%%        kvapp_store.erl  真正干活的 gen_server
%%
%%    编译：
%%      erlc -Werror -Wall -o build/17_application examples/17_application/*.erl
%%      copy examples\17_application\kvapp.app build\17_application\     ← .app 不是代码，erlc 不认，要手工拷
%%    运行：
%%      erl -noshell -pa build/17_application -run '17_application' main -s init stop
%%
%%    注意：本示例在末尾会 unload 掉 kvapp，跑完环境是干净的。
%% ============================================================
-module('17_application').

-export([main/0]).

main() ->
    %% 默认的 logger handler 会把「error 级」的报告异步打到 stdout，
    %% 带时间戳和 pid → 输出不可重复。本示例只关心返回值和自己的打印。
    _ = logger:remove_handler(default),

    layers(),
    app_resource_file(),
    lifecycle(),
    app_env(),
    real_app(),
    dependencies(),
    inspect_state(),
    config_change_walkthrough(),
    pitfalls(),
    io:format("~n==== 17 结束 ====~n").

%% 1) 三层结构：进程 / 监督树 / 应用
%% ------------------------------------------------------------
layers() ->
    io:format("== 1) 三层结构 ==~n"),
    Rows = [{"进程", "spawn 出来的东西；不共享内存，只靠消息通信（13 章）"},
            {"监督树", "谁挂了由谁负责重启（16 章）；它是「一个应用」的内部结构"},
            {"应用", "本章的内容：一棵进程树 + 一个 .app 文件，"
                     "能被 application:start/1 整体拉起来"},
            {"节点", "一个 erl 虚拟机实例；节点上跑着若干个应用"},
            {"发布", "release：把若干应用 + 一个 ERTS 版本打包成可部署的目录"}],
    [begin
         io:format("  ~ts~n", [A]),
         io:format("      ~ts~n", [B])
     end || {A, B} <- Rows],
    io:format("~n  规则：**一个应用只应该有一个顶层监督者**（由它的 start/2 启动）。~n"),
    io:format("  应用之间的依赖写进 .app 的 applications 字段，交给 OTP 去管启动顺序；~n"),
    io:format("  不要在自己代码里手动去 start 别的应用的进程。~n"),
    ok.

%% 2) .app 资源文件的字段
%% ------------------------------------------------------------
%% 两种加载方式：
%%   (a) 代码路径上有 <应用名>.app 文件  →  application:load(kvapp)
%%   (b) 直接把 spec 当项交进去          →  application:load({application, N, Spec})
%%       —— 这种方式**不需要磁盘上有任何文件**，写测试时很好用。
app_resource_file() ->
    io:format("~n== 2) .app 资源文件的字段 ==~n"),
    InlineSpec = [{description, "inline demo app (no file on disk)"},
                  {vsn, "0.1.0"},
                  {modules, []},
                  {registered, []},
                  {applications, [kernel, stdlib]},
                  {env, [{answer, 42}]}],
    d("用元组形式 load（磁盘上没有这个文件）",
      application:load({application, inline_demo, InlineSpec})),
    d("get_key(vsn)", application:get_key(inline_demo, vsn)),
    d("get_key(env)", application:get_key(inline_demo, env)),
    d("get_key(applications)", application:get_key(inline_demo, applications)),
    d("没写 mod 字段时 get_key(mod)", application:get_key(inline_demo, mod)),
    io:format("~n"),
    %% get_key/2 找不到的键返回 undefined（不是报错），所以别直接 {ok,X} = 它
    d("get_key(随便一个不存在的键) 返回 undefined，不报错",
      application:get_key(inline_demo, this_key_does_not_exist)),
    d("重复 load 同一个应用", application:load({application, inline_demo, InlineSpec})),
    d("unload", application:unload(inline_demo)),
    d("unload 之后 get_key", application:get_key(inline_demo, vsn)),

    io:format("~n  -- 对照：磁盘上真实的 kvapp.app --~n"),
    ok = load_kvapp(),
    {ok, All} = application:get_all_key(kvapp),
    d("get_all_key 返回的字段总数", length(All)),
    show_atom_list("字段名（排序后每行 4 个）",
                   lists:sort([K || {K, _} <- All]), 4),
    io:format("~n  get_all_key 会把**你没写的字段补成默认值**——这是最容易忽略的一点：~n"),
    Defaults = [id, maxP, maxT, included_applications,
                optional_applications, start_phases],
    [io:format("      ~-24ts = ~p~n", [atom_to_list(K), V])
     || {K, V} <- All, lists:member(K, Defaults)],
    io:format("~n  （对比一下 kvapp.app 里实际写了的字段：description / vsn / modules /~n"),
    io:format("    registered / applications / mod / env —— 其余都是 OTP 补的）~n"),
    ok.

%% 3) 生命周期：load → start → stop → unload
%% ------------------------------------------------------------
%% 四个状态的严格顺序（每一步的返回值都实测过）：
%%
%%     （不存在）
%%        | application:load/1        成功 ok；文件找不到 {error,{"no such file or directory",F}}
%%        v
%%      loaded  ── application:start/1 ──>  started  ── application:stop/1 ──> loaded
%%        ^            （已在跑 -> {error,{already_started,A}}）      （没在跑 -> {error,{not_started,A}}）
%%        |                                                                  |
%%        +---------------- application:unload/1 <----------------------------+
%%                    （还在跑 -> {error,{running,A}}；成功 ok）
%%
%% 关键：**stop 不等于 unload**。stop 只是让进程树停下，配置和环境变量都还在；
%% unload 才把它从应用控制器里彻底摘掉（get_key 变 undefined）。
lifecycle() ->
    io:format("~n== 3) 生命周期 ==~n"),
    Name = 'lifecycle_demo',
    Spec = [{description, "lifecycle demo"},
            {vsn, "0.0.1"},
            {modules, []},
            {registered, []},
            {applications, [kernel, stdlib]},
            {env, [{k, v}]}],
    d("start 一个**从没 load 过**的应用",
      application:start(nosuch_app_xyz)),
    d("load", application:load({application, Name, Spec})),
    d("这时候 loaded_applications 里有它吗",
      lists:keymember(Name, 1, application:loaded_applications())),
    d("但 which_applications（只列运行中的）里有吗",
      lists:member(Name, [A || {A, _, _} <- application:which_applications()])),
    d("start（没有 mod 的「库应用」也能启动，直接返回 ok）",
      application:start(Name)),
    d("start 之后 which_applications 里有吗",
      lists:member(Name, [A || {A, _, _} <- application:which_applications()])),
    d("再 start 一次", application:start(Name)),
    d("还在跑的时候 unload", application:unload(Name)),
    d("stop", application:stop(Name)),
    d("再 stop 一次", application:stop(Name)),
    d("stop 之后 env 还能读吗（能——stop 不清配置）",
      application:get_env(Name, k)),
    d("unload", application:unload(Name)),
    d("unload 之后 env 还能读吗（不能了）", application:get_env(Name, k)),
    ok.

%% 4) 应用环境（application environment）
%% ------------------------------------------------------------
%% 这是「应用」这一层最日常的价值：把可变配置从代码里搬出去。
%% 三种覆盖方式（优先级从低到高）：
%%   1. .app 里的 env 字段            —— 默认值，写在代码库里
%%   2. sys.config / 命令行 -App Key Val  —— 部署时覆盖，不改代码
%%   3. application:set_env/3          —— 运行时改，**不会写回任何文件**
app_env() ->
    io:format("~n== 4) 应用环境（env）==~n"),
    d("get_env(kvapp, max_items) 读 .app 里的默认值",
      application:get_env(kvapp, max_items)),
    d("get_env(kvapp, greeting)", application:get_env(kvapp, greeting)),
    d("get_env(kvapp, 不存在的键) 返回 undefined",
      application:get_env(kvapp, nope)),
    d("所以推荐**永远用 get_env/3** 带一个兜底默认值",
      application:get_env(kvapp, nope, my_default)),

    io:format("~n  -- get_all_env/1 的顺序 --~n"),
    d("get_all_env(kvapp)（原样）", application:get_all_env(kvapp)),
    d("  排序后（.app 里写的是 greeting, max_items, store_mode；读出来是**反序**的，"
      "所以想稳定比较就先 sort）",
      lists:sort(application:get_all_env(kvapp))),

    io:format("~n  实测：set_env/3 对**没 load 过**的应用也返回 ok —— 它只是把值先存着。~n"),
    d("set_env(一个从没见过的应用, k, v)",
      application:set_env(never_loaded_app, k, v)),
    d("  而且这个值之后真能读到",
      application:get_env(never_loaded_app, k, missing)),
    d("  get_all_env/1 也读得到（env 是存在应用控制器里，不依赖应用文件）",
      application:get_all_env(never_loaded_app)),
    d("  但 get_key(App, env) 读不到（那个要应用已 load 的记录）",
      application:get_key(never_loaded_app, env)),
    d("unset_env 同样不报错", application:unset_env(never_loaded_app, k)),
    d("  unset 之后（.app 的默认值也不会恢复，就是 undefined）",
      application:get_env(never_loaded_app, k, missing)),

    io:format("~n"),
    d("set_env(kvapp, max_items, 7)", application:set_env(kvapp, max_items, 7)),
    d("  读回来", application:get_env(kvapp, max_items)),
    d("unset_env(kvapp, max_items)", application:unset_env(kvapp, max_items)),
    d("  unset 之后：.app 的默认值**不会**自动恢复，读到 undefined",
      application:get_env(kvapp, max_items)),
    d("  get_all_env 里这个键也确实没了",
      lists:sort(application:get_all_env(kvapp))),

    %% 恢复，后面几节还要用
    ok = application:set_env(kvapp, max_items, 100),
    d("  恢复 max_items=100（后面几节要用）", application:get_env(kvapp, max_items)),
    ok.

%% 5) 真的启动 kvapp：应用回调的顺序 + 关闭顺序
%% ------------------------------------------------------------
real_app() ->
    io:format("~n== 5) 真的启动 kvapp ==~n"),
    io:format("  下面 [kvapp_*] 开头的行来自应用自己的回调，其余是本示例打的。~n~n"),
    d("start(kvapp)  —— 注意它同步等待应用主进程起来，所以回调的打印会插在这一行前面",
      application:start(kvapp)),

    io:format("~n"),
    d("启动后可以直接用它的服务", kvapp_store:put(alpha, 1)),
    d("get(alpha)", kvapp_store:get(alpha)),
    d("init 时从 env 读到的容量（max_items=100, store_mode=memory）",
      kvapp_store:capacity()),
    d("监督树（剥掉 pid，因为每次运行都不同）",
      [{Id, Type, Mods} || {Id, _Pid, Type, Mods} <- supervisor:which_children(kvapp_sup)]),
    d("count_children（排序后）",
      lists:sort(supervisor:count_children(kvapp_sup))),
    d("从「一个进程的 pid」反查它属于哪个应用：get_application(store 的 pid)",
      application:get_application(whereis(kvapp_store))),
    d("顶层监督者：get_supervisor(kvapp) == {ok, whereis(kvapp_sup)}",
      application:get_supervisor(kvapp) =:= {ok, whereis(kvapp_sup)}),

    io:format("~n  -- env 是什么时候生效的？重启一次就知道 --~n"),
    d("把 max_items 改成 2", application:set_env(kvapp, max_items, 2)),
    d("  但当前这个 store 进程还是老值（它在 init/1 里读一次就定下来了）",
      kvapp_store:capacity()),
    d("stop", application:stop(kvapp)),
    d("  再 start（新进程会重新读 env）", application:start(kvapp)),
    d("  重启后的容量（已经变成 2 了）", kvapp_store:capacity()),
    io:format("~n  → 结论：env 是**进程启动时读一次**的快照，不是实时可变的。~n"),
    io:format("    想让它变，要么重启进程，要么自己监听、用 set_env 时通知进程。~n"),

    io:format("~n  -- 关闭顺序（上面那几行 [kvapp_*] 就是它打的）--~n"),
    io:format("    实测顺序是：~n"),
    io:format("      1. Mod:prep_stop/1               —— 开始关监督树之前，最后能读写自己状态的机会~n"),
    io:format("      2. 监督者关掉它的孩子            —— gen_server 的 terminate/2 在这里被调到~n"),
    io:format("      3. Mod:stop/1                    —— 树已经关完了，只能收尾~n"),
    d("stop 返回", application:stop(kvapp)),
    io:format("~n  **坑**：gen_server 默认 trap_exit = false，而监督者关闭孩子的方式是~n"),
    io:format("    exit(Child, shutdown)。不打开 trap_exit 的话这个信号直接把进程打死，~n"),
    io:format("    terminate/2 **根本不会被调用**（你在里面写的落盘/关表全部丢失）。~n"),
    io:format("    kvapp_store.erl 里那句 process_flag(trap_exit, true) 就是为这个加的。~n"),

    %% 恢复 max_items，后面还要用
    ok = application:set_env(kvapp, max_items, 100),
    ok.

%% 6) 依赖与 ensure_all_started
%% ------------------------------------------------------------
dependencies() ->
    io:format("~n== 6) 依赖与 ensure_all_started ==~n"),
    d("kvapp 声明的依赖（.app 的 applications 字段）",
      application:get_key(kvapp, applications)),
    d("ensure_all_started(kvapp) 返回**这次真正启动了哪些应用**，按依赖顺序",
      application:ensure_all_started(kvapp)),
    d("已经有了，再 ensure 一次（什么都不用做 → 空列表）",
      application:ensure_all_started(kvapp)),
    d("但 start/1 不管依赖，也不会替你判断已启动，直接报错",
      application:start(kvapp)),
    d("运行中的应用（排序后；只列 running）",
      lists:sort([A || {A, _, _} <- application:which_applications()])),
    io:format("~n  → 什么时候用哪个：~n"),
    io:format("      · 启动：**ensure_all_started/1**（返回 {ok, [这次启动的应用]})~n"),
    io:format("      · 停止：stop/1（它**不会**反向停依赖；要停依赖得自己一个个来）~n"),
    io:format("      · 兜底写法：ensure_all_started 幂等，重复调不会报错~n"),
    d("stop", application:stop(kvapp)),
    ok.

%% 7) 查询应用状态
%% ------------------------------------------------------------
inspect_state() ->
    io:format("~n== 7) 查询状态 ==~n"),
    Desc = element(2, application:get_key(kvapp, description)),
    io:format("  which_applications/0 的元素形状是 {应用名, 描述, 版本}；描述长这样：~n"),
    io:format("      ~ts~n", [Desc]),
    d("  版本 get_key(kvapp, vsn)", application:get_key(kvapp, vsn)),
    d("which_applications/0 里运行中的应用名（排序后）",
      lists:sort([A || {A, _, _} <- application:which_applications()])),
    d("which_applications/1 支持超时参数（毫秒），避免应用控制器卡住时死等；"
      "结果与 /0 相同",
      application:which_applications(5000) =:= application:which_applications()),
    d("loaded_applications/0 里已加载的（不一定在跑）",
      lists:sort([A || {A, _, _} <- application:loaded_applications()])),
    io:format("~n"),
    %% application:info/0 里全是机器相关的路径和名字，只打键名
    show_atom_list("application:info/0 的键（排序后——值里有本机路径，不打）",
                   lists:sort([K || {K, _} <- application:info()]), 3),

    io:format("~n  -- 几个容易想当然的 API --~n"),
    d("application:app_dir/1 **不存在**（function_exported = false）",
      erlang:function_exported(application, app_dir, 1)),
    io:format("      要应用的目录用 code:lib_dir(App)，而且只对标准的 lib/<app>-<vsn>/ 布局有效~n"),
    d("  本仓库把 .app 放在 build/ebin/，不是标准布局，所以 code:lib_dir(kvapp)",
      code:lib_dir(kvapp)),
    d("application:start_type/0 返回**调用进程所属**应用的启动方式；"
      "-run 起来的进程不属于任何应用",
      application:start_type()),
    d("application:get_all_env/0 同理（只列调用进程所属应用的 env）",
      application:get_all_env()),
    d("application:get_env/0、get_key/0 **不存在**（最少是 /1）",
      {erlang:function_exported(application, get_env, 0),
       erlang:function_exported(application, get_key, 0)}),
    ok.

%% 8) config_change/3：只有发布升级才会走的那条路
%% ------------------------------------------------------------
%% 这一节是本章最容易被误解的地方。实测结论：
%%   application:set_env/3 **不会**触发 config_change/3。
%% 读 OTP 源码（kernel-11.0.3/src/application_controller.erl）可以看到，
%% config_change/3 唯一的调用点是 do_config_change/3，而它只被
%% application_controller:config_change/1 调用 —— 只有 release_handler
%% 在做**发布升级**时才会走这条路。完整链路是：
%%
%%     1. release_handler 先给所有在跑应用的 env 拍一张「升级前」快照
%%          application_controller:prep_config_change/0
%%     2. 装载新的 .app / sys.config（于是 env 变了）
%%     3. application_controller:config_change(EnvBefore)
%%          → 对每个应用算 diff → 有变化才调 Mod:config_change(Changed, New, Removed)
%%
%% 顺序不能反：先改配置再拍快照，diff 永远是空的，回调静默不执行。
%% 下面这两个函数是导出但标记为内部的（-moduledoc false），
%% 这里只是**为了让这条链路可见**才直接调用；真实系统里由 release_handler 调。
%% 三个参数里 Removed 只有**键名**（值已经不存在了）。
config_change_walkthrough() ->
    io:format("~n== 8) config_change/3：发布升级才会走的路 ==~n"),
    %% 先把 env 摆回已知状态，这样下面的 diff 可预期
    ok = application:set_env(kvapp, greeting, "hello from kvapp.app"),
    ok = application:set_env(kvapp, max_items, 100),
    ok = application:set_env(kvapp, store_mode, memory),
    ok = application:start(kvapp),

    EnvBefore = application_controller:prep_config_change(),
    d("1. 先拍「升级前」快照：覆盖了当前所有在跑的应用",
      length(EnvBefore) =:= length(application:which_applications())),
    d("2. 模拟装载新配置：改一个已有键", application:set_env(kvapp, greeting, "hello v2")),
    d("   加一个全新键", application:set_env(kvapp, brand_new, 42)),
    d("   删掉一个键", application:unset_env(kvapp, max_items)),
    io:format("~n  3. 调 application_controller:config_change(EnvBefore)，"
              "下面这行就是 kvapp_app:config_change/3 打的：~n"),
    d("   config_change/1 返回", application_controller:config_change(EnvBefore)),
    io:format("~n  注意 Removed 只有键名 [max_items]，没有值 —— 值已经不存在了。~n"),
    io:format("  三个列表都是排序过的（源码里 do_config_diff 前先 lists:sort）。~n"),

    d("stop", application:stop(kvapp)),
    d("unload（跑完把环境收干净）", application:unload(kvapp)),
    ok.

%% 9) 常见错误与建议
%% ------------------------------------------------------------
pitfalls() ->
    io:format("~n== 9) 常见错误与建议 ==~n"),
    Rows =
        [{"忘了把 <应用>.app 拷到代码路径",
          "application:load 报 {error,{\"no such file or directory\",\"x.app\"}}。"
          "erlc 只编 .erl，.app 是数据文件，构建脚本里必须显式拷（见 build.ps1）"},
         {"把 start/1 当成「启动我要的一切」",
          "它不管依赖，也不判断是否已在跑。用 ensure_all_started/1"},
         {"用 stop/1 后以为配置没了",
          "stop 只停进程树；env 还在，get_key 也还在。彻底摘掉要用 unload/1"},
         {"运行中 unload",
          "报 {error,{running,App}}。必须先 stop"},
         {"以为 set_env 会写回 .app 或 sys.config",
          "不会，只改内存里的应用控制器状态；重启节点就丢"},
         {"以为 set_env 会让已经在跑的进程立刻看到新配置",
          "不会。env 是进程 init 时读一次的快照"},
         {"把 config_change/3 当成 set_env 的回调",
          "不是。它只在发布升级时被调（见第 8 节）"},
         {"gen_server 里写了 terminate/2 却没打开 trap_exit",
          "监督者关闭孩子用 exit(Child, shutdown)，进程直接被打死，terminate/2 不执行"},
         {"在 start/2 里手动去 start 别的应用的进程",
          "依赖关系写进 .app 的 applications 字段，让 OTP 按顺序启动"},
         {"一个应用开多个顶层监督者",
          "不应该。应用只有一个顶层监督者，多个「子树」挂在它下面"}],
    [begin
         io:format("  ~ts~n", [A]),
         io:format("      → ~ts~n", [B])
     end || {A, B} <- Rows],
    ok.

%% ============================================================
%% 辅助
%% ============================================================

%% kvapp.app 必须躺在代码路径上；没有就直说怎么修，别让它以一个看不懂的 badmatch 崩掉。
load_kvapp() ->
    case application:load(kvapp) of
        ok -> ok;
        {error, {already_loaded, kvapp}} -> ok;
        {error, Reason} ->
            io:format("~n找不到 kvapp.app（~p）。~n"
                      "请先运行 pwsh ./build.ps1 —— 它会把 examples/17_application/*.app 拷到 build/17_application/。~n",
                      [Reason]),
            halt(1)
    end.

%% ~p 会把可打印的字符列表打成字符串；想按列表看数用 ~w
d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).

%% 一个长列表用 ~p 打印会被自动折行得很难看；~ts 不折行。
%% 这里自己切成每行 N 个。
show_atom_list(Label, Atoms, PerLine) ->
    Strs = [atom_to_list(A) || A <- Atoms],
    io:format("  ~ts~n", [Label]),
    [io:format("      ~ts~n", [lists:join(", ", C)]) || C <- chunk(Strs, PerLine)],
    ok.

chunk([], _) -> [];
chunk(L, N) ->
    {H, T} = lists:split(min(N, length(L)), L),
    [H | chunk(T, N)].

