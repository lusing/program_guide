%% ============================================================
%% 27_ports —— 端口：Erlang 与外部程序的字节协议
%%
%%    端口是 Erlang 世界与 OS 进程之间的「一根管道」：
%%      · open_port({spawn_executable, 程序}, [...]) —— 起一个外部进程
%%      · {packet, 2} —— 驱动自动加/剥 2 字节长度前缀：Erlang 这边
%%        send 裸载荷、收 {data, 裸载荷}；**外部程序**那边看到的才是
%%        「2 字节长度 + 载荷」的原始字节流，回信必须自带前缀
%%      · exit_status —— 外部进程退出时投递 {Port, {exit_status, N}}
%%    外部程序用 escript 写（Erlang 自带、零外部编译器依赖），
%%    源码作为**数据**内嵌在本模块里，运行时落到 build 目录再 spawn。
%%
%%    两个实测大坑（CHEATSheet 详见）：
%%      1) escript 端口程序必须先 io:setopts(standard_io,
%%         [{binary,true},{encoding,latin1}])——默认 unicode 输入走
%%         「解码为 unicode 再编码为 latin1」的转译，非 ASCII 字节直接
%%         no_translation 崩掉；
%%      2) {packet,N} 的帧由**驱动**负责：command 发裸载荷即可，
%%         手工再加一层前缀就是对端读到的「载荷里带前缀」。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/27_ports examples/27_ports/27_ports.erl
%% 运行：
%%   erl -noshell -pa build/27_ports -run '27_ports' main
%% ============================================================
-module('27_ports').

-export([main/0, write_escript/2, escript_path/0, open_echo_port/1,
         call/2, echo_source/0, bad_echo_source/0]).

%% 正确的 echo 端口程序：binary+latin1 透传字节
echo_source() ->
    "#!/usr/bin/env escript\n"
    "%%! -noshell\n"
    "main(_) ->\n"
    "    ok = io:setopts(standard_io, [{binary, true}, {encoding, latin1}]),\n"
    "    loop(0).\n"
    "loop(N) ->\n"
    "    case file:read(standard_io, 2) of\n"
    "        {ok, <<H, L>>} ->\n"
    "            Len = H bsl 8 bor L,\n"
    "            {ok, Payload} = file:read(standard_io, Len),\n"
    "            Reply = <<N:32, Payload/binary>>,\n"
    "            ok = file:write(standard_io, [<<(byte_size(Reply)):16>>, Reply]),\n"
    "            loop(N + 1);\n"
    "        eof -> ok\n"
    "    end.\n".

%% 坏版本：忘了 setopts——非 ASCII 载荷一来就 no_translation 崩溃。
%% 自捕异常静默 halt(1)：escript 的异常栈会打到父进程 stderr（挂验证），
%% 崩溃事实由 exit_status 呈现
bad_echo_source() ->
    "#!/usr/bin/env escript\n"
    "%%! -noshell\n"
    "main(_) ->\n"
    "    try loop(0)\n"
    "    catch _:_ -> halt(1)\n"
    "    end.\n"
    "loop(N) ->\n"
    "    case file:read(standard_io, 2) of\n"
    "        {ok, [H, L]} ->\n"
    "            Len = H bsl 8 bor L,\n"
    "            {ok, Chars} = file:read(standard_io, Len),\n"
    "            Reply = <<N:32, (list_to_binary(Chars))/binary>>,\n"
    "            ok = file:write(standard_io, [<<(byte_size(Reply)):16>>, Reply]),\n"
    "            loop(N + 1);\n"
    "        eof -> ok\n"
    "    end.\n".

escript_path() ->
    os:find_executable("escript").

%% 把 escript 源码写到 beam 所在目录（build/27_ports，不入库）
write_escript(Name, Source) ->
    Dir = filename:dirname(code:which(?MODULE)),
    Path = filename:join(Dir, Name),
    ok = file:write_file(Path, unicode:characters_to_binary(Source)),
    Path.

%% 起一个 echo 端口：{packet,2} 帧由驱动负责
open_echo_port(Path) ->
    open_port({spawn_executable, escript_path()},
              [binary, {packet, 2}, {args, [Path]}, exit_status]).

