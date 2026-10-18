# 02 · 模块与第一个程序

> 对应示例：`examples/02_hello/`（模块名是引号原子 `'02_hello'`，原因见 2.2）

## 2.1 三条命令跑起来

```powershell
cd erlang
erlc -Wall -Werror -o build/02_hello examples/02_hello/02_hello.erl   # 编译成 .beam
erl -noshell -pa build/02_hello -run '02_hello' main -s init stop     # 非交互运行
pwsh ./build.ps1 -Example 02_hello    # 或者：本仓库的四层验证入口
```

| 开关 | 作用 |
|---|---|
| `-noshell` | 不进 REPL，跑完就走 |
| `-pa <目录>` | 把目录加进代码搜索路径（找 .beam 用） |
| `-run <M> <F> [参数...]` | 启动后调用 `M:F(...)`，参数原样传 |
| `-s init stop` | 跑完后正常关闭虚拟机 |

## 2.2 最小模块解剖

```erlang
-module('02_hello').        %% 文件名必须与模块名完全一致，否则 erlc 报错
-export([main/0, greet/1]). %% 显式契约：没列出来的函数对外不可见

main() -> io:format("Hello, Erlang/OTP!~n").
```

- `main/0` 的 `/0` 是 **arity**（参数个数）——`greet/1` 和 `greet/2` 是两个不同的函数；
- 模块名 `'02_hello'` 带引号，因为**以数字开头的名字不是合法原子**，必须写成引号原子。你自己的工程模块用普通名字（`hello`、`kv_store`）即可；
- 变量**大写开头、只绑定一次**（`Name = "x"` 之后再 `Name = "y"` 直接 badmatch）；原子、函数名小写开头。

## 2.3 io:format 动词速查

格式串里 `~X` 是指令，实测对照（完整表在示例输出里）：

| 指令 | 含义 | 例 |
|---|---|---|
| `~p` | 项打印（美化缩进，字符串加引号） | `"abc"` |
| `~w` | 项打印（不美化，字符串还原成码点列表） | `[97,98,99]` |
| `~ts` | 按 Unicode 打印字符串/二进制（中文必用） | `中文` |
| `~s` | 按 latin1 打印；码点 > 255 会 badarg | `abc` |
| `~b` `~.16B` | 十进制 / 指定进制（"精度"就是进制） | `255` `FF` |
| `~f` `~.2f` `~e` | 定点 / 小数位 / 科学计数法 | `3.141590` |
| `~8s` `~-8s` | 宽度右对齐 / 负宽度左对齐 | `[      ab]` |
| `~2..0B` | 宽 2、填充 `0` | `09` |
| `~~` | 字面波浪号（正文里的 `~` 必须写两遍） | `100~%` |

中文出现在**原子**里时 `~p` 会打成 `'\x{4E2D}\x{6587}'` 转义——用 `~tp` 才原样输出；字符串用 `~ts`（09 章展开）。

## 2.4 多子句函数：Erlang 的"分支"

```erlang
greet(Name) when is_list(Name) ->      %% 子句 1：模式 + guard
    io:format("  你好，~ts！~n", [Name]);
greet(Other) ->                        %% 子句 2：兜底
    io:format("  期望字符串，收到 ~p~n", [Other]).
```

子句之间用**分号**，最后一个子句用**句点**；调用时从上往下匹配，没匹配到就抛 `function_clause`。这就是 Erlang 的"if"——模式匹配即分派（04 章展开）。

## 2.5 测试文件初见

```erlang
%% 02_hello_tests.erl
-module('02_hello_tests').
-include_lib("eunit/include/eunit.hrl").   %% 名字 *_test 结尾的函数被自动导出

render_directives_test() ->
    ?assertEqual("[97,98,99]", '02_hello':render("~w", "abc")).
```

和 Go 的 `go test` 一样，测试是**OTP 自带**的：include 头文件、函数名以 `_test` 结尾即可，`eunit:test('02_hello_tests')` 收集执行。本教程每个示例都带测试（build.ps1 第 2 层验证靠它），21 章系统讲断言、fixture 与生成器。

## 2.6 -Wall -Werror：编译器替你拦截运行期错误

```erlang
N = list_to_integer("abc"),   %% 编译期就报：will fail with a 'badarg' exception
{ok, X} = {error, boom},      %% 编译期就报：no clause will ever match
```

本教程所有示例开着 `-Wall -Werror`（警告即错误）。反直觉的后果：**想在示例里演示运行期错误，输入必须来自参数或函数返回值**，不能写编译器能算死的常量——所以示例里到处是这种写法：

```erlang
opaque_zero() -> length(lists:seq(1, 0)).   %% 让编译器看不出这是 0
```

## 2.7 模块自查：module_info 与 code:which

```erlang
code:which('02_hello').                        %% .beam 从哪儿加载的
lists:sort(?MODULE:module_info(exports)).      %% 导出了哪些函数
erlang:function_exported(?MODULE, greet, 1).   %% 某函数是否导出
```

`?MODULE` 是编译期宏（当前模块名原子，2.8 系统讲）。排查"函数明明写了却 undef"时，先看 exports——**没导出的函数从外部调不到**。

## 2.8 预处理与宏

编译一个 `.erl` 其实走两步：**预处理器**先通读源码、做纯文本替换，再把结果交给编译器。你一直在用的 `-module(...)`、`-export(...)`、`?MODULE` 都是预处理器的东西——**凡是 `-` 开头、以 `.` 结尾的顶层指令，都是给它看的**。

### 2.8.1 定义与使用宏

`-define` 定义，`?` 使用：

