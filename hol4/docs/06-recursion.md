# 06 · 递归定义与终止性

> 对应示例：[`examples/06_recursion/06_recursion.sml`](../examples/06_recursion/06_recursion.sml)

HOL4 里没有"随便写的递归"：每个定义都必须通过**终止性检查**，否则 TFL
（Total Function Library）会拒绝。本章从结构递归一直走到"必须手写良基关系"
的例子，并演示自带的归纳定理怎么用。

> 为什么要查终止性？因为 HOL 的逻辑里没有"不终止的函数"这个位置 ——
> 一个不终止的递归会让你从 `fib n = fib n + 1` 推出 `0 = 1`，整个逻辑崩掉。

## 06.1 结构递归

递归只在参数的直接子结构上发生时，TFL 自己就能证明终止，不用你说话：

```text
⊢ mylen [] = 0 ∧ ∀x xs. mylen (x::xs) = 1 + mylen xs
求值：mylen [1; 2; 3] = 3
```

```sml
Definition mylen_def:
  (mylen [] = 0) /\
  (mylen (x :: xs) = 1 + mylen xs)
End
```

`Definition` 和 `Datatype` 相反：它**既**登记定理（`mylen_def`），
**又**给出 ML 绑定（同名的 `mylen_def`）。

## 06.2 结构递归换不来额外的归纳定理

```text
mylen_ind = ⊢ T
它是平凡的：每步递归都是结构下降，没有可证的归纳义务；
要归纳时用 listTheory 给类型准备的 list_induction 即可。
```

```sml
val _ = out ("mylen_ind = " ^ thm_to_string mylen_ind)
```

这是个反直觉的点：结构递归**也会**生成一个 `_ind` 定理，但它是 `⊢ T` ——
因为每一步递归都是结构下降，没有"额外的归纳义务"需要包装。
要归纳时直接用类型自带的 `list_induction` / `num_induction`。

真正有价值的 `_ind` 出现在良基递归里（下一节）。

## 06.3 良基递归：欧几里得最大公约数

`mygcd b (a MOD b)` 的第二个参数不一定是 `b` 的结构子项，TFL 证不动，
得自己交一个良基关系：

```text
<<HOL warning: Context.snapshot: ambient context read while a proof was running (in Tut06)>>
⊢ ∀b a. mygcd a b = if b = 0 then a else mygcd b (a MOD b)
求值：mygcd 12 8 = 4
再求值：mygcd 1071 462 = 21
这次 _ind 不平凡：⊢ ∀P. (∀a b. (b ≠ 0 ⇒ P b (a MOD b)) ⇒ P a b) ⇒ ∀v v1. P v v1
```

```sml
Definition mygcd_def:
  mygcd a b = if b = 0 then a else mygcd b (a MOD b)
Termination
  WF_REL_TAC `measure (\(a, b). b)` >> rw []
End
```

`Termination` 块里 `WF_REL_TAC \`measure …\`` 声明"每次递归，这个量在
良基关系 `<` 下严格变小"；剩下的是证明义务，交给 `rw []`。

这次的 `mygcd_ind` 不平凡了 —— 它就是"对这个递归做归纳"的正确原理。

> 那行 `<<HOL warning: Context.snapshot: …>>` 是 TFL 的终止性证明器
> 读取上下文时打出来的一次性提示。它每个 `Termination` 块出现一次，
> 两条入口都一样，**留在比对区间里是安全的**。

## 06.4 多重递归

斐波那契有两种写法，只有一种能算：

```text
⊢ fib 0 = 0 ∧ fib (SUC 0) = 1 ∧ ∀n. fib (SUC (SUC n)) = fib (SUC n) + fib n
EVAL ``fib 10``        = fib 10 = fib 10
  ↑ 原地踏步：算不动，只给出 fib 10 = fib 10。
EVAL ``fib (SUC (SUC 0))`` = fib (SUC (SUC 0)) = fib 2
  ↑ 把参数写成 SUC 链，求值器先把 SUC (SUC 0) 折成 2，然后就卡住了。
⊢ ∀n. fib2 n =
      if n = 0 then 0 else if n = 1 then 1 else fib2 (n − 1) + fib2 (n − 2)
EVAL ``fib2 10``       = fib2 10 = 55
  ↑ 这次算得动：模式是 n = 0 / n = 1，numeral 能直接判定。
```

