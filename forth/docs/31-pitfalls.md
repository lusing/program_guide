# 31 · gforth 0.7.3 坑清单（Debian/WSL 实测版）

这一章是全教程最有价值的部分——下面每一条都是在本机 0.7.3（WSL Debian）
上**真跑出来的**，不是从文档抄的。代码里搜 `⚠ 坑：` 能看到当时的上下文。

## 字面量与数字

| 现象 | 说明 |
|---|---|
| `f" 3.5"` 不存在 | 浮点字面量必须写 `3.5e0`；`f1.0e`、`1e` 也无效 |
| `**` 不存在 | 没有整数幂运算。自己写循环，或改用 `f**` |
| `d*` 不存在 | 用 `m*/` |
| `pi` 不能重定义 | 它是内置浮点常量 |
| `123.` | 双精度字面量（`d.` 打印不带小数点；`f.` 才带） |
| `>number` 不认负号 | 只转无符号数字；负数要自己处理 `-`（18 章、22 章） |
| 数基参与 `>number` | `hex` 下 `ff` 能转；用完记得 `decimal` |

## 「看起来该有其实没有」的词

`+to`、`-!`、`%free`、`holds`、`traverse-wordlist`、整数 `**`、
`3drop`、`3dup`、`buffer:`、`up@`、`latestnt` —— 都不存在。

| 想要 | 改成 |
|---|---|
| `+to x` | `x 5 + to x` |
| `-!` | `-1 +!` |
| `%free` | `free drop` |
| `holds` | 循环 `hold`；多字节符号要在 `<#` 之前用 `."` 输出 |
| `3drop` / `3dup` | `drop drop drop` / `2 pick 2 pick 2 pick` |
| `buffer: buf n` | `create buf n allot` |

反过来这些**是内置词，别重定义**（redefined 警告走 stderr，判定脚本
直接挂）：`2nip`、`sign`、`sgn`、`.line`、`boot`、`for/next`。

## 会直接崩的词（Address alignment exception）

**别用**：`alias`、`name>int`、`name>comp`。

| 想要 | 改成 |
|---|---|
| 起别名 | `: 新名 旧名 ;` |
| 执行找到的词 | `xt execute` |
| 打印词的名字 | `nt name>string` |
| `objects.fs` | **0.7.3 上完全不可用**，改用 `mini-oof.fs` |
| `libcc`（FFI） | 本机不可用，`libcc.h` 路径拼不对 |
| `find-name` | **Debian 版 0.7.3 上坏了**：一用就 Stack underflow（`(vocfind)` 里炸，交互态同样）。用 `get-current search-wordlist` 包在冒号里代替 |
| `search-wordlist` | **顶层裸调**会 Invalid memory address；包进冒号定义就稳 |
| `require look.fs` / `see.fs` | 炸（`>name`/`see` 已在镜像里）。千万别 require |
| `require arch/amd64/asm.fs` | 炸 unstructured——那是交叉编译器的部件，0.7.3 **没有可用的宿主汇编器**，CODE 定义写不了机器码 |

## 编译期 vs 运行期

| 坑 | 说明 |
|---|---|
| `'` 在冒号定义里用不了 | 报 "zero-length string as a name"。改用 `[']` |
| `[']` 在顶层用不了 | 是 compile-only。顶层拿 xt 用 `' 名字` |
| `[ ' word ]` vs `['] word` | `[']` 把 xt 编成**常量**（运行时才压栈）；immediate 词编译期就要用，必须写 `[ ' word ]` |
| 顶层写 `[ ... ]` | 末尾的 `]` 会把你推进编译态，后面的代码被当编译指令 |
| `[ ... ]` 内部 | 是**解释态**，结构化语句一概不能用 |
| 结构化语句 | 只能用在冒号定义内部 |
| `c"` 和 `,"` | 都是 compile-only。顶层造字符串表用 `create + s,` |
| `s,` | 存的是 **counted string**（首字节是长度）——取回 `count type`，直接 `type` 会打出长度字节 |
| `' 名字 ,` | 存进表的是 **xt 不是 body 地址**——要 body 直接执行 create 词：`n0 ,` |

## 解析词的输入流陷阱（20–22 章）

`parse-name / parse / word / see / find-name / action-of` 都是**从输入流
解析参数**的词：

