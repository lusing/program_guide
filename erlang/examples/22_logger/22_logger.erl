%% ---------------------------------------------------------------------------
%%  22_logger —— 日志（logger）与可观测性
%%
%%  编译：erlc -Werror -Wall -o build/22_logger examples/22_logger.erl
%%  运行：erl -noshell -pa build/22_logger -run '22_logger' main -s init stop
%%
%%  ⚠ 本章的实现方式说明（很重要）：
%%  日志是由 **handler 所在的另一个进程** 写出去的，它和本进程的 io:format
%%  之间没有顺序保证 —— 实测中同一份代码，日志行会插在 io:format 行的任意位置。
%%  为了让输出可复核，本章的每一轮演示都：
%%      1) 把日志写进 build/erl-demo-22/log.txt（logger_std_h 的 {file, Name}）
%%      2) logger_std_h:filesync/1 强制落盘
%%      3) file:read_file 读回来，再用 io:format 打印
%%  这样输出顺序完全确定；顺带也演示了「日志写文件」这个真实用法。
%% ---------------------------------------------------------------------------
-module('22_logger').

-include_lib("kernel/include/logger.hrl").

-export([main/0]).

-define(DIR, "build/erl-demo-22").
-define(LOGFILE, "build/erl-demo-22/log.txt").
-define(H, demo_h).

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).

main() ->
    io:format("=== 27) 日志（logger）与可观测性 ===~n"),
    reset(),
    %% 注意：第 3 节要读默认 handler 的配置，所以**先读再摘**。
    why_not_io_format(),
    the_pipeline(),
    default_config(),
    %% 摘掉默认 handler：它的默认模板带时间戳 + pid，会污染本示例的 stdout
    _ = logger:remove_handler(default),
    levels(),
    three_places_to_filter(),
    module_level_trap(),
    msg_shapes(),
    templates(),
    filters(),
    metadata_and_domain(),
    overload_protection(),
    mistakes(),
    cleanup(),
    io:format("==== 22 结束 ====~n"),
    ok.

reset() ->
    _ = file:del_dir_r(?DIR),
    ok = file:make_dir(?DIR),
    ok.

cleanup() ->
    logger:remove_handler(?H),
    ok = file:del_dir_r(?DIR),
    ok.

%% ---------------------------------------------------------------------------
%% 每一轮：换一套 handler 配置 → 打几条日志 → 落盘 → 读回来打印
%% ---------------------------------------------------------------------------
demo(Title, Cfg, Fun) ->
    _ = file:delete(?LOGFILE),
    _ = logger:remove_handler(?H),
    ok = logger:add_handler(?H, logger_std_h, Cfg),
    Fun(),
    ok = logger_std_h:filesync(?H),
    Content = case file:read_file(?LOGFILE) of
                  {ok, Bin} -> Bin;
                  {error, enoent} -> <<"    （一条都没写出去）\n">>
              end,
    io:format("~n  -- ~ts --~n", [Title]),
    io:format("~ts", [Content]),
    ok.

%% 默认配置：debug 以上全收，模板是「级别|消息」
cfg() ->
    #{level => debug,
      formatter => {logger_formatter, #{template => [level, <<"  ">>, msg, "\n"]}},
      config => #{type => {file, ?LOGFILE}}}.

%% 在默认配置上改一个键
with(Base, Key, Value) -> Base#{Key := Value}.
plus(Base, Key, Value) -> Base#{Key => Value}.

%% ---------------------------------------------------------------------------
%% 1) 为什么不用 io:format
%% ---------------------------------------------------------------------------
why_not_io_format() ->
    io:format("~n== 1) 为什么不用 io:format ==~n"),
    io:format("  io:format 打到的是\"当前进程的 group leader\"，"
              "它不知道\"级别\"这回事，也没法在运行时关掉一部分。~n"),
    io:format("  logger 的区别在于：日志**先过关卡再决定要不要写、写到哪、写成什么样**。~n"),
    d("日志是另一个进程写的（不是同步的）", true),
    d("  实测：同一份代码里 io:format 和 logger 的先后顺序不固定", true),
    d("  所以本示例把日志写进文件再读回来打印（见文件头说明）", true),
    ok.

