# 25 · 分布式 Erlang：节点、rpc 与 global

> 对应示例：`examples/25_distributed/`（⚠ 必须以分布式节点启动：`erl -sname ex25_a ...`——build.ps1 已自动处理）

「进程之间 `send` 永远长一样」——不管那个进程住在哪台机器上。分布式
Erlang 把这句话做成了语言的一部分，而不是库。取材《Erlang 程序设计》
第 14 章，起节点的方式按 OTP 29 的 **peer 模块**重写——老书里手工开
两个终端敲命令行的做法，如今是一个函数调用。

## 25.1 节点：给 VM 一个名字

```erlang
%% erl -sname ex25_a 起来的 VM：
node().          %% 'ex25_a@主机名'（短名）
is_alive().      %% true；不带 -sname 时 node() 是 nonode@nohost、is_alive() 是 false
```

`-sname` 短名用主机短名，`-name` 长名用 FQDN；同一集群必须同一种。
本教程输出不打印完整节点名（主机名因机器而异），只用 `@` 前的短名。

## 25.2 peer：一个函数起一个节点

```erlang
{ok, Peer, Node} = peer:start(#{name => ex25_peer1}),
[Node] = nodes().                        %% 节点起来就自动与父节点握手
rpc:call(Node, erlang, is_alive, []).    %% true
```

实测出两种 peer 的**关键分野**：

| 起法 | 行为 |
|---|---|
| `peer:start(#{name => X})` | 启动即自动建立分布式连接；**父侧 disconnect 会把 peer 节点连带杀死**（生命周期绑在分布式连接上） |
| `peer:start(#{name => X, connection => 0})` | 控制通道走 TCP，分布式连接**不自动建立**——cookie 演示、断开重连都要可控时用它 |

老书的 `slave` 模块已被 peer 取代；peer 还带 `wait_boot`（等对端 boot
完成）、`peer:call/4`（经控制通道的 rpc，不占分布式连接）等现代设施。

## 25.3 rpc：在对端节点上调用函数

```erlang
42 = rpc:call(Node, erlang, '+', [19, 23]).
42 = rpc:call(Node, ?MODULE, add, [20, 22], 5000).   %% 第 5 参：毫秒超时
```

让对端跑**我们自己的模块**，先把 beam 目录挂上对端代码路径：

```erlang
BeamDir = filename:dirname(code:which(?MODULE)),
true = rpc:call(Node, code, add_patha, [BeamDir]).
```

失败形状两种：对端没有那个函数 → `{badrpc, {'EXIT', {undef, _}}}`；
节点根本不存在（epmd 查无此名）→ `{badrpc, nodedown}`。

## 25.4 对端 spawn：位置透明性

```erlang
RemotePid = spawn(Node, ?MODULE, loop, []),   %% 分布式 spawn 原语
RemotePid ! {ping, self()},                   %% send 的语法没变半个字符
receive {pong, Node} -> ok end.               %% 回信自带对方节点名
```

rpc 的等价物是让对端自己 spawn（`spawn/3` 在对端求值）。代码在哪，
进程就在哪——消息怎么发、怎么收与单机完全一致，这就是位置透明。

## 25.5 global：集群级注册名

`register` 只在本节点生效；`global` 的名字整个集群共享：

```erlang
RemotePid = spawn(Node, ?MODULE, loop, []),
yes = rpc:call(Node, global, register_name, [ex25_echo, RemotePid]),
ok  = global:sync(),                        %% 名字同步是异步的——查之前 sync
true = is_pid(global:whereis_name(ex25_echo)),
global:send(ex25_echo, {ping, self()}).
```

两个实测点：`register_name` 成功返回的是原子 **yes**（不是 true）；
注册后立刻 `whereis_name` 可能查不到——global 的名字交换是异步的，
先 `global:sync()` 等一次交换。

## 25.6 cookie：节点握手的口令

同机节点默认读同一份 `~/.erlang.cookie`，握手不用管口令。口令只在
**握手建立连接那一刻**校验（之后改口令不影响已建立的连接）：

```erlang
true = erlang:set_cookie(Node, erlang:get_cookie()),
pong = net_adm:ping(Node),
pang = net_adm:ping(Ghost).     %% 不存在的节点：连握手都没有
```

⚠ **实测大坑**：口令失配的握手会触发 **ERTS 层的 ERROR REPORT**
（`Invalid challenge reply`，带时间戳）——它**不走 logger**，父节点
与 peer 都摘掉 handler 也拦不住。确定性演示/测试只能避开真实的失配
握手，用「节点不存在」演示同款的 pang。

## 25.7 拓扑：连接、断开、重连

```text
当前已连节点 = [ex25_peer1,ex25_peer2]
对已连接节点再 ping（幂等） = pong
disconnect 之后 nodes() = [ex25_peer1]
再 ping 一次就回来了（口令没变） = pong
```

disconnect/reconnect 只对 **TCP 控制 peer** 可演示——默认 peer 的分布
式连接就是控制通道，disconnect 等于判死刑。

## 25.8 要点小结

```text
  节点=有名字的 VM；-sname 短名 / -name 长名，一个集群只用一种
  peer:start 一个函数起节点；connection => 0 走 TCP 控制通道（分布式连接不自动建）
  对端跑自己的代码：先 rpc code:add_patha 挂 beam 目录
  spawn(Node,M,F,A) 分布式 spawn；send/receive 语法与单机一字不差
  global 集群注册名：返回 yes 不是 true；查名前先 global:sync()
  cookie 只在握手时校验；失配握手的 ERROR REPORT 在 ERTS 层，摘 logger 拦不住
  输出纪律：不打印 pid、不打印带主机名的完整节点名
```

## 25.9 坑位清单

1. **peer 生命周期绑父连接**：默认 peer 的分布式连接即控制通道，
   `net_kernel:disconnect/1` 会把 peer 节点和父侧控制进程一并带走；
   要反复断连用 `connection => 0`（TCP 控制）。
2. **`peer:start` 的 map 没有 `peer_start` 选项**——传额外的 erl 参数
   用 `args => ["-eval", "..."]`（字符串列表）；不存在的选项被静默忽略。
3. **peer 的输出会转发回父节点**：握手被拒等报告经控制通道回流父
   stdout——让 peer 自静音要 `args => ["-eval",
   "logger:remove_handler(default)"]`（注意 `set_primary_config(level,
   none)` 是**全放行**不是全静音——none 是最低档！）。
4. **`global:register_name` 返回 yes/no**，`true = ...` 直接 badmatch。
5. **global 名字同步是异步的**：注册后立刻 `whereis_name` 可能
   undefined，先 `global:sync()`。
6. **失配握手的 ERROR REPORT 拦不住**（ERTS 层、带时间戳）——确定性
   脚本别触发真实失配握手；`pang` 用「节点不存在」来演示。
7. **build.ps1 特判**：本示例的 EUnit 与运行层都要 `-sname ex25_a`
   （peer 要求父节点是活节点）——手工跑别忘带。
8. **rpc 别裸奔**：`rpc:call/4` 无超时默认 5 秒挂等；长活或对端不可靠
   时显式给第 5 参。