| 场景 | 后果 |
|---|---|
| 脚本顶层写 `parse-name` | 吃掉**源文件自己的下一个 token**——下一行代码被当数据切走 |
| 包进冒号定义喂参数 | 它抓走**定义体里的下一个 token**（比如 `see` 词内的用法直接炸） |
| 正确姿势 | 驱动词 + `s" 驱动词 数据..." evaluate`；驱动词把余下输入**吃干净**（`>in` 推到行尾） |
| `begin parse-name dup while ... repeat` | 收尾要 **2drop**：parse-name 空手而归也压 `( addr 0 )` |
| 造 counted 串后直接 `type` | 首字节是长度——用 `count type` |

## defer 全家（21 章）

| 坑 | 说明 |
|---|---|
| 未初始化 defer 一执行 | stderr 打 `deferred word xxx is uninitialized`——**catch 拦下来返回 0（假成功），stderr 还是脏**。空占位挂 `' noop is xxx` |
| `is` 的解释态用法 | `xt is 名字`——名字来自输入流，xt 在栈上。写成 `' 名字 is` 会把 defer 词先执行了 |
| `defer!` | 没有返回值，后面别接 `.` |

## locals（09 章 + 25 章实测补充）

| 坑 | 说明 |
|---|---|
| `{ a b \| c }`（带 `\|`） | Address alignment exception。**locals 声明不能带 `\|` 部分**——栈注释里也别写 `\|`（25 章又踩了一遍：静默吃栈） |
| `{ a b }` vs `locals\| a b \|` | **顺序相反**：`{ a b }` 里 a 是次栈顶；`locals\| a b \|` 里 a 是栈顶 |
| `{ }` 声明的参数是局部变量 | 词体里**直接用名字**，别指望它们还在数据栈上 `2dup`——抓错一对 |
| 失败路径要还串 | locals 随词退出消亡：查词失败的分支要在 `false` 前把 `caddr u` 重新压栈 |
| 循环体内 `dup { e }` | 能编译但容易被退出协议咬——循环里走链用变量或 `>r` 配对 |
| 局部变量不能用 `TO` 赋值 | 它只是有名字的栈槽，只能读 |
| gforth locals 不做闭包捕获 | `:noname` 捕不到外层变量 |
| `require test/tester.fs` 之后 | tester.fs 里有 `: { T{ ;`，**把 `{` 抢走**，locals 语法报废 |

## 循环

| 坑 | 说明 |
|---|---|
| `?DO` | 只在「起点 = 上限」时跳过。**起点 > 上限 不是「不循环」**，而是无符号比较一路加到回绕 ≈ 2⁶⁴ 次 = 死循环。要「可能 0 次」用 `begin while repeat` |
| `-1 +LOOP` | 用无符号比较，`0 5 ?do ... -1 +loop` 会跑到 -1 |
| `DO` 参数顺序 | `( 上限 起点 -- )`——写反会「循环 5..0 次」变成超长循环（20 章实测 574 那次的亲戚） |
| `n FOR ... NEXT` | 是 gforth 内置倒数循环；但 asm 词汇表里也有 `NEXT`，require 汇编部件会遮蔽它 |

## 返回栈

| 坑 | 说明 |
|---|---|
| 顶层跨行写 `>r ... r>` | Invalid memory address。改用 `value` 变量存 |
| 想保存 `get-current` 的结果 | 别用 `>r`，用 `0 value saved-current` |
| DO 循环参数住在返回栈 | `i`/`j` 在偷看；循环体内自己的 `>r` 必须本轮配平 |

## 字符串

| 坑 | 说明 |
|---|---|
| `s" 中文词 "` | **尾随空格会被当成名字的一部分**，查找失败 |
| `.(" ... ")` | 里面不能转义 `\"` |
| `,"` | 造的是 counted string，直接 `type` 会打出长度字节，用 `count` |
| `hold` | 每次只放 1 字节，中文等多字节符号要放到 `<#` 之前用 `."` 输出 |
| `s" a" s" b"` 相邻两个串 | 都压栈但随时可能被覆盖——要留先 `save-mem` 或拷进字典 |

## 浮点