%% ---------------------------------------------------------------------------
%% 2) 一条日志要过的关卡
%% ---------------------------------------------------------------------------
the_pipeline() ->
    io:format("~n== 2) 一条日志要过四道关 ==~n"),
    Steps =
     [{"1. 主级别 primary level", "全局总闸。默认是 notice —— 所以 info/debug 默认**不出来**"},
      {"2. 主过滤器 primary filters", "对所有 handler 生效；返回 stop 就到此为止"},
      {"3. 模块级别 module level", "按发起日志的模块单独调级别（只对 ?LOG_* 宏有效，见第 6 节）"},
      {"4. handler 级别 + handler 过滤器", "每个 handler 自己再筛一遍；可以有多个 handler 写不同地方"}],
    [begin
         io:format("  ~ts~n", [S]),
         io:format("      → ~ts~n", [D])
     end || {S, D} <- Steps],
    io:format("~n  任何一道关说\"不要\"，这条日志就消失了 —— 而且**不会报错**。~n"),
    ok.

%% ---------------------------------------------------------------------------
%% 3) 默认配置长什么样
%% ---------------------------------------------------------------------------
default_config() ->
    io:format("~n== 3) 默认配置（实测值） ==~n"),
    {ok, H} = logger:get_handler_config(default),
    d("get_handler_ids()", logger:get_handler_ids()),
    d("默认 handler 的 module", maps:get(module, H)),
    d("  它自己的 level", maps:get(level, H)),
    d("  输出目标 config.type", maps:get(type, maps:get(config, H))),
    d("  filter_default（过滤器不表态时的默认动作）", maps:get(filter_default, H)),
    d("  自带的三个过滤器", [Id || {Id, _} <- maps:get(filters, H)]),
    d("  默认 formatter 的配置",
      element(2, maps:get(formatter, H))),
    io:format("~n  -- 主配置 --~n"),
    P = logger:get_primary_config(),
    d("primary level（**默认是 notice**，不是 info）", maps:get(level, P)),
    d("primary 的 filter_default", maps:get(filter_default, P)),
    d("primary 的 filters", maps:get(filters, P)),
    io:format("~n  这就是为什么你刚装好 OTP、直接 logger:info 什么也看不到。~n"),
    ok.

%% ---------------------------------------------------------------------------
%% 4) 八个级别
%% ---------------------------------------------------------------------------
levels() ->
    io:format("~n== 4) 八个级别 ==~n"),
    ok = logger:set_primary_config(level, debug),
    demo("把 primary 降到 debug，全打一遍", cfg(), fun() ->
        logger:emergency("emergency 系统不可用了"),
        logger:alert("alert 必须立刻处理"),
        logger:critical("critical 关键故障"),
        logger:error("error 出错了"),
        logger:warning("warning 警告"),
        logger:notice("notice 注意"),
        logger:info("info 信息"),
        logger:debug("debug 调试")
    end),
    io:format("  严重度顺序用 logger:compare_levels/2 比较：~n"),
    d("compare_levels(error, debug)", logger:compare_levels(error, debug)),
    d("compare_levels(debug, error)", logger:compare_levels(debug, error)),
    d("compare_levels(notice, notice)", logger:compare_levels(notice, notice)),
    io:format("  gt = 前一个**更严重**，lt = 前一个更轻微，eq = 一样。~n"),
    ok.

