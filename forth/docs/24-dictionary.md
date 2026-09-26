# 24 · 词典内部解剖

对应示例：`../examples/24-dictionary.fs`

素材：《IBM-PC FORTH 语言》下篇第五章（六种定义的字典格式）、
《Programming Forth》第 16 章 Forth Internals。

## 词条四区

《IBM-PC FORTH》下篇第五章逐类讲了冒号 / CODE / CONSTANT / VARIABLE /
USER / VOCABULARY 六种词条格式——机器不同布局不同，但共性是四区：

```text
[ 名字区 ][ 链接场 ][ 代码指针 CFA ][ 参数区 PFA ]
```

链接场把所有词条串成链——「词典 dictionary」的由来；CFA 指向这类词的
执行行为；PFA 放数据（常数、变量地址、编译出来的 xts）。

## 两套句柄：nt 与 xt

| 句柄 | 管什么 | 换算词 |
|---|---|---|
| nt（名字令牌） | 名字 | `>name`（xt→nt）、`nt name>string` |
| xt（执行令牌） | 执行 | `'`（顶层）、`[']`（词内）、`execute` |
| PFA | 参数区 | `>body`（xt→PFA）、`body>`（反查） |

示例实测了五种定义的 PFA：CONSTANT 的 PFA 里就存着那个值，CREATE 的
PFA 里是你 `,` 进去的数据——「四区」里 PFA 的意义看得见摸得着。

## see：词典自己会交代

`see 词名` 反编译——冒号定义显示词序，CONSTANT 显示值，DOES> 词显示
数据与行为。⚠ `see` 和 `find-name` 都是**解析词**（词名来自输入流），
只能顶层紧跟词名用，包进冒号定义会抓走定义体里的下一个 token。

## 查词典

⚠ 本机 Debian gforth 0.7.3 双坑（详见坑清单）：

- **`find-name` 一用就 Stack underflow**（在 `(vocfind)` 里炸，交互态同
  样）——这个构建里它坏了；
- `search-wordlist` 顶层裸调会 Invalid memory address——**包进冒号定义
  里用就稳**：

```forth
: exists?  ( caddr u -- flag )
  get-current search-wordlist   \ ( xt 1 | 0 )
  if  drop true  else  false then ;
```

还有一条：**千万别 `require look.fs`**——`>name`/`see` 已在镜像里，
现场再 require 会在 glocals/search 链上炸出 Undefined word。

## 字典指针

`here / allot / , / c, / align / aligned / unused`——手工长词典的全套。
char 数据后要自己 `align` 到 cell 边界。`latestxt` 给出「刚造出来的词」，
配合 `>body` 就能在造词瞬间报告它的住址。

## 线程模型导游（纯理论）

词表里存什么、怎么跳过去——历代 Forth 的分野（Pelc 第 16 章）：

| 模型 | 一句话 |
|---|---|
| ITC 间接线程 | CFA 指向「跳下一单元」的小例程；FORTH-79/83 标配 |
| DTC 直接线程 | CFA 里直接放机器跳转；快一跳 |
| STC 子程序线程 | 编译成真 CALL 序列；返回栈就是 CPU 的 |
| TTC 令牌线程 | 存压缩令牌号，省内存要查表 |
| NCC 原生码 | 全机器码；gforth 0.7.x 用「超级指令」折衷 |

`see` 看到的词名序列，就是线程码的「源码视图」。

运行：`gforth examples/24-dictionary.fs`

---
上一章：[23 · 块与屏幕](23-blocks.md) ｜ 下一章：[25 · 外层解释器](25-outer-interp.md) ｜ 返回：[README](../README.md)
