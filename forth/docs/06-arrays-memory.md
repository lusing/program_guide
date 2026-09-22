# 06 · 数组与内存

对应示例：`../examples/06-arrays-memory.fs`

Forth 没有数组类型：数组 = 一块连续内存 + 你自己算地址。

```forth
create vec  10 cells allot
: vec[]  ( i -- addr )  cells vec + ;
: fill-vec  ( -- )  10 0 do  i i *  i vec[] !  loop ;
```

带越界检查：

```forth
: vec[]!  ( n i -- )
  dup 0 10 within 0= abort" 下标越界"
  vec[] ! ;
```

二维数组（行优先）：

```forth
: mat[]  ( row col -- addr )  swap MCOLS * +  cells mat + ;
```

批量操作：`erase`（清零）、`fill`（**按字节**填充）、`move`、`cmove` / `cmove>`（重叠区用 `cmove>`）。

对齐：写 `1 cells` / `1 chars` 而不是写死 8 / 1，代码才与 cell 宽度无关。

运行：`gforth examples/06-arrays-memory.fs`

---
上一章：[05 · 字符串](05-strings.md) ｜ 下一章：[07 · 递归](07-recursion.md) ｜ 返回：[README](../README.md)
