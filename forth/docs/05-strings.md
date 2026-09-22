# 05 · 字符串

对应示例：`../examples/05-strings.fs`

Forth 的字符串 = **首地址 + 长度** 两个值，没有 `\0` 结尾。

三种字面量：

| 写法 | 结果 | 说明 |
|---|---|---|
| `s" abc"` | `( addr u )` | 最常用 |
| `c" abc"` | `( addr )` | counted string，**首字节是长度**，要用 `count` 展开 |
| `s\" a\tb\n"` | `( addr u )` | 支持转义 |

常用词：`compare`（返回 0/正/负）、`search`、`scan`、`skip`、`/string`、`>number`。

```forth
: $=  ( a1 u1 a2 u2 -- f )  compare 0= ;

: cut-demo  ( -- )
  s" hello world" 6 /string type        \ "world"
  s" hello world" s" world" search
     if  ." 找到：[" type ." ]"  then
  s"    abc" bl skip type ;             \ ⚠ 是 bl，不是 [char] bl
```

拼接要自己管缓冲区（没有 GC，也没有自动增长的字符串）：

```forth
: $copy  { src u dest }  src dest u cmove  dest u ;
```

> ⚠ `s" 中文词 "` 的**尾随空格会被当成名字的一部分**，用于 `find-name` 时一定查不到。

运行：`gforth examples/05-strings.fs`

---
上一章：[04 · 分支与循环](04-control-flow.md) ｜ 下一章：[06 · 数组与内存](06-arrays-memory.md) ｜ 返回：[README](../README.md)
