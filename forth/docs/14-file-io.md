# 14 · 文件读写

对应示例：`../examples/14-file-io.fs`

gforth 的文件操作是「句柄 + ior」风格，每个操作返回 ior，习惯上直接 `throw`。

打开模式：`r/o`（只读，文件须存在）、`w/o`（只写，创建或清空）、`r/w`（读写，须存在）。

```forth
: write-demo  ( -- )
  NOTE-FILE w/o create-file throw fh !
  s" 第一行" fh @ write-line throw
  fh @ close-file throw ;
```

逐行读取有三个坑，一次说清：

```forth
begin
  pad 256 fh @ read-line throw       \ ( 计数 长度 flag )
while
  cr ."   " pad swap type            \ ⚠ 缓冲区地址不会还给你，要自己写 pad
  1+
repeat
```

- `read-line` 的签名是 `( 缓冲区 最大长度 文件id -- 长度 flag ior )`，**不会**把地址还给你；
- `flag` 为假表示到文件尾，此时长度是 0；
- 行尾换行符**不**包含在长度里，`type` 之后要自己 `cr`。

其他：`slurp-file` 一次读进内存、`file-size`、`rename-file`、`delete-file`、二进制读写（`read-file` / `write-file` 按字节）。示例最后实现了一个能用的 `wc`（行数 / 词数 / 字节数）。

> ⚠ `open-file` 失败时**也会**返回一个 fid（虽然没用），两个分支都要 drop，否则栈上悄悄多一个垃圾值。

运行：`gforth examples/14-file-io.fs`

---
上一章：[13 · 浮点数](13-floats.md) ｜ 下一章：[15 · 面向对象](15-oop.md) ｜ 返回：[README](../README.md)