| 坑 | 说明 |
|---|---|
| `f=` | 存在，但是**精确比较**，对算出来的值几乎永远假 |
| `f~` 负容差 | ANS 说是绝对误差比较，**0.7.3 实测反直觉**：`f: 0.0e0 0.0e0 -1.0e-9 f~` → **false**。判等请自己写 `f- fabs 容差 f<` |
| `f~` 会吃掉三个浮点数 | `fover fover f- fabs 1.0e-12 f~` 是错的 |
| 在浮点栈上做收敛判断 | 不好写，改用 `fvariable` 存当前值 / 新值 |
| `fvalue` / `fto` 不存在 | 别写 `1.0e0 fvalue x` |
| `fvariable` 初值永远是 0 | `1.5e0 fvariable v` 里的 `1.5e0` 会被丢掉 |

## 词表 / 查找

| 坑 | 说明 |
|---|---|
| `' 名字` | 返回 **xt** |
| `find-name` | 返回 **nt**（但本机 0.7.3 坏了，见上） |
| `search-wordlist` | 返回 **xt** |
| `search-wordlist` 栈深度不一致 | 找到返回 `( xt flag )`，找不到只返回 `( 0 )`。两个分支要分别处理 |
| 没有 `traverse-wordlist` | 没法直接遍历词表 |

## 块（23 章）

| 坑 | 说明 |
|---|---|
| `require blocks.fs` | redefined 噪音全走 stderr——`warnings off` … `require` … `warnings on` 包夹 |
| 块要用**空格**填充 | `n block 1024 bl fill`；填 NUL 的话 `load` 把垃圾字节当 token 报错 |
| `fill` 参数序 | `( c-addr u char )`——1024 要压在地址**之后**（实测反着压 = Invalid memory address） |
| 空文件可以直接写块 | 自动扩文件（实测 9216 字节）；但别 `@` 一个从没写过的块 |
| `open-blocks` 不存在的文件 | 会自动新建（实测），不抛错 |

## 多任务（26 章）

| 坑 | 说明 |
|---|---|
| `activate` 顶层调用 | 主任务返回栈被 `(pass)` 吃掉——**脚本挂死进交互态**。只能包在冒号定义里 |
| `activate` 是「双返回」 | 主任务从这句话直接跳出所在词；新任务从这句话**后面**开始跑。启动词是固定套式（26 章五步走） |
| 任务自然结束 | 会 `kill-task` 自杀并 free 自己——之后再 `kill` 就是 **double free or corruption**（glibc 报） |
| `require tasker.fs` | 同款 redefined 噪音 → warnings off/on 包夹；它还会把 `key/emit/type` 换成带 pause 的版本 |

## 其它

| 坑 | 说明 |
|---|---|
| `create` 后写 `, ,` | **栈顶先存**，所以 `body[0]` = 栈顶那个 |
| `?dup` 后接 `if` | 复制的那份被 `if` 吃掉，剩下那份才是真值（异常码 / xt），别急着 `drop` |
| 未捕获的 `throw` | gforth 会退回交互态等 stdin —— **表现是脚本「卡死」而不是报错退出**。脚本末尾一定写 `bye` |
| **脚本出错退出码仍是 0** | 实测：报了 Undefined word 照样 rc=0——**退出码不可信，stderr 干不干净才是硬门槛**（run-all.sh 两条都查） |
| `catch` 后面 | 不能直接跟复合表达式，必须先封装成词 |
| `try...recover...endtry` | 用不了。except.fs 里根本没有 `recover`；换 `endtry-iferror` 也编译不过（unstructured）。异常用内核的 `catch` / `throw` |
| `abort"` 在定义内 | 会直接抛出。想演示就包一层 `: 试 ( -- ) ... ;` 再 `' 试 catch` |
| `fill` | 按字节填充，不是按 cell |
| `nextname` 的名字缓冲区 | **不能用 `pad`**（`<#` 等词会覆盖），要用自己的 `create` 字典空间 |
| `constant` | 是编译期造词工具，**不能放进冒号定义** |
| `utime` | 双精度。要 `utime 2>r ... utime 2r> d- d>s` |
| `move` 参数序 | `( src dst u )`——摆反了就是悄悄把目标拷进源 |
| 源文件行尾 | `.fs` 要 **LF**；CRLF 的 `run-all.sh` 在 WSL 里直接 `bash\r` 报错 |

最后再强调最容易吃亏的两条：

> **每个词跑完都看一眼栈。** `.s` 是你的第一道防线。
> **stderr 有一行就算挂。** 编译警告也是错——查你的重定义。

（全书完 · 31 章 · 示例 28 个 · 全部经 gforth 0.7.3 / WSL Debian 实测通过）

---
上一章：[30 · 速查表](30-cheatsheet.md) ｜ 返回：[README](../README.md)