%% ---------------------------------------------------------------------------
%% 5) 三处能设级别：primary / module / handler
%% ---------------------------------------------------------------------------
three_places_to_filter() ->
    io:format("~n== 5) 三处能设级别 ==~n"),
    ok = logger:set_primary_config(level, debug),

    demo("primary 抬回 notice（info/debug 全没了，handler 还是 debug）",
         cfg(), fun() ->
        ok = logger:set_primary_config(level, notice),
        logger:error("error 还在"),
        logger:info("info 被 primary 挡了"),
        logger:debug("debug 也被挡了"),
        ok = logger:set_primary_config(level, debug)
    end),

    demo("primary 放行、但 handler 抬到 error",
         with(cfg(), level, error), fun() ->
        logger:error("error 出来了"),
        logger:info("info 被 handler 挡了")
    end),
    io:format("  两道关是**串联**的：任何一处更严格，就按更严格的来。~n"),
    ok.

%% ---------------------------------------------------------------------------
%% 6) 模块级：只对 ?LOG_* 宏生效
%% ---------------------------------------------------------------------------
module_level_trap() ->
    io:format("~n== 6) 模块级别的坑：logger:info 不受它管 ==~n"),
    io:format("  set_module_level 靠日志事件里的 mfa 元数据判断\"是谁打的\"，~n"),
    io:format("  而 mfa 只有 ?LOG_* 宏才会塞进去。用 logger:info/1 直接调，它管不着。~n"),

    ok = logger:set_module_level(?MODULE, critical),
    demo("模块级设成 critical 之后", cfg(), fun() ->
        logger:info("logger:info —— 还是出来了（模块级没生效）"),
        log_with_macro(),
        logger:critical("critical 当然在")
    end),
    d("unset_module_level", logger:unset_module_level(?MODULE)),
    d("get_module_level（现在是空的）", logger:get_module_level()),
    ok.

%% 单独放在一个函数里，?LOG_INFO 宏才能带上清晰的 mfa
log_with_macro() ->
    ?LOG_INFO("?LOG_INFO —— 被模块级挡掉了").

