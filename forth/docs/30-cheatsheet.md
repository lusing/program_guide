# 30 · 速查表

## 栈

| 词 | 栈效应 | 说明 |
|---|---|---|
| `dup` `?dup` `over` `swap` `rot` `-rot` | | 复制 / 交换 / 旋转 |
| `nip` | `( a b -- b )` | 丢次栈顶（**留栈顶**） |
| `drop` `2drop` `2dup` `2swap` `2over` | | 丢弃 / 成对工作 |
| `pick` | `( ... n -- ... x )` | 复制第 n 项（0 = dup） |
| `roll` | | 抽出第 n 项 |
| `depth` `.s` `clearstack` | | 栈深度 / 打印 / 清空 |

自制补充（0.7.3 没有）：`3drop = drop drop drop`、
`3dup = 2 pick 2 pick 2 pick`；反过来 `2nip`、`sign` 是内置的。

## 返回栈

`>r` `( n -- )`、`r>` `( -- n )`、`r@` `( -- n )`、`2>r` `2r@` `2r>` `2rdrop`
—— **只能在冒号定义里用，且必须成对**；DO 循环参数住在里面（`i`/`j`
在偷看）。

## 内存

| 词 | 说明 |
|---|---|
| `!` `@` | 存 / 取一个 cell |
| `c!` `c@` | 存 / 取一个字节 |
| `+!` | 自增（没有 `-!`，用 `-1 +!`） |
| `,` `allot` `create` | 在字典里存 cell / 预留字节 / 建词 |
| `here` `unused` `align` `aligned` | 字典顶端 / 剩余 / 对齐 |
| `cells` `cell+` `chars` `char+` | 宽度换算 |
| `erase` `fill` | 清零 / 按字节填充（`fill ( c-addr u char )`） |
| `move` `cmove` `cmove>` | 块拷贝（重叠区用 `cmove>`） |
| `allocate` `resize` `free` | 堆内存（无 GC，自己管） |
| `s,` | 字符串入字典（**counted string**，配 `count type`） |

## 控制流

```forth
IF ... ELSE ... THEN
CASE  x OF ... ENDOF  y OF ... ENDOF  ( 默认 ) ENDCASE
DO ... LOOP      DO ... n +LOOP      ?DO ... LOOP      LEAVE  UNLOOP
BEGIN ... UNTIL  BEGIN ... WHILE ... REPEAT   BEGIN ... AGAIN
n FOR ... NEXT          \ gforth 扩展：倒数循环
```

## 执行令牌与 defer（21 章）

| 词 | 说明 |
|---|---|
| `'` / `[']` | 顶层 / 冒号内取 xt |
| `execute` / `xt catch` | 调用 / 防连坐调用 |
| `defer` | 声明可换装口子 |
| `xt is 名字` | 解释态换装（名字来自输入流） |
| `defer@` / `defer!` / `action-of` | 读 / 写 / 读当前指向 |
| `>name` `name>string` | xt→nt→名字 |
| `>body` `body>` `latestxt` | xt↔PFA、最新词 |

## 输入流解析（22 章）

| 词 | 说明 |
|---|---|
| `source` `>in` | 输入源 / 游标 |
| `parse-name` | 按空白切 token（**驱动词+evaluate 模式用**） |
| `[char] , parse` | 按字符切 |
| `word` | 老 counted 版（pad 陷阱，别用） |
| `>number` | 字符串转双精度（部分值也返回） |
| `evaluate` | 字符串即代码 |
| `refill` | 取下一行 |

## 块（23 章，`require blocks.fs`）

`open-blocks / block / buffer / update / save-buffers / flush /
n list / n load / thru / scr`

## 多任务（26 章，`require tasker.fs`）

`NewTask / activate（冒号内！）/ pause / kill / sleep / wake / pass /
single-tasking? / user`

## 常用工具词

| 词 | 说明 |
|---|---|
| `." xxx"` | 打印字符串（**只能用在冒号定义内部**） |
| `.( xxx)` | 立即打印（**只能用在定义外 / 顶层**） |
| `cr` `space` `spaces` `emit` `type` | 输出 |
| `key` `accept` | 读一个键 / 读一行 |
| `include` `require` `required` | 加载文件（`require` 会去重） |
| `bye` | 退出（**每个脚本末尾都要写**） |
| `utime` | 当前微秒（双精度） |
| `words` `see 词` | 列出词 / 反编译一个词（**只能顶层用**） |
| `marker 名字` | 词典快照，执行名字即回滚 |
| `warnings off/on` | 包夹 require，压 redefined 噪音 |

---
上一章：[29 · Forth 简史与文献导读](29-history.md) ｜ 下一章：[31 · gforth 0.7.3 坑清单](31-pitfalls.md) ｜ 返回：[README](../README.md)