%% 一次请求-响应：发载荷，收 {序号, 载荷}
call(Port, Payload) ->
    Port ! {self(), {command, Payload}},
    receive
        {Port, {data, <<Seq:32, Back/binary>>}} -> {Seq, Back}
    after 3000 -> timeout
    end.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).

main() ->
    logger:remove_handler(default),
    model_and_boot(),
    framing_roundtrips(),
    utf8_transparency(),
    crash_and_cleanup(),
    io:format("~n==== 27 结束 ====~n").

%% ------------------------------------------------------------ %%
%% 1) 起端口：外部程序就是一根管道
%% ------------------------------------------------------------
model_and_boot() ->
    io:format("~n== 1) 起端口：外部程序就是一根管道 ==~n"),
    d("escript 可执行文件找到路径", is_list(escript_path())),
    Path = write_escript("echo_port.escript", echo_source()),
    Port = open_echo_port(Path),
    d("open_port 拿到的是端口标识", is_port(Port)),
    {0, <<"hello">>} = call(Port, <<"hello">>),
    d("第一条命令往返", ok),
    port_close(Port).

%% ------------------------------------------------------------ %%
%% 2) 帧协议：驱动管前缀，多轮对话有序号
%% ------------------------------------------------------------
framing_roundtrips() ->
    io:format("~n== 2) 帧协议：驱动管前缀，多轮对话有序号 ==~n"),
    Path = write_escript("echo_port.escript", echo_source()),
    Port = open_echo_port(Path),
    d("第 1 轮", call(Port, <<"one">>)),
    d("第 2 轮", call(Port, <<"two">>)),
    d("第 3 轮", call(Port, <<1, 2, 3, 4, 5>>)),
    io:format("  （序号由 escript 端计数——对端程序也有自己的状态）~n"),
    port_close(Port).

%% ------------------------------------------------------------ %%
%% 3) 字节透传：UTF-8 与 binary+latin1
%% ------------------------------------------------------------
utf8_transparency() ->
    io:format("~n== 3) 字节透传：UTF-8 与 binary+latin1 ==~n"),
    Path = write_escript("echo_port.escript", echo_source()),
    Port = open_echo_port(Path),
    Utf8 = unicode:characters_to_binary("中文"),
    {N, Utf8} = call(Port, Utf8),
    d("UTF-8 载荷原样往返（第 N 轮）", N),
    d("往返后字节还是合法 UTF-8 原文",
      unicode:characters_to_list(Utf8) =:= "中文"),
    port_close(Port).

%% ------------------------------------------------------------ %%
%% 4) 崩溃与收尾：exit_status 与死端口
%% ------------------------------------------------------------
crash_and_cleanup() ->
    io:format("~n== 4) 崩溃与收尾：exit_status 与死端口 ==~n"),
    %% 坏 escript：忘了 binary+latin1——非 ASCII 载荷触发 no_translation
    BadPath = write_escript("bad_echo_port.escript", bad_echo_source()),
    BadPort = open_echo_port(BadPath),
    %% 先来一条 ASCII 的：能过（转译对 ASCII 透明）
    {0, <<"ascii fine">>} = call(BadPort, <<"ascii fine">>),
    d("ASCII 载荷坏版本也能过", ok),
    %% 再发中文：escript 内部崩掉，端口投递 exit_status
    BadPort ! {self(), {command, unicode:characters_to_binary("中文")}},
    receive
        {BadPort, {exit_status, S}} -> d("坏版本收到中文后退出码", S)
    after 3000 -> d("exit_status", timeout)
    end,
    %% 端口死了：port_close 对已死端口抛 badarg
    try port_close(BadPort), d("对已死端口 port_close", unexpected_ok)
    catch error:badarg -> d("对已死端口 port_close 抛的错", badarg) end,
    %% 与外部进程相比：端口崩溃不连累 Erlang 进程——catch 之后照常干活
    Path = write_escript("echo_port.escript", echo_source()),
    Port = open_echo_port(Path),
    {0, <<"still alive">>} = call(Port, <<"still alive">>),
    d("Erlang 这边无恙，新端口照常工作", ok),
    port_close(Port).
