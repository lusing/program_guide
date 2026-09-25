# 27 · 端口：Erlang 与外部程序的字节协议

> 对应示例：`examples/27_ports/`（escript 端口程序的源码作为**数据**内嵌在模块里，运行时落到 build 目录再 spawn）

端口是 Erlang 世界与 OS 进程之间的「一根管道」——比分布式轻、比 NIF
安全：外部程序崩溃不会连累 VM。取材《Erlang 程序设计》第 15 章；书里
的 C 例程换成 **escript 写的外部程序**（Erlang 自带，零外部编译器）。

## 27.1 起端口：外部程序就是一根管道

```erlang
Escript = os:find_executable("escript"),
Port = open_port({spawn_executable, Escript},
                 [binary, {packet, 2}, {args, [ScriptPath]}, exit_status]).
Port ! {self(), {command, <<"hello">>}},
receive {Port, {data, Reply}} -> ok end.
```

`os:find_executable("escript")` 在 Windows 自动找到 `escript.exe`——
比拼 `code:root_dir() ++ "/bin"` 便携。`exit_status` 选项让外部进程
退出时投递 `{Port, {exit_status, N}}`。

## 27.2 帧协议：驱动管前缀

`{packet, 2}` 的帧由**驱动**负责，方向不对称要记清：

- Erlang → 外部：`command` 发**裸载荷**即可（驱动自动加 2 字节前缀）；
- 外部 → Erlang：外部程序必须**自带前缀**写 `<<(Len):16, Body/binary>>`
  （驱动剥掉前缀才投递 `{data, 裸载荷}`）。

所以外部程序看到 stdin 是「2 字节长度 + 载荷」的裸字节流，echo 端口
程序的完整协议处理：

```erlang
main(_) ->
    ok = io:setopts(standard_io, [{binary, true}, {encoding, latin1}]),
    loop(0).
loop(N) ->
    case file:read(standard_io, 2) of
        {ok, <<H, L>>} ->
            Len = H bsl 8 bor L,
            {ok, Payload} = file:read(standard_io, Len),
            Reply = <<N:32, Payload/binary>>,        %% 序号是外部程序自己的状态
            ok = file:write(standard_io, [<<(byte_size(Reply)):16>>, Reply]),
            loop(N + 1);
        eof -> ok
    end.
```

多轮对话里序号递增——对端程序不是无状态的解码器，它有自己的计数。

## 27.3 字节透传：binary + latin1 是一对

**本章头号实测坑**：escript 的 standard_io 默认按 unicode 解码输入、
按 latin1 编码交付——非 ASCII 字节一来就是
`{no_translation, unicode, latin1}` 直接崩：

```erlang
%% 必须：
ok = io:setopts(standard_io, [{binary, true}, {encoding, latin1}]),
```

`binary` 让 read 返回原始字节、`latin1` 关掉转译——两个都要。设对了
之后 UTF-8 载荷原样往返：

```text
UTF-8 载荷原样往返（第 N 轮） = 0
往返后字节还是合法 UTF-8 原文 = true
```

## 27.4 崩溃与收尾：exit_status 与死端口

坏版本（忘了 setopts 的那段）演示崩溃路径——ASCII 能过（转译对
ASCII 透明），中文一来就崩：

```text
ASCII 载荷坏版本也能过 = ok
坏版本收到中文后退出码 = 1
对已死端口 port_close 抛的错 = badarg
Erlang 这边无恙，新端口照常工作 = ok
```

三个工程细节：

1. 教学用的坏 escript **自捕异常后 `halt(1)`**：escript 崩溃的默认
   行为是把异常栈打到 stderr——那会直接挂掉验证第 2/3 层；
2. 对已死端口 `port_close/1` 抛 `error:badarg`（不是返回 error）——
   用 `try ... catch error:badarg` 收；
3. 端口崩溃**不连累** Erlang 进程：catch 之后照常开新端口干活。

## 27.5 端口 vs 分布式 vs NIF

| | 端口 | 分布式节点 | NIF |
|---|---|---|---|
| 对面是 | OS 进程（任何语言） | Erlang VM | VM 内的 C 代码 |
| 隔离 | 进程级——崩了只死它 | 节点级——崩了只死节点 | **无**——崩了带走 VM |
| 通信 | 字节协议（自己定帧） | 项式（term）直接送 | 直接函数调用 |
| 延迟 | 高（协议+调度） | 中 | 低 |
| 本教程 | 第 27 章 | 第 25 章 | 不涉（记住它的崩溃语义即可） |

选型口诀：**信任边界外用端口/节点，性能热点才上 NIF**——NIF 里一个
段错误就是整台 VM 的段错误。

## 27.6 要点小结

```text
  open_port + spawn_executable；os:find_executable 跨平台找可执行
  {packet,N} 帧由驱动管：command 发裸载荷；外部程序回信必须自带前缀
  escript 端口程序必设 io:setopts(standard_io, [binary, {encoding, latin1}])
  exit_status 让外部进程的退出可观测；死端口 port_close 抛 badarg
  端口崩溃不连累 Erlang；escript 的异常栈会进 stderr——自捕后 halt(1)
  端口（进程级隔离）vs 分布式（节点级）vs NIF（零隔离，最高性能）
```

## 27.7 坑位清单

1. **escript 端口程序不 setopts 就崩**：standard_io 默认
   unicode→latin1 转译，非 ASCII 字节 `{no_translation, unicode,
   latin1}`——`[{binary, true}, {encoding, latin1}]` 双保险。
2. **escript 崩溃的异常栈打到父进程 stderr**——确定性脚本让外部程序
   自捕异常 `halt(1)`，把「崩溃事实」留给 exit_status 表达。
3. **双重成帧**：`{packet, 2}` 下 command 再手工加长度前缀，对端读到
   的「载荷」里就带着前缀——驱动管帧，别抢它的活。
4. **死端口的 port_close 抛 badarg**（异常不是返回值）；`catch` 表达
   式本身已被 `-Wall` 盯上，用 `try ... catch error:_ -> ok end`。
5. **`os:find_executable/1` 返回路径或 false**——不检查直接当
   spawn_executable 的参数，false 会变成 open_port badarg。
6. **外部程序也有状态**（echo 的序号）——「无状态服务器」是设计选择
   不是默认事实，重连不重置。
