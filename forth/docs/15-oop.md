# 15 · 面向对象

对应示例：`../examples/15-oop.fs`

Forth 不是 OO 语言，但它给你造轮子的一切零件。示例演示三个层次：

## 1) 手工方法表（就是 C++ 的虚表）

```
对象:  [ vtable | 字段1 | 字段2 | ... ]
              |
              v
vtable: [ 方法0 xt | 方法1 xt | ... ]
```

```forth
: invoke  ( o method# -- )
  cells  over @ +  @  execute ;      \ ⚠ 是 over @（取 vtable），不是 dup @
```

同一个方法号、不同的 vtable，就是多态。

## 2) `mini-oof.fs`（gforth 自带，约 60 行）

核心只有 5 个词，是本机能用的 OO 方案（`point3` 继承 `point`）：

```forth
require mini-oof.fs
object class
  cell% var px          \ 实例变量
  method init           \ 虚方法
  method show
end-class point
```

> ⚠ `method` 的签名里**没有 this**：调用时对象地址在栈顶（最右边），所以 locals 要写 `{ w h this -- }` 而不是 `{ this w h -- }`。
> ⚠ `new` 出来的对象在**字典**里（`here ... allot`），**不能 free**，也没有 dispose。
> ⚠ mini-oof **不会初始化字段**，字段里是什么全看那块内存上一位住户留下什么，一定要自己写 `init` 并记得调用。

> ❌ **不要用 `objects.fs`**：在这台机器的 0.7.3 上它一定义类就 Address alignment exception（`end-class` 里的 `2!` 崩）。要用完整的 OO 系统请升级 gforth。

## 3) 鸭子类型 / 「接口」

约定好一组方法号，任何实现了这些方法号的对象都能被同一段代码消费——不需要类型声明。

> ⚠ `counter-new constant c1` 必须写在顶层：`constant` 是编译期造词工具，放进冒号定义体里就是 Undefined word。对象要么在顶层造好，要么用 `value` / 变量持有。

运行：`gforth examples/15-oop.fs`

---
上一章：[14 · 文件读写](14-file-io.md) ｜ 下一章：[16 · 词典、词表与搜索顺序](16-vocabulary.md) ｜ 返回：[README](../README.md)
