# 24 · 实战：mini-grep ⭐

> 对应示例：`examples/24_minigrep/`（OTP 工程：`.app` + 监督树 + gen_server + worker 池 + 递归遍历）

## 24.1 组装图

```text
24_minigrep.erl    CLI：解析参数 → 递归列文件 → 调服务 → 格式化输出
mg.app             应用资源文件（env: max_workers = 4）
mg_app.erl         application 回调（start/2 返回顶层监督者）
mg_sup.erl         supervisor：one_for_one，唯一孩子 dispatcher
mg_dispatcher.erl  gen_server：分派文件、聚合结果（先干活后回）
mg_worker.erl      worker：扫单文件（binary 切行 + binary:match）
corpus/            语料（示例扫描目标，含子目录）
```

```powershell
cd examples/24_minigrep
erl -noshell -pa ../../build/24_minigrep -run '24_minigrep' main spawn corpus -s init stop
```

## 24.2 每一层都是前章的复用

| 层 | 用到的章 |
|---|---|
| `.app` + ensure_all_started + env 快照 | 17 |
| supervisor child spec | 16 |
| gen_server 先干活后回（`{noreply, State}` + `gen_server:reply/2`） | 15 |
| spawn + monitor + 按 DOWN 聚合 | 13/14 |
| 二进制切行/匹配/剥 `\r` | 08/19 |
| 递归遍历目录（自写：wildcard 不递归） | 05/19 |

## 24.3 worker：扫一个文件

```erlang
scan_file(File, Pattern) ->
    {ok, Bin} = file:read_file(File),
    Lines = binary:split(Bin, <<"\n">>, [global, trim_all]),
    [{No, strip_cr(L)} || {No, L} <- enumerate(Lines),
                          binary:match(L, Pattern) =/= nomatch].
```

纯函数、可单测（`mg_tests` 直接对临时文件断言行号）；CRLF 的 `\r` 剥掉再输出（Windows 实测坑）。

## 24.4 dispatcher：回合制 worker 池

```erlang
handle_call({grep, Files, Pattern}, From, #{phase := idle} = State) ->
    {First, Rest} = split_at(Cap, Files),          %% 第一回合 cap 个
    {noreply, State#{phase := busy, running => spawn_workers(First, Pattern), ...}};
handle_info({worker_done, Pid, Result}, ...) ->   %% 结果先到，挂到 done
handle_info({'DOWN', _, process, Pid, _}, ...) -> %% DOWN 取结果/记崩溃，补员或收工
```

要点：**结果消息先于 DOWN**（同一发送者 FIFO + 死亡在发送之后）；DOWN 时从 `done` 取结果配 `running` 里的 File——**取不到 = worker 崩了没交活**，记 `{error, worker_crashed}` 不丢文件；全部结束后 `lists:sort` 再回复——worker 完成顺序是乱的，**排序去随机**；cap 从 env 读（init 快照）。

## 24.5 输出（真实运行）

```text
扫描 3 个文件，找含 "spawn" 的行：
  corpus/alpha.erl:5:     Pid = spawn(fun worker/0),
  corpus/alpha.erl:6:     %% spawn 一个再 spawn 一个——同一行多个命中只算一行
  corpus/notes.md:2: 这个目录是 24_minigrep 的扫描目标。命中的关键词是 `spawn`。
  ...
共 7 处命中，分布在 3 个文件里。
[mg_app] prep_stop          ← 关闭顺序可见（17 章）
[mg_app] stop
```

## 24.6 坑位清单（本次实战亲历）

1. **期望值写成 `<<"...中文...">>`**：二进制字面量按 latin1 截断（`读不了` → `<<251,13,134>>`，即各码点 rem 256）——**本教程自己的测试踩了 09 章头号坑**，改用 `unicode:characters_to_binary("...")` 从列表转。
2. **`iolist_to_binary` 遇中文 badarg**：含 >255 码点的 chardata 要用 `unicode:characters_to_binary`。
3. **worker 结果与 File 分离**：worker 只回 `{ok, Lines}`，文件名在 dispatcher 的 running 表里——DOWN 时配对，丢了就说不清哪个文件崩了。
4. **忘记排序就输出**：worker 完成顺序随调度，双通道验证直接挂。
5. **aggregation 丢崩溃文件**：只收结果不记 DOWN，崩掉的文件无声消失——DOWN 无结果时记 worker_crashed。
6. **`handle_call` 里阻塞等 worker**： mailbox 会死锁（call 自己）——用 `{noreply, State}` + `gen_server:reply/2`。

## 24.7 扩展练习

1. **正则模式**：`re:run/2` 替换 `binary:match`（注意转义与性能）。
2. **上下文行**：命中行前后各带 N 行（worker 多返回几行，聚合去重）。
3. **递归上限**：walk 加深度限制与符号链接防护（file:read_link_info）。
4. **流式输出**：dispatcher 每收到一个结果就 cast 给 CLI，不等全部（怎么保证输出顺序？）。
5. **-i 忽略大小写**：把文件与模式都 lower 后再匹配，输出保留原文。
6. **多模式 OR**：Pattern 变列表，命中任意一个都算。

---

---

> 本章曾是收官；第 25–32 章的扩充（分布式、套接字、端口、
> DETS/Mnesia、gen_event/gen_statem、剖析、多核、文本侦探）接在它后面——
> OTP 的世界铺完之后，第 32 章回到纯函数收官。
