%% ============================================================
%% 01 - 模块结构、导出与格式化输出
%%
%%    Erlang 程序的最小单位是「模块」：一个 .erl 文件就是一个模块。
%%    文件名必须与 -module(...) 里的名字**完全一致**，否则 erlc 直接报错：
%%      Module name 'xxx' does not match file name 'yyy'
%%    本教程的示例名以数字开头，而 Erlang 里以数字开头或含连字符的名字
%%    必须写成「引号原子」，所以模块名是 '01-hello'。
%%
%% 编译：
%%   erlc -Werror -Wall -o build examples/01-hello.erl
%% 运行：
%%   erl -noshell -pa build -run '01-hello' main -s init stop
%% 交互式：
%%   erl -pa build
%%   1> '01-hello':greet("世界").
%%
%% 说明：-Werror 把警告当错误。教程里开着它，是为了让
%% 「格式串指令数不匹配」这类问题在编译期就暴露，而不是留到运行期。
%% ============================================================
-module('01-hello').

%% -export 是显式契约：没列出来的函数对外不可见。
%% 写法是 [函数名/参数个数]；同名不同参数个数算两个不同的函数。
-export([main/0, greet/1, show_directives/0, show_width/0, show_module_info/0]).

%% 1) 最小可运行模块
%% ------------------------------------------------------------
%% erl 的 -run '01-hello' main 会调用 main/0（参数个数为 0）。
main() ->
    io:format("Hello, Erlang/OTP!~n"),
    io:format("OTP ~s / erts ~s~n",
              [erlang:system_info(otp_release),
               erlang:system_info(version)]),
    %% 调度器个数取决于机器核数与 +S 启动参数，**每次运行都可能不同**，
    %% 所以这里只断言「至少 1 个」，不把具体数字打进输出 ——
    %% 否则 run-all.sh 的「两种调度器配置输出必须逐字节一致」这条就过不了。
    %% 想看具体数字：
    %%   erl -noshell -eval 'io:format("~p~n",[erlang:system_info(schedulers_online)]),halt(0).'
    io:format("  调度器个数 >= 1                = ~p~n",
              [erlang:system_info(schedulers_online) >= 1]),
    greet("世界"),
    show_directives(),
    show_width(),
    show_module_info(),
    io:format("~n==== 01 结束 ====~n").

%% 函数名小写，变量名大写；多个子句之间用分号，最后一个子句用句点。
%% 两个子句分别是「参数是字符串」和「其它」，靠模式与 guard 分流。
greet(Name) when is_list(Name) ->
    %% ~ts 是「按 unicode 打印」，中文必须用它（~s 只认 latin1，见第 03 章）
    io:format("  你好，~ts！~n", [Name]);
greet(Other) ->
    io:format("  期望字符串，收到 ~p~n", [Other]).

%% 2) io:format 的常用指令
%% ------------------------------------------------------------
%% 格式串里的 ~X 是「指令」。出现在正文里的波浪号必须写成 ~~，
%% 否则会被当成指令、并因参数个数对不上而 badarg（编译器也会警告）。
%%
%% 下面每一行都**真的用该指令渲染一次**，再把结果打出来对照。
show_directives() ->
    io:format("~n== 2) 常用格式指令 ==~n"),
    dir("~p", "项打印；可打印的字符列表打成字符串", "abc"),
    dir("~w", "项打印；不套用字符串美化", "abc"),
    dir("~p", "对照：~p 遇到非 latin1 原子会转义", '中文'),
    dir("~tp", "~p 的 unicode 版：非 latin1 原子原样输出", '中文'),
    dir("~ts", "按 unicode 打印字符串或 utf8 二进制", <<"中文"/utf8>>),
    dir("~s", "按 latin1 打印；码点 > 255 会 badarg", "abc"),
    dir("~b", "十进制整数", 255),
    dir("~.16B", "十六进制（~B 的「精度」就是进制）", 255),
    dir("~.2B", "二进制", 5),
    dir("~.8B", "八进制", 8),
    dir("~c", "按字符打印一个整数", $A),
    dir("~f", "定点浮点，默认 6 位小数", 3.14159),
    dir("~.2f", "两位小数", 3.14159),
    dir("~e", "科学计数法", 1234.5),
    dir("~p", "元组", {a, 1}),
    dir("~p", "列表", [1, 2, 3]),
    dir("~p", "原子（含空格时会自动加引号）", 'has space'),
    %% 正文里的波浪号要写两遍
    io:format("  ~-8ts ~ts  ->  ~ts~n",
              ["~~", "正文中的字面波浪号", lists:flatten(io_lib:format("100~~%", []))]),
    ok.

%% 3) 宽度、对齐与填充
%% ------------------------------------------------------------
%% 指令通式是  ~宽 . 精度 . 填充字符 控制字符
%%   正数宽度右对齐，负数宽度左对齐
%%   对 ~B 来说「精度」就是进制，所以十六进制要写 ~.16B
show_width() ->
    io:format("~n== 3) 宽度与对齐 ==~n"),
    io:format("  [~8s][~-8s]   左对齐用负宽度~n", ["ab", "ab"]),
    io:format("  [~8b][~-8b]~n", [42, 42]),
    io:format("  零填充日期：~2..0B-~2..0B-~4..0B~n", [9, 16, 2026]),
    io:format("  零填充十六进制：~8.16.0B~n", [255]),
    %% 顺序写错（把填充字符写到精度前面，如 ~8..0.16B）会 badarg。
    %% 这种错误不用等到运行期：格式串是字面量时，erlc -Wall 在编译期就报
    %%   format string invalid (invalid control ~.)
    %% 所以这里演示不出运行期异常 —— 编译器已经先拦住了。
    io:format("  （顺序写错的写法在编译期即被拒绝，无法在本示例里运行）~n"),
    ok.

%% 4) 模块自身的信息
%% ------------------------------------------------------------
show_module_info() ->
    io:format("~n== 4) 模块信息 ==~n"),
    %% code:which/1 告诉你这个模块的 .beam 到底从哪儿加载的。
    %% 只打文件名和它所在的目录名：绝对路径里带这台机器的仓库位置，
    %% 打进输出既没法在别的机器上复核，也会把文档污染成「只在本机成立」。
    Which = code:which('01-hello'),
    io:format("  code:which('01-hello') 的文件名 = ~ts~n", [filename:basename(Which)]),
    io:format("  它所在的目录名                 = ~ts~n",
              [filename:basename(filename:dirname(Which))]),
    io:format("  ?MODULE                        = ~p~n", [?MODULE]),
    io:format("  导出的函数个数                 = ~p~n", [length(?MODULE:module_info(exports))]),
    io:format("  导出的函数                     = ~p~n", [lists:sort(?MODULE:module_info(exports))]),
    io:format("  是否导出了 greet/1             = ~p~n",
              [erlang:function_exported(?MODULE, greet, 1)]),
    io:format("  是否导出了不存在的 nope/0      = ~p~n",
              [erlang:function_exported(?MODULE, nope, 0)]),
    ok.

%% 辅助函数：用指定指令渲染一个值，再把「指令 / 说明 / 实际输出」三列打出来。
%% 说明列用 ~ts 打印，所以说明里出现 ~ 也不会被当成指令 —— 这是最省心的写法。
dir(Fmt, Desc, Value) ->
    Rendered = lists:flatten(io_lib:format(Fmt, [Value])),
    io:format("  ~-8ts ~ts  ->  ~ts~n", [Fmt, Desc, Rendered]).
