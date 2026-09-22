# 13 · 浮点数

对应示例：`../examples/13-floats.fs`

浮点全在**浮点栈**上进行，写法和整数那套完全不同。

字面量必须带 `e + 指数`：

```forth
3.5e0      1.0e-3     6.022e23
```

> ⚠ 没有 `f" ..."`；`1.0e` / `2.5e` 无效（e 后必须有指数）；
> ⚠ 光写 `3.14`（不带 e）会被当成**双精度整数**，不是浮点。

运算：`f+ f- f* f/ fnegate fabs fmin fmax fsqrt fexp fln flog f** fsin fcos ftan fatan2`，`f2*` / `f2/` 比乘除 2 快。

栈操作：`fdup fdrop fswap fover frot fnip ftuck`（必须带 `f`）。

比较与判等：

```forth
: f≈  ( f: a b -- )  ( -- flag )   f- fabs  1.0e-9 f< ;
```

> ⚠ `f=` 是**精确比较**，对算出来的值几乎永远假。
> ⚠ 别用 `f~` 做绝对误差判等：0.7.3 上 `0.0e0 0.0e0 -1.0e-9 f~` 返回 **false**（0 和 0 都不相等），它的实际行为更接近相对误差。

示例还实现了牛顿法开方和数值积分（梯形法），演示「浮点栈不好写收敛判断，改用 `fvariable` 存当前值」。

> ⚠ `fvalue` / `fto` 在 0.7.3 不存在；`fvariable` 的初值**（永远）**是 0，`1.5e0 fvariable v` 里的 `1.5e0` 会被丢掉。

运行：`gforth examples/13-floats.fs`

---
上一章：[12 · 结构体](12-structures.md) ｜ 下一章：[14 · 文件读写](14-file-io.md) ｜ 返回：[README](../README.md)
