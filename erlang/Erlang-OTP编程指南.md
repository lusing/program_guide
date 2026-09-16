# Erlang/OTP 编程指南

> 目标：让你读完之后能**真的写出**可上线的 Erlang/OTP 程序，而不是只认识语法。
>
> 这份指南里的每一条结论、每一段输出都在本机 Erlang/OTP 29 / erts 17.0.3 上实跑过。
> 凡是你觉得"应该如此"而我又写得不一样的地方，几乎都是被实测推翻过的 —— 我在正文里把
> 这些地方单独标了出来。

---

## 怎么读这份指南

### 三条原则

1. **文档里每条输出都能溯源**。下面所有标着「实测输出」的代码块都来自
   `build/<章>/stdout.txt`，是 `./run-all.sh` 或 `pwsh ./build.ps1 -All` 真跑出来的。
   不要凭印象相信某条结论 —— 按[第 29 章](#第-29-章-构建与验证)的办法单跑一章就能复核。
2. **先理解再写，不要先看代码猜语义**。Erlang 有很多名字看着熟悉、语义完全不同的东西：
   `get/1` 是自动导入的 BIF 而不是你的函数、`string:length` 数的是字素簇不是字节、
   `size/1` 对 tuple 和 binary 行为不同。这些是 Node 级事故的常见来源。
3. **遇到问题先查[第 30 章坑总表](#第-30-章-坑总表)**。里面有 70 多条实测踩过的坑，涵盖
   编码、原子表泄漏、日志丢失、监督者不调 `terminate/2` 等只有在线上才体会得到的东西。

### 与其他语言的对照

如果你有下面这些语言的经验，这张表能让你少走弯路：

| 你熟悉的 | Erlang 里对应的东西 | 关键差异 |
| --- | --- | --- |
| Go goroutine / channel | Erlang process / mailbox | Erlang 进程**不共享内存**（消息是拷贝）；邮箱是**每进程独有**的，而且接收是"选择性"的（第 19 章） |
| Rust `Result<T, E>` | `{ok, V}` / `{error, R}` 元组 | 没有类型系统逼你处理错误分支；OTP 另有一套做法：**让它崩，让别人重启**（第 15、22 章） |
| Java `try/catch/finally` | `try ... of ... catch ... after ... end` | `catch` 分**三类**（error / exit / throw）；`after` 里改变值不会影响到返回值（第 13 章） |
| Python `dict` | `map` / `proplists` / ETS | `map` 的迭代顺序**每次进程启动都随机**（第 10 章）；要稳定顺序必须 `lists:sort` |
| C `struct` | `record` | record 只是**编译期语法糖**，运行期就是一个元组（第 11 章） |
| Node.js `async/await` | 没有对应物，也不需要 | 进程 + 邮箱本身就是异步的；`gen_server:call` 是**带超时**的同步调用（第 21 章） |
| Kubernetes 的 pod restart policy | supervisor 的 `one_for_one` 等 | supervisor 是 Erlang 自带的、粒度到单个进程的重启机制，不依赖外部编排（第 22 章） |
| Python `logging` | `logger` | 日志先过**四道关**，默认级别是 `notice` 不是 `info`；过载时**真的会丢**（第 27 章） |

### 目录

**基础篇**

- [第 1 章 模块、函数与 Hello World](#第-1-章-模块函数与-hello-world)
- [第 2 章 数值与算术](#第-2-章-数值与算术)
- [第 3 章 原子、字符串与 Unicode](#第-3-章-原子字符串与-unicode)
- [第 4 章 模式匹配](#第-4-章-模式匹配)
- [第 5 章 卫语句（guard）](#第-5-章-卫语句guard)
- [第 6 章 递归与尾调用](#第-6-章-递归与尾调用)
- [第 7 章 列表](#第-7-章-列表)
- [第 8 章 推导式](#第-8-章-推导式)
- [第 9 章 二进制与位语法](#第-9-章-二进制与位语法)
- [第 10 章 映射（map）](#第-10-章-映射map)
- [第 11 章 记录（record）](#第-11-章-记录record)
- [第 12 章 函数与 fun](#第-12-章-函数与-fun)
- [第 13 章 控制流与异常](#第-13-章-控制流与异常)
- [第 14 章 高阶函数](#第-14-章-高阶函数)

**容错与并发篇**

- [第 15 章 错误处理哲学](#第-15-章-错误处理哲学)
- [第 16 章 proplists 与配置](#第-16-章-proplists-与配置)
- [第 17 章 集合容器](#第-17-章-集合容器)
- [第 18 章 进程](#第-18-章-进程)
- [第 19 章 消息传递](#第-19-章-消息传递)
- [第 20 章 链接与监控](#第-20-章-链接与监控)

**OTP 篇**

- [第 21 章 gen_server](#第-21-章-gen_server)
- [第 22 章 supervisor](#第-22-章-supervisor)
- [第 23 章 application](#第-23-章-application)
- [第 24 章 ETS](#第-24-章-ets)
- [第 25 章 文件 I/O 与二进制序列化](#第-25-章-文件-io-与二进制序列化)
- [第 26 章 定时器、时间与系统限制](#第-26-章-定时器时间与系统限制)
- [第 27 章 日志（logger）与可观测性](#第-27-章-日志logger与可观测性)
- [第 28 章 调试、热加载与运维](#第-28-章-调试热加载与运维)

**附录**

- [第 29 章 构建与验证](#第-29-章-构建与验证)
- [第 30 章 坑总表](#第-30-章-坑总表)

---

## 第 0 章 环境与工具链

### 0.1 需要什么

只需要两个可执行文件：

- `erl` —— 虚拟机 + REPL
- `erlc` —— 编译器

本仓库的所有验证都在 MacPorts 的 Erlang/OTP 29（erts 17.0.3）上完成：

```console
$ erl -noshell -eval 'io:format("~s/~s~n",
    [erlang:system_info(otp_release), erlang:system_info(version)]), halt(0).'
29/17.0.3
```

### 0.2 一条命令跑完本教程的全部示例

```bash
cd erlang
./run-all.sh           # shell 版入口（macOS / Linux / WSL）
pwsh ./build.ps1 -All  # PowerShell 版入口（Windows / macOS / Linux）
```

两个入口做完全一样的事：编译 `examples/` 下 28 个示例，每个跑两遍（两种调度器配置），
逐条比对输出。详见[第 29 章](#第-29-章-构建与验证)。

### 0.3 编译单个文件、跑单个示例

```bash
# 编译：产物 .beam 落到 build/ebin
erlc -Wall -Werror -o build/ebin examples/01-hello.erl

# 运行：模块名就是文件名（去掉 .erl）
erl -noshell -pa build/ebin -run 01-hello main -s init stop
```

几个开关值得记住：

| 开关 | 作用 |
| --- | --- |
| `-noshell` | 不进 REPL，跑完就走 |
| `-pa <目录>` | 把这个目录加进代码搜索路径 |
| `-run <模块> <函数> [参数...]` | 启动后调用这个函数；参数按原样传给函数 |
| `-s <模块> <函数>` | 类似 `-run`，但会把参数打包成一个列表 |
| `+S 1:1` | 只用 1 个调度器（本教程用它做第二条验证通道，见第 29 章） |

> **注意模块名要加引号**。文件名 `01-hello.erl` 对应的模块名是 `'01-hello'` ——
> 它以数字开头又带连字符，**不是合法原子**，必须写成引号原子：
>
> ```erlang
> -module('01-hello').
> ```
>
> 命令行里不用加：`-run` 的参数本来就是字符串，`list_to_atom` 一下就行。

### 0.4 `-Wall -Werror` 是本教程的默认

所有示例都用 `-Wall -Werror` 编译：**任何警告都算失败**。这不是偏执，而是 Erlang 的编译器
能在编译期就把一大批"必然失败"的代码找出来：

```erlang
%% 这三行都会被 -Wall 拒绝，根本不让你运行
N = list_to_integer("abc"),        %% will fail with a 'badarg' exception
{ok, X} = {error, boom},           %% no clause will ever match
V = maps:get(k, not_a_map),        %% will fail with a '{badmap,not_a_map}' exception
```

这带来一个反直觉的后果：**想在示例里演示运行期错误，输入必须来自参数或函数返回值**，
不能写成编译器能算出结果的常量。本教程到处可见下面这种写法，原因就在这里：

```erlang
%% 让编译器看不出这是 0 —— 否则它会直接判 "will fail with a badarith"
opaque_zero() -> length(lists:seq(1, 0)).
```

### 0.5 本文用到的两个 Erlang 术语

- **arity**：函数的参数个数。`foo/1` 和 `foo/2` 是两个完全不同的函数。
- **term**：任何一个 Erlang 值（整数、原子、元组、列表、map、二进制……）。这是 Erlang 的
  "值"的正式叫法。

---

## 第 1 章 模块、函数与 Hello World

**示例**：`examples/01-hello.erl`

### 1.1 一个模块的最小结构

```erlang
-module('01-hello').          %% 模块名必须与文件名一致
-export([main/0, greet/1]).   %% 只有导出的函数才能从外面调用

main() ->
    greet("Erlang/OTP").

greet(Name) ->
    io:format("Hello, ~s!~n", [Name]).
```

三件事和其他语言不一样：

1. **`-` 开头的行是属性（attribute），不是语句**。`-module` / `-export` 是给编译器看的。
2. **函数是用多个"子句"（clause）写的，子句之间用 `;` 分隔、最后用 `.` 结束**。
   忘写 `.` 或用错 `;` 是本语言最常见的语法错误。
3. **导出表写的是 `名字/元数`**。`greet/1` 和 `greet/2` 是不同函数，都要单独导出。

### 1.2 常用格式指令（实测）

`io:format` 的第二个参数永远是一个列表，列表里的每一项对应格式串里的一个 `~`。

```
== 2) 常用格式指令 ==
  ~p       项打印；可打印的字符列表打成字符串  ->  "abc"
  ~w       项打印；不套用字符串美化  ->  [97,98,99]
  ~p       对照：~p 遇到非 latin1 原子会转义  ->  '\x{4E2D}\x{6587}'
  ~tp      ~p 的 unicode 版：非 latin1 原子原样输出  ->  '中文'
  ~ts      按 unicode 打印字符串或 utf8 二进制  ->  中文
  ~s       按 latin1 打印；码点 > 255 会 badarg  ->  abc
  ~b       十进制整数  ->  255
  ~.16B    十六进制（~B 的「精度」就是进制）  ->  FF
  ~.2B     二进制  ->  101
  ~.8B     八进制  ->  10
  ~c       按字符打印一个整数  ->  A
  ~f       定点浮点，默认 6 位小数  ->  3.141590
  ~.2f     两位小数  ->  3.14
  ~e       科学计数法  ->  1.23450e+3
  ~p       元组  ->  {a,1}
  ~p       列表  ->  [1,2,3]
  ~p       原子（含空格时会自动加引号）  ->  'has space'
  ~~       正文中的字面波浪号  ->  100~%
```

> **`~p` 和 `~w` 是真的不一样**，这条在写测试时特别要命：
>
> ```erlang
> io:format("~p~n", [[97,98,99]]).   %% "abc"     —— 当成字符串美化了
> io:format("~w~n", [[97,98,99]]).   %% [97,98,99] —— 不美化
> ```
>
> 想看到列表里的**数字**，必须用 `~w`。本教程的示例里因此有两个辅助函数：
> `d/2` 用 `~p`、`ds/2` 用 `~w`。
>
> **`~p` 只对 latin1 可打印字符生效**：一旦列表里有中文，`~p` 就退化成整数列表。
> 要打印含中文的字符串用 `~ts`。

### 1.3 宽度与对齐

```
  [      ab][ab      ]   左对齐用负宽度
  [      42][42      ]
  零填充日期：09-16-2026
  零填充十六进制：000000FF
```

```erlang
io:format("[~10s][~-10s]~n", ["ab", "ab"]),   %% -N 是左对齐
io:format("~2.10.0B~n", [9]),                 %% 零填充：字段宽 10，值 9
```

`~-Nts` 的宽度**按字符数算**。一个汉字在大多数终端里占 **2 列**，所以直接用 `~-40ts`
排中文表必然错位。示例 13 和 17 里各自实现了一个按 East Asian Width 补空格的 `pad/2`，
想排中文表就去抄它。

### 1.4 模块自身的元信息

```
  code:which('01-hello') 的文件名 = 01-hello.beam
  它所在的目录名                 = ebin
  ?MODULE                        = '01-hello'
  导出的函数个数                 = 7
  是否导出了 greet/1             = true
  是否导出了不存在的 nope/0      = false
```

注意导出的函数**自动包含** `module_info/0` 和 `module_info/1`（编译器加的），
所以上面是 7 个而不是你写的 5 个。

> **别在文档里打印绝对路径**。`code:which/1` 返回的是本机的绝对路径，它会随着你把仓库
> clone 到哪个目录而变化。示例里改成打印 `filename:basename(...)`，这样换台机器也能复核。

---

## 第 2 章 数值与算术

**示例**：`examples/02-numbers.erl`

### 2.1 整数是任意精度的

```
  2^64 = 18446744073709551616
  2^128 的十进制位数 = 39
  100!（末尾有几个 0） = 24
  (1 bsl 10000) 的位数 = 3011
```

没有 `int64` 溢出这回事。`1 bsl 10000` 是一个 3011 位的整数，算得出来。

### 2.2 数字字面量

```
  16#FF = 255
  2#1010 = 10
  8#777 = 511
  36#Z（最大进制 36） = 35
  1_000_000（下划线只是分隔） = 1000000
  $A（字符即码点） = 65
  $中 = 20013
```

`Base#Value` 的写法，**最大进制是 36**。`$X` 取字符的**码点**（不是字节），
所以 `$中 = 20013`。

### 2.3 位运算

```
  1 bsl 8 = 256           %% 左移
  256 bsr 4 = 16          %% 右移
  12 band 10 = 8
  12 bor 10 = 14
  12 bxor 10 = 6
  bnot 0（按位取反，负数） = -1
```

### 2.4 `div` / `rem` 一律向零截断

这一条很多人都记反：

```
   7 div 2 = 3
  -7 div 2 = -3           %% 不是 -4！向零截断
   7 div -2 = -3
  -7 div -2 = 3
   7 rem 2 = 1
  -7 rem 2（余数跟随被除数符号） = -1
   7 rem -2 = 1
  -7 rem -2 = -1
   7 / 2（/ 永远返回浮点） = 3.5
  1 div 0 会抛 = {error,badarith}
  恒等式 7 =:= (-7 div 2)*2 + (-7 rem 2) = true
```

**`rem` 的符号跟随被除数**（`-7 rem 2 = -1`），这和 C 的规则一致，和 Python 的取模
（`%` 结果同除数符号）相反。另外 `/` **永远返回浮点**，想要整除结果必须用 `div`。

### 2.5 浮点：溢出是 badarith，不是 inf

```
  0.1 + 0.2 = 0.30000000000000004
  0.1 + 0.2 =:= 0.3 = false
  float_to_binary(0.1) = <<"1.00000000000000005551e-01">>
  float_to_binary(0.1, [short])（最短往返表示） = <<"0.1">>
  1.0e308 * 10 = {error,badarith}
  1.0e308 * 10 会得到 inf 吗 = false
  0.0 / 0.0 = {error,badarith}
```

**Erlang 没有 `inf` / `nan`**。浮点溢出、非法运算一律抛 `badarith`。
涉及金额请用整数（分），这是 Erlang 圈的通行的默认做法。

### 2.6 取整

```
  trunc(2.7)  截断 = 2
  round(2.5)  四舍五入（.5 远离零） = 3
  round(3.5) = 4
  round(-2.5) = -3
  floor(-2.5) 向下 = -3
  ceil(-2.5)  向上 = -2
  trunc(-2.5) = -2
  io_lib:format("~.2f", [2.0/3]) = "0.67"
  io_lib:format("~.0f", [2.5]) 会抛 = badarg
```

`round(-2.5) = -3`（.5 远离零，不是"银行家舍入"）。
`io_lib:format("~.0f", ...)` 会 **badarg** —— 想要整数用 `~.0B` 或 `trunc`。

### 2.7 `==` 和 `=:=` 是两套比较

```
  1 == 1.0（算术比较，会把整数提升为浮点） = true
  1 =:= 1.0（精确比较，类型也必须相同） = false
  1 /= 1.0 = false
  1 =/= 1.0 = true
  min(1, 1.0)（算术比较下两者相等，返回第一个） = 1
  1 < a（数字永远排在原子前面） = true
  lists:sort([b, 1, a, "x", 3.0]) 的项序 = [1,3.0,a,b,"x"]
```

**默认就用 `=:=` / `=/=`**。`==` 只在你想让整数和浮点互相"抹平"时才用。

Erlang 有一个**全序**（total ordering），任何两个 term 都能比大小：
`number < atom < reference < fun < port < pid < tuple < map < nil < list < bit string`。

---

## 第 3 章 原子、字符串与 Unicode

**示例**：`examples/03-atoms-strings.erl`

### 3.1 原子

```
  hello = hello
  'Hello'（大写开头必须引号） = 'Hello'
  'has space' = 'has space'
  '01-hello' = '01-hello'
  '中文' = '\x{4E2D}\x{6587}'
  atom =:= atom（原子比较是常数时间） = true
  本机原子表上限 = 1048576
  造一个不存在的原子会被拦下 = {error,not_existing}
```

规则：小写字母开头、只含字母数字下划线的可以直接写；其余一律加单引号 `'...'`。

**原子不会被 GC**。原子表上限（本机 1048576）一旦打满，节点直接被杀。所以：

> **永远不要拿外部输入去做 `list_to_atom`**（用户名、MQ topic、HTTP path……）。
> 想"查有没有这个原子"用 `list_to_existing_atom`（不存在就 badarg，**不会创建**）。

### 3.2 字符串就是整数列表

```
  "abc" =:= [97, 98, 99] = true
  length("abc")（按码点计数） = 3
  hd("abc") = 97
  "ab" ++ "cd" = "abcd"
```

`"abc"` 和 `[97,98,99]` 是**同一个东西**，`=:=` 都为 true。这是 Erlang 早期的设计，
好处是能用全部列表函数处理字符串，代价是它非常占内存（一个字符一个机器字 + 列表节点）。

### 3.3 二进制

```
  <<1, 2, 3>> = <<1,2,3>>
  byte_size(<<1,2,3>>) = 3
  bit_size(<<1:4>>)（按位） = 4
  <<1:16>>（默认大端） = <<0,1>>
  <<1:16/little>> = <<1,0>>
```

二进制**紧挨着放字节**，适合存大数据；而且它的匹配语法非常强（第 9 章）。

### 3.4 头号编码坑：`<<"中文">>` 会被 latin1 截断

这是本教程最高频的一个坑，看实测：

```
  $中 = 20013
  20013 rem 256 = 45
  <<"中">>（错！只剩一个字节） = <<"-">>
  <<"中"/utf8>>（对：三字节 UTF-8） = <<"ä¸­">>
  byte_size(<<"中">>) = 1
  byte_size(<<"中"/utf8>>) = 3
  纯 ASCII 时两者等价 = true
  unicode:characters_to_list(<<"中文">>) = {error,"-",<<135>>}
  unicode:characters_to_list(<<"中文"/utf8>>) = [20013,25991]
  list_to_binary 遇到 >255 的码点会 badarg = {error,badarg}
  正确做法 unicode:characters_to_binary([$中]) = <<"ä¸­">>
```

> **二进制字面量里的字符串默认是 latin1**。写成 `<<"中">>` 不会报错，
> 而是把码点 `20013` 截断成 `20013 rem 256 = 45`（也就是字符 `-`）。
> 写 UTF-8 必须显式加 **`/utf8`**：`<<"中文"/utf8>>`。
>
> `file:write_file` 同理 —— 详见第 25 章。

### 3.5 unicode / string 模块

```
  string:length("中文")（按字符数） = 2
  byte_size(<<"中文"/utf8>>)（按字节数） = 6
  string:uppercase("abc") = "ABC"
  string:split("a,b,c", ",", all) = ["a","b","c"]
  string:trim("  x  ") = "x"
  string:pad("7", 3, leading, $0) = ["00","7"]
  string:find("hello", "ll") = "llo"
  string:slice("hello", 1, 3) = "ell"
  string:lexemes("a,,b", ",") = ["a","b"]
  string:to_integer("42x") = {42,"x"}
  string:to_integer("x") = {error,no_integer}
```

注意 `string:length/1` 数的是**字素簇**（grapheme cluster），`length/1` 数的是码点，
`byte_size/1` 数的是 UTF-8 字节 —— 三个都可能不一样。

### 3.6 iolist：拼接不用复制

```
  嵌套的 iodata = ["a","bc",<<"def">>,[[<<"g">>]]]
  iolist_to_binary 扁平化 = <<"abcdefg">>
  iolist_size = 7
```

**iodata** = `binary | 0..255 的列表 | 两者的任意嵌套列表`。
`file:write_file`、`gen_tcp:send`、`iolist_to_binary` 都吃它。
它的价值：**拼接不需要复制**，直接把结构传下去就行。

---

## 第 4 章 模式匹配

**示例**：`examples/04-patterns.erl`

### 4.1 匹配就是分派

Erlang 没有 `switch`，函数的多个子句按从上到下的顺序尝试匹配：

```erlang
area({circle, R}) when R > 0    -> 3.14159 * R * R;
area({rect, W, H}) when W > 0   -> W * H;
area(Other)                     -> {error, {unknown_shape, Other}}.
```

```
  area({circle, 1}) = 3.1416
  area({rect, 0, 4})（guard 不通过，落到兜底子句） = {error,{unknown_shape,{rect,0,4}}}
  area(hexagon) = {error,{unknown_shape,hexagon}}
```

**总是留一个兜底子句**。漏了的话就是 `function_clause` 异常（第 15 章）。

### 4.2 各种地方都能匹配

```
  head_tail([1,2,3,4]) = {two_plus,1,2,[3,4]}
  [X, Y | Rest] = [1,2,3,4] = {1,2,[3,4]}
  有符号 <<X:16/signed>> = <<255,255>> = -1
  无符号 <<X:16/unsigned>> = <<255,255>> = 65535
  config_get(#{name => a, retries => 3}) = {ok,a,3}
  classify({point, 3, 3}) = {on_diagonal,{point,3,3},3}
```

注意 `[X, Y | Rest]` 这种写法 —— Erlang 允许一次性剥离多个元素，这在解析协议时非常方便。

### 4.3 变量的绑定规则

```
  same_or_diff({X, X}) 的判定 = [same,different,same,different]
  _ 不绑定任何变量 = ok
  {ok, V} = {ok, 42} 之后 V = 42
  {ok, V} = {error, 1} 会抛 = {error,{badmatch,{error,1}}}
```

`{X, X}` 这样的模式要求**两个位置相等**（"`X` 已绑定，这里复用它的值"）。
`{X, _X}` 才是"两个都取出来"。

`_` 是特殊的：它每次都是"新的"，不绑定任何东西。`_Foo` 会绑定但会告诉编译器
"我知道我不用它"，从而避免 unused variable 警告。

### 4.4 `=` 在函数体里就是断言

```
  X 已绑定为 1，再写 1 = X = 1
  再写 2 = X 会抛 = {error,{badmatch,1}}
  所以在函数里可以用 = 做断言 = 5
```

```erlang
%% 常见写法：断言调用一定成功
{ok, Socket} = gen_tcp:connect(Host, Port, Opts),
```

失败时抛 `{badmatch, Value}`，`Value` 是**右边真正的值**（不是左边的模式）——
这条对排查很有用。

---

## 第 5 章 卫语句（guard）

**示例**：`examples/05-guards.erl`

### 5.1 逗号是 and，分号是 or

```erlang
clamp(X, Lo, Hi) when Lo =< Hi, X < Lo  -> Lo;     %% 逗号：两个条件都要
clamp(X, Lo, Hi) when Lo =< Hi, X > Hi  -> Hi;
clamp(X, _Lo, _Hi)                      -> X.
```

```
  kind(5) = non_negative_int
  kind(-5) = negative_int
  kind(3.5) = zero_or_float
  kind(hello) = atom
```

> **注意这和大多数语言相反**：在 Erlang 里 `,` 表示"并且"、`;` 表示"或者"，
> 因为 Erlang 的标点符号跟 Prolog 学的是"逻辑连接词"，而其他语言学的是 C 的语句分隔符。

### 5.2 guard 里能用什么

guard 里**只能**用一小撮允许的东西（卫语句必须是"保证无副作用、保证会终止"的）：

- 比较运算符、`andalso` / `orelse` / `and` / `or` / `not`
- 类型测试：`is_atom` `is_binary` `is_list` `is_map` `is_integer` `is_pid` ...
- 一小组 BIF：实测可用的抽样子集：

```
  hd([1,2]) = yes
  length(L) =:= 3 = three
  abs(X) > 3 = big
  round(X) =:= 2 = two
  trunc(X) =:= 3 = three
  float(X) > 1.0 = big
  size(T) =:= 2（元组或二进制） = two
  map_size(M) =:= 1 = one
  map_get(a, M) =:= 1 = one
  is_map_key(a, M) = has
  bit 运算 (A band 1) =:= 0（偶数） = even
  element(1, T) =:= a = first_a
```

**不能**调用你自己写的函数。想复用逻辑就在函数体里用 `case`。

### 5.3 guard 失败 ≠ 异常

```
  first_or_empty([]) = empty
  first_or_empty([7]) = {first,7}
  函数体里 hd([]) 会抛 = {error,badarg}
```

guard 如果因为**任何原因**出错（`hd([])`、`1/0`）都会默默变成 `false`，
然后继续尝试下一个子句。这既是优点（容错）也是坑（掩盖了你的 bug）。

### 5.4 guard 里的 map 匹配（OTP 24+）

```erlang
classify(#{id := Id}) when Id > 0 -> {positive_id, Id};
classify(#{id := Id})             -> {other_id, Id};
classify(#{})                     -> empty_map;
classify(_)                       -> not_a_map.
```

注意 **`#{}` 匹配任何 map**（和 `:=` 相反：`#{id := _}` 要求必须有 `id` 键）。

---

## 第 6 章 递归与尾调用

**示例**：`examples/06-recursion.erl`

### 6.1 尾递归到底省了什么（实测）

```
  递归深度 = 200000
  非尾递归峰值内存 (words) = 2546256
  尾递归峰值内存 (words) = 2624
  两者结果相同 = true
  非尾递归内存 > 尾递归内存 * 10 = true
```

**970 倍**。这不是理论值，是量出来的。

差别在于调用的最后一步是什么：

```erlang
%% 非尾递归：最后一步是 +，得先算完递归才能加
sum(0)            -> 0;
sum(N)            -> N + sum(N - 1).

%% 尾递归：最后一步就是递归调用本身，调用者的栈帧可以直接复用
sum_tail(N)       -> sum_tail(N, 0).
sum_tail(0, Acc)  -> Acc;
sum_tail(N, Acc)  -> sum_tail(N - 1, Acc + N).
```

**只要一个进程活得久（服务器循环就是），它的循环函数必须是尾递归的**，
否则进程内存会一直涨到 OOM。

### 6.2 相互递归与 accumulate-then-reverse

```erlang
is_even(0) -> true;
is_even(N) -> is_odd(N - 1).
is_odd(1)  -> true;
is_odd(N)  -> is_even(N - 1).
```

```
  is_even/1 与 is_odd/1 互相调用 = [{0,true},{1,false},{2,true},{3,false},...]
```

尾递归构造列表的惯用法是**先 `[X|Acc]` 攒着、最后 `lists:reverse/1`**：

```
  尾递归版也能改写 map，只是要 reverse 一次 = [2,4,6,8]
```

### 6.3 用递归处理递归的数据结构

```erlang
eval({num, N})        -> N;
eval({add, A, B})     -> eval(A) + eval(B);
eval({mul, A, B})     -> eval(A) * eval(B);
eval({divi, _A, 0})   -> {error, divide_by_zero};
eval({divi, A, B})    -> eval(A) div eval(B).
```

```
  表达式 (2*3) + (10-4) = 12
  除零被兜底子句接住 = {error,divide_by_zero}
```

注意 `{divi, _A, 0}` 这个子句必须**放在** `{divi, A, B}` 前面 —— Erlang 按顺序匹配。

---

## 第 7 章 列表

**示例**：`examples/07-lists.erl`

### 7.1 取元素要看清是从 0 还是从 1

```
  lists:nth(2, L)（从 1 开始） = b
  lists:last(L) = e
  lists:sublist(L, 3)（前 3 个） = [a,b,c]
  lists:sublist(L, 2, 3)（从第 2 个起取 3 个） = [b,c,d]
```

`lists:nth/2` **从 1 开始**。想按 0 基取用 `lists:nthtail(N, L)` 或直接模式匹配。

### 7.2 foldl 构造列表是逆序的，foldr 是正序的

```
  lists:foldl(+, 0, L) = 15
  lists:foldr(+, 0, L) = 15
  foldl 构造列表（逆序） = [3,2,1]
  foldr 构造列表（正序） = [1,2,3]
```

加法是结合的所以看不出来，构造列表一下就暴露了：**foldl 从左往右访问**，
所以 `[X|Acc]` 攒出来是逆序；foldr 从右往左，`[X|Acc]` 攒出来是正序。

### 7.3 `lookup` 类函数的返回值不统一

```
  lists:keyfind(b, 1, L) = {b,2}
  lists:keyfind(z, 1, L)（找不到返回 false） = false
  lists:search(>2, [1,2,3]) = {value,3}
  lists:search(>9, [1,2,3])（找不到返回 false） = false
  maps:find 返回 {ok,V} 或 error = {{ok,1},error}
  ets:lookup 找不到返回 []
  proplists:lookup 找不到返回 none
```

**这四个"查不到"的返回值都不一样**（`false` / `error` / `[]` / `none`），
没有任何一致性可言，用之前一定先确认。这是 Erlang stdlib 最让人头疼的地方之一。

### 7.4 排序是稳定的

```
  lists:sort 是稳定排序 = [{1,a},{1,c},{2,b},{2,d}]
  lists:usort 去重并排序 = [1,2,3]
  lists:usort 按项序排列混合类型 = [1,2.0,a,b,"x"]
```

`lists:sort/2` 可以传自定义比较器，注意它要返回 **`=<` 语义**（相等返回 true）：

```erlang
lists:sort(fun(A, B) -> A >= B end, [1,3,2]).   %% 降序 → [3,2,1]
```

### 7.5 代价：不要在循环里 `++` 到尾巴

```
  朴素追加与「攒完再 reverse」结果相同 = true
```

```erlang
%% 慢：O(n^2)
bad([], Acc)      -> Acc;
bad([H|T], Acc)   -> bad(T, Acc ++ [f(H)]).

%% 快：O(n)
good([], Acc)     -> lists:reverse(Acc);
good([H|T], Acc)  -> good(T, [f(H)|Acc]).
```

`L1 ++ L2` 的代价正比于 `L1` 的长度 —— 把新元素加到**长列表的尾部**是最坏情况。

### 7.6 没有 `lists:group/1`，但有替代方案

```
  自实现 group/1（相等元素打包） = [[1,1],[2],[3,3,3]]
  配合 sort 就是 SQL 的 GROUP BY = [[a,a],[b,b],[c]]
```

Erlang/OTP 里**没有** `lists:group/1`。标准做法是 `lists:sort` 再打包，或者直接用
`maps:groups_from_list/2,3`（OTP 25+）。第 10 章有基于 map 的版本。

---

## 第 8 章 推导式

**示例**：`examples/08-comprehension.erl`

推导式（comprehension）对 **list / binary / map** 都有对应的写法。

### 8.1 基本形式

```erlang
[输出表达式 || 生成器, 过滤器]
```

```
  [X*2 || X <- [1,2,3]] = [2,4,6]
  [X || X <- 1..10, X rem 2 =:= 0] = [2,4,6,8,10]
  [N || {N, _} <- [{a,1},{b,2}]] —— 注意这里 N 是原子 = [a,b]
  模式不匹配会被跳过：[X || {X} <- [{1},{2},not_tuple,{3}]] = [1,2,3]
```

> **生成器里的模式不匹配会被静默跳过**，不是报错。上面 `not_tuple` 就被跳过了。
> 如果你要求"每一项都必须匹配"，必须自己显式做 `=`：
>
> ```erlang
> strict(L) -> [X || {X} = _Full <- L].     %% 这样不匹配的会抛 badmatch
> ```

### 8.2 多个生成器 = 嵌套循环（笛卡尔积）

```
  笛卡尔积 [[A,B] || A<-[1,2], B<-[x,y]] = [[1,x],[1,y],[2,x],[2,y]]
  20 以内的勾股数 = [{3,4,5},{6,8,10},{5,12,13},{9,12,15},{8,15,17},{12,16,20}]
  第二个生成器的范围由第一个决定 = [{1,1},{2,1},{2,2},{3,1},{3,2},{3,3}]
```

### 8.3 二进制推导式用 `<=` 而不是 `<-`

```
  <<<<X>> || <<X>> <= Bin>>（原样复制） = <<1,2,3,4,5,6>>
  <<<<(X*2)>> || <<X>> <= Bin, X rem 2 =:= 0>>（取偶数再翻倍） = <<4,8,12>>
  <<<<Y:16/little>> || <<Y:16/big>> <= <<1,0,2,0,3,0>>>> = <<0,1,0,2,0,3>>
```

两条硬规则：
- 生成器写 `<=`（左边允许任意二进制片段模式，包括变长的）；
- **输出表达式的结果必须是二进制**（所以通常写成 `<<...>>`）。

### 8.4 实战：几行搞定常用操作

```
  flatten_deep([1,[2,[3,[4]]],5]) = [1,2,3,4,5]
  保序去重 [3,1,3,2,1] = [3,1,2]
  带下标 [{1,a},{2,b}] = [{1,a},{2,b}]
  词频统计 = [{"a",3},{"b",2},{"c",1}]
  quicksort([3,6,1,8,2]) = [1,2,3,6,8]
```

quicksort 那两行是整个 Erlang 圈子最著名的代码片段：

```erlang
qsort([])     -> [];
qsort([P|Rs]) -> qsort([X || X <- Rs, X < P])
              ++ [P] ++
                 qsort([X || X <- Rs, X >= P]).
```

---

## 第 9 章 二进制与位语法

**示例**：`examples/09-binaries.erl`

位语法（bit syntax）是 Erlang 的独门武器：**同一套语法既能构造也能匹配**。

### 9.1 构造

```
  <<1, 2, 3>> = <<1,2,3>>
  <<255>>（单字节，取值必须 0..255） = <<"ÿ">>
  <<300:16>>（16 位存放 300） = <<1,44>>
  <<1:4, 2:4>>（两段拼成一个字节） = <<18>>
  <<1:1, 0:1, 1:1>>（只占 3 位） = <<5:3>>
  <<<<1,2>>/binary, <<3,4>>/binary>> = <<1,2,3,4>>
```

默认是**无符号大端 8 位**。每段的基本形式是 `Value:Size/TypeSpecifierList`。

### 9.2 匹配：解析变长报文太舒服了

```
  <<N:8, P:N/binary, T/binary>>（先读长度再读负载） = {3,<<"abc">>,<<"tail">>}
  模式里的字面量 <<"GET ", Path/binary>> = {ok,<<"/index">>}
  长度声明比实际数据长（没有子句可匹配） = {error,function_clause}
```

```erlang
parse_frame(<<1, 0, Len:8, Payload:Len/binary, Tail/binary>>) ->
    {ok, Len, Payload, Tail};
parse_frame(<<1, 0, Len:8, Short/binary>>) ->
    {incomplete, Len, byte_size(Short)};
parse_frame(<<1>>) ->
    {error, too_short}.
```

**同一道题用 C 写要手工算指针算术，这里就是三段模式。**

### 9.3 字节序与符号

```
  <<1:16/big>> = <<0,1>>
  <<1:16/little>> = <<1,0>>
  <<1:16/native>>（随机器） = <<1,0>>
  <<1:2/unit:8>>（2 个 8 位单元 = 16 位） = <<0,1>>
  按有符号读 <<255>> = -1
  按无符号读 <<255>> = 255
  <<1.0:32/float>>（IEEE 754 单精度） = <<63,128,0,0>>
  <<1.0:64/float>>（双精度） = <<63,240,0,0,0,0,0,0>>
```

UTF 类型也在这里指定：`/utf8` `/utf16` `/utf32`，
字节序用连字符 `-` 连接：`/utf16-little`、`/utf32-big`。

```
  <<$中/utf8>> 及字节 = {<<"ä¸­">>,"ä¸­"}
  <<$中/utf16>> 及字节（大端） = {<<"N-">>,"N-"}
  <<$中/utf16-little>> 及字节（小端） = {<<"-N">>,"-N"}
  <<$中/utf32>> 及字节 = {<<0,0,78,45>>,[0,0,78,45]}
  byte_size 分别是 = [3,2,4]
```

### 9.4 `binary` 模块

```
  binary:at(B, 1) = 2
  binary:part(B, 1, 3) = <<2,3,4>>
  binary:split(<<1,2,0,3,0,4>>, <<0>>, [global]) = [<<1,2>>,<<3>>,<<4>>]
  binary:split(<<1,2,3>>, <<3>>) = [<<1,2>>,<<>>]
  binary:match(<<1,2,3>>, <<2,3>>) = {1,2}
  binary:matches(<<1,2,1,2>>, <<1,2>>) = [{0,2},{2,2}]
  binary:decode_unsigned(<<1,0>>) = 256
  binary:encode_unsigned(256) = <<1,0>>
```

注意 `binary:split` **保留空片段**（分成 `[<<1,2>>, <<>>]`），而 `string:split` 的
`trim` 选项可以去掉它们 —— 两套模块的行为不一致，别想当然。

### 9.5 实战：一个带 CRC 的报文格式

第 25 章第 7 节里做了一个完整的：

```
  Magic 16 位 | Ver 8 | Type 8 | Len 16 | Payload Len 字节 | Crc 32
```

编码和解码几乎是同一份代码的镜像 —— 这就是位语法的价值。

---

## 第 10 章 映射（map）

**示例**：`examples/10-maps.erl`

### 10.1 `=>` 与 `:=` 的区别

```erlang
M#{b => 2}.      %% => 新增或覆盖都可以（upsert）
M#{a := 9}.      %% := 只覆盖，键不存在会 badkey
```

```
  M#{b => 2}（新增） = [{a,1},{b,2}]
  M#{a => 9}（覆盖） = [{a,9}]
  M#{zz => 1} 里用 := 会抛 badkey = {error,{badkey,zz}}
```

同样的区分也出现在**模式匹配**里：`#{k := V}` 要求键必须存在，`#{k => V}` 不匹配任何东西
（只有匹配 `:=` 才有意义）。

### 10.2 迭代顺序每次进程启动都随机

这是最容易踩的一条：

```
  排序后的键（稳定） = [a,b,c,y,z]
  to_list 排序后（稳定） = [{a,1},{b,2},{c,3},{y,25},{z,26}]
  maps:to_list 再排序才是稳定输出 = [{age,30},{name,"alice"}]
  所以「相等」要用排序后的列表判断 = true
```

> map 的内部结构 **small map 是扁平元组、large map 是 HAMT**，
> 遍历顺序取决于内部 bitset / 哈希。OTP 每次启动会**随机化原子哈希种子**，
> 于是 `maps:keys/1`、`maps:to_list/1`、`maps:fold/3` 的顺序不可预测。
>
> **任何要对比、要写进日志、要做测试的地方，一律先 `lists:sort`。**
> 本教程的每一条输出都是在 `+S 1:1`（单调度器）之外还要再跑一遍默认调度器，
> 并且要求**逐字节一致** —— 这条检查会把顺序问题直接暴露出来。

### 10.3 更新 API

```
  maps:put 与 => 等价 = [{a,1},{c,3}]
  maps:remove 删键（删不存在的键不报错） = [{a,1}]
  maps:take 返回 {值, 剩余} 或 error = {{1,#{}},error}
  maps:update_with(a, +1, 0, M) = [{a,2}]
  maps:merge 右侧优先 = [{a,1},{b,9}]
  maps:merge_with 冲突时用函数决定 = [{a,3}]
  maps:with 只保留指定键 = [{a,1},{c,3}]
  maps:without 排除指定键 = [{b,2},{c,3}]
```

`maps:update_with/4` 非常适合做计数器：`maps:update_with(K, fun(V) -> V+1 end, 1, M)`。

### 10.4 词频统计（两次 admitting 的用法）

```erlang
count(Words) ->
    lists:foldl(fun(W, Acc) -> maps:update_with(W, fun(N) -> N+1 end, 1, Acc) end,
                #{}, Words).
```

```
  词频统计 = [{"apple",3},{"banana",2},{"cherry",1}]
  按词长分组（每组内排序） = [{5,["apple","apple","apple"]},
                  {6,["banana","banana","cherry"]}]
```

---

## 第 11 章 记录（record）

**示例**：`examples/11-records.erl`

### 11.1 record 只是编译期的元组

```
  tuple_size(P) = 4
  element(1, P) 是标签 = person
  element(3, P) 是 age = 30
  可以直接用元组构造出等价的 record = true
  record_info(fields, person)（编译期展开） = [name,age,tags]
  record_info(size, person) = 4
```

```erlang
-record(person, {name, age = 0, tags = []}).

P = #person{},                    %% {person, undefined, 0, []}
P#person.name,                    %% 取值（编译期展开成 element/2）
Q = P#person{age = 31},           %% 更新（产生新元组，原值不变）
#person{name = N} = P,            %% 模式匹配
```

**record 没有运行期的自省能力**。你没法问"这个 record 有哪些字段"，
因为编译完之后它就是一个普通元组。想要动态字段请用 map。

### 11.2 record vs map 怎么选

| 场景 | 用什么 |
| --- | --- |
| 内部数据、字段固定、要模式匹配 | record（typed by tuple tag，可以区分不同类型） |
| 跨模块边界、要序列化成 JSON、字段可能变 | map |
| 需要判断"这是哪一种" | record（`is_record(P, person)`）；map 得靠tag 约定 |

实务上一个常见做法是：**对外用 map，内部用 record**，然后再写 `to_map/1` / `from_map/1`
（本章第 5 节就有）。

---

## 第 12 章 函数与 fun

**示例**：`examples/12-funs.erl`

### 12.1 四种写法

```
  匿名 fun fun(X) -> X * 2 end = 42
  多子句 fun = [positive,zero,negative]
  fun erlang:max/2 = 7
  fun local_helper/1 = 500
  erlang:fun_info(F1, arity) = 1
  erlang:fun_info 的 type / name = {local,local_helper}
```

注意 `fun local_helper/1` 这种写法：它引用的是**当前模块里**的函数。
模块热加载时行为不同（第 28 章）。

### 12.2 闭包捕获的是值，不是变量

```
  捕获 N=10 的 fun 调用 5 次 = 15
  同一个 fun 调三次结果相同 = {11,11,11}
  adder(2)(10) / adder(3)(10) = {12,13}
```

Erlang 是**不可变语言**，所以"闭包陷阱"根本不存在 —— 捕获的就是当时的值。

### 12.3 fun 当参数 / 返回值 / 数据结构

```
  用 fun 当比较器排序 = [3,2,1]
  用 fun 做按键提取再排序 = [{b,1},{c,2},{a,3}]
  校验器工厂 = [{min_len,true},{is_int,false}]
  第二次命中缓存 = {cached,36}
  用 map 做命令表（键排序后输出） = [{add,9},{mul,18},{sub,3}]
  把 fun 当消息发给另一个进程 = 21
```

### 12.4 匿名 fun 的递归

匿名 fun 不能直接调自己（没名字），要把自己当参数传进去：

```erlang
%% 标准写法
Fact = fun F(0) -> 1;
           F(N) -> N * F(N-1)
        end.
```

```
  匿名 fun 实现阶乘 fact(6) = 720
  具名函数 + fun 引用更清晰 = 720
```

> `fun F(...)` 里的 `F` 只在 fun 体内可见，这就是 Erlang 版的 Y 组合子写法。
> 大部分时候还是写成具名函数更清楚。

---

## 第 13 章 控制流与异常

**示例**：`examples/13-control-flow.erl`

### 13.1 case / if

```
  describe({ok, 1}) = {success,1}
  describe(42) = {unknown,42}
  没有兜底子句时抛 case_clause = {error,{case_clause,something_else}}
  if 没有 true 兜底时会抛 if_clause = {error,if_clause}
```

**`if` 的分支必须是 guard**，而且必须有一个 `true ->` 兜底，否则就是 `if_clause`。
大部分时候用 `case` 更好（`if` 里不能绑定新变量的模式）。

### 13.2 try 的三类异常与 reason 形状

```
  三类异常的 Class = [{error,error},{exit,exit},{throw,throw},{badarith,error}]
  只接 throw 类：写 throw:R 时 error/exit 类接不住 = [{error,{escaped,error,e}},
                                            {exit,{escaped,exit,x}},
                                            {throw,{caught_as_throw,t}},
                                            {badarith,{escaped,error,badarith}}]
  捕获时带上 stacktrace（长度 > 0） = true
  after 一定执行（无论正常还是异常） = {after_ran,true,value_delivered,true}
```

```erlang
try Expr of
    Pattern -> Body
catch
    Class:Reason:Stack -> Handler       %% Stack 是可选的第三段
after
    Always             -> cleanup
end
```

三类怎么用：

| 类 | 触发方式 | reason 形状 | 什么时候用 |
| --- | --- | --- | --- |
| `error` | 运行期错误（`badarg` 等）、`erlang:error/1` | `{Reason, Stacktrace}` 或裸 reason | 真正的 bug |
| `exit` | `exit(Reason)` | Reason 原样 | 进程要死（正常或异常终止） |
| `throw` | `throw(Value)` | `{nocatch, Value}` 未捕获时 | 非局部返回（少用） |

> **`catch Class:Reason` 里省略 Class 就默认是 `throw` 类**！上面那条实测就是证据：
> 写 `catch throw:R` 时 error 和 exit 类**穿透了**，由外层接住。
> 想全接要写 `catch _:_`。

### 13.3 `catch Expr` 已经废弃（OTP 29）

> 写 `catch Expr` 在 OTP 29 下会产生 **deprecation 警告**，配合 `-Werror` 直接编译失败。
> 它还会把三类异常压成三种不同形状的返回值，非常难用。一律改成 `try`。

### 13.4 maybe 表达式（OTP 25+）

maybe 解决"连续多个可能失败的步骤"：

```erlang
classify(X) ->
    maybe
        {ok, N} ?= to_int(X),
        true    ?= (N >= 0),
        {non_negative, N}
    else
        {error, R} -> {error, R};
        false      -> {error, negative}
    end.
```

```
  classify(5) = {non_negative,5}
  classify(-5)（?= 失败，值是 false → 命中 else 的 false 子句） = {error,negative}
  classify("abc")（?= 失败，值是 {error,not_a_number}） = {error,not_a_number}
```

三个必须知道的点（都是实测出来的）：

1. **`else` 只处理 `?=` 的失败**。body 里普通 `=` 失败会抛 `{badmatch, V}`，
   **直接穿透 `else`**：

   ```
     body 里写 true = N >= 0 的后果（badmatch 穿透 else） = {error,
                                                     {error,{badmatch,false}}}
   ```
2. **`else` 匹配的是"失败的那个值本身"**，不是构造函数。`{ok,N} ?= {error,R}` 时，
   失败值是 `{error, R}`，所以你要写 `{error, R} -> ...` 的分支去接它。
3. **`else` 也要兜底**，全不匹配会抛 `{else_clause, V}`。

### 13.5 选择建议

```
  函数参数的不同形状                       -> 函数多子句 + guard
  中间结果的形状                           -> case
  纯条件阶梯（无变量绑定）                 -> if（记得 true 兜底）
  可能失败的调用链                         -> try/catch，或返回 {ok,_}|{error,_}
  等消息 / 超时                            -> receive ... after
  连续多个可能失败的步骤                   -> maybe 表达式
```

---

## 第 14 章 高阶函数

**示例**：`examples/14-higher-order.erl`

### 14.1 fold 是通用递归模板

```
  原列表 = [1,2,3,4]
  自写 map（每个元素 +1） = [2,3,4,5]
  自写 filter（只留偶数） = [2,4]
  自写 reverse = [4,3,2,1]
  自写 append = [1,2,3,4]
  自写 sum = 10
  自写 max = 4
  fold_map 与 lists:map 一致 = true
```

`lists:foldl/3` 能表达**所有**左折叠能做的事 —— 理解了它就是理解了列表处理的一半。

### 14.2 any / all 会短路（用异常探针证明）

```
  lists:any 命中 hit 就返回，后面的 touched 不会被求值 = true
  lists:all 遇到第一个 false 就返回，后面的 touched 不会被求值 = false
  对照：lists:map 会遍历到底，于是碰到 touched 抛异常 = {error,error,probe_touched}
  对照：lists:foreach 同样遍历到底 = {error,error,probe_touched}
```

探针函数是一个"碰到就抛异常"的函数：如果它被求了值，我们就能看见。这是证明短路行为的
最简办法。

### 14.3 谓词 / 变换器 / 比较器

```
  原数据 = [{bob,30},{alice,25},{carol,35}]
  按名字排 = [{alice,25},{bob,30},{carol,35}]
  按年龄排 = [{alice,25},{bob,30},{carol,35}]
  按谓词挑（年龄 > 28） = [{bob,30},{carol,35}]
  用谓词取反 = [{alice,25}]
  变换器：把年龄换成出生年份（2026 - age） = [{bob,1996},{alice,2001},{carol,1991}]
```

把"比较什么"抽成一个 fun，就能一段代码到处复用：

```erlang
sort_by(KeyFun, List) ->
    lists:sort(fun(A, B) -> KeyFun(A) =< KeyFun(B) end, List).
```

### 14.4 组合 / 管道 / 柯里化

```
  compose(Double, Inc)(3) = 7
  compose(Inc, Double)(3)（顺序反过来结果就不同） = 8
  pipeline([Double, Inc, 平方])(3) = 49
  lists:map(adder(10), [1,2,3]) = [11,12,13]
```

顺带一条实测：`[11,12,13]` 这种列表用 `~p` 打印会变成 `"\v\f\r"`（因为它们都是可打印
ASCII 字符）。这在第 1 章讲过，这里又撞上一次。

### 14.5 用 fun 表示惰性序列

```
  从 1 开始取 5 个 = [1,2,3,4,5]
  偶数序列的前 5 个 = [2,4,6,8,10]
  惰性序列 + 变换 + 过滤（取前 4 个偶数的平方） = [4,16,36,64]
```

```erlang
nats_from(N) -> fun() -> {N, nats_from(N+1)} end.

take(0, _Gen) -> [];
take(K, Gen)  -> {V, Next} = Gen(), [V | take(K-1, Next)].
```

这就是 Erlang 版的流（stream）。实际项目里用 `streams` / `cut` 之类的库，
但原理就是这么简单。

---

## 第 15 章 错误处理哲学

**示例**：`examples/15-errors.erl`

### 15.1 三类异常

```
  error  -> Class = error, Reason = bug
  error  -> Class = error, Reason = badarith
  exit   -> Class = exit, Reason = shutdown
  throw  -> Class = throw, Reason = early_return
  error({bad_input, S}) 风格的原因 = {error,error,{bad_input,"abc"}}
```

### 15.2 什么时候用返回值，什么时候抛

```
  可预期失败：返回 {ok,_} / {error,_} = {ok,12}
  同样可预期失败（输入不是数字） = {error,{not_a_number,"abc"}}
  不该这样做：可预期失败却抛异常 = {error,error,{bad_input,"abc"}}
  替代方案：用 case 直接分派 = {failed,{not_a_number,"abc"}}
```

判断标准很简单：

- **调用方能做点什么吗？** 能 → 返回值（`{error, Reason}`）。
  比如"这个用户名不存在"，调用方该给用户一个提示。
- **调用方什么也做不了吗？** 是 bug → 让它崩。
  比如"数据库配置缺失"，只能由运维修。

这就是 Erlang/OTP 的 **let it crash**：不要把异常藏在一个试图自愈的 try/catch 里，
而是让它崩掉，让**监督者**把状态恢复到一个已知的良好起点（第 22 章）。

### 15.3 常见运行期错误 Reason 全表（实测）

```
  badarg（参数类型/取值不对）                      = {error,badarg}
  badarith（算术错误，除零等）                     = {error,badarith}
  badmatch（模式匹配失败）                       = {error,{badmatch,{error,boom}}}
  function_clause（函数没有匹配的子句）             = {error,function_clause}
  undef（模块或函数不存在）                        = {error,undef}
  badarity（调用 fun 时参数个数不对）               = {error,{badarity,{'<fun>',[1,2]}}}
  try_clause（try 的 of 子句都不匹配）            = {error,{try_clause,1}}
  case_clause（case 的子句都不匹配）              = {error,{case_clause,1}}
  if_clause（if 没有真分支）                    = {error,if_clause}
  badmap（拿非 map 当 map 用）                 = {error,{badmap,not_a_map}}
  badkey（map 里没有这个键，maps:get/2）          = {error,{badkey,missing}}
  system_limit（超长原子等资源上限）                = {error,system_limit}
  timeout_value（receive 的超时为负）           = {error,timeout_value}
```

规律值得记住：

- `badmap` / `badkey` 的 Reason 是 `{badmap, X}` / `{badkey, K}` —— 带参数；
- `badmatch` / `case_clause` / `try_clause` 都把**触发的那个值**带在 Reason 里；
- `function_clause` / `if_clause` / `undef` / `badarg` / `badarith` 是**裸原子**。

> 注意 `'<fun>'` —— 那条输出里把 fun 归一化成了占位符。
> 真实 reason 里是一个 fun，**直接打印会带上模块版本/pid 之类的每次都不一样的东西**。
> 本教程的示例里都有一个 `norm/1` 做这种归一化，否则输出的不可重复性会让验证失败。

### 15.4 编译期就能发现的"必然失败"

见第 0.4 节。`-Wall` 能抓到 `list_to_integer("abc")` 这类写死的必然失败。
**想演示运行期错误，输入必须来自参数**。

### 15.5 从一个外部进程观察崩溃

```
  （先摘掉默认 logger handler，否则 stdout 里会混进带时间戳的 ERROR REPORT）
  观察 error_class 类崩溃的 DOWN 原因 = {down,
                                 {error,boom,top_frame,
                                  {'15-errors',crash,1},
                                  stack_non_empty,true}}
  观察 exit_class 类崩溃的 DOWN 原因 = {down,{other_class,reason_x}}
  观察 throw_class 类崩溃的 DOWN 原因 = {down,
                                 {error,
                                  {nocatch,tossed},
                                  top_frame,
                                  {'15-errors',crash,1},
                                  stack_non_empty,true}}
  观察者进程自己没事（同一个进程连续观察三次也没崩） = true
```

三条规矩：

1. **monitor 不会把崩溃传染给观察者**，link 会（第 20 章）。
2. `error` 类崩溃的 DOWN reason 是 `{Reason, Stacktrace}`；`exit` 类是 Reason 原样；
   未捕获的 `throw` 变成 `error` 类、reason 是 `{nocatch, Value}`。
3. **默认 logger handler 会把 error 类的进程崩溃异步打到 stdout**：
   `=ERROR REPORT==== 16-Sep-2026::20:27:48.198791 ===` 这种带时间戳的行。
   它会污染你的输出（也让确定性验证失败）。示例里第一步就
   `_ = logger:remove_handler(default),`。

实测的边界：**默认 handler 只上报 error 类与未捕获的 throw**。
`exit(reason_x)` / `exit({shutdown,_})` / `exit(normal)` / `exit(kill)` **都不上报**。

### 15.6 加一层上下文再抛出

```erlang
with_context(F) ->
    try F()
    catch Class:Reason:Stack -> erlang:raise(Class, {context, Reason}, Stack)
    end.
```

```
  原始异常 = {error,error,boom}
  包了一层 context 之后（注意 Reason 变了） = {error,error,{context,boom}}
  栈顶仍是真正的出错函数（因为 Stack 一起传下去了） = {'15-errors',crash,1}
```

**第三个参数（Stack）一定要传**，否则栈会被重置到你的 `raise` 处，你就看不出真正
出错的地方了。

---

## 第 16 章 proplists 与配置

**示例**：`examples/16-proplists.erl`

**proplist**（属性列表）是 `[{K,V} | K]` 这样的列表：允许重复键，允许用裸原子表示
`{K, true}`。OTP 的几乎所有老 API 的选项参数都是它。

### 16.1 读取：裸原子等价于 `{K, true}`

```
  proplists:get_value(verbose, Opts) = true
  proplists:get_value(debug, Opts)（裸原子等价于 {debug,true}） = true
  proplists:get_value(missing, Opts) → undefined = undefined
  proplists:get_value(missing, Opts, 默认值) → 用第三个参数兜底 = 60
  proplists:lookup(missing, Opts) = none
  proplists:get_keys(Opts)（裸项也算键） = [debug,retries,verbose]
```

> `get_keys/1` 内部用的是 **sets**，所以结果**去重 + 顺序随机**。
> 要稳定就得 `lists:sort`。

### 16.2 `property/1,2` 是构造器，不是判定器（对着源码核过）

这是我一开始完全记错的一组函数，看实测：

```
  property(a, 1) → 构造 {a,1} = {a,1}
  property(a, true) → 缩成裸原子 a = a
  property({a, true}) → 归一化成裸原子 = a
  property({a, 1}) → 原样 = {a,1}
  property(42) → 原样返回（它不做合法性判断！） = 42
```

源码（`stdlib/src/proplists.erl`）就是：

```erlang
property({Key, true}) when is_atom(Key) -> Key;
property(Property)                      -> Property.

property(Key, Value) when Key =:= true; Key =:= false -> erlang:error(badarg);
property(Key, true) when is_atom(Key)                 -> Key;
property(Key, Value)                                  -> {Key, Value}.
```

所以 `property/1` 是**归一化器**，`property/2` 是**构造器**，两者都不是"这是不是合法
属性"的判断函数。

### 16.3 重复键是 proplist 的看家本领

```
  同一个键出现三次 = [{level,warn},{level,info},{level,debug}]
  get_value 取**第一个** = warn
  get_all_values 取全部（返回的是值列表） = [warn,info,debug]
  对照 map：from_list 之后只剩最后一个 = [{level,debug}]
  默认值 + 用户值，用户值放前面 → 用户赢 = [{retries,3},{timeout,5}]
```

**搭配 `++` 实现"默认值 + 覆盖"**是 OTP 里最常见的写法：

```erlang
Opts = UserOpts ++ Defaults,     %% 用户值在前，get_value 取第一个 → 用户赢
```

### 16.4 `unfold` / `compact` / `expand`

```
  unfold([a, {b,2}, {c,[1,2]}])（只动裸原子） = [{a,true},{b,2},{c,[1,2]}]
  compact([a, {b,true}, {c,1}])（{K,true} 缩成 K） = [a,b,{c,1}]
  normalize/2 的 stages 是空列表时等价于 compact = [a,{b,1}]
  expand(表, [debug])（裸原子会被展开） = [{debug,log},{debug,trace}]
  expand(表, [{debug,x}])（值是 x，不展开） = [{debug,x}]
  表里写 {{K,false}, ...} 时只匹配 {K,false} = [{debug,off}]
```

`expand/2` 的匹配规则（实测总结，很容易猜错）：

| 展开表的写法 | 匹配的输入 | 不匹配的输入 |
| --- | --- | --- |
| `{debug, Expansion}` | 裸原子 `debug`、**`{debug, true}`** | `{debug, x}`、`{debug, false}` |
| `{{debug, false}, Expansion}` | **`{debug, false}`** | 裸原子 `debug` |
| 其它任何键 | —— | —— |

`unfold/1` **只把裸原子变成 `{K, true}`，不会拆列表** —— 想拆 `{path, ["/a","/b"]}`
得用 `expand/2`。

### 16.5 带选项的 API 怎么写（一个模板）

```
  全用默认值 = {ok,[{mode,read},{retries,3},{verbose,false}]}
  改两个 = {ok,[{mode,write},{retries,0},{verbose,false}]}
  mode 非法 = {error,{bad_mode,destroy}}
  多写了不认识的键（应该报错，而不是静默忽略） = {error,{unknown_options,[retry]}}
```

```erlang
run(File, Opts) ->
    case validate_opts(Opts) of
        ok ->
            Mode    = proplists:get_value(mode, Opts, read),
            Retries = proplists:get_value(retries, Opts, 3),
            Verbose = proplists:get_bool(verbose, Opts),
            do_run(File, Mode, Retries, Verbose);
        {error, _} = E -> E
    end.
```

> **不认识的选项一定要报错**。静默忽略拼错的选项是生产事故的常见源头
> （`retry` 写成 `retries` 就永远不生效了）。

---

## 第 17 章 集合容器

**示例**：`examples/17-collections.erl`

### 17.1 三套集合实现

```
  输入（注意 a 出现两次） = [c,a,b,z,a]
  sets:to_list（顺序随机！必须 sort 才能比较） = [a,b,c,z]
  ordsets:to_list（有序列表实现，天然有序） = [a,b,c,z]
  gb_sets:to_list（树的中序遍历，也是有序的） = [a,b,c,z]
  sets 的内部表示（就是个 map：键=元素，值=占位） = [{a,[]},{b,[]}]
  ordsets 的内部表示（就是有序列表本身） = [a,b]
```

| | 内部实现 | 查询 | `to_list` 顺序 | 适用 |
| --- | --- | --- | --- | --- |
| `sets` | map | O(1) | **随机** | 频繁查成员、不在乎顺序 |
| `ordsets` | 有序列表 | O(n) 线性扫 | 有序 | 元素少（几十个）且要按序遍历 |
| `gb_sets` | 平衡二叉树 | O(log n) | 有序 | 元素多、要按序或取极值 |

**`sets:to_list/1` 的顺序也是随机的**（因为内部是 map），这在第 10 章讲过。

### 17.2 `gb_sets` 的独有能力

```
  smallest = 1
  largest = 9
  take_smallest → {取出的元素, 剩下的集合转成列表} = {1,[3,5,7,9]}
  take_largest = {9,[1,3,5,7]}
  iterator + next 按序取出全部 = [1,3,5,7,9]
  larger(4, G) → {found, 比 4 大的最小元素} = {found,5}
  smaller(4, G) → {found, 比 4 小的最大元素} = {found,3}
  larger(100, G) → 没有更大的，返回 none = none
```

`gb_sets` 是三套里功能最全的（也是唯一的排序语义完整的实现）。
注意它的返回值形状：`{found, X} | none`。

### 17.3 queue：FIFO

```
  peek = {value,1}
  head / last = {1,3}
  out → {取出的项, 剩下的队列转成列表} = {{value,1},[2,3]}
  in(4, Q) 从尾部加 = [1,2,3,4]
  in_r(0, Q) 从头部加 = [0,1,2,3]
  cons(0, Q) 等价于 in_r = [0,1,2,3]
  snoc(Q, 4) 等价于 in（注意参数顺序反了） = [1,2,3,4]
  join 把两个队列接起来 = [1,2,3,4,5]
  空队列：is_empty / peek / len = {true,empty,0}
```

> **`in/2` 和 `snoc/2` 的参数顺序是反的**：`queue:in(Item, Q)` vs `queue:snoc(Q, Item)`。
> 这是历史遗留，写的时候照着文档确认，别凭手感。

### 17.4 array：稀疏数组

```
  get(9)（越界！返回默认值而不是报错） = undefined
  array:set(1000, x, array:new()) 之后 = {size,1001,sparse_size,1001}
  to_orddict 的前 3 项（**含**默认值条目） = [{0,undefined},{1,undefined},{2,undefined}]
  sparse_to_orddict（只列真正设过的） = [{1000,x}]
```

`array` 的三个函数名字相近但语义完全不同（按官方文档核过）：

| 函数 | 含义 |
| --- | --- |
| `size/1` | 总条目数（**含**默认值的条目） |
| `sparse_size/1` | 到最后一个非默认值条目为止的条目数（不是"存了几个"） |
| `sparse_to_orddict/1` | 只列出真正设过的条目 —— **这才是你要的** |

越界 `get` **不报错**，返回默认值。

### 17.5 选择建议

```
  需要频繁成员判断、不在乎顺序      -> sets（O(1)，但 to_list 顺序随机）
  元素少（几十个以内）且要按序遍历  -> ordsets（实现就是有序列表，最省）
  元素多、要按序遍历或取最小/最大   -> gb_sets（O(log n)，功能最全）
  FIFO 队列                         -> queue（均摊 O(1)，别用 list ++）
  下标是整数、大部分为空            -> array
  键是任意项、要 O(1) 查找          -> map（第 10 章）
```

---

## 第 18 章 进程

**示例**：`examples/18-processes.erl`

### 18.1 三种 spawn

```
  spawn/1 的结果 = from_fun
  spawn/3（模块, 函数, 参数列表）的结果 = from_mfa
  spawn_monitor/1 的结果 = from_monitor
```

```erlang
Pid = spawn(fun() -> worker() end),               %% spawn/1
Pid = spawn(?MODULE, worker, [Arg1, Arg2]),       %% spawn/3 —— 热加载友好
{Pid, Ref} = spawn_monitor(fun() -> worker() end),%% 顺便监控
```

> **优先用 `spawn/3`（MFA 形式）**。它保存的是 `{M, F, A}`，
> 模块热加载时能拿到新代码；`spawn/1` 保存的是 fun 的闭包，会一直跑旧版本
> （第 28 章会详细讲）。

### 18.2 数据是拷贝，不是共享

```
  子进程看到的原始值 = [1,2,3]
  子进程「改」完的值 = [0,1,2,3]
  父进程的数据有没有被改？ = [1,2,3]
  父进程的数据与子进程看到的值相等吗（=:= 只比大小） = true
  子进程在自己字典里读到的 = written_by_child
  父进程读同一个键（进程字典也是每进程独立的） = undefined
```

这就是 Erlang 没有锁的原因：**每个进程有自己的堆**。代价是发大消息要做拷贝
（二进制 > 64 字节时只拷引用到共享堆，这是另一回事）。

### 18.3 注册名

```
  whereis(没注册过的名字) = undefined
  重名注册会 badarg = badarg
  unregister 之后 whereis 返回 = undefined
```

```erlang
register(my_server, Pid),
whereis(my_server).       %% undefined → 说明进程已经死了或根本没注册过
```

> **`whereis/1` 返回 `undefined` 不是崩溃**。别把结果直接当 pid 用，先判。

### 18.4 并行 map（一个可复用的模式）

```erlang
pmap(F, List) ->
    Parent = self(),
    Ref = make_ref(),
    Pids = [spawn(fun() -> Parent ! {Ref, self(), catch F(X)} end) || X <- List],
    [receive {Ref, P, R} -> R end || P <- Pids].
```

```
  输入的平方（顺序版） = [1,4,9,16,25,36,49,64,81,100,121,144]
  输入的平方（并发的 pmap） = [1,4,9,16,25,36,49,64,81,100,121,144]
  两者完全一致吗 = true
```

两个关键点：

1. **用 `make_ref()` 打标记**，避免捡到别人发来的消息（第 19 章有血泪教训）；
2. **按 `Pids` 的顺序收**，`receive` 里用 `P` 做模式，这样即使回复乱序，
   结果列表的顺序仍然和输入一致。

### 18.5 进程字典：知道就好，别用

```
  put 之后本进程 get 得到 = 42
  get/1 取不存在的键返回 = undefined
  另一个进程里 get 同一个键（看不到！） = undefined
```

它是每进程独立的全局可变状态 —— 破坏引用透明性、没法测、和 ETS 的语义混淆。
只在两个地方还会见到：`proc_lib` 的 `$ancestors` / `$initial_call`（第 28 章），
以及某些老库的 hack。

---

## 第 19 章 消息传递

**示例**：`examples/19-messaging.erl`

### 19.1 邮箱语义

```
  塞完三条后 message_queue_len = 3
  只取匹配 {tag,_} 的第一条 = 1
  不匹配的 other 还留着 → message_queue_len = 2
  把剩下的 other 取掉 = picked
  邮箱清空后 message_queue_len = 0
```

- 每个进程**一个**邮箱；多个发送者可以往里面塞（`!`）。
- `receive` 是**选择性接收**：扫描邮箱找到第一个匹配的，不匹配的留在里面。
- 同一发送者的两条消息**保证按发送顺序到达**；不同发送者之间只有很弱的保证。

### 19.2 发给已死进程不报错

```
  往它发消息的返回值（就是被发的那个值，没有报错） = hello_dead
  发送后依然没有异常，本进程邮箱长度 = 0
```

`Pid ! Msg` 的**返回值就是 Msg 本身**。这是唯一一个"返回值不是调用结果"的操作，
也是 Erlang 里 `!` 可以链起来的原因：`Pid1 ! Pid2 ! Msg`。
发给死进程静默丢弃 —— 所以你需要 `monitor`（第 20 章）来感知对方的死亡。

### 19.3 不带 ref 的协议会被乱序回复搞错（实测）

这是本章最重要的一条。看实测：

```
  朴素协议：调用方以为第一条回复属于 a_request = {b_request,222}
  朴素协议：以为第二条属于 b_request = {a_request,111}
  （上面读到的其实是 b 的回复和 a 的回复 —— 配对错了）
  带 ref：a_request 的回复（即使它后到） = {a_request,111}
  带 ref：b_request 的回复（即使它先到） = {b_request,222}
```

服务实现故意先回第二条请求，于是**朴素协议拿错了答案且不报错**。

**所以标准协议一定是这样的：**

```erlang
%% 调用
Ref = make_ref(),
Server ! {self(), Ref, Request},
receive
    {Ref, Reply} -> Reply
after 5000 -> {error, timeout}
end.

%% 服务
handle({From, Ref, Request}, State) ->
    From ! {Ref, do(Request, State)}.
```

这也是 `gen_server:call` 内部做的事。

### 19.4 超时与迟到回复

```
  只等 50ms → 超时 = timeout
  迟到回复已在邮箱里（message_queue_len） = 1
  flush(Ref) 之后还能读到它吗 = clean
```

> **超时之后回复可能还是来了**，而且会留在邮箱里污染后续所有的 `receive`。
> 超时后一定要用一个新的 ref，并且把旧的 ref 的消息清掉。

### 19.5 选择性接收的代价

```
  先塞 1000 条不匹配的消息，邮箱长度 = 1000
  再塞一条匹配的 = 1001
  取出匹配的那条 = found
  取完之后邮箱长度（1000 条噪音还在） = 1000
```

`receive` 每次从**邮箱头**扫到第一个匹配的消息。如果邮箱里堆了十万个没人认的消息，
每次 `receive` 都是 O(n)。

> **结论**：协议必须保证"每个进程只收到自己认识的消息"。
> 垃圾消息进邮箱就是内存泄漏 + CPU 变慢。OTP 的标准做法是
> **每次请求都用新的 `Ref`**，并且 `gen_server` 会自动丢弃不认识的消息形状。

### 19.6 一个正经的协议：计数器服务

```
  新建服务，初始值 = 0
  add 5 的返回 = ok
  发一条 cast 之后立刻 get = 6
  发一个协议里没定义的请求（调用方会超时） = {error,timeout}
  服务进程被这条没人认领的消息影响了吗（还能正常 get） = 16
```

注意最后两条：服务没认那个请求，于是它留在邮箱里，但服务还在正常干活 ——
这就是选择性接收的代价，也是上面那句"必须每个 Request 带 Ref / 只发认识的消息"的原因。

---

## 第 20 章 链接与监控

**示例**：`examples/20-links-monitors.erl`

### 20.1 link vs monitor

```
  本进程（erl -run 启动）的 trap_exit = true
  新 spawn 的进程默认 trap_exit = false

  monitor 一个会崩的进程，收到 DOWN 的原因标签 = {crashed,boom,stack_non_empty,true}
  我还活着吗（monitor 不影响调用者） = true
  link 一个会崩的进程，收到 EXIT 消息 = {crashed,boom,stack_non_empty,true}
  monitor 的消息：{'DOWN', Ref, process, Pid, Reason}
  link 的消息：   {'EXIT', Pid, Reason}（仅 trap_exit 时才变成消息）
```

| | link | monitor |
| --- | --- | --- |
| 方向 | **双向** | 单向 |
| 对方死了 | 不 trap 的话**自己也会被带走** | 只收到一条 `DOWN` |
| 可重复 | 重复 link 要小心成对 pid | 可以 monitor 同一个进程多次（不同 Ref） |
| 用于 | 监督树的父子关系 | 观察别人的死活 |

> **一个反直觉的实测**：用 `erl -run` 启动的那个进程，它的 `trap_exit` **本来就是
> `true`**；你自己 `spawn` 的进程才是 `false`。所以在 REPL / `-eval` 里手测 link 行为时，
> 你会以为 link 不会传染 —— 那是因为你在一个特殊进程里。

### 20.2 exit 消息里的 reason 形状

```
  error 类：reason 是 {原因, 栈} = {crashed,boom,stack_non_empty,true}
  exit(R)：reason 就是 R = reason_x
  throw 未捕获：{nocatch, Value} = {crashed,{nocatch,tossed},stack_non_empty,true}
  正常结束：normal = normal
```

和第 15 章从 monitor 看到的 DOWN reason 完全一致。

### 20.3 `exit(Pid, kill)` 不可捕获

```
  开了 trap_exit 的目标：普通 exit 信号被它处理掉了，终止原因是 = handled_exit_message
  同一个目标改用 kill：照样死，且原因是 = killed
```

`kill` 是**不可捕获的终止信号**。开了 `trap_exit` 的目标也没法把它变成消息，
它一定会被打死，reason 就是 `killed`。这是监督者在正常关闭流程超时后的最后手段。

### 20.4 手写这套东西为什么不够

```
  · 我崩了要重启 → 谁负责重启？重启几次？太频繁要不要放弃？
  · 我崩了要通知别人 → 通知谁？通知完对方该做什么？
  · 启动顺序有依赖 → 数据库没起来时，缓存进程该不该启动？
  · 关闭顺序有依赖 → 关的时候谁先谁后？关不掉怎么办？
```

这四个问题的答案，OTP 已经替你写好了：**supervisor + application**。
第 21、22、23 章。

---

## 第 21 章 gen_server

**示例**：`examples/21-gen-server.erl`

`gen_server` 是 OTP 里最常用的**行为**（behaviour）。它把"一个服务进程"的样板代码
（收消息、超时、系统消息、关闭流程、调试支持）全包了，你只写 6 个回调。

### 21.1 一个最小实现

```erlang
-module(my_kv).
-behaviour(gen_server).

%% API（给调用方）
-export([start_link/1, fetch/1, put/3, count/0, stop/0]).
%% 回调（给 gen_server 用）
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).

start_link(Tag) -> gen_server:start_link({local, ?MODULE}, ?MODULE, [Tag], []).
fetch(K)        -> gen_server:call(?MODULE, {fetch, K}).
put(K, V, Who)  -> gen_server:call(?MODULE, {put, K, V, Who}).
count()         -> gen_server:call(?MODULE, count).
stop()          -> gen_server:call(?MODULE, stop).

init([Tag]) -> {ok, #{tag => Tag, data => #{}, puts => 0}}.

handle_call({fetch, K}, _From, S) ->
    {reply, maps:get(K, maps:get(data, S), undefined), S};
handle_call(count, _From, S) ->
    {reply, maps:size(maps:get(data, S)), S};
handle_call(stop, _From, S) ->
    {stop, normal, ok, S};
handle_call(Other, _From, S) ->
    {reply, {error, {unknown_request, Other}}, S}.

handle_cast(_Msg, S) -> {noreply, S}.
handle_info(_Msg, S) -> {noreply, S}.
terminate(_Reason, _S) -> ok.
```

### 21.2 回调返回值全表

| 回调 | 返回值 | 含义 |
| --- | --- | --- |
| `init/1` | `{ok, State}` | 启动成功 |
| | `{ok, State, Timeout \| hibernate}` | 带超时/休眠 |
| | `{stop, Reason}` | 启动失败 |
| | `ignore` | 不启动（supervisor 会当作不存在） |
| `handle_call/3` | `{reply, Reply, State}` | 回一个值 |
| | `{reply, Reply, State, Timeout}` | 同上 + 超时 |
| | `{noreply, State}` | 不回（调用方会一直等到超时） |
| | `{stop, Reason, Reply, State}` | 先回 Reply，然后停止 |
| | `{stop, Reason, State}` | 停止（调用方 exit） |
| `handle_cast/2` | `{noreply, State}` / `{stop, Reason, State}` | |
| `handle_info/2` | 同 `handle_cast/2` | 处理任意消息 |
| `terminate/2` | 任意 | 忽略返回值 |

### 21.3 状态属于进程，不属于函数

```
  直接调 handle_call 并传一个空状态，拿到的 = undefined
  通过 gen_server:call 问服务进程，拿到的真实状态 = 100
  两个值不同 → 状态属于进程，不属于函数 = true
```

这是初学者的经典误解：`my_kv:handle_call(...)` 是**可以**直接调用的（它就是个普通
导出函数），但拿到的状态是你传进去的那个，不是服务进程里的。

### 21.4 call / cast / info

```
  cast 的返回值（只表示消息发出去了） = ok
  服务处理完定时消息后主动通知我们（Tag 对上号） = {ticked,cast_demo,ok}
  cast 之后立刻 call（FIFO 保证顺序） = 1
```

- `gen_server:call` —— 同步，带超时（默认 5000ms），内部用的就是带 `Ref` 的协议。
- `gen_server:cast` —— 异步，返回 `ok` 只表示"消息发出去了"。
- **同一个进程的邮箱是 FIFO 的**，所以"cast 完再 call"能保证 call 处理时 cast 已经
  被处理过了。这是 Erlang 里一个很有用的隐含时序保证。
- `handle_info/2` 处理**不是** call/cast 形状的任意消息（定时器、监控、裸消息）。

### 21.5 回调里抛异常会怎样

```
  调用会崩的请求，调用方收到 = {exit,
                      {call_failed,
                          {crashed,callback_boom,stack_non_empty,true},
                          request,boom}}
  terminate 也被调用了（原因里带栈） = {crashed,callback_boom,stack_non_empty,true}
  服务进程还活着吗 = false
  注册名字释放了吗（whereis → undefined） = undefined
  再 call 一个已经没了的服务 = {exit,{call_failed,noproc,request,count}}
```

`gen_server:call` 失败时，调用方收到的是
**`{Reason, {gen_server, call, [Name, Request]}}`** 这样一个二元组 exit。
`Reason` 可能是：

- `{Reason0, Stacktrace}` —— 回调崩了；
- `noproc` —— 服务根本不存在；
- `timeout` —— 超时了。

> 本示例用一个 `describe_call_failure/1` 把 Reason 里的**栈剥掉**再打印。
> 否则输出里会带上 `file` / `line`，每次改代码都不一样。

### 21.6 优雅停止

```
  从 handle_call 里返回 {stop, normal, Reply, State} = stopped
  terminate 的原因 = normal
  gen_server:stop 的返回 = ok
```

### 21.7 一个必须知道的坑：自动导入的 BIF

```erlang
%% 这两行会让编译器报错：ambiguous call of overridden auto-imported BIF
-export([get/1, size/0]).
get(K)  -> ...
size()  -> ...
```

> `get/1`、`get/0`、`put/2`、`size/1`、`length/1`、`apply/2` 等是**自动导入的 BIF**。
> 你在模块里定义同名函数，模块内对它的调用就会有歧义，编译器直接报错。
>
> 两个办法：
> 1. **改名**（本教程的示例把 `get/1` 改成 `fetch/1`、`size/0` 改成 `count/0`）；
> 2. 加 `-compile({no_auto_import, [get/1]}).`
>
> **推荐改名** —— 名字撞 BIF 本身就说明这个名字取得太泛。

---

## 第 22 章 supervisor

**示例**：`examples/22-supervisor.erl`

### 22.1 三种重启策略（实测）

```
  one_for_one —— 谁崩了重启谁
      适用：进程之间互相独立
  one_for_all —— 任何一个崩了，全部重启
      适用：进程之间有强耦合，缺一不可
  rest_for_one —— 崩的那个 + 它之后启动的全部重启
      适用：有启动依赖（如先 DB 后缓存）
```

实测（三个孩子 a/b/c，启动顺序 a→b→c）：

```
  杀掉 c 之后被重启的是 = [c]                     %% one_for_one
  杀掉 c 之后被重启的是（三个都重启） = [a,b,c]    %% one_for_all
  杀掉 c（最后一个）之后被重启的是（只有它） = [c] %% rest_for_one
  杀掉 a（第一个）之后被重启的是（它和后面的） = [a,b,c]  %% rest_for_one
```

> **区分 `one_for_all` 和 `rest_for_one` 要杀最后一个孩子**：杀 c 时 rest_for_one
> 只重启 c，one_for_all 重启全部。杀 a 的话两者结果一样，看不出区别。

### 22.2 重启强度：intensity / period

```erlang
%% child spec / supervisor flags
#{intensity => 2, period => 1}     %% 1 秒内最多重启 2 次
```

```
  前两次杀掉都被重启了 = {[a],[a]}
  第 3 次之后 supervisor 自己的终止原因 = shutdown
  supervisor 死了以后孩子还在吗（which_children 会退出） = supervisor_gone
```

超过强度上限之后，**supervisor 自己会终止**（reason = `shutdown`）。
这是故意的：疯狂重启说明有系统性问题，再重启只会更糟 —— 把问题交给**上一层**
supervisor。这就是监督树的层次设计。

### 22.3 观察与运行期增删

```
  which_children 的稳定形状 = [{a,true,worker},{b,true,worker}]
  count_children = [{active,2},{specs,2},{supervisors,0},{workers,2}]
  start_child 之后 count_children = [{active,3},
                                   {specs,3},
                                   {supervisors,0},
                                   {workers,3}]
  重复 delete_child 的返回 = {error,not_found}
```

> **`which_children` 的返回顺序未定义**。想按 id 找孩子必须
> `lists:keyfind(Id, 1, Children)`，**不要**按下标取第一个（本示例一开始就是这么错的）。
> `count_children` 同理，比较前先 `lists:sort`。

`which_children` 的每一项是 `{Id, Child, Type, Modules}`（4 元）；
上面打印的是去掉 pid 之后的 3 元。

### 22.4 child spec 的两种写法（map 版）

```erlang
#{id       => kvapp_store,
  start    => {kvapp_store, start_link, []},
  restart  => permanent,        %% permanent | temporary | transient
  shutdown => 5000,             %% 毫秒 | brutal_kill | infinity
  type     => worker,           %% worker | supervisor
  modules  => [kvapp_store]}
```

| `restart` | 含义 |
| --- | --- |
| `permanent` | 崩了**一定**重启（默认、最常用） |
| `temporary` | 崩了**永远不**重启 |
| `transient` | 只有**异常**终止才重启（normal / shutdown / `{shutdown, _}` 不重启） |

---

## 第 23 章 application

**示例**：`examples/23-application.erl`，配套 `examples/kvapp/`

### 23.1 五层结构

```
  进程      spawn 出来的东西；不共享内存，只靠消息通信（18/19 章）
  监督树    谁挂了由谁负责重启（22 章）；它是「一个应用」的内部结构
  应用      本章：一棵进程树 + 一个 .app 文件，能被 application:start/1 整体拉起来
  节点      一个 erl 虚拟机实例；节点上跑着若干个应用
  发布      release：把若干应用 + 一个 ERTS 版本打包成可部署的目录
```

> **规则：一个应用只应该有一个顶层监督者**（由它的 `start/2` 启动）。
> 应用之间的依赖写进 `.app` 的 `applications` 字段，交给 OTP 去管启动顺序。

### 23.2 `.app` 资源文件

它是一个普通的 Erlang 项（用 `file:consult/1` 读的**数据文件**，不是模块）：

```erlang
{application, kvapp,
 [{description, "minimal OTP application demo (1 gen_server + 1 supervisor)"},
  {vsn, "1.0.0"},
  {modules, [kvapp_app, kvapp_sup, kvapp_store]},
  {registered, [kvapp_sup, kvapp_store]},
  {applications, [kernel, stdlib]},
  {mod, {kvapp_app, []}},
  {env, [{greeting, "hello from kvapp.app"}, {max_items, 100}, {store_mode, memory}]}]}.
```

```
  get_all_key 返回的字段总数 = 13
  字段名（排序后每行 4 个）
      applications, description, env, id
      included_applications, maxP, maxT, mod
      modules, optional_applications, registered, start_phases
      vsn
```

> **`get_all_key/1` 会把你没写的字段补成默认值**，这是最容易忽略的一点：
> `id = []`、`maxP = infinity`、`maxT = infinity`、`start_phases = undefined`。
>
> 另外：**`.app` 是 UTF-8 的**。`epp` 的默认编码就是 `utf8`，
> 所以你在 `.app` 里写中文描述是**没问题**的（我一开始以为要避免，实测推翻了）。

> ⚠ **`.app` 必须手工拷到代码路径上**。它是数据文件，`erlc` 不认。
> 忘了拷会得到 `{error,{"no such file or directory","kvapp.app"}}`。

### 23.3 生命周期

```
  start 一个**从没 load 过**的应用 = {error,{"no such file or directory",
                                     "nosuch_app_xyz.app"}}
  load = ok
  这时候 loaded_applications 里有它吗 = true
  但 which_applications（只列运行中的）里有吗 = false
  start（没有 mod 的「库应用」也能启动，直接返回 ok） = ok
  再 start 一次 = {error,{already_started,lifecycle_demo}}
  还在跑的时候 unload = {error,{running,lifecycle_demo}}
  stop = ok
  再 stop 一次 = {error,{not_started,lifecycle_demo}}
  stop 之后 env 还能读吗（能——stop 不清配置） = {ok,v}
  unload 之后 env 还能读吗（不能了） = undefined
```

四个动作：**load → start → stop → unload**。

- `load` 只读 `.app`、不启动任何进程；
- `stop` 只停进程树，**不清配置**；
- `unload` 才把配置一起摘掉。

### 23.4 应用环境（env）

```
  get_env(kvapp, max_items) 读 .app 里的默认值 = {ok,100}
  get_env(kvapp, 不存在的键) 返回 undefined = undefined
  所以推荐**永远用 get_env/3** 带一个兜底默认值 = my_default
```

几个反直觉的实测：

```
  set_env(一个从没见过的应用, k, v) = ok
    而且这个值之后真能读到 = v
    get_all_env/1 也读得到（env 是存在应用控制器里，不依赖应用文件） = [{k,v}]
    但 get_key(App, env) 读不到（那个要应用已 load 的记录） = undefined
  unset 之后：.app 的默认值**不会**自动恢复，读到 undefined = undefined
```

**env 是进程 init 时读一次的快照**，不是实时可变的：

```
  把 max_items 改成 2 = ok
    但当前这个 store 进程还是老值（它在 init/1 里读一次就定下来了） = {100,memory}
  stop = ok
    再 start（新进程会重新读 env） = ok
    重启后的容量（已经变成 2 了） = {2,memory}
```

### 23.5 关闭顺序（实测）

```
    [kvapp_app:prep_stop/1] 关闭前最后一刻，State=[]
    [kvapp_store:terminate/2] Reason=shutdown，关表时还剩 1 条
    [kvapp_app:stop/1] 监督树已经关完了，这里只能做收尾
```

1. `Mod:prep_stop/1` —— 开始关监督树之前，最后能读写自己状态的机会；
2. 监督者关掉它的孩子 —— gen_server 的 `terminate/2` 在这里被调到；
3. `Mod:stop/1` —— 树已经关完了，只能收尾。

> **最大的坑**：gen_server 默认 `trap_exit = false`，而监督者关闭孩子的方式是
> `exit(Child, shutdown)`。**不打开 `trap_exit`，`terminate/2 根本不会被调用** ——
> 你在里面写的落盘、关表全部丢失。
>
> ```erlang
> init([]) ->
>     process_flag(trap_exit, true),   %% 想要 terminate/2 被调用就必须加这一行
>     {ok, State}.
> ```
>
> 本教程的 `kvapp_store.erl` 就是为演示这一点写的。

### 23.6 `config_change/3` 只在发布升级时被调用

```
  1. 先拍「升级前」快照：覆盖了当前所有在跑的应用 = true
  2. 模拟装载新配置：改一个已有键 / 加一个全新键 / 删掉一个键
  3. 调 application_controller:config_change(EnvBefore)：
    [kvapp_app:config_change/3] 被调到了：
        Changed = [{greeting,"hello v2"}]
        New     = [{brand_new,42}]
        Removed = [max_items]
```

**`application:set_env/3` 不会触发 `config_change/3`**。它只由
`application_controller:config_change/1` 调用，而后者只有 **release_handler**（发布升级）
才会走。手工演示的顺序是：**先 `prep_config_change()` 拍快照 → 再改配置 →
再 `config_change(EnvBefore)`**，顺序反了就不会触发。

### 23.7 依赖与 `ensure_all_started`

```
  ensure_all_started(kvapp) 返回**这次真正启动了哪些应用**，按依赖顺序 = {ok,[kvapp]}
  已经有了，再 ensure 一次（什么都不用做 → 空列表） = {ok,[]}
  但 start/1 不管依赖，也不会替你判断已启动，直接报错 = {error,{already_started,kvapp}}
```

- 启动用 `ensure_all_started/1`（幂等，返回 `{ok, [这次启动的]}`）；
- 停止用 `stop/1`（**不会**反向停依赖）。

---

## 第 24 章 ETS

**示例**：`examples/24-ets.erl`

ETS（Erlang Term Storage）是**进程外的、可共享的**内存表。它是 mutable 的 ——
Erlang 里唯一的例外。

### 24.1 基本操作

```
  insert 一个列表（批量，比逐条快） = true
  tab2list（排序后） = [{a,1},{b,2},{c,3}]
  表里有几条（ets:size/1 **不存在**，要写 ets:info(T, size)） = 3
  lookup(不存在的键) → 空列表，不报错 = []
  同键再 insert 会**覆盖**（set 的语义） = [{a,999}]
  delete_object 只删匹配的那条 = true
```

> `ets:size/1` **不存在**（编译期不报、运行才炸）。查条数用 `ets:info(T, size)`。

### 24.2 四种表类型

```
  set              -> [{k,1}]
  ordered_set      -> [{k,1}]
  bag              -> [{k,1},{k,2}]
  duplicate_bag    -> [{k,1},{k,1},{k,2}]
```

- `set` / `ordered_set`：一个键一条（同键覆盖）；
- `bag`：一个键多条，但**完全相同**的行会去重；
- `duplicate_bag`：允许完全相同的行。

`ordered_set` 按 Erlang 项序排，可以做范围扫描（`ets:next` / `ets:prev`）。

### 24.3 match vs match_object vs select

```
  match(T, {'_', 2})（找值为 2 的项） = [[]]
  match_object(T, {'_', 2})（同条件，但要对象） = [{b,2}]
  match(T, {'_', '$1'}) 返回的是每个匹配项的 $1 绑定 = [[1],[2],[3]]
```

- `ets:match/2` 返回的是**变量绑定列表**（不是对象），所以要对象用 `match_object`；
- `ets:select/2` 才是完整的 match spec（能做比较、能做运算）。

match spec 的 body 写法实测（表里是 `{a,1},{b,5},{c,9}`）：

```
  ['$2']                  只想拿 $2                      => [1,5,9]
  ['$_']                  $_ 是**整个对象**               => [{a,1},{b,5},{c,9}]
  [{{'$1','$2'}}]         想造一个元组（多套一层）        => [{a,1},{b,5},{c,9}]
  [['$1','$2']]           想造一个列表                    => [[a,1],[b,5],[c,9]]
  [{'element',2,'$_'}]    用 BIF 取整个对象的第 2 个元素   => [1,5,9]
  [{'element',2,'$1'}]    ←错：$1 是键（原子），不是对象   => ['EXIT','EXIT','EXIT']
  [{'const',42}]          常量（每个对象都给一个 42）      => [42,42,42]
  [{'=:=','$2',5}]        只做判断，不做筛选              => [false,true,false]
  [{'$1','$2'}]           忘了多套一层 → badarg           => {error,badarg}
  [{'$2'}]                想拿 $2 却写成元组 → badarg     => {error,badarg}
  []                      空 body → badarg               => {error,badarg}
```

> **body 里的单元素元组会被当成"动作函数"**（`'$2'` 不是变量而是 `{action, ...}` 的头）。
> 想返回一个元组必须**多套一层**：`[{{'$1','$2'}}]`。

### 24.4 原子自增

```
  默认步长 1，返回自增后的值 = 1
  再来两次 = {2,3}
  步长写负数就是自减 = 1
  带门槛的写法 {Pos, Incr, Threshold, SetValue}：低于门槛就设为 SetValue = 11
```

`ets:update_counter/3` 是**原子**的：多个进程同时自增不会丢计数。
这是做限流器、计数器的首选（比"读出来 + 写回去"快一个数量级，而且正确）。

### 24.5 所有权与 heir

```
  子进程建成表后，表是存在的吗 = true
  owner 被 kill 之后，表还在吗 = false
  owner 死了，但我们（heir）会收到 ETS-TRANSFER 消息 = {got_transfer,my_data}
  表还活着吗 / 现在 owner 是本进程吗 = {true,true}
```

> **ETS 表属于创建它的进程，owner 死了表就没了**（没有 GC 但也没有引用计数）。
> 想让它"活过" owner，用 `{heir, Pid, Data}`：owner 死时表转移给 heir，
> heir 会收到 `{'ETS-TRANSFER', Tid, FromPid, Data}`。

### 24.6 选项的两种形状（实测）

```
  compressed               裸原子                      => ok
  named_table              裸原子                      => ok
  {keypos,2}               元组，对                    => ok
  {compressed,true}        ←错：裸原子写成元组          => {error,badarg}
```

有些选项是**裸原子**（`set` / `public` / `named_table` / `compressed`），
有些是**元组**（`{keypos, N}` / `{heir, Pid, Data}` / `{read_concurrency, Bool}`）。
把裸原子写成 `{compressed, true}` 会 badarg。

**另一个调度器相关的实测**：

```
  read_concurrency **不受**调度器个数影响 = true
  write_concurrency 读回来 = (调度器个数 > 1) = true
  decentralized_counters 走同一条规则（一起被降级） = true
```

> 在 `+S 1:1`（单调度器）下，`write_concurrency` 和 `decentralized_counters`
> 会被**静默降级成 `false`**。这不是 bug，但意味着"选项设置了"和"选项生效了"
> 是两回事 —— 要确认得读回来。

### 24.7 什么时候用 ETS

```
  一个进程的高频本地缓存            → 还是用 map（ETS 有额外开销）
  多个进程都要读同一份数据          → ETS（protected/public，读几乎无锁）
  要做「按键范围扫描」              → ordered_set
  计数器、限流、去重集合            → ETS + update_counter / insert_new
  数据必须跨进程重启还在            → ETS + heir，或者干脆用数据库
  需要事务语义（多表一起成功或失败） → mnesia（本章不涉及）
```

---

## 第 25 章 文件 I/O 与二进制序列化

> 示例：`examples/25-binary-files.erl`　输出：`build/25-binary-files/stdout.txt`

Erlang 的文件 I/O 分三层，先分清它们各自管什么，后面所有坑都源自"混用"：

| 层 | 模块 | 单位 | 典型函数 |
| --- | --- | --- | --- |
| 路径层 | `filename` | 字符串/binary | `join` / `split` / `basename` / `extension` |
| 文件层 | `file` / `filelib` | **字节** | `read_file` / `write_file` / `open` / `position` |
| 设备层 | `io` | **字符（码点）** | `get_line` / `put_chars` / `format` |

**一句话记住**：`file:*` 写的是字节，`io:*` 写的是字符。中文在这两层的表现完全不同。

### 25.1 路径用 filename，别手拼

```
  filename:join(["/tmp", "a", "b.txt"]) = "/tmp/a/b.txt"
  filename:split(上一条) = ["/","tmp","a","b.txt"]
  filename:basename = "b.txt"
  filename:dirname = "/tmp/a"
  filename:rootname（去掉扩展名） = "/tmp/a/b"
  filename:extension = ".txt"
    没有扩展名时 extension = []
    只有点开头的文件（.gitignore） = []
  filename:absname("b.txt") 转成了绝对路径（pathtype 验证） = absolute
  filename:pathtype（相对/绝对/卷相关） = absolute
    相对路径的 pathtype = relative
  filename:nativename 在 macOS 上就是原样 = "a/b"
```

手拼 `"a" ++ "/" ++ "b"` 在 Windows 上就是错的（分隔符是 `\`）。`filename:join/1`
会按当前系统的分隔符处理，**而且是唯一正确的拼法**。

两个反直觉的点（都实测过）：

```
  join 的第二参数给 binary 时返回什么类型 = {true,false}
    join 会保留 binary（不是自动转 list）—— 所以 file 模块两种都能吃 = <<"/tmp/erl-demo-25/b.txt">>
  filename:join 传入绝对路径的第二段（会直接替换） = "/c/d"
```

- `join` **保留参数的类型**：给 binary 就返回 binary。这正好，因为 `file` 模块两种都吃。
- `filename:join("a/b", "/c/d")` 得到 `"/c/d"` 而不是 `"/a/b/c/d"` —— 第二段是绝对路径
  就整体替换。这是 POSIX 的语义，不是 bug，但拼接用户输入时一定要先校验。

### 25.2 目录与元信息

```
  filelib:ensure_dir(一个还不存在的文件路径) = ok
    之后 sub 目录存在了吗 = true
    注意：ensure_dir 只建**目录**，不建文件 = false
  filelib:is_file / is_dir / is_regular = {true,false,true}
  filelib:file_size = 10
  filelib:last_modified 是个非零时间 = true
  read_file_info 返回一个 #file_info 记录 = true
    size = 10
    type = regular
    access = read_write
    mode（是个整数，按位存权限） = true
    mtime 是个非零时间 = true

  -- 列目录 --
  file:list_dir（排序后） = ["meta.txt","sub","y.dat","z.txt"]
  filelib:wildcard("*.txt") = ["/tmp/erl-demo-25/meta.txt",
                               "/tmp/erl-demo-25/z.txt"]
  wildcard 只匹配**文件名**，不对路径分隔符做特殊处理 = ["meta.txt","sub","y.dat","z.txt"]
  file:open 一个目录会怎样 = {error,eisdir}
  file:read_file 一个目录会怎样 = {error,eisdir}
```

> `filelib:ensure_dir/1` 的名字很骗人：参数是**文件路径**，但它只保证这个路径的
> **目录部分**存在，文件本身不会创建。想要文件还得自己 `write_file`。

> `filelib:wildcard/1` 的 `*` **不匹配路径分隔符**（和 shell 的 glob 一致，但和
> 很多语言的 `**` 不同）。要递归遍历目录得自己写递归。

注意最后两行：**打开/读取一个目录会返回 `{error, eisdir}`**，不是抛异常。
所以判断"这是目录还是文件"要用 `filelib:is_dir/1`，不要用 `file:open` 试探。

### 25.3 一次性读写与 iodata

```
  file:write_file（二进制） = ok
  file:read_file = {ok,<<"hello">>}
  file:read_file 一个不存在的文件（不抛，返回 error 元组） = {error,enoent}
```

`file` 模块的风格是**返回 error 元组而不是抛异常**（`enoent` / `eacces` / `eisdir` …）。
这是 Erlang 的标准做法：错误是数据，你可以用 `case` 处理，也可以不处理让它崩。

**iodata 是这章最值得记住的概念**：

```
  iodata = binary | 字节列表 | 这两者的任意嵌套列表。好处是拼接不用复制。
  写深嵌套 iodata = ok
    读回来 = {ok,<<"abcdefg">>}
  iolist_size（不用真的拼起来就能算长度） = 7
  iolist_to_binary（真的拼起来） = <<"abcdefg">>
  iolist_to_iovec 存在吗（OTP 里有） = true
```

`iodata()` 的定义是递归的：**binary 或 0..255 的整数，以及它们的任意嵌套列表**。
所以 `<<"ab">>, "cd", [<<"e">>, [102], <<"g">>]` 这种"千层饼"是合法 iodata。

好处是**拼接零拷贝**：要写 `[Header, Body, Footer]` 不需要先把它们拼成一个大 binary，
`file:write_file` / `gen_tcp:send` 会自己按片段写出去。这在构造大响应时差一个数量级。

`iolist_size/1` 只累加长度不复制，`iolist_to_binary/1` 才是真的拼。

```
  -- 追加 / 重命名 / 复制 / 删除 --
  write_file 加 [append] = ok
    读回来 = {ok,<<"abcdefg!">>}
  file:copy 返回拷贝的字节数 = {ok,8}
  file:rename = ok
  file:delete = ok
    删完之后 = false
  file:delete 一个不存在的文件（不报错） = {error,enoent}
```

`file:copy/2` 返回的是 `{ok, 拷贝的字节数}`，不是 `ok`。`file:delete/1` 删不存在的
文件返回 `{error, enoent}` —— 想做"存在就删"直接忽略返回值即可。

### 25.4 编码陷阱：这是全章最容易踩的一节

```
  "你好" 在内存里是码点列表 [20320, 22909]，而文件里存的是字节。
  file:write_file 要求参数是**字节** iodata（每个元素 0..255），
  所以直接把中文字符串交给它会 badarg —— 这是最常见的踩坑。

  写纯 ASCII 字符串（码点都 <= 255，正好合法） = ok
    读回来 = {ok,<<"abc">>}
  写含中文的字符串 "你好"（注意：是**返回** error 元组，不是抛异常） = {error,badarg}
  正确写法 1：<<"你好"/utf8>> = ok
    读回来（字节） = {ok,<<"ä½ å¥½">>}
    byte_size（UTF-8 下一个汉字 3 字节） = 6
  正确写法 2：unicode:characters_to_binary("你好") = ok
    byte_size = 6
```

两个要点：

1. **写 ASCII 字符串不会报错** —— 因为 `'a'` 到 `'z'` 的码点恰好 ≤ 255，正好是合法字节。
   所以"我本地测试没问题，一上中文就 badarg"。
2. **它是返回 `{error, badarg}` 而不是抛异常**。如果你没有匹配返回值，
   这段代码会静默失败 —— 文件根本没写进去，而调用方毫不知情。这是生产事故的典型形状。

> `{ok,<<"ä½ å¥½">>}` 这一行不是乱码 bug：那 6 个字节**就是** "你好" 的 UTF-8，
> 只是 shell 按 latin1 把它显示成了字符。用 `unicode:characters_to_list/1` 读回来就对了。

反向解码：

```
  unicode:characters_to_list(<<"你好"/utf8>>) = [20320,22909]
    拿 latin1 字节去当 UTF-8 解会失败（返回 incomplete/error 元组） = {incomplete,"caf",
                                                       <<"é">>}
    lists:flatten(io_lib:format("~ts", [<<"你好"/utf8>>])) = [20320,22909]
```

`unicode:characters_to_list/1` 失败时返回 `{incomplete, 已解出来的, 剩下的}` 或
`{error, 已解出来的, 剩下的}` —— **不会抛**。想让它抛就用 `unicode:characters_to_list/2`
的严格版本或自己匹配返回值。

`~ts` 是"按 unicode 打印这个串"的格式指令，配合 `io_lib:format` 是另一种解码手段。

**`{encoding, utf8}` 救不了 `write_file`**：

```
  write_file(F, <<"x">>, [{encoding, utf8}])（字节本来就合法 → ok） = ok
  write_file(F, "你好", [{encoding, utf8}])（选项没帮上忙） = {error,badarg}
  write_file(F, ["你","好"], [{encoding, utf8}])（拆开也不行） = {error,badarg}
  想让运行时替你做 UTF-8 编码，得走 file:open + io:put_chars（第 6 节）。
    顺便：不认识的选项被**静默忽略**（返回 ok）—— 拼错选项不会报错 = ok
```

这三条一起看最说明问题：`write_file/3` 的第三个参数**根本不接受 `encoding`**，
而且**不认识的选项被静默忽略**（最后一行：拼错的选项返回 `ok`）。
所以"我加了 `{encoding, utf8}` 怎么还是 badarg" —— 那个选项从来就没生效过。

### 25.5 字符串长度：三个"长度"

```
  length("你好")（码点数） = 2
  byte_size(<<"你好"/utf8>>)（UTF-8 字节数） = 6
  string:length("你好")（字素簇数） = 2
    string:slice("你好世界", 1, 2)（按码点切） = [22909,19990]
```

| 函数 | 数的是什么 | "你好" | 典型用途 |
| --- | --- | --- | --- |
| `length/1` | 码点（列表元素） | 2 | 遍历 |
| `byte_size/1` | UTF-8 字节 | 6 | 网络包长度、落盘 |
| `string:length/1` | **字素簇**（用户看到的"字"） | 2 | UI 显示、截断 |

三者对 ASCII 一样，对 emoji / 组合字符就不一样了（比如带肤色修饰的 emoji，
码点是 2 个、字素簇是 1 个）。**做"最多显示 10 个字"必须用 `string:length`**。

### 25.6 流式读写：open / read / position / pread

```
  file:read(Fd, 3) = {ok,<<"abc">>}
  file:position(Fd, cur)（当前偏移） = {ok,3}
  file:position(Fd, {bof, 1})（绝对定位） = {ok,1}
  file:read(Fd, 2) = {ok,<<"bc">>}
  file:pread(Fd, 0, 2)（定位读，不动当前偏移） = {ok,<<"ab">>}
    之后 position 还是刚才的位置（pread 不影响） = {ok,2}
  file:read(Fd, 100) 超过文件长度 → 给剩下的，不是 eof = {ok,<<"cdefg">>}
  file:read(Fd, 1) 再读 → eof = eof
  file:position(Fd, eof) = {ok,7}
  关掉之后再 read（句柄变成 terminated） = {error,terminated}
```

**`file:read(Fd, N)` 读到文件尾的行为**：只要还剩哪怕 1 字节，就返回 `{ok, 剩下的}`，
**不会**给你 `eof`。只有"当前已经在末尾了，还要读"才返回 `eof`。
所以判断读完的正确写法是循环读、直到拿到 `eof`，而不是比较 `byte_size(R) < N`。

```
  -- 写：默认覆盖，不会问你 --
  file:write(Fd2, <<"XY">>) = ok
    文件内容（被截断了，只剩 2 字节） = {ok,<<"XY">>}
  [append] 打开再写 = {ok,<<"XYZ">>}
```

`[write]` 打开会**截断**文件（和 C 的 `fopen("w")` 一样）。要追加必须显式给 `[append]`。

```
  -- raw / delayed_write 什么时候用 --
  raw 模式下的 read = {ok,<<"X">>}
  raw 模式下用 io:get_line（io 协议不支持） = {error,function_clause}
  delayed_write：攒够了再落盘（用 file:write_file/3 传选项） = ok
```

- **默认句柄**走的是"文件服务器"进程：所有 Erlang 进程共享，能 `pread`、能被 `io` 用，
  但每次调用都有进程间开销。
- **`raw`** 直接用驱动：快很多，但**不支持 io 协议**（`io:get_line` 直接
  `{error, function_clause}`），也不支持 `pread` 的部分语义。

### 25.7 按行读写与 `{encoding, utf8}`

```
  io:get_line 第 1 行 = 第一行
  io:get_line 第 2 行 = 第二行
  io:get_line 第 3 行 = 第三行
  io:get_line 到末尾 → eof（不是空字符串） = eof
```

`io:get_line` 到末尾返回的是**原子 `eof`**，不是 `""`。用 `length(L) =:= 0` 判断会崩。

编码对比（同一份 UTF-8 文件，两种打开方式）：

```
  latin1 打开读第一行：长度（UTF-8 的 3 字节被当成 3 个字符） = 10
    这些字符的码点（用 ~w 看，不然 ~p 会美化成乱码字符串） = [231,172,172,228,184,128,232,161,140,10]
```

10 个字符 = "第一行" 的 9 个 UTF-8 字节 + 换行。**这就是为什么"读中文文件长度不对"。**
默认（latin1）打开时，一个字节被当成一个码点。

```
  -- 写：latin1 设备写 unicode 会抛 no_translation --
  latin1 设备 io:put_chars("你好")（{抛出, 类, 原因}） = {thrown,error,no_translation}
  utf8 设备 io:put_chars("你好") = ok
    写出来的字节数 = 6
```

注意这里和 25.4 的差别：**`io:put_chars` 是抛**（`error:no_translation`），
而 `file:write_file` 是返回 `{error, badarg}`。同一个"中文写不进去"的问题，
在两层里有完全不同的失败方式。

**配置文件的正确姿势：`file:consult`**

```
  file:consult = {ok,[{name,<<"kv">>},{port,8080}]}
  consult 一个空文件 = {ok,[]}
  consult 一个坏文件（第几行 + 解析器原因） = {1,erl_parse,["syntax error before: ","is"]}
```

`file:consult/1` 读一个"每行一个 Erlang 项、以句点结尾"的文件，返回**项的列表**。
它是 Erlang 生态里配置文件的标准格式（`sys.config` 就是它）。

失败时返回 `{error, {行号, 模块, 原因}}` —— 注意行号在里面，报错信息很友好。

### 25.8 二进制协议：位语法实战

位语法同时是**构造**和**匹配**语法，所以编解码天然对称。本节的报文格式：

```
  报文格式（大端）：
    Magic   16 位   0x45 0x52 （'E' 'R'）
    Ver      8 位   版本号
    Type     8 位   消息类型
    Len     16 位   Payload 字节数
    Payload  Len 字节
    Crc     32 位   erlang:crc32(Payload)
```

编码函数的核心就是一行：

```erlang
encode(Ver, Type, Payload) ->
    Len = byte_size(Payload),
    Crc = erlang:crc32(Payload),
    <<16#45, 16#52, Ver:8, Type:8, Len:16/big, Payload/binary, Crc:32/big>>.
```

解码是同一个模式的**匹配**，而且四个失败分支全部显式处理：

```
  encode(1, 7, <<"hello">>) 的字节 = <<69,82,1,7,0,5,104,101,108,108,111,54,16,
                                    166,134>>
    总字节数 = 15
  decode 回去 = {ok,#{type => 7,payload => <<"hello">>,ver => 1}}
  decode 空 payload = {ok,#{type => 0,payload => <<>>,ver => 1}}
  改一个字节（把 Ver 从 1 改成 2） = {ok,#{type => 7,payload => <<"hello">>,ver => 2}}

  -- 解不开的四种情况，都得显式处理 --
  Magic 不对 = {error,bad_magic}
  Magic 对了但长度不够（头就 8 字节，只给了 7） = {error,truncated}
  头够了但 payload 短了（说 5 字节只给了 2） = {error,truncated}
  Crc 对不上（payload 被改了） = {error,crc_mismatch}
```

关键技巧是**用 `Rest/binary` 接住变长部分**，然后用 `byte_size(Rest)` 校验：

```erlang
decode(<<16#45, 16#52, Ver:8, Type:8, Len:16/big, Rest/binary>>)
  when byte_size(Rest) >= Len + 4 ->
    <<Payload:Len/binary, Crc:32/big, _Tail/binary>> = Rest,
    case erlang:crc32(Payload) of
        Crc -> {ok, #{ver => Ver, type => Type, payload => Payload}};
        _   -> {error, crc_mismatch}
    end;
decode(<<16#45, 16#52, _/binary>>) -> {error, truncated};
decode(_) -> {error, bad_magic}.
```

注意 `Rest` 之后还有 4 字节 CRC 时，`_Tail/binary` 允许有尾巴 —— 这样
"多个报文粘在一个包里"也能量出来，是写 TCP 拆包的标准做法。

**位语法速查（全部实测）**：

```
  <<258:16/big>> vs <<258:16/little>> = {<<1,2>>,<<2,1>>}
  binary:encode_unsigned(258) / little = {<<1,2>>,<<2,1>>}
  binary:encode_unsigned(-1)（负数要自己用 /signed） = {error,badarg}
  <<-1:8/signed>> 的字节 = <<"ÿ">>
  <<1:3, 5:5>>（非整字节） = <<"%">>
    binary:at(它, 0) = 37
    bit_size vs byte_size（byte_size 向上取整） = {3,1}
  <<1.5:64/float>> vs <<1.5:32/float>> = {<<63,248,0,0,0,0,0,0>>,
                                          <<63,192,0,0>>}
  <<"A":8/unit:2>>（unit 是重复倍数） = <<0,65>>
  binary:part / split / match / replace = {<<"hello">>,
                                           [<<"a">>,<<"b">>,<<"c">>],
                                           {6,5},
                                           <<"a+b">>}
  binary:encode_hex / decode_hex 往返 = <<1,2,255>>
  base64:encode(<<"hi">>) = <<"aGk=">>
```

三个要点：

- 默认是 **big endian**；`binary:encode_unsigned/1` 也是大端，要小端用 `encode_unsigned(N, little)`。
- 默认**无符号**。`binary:encode_unsigned(-1)` 直接 badarg；负数要用位语法的 `/signed`。
- `unit:N` 是"每个单位多少位"的倍数，`<<"A":8/unit:2>>` = 8×2 = 16 位，所以是 `<<0,65>>`。

### 25.9 序列化：term_to_binary 与它的安全问题

```
  原始 term = {user,<<229,188,160,228,184,137>>,30,#{tags => [a,b]}}
  term_to_binary 的字节数 = 45
    第一个字节是外部格式版本号（固定 131） = 131
  binary_to_term 完全还原（不是"像"，是相等） = true
```

外部格式（Erlang External Term Format）的第一个字节恒为 `131` —— 这可以当作
"这是不是 Erlang 序列化数据"的指纹。

**压缩**：

```
    20000 个整数的列表：未压缩 / 压缩后字节数 = {99242,42208}
    上面那个小 term：未压缩 / 压缩后 = {45,45}
    压缩对很短的数据反而变**大**（头信息开销）—— 别无脑开 = false
    压缩级别 0（几乎不压） = 99242
```

2 万个整数：99242 → 42208（省 57%）。45 字节的小 term：压缩后**还是 45**（没变）。
所以**短数据开 compressed 是纯亏** —— 只在数据确实大（KB 级以上）时开。

**安全性：`binary_to_term` 会创建原子**：

```
  [safe] 解一个本节点没见过的原子（手工拼的外部格式） = {error,badarg}
  （上面故意先解一个「肯定没见过」的原子；如果先默认解过一次，它就在原子表里了，safe 也就拦不住了。）
  binary_to_term 喂垃圾字节 = {error,badarg}
  term_to_binary 一个 pid（能编，但解出来只在原节点有意义） = true
```

> 原子表**不会回收**（见 26.6）。所以拿不可信输入去 `binary_to_term` 是一个真实的
> DoS 入口：对方发一堆新原子就能把你的节点撑死。**永远加 `[safe]`**。
>
> `[safe]` 的语义是"不许创建新原子"，不是"不许解"。如果那个原子**已经**在原子表里了
> （比如你之前默认解过一次），`[safe]` 也拦不住 —— 上面那行注释就是在说这件事。

### 25.10 什么时候用哪个

```
  跨节点/同语言进程之间传数据
      → term_to_binary（快、保真、支持任意 term）
  要落盘、以后还要读
      → term_to_binary + 版本号字段（别裸存，改结构就解不了了）
  要和其它语言互通
      → 自己定位长协议（第 7 节）或 JSON（jsx/jiffy 等库）
  配置给**人**看
      → file:consult（就是 Erlang 项，能写注释）
  配置给**机器**批量下发
      → .app 的 env，或者 sys.config
```

落盘那条要特别强调：**裸存 `term_to_binary` 的结果，改一次数据结构旧文件就全解不了了**。
一定要在前面加一个版本号字段（比如存 `{?FORMAT_VSN, Term}`），解的时候先匹配版本号。

### 25.11 常见错误清单

```
  file:write_file(F, "中文")
      现象：badarg
      处理：参数是字节 iodata，中文码点 > 255。用 <<"中文"/utf8>> 或 unicode:characters_to_binary/1
  file:write_file(F, D, [{encoding, utf8}])
      现象：badarg
      处理：write_file 不接受 encoding 选项；要编码就 file:open + io:put_chars
  latin1 设备 io:put_chars 中文
      现象：error:no_translation（抛）
      处理：打开时加 {encoding, utf8}
  io:get_line 到末尾
      现象：返回 eof 原子，不是 ""
      处理：用 =:= eof 判断，别用 length(L) =:= 0
  file:read(Fd, N) 超过文件长度
      现象：给剩下的字节，不是 eof
      处理：判断是不是真的读完，要看下一次 read 是否返回 eof
  file:open(目录, [read])
      现象：{error, eisdir}
      处理：先 filelib:is_dir/1 判断
  关掉句柄后再 read
      现象：{error, terminated}
      处理：句柄是一次性的，忘了 close 会泄漏描述符
  filelib:ensure_dir(File)
      现象：只建目录不建文件
      处理：想要文件还得自己 write_file
  size(Bin) 当 byte_size 用
      现象：已被 byte_size 取代
      处理：size/1 对 binary 还能用但别写
  byte_size(<<1:3>>)
      现象：返回 1（向上取整）
      处理：想看真实位数用 bit_size/1
  binary_to_term(不可信数据)
      现象：会创建新原子，可能 DoS
      处理：加 [safe]，或改用自己定义的协议
  term_to_binary 默认开 compressed
      现象：短数据反而变大
      处理：只在数据确实大时开
```

---

## 第 26 章 定时器、时间与系统限制

> 示例：`examples/26-timers-limits.erl`　输出：`build/26-timers-limits/stdout.txt`

这一章讲三件事：**怎么"过一会儿做点什么"**、**怎么正确地测时间**、
**这台虚拟机到底能撑多少东西**。第三个是容量规划的基础。

### 26.1 三种（其实是四种）定时机制

```
  (a) receive ... after —— 最轻，但它是**接收的一部分**
  receive 一个不会来的消息，after 20 毫秒 = timed_out

  (b) erlang:send_after/3 —— 由虚拟机管，不占进程
  返回值是引用吗 = true
  等着收（最多 2 秒） = got_it

  (c) erlang:start_timer/3 —— 消息形状固定是 {timeout, Ref, Msg}
  收到的是 = {timeout,'<Ref>',payload}

  (d) timer 模块 —— stdlib 的，背后**有一个进程**
  timer:send_after 返回值的形状 = send_local
  等着收 = got_it
  只发到本地 pid 的话，timer_server **根本没启动** = false
  timer:sleep(10) 的返回值 = ok
  timer:seconds(1) / minutes(1) / hms(1,2,3) = {1000,60000,3723000}
```

四种机制的选择：

| 机制 | 由谁管 | 返回 | 适用场景 |
| --- | --- | --- | --- |
| `receive ... after` | 进程自己 | —— | 就是"等消息最多等多久"，**首选** |
| `erlang:send_after/3` | 虚拟机（定时器轮） | `Ref` | 要给**别的**进程发定时消息；大量/高频 |
| `erlang:start_timer/3` | 虚拟机 | `Ref` | 同上，但消息要带 `Ref` 以便区分（见 19 章） |
| `timer` 模块 | `timer_server` 进程 | 见下 | 偶发的一次性任务、`timer:tc` 计时 |

`send_after` 和 `start_timer` 的**唯一区别是消息形状**：

```
  区别：send_after 把你的消息**原样**投递，start_timer 包一层 {timeout, Ref, Msg}。
```

带 `Ref` 的价值在 19 章讲过：能区分"这次请求的超时"和"上次请求的迟到回复"。
**写 `gen_server` 的超时逻辑时优先用 `start_timer`**，`handle_info({timeout, Ref, _}, ...)`
里可以精确判断是不是自己等的那个。

### 26.2 取消与查询剩余时间

```
  read_timer 一个还早的定时器（返回剩余毫秒） = {true,true}
    再读一次（只会**变少**，不会变多） = true
  cancel_timer 返回剩余毫秒 = {true,true}
    再 cancel 一次（已经没了 → false） = false
    再 read_timer（false） = false

  -- 已经触发过的定时器 --
  cancel 一个**已经触发**的（false，不是剩余 0） = false
    read_timer 也已经 false = false
```

`erlang:cancel_timer/1` 和 `erlang:read_timer/1`：

- 定时器还在 → 返回**剩余毫秒数**（整数）；
- 定时器没了（取消过 / 已触发 / ref 根本不对）→ 返回 **`false`**。

> 注意是 `false` 不是 `0`。所以判断"取消成功了吗"要写 `case erlang:cancel_timer(Ref) of
> false -> ...; _Ms -> ... end`，**不要**写 `Ms > 0`（`false > 0` 在 Erlang 里居然是
> `true`，因为 `false` 是原子、原子 > 整数 —— 这个比较不会报错，只会得出错误结论）。

```
  注意：cancel_timer **保证**消息不会再来，但**不保证**它还没在邮箱里。
  如果定时器已经触发、消息已经投递，你得自己把它从邮箱清掉：
    清一下邮箱里可能残留的 = nothing_there
```

取消之后**必须再清一次邮箱**，标准写法：

```erlang
case erlang:cancel_timer(Ref) of
    false ->
        %% 消息可能已经在邮箱里了，收掉它
        receive {timeout, Ref, _} -> ok
        after 0 -> ok
        end;
    _Ms ->
        ok   %% 还没触发，cancel 保证它不会来
end.
```

### 26.3 timer 模块的真相：它不一定经过 timer_server

这是本章最"反老教程"的一节。老说法是"timer 模块所有定时器都挤在 `timer_server`
一个进程里"。**OTP 27 之后这不成立了**，实测（OTP 29）：

```
  一开始 timer_server 存在吗 = false
  timer:send_after 到**本地 pid** 的返回值 = send_local
    之后 timer_server 启动了吗（**没有**） = false
  timer:send_after 到**注册名**的返回值 = once
    之后 timer_server 启动了吗（**启动了**） = true
  timer:send_interval 的返回值 = interval
  timer:send_after 时间给 0 的返回值 = instant
    消息是**立刻**投递的（不用等） = delivered

  规律（对着 stdlib 源码确认的）：
    · 发给**本地 pid** → 直接委托给 erlang:send_after，返回 {send_local, Ref}
    · 发给**注册名 / 远端** → 得由服务进程代发，返回 {once, Ref}
    · apply_after / exit_after / kill_after → {once, Ref}，需要服务进程
    · send_interval → {interval, Ref}
    · 时间为 0 → {instant, Ref}，立即投递，不走定时器
```

所以 **"timer 模块一定慢"已经不完全对了**：发给本地 pid 时它直接委托给
`erlang:send_after`，根本不启动 `timer_server`。只有发给注册名/远端、
以及 `apply_after` / `send_interval` 才走服务进程。

```
  -- timer:cancel 与 erlang:cancel_timer 的差别 --
  timer:cancel 一个正常的 tref = {ok,cancel}
    再 cancel 一次（**还是** {ok, cancel}，不会告诉你已经没了） = {ok,cancel}
    对比：erlang:cancel_timer 第二次返回 false = false
    timer:cancel 传一个裸 ref（返回 error 元组，不是抛） = {error,badarg}
```

> **`timer:cancel/1` 的返回值不能用来判断"到底取消成功没有"** —— 取消一个已经不存在的
> 定时器，它依然返回 `{ok, cancel}`。要精确控制（限流器之类的），
> 直接用 `erlang:send_after` + `erlang:cancel_timer`。

### 26.4 超时值：0、infinity、以及哪些值会炸

```
  receive after 0（不等，直接走超时分支） = immediate
  send_after 时间给 0（几乎立刻投递） = delivered
  send_after 负数 = {error,badarg}
  send_after 超大值（超过 2^64 毫秒） = {error,badarg}
  send_after 带一个不认识的选项 = {error,badarg}
  receive after 非法值（负数） = {error,timeout_value}
  infinity 是一个合法超时值（一直等），gen_server:call 不传超时默认就是 5000。
```

**`after 0` 是一个惯用法**："看看邮箱里有没有，没有就走超时分支，绝不等待"。
它就是"非阻塞接收"。

两类错误要分清：

- `badarg` —— 参数类型不对（`erlang:send_after` 是 BIF，参数错就 badarg）；
- **`timeout_value`** —— 这是**专门**给"超时值不对"的错误类。看到它就查超时参数，
  和 badarg 完全不是一回事。

`infinity` 是合法超时值（`gen_server:call/2` 不传超时默认 5000 毫秒，
`gen_server:call(Pid, Req, infinity)` 就是一直等 —— 但**不建议**，会掩盖死锁）。

### 26.5 时间：墙钟会跳，单调钟不会

```
  连续两次 monotonic_time，第二次不小于第一次 = true
  monotonic_time 一定 >= 0 吗（**不是**） = false
  system_time 是个正数（纳秒） = true
  os:system_time 与 erlang:system_time 差不到 1 秒 = true
  time_offset 是个整数（墙钟 = 单调钟 + 偏移） = true
  convert_time_unit(1000, 微秒 → 纳秒) = 1000000
  erlang:timestamp() 是个三元组（元/秒/微秒） = 3
```

Erlang 里有两个时钟：

| | 函数 | 特性 | 用途 |
| --- | --- | --- | --- |
| 墙钟 | `erlang:system_time/0`、`os:system_time/0`、`erlang:timestamp/0` | **会前后跳**（NTP 校时、手动改表） | 存时间戳、显示给用户 |
| 单调钟 | `erlang:monotonic_time/0` | 只增不减，但**起点任意** | 算间隔、超时 |

> **单调钟的起点是任意的，甚至可能是负数**（实测 `>= 0` 为 `false`）。
> 所以：拿它算**间隔**是对的，拿它当"时间戳"存起来是错的 —— 重启一次就全变了。

```
  -- 计时：timer:tc 还是 monotonic_time？ --
  timer:tc 的耗时（微秒，>0） = true
    它的返回值就是函数的返回值 = 5000050000
  timer:tc 内部用的是 os:timestamp（墙钟），跨 NTP 校时可能量出负数；
  要准确测间隔，用 erlang:monotonic_time(0) 前后各取一次相减。
  monotonic_time 算出来的间隔 >= 0 = true
```

**`timer:tc/1` 内部用的是墙钟**（`os:timestamp`），跨 NTP 校时理论上能量出负数。
要准确测间隔：

```erlang
T0 = erlang:monotonic_time(0),
do_something(),
T1 = erlang:monotonic_time(0),
Diff = T1 - T0.   %% 单位是 native time unit
```

`monotonic_time(0)` 的参数 `0` 是"别换算，给我原始单位"，这样最快；
要换算成纳秒用 `erlang:convert_time_unit(Diff, native, nanosecond)`。

### 26.6 系统限制：这台虚拟机能撑多少东西

```
  process_limit（进程数上限） = 1048576
    当前进程数 > 0 = true
  ets_limit（ETS 表数上限，比进程小得多） = 8192
  port_limit 的**具体数字会随环境变**：它是按进程能打开的文件描述符
  上限算出来的，同一个仓库用 ./run-all.sh 跑和用 pwsh ./build.ps1 跑
  都可能不一样（实测过 1048576 与 65536 两种情况）。所以这里只断言性质。
    port_limit > 0 = true
    port_limit >= 当前 port 数 = true
    atom_limit > 0 = true
    当前原子数 > 0 = true
  wordsize（一个字的字节数） = 8
  endian = little
  system_architecture 里含 x86_64 吗 = true
  调度器个数 >= 1（具体几个随机器变，别写死） = true
  smp_support = true
```

容量规划要记住的三个数量级：

- **进程**：默认 100 万+，基本不用担心；
- **ETS 表**：默认只有 **8192**（比进程少两个数量级）—— 建很多表要 `+e` 调或复用表；
- **port / 文件描述符**：随环境变，别写死数字。

> **为什么这里的输出只写"性质"不写数字**：`port_limit` 和调度器个数都是
> **环境相关**的，跑 shell 版入口和 PowerShell 版入口结果都可能不同
> （实测过 1048576 与 65536 两种）。本教程要求两个入口输出**逐字节一致**，
> 所以凡环境相关的值一律改成布尔断言。这也是你自己写测试时该学的做法。

**原子表：只涨不回收**

```
  造 200 个新原子后，原子数增加了 = 200
    造过之后就能用 list_to_existing_atom 找到 = limits_probe_1
    找一个从没造过的（badarg） = {error,badarg}
```

> **绝不能拿外部输入（用户名、请求路径、MQ 主题、URL 参数）去 `list_to_atom/1`。**
> 原子表不回收，攻击者发 100 万个不同的字符串就能把节点撑死。
>
> 要"查有没有这个原子"用 `list_to_existing_atom/1`：不存在就 badarg，
> **不会创建**。这是 Erlang 里做"字符串 → 已知原子"白名单的标准写法。

### 26.7 数值边界：整数不会溢出，浮点会

```
  1 bsl 1000 还是个整数（任意精度） = true
    它是大整数（超过一个字） = true
    (-1 bsl 100) + 1 也正常 = true
  10 的 100 次方算得出来 = true
  trunc(math:pow(10,100)) 和真值一样吗（**不**） = true

  -- 浮点：溢出是 badarith，不是 inf --
  math:pow(10, 400) = {error,badarith}
  1e308 * 10（连乘溢出） = {error,badarith}
  math:sqrt(负数)（不是 nan，是 badarith） = {error,badarith}
  0.1 + 0.2 == 0.3 吗 = false
    差值 = 5.551115123125783e-17
```

Erlang 的整数是**任意精度**的（和 Python 一样），不会溢出。`1 bsl 1000` 完全合法。

浮点则完全不同：

- 溢出 → **抛 `badarith`**（不是 `infinity`）；
- `math:sqrt(-1.0)` → **抛 `badarith`**（不是 `nan`）；
- `0.1 + 0.2 =/= 0.3`（IEEE 754，和其它语言一样）。

> **一个编译器细节**：`erlc -Werror -Wall` 会在**编译期**就把
> `math:sqrt(-1.0)` 这种"必然 badarith"的表达式判死（报
> "will fail with a badarith exception"）。所以示例里想演示**运行期**错误，
> 值必须来自参数或 `opaque_*()` 函数 —— 编译器看不穿的参数。
> 这是本教程所有示例的一个共同设计约束。

### 26.8 观测内存与 GC

```
  erlang:memory() 的键（排序后） = [atom,atom_used,binary,code,ets,processes,
                             processes_used,system,total]
    total > 0 = true
    processes > 0 = true
    atom_used <= atom = true
  造一个 20 万元素的列表后 heap_size 变了 = {true,true}
  process_info 里有 garbage_collection 这一项 = true
  主动 erlang:garbage_collect() = true
  message_queue_len（当前邮箱里的消息数） = 0
  reductions（已经执行了多少"步"） = true
  process_info 一个已经死的进程 → undefined = undefined
```

运维时最常用的几个：

- **`message_queue_len`** —— 邮箱堆积是线上"变慢但 CPU 不高"的第一嫌疑（见 28.4）；
- **`reductions`** —— 跑了多"步"，差值能看出这个进程有多忙；
- **`memory`** —— 单个进程的堆大小；
- **`erlang:memory(total)`** —— 整个节点。

`process_info/2` 对**已死进程返回 `undefined`**，不是崩溃 —— 所以不要写
`element(2, process_info(Pid, messages))`，要先判 `undefined`。

### 26.9 常见错误清单

```
  拿外部输入做 list_to_atom
      现象：原子表一直涨，直到节点被杀
      处理：用 list_to_existing_atom，或者先自己白名单校验
  把 monotonic_time 当时间戳存
      现象：起点任意，甚至可能是负数
      处理：只用它算间隔；存时间用 system_time / os:system_time
  用墙钟测间隔
      现象：NTP 校时会让间隔变成负数
      处理：erlang:monotonic_time(0) 前后相减，或 erlang:statistics(runtime)
  cancel_timer 之后以为邮箱干净了
      现象：消息可能已经投递
      处理：cancel 之后再用 receive ... after 0 清一次
  大量定时器全用 timer 模块
      现象：都挤在一个 timer_server 进程里
      处理：高频/大量用 erlang:send_after；timer 模块只做偶发的一次性任务
  receive after 一个变量
      现象：变量是负数时抛 timeout_value
      处理：超时值也要防御性检查
  以为 ETS 表数和进程数一样多
      现象：ets_limit 默认只有几千（本机 8192）
      处理：要建很多表就 +e 调，或者复用表
  用 float 存金额
      现象：0.1 + 0.2 /= 0.3
      处理：用整数（分）或专门的十进制库
  以为浮点溢出得到 infinity
      现象：实际抛 badarith
      处理：涉及大数就用整数，别用 float
  process_info 一个未知进程
      现象：返回 undefined，不是崩溃
      处理：判断返回值，别直接 element(2, ...)
```

---

## 第 27 章 日志（logger）与可观测性

> 示例：`examples/27-logger.erl`　输出：`build/27-logger/stdout.txt`

OTP 21 之后有了官方的 `logger`，`error_logger` 和第三方 lager 都成了历史。
但 logger 的默认行为**反直觉**（默认级别是 `notice`，`info` 打不出来），
这一章把它的机制讲透。

### 27.1 为什么不用 io:format

```
  io:format 打到的是"当前进程的 group leader"，它不知道"级别"这回事，也没法在运行时关掉一部分。
  logger 的区别在于：日志**先过关卡再决定要不要写、写到哪、写成什么样**。
  日志是另一个进程写的（不是同步的） = true
    实测：同一份代码里 io:format 和 logger 的先后顺序不固定 = true
    所以本示例把日志写进文件再读回来打印（见文件头说明） = true
```

`io:format` 的三个问题：

1. **没有级别** —— 要么全打，要么全不打（除非你自己写 `if`）；
2. **没有目标** —— 只能打到 group leader（一般是 stdout），没法同时写文件和发网络；
3. **同步** —— 慢速输出（网络、磁盘）会拖住业务进程。

> **日志是异步的**：调用方把事件丢给 handler 进程就返回了。所以
> "`io:format` 打在这行、日志打在那行"的**相对顺序不保证**。
> 本示例的做法值得学：**把日志写进文件，再读回来打印**，这样输出才是确定的。

### 27.2 一条日志要过四道关

```
  1. 主级别 primary level
      → 全局总闸。默认是 notice —— 所以 info/debug 默认**不出来**
  2. 主过滤器 primary filters
      → 对所有 handler 生效；返回 stop 就到此为止
  3. 模块级别 module level
      → 按发起日志的模块单独调级别（只对 ?LOG_* 宏有效，见第 6 节）
  4. handler 级别 + handler 过滤器
      → 每个 handler 自己再筛一遍；可以有多个 handler 写不同地方

  任何一道关说"不要"，这条日志就消失了 —— 而且**不会报错**。
```

这个模型很像 Web 框架的中间件链：每一道都能"放行 / 丢弃 / 改写"。
记住 **primary 是总闸、handler 是分闸**，两者串联。

### 27.3 默认配置（实测值）

```
  get_handler_ids() = [default]
  默认 handler 的 module = logger_std_h
    它自己的 level = all
    输出目标 config.type = standard_io
    filter_default（过滤器不表态时的默认动作） = stop
    自带的三个过滤器 = [remote_gl,domain,no_domain]
    默认 formatter 的配置 = #{single_line => false,legacy_header => true}

  -- 主配置 --
  primary level（**默认是 notice**，不是 info） = notice
  primary 的 filter_default = log
  primary 的 filters = []
```

> **默认 primary level 是 `notice`** —— 这意味着 `logger:info(...)` 和
> `logger:debug(...)` 开箱**什么都不输出**。这是 90% 的"logger 没反应"问题的原因。

另外注意两处 `filter_default` 不一样：

- **primary 的 `filter_default` 是 `log`** —— 过滤器不表态就放行；
- **默认 handler 的 `filter_default` 是 `stop`** —— 不表态就丢弃。

这个不对称经常让人困惑：在 primary 上加一个"不表态"的过滤器，日志照样出去；
在默认 handler 上加同一个过滤器，日志就没了。

### 27.4 八个级别

```
emergency  emergency 系统不可用了
alert  alert 必须立刻处理
critical  critical 关键故障
error  error 出错了
warning  warning 警告
notice  notice 注意
info  info 信息
debug  debug 调试
  严重度顺序用 logger:compare_levels/2 比较：
  compare_levels(error, debug) = gt
  compare_levels(debug, error) = lt
  compare_levels(notice, notice) = eq
```

八个级别从重到轻：`emergency > alert > critical > error > warning > notice > info > debug`。
设成某个级别 = "这个级别**及更严重**的都放行"。

`logger:compare_levels(A, B)` 返回 `gt` / `lt` / `eq`（前一个相对后一个）。
注意语义：**`gt` = 前一个更严重**，不是"数值更大"。

### 27.5 三处能设级别（串联关系）

```
  -- primary 抬回 notice（info/debug 全没了，handler 还是 debug） --
error  error 还在

  -- primary 放行、但 handler 抬到 error --
error  error 出来了
  两道关是**串联**的：任何一处更严格，就按更严格的来。
```

排查"日志打不出来"的清单：

1. `logger:get_primary_config()` 看 primary level；
2. `logger:get_handler_config(default)` 看 handler level；
3. 看有没有过滤器返回了 `stop`；
4. 看有没有设过 module level（下一节）。

### 27.6 模块级别的坑：`logger:info` 不受它管

```
  set_module_level 靠日志事件里的 mfa 元数据判断"是谁打的"，
  而 mfa 只有 ?LOG_* 宏才会塞进去。用 logger:info/1 直接调，它管不着。

  -- 模块级设成 critical 之后 --
info  logger:info —— 还是出来了（模块级没生效）
critical  critical 当然在
  unset_module_level = ok
  get_module_level（现在是空的） = []
```

这是本章最容易踩的坑：`logger:set_module_level([my_mod], critical)` 对
`logger:info("...")` **无效**，因为直接调函数**不会**在事件里写 `mfa` 元数据。

只有用宏（`?LOG_INFO` 等，需要 `-include_lib("kernel/include/logger.hrl").`）才会带
`mfa`、`line`、`file`。所以要享受模块级控制，**必须用宏**：

```erlang
-include_lib("kernel/include/logger.hrl").
?LOG_INFO("用户 ~p 登录", [User]),   %% 带 mfa，受 module level 管
logger:info("用户 ~p 登录", [User]), %% 不带 mfa，不受管
```

### 27.7 日志事件的 msg 有三种形状

```
  -- 三种写法 --
info  纯字符串
info  带参数 1 和 two
info  count: 3, what: happened
  内部表示分别是：
    {string, "纯字符串"}        —— 直接给的字符串
    {"带参数 ~p 和 ~p", [1,two]} —— 格式串 + 参数，格式化**推迟**到写的时候
    {report, #{...}}           —— 结构化报告，按键排序输出
  想自己写 filter 就必须三种都处理（第 9 节有例子）。
```

三种写法：

```erlang
logger:info("纯字符串"),              %% {string, _}
logger:info("带参数 ~p 和 ~p", [1, two]), %% {Fmt, Args}
logger:info(#{count => 3, what => happened}), %% {report, _}  或 ?LOG_INFO
```

> **第二种（格式串 + 参数）是推荐写法**：格式化**推迟**到 handler 真正要写的时候才做。
> 如果这条日志因为级别被丢弃了，格式化**根本不会发生**。
> 而拼好字符串再传进去（`logger:info("用户 " ++ Name ++ " 登录")`），
> 代价留在业务进程，而且丢不丢都一样付。

### 27.8 用 template 控制长什么样

```
  -- level + mfa + msg --
info '27-logger':log_with_macro/0 ?LOG_INFO —— 被模块级挡掉了

  -- level + domain + msg --
info  没设 domain
info [myapp,db] 设了 [myapp,db]
  模板里能放的字段（实测可用） = [level,msg,mfa,domain,time,date,pid,gl,file,line,report_cb]
```

自定义 template：

```erlang
logger:set_handler_config(default, formatter,
    {logger_formatter, #{template => [level, " ", mfa, " ", msg, "\n"]}}).
```

`time` / `pid` 会让输出**每次都不一样** —— 本示例故意没把它们放进模板，
否则两个入口（shell / PowerShell）就没法逐字节比对了。你自己写测试时也要注意这一点。

```
  -- 模板里直接写字符串字面量（可以） --
[x] 字面量演示
  但如果用 ++ 把字面量和 msg **拼平成一个列表**，里面就会混进整数和原子，模板就不认识了：
  用 ++ 拼平的模板 = {error,invalid_formatter_template,logger_formatter}
  正确写法是列表里一项一项写：["[ERR] ", msg, "\n"] （binary <<"[ERR] ">> 也行）。
```

> 模板里的字面量**必须写成 binary**（`<<"[ERR] ">>`）。用字符串列表 `"[ERR] "`
> 会被拆成一堆整数，混在模板里就不认识了。用 `++` 拼平更是直接报
> `invalid_formatter_template`。

### 27.9 过滤器：`stop` 才丢，`ignore` 只是"不表态"

```
  过滤器函数返回三种值：
    返回 LogEvent  → 继续（可以顺手改字段）
    返回 ignore    → 这个过滤器不表态，交给后面的过滤器和 filter_default
    返回 stop      → **丢掉**这条日志
```

这是 logger 里最容易搞错的一点：**返回 `ignore` 不等于丢弃**。
`ignore` 的意思是"我不管"，最终按 `filter_default` 办。要丢必须返回 `stop`。

```
  -- 挡掉正文里含"丢弃"的 --
info  这条正常

  -- ignore 不表态 —— 日志照常出来 --
info  过滤器 ignore，我还在

  -- 过滤器能改事件（把 info 提级成 critical） --
critical  我本来是 info

  -- primary filter 对所有 handler 生效 --
info  删掉之后又出来了
```

过滤器还能**改写事件**（第三组：把 `info` 提级成 `critical`）。这就是
"给所有日志打上 request_id"的实现方式。

写一个处理三种 msg 形状的过滤器：

```erlang
Fun = fun(#{msg := {string, S}} = Event) ->
              case string:find(S, "丢弃") of
                  nomatch -> Event;
                  _       -> stop
              end;
         (#{msg := {Fmt, Args}} = Event) ->
              case string:find(io_lib:format(Fmt, Args), "丢弃") of
                  nomatch -> Event;
                  _       -> stop
              end;
         (Event) -> Event   %% report 形状，别漏了
      end,
logger:add_primary_filter(drop_secret, Fun).
```

> **过滤器崩了会怎样**：logger 会把出错的 filter **摘掉**并报一条错误，
> 之后所有日志都出来了（因为没人拦了）。所以过滤器必须处理 msg 的三种形状，
> 别假设它一定是字符串。

### 27.10 结构化日志：metadata 与 domain

```
  -- 把请求 id 打进日志 --
info [<<"r-42">>] 带 request_id
info [] 没有 request_id
  metadata 里没有的字段，模板会输出**空字符串**而不是报错。
  primary 上也能挂全局 metadata（每条日志都带） = ok
```

`domain` 是 logger 的"分类"机制（类似 Java logger 的层级名），
配合 `logger:set_handler_config(H, filters, [{domain, ...}])` 可以把不同
子系统的日志发到不同文件。

### 27.11 过载保护：日志刷爆时不能拖垮业务

```
  logger handler 是**异步**的：调用方把事件丢给 handler 进程就返回了。
  如果业务打日志的速度超过 handler 写得完的速度，队列就会无限涨。
  OTP 内置三道闸（默认值，实测自 logger_std_h 的 config）：
  sync_mode_qlen（队列超过这个数就转同步，调用方被迫等） = 10
  drop_mode_qlen（再超就**直接丢**日志，保命） = 200
  flush_qlen（丢模式下，队列降到这里就恢复） = 1000
  burst_limit_enable / max_count / window_time = {true,500,1000}
  overload_kill_enable（极端情况直接把 handler 杀掉重启） = false
```

三道闸是递进的：

1. 队列 > `sync_mode_qlen`（10）→ **转同步**，调用方开始被阻塞（牺牲业务速度）；
2. 队列 > `drop_mode_qlen`（200）→ **直接丢日志**（牺牲日志完整性）；
3. 队列降到 `flush_qlen`（1000）以下 → 恢复。

> 这些数不用背，记住两件事就够：
> - 日志**真的会被丢**，所以别拿日志当业务数据（审计、计费都不行）；
> - 慢速落盘（文件/网络）的 handler 要把 `drop_mode_qlen` 调小一点。

### 27.12 常见错误清单

```
  logger:info 什么都没打出来
      现象：primary level 默认是 notice，info 被挡了
      处理：logger:set_primary_config(level, info)，或在 sys.config 里配
  set_module_level 不生效
      现象：模块级靠 mfa 元数据，logger:info 不带
      处理：改用 ?LOG_INFO 等宏（include kernel/include/logger.hrl）
  过滤器返回 ignore 日志还在
      现象：ignore = 不表态，不是丢弃
      处理：要丢就返回 stop
  过滤器崩了，之后所有日志都出来了
      现象：logger 会把出错的 filter 摘掉并报一条
      处理：filter 必须处理 msg 的三种形状，别假设它是字符串
  日志行的顺序和 io:format 对不上
      现象：日志由 handler 进程异步写
      处理：别依赖两者的相对顺序；要复核就写文件再读回来
  日志输出里有 pid/时间戳，测试没法比对
      现象：默认模板带了 time 和 pid
      处理：自定义 template，把 time/pid 去掉
  在日志里拼大字符串
      现象：字符串会先在调用方进程里拼好，代价留在业务进程
      处理：用 logger:info("~p", [X]) 或 report，格式化推迟到 handler
  把日志当审计/业务数据
      现象：过载时日志会被丢（drop_mode_qlen）
      处理：要可靠就走数据库/消息队列，别指望日志
  模板里写 "[x] ", msg
      现象：报 invalid_formatter_template
      处理：模板里的字面量要写成 binary：<<"[x] ">>
  直接 logger_disk_h 当 handler
      现象：报 function_not_exported(logger_disk_h, log, 2)
      处理：用 logger_std_h + config#{type => {file, Name}}
```

最后一条值得单独说：**没有 `logger_disk_h` 这个 handler**。
写文件要用 `logger_std_h` 并配 `config#{type => {file, Name}}`：

```erlang
logger:add_handler(my_file, logger_std_h,
    #{config => #{type => {file, "/var/log/myapp.log"}}, level => info}).
```

---

## 第 28 章 调试、热加载与运维

> 示例：`examples/28-debugging-ops.erl`　输出：`build/28-debugging-ops/stdout.txt`
>
> 这一章复用第 23 章的 `kvapp`（`examples/kvapp/`），把它当"线上服务"来操作。

### 28.1 sys：不停机查看/修改一个 OTP 进程

```
  sys 是 OTP 自带的"调试通道"：它用**系统消息**跟进程说话，
  所以不需要你在 gen_server 里写任何额外代码。

  sys:get_state（服务自己才知道的状态） = #{max => 100,mode => memory,
                                tab => kvapp_store_tab,puts => 0}
    放了两条之后的 state = #{max => 100,mode => memory,tab => kvapp_store_tab,
                      puts => 2}
```

`sys:get_state/1` 能拿到 `gen_server` 的**内部 state**，而服务代码里一行都不用写。
这是 OTP 的福利：只要你的进程遵守 OTP 约定，工具链就能"透视"它。

```
  -- 改状态：线上救急用，但要小心 --
  sys:replace_state 把 puts 计数改成 999 = #{max => 100,mode => memory,
                                        tab => kvapp_store_tab,puts => 999}
    all()（数据没动） = [{alpha,1},{beta,2}]
    count() = 2
```

> `sys:replace_state/2` 直接改内部 state，**绕过所有业务逻辑**。
> 只作为线上救急手段，改完要考虑重启恢复一致性。

```
  -- get_status：人读的版本 --
  是 {status, Pid, {module, _}, 清单} 这个形状吗 = true
    module（注意是行为模块名，不是你的模块） = gen_server
    清单长度（固定的 5 项） = 5
    最后一项的 header = "Status for generic server kvapp_store"
    最后一项里的 State = [{"State",
                     #{max => 100,mode => memory,tab => kvapp_store_tab,
                       puts => 999}}]
  observer / 各种运维工具显示的就是这个结构。
```

注意 `{module, gen_server}` 里是**行为模块名**（`gen_server`），
不是你的业务模块（`kvapp_store`）。`observer`  GUI 显示的就是 `sys:get_status` 的结果。

```
  -- 开关统计与日志 --
  sys:statistics 开 = ok
    开完之后 get_status 里多出来的项 = [header,data,data]
  sys:statistics 关 = ok
  sys:log 开始记录事件 = ok
    记录下来的事件条数 = 4
    每条事件的第一项（事件类型） = [in,out,in,out]
  sys:log 关 = ok

  -- 挂起与恢复 --
  sys:suspend = ok
    挂起期间 call 会超时（业务侧表现为"卡住"） = {exit,timeout}
  sys:resume = ok
    恢复之后 = 3
```

`sys:suspend/1` 在生产上可以用来"冻结"一个进程做排查
（比如它正在疯狂打日志），恢复用 `sys:resume/1`。挂起期间所有 `call` 会超时。

`sys:no_debug(Pid)` 一键关掉所有调试开关（statistics / log / trace）——
`sys:trace` 会把每条系统消息打到 stdout，很容易把终端刷爆。

### 28.2 proc_lib：手写进程的启动同步与身份信息

```
  直接 spawn 有两个问题：
    (a) start 函数返回时，子进程**可能还没初始化完** —— 经典竞态；
    (b) 它崩了之后，崩溃报告里只有 <0.87.0>，看不出是谁。
  proc_lib 解决这两件事。

  proc_lib 启动的进程是活的 = true
    start/0 返回时 init 已经跑完了（init_ack 保证的） = true
    进程字典里的键 = ['$ancestors','$initial_call']
    $initial_call（崩溃报告靠它显示"本来要跑哪个函数"） = true
    $ancestors（谁启动了我；监督者靠它认孩子） = true
    对比：普通 spawn 的进程字典 = []
```

`proc_lib:start_link` + `proc_lib:init_ack` 的标准写法：

```erlang
start_link() ->
    proc_lib:start_link(?MODULE, init, [self()]).

init(Parent) ->
    %% 做初始化...
    proc_lib:init_ack(Parent, {ok, self()}),  %% ← 这一行之后 start_link 才返回
    loop().
```

`init_ack` 之前 `start_link` **一直阻塞**，所以调用方返回时初始化一定完成了。

```
  -- 初始化失败要显式通知 --
  init_fail 让调用方拿到错误 = <0.10.0>
    proc_lib:stop 也要 sys 支持，我们这个进程不认 → 会一直等到超时 = {exit,timeout}

  ⚠ 常见误解：proc_lib **不**自动支持 sys。
    想让手写进程也能被 sys 查看，循环里必须自己处理系统消息：
        receive {system, From, Req} -> sys:handle_system_msg(Req, From, ...);
    或者干脆用 gen_server —— 这些它都替你做了。
```

> **`proc_lib` 不等于 OTP 进程**。它只解决了"启动同步"和"身份信息"两件事，
> **没有**给你 `sys` 支持、`terminate` 回调、代码热加载。想要这些就用 `gen_server`。

### 28.3 热代码加载：局部调用 vs 全限定调用

这是 Erlang 最有名也最容易出错的特性。规则只有两条：

```
  一个模块在虚拟机里可以**同时存在两个版本**。规则是：
    · 局部调用（直接写函数名）→ 永远用**当前进程正在跑的那一版**；
    · 全限定调用（?MODULE:f()）→ 永远用**最新的一版**。
  所以循环函数要想升级后立刻生效，必须写成  ?MODULE:loop(...)。
```

实测：

```
  第 1 版：局部调用 loop() = {'EXIT',<0.87.0>,shutdown}
  第 1 版：全限定调用 ?MODULE:ver() = 1
  装完第 2 版（ver/0 从 1 改成 2）之后：
    还在跑的 loop（局部调用）→ 还是旧值 = 1
    还在跑的 loop_fq（全限定调用）→ 拿到新值 = 1
  erlang:check_old_code（有旧版本在跑吗） = true
    新起的进程用 loop（局部调用）也是新的 = 2
```

（注意"全限定调用"那行实测值也是 `1`，因为示例里 P1 在加载新代码**之前**就取了值；
关键在于**循环**用哪种写法 —— 这决定了升级后新的一轮循环用哪个版本。）

```
  -- 旧版本什么时候被清掉 --
  code:soft_purge（只清没人跑的旧版） = false
    因为 P1 还在跑旧版，所以清不掉；check_old_code 仍是 = true
    把 P1 杀掉之后再 soft_purge = false
    check_old_code = true
  code:purge/1 是**硬清**：会把还在用旧版的进程直接杀掉，慎用。
```

| 操作 | 行为 |
| --- | --- |
| 加载第 3 版 | 第 1 版被自动清掉（最多同时存在**两个**版本） |
| `code:soft_purge/1` | 只清"没人在跑"的旧版，返回是否清成功 |
| `code:purge/1` | **杀掉**还在跑旧版的进程，强制清理 |

> 生产上永远用 `code:soft_purge`。`code:purge` 会静默杀掉正在跑旧代码的进程。

**实践结论**：
- 常驻循环（服务器循环、`gen_server` 的回调）**必须**能拿到新版本 ——
  `gen_server` 内部已经用全限定调用做了这件事，所以你不用管；
- **手写循环**（`loop(State) -> ... loop(State1)`）**必须**写成 `?MODULE:loop(State1)`，
  否则加载新代码后这个进程会一直跑旧版本，直到它被重启。

### 28.4 内省：出问题第一眼看什么

```
  进程数 > 0 = true
    已经注册了名字的进程数 > 0 = true
    端口数 > 0 = true
    ETS 表数 >= 0 = true
  erlang:system_info(process_count) 与 length(processes()) 一致吗 = true

  -- 按注册名找进程 --
  whereis(kvapp_store) 是 pid 吗 = true
  whereis(一个没注册的名字) = undefined
  registered() 里能找到 kvapp_store 吗 = true

  -- 找出"最可疑"的进程：邮箱最长的 --
  邮箱最长的三个进程的队列长度（只打数字，不打 pid） = [1,0,0]
  邮箱一直涨 = 有人发得比处理得快。这是线上最常见的"变慢"原因。
```

**"线上变慢但 CPU 不高"的第一嫌疑就是邮箱堆积**。定位方法：

```erlang
%% 按邮箱长度倒序，取前 10
Top = lists:sublist(
        lists:reverse(lists:keysort(2,
            [{P, Q} || P <- erlang:processes(),
                       {message_queue_len, Q} <- [process_info(P, message_queue_len)]])),
        10).
```

```
  -- 内存占用最大的进程 --
  具体字节数每次运行都不一样（而且和调度器个数有关），
  所以这里只断言它的**性质**：
  每个进程的内存都 > 0 = true
  取前三大的，结果是递减的 = true
  三个之和 <= 总内存 = true

  -- 一个进程到底在干什么 --
  process_info(whereis(kvapp_store), current_function) 有值吗 = true
    current_function 是个 {模块, 函数, 参数个数} = 3
    reductions（跑了多少"步"，越大越忙） = true
```

> 内存的具体数字**随调度器个数变化**（同一个仓库用 `./run-all.sh` 和
> `pwsh ./build.ps1` 跑出来的就不一样）。所以这里只断言性质。
> 这是本教程所有示例的共同约定：**环境相关的值一律改成布尔断言**。

`current_function` 告诉你"这个进程卡在哪一行"—— 配合 `reductions` 的差值
（隔 5 秒取两次）能看出它到底在忙还是在等。

### 28.5 常见错误清单

```
  改了代码但进程行为没变
      现象：循环里用了局部调用，进程还在跑旧版本
      处理：循环写成 ?MODULE:loop(State)
  release 升级后老进程跑老代码
      现象：同上：最多同时存在两个版本
      处理：要么全限定调用，要么让监督者重启进程
  code:purge 之后有进程莫名死了
      现象：purge 会杀掉还在跑旧版的进程
      处理：先用 code:soft_purge；确认没人用了再 purge
  sys:get_state 卡住不返回
      现象：目标不是 OTP 进程（不处理系统消息）
      处理：手写进程要在循环里调 sys:handle_system_msg/6，或者改用 gen_server
  sys:replace_state 改完服务行为怪了
      现象：绕过了所有业务逻辑直接改内部状态
      处理：只作为应急手段；改完要考虑重启
  用 sys:trace 之后日志刷屏
      现象：trace 会把每条系统消息打到 stdout
      处理：sys:no_debug(Pid) 一键关掉所有调试开关
  spawn 之后立刻用，偶尔拿不到
      现象：start 返回时子进程还没初始化完
      处理：用 proc_lib:init_ack 做启动同步，或者干脆用 gen_server
  崩溃报告里只有 pid，看不出是谁
      现象：进程字典里没有 $initial_call
      处理：用 proc_lib 起进程，或放进监督树
  线上"变慢"但 CPU 不高
      现象：某个进程邮箱堆积
      处理：按 message_queue_len 排序找最长的那个
  registered() 拿不到想要的名字
      现象：进程已死或名字被别人先注册了
      处理：whereis/1 返回 undefined 就当没这个人，别直接当 pid 用
```

---

## 第 29 章 构建与验证

这一章讲本教程**自己是怎么被验证的**。看懂它，你就能：

- 复核指南里任何一条输出；
- 往 `examples/` 里加新示例并保证它不会悄悄退化；
- 把这套"双入口 + 四条判定 + 反向验证"的思路搬到你自己的项目里。

### 29.1 目录结构

```
erlang/
├── README.md                  简介 + 工具链 + 各章索引 + 当前状态
├── Erlang-OTP编程指南.md       教程正文（就是这份文档）
├── build.ps1                  PowerShell 入口（Windows / macOS / Linux）
├── run-all.sh                 shell 入口（macOS / Linux / WSL）
├── examples/
│   ├── 01-hello.erl           NN-topic.erl：两位编号 + 主题
│   ├── ...
│   ├── 28-debugging-ops.erl
│   └── kvapp/                 第 23、28 章用的示例 application
│       ├── kvapp.app          .app 资源文件（erlc 不认，脚本手工拷进 build/ebin）
│       ├── kvapp_app.erl
│       ├── kvapp_sup.erl
│       └── kvapp_store.erl
└── build/                     编译与运行产物（不入库）
    ├── ebin/                  所有 .beam
    └── <示例名>/
        ├── stdout.txt  stderr.txt       通道 A（默认调度器）
        └── stdout.s1.txt stderr.s1.txt  通道 B（+S 1:1）
```

**命名约定**：`NN-topic.erl`。编号决定运行顺序，也决定结束标记
（`==== NN 结束 ====`）。数字开头的文件名意味着模块名**必须加引号**：

```erlang
-module('01-hello').
-export([main/0]).
```

运行命令也因此要写引号：

```bash
erl -noshell -pa build/ebin -run '01-hello' main -s init stop
```

### 29.2 两个入口

```bash
./run-all.sh                 # shell 版
pwsh ./build.ps1 -All        # PowerShell 版
```

| 需求 | shell 版 | PowerShell 版 |
| --- | --- | --- |
| 跑全部 | `./run-all.sh` | `pwsh ./build.ps1 -All` |
| 附带打印每个示例的输出 | `./run-all.sh -v` | `pwsh ./build.ps1 -All -ShowOutput` |
| 只跑指定编号 | `./run-all.sh 01 13` | `pwsh ./build.ps1 01 13` |
| 只跑指定文件 | （用编号） | `pwsh ./build.ps1 -Example 24-ets.erl` |
| 清理 build | `./run-all.sh --clean` | `pwsh ./build.ps1 -Clean` |
| 改超时上限 | `TIMEOUT_SECS=8 ./run-all.sh` | `pwsh ./build.ps1 -All -TimeoutSec 8` |
| 指定工具链 | `ERL=... ERLC=... ./run-all.sh` | 自动探测 PATH / 常见安装路径 |

两个入口做**完全一样的事**，包括输出的措辞。本教程的收尾要求之一是
**两者产生的 56 个输出文件逐字节一致**（实测：`一致 56  不一致 0`）。

> **不要并行跑两个入口**：它们共用 `build/<示例名>/stdout.txt`，并行会互相覆盖，
> 导致输出只写一半、结束标记丢失，然后被误报成"示例 bug"。
> 这个坑在好几个教程目录里都踩过（见仓库根的 MEMORY.md）。

### 29.3 四条判定标准

每个示例在每个通道下必须同时满足：

| # | 判定 | 为什么 |
| --- | --- | --- |
| 1 | **退出码为 0** | 崩了就是崩了 |
| 2 | **stderr 为空** | Erlang 的崩溃报告、SASL 日志、进度提示都走 stderr，非空就说明有异常 |
| 3 | **stdout 里除 TAB/LF/CR 外没有 0..31 的控制字符** | 抓"终端转义序列漏进输出"（比如 `sys:trace`、`io:format` 打了 `\e[31m`） |
| 4 | **stdout 里有 `==== NN 结束 ====`** | 抓"程序跑了一半就死了"—— 退出码可能是 0，但标记在最后一行 |

第 4 条是最有价值的：Erlang 里 `main/0` 抛异常时，如果没人 link 它，
进程死了但 `erl` 的退出码**仍然可能是 0**。只有结束标记能证明
"这个示例真的从头跑到尾"。

**编译阶段**另有两条：

- 用 `erlc -Werror -Wall` —— **警告即错误**；
- 编译失败就停止运行（不带着旧 .beam 继续跑，那样会得出误导性结论）。

### 29.4 为什么是"两个通道"而不是"多实现比对"

仓库里 fortran / sml 那几个目录的惯例是**每份示例在两套实现上跑**
（flang + gfortran、SML/NJ + Poly/ML + MLton）。Erlang 这里做不到 ——
本机只有一套实现（erts 17.0.3 / OTP 29）。

所以改成**同一份 BEAM、两种运行时配置**：

| 通道 | 启动参数 | 含义 |
| --- | --- | --- |
| A | （默认） | 多调度器，正常情况 |
| B | `+S 1:1` | 单调度器 |

两通道的输出必须**逐字节一致**。这条约束比听起来强得多，它抓的是
"输出依赖调度/环境"这类不可重复的东西：

- **map 的迭代顺序每次进程启动都随机**（原子哈希用了随机种子）→ 不 `lists:sort` 就露；
- **ETS `set` 的顺序未定义** → 打出来就露；
- **打了 pid / ref / 时间戳** → 每次都不一样，必露；
- **内存占用的具体字节数**、**`port_limit` 的具体数字** → 随调度器个数和环境变，必露。

最后这一类无法"修好"，只能**改断言形式**：把"打具体数字"改成打布尔断言
（"每个都 > 0"、"递减"、"三者之和 ≤ 总内存"）。第 26.6、28.4 节都是这么处理的。

### 29.5 反向验证：确认判定标准真的会 FAIL

**判定标准本身也可能有 bug** —— 一个永远返回 OK 的判定函数比没有判定更危险
（它制造虚假的安全感）。所以每次改完判定逻辑，都要造几个"故意违规"的示例，
确认它真的报 FAIL。本轮做过的六个场景：

| 场景 | 造假方式 | 期望 | 实测 |
| --- | --- | --- | --- |
| A | 示例不打结束标记 | FAIL（缺标记） | ✅ 两个入口都报 FAIL |
| B | 往 stderr 写一个字节 | FAIL（stderr 非空） | ✅ |
| C | stdout 里打 BEL(7) / ESC(27) / 0x01 | FAIL（控制字符） | ✅ |
| D | `halt(3)` | FAIL（退出码 3） | ✅ |
| E | `receive X -> X end`（永不结束） | FAIL（超时 + 缺标记） | ✅ `TIMEOUT_SECS=8` |
| F | 缺句点 + 未定义变量 | 编译阶段 FAIL 并停止 | ✅ |
| G | 打 `schedulers_online` | `[DIFF] 两通道输出不一致` | ✅ |

场景 E 顺带验证了**超时机制本身**：本机没有 GNU `timeout`，
`run-all.sh` 里的 `run_limited` 是自己起一个看门狗子进程实现的
（到点 kill 掉 `erl`，并返回 124）。

### 29.6 怎么复核文档里的某一条输出

文档里的每个「实测输出」块都来自 `build/<章>/stdout.txt`。复核办法：

```bash
# 1) 只跑那一章
./run-all.sh 25            # 或：pwsh ./build.ps1 25

# 2) 看它的完整输出
cat build/25-binary-files/stdout.txt

# 3) 想看运行过程（含每个示例的完整 stdout）
./run-all.sh -v 25
```

如果你的 `build/` 是空的（比如刚 clone），先跑一次全量：

```bash
./run-all.sh        # 28 个示例 × 2 通道，本机约 30 秒
```

单跑一个文件（不走判定，只是看结果）：

```bash
erlc -Wall -Werror -o build/ebin examples/25-binary-files.erl
erl -noshell -pa build/ebin -run '25-binary-files' main -s init stop
```

### 29.7 示例文件的写法约定

每个示例都遵守这几条，原因都写在后面：

1. **文件头注释里给出准确的编译/运行命令** —— 读者复制就能跑；
2. **正文按 `1) 2) 3)` 分节打印**，和文档的小节一一对应；
3. **最后一行一定打印 `==== NN 结束 ====`** —— 判定标准第 4 条；
4. **环境相关的值一律改成布尔断言**（具体数字、pid、时间戳、内存字节数）；
5. **想演示"运行期错误"，值必须来自参数或 `opaque_*()` 函数** ——
   因为 `erlc -Werror -Wall` 会在**编译期**就判死"必然 badarith"的表达式，
   比如直接写 `math:sqrt(-1.0)` 编译就过不去（见 26.7）；
6. **会打 pid / ref 的地方要遮掩** —— 本教程用 `'<Ref>'` 之类的占位，
   或者直接不打（只打"是 ref 吗"这种布尔）。

第 5、6 条是 Erlang 特有的，也是本教程所有示例里反复出现 `opaque/1` 的原因。

### 29.8 两个入口的实现坑（写给要维护脚本的人）

这些都是本轮真踩过的，写自动化脚本时值得抄作业：

- **PowerShell 的 `Start-Process -RedirectStandardOutput` 会吞空行**：
  `"A\n\nB\n"`（5 字节）捕获后变成 `"A\nB\n"`（4 字节）。
  56 个输出里有 54 个因此和 shell 版不一致。改用
  `System.Diagnostics.ProcessStartInfo` + `StandardOutput.BaseStream.CopyToAsync`
  按字节捕获就对了。
- **`Start-Process` 会吃掉参数里的内层双引号**：
  `-eval 'io:format("A"),halt(0).'` 传进去变成 `io:format(A)`。
  同样是改用 `ProcessStartInfo` 自己拼 `Arguments`（只对含空白的参数加引号）。
- **`Start-Process` 不允许 stdout / stderr 重定向到同一个文件** —— 必须拆两个。
- **bash 的 `tr` / `grep` 一律要 `LC_ALL=C`**：UTF-8 locale 下 toybox 的 `tr`
  碰到非法 UTF-8 会报 `Illegal byte sequence` 并**在那里截断输入**，
  导致"结束标记丢失"的假 FAIL。本脚本只在 `tr`/`grep` 的调用点加 `LC_ALL=C`
  （不能全局设 `C`，否则中文变问号）。
- **PowerShell 的 `-Verbose` 是保留的公共参数名** —— 自定义 switch 不能叫它
  （本脚本改叫 `-ShowOutput`）。
- **`[CmdletBinding(PositionalBinding = $false)]`** 必须配合
  `[Parameter(ValueFromRemainingArguments = $true)]`，否则 `./build.ps1 24`
  里的 `24` 会被绑给第一个位置参数当文件名。
- **pwsh 全平台都有只读自动变量 `$IsWindows`**，不能自己定义同名变量。

---

## 第 30 章 坑总表

这一章把前面 28 章分散在各处的坑集中起来，按主题分类。
每条都标了出处章节，想看实测细节就翻回去。

**格式**：`现象` = 你会看到什么；`处理` = 该怎么做。

### 30.1 语法、命名与编译（12 条）

```
模块名和文件名不一致 / 数字开头
    现象：编译失败，或运行时 "undefined module"
    处理：模块名必须等于文件名；含连字符或数字开头要加引号 -module('01-hello')（1.1）
guard 里写 A, B 以为是"或者"
    现象：条件永不成立 / 语义反了
    处理：Erlang 反过来：逗号是 and，分号是 or（5.1）
if 没有任何分支匹配
    现象：抛 if_clause
    处理：最后一个分支写 true -> ...兜底（13.1）
catch Class:Reason 省略了 Class
    现象：只捕获到 throw 类，error 类照样崩
    处理：省略 Class 时默认是 throw；三类要分别写（13.2）
用 catch Expr 包一切
    现象：OTP 29 已废弃
    处理：用 try ... of ... catch Class:Reason:Stack ... end（13.3）
函数名撞上自动导入的 BIF
    现象：调用自己的 get/1 时警告"ambiguous call"，甚至调到 BIF 上
    处理：改名，或显式写 ?MODULE:get/1（21.7）
变量第二次绑定
    现象：编译错误 / 匹配失败
    处理：变量单次绑定；函数体里的 = 是断言不是赋值（4.3、4.4）
record 当字典用，运行期改字段
    现象：编译期报错
    处理：record 只是编译期语法糖，运行期就是元组（11.1）
== 和 =:= 混用
    现象：1 == 1.0 为 true，1 =:= 1.0 为 false
    处理：数值比较一律用 =:= 系列，除非你确实要跨类型（2.7）
maybe 里写成 = 而不是 ?=
    现象：匹配失败直接抛，而不是走 else 分支
    处理：maybe 的短路靠 ?=，else 分支收的是"没匹配上"的值（13.4）
匿名 fun 里递归调用自己
    现象：编译错误 "variable 'F' is unbound"
    处理：把 fun 自己当参数传进去（12.4）
闭包捕获了循环变量
    现象：所有闭包拿到同一个值
    处理：Erlang 捕获的是**值**不是变量，所以没这个问题；
         但推导式里的变量每次都是新绑定，别想多了（12.2）
```

### 30.2 数值与算术（6 条）

```
(-7) div 2 期望 -4
    现象：得到 -3
    处理：div / rem 一律**向零截断**（不是向下取整）（2.4）
浮点溢出期望 infinity
    现象：抛 badarith
    处理：Erlang 浮点溢出是异常，不是 IEEE 的 inf（2.5、26.7）
math:sqrt(-1.0) 期望 nan
    现象：抛 badarith
    处理：同上，涉及负数先自己判断（26.7）
0.1 + 0.2 == 0.3
    现象：false
    处理：金额用整数（分）或十进制库（26.7）
trunc(math:pow(10, 100))
    现象：和真值不一样
    处理：要用大整数就一路用整数，别中途转 float（26.7）
想演示运行期 badarith
    现象：编译就过不去
    处理：-Wall -Werror 会在编译期判死"必然 badarith"；值要来自参数（26.7）
```

### 30.3 字符串、编码与原子（10 条）

```
<<"中文">> 打出来字节数不对
    现象：中文被 latin1 截断成 63
    处理：二进制字面量默认 latin1，要写 <<"中文"/utf8>>（3.4）
~p 打印中文
    现象：打出一串整数，不是文字
    处理：~p 只对 latin1 可打印字符生效；用 ~ts（1.2、3.4）
用 length 算"能显示几个字"
    现象：emoji / 组合字符算错
    处理：显示用 string:length（字素簇），落盘用 byte_size（25.5）
list_to_atom(外部输入)
    现象：原子表一直涨直到节点被杀
    处理：用 list_to_existing_atom，或白名单校验。原子表**不回收**（3.1、26.6）
binary_to_term(不可信数据)
    现象：会创建新原子，DoS 入口
    处理：加 [safe]；但注意原子若已存在，safe 也拦不住（25.9）
file:write_file(F, "中文")
    现象：{error, badarg} —— 是**返回**不是抛，容易静默失败
    处理：用 <<"中文"/utf8>> 或 unicode:characters_to_binary/1（25.4）
file:write_file(F, D, [{encoding, utf8}])
    现象：还是 badarg
    处理：write_file 不接受 encoding 选项，而且错选项被**静默忽略**（25.4）
latin1 设备 io:put_chars 中文
    现象：抛 error:no_translation
    处理：file:open 时加 {encoding, utf8}（25.7）
unicode:characters_to_list 解坏数据
    现象：返回 {incomplete, ...} 元组，不是抛
    处理：匹配返回值，别假设一定成功（25.4）
io:get_line 到文件末尾
    现象：返回原子 eof，不是 ""
    处理：用 =:= eof 判断（25.7）
```

### 30.4 列表、map 与容器（10 条）

```
map 遍历顺序不稳定
    现象：每次进程启动顺序都不一样
    处理：原子哈希有随机种子；要稳定就 lists:sort（10.2）
maps:update 一个不存在的键
    现象：badarg
    处理：=:= 要求键必须存在；插入用 =>（10.1）
proplists:is_defined 语义搞错
    现象：property/1,2 是**构造器**不是判定器
    处理：用 proplists:get_value / is_defined，别被名字骗了（16.2）
proplists 有重复键
    现象：不是 bug，是它的看家本领
    处理：get_value 取第一个；get_all_values 取全部（16.3）
queue:in / queue:snoc 参数顺序
    现象：写反了
    处理：queue:in(Item, Q) vs queue:snoc(Q, Item)，是反的（17.3）
在循环里用 ++ 往尾巴追加
    现象：O(n²)，数据一大就卡死
    处理：头插再 lists:reverse，或用 iolist（7.5）
foldl 的结果顺序反了
    现象：foldl 是逆序构造
    处理：要正序用 foldr，或最后 reverse 一次（7.2）
lists:keyfind / find 返回值不统一
    现象：有的返回元组、有的返回 false、有的返回 none
    处理：每个 lookup 类函数的"没找到"值都不同，别猜（7.3）
推导式里模式不匹配
    现象：元素被**静默跳过**，不报错
    处理：想报错就用严格的生成器或先过滤（8.1）
二进制推导式写成 <-
    现象：编译错误
    处理：二进制推导式用 <=（8.3）
```

### 30.5 进程、消息与热加载（12 条）

```
用 spawn/1 起常驻进程
    现象：热代码加载后它一直跑旧版本
    处理：优先 spawn/3（MFA 形式），存的是 {M,F,A}（18.1）
whereis 的结果直接当 pid 用
    现象：目标没起来时崩溃
    处理：whereis 返回 undefined 不崩，先判断（18.3、28.4）
给已死进程发消息
    现象：静默丢弃，不报错
    处理：需要知道死活就 monitor（19.2）
请求/回复协议不带 Ref
    现象：迟到回复被当成这次的回复
    处理：每次请求用新 ref；gen_server 会丢不认识的消息形状（19.3）
call 超时后继续用返回值
    现象：超时后回复可能还是来了，污染后续所有 receive
    处理：超时后要么 flush 邮箱，要么用 start_timer + ref（19.4）
邮箱很长时"变慢但 CPU 不高"
    现象：选择性接收要扫整个邮箱，O(n)
    处理：监控 message_queue_len；必要时加"先收进缓冲区"的两段式接收（19.5、28.4）
用进程字典存业务状态
    现象：热加载、测试、调试全都难受
    处理：知道就好，别用（18.5）
以为消息是共享引用
    现象：改了这边那边没变 / GC 行为意外
    处理：消息是**拷贝**；大 binary 走引用计数堆外内存（18.2）
spawn 之后立刻用，偶发拿不到
    现象：start 返回时子进程还没初始化完
    处理：proc_lib:init_ack 做启动同步，或直接用 gen_server（28.2）
以为 proc_lib 就等于 OTP 进程
    现象：sys:get_state 卡住不返回
    处理：proc_lib 只管启动同步和身份信息，sys 支持要自己处理系统消息（28.2）
改了代码但进程行为没变
    现象：循环用了局部调用，还在跑旧版本
    处理：循环写成 ?MODULE:loop(State)（28.3）
code:purge 之后进程莫名死了
    现象：purge 会杀掉还在跑旧版的进程
    处理：用 code:soft_purge，确认没人用再 purge（28.3）
```

### 30.6 OTP：gen_server / supervisor / application（11 条）

```
terminate/2 从来不被调用
    现象：关服务时清理逻辑没跑
    处理：gen_server 默认 trap_exit=false，监督者用 exit(shutdown) 关它 →
         必须 process_flag(trap_exit, true)（23.5）
gen_server:call 偶尔超时
    现象：默认只有 5000 毫秒
    处理：显式传第三个参数，或排查是不是邮箱堆积（21.4）
handle_info 收到不认识的消息
    现象：没有 crash 日志，但状态不对
    处理：加一条 catch-all 打日志，别静默忽略（21.4）
回调里抛异常导致整个监督树重启
    现象：一个孩子的 bug 拖垮一片
    处理：能处理的在回调里处理；这是设计意图，但要确认重启策略对（21.5）
which_children 的顺序当固定用
    现象：顺序未定义
    处理：按 id 找，别按下标（22.3）
one_for_all 和 rest_for_one 分不清
    现象：该杀的没杀 / 不该杀的被杀了
    处理：杀**最后一个**孩子才能区分：one_for_all 全重启，rest_for_one 只重启它及之后（22.1）
重启太频繁导致 supervisor 自己崩了
    现象：整个应用挂掉
    处理：intensity / period 是"period 秒内最多重启 intensity 次"的总闸（22.2）
application:get_env 拿到的是旧值
    现象：改了 sys.config 不生效
    处理：env 是应用启动时读一次的**快照**（23.4）
config_change/3 没被调用
    现象：改了配置没反应
    处理：它只在发布升级（release upgrade）时调，日常改配置不走（23.6）
一个应用放了多个顶层监督者
    现象：关闭顺序、依赖关系混乱
    处理：一个应用只应有一个顶层监督者（23.1）
get_all_key 返回的字段比 .app 里写的多
    现象：以为自己漏配了
    处理：它会把没写的字段补成默认值（23.2）
```

### 30.7 ETS（6 条）

```
ets:select 的 body 写成 [{'$1','$2'}]
    现象：badarg
    处理：单元素元组会被当"动作函数"；要返回元组得多套一层 [{{'$1','$2'}}]（24.3）
owner 进程挂了表就没了
    现象：数据凭空消失
    处理：用 {heir, Pid, Data} 转移（24.5）
选项写 {compressed, true}
    现象：badarg
    处理：set/public/named_table/compressed 是**裸原子**；keypos/heir 才是元组（24.6）
write_concurrency 设了但不生效
    现象：读回来是 false
    处理：单调度器（+S 1:1）下被**静默降级**；要确认就读回来（24.6）
建很多 ETS 表
    现象：到达上限建不出来
    处理：ets_limit 默认只有 8192（比进程上限小两个数量级）（26.6）
named_table 重建时 badarg
    现象：进程重启后建表失败
    处理：表名全局唯一，旧表还在（owner 没死透）就建不了；配 heir 或先删（24.5）
```

### 30.8 文件 I/O 与序列化（8 条）

```
filelib:ensure_dir(File) 之后文件不存在
    现象：只建了目录
    处理：名字骗人，它只保证目录部分（25.2）
file:read(Fd, N) 用返回值长度判断是否读完
    现象：读到最后一批时长度小于 N 但还没结束
    处理：只有**下一次** read 返回 eof 才算完（25.6）
file:open(F, [write]) 之后内容丢了
    现象：文件被截断
    处理：要追加必须显式给 [append]（25.6）
关掉句柄后再 read
    现象：{error, terminated}
    处理：句柄是一次性的；忘了 close 会泄漏描述符（25.6）
filelib:wildcard("**/*.erl")
    现象：匹配不到子目录
    处理：* 不匹配路径分隔符；要递归自己写（25.2）
raw 模式下用 io:get_line
    现象：{error, function_clause}
    处理：raw 不支持 io 协议（25.6）
裸存 term_to_binary 的结果
    现象：改一次数据结构，旧文件全解不了
    处理：加一个版本号字段（25.9、25.10）
无脑给 term_to_binary 加 compressed
    现象：短数据反而变大
    处理：只在数据确实大（KB 级）时开（25.9）
```

### 30.9 时间与定时器（8 条）

```
把 monotonic_time 当时间戳存
    现象：重启后全变，甚至可能是负数
    处理：只用它算间隔；存时间用 system_time（26.5）
用 timer:tc 测间隔
    现象：跨 NTP 校时可能量出负数
    处理：erlang:monotonic_time(0) 前后相减（26.5）
cancel_timer 之后以为邮箱干净了
    现象：消息可能已经投递
    处理：cancel 之后 receive ... after 0 清一次（26.2）
用 cancel_timer(Ref) > 0 判断取消成功
    现象：永远为"真"
    处理：失败时返回 false，而 false > 0 在 Erlang 里是 true（原子 > 整数）（26.2）
timer:cancel 总是返回 {ok, cancel}
    现象：以为取消成功了其实没有
    处理：要精确控制就用 erlang:cancel_timer（26.3）
receive after 一个变量
    现象：变量为负时抛 timeout_value
    处理：超时值也要防御性检查（26.4）
大量定时器全用 timer 模块
    现象：挤在一个 timer_server 进程里
    处理：高频用 erlang:send_after；OTP 27+ 只有发注册名/远端才走服务进程（26.3）
receive after 里写 0 想"等一下"
    现象：根本不等，直接走超时分支
    处理：after 0 是"非阻塞接收"惯用法，不是"等 0 毫秒"（26.4）
```

### 30.10 日志与运维（8 条）

```
logger:info 什么都没打出来
    现象：默认 primary level 是 notice
    处理：set_primary_config(level, info) 或写进 sys.config（27.3）
set_module_level 不生效
    现象：模块级靠 mfa 元数据，logger:info 不带
    处理：改用 ?LOG_INFO 宏（27.6）
过滤器返回 ignore 日志还在
    现象：ignore = 不表态，不是丢弃
    处理：要丢就返回 stop（27.9）
过滤器崩了之后所有日志都出来了
    现象：logger 把出错的 filter 摘掉了
    处理：filter 必须处理 msg 的三种形状（27.9）
把日志当审计/业务数据
    现象：过载时日志**真的会被丢**（drop_mode_qlen）
    处理：要可靠就走数据库/消息队列（27.11）
模板里写 "[x] ", msg
    现象：invalid_formatter_template
    处理：字面量要写成 binary：<<"[x] ">>（27.8）
日志输出里有 pid/时间戳，测试没法比对
    现象：默认模板带了 time 和 pid
    处理：自定义 template 去掉它们（27.8）
直接拿 logger_disk_h 当 handler
    现象：function_not_exported(logger_disk_h, log, 2)
    处理：用 logger_std_h + config#{type => {file, Name}}（27.12）
```

### 30.11 一条元规则

上面 80 多条里，有一半属于同一类问题：

> **"它没报错"不等于"它生效了"。**

- `file:write_file` 写中文失败 → 返回 `{error, badarg}`，你不匹配就不知道；
- `write_file` 的 `{encoding, utf8}` 选项被静默忽略 → 拼错了也返回 `ok`；
- `write_concurrency` 被静默降级 → "设置了"和"生效了"是两回事；
- logger 的关卡说"不要" → 日志消失且**不报错**；
- 给已死进程发消息 → 静默丢弃；
- 推导式里模式不匹配 → 元素被静默跳过。

Erlang 的哲学是"让它崩，让别人重启"，但**这个承诺只覆盖会崩的错误**。
上面这些"静默失败"恰恰是不崩的那部分 —— 所以写 Erlang 时，
**对返回 error 元组的地方要显式匹配，对选项要读回来验证**。
这是这份指南最想留下的结论。

---

## 附录：常用命令速查

```bash
# 版本
erl -noshell -eval 'io:format("~s/~s~n",[erlang:system_info(otp_release),
    erlang:system_info(version)]),halt(0).'

# 编译（警告即错误）
erlc -Wall -Werror -o build/ebin examples/01-hello.erl

# 运行单个模块
erl -noshell -pa build/ebin -run '01-hello' main -s init stop

# 单求值
erl -noshell -eval 'io:format("~p~n",[lists:sort([3,1,2])]),halt(0).'

# 应用方式启动（需要 .app 在代码路径里）
erl -noshell -pa build/ebin -eval 'application:ensure_all_started(kvapp),
    io:format("~p~n",[application:which_applications()]),halt(0).'

# 全量验证（两个入口二选一，不要并行）
./run-all.sh
pwsh ./build.ps1 -All

# 只跑一章
./run-all.sh 25
pwsh ./build.ps1 25
```

```erlang
%% shell 里最常用的几条（erl 不带 -noshell）
c(mod).                    %% 编译并加载
c(mod, [debug_info]).      %% 带调试信息（observer / debugger 需要）
l(mod).                    %% 重新加载
m().                       %% 列出已加载模块及改动
rr(mod).                   %% 把 record 定义读进 shell
rp(Expr).                  %% 用 ~p 打印
q().                       %% 退出（init:stop()）
help().                    %% shell 命令帮助
```
