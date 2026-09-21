# 02 · 第一个程序

> 对应示例：[`examples/02_hello/02_hello.pl`](../examples/02_hello/02_hello.pl)

## 2.1 Prolog 没有 `main`

在 C/Java/Go 里，「程序从哪开始」是语言规定好的。**Prolog 没有这个概念** —— 它只是一个
交互式环境，你加载文件、然后提问。所以才需要 `?-` 提示符。

本教程把所有示例都脚本化，约定用 `main/0` 当入口：

```prolog
main :-
    (   catch(run, E, (format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   format(user_error, "*** run/0 失败~n", []),
        halt(1)
    ).
```

这五行是整个文件里最值得背下来的部分，它一次解决四件事：

- `catch(run, E, ...)`：异常不许逃到顶层（逃出去就是满屏 `ERROR: ...`，判定直接挂）；
- 异常原因用 `format(user_error, ...)` 写 **stderr**，stdout 保持干净；
- `-> halt(0) ; ... halt(1)`：**成功与失败分开给退出码**，CI 直接读；
- **没有 `halt` 的话，程序跑完会掉进交互式 toplevel 等键盘输入** —— 在脚本里就是永久挂死。

> 这条「`halt` 必须写在入口」的纪律还牵出通道 3 的一个坑：`gplc` 编译出的二进制如果源码里
> 没有 `:- initialization(main).`，同样会掉进 toplevel。所以 `run-all.sh` 拼入口文件时，
> 第一行永远是 `:- initialization(main).`。

## 2.2 文件骨架

```prolog
:- set_prolog_flag(double_quotes, codes).

say(S) :- format("~s~n", [S]).

program_name('Prolog 教程示例 02').

demo_output :- ...
demo_format :- ...
demo_utf8   :- ...

run :-
    format("==== 02 开始 ====~n", []),
    say("..."),
    demo_output,  say(""),
    demo_format,  say(""),
    demo_utf8,    say(""),
    format("==== 02 结束 ====~n", []).
```

三个约定：

1. **`:- set_prolog_flag(double_quotes, codes).` 是每个文件的第一行指令。**
   SWI 默认把 `"abc"` 当 string 对象，GNU 默认当字符码列表，不统一的话两套引擎行为直接
   分叉（15 章细讲）。
2. **`say/1` 这个封装把「格式串里混进 `~`」这类事故挡在外面。** 而且 `~s` 按字符码原样
   输出，中英文都不会被加引号 —— 这是唯一稳妥的常量文字通道。
3. **打印用两条标记圈起来**，验证脚本靠它抽取比对区间（01 章 1.5 节）。

## 2.3 输出三件套

| 谓词 | 行为 | 适用 |
|---|---|---|
| `write/1` | 原样打，不加引号 | 给人看的裸文本；原子带空格时看不出边界 |
| `writeq/1` | 必要时加引号，**能读回** | 回显给程序员看、序列化 |
| `format/2` | 完全控制排版 | 唯一能在两套引擎上稳定控制数值格式的手段 |

```text
write/1   : prolog
write/1   : [a,b]
writeq/1  : 'hello world'
writeq/1  : [a,1]
format/2  : plain / 'a b' / plain
```

注意 `write/1` 打 `'hello world'` 时输出的是 `hello world`（看不见边界），而 `writeq/1`
会补上引号。**要「能被 `read/1` 读回来」就用 `writeq/1`**（14 章用它做序列化）。

`nl/0` 与格式串里的 `~n` 等价，区别是 `nl/1` 能指定流。

## 2.4 `format` 说明符速查（实测）

```text
  w  通用 : [1,a,f(x)]
  q  加引号 : 'a b'
  a  原子 : plain
  d  十进制 : 255
  c  字符 : A
  2f 定点两位 : 3.14
  3f 定点三位 : 3.142
  e  科学计数 : 3.141590e+04
  r  指定进制 : 12
  混排 : bob 有 2 个孩子，第 1 个叫 ann
```

| 说明符 | 含义 | 说明 |
|---|---|---|
| `~w` | `write/1` 形式 | 列表会打成 `[1,a,f(x)]` |
| `~q` | `writeq/1` 形式 | 需要时加引号，可读回 |
| `~a` | 原子 | 只对原子有效，比 `~w` 更严格 |
| `~d` | 十进制整数 | |
| `~c` | 字符（给码点） | `~c` + `65` → `A` |
| `~s` | 字符码列表按字符串输出 | **打中文/常量文字走这个** |
| `~2f` `~3f` | 定点 n 位 | |
| `~e` | 科学计数 | |
| `~r` | 指定进制 | `~r` + `10` → `12`（八进制） |
| `~n` | 换行 | **不消耗实参** |
| `~~` | 字面量 `~` | |

