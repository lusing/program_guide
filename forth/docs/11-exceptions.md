# 11 · 异常处理

对应示例：`../examples/11-exceptions.fs`

`CATCH` / `THROW` 是 ANS 标准，直接用即可。**不要用 `except.fs`**（见 [21 · 坑清单](21-pitfalls.md)）。

```forth
: risky  ( -- )  -5 throw  ." 这行永远执行不到" ;

: catch-demo  ( -- )
  ['] risky catch  ?dup if  ." 捕获到异常，代码 = " .  then ;
```

`CATCH` 吃一个 xt，返回 0 表示正常，非 0 是异常码。标准异常码：

| 码 | 含义 |
|---|---|
| -1 | `ABORT` |
| -2 | `ABORT"`（最常见） |
| -3 | 栈溢出 |
| -4 | 栈下溢 |
| -9 | 无效地址 |
| -11 | 除零（部分系统） |
| 正数 | 留给应用程序自定义 |

自定义异常 + `abort"`：

```forth
-100 constant ERR-EMPTY
: pop-v  ( -- n )
  sp-index 0=  if  ERR-EMPTY throw  then
  ... ;

: divide  ( a b -- q )  dup 0= abort"  除数不能为零"  / ;
```

两点重要行为：

- **`catch` 会把数据栈恢复到进入时的深度**（异常路径上留在栈上的垃圾会被清掉），所以不用担心回调崩掉时把栈弄脏。
- 资源清理的标准姿势是「`catch` 之后无条件释放，再把异常转抛出去」：

```forth
: with-buffer  { u xt -- }
  u allocate throw  { p }
  p xt catch                      \ 执行回调，捕获异常
  p free throw                    \ 无论成功失败都要释放
  throw ;                         \ 把异常继续往外抛
```

断言可以用 `assert( 条件 )`，条件为假就抛异常：

```forth
: checked-div  { a b -- q }
  assert( b 0 <> )
  a b / ;
```

运行：`gforth examples/11-exceptions.fs`

---
上一章：[10 · 堆内存](10-heap-alloc.md) ｜ 下一章：[12 · 结构体](12-structures.md) ｜ 返回：[README](../README.md)
