# 23 · 工具链：typespec、dialyzer 与热加载

> 对应示例：`examples/23_tooling/`（自带一个 gen_server 当 sys 的观测对象，完全自包含）

## 23.1 typespec：写给人也写给 dialyzer

```erlang
-spec combine(string(), string()) -> string().
combine(A, B) when is_list(A), is_list(B) -> A ++ " " ++ B.

-spec tagged(integer() | float()) -> {number(), integer()}.
-type my_result() :: {ok, integer()} | {error, term()}.
```

常用类型：`integer()/float()/number()`、`string()/binary()`、`[T]`、`{A,B}`、`map()`、`any()`；`-type` 定义可复用的 union。-spec 会存进 beam 的抽象代码——**前提是编译带 `+debug_info`**（erlc 默认**不带**，实测 `beam_lib:chunks` 读出来是 `no_abstract_code`；本仓库 build.ps1 已统一加 `+debug_info`）。示例现场用 `beam_lib:chunks(Beam, [abstract_code])` 把自己的 spec 读出来验证。

## 23.2 dialyzer：成功类型推断（本机实测）

```powershell
# 一次性建 PLT（~25 秒；要覆盖你调用的所有 app，否则报 Unknown functions）
G:\scoop\apps\erlang\current\bin\dialyzer.exe --build_plt --output_plt build\guide_plt `
    --apps erts kernel stdlib compiler eunit common_test
# 分析（对本仓库任一示例目录）
dialyzer --plt build\guide_plt build\23_tooling\*.beam
# typer：反推"缺了哪些 -spec"
typer --plt build\guide_plt build\23_tooling\*.beam
```

对 `examples/23_tooling` 实跑的真实输出（3 条，每条都有解释）：

```text
23_tooling.erl:204:1: Function proc_init/2 has no local return
  → 真的：proc_init/2 末尾是 init_fail（进程必然退出），dialyzer 说得对
23_tooling_tests.erl:18: The call '23_tooling':tagged('atom') will never return ...
  → 测试里故意传 atom 断言抛异常；dialyzer 不看 try 上下文照样提示
Unknown functions: hot_demo:start/0
  → hot_demo 是运行时生成的模块，PLT 里没有——把生成物加进 PLT 或忽略
