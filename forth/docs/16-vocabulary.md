# 16 · 词典、词表与搜索顺序

对应示例：`../examples/16-vocabulary.fs`

Forth 的「词典」不是书，是**一串哈希表（wordlist）**。理解它就能做模块封装、命令分发器和自己的 DSL。

每个词有两个「把手」：

- **nt**（name token）—— 名字那一半，能拿字符串；
- **xt**（execution token）—— 代码那一半，能 `execute` / `compile,`。

```forth
' 名字          -> xt      （顶层取 xt；冒号定义里要写 ['] ）
find-name       -> nt
>name           xt -> nt
name>string     nt -> addr u
```

> ⚠ `find-name` 返回 **nt**，`search-wordlist` 返回 **xt**（旧语义）。用 `search-wordlist` 的结果打名字要先 `>name`。

搜索顺序就是 Forth 的「作用域」：

```forth
order        \ 打印当前搜索顺序
get-order    \ ( -- wid1..widn n ) 取出来
set-order    \ ( wid1..widn n -- ) 放回去
also   only   previous
>order       \ ( wid -- ) 把词表塞进搜索顺序最前面
definitions  \ 后续定义的词放进搜索顺序最前面的词表
```

命名空间：

```forth
vocabulary 数学工具
数学工具 definitions
  : 平方  ( n -- n )  dup * ;
forth definitions
```

`marker 名字` 建立词典快照，之后执行 `名字` 就回滚到建快照时的状态——调试和 REPL 里非常好用。

> ⚠ 编译期和运行期是两码事：用 `find-name` 在**运行期**查词，调用前 `also` 是有效的；但如果一个冒号定义的**代码里**直接写了某个词表里的词，编译时搜索顺序里就必须已经有它，运行时再 `also` 也没用。

运行：`gforth examples/16-vocabulary.fs`

---
上一章：[15 · 面向对象](15-oop.md) ｜ 下一章：[17 · 元编程](17-metaprogramming.md) ｜ 返回：[README](../README.md)
