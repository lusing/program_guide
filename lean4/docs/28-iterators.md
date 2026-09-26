# 28 · 迭代器

**对标**: *Reference* 第22章（Iterators）。

`Std.Iter` 是惰性迭代器，`for ... in` 直接消费它；组合子链 `.map .filter` 只在
被消费时逐元素求值，比 `List.map . List.filter`（各自物化整个中间列表）省内存：

```lean
def itSum (l : List Nat) : Nat := Id.run do
  let mut s := 0
  for x in l.iter do
    s := s + x
  return s
#eval itSum (List.range 100)   -- 4950

#eval (List.range 10).iter.map (· * 2) |>.toList      -- [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]
#eval (List.range 10).iter.filter (· % 3 == 0) |>.toList   -- [0, 3, 6, 9]
#eval (List.range 5).iter.length   -- 5
#eval (List.range 5).iter.toArray  -- #[0, 1, 2, 3, 4]
```

> **版本陷阱**：4.33 及更早版本的底层 API `Std.Iter.next`/`.curr`/`.atEnd` 已移除，
> 旧代码改用 `for` 或组合子（`.map`/`.filter`/`.fold`/`.take`/`.drop`/`.toList`/`.toArray`）。

---

> 上一章：[27 · 强制转换、记法与宏](27-coe-notation-macros.md) ｜ 下一章：[29 · 性能、编译与程序验证](29-performance-verification.md) ｜ 返回：[README](../README.md)