```

dialyzer 的哲学：**成功类型**（这个函数实际能接受/返回什么）比 spec 更宽就报警；它不证明程序对，但抓"这段代码永远不可能正确"。

## 23.3 sys：不停机查看/修改 OTP 进程

```erlang
sys:get_state(Name).                    %% 服务内部状态（gen_server 的 State）
sys:replace_state(Name, fun(S) -> S#{} end).  %% 直接改状态（返回改后的新状态）——救急用
sys:get_status(Name).                   %% {status, Pid, {module, gen_server}, [5 项]}
sys:statistics(Name, true). / sys:log(Name, true).   %% 统计/事件记录
sys:suspend(Name). / sys:resume(Name).  %% 挂起（call 全超时）/恢复
sys:no_debug(Name).                     %% 一键关掉所有调试开关
```

sys 用**系统消息**跟进程说话，gen_server 原生支持、业务代码零配合。observer 显示的就是 get_status 的结构。

## 23.4 proc_lib：手写进程的启动同步与身份

普通 spawn 的两个问题：start 返回时子进程可能还没初始化完（竞态）；崩溃报告只有 `<0.87.0>` 看不出是谁。`proc_lib:start_link` + `init_ack` 解决同步；进程字典里的 `$initial_call`/`$ancestors` 给身份（监督者靠它认孩子）。

> ⚠ 实测两个坑：**`proc_lib:init_fail/2` 的参数语义变了**——老写法 `init_fail(Parent, Ret)` 在现代 OTP 会把 Parent 当返回值发回（拿到裸 pid + CRASH REPORT），要用 `/3`：`init_fail(Parent, Ret, {exit, normal})`；**proc_lib ≠ OTP 进程**——它不自动支持 sys，循环里要自己接 `{system, From, Req}` 或干脆用 gen_server。

## 23.5 热代码加载：两个版本的规则

模块在 VM 里可**同时存在两个版本**：局部调用（裸函数名）永远用当前进程**正在跑的**版本；全限定调用（`?MODULE:f()`）用**最新**版本。所以**循环必须写成 `?MODULE:loop(...)`** 才能在升级后生效。

```erlang
code:soft_purge(Mod).   %% 只清没人跑的旧版（有人在跑 → false）
code:purge(Mod).        %% 硬清：杀掉还在跑旧版的进程——慎用
erlang:check_old_code(Mod).  %% 有旧版本在跑吗
```

## 23.6 节点内省：第一眼看什么

```erlang
[process_info(P, message_queue_len) || P <- erlang:processes()].  %% 按邮箱排序！
erlang:memory().      process_info(P, current_function/reductions/memory).
```

邮箱一直涨 = 有人发得比处理得快——线上"变慢但 CPU 不高"的头号原因。

## 23.7 beam_lib：把 beam 当数据库读

beam 文件是**分块容器**：抽象代码、属性、编译信息各占一块。23.1 用它验过 abstract_code，其实任何元数据都能按需取。本机实测（对一个探针模块自己的 beam）：

```erlang
Beam = code:which(probe_23).
beam_lib:info(Beam).
%% 注意：直接返回清单，**不包 {ok, ...}**（OTP 29 实测，连错两次的坑）：
%% => [{binary, 整个 beam 二进制}, {module, probe_23},
%%     {chunks, [{块名, 偏移, 大小}, ...]}]
{ok, {probe_23, [{attributes, Attrs}]}} = beam_lib:chunks(Beam, [attributes]),
proplists:get_value(vsn, Attrs).
%% => [203085611425987404064261429777252364843]
%%    没写 -vsn 时编译器自动算的版本指纹
{ok, {_, [{compile_info, CI}]}} = beam_lib:chunks(Beam, [compile_info]),
proplists:get_value(version, CI).   %% => "10.0.2"  ← 编译器版本
proplists:get_value(options, CI).   %% => []  ← 编译选项原样记录（+debug_info 会出现在这里）
```

工程用途：**发布前自检**——遍历发布目录的 beam，断言每个都能读出 `abstract_code`（没编 debug_info 的混进来立刻现形）、`compile_info` 的 options 里没有忘关的调试开关。

## 23.8 Shell 体验：h()、彩色输出与特性开关

**h()：文档进了 beam（OTP 23）**。OTP 23 起文档以 docs_v1 chunk 编进 beam，shell 里直接查，不用开浏览器：

```erlang
1> h(lists).            %% 整个模块的文档
2> h(lists, reverse).   %% 单个函数
```

底层是 shell_docs 渲染，本机实测 `h(lists, reverse)` 的输出（逐字节）：

```text
   -spec reverse(List1) -> List2
                    when List1 :: [T], List2 :: [T], T :: term().

   Returns a list containing the elements in List1 in
   reverse order.

   Examples

       1> lists:reverse([1,2,3]).
       [3,2,1]
```

官方库全带文档；自己的模块写 `-moduledoc`/`-doc` 属性（OTP 27 起的文档语法）就能享受同等待遇。

**io_ansi：终端控制序列（OTP 29）**。手写 `\e[31m` 的时代结束了——新模块 io_ansi 按命名族生成序列，直接返回 binary：

```erlang
io_ansi:blue().              %% <<"\e[34m">>
io_ansi:red_background().    %% <<"\e[41m">>——注意命名：颜色_background，不是 background_red
io_ansi:bold().              %% <<"\e[1m">>
```

更好用的是 format 族：跟 io_lib:format 一个路子，但**格式串里可以混排 VTS 原子**：

```erlang
io_ansi:format([blue, "~p"], [red], [{enabled, true}]).
%% => <<"\e[34mred\e[0m">>              ← 结尾自动追加 reset
io_ansi:format([bold, red_background, " ~s "], ["WARN"], [{enabled, true}]).
%% => <<"\e[1m\e[41m WARN \e[0m">>
```

**它知道什么时候不该输出转义序列**：默认按终端能力探测（terminfo），无终端环境（noshell、重定向到文件）自动剥掉 VTS——本机 `erl -noshell` 下实测：

```erlang
io_ansi:enabled().                    %% => false
io_ansi:format([blue, "~p"], [red]).  %% => <<"red">>——日志文件里干干净净，不会有一堆 ^[
```

其他旋钮：`{reset, false}` 不追加 reset；`{color, false}` 只剥颜色、保留 underline 等修饰；`fwrite` 直写设备返回 `ok`；认 `NO_COLOR` 环境变量约定。

**erl_features：特性开关（OTP 25）**。语言新特性先以"实验特性"发布、逐版本转正，all/0 列出当前 VM 认识的全部特性：

```erlang
erl_features:all().   %% => [compr_assign, maybe_expr]——本机 OTP 29 实测
```

## 23.9 坑位清单

1. **erlc 默认不带 debug_info**：dialyzer/beam_lib 没料——build.ps1 统一 `+debug_info`（实测）。
2. **PLT 少 app**：调了 `compile:file`/`eunit:test` 而 PLT 没编 compiler/eunit → Unknown functions。
3. **`init_fail/2` 语义已变**：老 `(Parent, Ret)` 会返回裸 pid；用 `init_fail/3`（23.4 实测）。
4. **循环局部调用，升级不生效**：必须 `?MODULE:loop(...)`。
5. **`code:purge` 杀进程**：先 `soft_purge` 确认没人跑旧版。
6. **API 撞 BIF**：`put/2` 撞进程字典——本模块实测改名 `set/2`（15 章的坑再现）。
7. **不同 arity 子句用分号连接**：`-Wall` 报 head mismatch——每个 arity 独立成函数。
8. **sys:get_state 卡住**：目标不是 OTP 进程（不认系统消息）——proc_lib 也不行，要 gen_server。
9. **io_ansi:format 的输出随终端能力变**：无终端自动剥 VTS（noshell 下实测 `<<"red">>`）——测试里断言序列要 `[{enabled, true}]` 强制（23.8）。
10. **argparse:run 出错直接 halt(1)**：escript 入口专用；单元测试和库代码用纯函数 parse（27.6）。

---

---

上一章：[22 日志](22-logger.md) · 下一章：[24 实战 mini-grep ⭐](24-minigrep.md)