两条硬规则：

- **`format/1` 不存在。** `format("hello~n")` 在 SWI 上能跑（它有重载），GNU 上直接
  `existence_error(procedure, format/1)`。**永远写 `format(Fmt, [])`**。
- **内容不要写进格式串。** 格式串里出现 `%` 时两套引擎结论不同：SWI 把 `%` 当普通字符，
  GNU 把它当**说明符**（`%%` 打 `%`；单独的 `%` 会去实参列表找参数，找不到就报
  `domain_error(non_empty_list, [])`）。所以正文文字一律用 `~s` 从实参传进来
  （22 章写文件时踩过，见 22.5）。

## 2.5 中文输出

```text
  UTF-8 直出: 事实 → 规则 → 查询
  用 ~s 说明符打中文字符码列表:
      逻辑编程
  用 ~w 说明符打中文原子:
      逻辑编程
  atom_length(ascii)    : 5
  atom_length('hello')  : 5
  中文的 atom_length 两边不同（4 vs 12），本教程一律不做这种操作
```

**中文的显示是安全的，中文的「计数」是危险的。**

`"逻辑编程"` 是四个汉字。SWI 的 `atom_length/2` 按 **Unicode 码点**数，得 4；GNU 按
**UTF-8 字节**数，得 12（每字 3 字节）。`atom_codes/2`、`sub_atom/5`、`atom_chars/2`
同理全部不同。

所以本教程的纪律是：**中文只用于显示，不做任何字符级的长度/截取/切分操作**。要处理文本
就改用在 ASCII 上语义一致的那批谓词（15 章）。

## 2.6 命令行参数

```text
  argv 标志可读: 是
  但 argv 的内容与长度两边不同（GNU 会把 --consult-file 之类算进去），
  可移植代码不要依赖 argv[0]；真要参数就走环境变量或固定文件名。
```

`current_prolog_flag(argv, L)` 两套引擎都有，但**填进去的内容不同**：GNU 会把
`--consult-file` 这种自己的启动参数也算进 `argv`。所以可以探测「有没有这个标志」，
但不要依赖具体下标。要传参数就用环境变量或固定文件名。

## 2.7 部署与退出码

```text
  开发期解释执行：
    swipl   -q -f prog.pl -g main -t halt
    gprolog --consult-file prog.pl --entry-goal main
  发布期编译：
    swipl -o prog -c prog.pl    （源文件要有 :- initialization(main, main). ）
    gplc  entry.pl -o prog      （entry.pl 首行 :- initialization(main). ）
  约定：run/0 走到底 -> halt(0)；出岔子 -> 原因写 stderr 并 halt(1)。
```

SWI 编出的是需要 SWI 运行时的**字节码可执行文件**；`gplc` 编出的是**真正无运行时依赖的
本地二进制**，可以直接扔到没装 GNU Prolog 的机器上跑。这是 GNU Prolog 相对 SWI 最实际的
优势（22 章会看到它的代价：**静态链接**把「运行时加载」这条路堵死了）。

## 2.8 坑位清单

1. **忘了 `halt`** → 程序跑完卡在 `| ?-` 提示符等输入，脚本永久挂死。
2. **`gplc` 的产物没有 `:- initialization(main).`** → 同上，产物掉进 toplevel。
3. **`format/1`** → GNU 上 `existence_error`；永远写两参数形式。
4. **格式串里混进 `~` 或 `%`** → `~` 被当说明符去取参数，`%` 在 GNU 上是说明符
   （见 2.4）。正文文字走 `~s` 实参。
5. **`~w` 打双引号串** → 双引号串是字符码列表，`~w` 会打出一串数字。**用 `~s`**。
6. **Windows 上不打 `-Dencoding=utf8`** → 满屏 `Illegal multibyte Sequence`。
7. **singleton 变量警告** → 警告进 stderr 就判定失败。只用一次的变量写 `_X`。
8. **中文做 `atom_length`/`sub_atom`** → 两套引擎一个按码点一个按字节，结论不同。

---

下一章：[03 · 事实、规则与查询](03-facts-rules.md)
