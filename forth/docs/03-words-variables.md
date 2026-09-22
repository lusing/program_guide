# 03 · 词、常量与变量

对应示例：`../examples/03-words-variables.fs`

冒号定义是 Forth 里唯一的「函数」：

```forth
: square  ( n -- n² )  dup * ;
```

四种「变量」，用途各不相同：

| 工具 | 读取 | 写入 | 说明 |
|---|---|---|---|
| `constant` | 名字即压值 | 不可 | 常量 |
| `variable` | `x @` | `5 x !` / `3 x +!` | 把**地址**留在栈上 |
| `value` | 名字即压值 | `5 to x` | 读起来最干净 |
| `create ... , / allot` | 手工算地址 | 手工 | 造数据结构 |

```forth
1024 constant KB
variable score
7 score !  3 score +!  -1 score +!  \ ⚠ 没有 -!，自减就是加负数
100 value speed
120 to speed
speed 5 + to speed                  \ ⚠ 0.7.3 没有 +TO
```

推荐做法：**用封装把裸变量藏起来**，只在词里访问：

```forth
variable counter
: reset  ( -- )  0 counter ! ;
: tick   ( -- )  1 counter +! ;
```

## DEFER / IS：运行期可换绑的函数指针

```forth
defer greet
: greet-cn  ( -- )  ." 你好！" cr ;
' greet-cn is greet
greet
```

这是 Forth 版的**策略模式**，也用于前向引用（见 [07 · 递归](07-recursion.md) 的相互递归）。

## 编译期常量

```forth
: .1mb  ( -- )
  [ 1024 1024 * ] literal      \ 编译期算好，运行期零开销
  ." 1MB = " . cr ;
```

运行：`gforth examples/03-words-variables.fs`

---
上一章：[02 · 算术与数字](02-arithmetic.md) ｜ 下一章：[04 · 分支与循环](04-control-flow.md) ｜ 返回：[README](../README.md)
