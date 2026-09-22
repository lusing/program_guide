# 17 · 元编程

对应示例：`../examples/17-metaprogramming.fs`

Forth 的编译期就是运行时——你能在「编译」的时候跑任意代码，算出该生成什么。

关键工具：

| 词 | 作用 |
|---|---|
| `state` | 0 = 解释态，非 0 = 编译态 |
| `[` `]` | 切到解释态 / 切回编译态 |
| `literal` | 编译「把这个数压栈」的指令 |
| `postpone` | 把某个词的**编译行为**编进当前定义 |
| `compile,` | 直接把某个 xt 编进当前定义 |
| `immediate` | 让刚定义的词在编译态下**立刻执行** |

编译期计算，运行时零开销：

```forth
: state-demo  ( -- )
  cr ." 编译期算出来的 2^16        = " [ 2 16 lshift ] literal .
  cr ." 编译期算出来的 斐波那契(20) = " [ 20 斐波那契 ] literal . ;
```

自己造控制结构：

```forth
: unless  ( -- )  postpone 0=  postpone if ;  immediate

: test-unless  ( n -- )
  unless  ." 是假的"  else  ." 是真的"  then ;
```

> ⚠ **`immediate` 词体里绝对不能碰返回栈**：那一刻返回栈上正放着解释器自己的状态，`do/loop/?do/recurse/>r/r>` 一用就崩（`do/loop` → Dictionary overflow，`?do`/`begin while` → unstructured，`recurse` → Invalid memory address）。
> ⚠ `immediate` 词**不能嵌套调用**另一个 `immediate` 词，展开会丢，老老实实把 `postpone` 全写开。
> ⚠ `[ ... ]` 内部是解释态，结构化语句不能用；顶层的 `[ ... ]` 会把状态切到编译态，后面的代码全被当编译指令。

示例最后写了一个迷你状态机 DSL 和条件编译（`[defined]` / `[undefined]`）。

运行：`gforth examples/17-metaprogramming.fs`

---
上一章：[16 · 词典、词表与搜索顺序](16-vocabulary.md) ｜ 下一章：[18 · 生成器与惰性序列](18-generators.md) ｜ 返回：[README](../README.md)
