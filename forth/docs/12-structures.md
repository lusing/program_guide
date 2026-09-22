# 12 · 结构体

对应示例：`../examples/12-structures.fs`

`struct.fs` 在 gforth 里是**内置**的，不要再 `require`（会刷一屏 redefined 警告）。

```forth
struct
  cell% field pt-x
  cell% field pt-y
end-struct point%
```

> ⚠ **执行 `point%` 会压两个值**：对齐值和总大小。取大小写 `point% %size`，取对齐写 `point% %alignment`；`%allot` / `%alloc` 正好吃这两个值。

两种分配方式：

```forth
point% %allot constant p1      \ 字典里，程序整个生命周期都在，不用释放
point% %alloc constant p2      \ 堆上，用完 free
```

支持嵌套（`point% field rect-tl`）和结构体数组（用 `%size` 算步长）。

> ⚠ `constant` 是编译期造词工具，**不能写在冒号定义里面**，结构体实例要在外面声明。

运行：`gforth examples/12-structures.fs`

---
上一章：[11 · 异常处理](11-exceptions.md) ｜ 下一章：[13 · 浮点数](13-floats.md) ｜ 返回：[README](../README.md)
