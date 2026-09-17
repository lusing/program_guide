%% ============================================================
%% 22_logger 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/22_logger examples/22_logger/*_tests.erl
%%   erl -noshell -pa build/22_logger -eval "eunit:test('22_logger_tests'), halt()."
%%
%% 日志由 handler 进程**异步**写——测试先落盘（filesync）再读回来断言。
%% 断言一律用 ASCII 消息（中文断言在 Windows 控制台输出下有编码怪象）。
%% ============================================================
-module('22_logger_tests').

-include_lib("kernel/include/logger.hrl").
-include_lib("eunit/include/eunit.hrl").

-define(LOG, "build/eunit-22-log.txt").
-define(H, eunit_h).

setup(Level) ->
    _ = logger:remove_handler(?H),
    _ = file:delete(?LOG),
    _ = logger:remove_handler(default),
    ok = logger:set_primary_config(level, debug),
    ok = logger:add_handler(?H, logger_std_h,
           #{level => Level,
             formatter => {logger_formatter, #{template => [level, <<" ">>, msg, "\n"]}},
             config => #{type => {file, ?LOG}}}).

read_log() ->
    ok = logger_std_h:filesync(?H),
    case file:read_file(?LOG) of
        {ok, Bin} -> binary:split(Bin, <<"\n">>, [global, trim_all]);
        {error, enoent} -> []
    end.

teardown() ->
    _ = logger:remove_handler(?H),
    _ = file:delete(?LOG),
    ok.

levels_filter_test() ->
    setup(debug),
    logger:error("e"), logger:info("i"), logger:debug("d"),
    ?assertEqual([<<"error e">>, <<"info i">>, <<"debug d">>], read_log()),
    %% handler 抬到 error：info/debug 被挡（两道关串联，取更严的）
    setup(error),
    logger:error("e"), logger:info("i"),
    ?assertEqual([<<"error e">>], read_log()),
    teardown().

primary_level_gates_all_test() ->
    setup(debug),
    %% primary 抬到 notice：info/debug 全没了（默认就是 notice！）
    ok = logger:set_primary_config(level, notice),
    logger:error("e"), logger:info("i"),
    ?assertEqual([<<"error e">>], read_log()),
    ok = logger:set_primary_config(level, debug),
    teardown().

compare_levels_test() ->
    ?assertEqual(gt, logger:compare_levels(error, debug)),
    ?assertEqual(lt, logger:compare_levels(debug, error)),
    ?assertEqual(eq, logger:compare_levels(notice, notice)).

module_level_only_for_macros_test() ->
    setup(debug),
    %% 模块级只对 ?LOG_* 宏生效（宏才带 mfa 元数据）
    ok = logger:set_module_level(?MODULE, critical),
    logger:info("plain call is NOT gated by module level"),
    macro_info("macro call IS gated"),
    ?assertEqual([<<"info plain call is NOT gated by module level">>], read_log()),
    ok = logger:unset_module_level(?MODULE),
    teardown().

filter_stop_vs_ignore_test() ->
    setup(debug),
    %% primary filter 返回 stop：这条日志在到达 handler 前就消失了
    ok = logger:add_primary_filter(mute_eunit, {fun(_, _) -> stop end, ok}),
    logger:info("muted"),
    ok = logger:remove_primary_filter(mute_eunit),
    logger:info("back"),
    ?assertEqual([<<"info back">>], read_log()),
    teardown().

report_shape_test() ->
    setup(debug),
    logger:info(#{what => happened, count => 3}),
    Lines = read_log(),
    %% report 按键排序输出：count 在 what 前面，形状是 "k: v, k2: v2"
    ?assertEqual([<<"info count: 3, what: happened">>], Lines),
    teardown().

msg_shapes_test() ->
    setup(debug),
    logger:info("plain"),
    logger:info("formatted ~p and ~p", [1, two]),
    ?assertEqual([<<"info plain">>, <<"info formatted 1 and two">>], read_log()),
    teardown().

macro_info(Msg) -> ?LOG_INFO(Msg).
