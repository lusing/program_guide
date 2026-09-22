# 10 · 堆内存

对应示例：`../examples/10-heap-alloc.fs`

字典空间（`create` / `allot`）在**编译期定死**；运行时变长的数据要去堆上，自己管理生命周期。

```forth
100 cells allocate throw   { p }     \ throw 把 ior 变成异常
50 p !
p 200 cells resize throw  to p       \ 扩容，地址可能变
p free throw
```

`allocate` / `resize` / `free` 都返回 `ior`（0 成功）。**不要丢掉它**：忘记 `throw` 的话 ior 会堆在栈上，越攒越多，而且这是最难查的一类 bug。

示例里实现了一个可增长的 vector（`vec-init` / `vec-push` / `vec-free`，容量满时翻倍）和一个堆上的链表（节点布局 `[next][val]`，用 `cons` / `push-front` 构造）。

运行：`gforth examples/10-heap-alloc.fs`

---
上一章：[09 · 局部变量](09-locals.md) ｜ 下一章：[11 · 异常处理](11-exceptions.md) ｜ 返回：[README](../README.md)