%% ---------------------------------------------------------------------------
%% 7) msg 的三种形状
%% ---------------------------------------------------------------------------
msg_shapes() ->
    io:format("~n== 7) 日志事件的 msg 有三种形状 ==~n"),
    demo("三种写法", cfg(), fun() ->
        logger:info("纯字符串"),
        logger:info("带参数 ~p 和 ~p", [1, two]),
        logger:info(#{what => happened, count => 3})
    end),
    io:format("  内部表示分别是：~n"),
    io:format("    {string, \"纯字符串\"}        —— 直接给的字符串~n"),
    io:format("    {\"带参数 ~~p 和 ~~p\", [1,two]} —— 格式串 + 参数，格式化**推迟**到写的时候~n"),
    io:format("    {report, #{...}}           —— 结构化报告，按键排序输出~n"),
    io:format("  想自己写 filter 就必须三种都处理（第 9 节有例子）。~n"),
    ok.

%% ---------------------------------------------------------------------------
%% 8) 格式化模板
%% ---------------------------------------------------------------------------
templates() ->
    io:format("~n== 8) 用 template 控制长什么样 ==~n"),
    demo("level + mfa + msg", with(cfg(), formatter,
        {logger_formatter, #{template => [level, <<" ">>, mfa, <<" ">>, msg, "\n"]}}),
        fun() -> log_with_macro() end),
    demo("level + domain + msg", with(cfg(), formatter,
        {logger_formatter, #{template => [level, <<" ">>, domain, <<" ">>, msg, "\n"]}}),
        fun() ->
            logger:info("没设 domain"),
            logger:log(info, "设了 [myapp,db]", #{domain => [myapp, db]})
        end),
    d("模板里能放的字段（实测可用）",
      [level, msg, mfa, domain, time, date, pid, gl, file, line, report_cb]),
    io:format("  time / pid 会让输出**每次都不一样**"
              "（本示例故意没把它们放进模板）。~n"),
    demo("模板里直接写字符串字面量（可以）",
         with(cfg(), formatter,
              {logger_formatter, #{template => ["[x] ", msg, "\n"]}}),
         fun() -> logger:info("字面量演示") end),
    io:format("  但如果用 ++ 把字面量和 msg **拼平成一个列表**，"
              "里面就会混进整数和原子，模板就不认识了：~n"),
    Bad = logger:add_handler(bad_h, logger_std_h,
              #{level => debug,
                formatter => {logger_formatter, #{template => "[ERR] " ++ [msg, "\n"]}},
                config => #{type => {file, ?LOGFILE}}}),
    d("用 ++ 拼平的模板",
      case Bad of
          {error, {Tag, Mod, _Tpl}} -> {error, Tag, Mod};
          Other -> Other
      end),
    _ = logger:remove_handler(bad_h),
    io:format("  正确写法是列表里一项一项写：[\"[ERR] \", msg, \"\\n\"] "
              "（binary <<\"[ERR] \">> 也行）。~n"),
    ok.

%% ---------------------------------------------------------------------------
%% 9) 过滤器
%% ---------------------------------------------------------------------------
filters() ->
    io:format("~n== 9) 过滤器：stop 才丢，ignore 只是\"不表态\" ==~n"),
    io:format("  过滤器函数返回三种值：~n"),
    io:format("    返回 LogEvent  → 继续（可以顺手改字段）~n"),
    io:format("    返回 ignore    → 这个过滤器不表态，交给后面的过滤器和 filter_default~n"),
    io:format("    返回 stop      → **丢掉**这条日志~n"),
    ok = logger:set_primary_config(level, debug),

    DropFun = fun(#{msg := M} = E, _Extra) ->
        Text = msg_to_text(M),
        case string:find(Text, "丢弃") of
            nomatch -> E;
            _ -> stop
        end
    end,
    demo("挡掉正文里含\"丢弃\"的", plus(cfg(), filters, [{drop_it, {DropFun, ok}}]), fun() ->
        logger:info("这条正常"),
        logger:info("这条要被丢弃"),
        logger:info("带参数的也会被丢弃 ~p", [here])
    end),

    demo("ignore 不表态 —— 日志照常出来",
         plus(cfg(), filters, [{shrug, {fun(_, _) -> ignore end, ok}}]), fun() ->
        logger:info("过滤器 ignore，我还在")
    end),

    demo("过滤器能改事件（把 info 提级成 critical）",
         plus(cfg(), filters, [{up, {fun(E, _) -> E#{level := critical} end, ok}}]), fun() ->
        logger:info("我本来是 info")
    end),

    demo("primary filter 对所有 handler 生效", cfg(), fun() ->
        ok = logger:add_primary_filter(mute, {fun(_, _) -> stop end, ok}),
        logger:info("被主过滤器挡了"),
        ok = logger:remove_primary_filter(mute),
        logger:info("删掉之后又出来了")
    end),
    ok.

%% 把三种 msg 形状统一转成文本（写 filter 时的标准做法）
msg_to_text({string, S}) -> S;
msg_to_text({report, R}) -> lists:flatten(io_lib:format("~p", [R]));
msg_to_text({Fmt, Args}) when is_list(Fmt) -> lists:flatten(io_lib:format(Fmt, Args)).

%% ---------------------------------------------------------------------------
%% 10) metadata 与 domain
%% ---------------------------------------------------------------------------
metadata_and_domain() ->
    io:format("~n== 10) 结构化日志：metadata 与 domain ==~n"),
    demo("把请求 id 打进日志", with(cfg(), formatter,
        {logger_formatter, #{template => [level, <<" [">>, request_id, <<"] ">>, msg, "\n"]}}),
        fun() ->
            logger:log(info, "带 request_id", #{request_id => <<"r-42">>}),
            logger:log(info, "没有 request_id", #{})
        end),
    io:format("  metadata 里没有的字段，模板会输出**空字符串**而不是报错。~n"),
    d("primary 上也能挂全局 metadata（每条日志都带）",
      logger:update_primary_config(#{metadata => #{service => <<"demo">>}})),
    logger:update_primary_config(#{metadata => #{}}),
    ok.

%% ---------------------------------------------------------------------------
%% 11) 过载保护
%% ---------------------------------------------------------------------------
overload_protection() ->
    io:format("~n== 11) 过载保护：日志刷爆时不能拖垮业务 ==~n"),
    io:format("  logger handler 是**异步**的：调用方把事件丢给 handler 进程就返回了。~n"),
    io:format("  如果业务打日志的速度超过 handler 写得完的速度，队列就会无限涨。~n"),
    io:format("  OTP 内置三道闸（默认值，实测自 logger_std_h 的 config）：~n"),
    {ok, H} = logger:get_handler_config(?H),
    C = maps:get(config, H),
    d("sync_mode_qlen（队列超过这个数就转同步，调用方被迫等）",
      maps:get(sync_mode_qlen, C)),
    d("drop_mode_qlen（再超就**直接丢**日志，保命）",
      maps:get(drop_mode_qlen, C)),
    d("flush_qlen（丢模式下，队列降到这里就恢复）", maps:get(flush_qlen, C)),
    d("burst_limit_enable / max_count / window_time",
      {maps:get(burst_limit_enable, C),
       maps:get(burst_limit_max_count, C),
       maps:get(burst_limit_window_time, C)}),
    d("overload_kill_enable（极端情况直接把 handler 杀掉重启）",
      maps:get(overload_kill_enable, C)),
    io:format("~n  这些数不用背，记住两件事就够：~n"),
    io:format("    · 日志**真的会被丢**，所以别拿日志当业务数据；~n"),
    io:format("    · 慢速落盘（文件/网络）的 handler 要把 drop_mode_qlen 调小一点。~n"),
    ok.

%% ---------------------------------------------------------------------------
%% 12) 常见错误清单
%% ---------------------------------------------------------------------------
mistakes() ->
    io:format("~n== 12) 常见错误清单 ==~n"),
    Rows =
     [{"logger:info 什么都没打出来", "primary level 默认是 notice，info 被挡了",
       "logger:set_primary_config(level, info)，或在 sys.config 里配"},
      {"set_module_level 不生效", "模块级靠 mfa 元数据，logger:info 不带",
       "改用 ?LOG_INFO 等宏（include kernel/include/logger.hrl）"},
      {"过滤器返回 ignore 日志还在", "ignore = 不表态，不是丢弃",
       "要丢就返回 stop"},
      {"过滤器崩了，之后所有日志都出来了", "logger 会把出错的 filter 摘掉并报一条",
       "filter 必须处理 msg 的三种形状，别假设它是字符串"},
      {"日志行的顺序和 io:format 对不上", "日志由 handler 进程异步写",
       "别依赖两者的相对顺序；要复核就写文件再读回来"},
      {"日志输出里有 pid/时间戳，测试没法比对", "默认模板带了 time 和 pid",
       "自定义 template，把 time/pid 去掉"},
      {"在日志里拼大字符串", "字符串会先在调用方进程里拼好，代价留在业务进程",
       "用 logger:info(\"~p\", [X]) 或 report，格式化推迟到 handler"},
      {"把日志当审计/业务数据", "过载时日志会被丢（drop_mode_qlen）",
       "要可靠就走数据库/消息队列，别指望日志"},
      {"模板里写 \"[x] \", msg", "报 invalid_formatter_template",
       "模板里的字面量要写成 binary：<<\"[x] \">>"},
      {"直接 logger_disk_h 当 handler", "报 function_not_exported(logger_disk_h, log, 2)",
       "用 logger_std_h + config#{type => {file, Name}}"}],
    [begin
         io:format("  ~ts~n", [What]),
         io:format("      现象：~ts~n", [Sym]),
         io:format("      处理：~ts~n", [Fix])
     end || {What, Sym, Fix} <- Rows],
    ok.