```sml
(* 写法一：SUC 模式 —— 定义能过，但算不动 *)
Definition fib_def:
  (fib 0 = 0) /\
  (fib (SUC 0) = 1) /\
  (fib (SUC (SUC n)) = fib (SUC n) + fib n)
End

(* 写法二：数值模式 + 显式良基关系 —— 能算 *)
Definition fib2_def:
  fib2 n = if n = 0 then 0 else if n = 1 then 1 else fib2 (n - 1) + fib2 (n - 2)
Termination
  WF_REL_TAC `measure I` >> rw [] >> DECIDE_TAC
End
```

> **这是本章最值钱的一课。** HOL4 的十进制字面量是**二进制 numeral**
> （`numeralTheory` 里的 `NUMERAL (BIT1 …)`），不是 `SUC` 链。
> 单层 `SUC n` 的模式求值器还能对上（它内置了 numeral ↔ SUC 的折叠），
> 但 `SUC (SUC n)` 这种**嵌套**模式匹配不上，于是 `EVAL` 原地踏步。
> 想让递归函数能被求值，就把模式写成 `n = 0` / `n = 1` 这种判定式。

## 06.5 互递归定义

```text
⊢ (evenp 0 ⇔ T) ∧ (∀n. evenp (SUC n) ⇔ oddp n) ∧ (oddp 0 ⇔ F) ∧
  ∀n. oddp (SUC n) ⇔ evenp n
evenp 6 = evenp 6 ⇔ T
oddp 6  = oddp 6 ⇔ F
```

```sml
Definition evenp_def:
  (evenp 0 = T) /\
  (evenp (SUC n) = oddp n) /\
  (oddp 0 = F) /\
  (oddp (SUC n) = evenp n)
End
```

一个 `Definition` 块可以同时定义多个互递归的函数。
`evenp 6 ⇔ T` 是"求值为真"的打印形式 —— 对 bool 值，`EVAL` 给出的是
`⊢ t ⇔ T`，不是 `⊢ t = T`。

## 06.6 用 _ind 定理做归纳

```text
⊢ ∀l. mylen l = LENGTH l
⊢ ∀n. (evenp n ⇔ T) ∨ (evenp n ⇔ F)
```

```sml
val _ = out (thm_to_string
               (prove(``!l : num list. mylen l = LENGTH l``,
                      Induct_on `l` >> simp [mylen_def])))
```

第一条用 `list_induction`（`Induct_on` 自动挑），第二条用 `num_induction`。
两个证明都只有"归纳 + 展开定义"两步 —— 这是 07 章的主线。

## 06.7 定义必须全覆盖且无重叠

```text
⊢ mylen [] = 0 ∧ ∀x xs. mylen (x::xs) = 1 + mylen xs
等式 LHS 覆盖了 [] 与 ::，互不重叠 —— TFL 才生成 _eqn 定理。
```

TFL 要求：所有等式的左边**覆盖所有情况**且**互不重叠**。
有重叠（比如同时写了 `f (SUC n) = …` 和 `f n = …`）会被直接拒绝。

## 06.8 坑位清单

1. **字面量是二进制 numeral，不是 SUC 链** → `SUC (SUC n)` 模式的定义 `EVAL` 算不动；改用 `n = 0` / `n = 1` 判定式。
2. **`EVAL` 对 bool 值返回 `t ⇔ T`** → 不是 `t = T`；比对输出时别写错。
3. **结构递归的 `_ind` 是 `⊢ T`** → 别指望它；用类型自带的 `list_induction` / `num_induction`。
4. **非结构递归必须写 `Termination`** → 否则 TFL 报 "unable to prove termination"。
5. **`WF_REL_TAC \`measure …\`` 里的 `\` 在 SML 字符串里要写成 `\\`** → 否则是转义符。
6. **`measure I` 表示"用参数本身当度量"** → 它要求参数类型是能比较大小的（如 `num`）。
7. **`Termination` 块会打一条 `Context.snapshot` 警告** → 一次性、两条入口一致，不影响比对。
8. **互递归要写在一个 `Definition` 块里** → 分成两块会互相找不到。
9. **等式的 LHS 必须覆盖且无重叠** → 有重叠 TFL 直接拒绝，不给 `_eqn`。
10. **`Definition` 给 ML 绑定，`Datatype` 不给** → 别把两者的取用方式搞混。

---

上一章：[05 · 数据类型](05-datatype.md) ·
下一章：[07 · 归纳证明](07-induction.md)