```erlang
-define(PI, 3.141592653589793).
-define(SQUARE(X), ((X) * (X))).          %% 带参数的宏

circle_area(R) -> ?PI * ?SQUARE(R).
```

带参宏是**文本替换**，不是函数调用：`?SQUARE(3)` 在编译前就被替换成 `((3) * (3))`，等价于 `9`；也没有函数调用的开销。实测 `circle_area(2)` 得 `12.566370614359172`。

正因为是文本替换，**括号必须自己加满**。写 `?SQUARE(A + B)` 时，宏体里外两层括号保证它展开成 `((A + B) * (A + B))`；如果当初定义成 `-define(SQUARE(X), X * X).`，`?SQUARE(A + B)` 展开会变成 `A + B * A + B`，被乘法优先级拆成 `A + (B * A) + B`——结果完全错。**参数加括号、整体再加一层括号**，是宏的保命习惯。

宏名按变量或原子的写法都行（惯例大写，`?PI`）；实测小写的 `-define(debug, true).` 配 `?debug` 同样工作，这也是很多项目里"开关式"宏的写法。宏是**编译期**概念：编译结束宏名就不存在了，生成的 `.beam` 里找不到它。

### 2.8.2 内置宏

不用定义就能用的一批，写日志、写断言时最有用：

| 宏 | 展开为 | 实测（模块 `p`，文件 `p.erl`） |
|---|---|---|
| `?MODULE` | 当前模块名原子 | `p` |
| `?MODULE_STRING` | 模块名的字符串 | `"p"` |
| `?FILE` | 当前源文件名 | `"p.erl"` |
| `?LINE` | 出现处所在的行号 | 整数 |
| `?FUNCTION_NAME` | 所在函数名原子 | `f` |
| `?FUNCTION_ARITY` | 所在函数的参数个数 | `0` |
| `?MACHINE` | 虚拟机名原子 | `'BEAM'` |
| `?OTP_RELEASE` | OTP 主版本号，整数 | `29` |

它们的典型用法是让信息"自己带上坐标"，不用手写常量：

```erlang
log(Level, Msg) ->
    io:format("~s ~s:~b ~s/0: ~ts~n",
              [Level, ?MODULE_STRING, ?LINE, ?FUNCTION_NAME, Msg]).
```

`?LINE` 取的是**使用处**那一行，改动代码后行号自动跟着变。

### 2.8.3 字符串化 `??`

`??X` 把宏的实参**按源码原文**变成一个字符串，常用于打印表达式本身：

```erlang
-define(STR(X), ??X).
```

于是 `?STR(hello)` 得 `"hello"`，`?STR(x + 1)` 得 `"x + 1"`（空格都被规范化成单个空格保留下来）。注意它**不递归展开内层宏**：`?STR(?STR(x))` 得到的是字符串 `"? STR ( x )"`——内层的 `?STR` 只是被当成一段文本，没有先展开。

### 2.8.4 条件编译

`-ifdef` / `-ifndef` 判断"宏有没有定义"，`-else`、`-endif` 收尾，中间可以整块换掉代码：

```erlang
-ifdef(DEBUG).
-define(LOG(M), io:format("[debug] ~ts~n", [M])).
-else.
-define(LOG(M), ok).
-endif.
```

没有定义 `DEBUG` 时走到 `-else` 分支，`?LOG("x")` 展开成 `ok`（实测返回值就是 `ok`，什么都不打印）；编译时加上 `-DDEBUG`（或文件里先 `-define(DEBUG, true).`）就切到打印那条。用 `-ifndef(DEBUG)` 可以反过来。

要按**表达式**判断则用 `-if`，`?OTP_RELEASE` 是最常见的判据——已经验证过 `-if(?OTP_RELEASE >= 27). ... -endif.` 在本机 OTP 29 上取真分支，这正是"同一份代码兼容新旧 OTP"的标准写法。

### 2.8.5 包含文件与取消定义

```erlang
-include("my_defs.hrl").                  %% 相对当前源文件找
-include_lib("eunit/include/eunit.hrl").  %% 到代码路径里找（2.5 已用过）
```

`.hrl` 里通常只放宏和 record（10 章），被多个模块共享。`-include_lib` 的第一段是**应用名**，所以能不管安装位置直接引用 OTP 自带的头文件——2.5 引入 `?assertEqual` 就是靠它。`-undef(M)` 可以取消一个已定义的宏。

一句话总结：**宏是编译期文本替换**。它没有类型、没有作用域、不出现在栈回溯里，好处是零运行时开销，代价是滥用会写出难读的代码——所以本教程只在"常量""开关""日志坐标"这三类场景用它。

## 2.9 坑位清单

1. **模块名与文件名不一致**：`Module name 'x' does not match file name`——一个文件一个模块，名字完全一致（含引号原子的拼写）。
2. **数字开头/带连字符的模块名必须加引号**：`-module('02_hello').`；命令行 `-run 02_hello main` 不用引号（参数本来就是字符串）。
3. **忘了 `-s init stop`**：`-run` 跑完后虚拟机**不退出**，脚本会挂住直到超时。
4. **正文里的 `~` 忘写两遍**：被当成指令、参数数对不上而 badarg——字面量格式串 `-Wall` 能在编译期抓住。
5. **`~s` 打中文崩 badarg**：`~s` 只认 latin1；中文用 `~ts`（09 章），原子用 `~tp`。
6. **在测试模块手写 `-export`**：include eunit.hrl 后 `*_test` 已被自动导出，再手写报 already exported 警告，`-Werror` 直接拦（本次实测）。

---

---

上一章：[01 概述](01-overview.md) · 下一章：[03 数值与基本类型](03-types.md)
