# 07 · 递归

对应示例：`../examples/07-recursion.fs`

Forth 的词**默认不可自引用**，必须显式 `recursive`（或 `recurse` 前声明）：

```forth
: fact  recursive  ( n -- n! )
  dup 1 >  if  dup 1- recurse *  else  drop 1  then ;
```

备忘化（把算过的结果存表里）能把指数级变线性：

```forth
: fib-m  recursive  ( n -- f )
  dup 2 <         if  exit  then
  dup cells memo + @ ?dup  if  nip exit  then
  dup >r
  dup  1- recurse
  r@   2 - recurse
  +
  dup  r> cells memo + !  nip ;
```

**相互递归**用 `defer` 打桩：先用 `defer` 声明后定义的那个词，全部定义完再 `is` 绑定。

计时用 `utime`（返回双精度微秒）：

```forth
utime  28 fib  drop  utime  2swap d-
```

> ⚠ `utime` 是双精度，只取低 32 位相减会翻车。

运行：`gforth examples/07-recursion.fs`

---
上一章：[06 · 数组与内存](06-arrays-memory.md) ｜ 下一章：[08 · CREATE ... DOES>](08-create-does.md) ｜ 返回：[README](../README.md)
