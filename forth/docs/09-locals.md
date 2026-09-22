# 09 · 局部变量

对应示例：`../examples/09-locals.fs`

Forth 正统风格是「栈传递 + 短定义」，但复杂算术用局部变量更好读。

两种语法，**参数顺序正好相反**：

```forth
: t1  { a b -- }    ... ;   \ a 是栈里较深的那个（次栈顶）
: t2  locals| a b |  ... ;  \ a 是栈顶
```

对比一下可读性：

```forth
: diff-of-squares-stack  ( a b -- n )  2dup -  -rot +  * ;
: diff-of-squares        { a b -- n }  a b +  a b -  * ;
```

类型前缀：`{ f: x  d: y }` 分别取浮点栈、双精度值。

> ⚠ 局部变量**不是变量**，只是有名字的栈槽，**不能用 `TO` 赋值**。要当累加器，用 `value` 配 `to`，或把中间值留在栈上。
> ⚠ `{ a b | c }` 这种带 `|` 的写法在 0.7.3 上会 Address alignment exception。

运行：`gforth examples/09-locals.fs`

---
上一章：[08 · CREATE ... DOES>](08-create-does.md) ｜ 下一章：[10 · 堆内存](10-heap-alloc.md) ｜ 返回：[README](../README.md)
