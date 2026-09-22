# 20 · 速查表

## 栈

| 词 | 栈效应 | 说明 |
|---|---|---|
| `dup` `?dup` `over` `swap` `rot` `-rot` | | 复制 / 交换 / 旋转 |
| `nip` | `( a b -- b )` | 丢次栈顶（**留栈顶**） |
| `drop` `2drop` `2dup` `2swap` `2over` | | 丢弃 / 成对工作 |
| `pick` | `( ... n -- ... x )` | 复制第 n 项（0 = dup） |
| `roll` | | 抽出第 n 项 |
| `depth` `.s` `clearstack` | | 栈深度 / 打印 / 清空 |

## 返回栈

`>r` `( n -- )`、`r>` `( -- n )`、`r@` `( -- n )`、`2>r` `2r>` —— **只能在冒号定义里用，且必须成对**。

## 内存

| 词 | 说明 |
|---|---|
| `!` `@` | 存 / 取一个 cell |
| `c!` `c@` | 存 / 取一个字节 |
| `+!` | 自增（没有 `-!`，用 `-1 +!`） |
| `,` `allot` `create` | 在字典里存 cell / 预留字节 / 建词 |
| `here` | 字典下一个空闲地址 |
| `cells` `cell+` `chars` `char+` | 宽度换算 |
| `erase` `fill` | 清零 / 按字节填充 |
| `move` `cmove` `cmove>` | 块拷贝（重叠区用 `cmove>`） |
| `allocate` `resize` `free` | 堆内存（无 GC，自己管） |

## 控制流

```forth
IF ... ELSE ... THEN
CASE  x OF ... ENDOF  y OF ... ENDOF  ( 默认 ) ENDCASE
DO ... LOOP      DO ... n +LOOP      ?DO ... LOOP      LEAVE  UNLOOP
BEGIN ... UNTIL  BEGIN ... WHILE ... REPEAT   BEGIN ... AGAIN
```

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
| `words` `see 词` | 列出词 / 反编译一个词 |
| `marker 名字` | 词典快照，执行名字即回滚 |

---
上一章：[19 · 测试与基准](19-testing.md) ｜ 下一章：[21 · gforth 0.7.3 坑清单](21-pitfalls.md) ｜ 返回：[README](../README.md)
