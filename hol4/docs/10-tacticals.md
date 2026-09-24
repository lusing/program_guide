# 10 · 战术算子

> 对应示例：[`examples/10_tacticals/10_tacticals.sml`](../examples/10_tacticals/10_tacticals.sml)

单个战术只能解决一步；真正的证明脚本是**"战术 + 算子"的表达式**。
本章把六个算子逐个放在同一个目标上，用残余目标对比它们干了什么。

## 10.1 THEN：顺序作用到所有子目标

```text
conj_tac           : T  ‖  b
conj_tac THEN simp : b
conj_tac >> simp   : b
simp 单独          : b
```

```sml
val _ = show "conj_tac THEN simp" (conj_tac THEN simp []) t1
val _ = show "conj_tac >> simp  " (conj_tac >> simp []) t1
```

`THEN` 把右边作用在左边产生的**所有**子目标上。`>>` 是它的"gentactic"
版本（两边都可以是 `tactic` 或 `list_tactic`，自动插入 `ALLGOALS`）。

看结果：`conj_tac` 留下 `T ‖ b`，`THEN simp` 之后只剩 `b` ——
`T` 被 `simp` 消掉了，`b` 消不掉。第三行和第四行给出同样的结果，
因为 `simp []` 单独作用在 `T ∧ b` 上也是这个效果。

> 日常写脚本用 `>>`：它更短，也更能容忍"左边产生了几个子目标"。

## 10.2 THENL：按位置发不同的战术

```text
THENL [simp,all]   : c ⇔ c
THENL [all,simp]   : T
THENL 数量不对     : <tactic failed>
```

```sml
val _ = show "THENL [simp,all]  " (conj_tac THENL [simp [], all_tac]) t2
val _ = show "THENL 数量不对    " (conj_tac THENL [all_tac]) t2
```

`THENL` 的列表长度必须**恰好**等于子目标数，多一个少一个都直接失败。
两个子目标分别是 `T` 和 `c = c`：给第一个 `simp`、第二个 `all_tac`，
剩下的是 `c ⇔ c`；反过来就只剩 `T`。

## 10.3 `>-` 只管第一个子目标

```text
conj_tac >- simp   : c ⇔ c
(>- 后再 >>)       : c ⇔ c
```

```sml
val _ = show "conj_tac >- simp  " (conj_tac >- simp []) t2
```

`>-` 把**第一个**子目标单独提出来管，剩下的原样留在列表里。
它比 `THENL` 好在不用数子目标个数 —— 子目标数变了脚本也不会立刻坏。

## 10.4 ORELSE

```text
disj1_tac          : a
conj_tac || disj   : a
conj_tac || and    : a  ‖  b
```

```sml
val _ = show "conj_tac || disj  " (conj_tac ORELSE disj1_tac) ``(a : bool) \/ b``
```

`ORELSE` 在左边**失败**时才试右边。第一个例子里 `conj_tac` 对 `a ∨ b`
失败（不是合取），于是走 `disj1_tac` 得到 `a`。第二个例子里
`conj_tac` 对 `a ∧ b` 成功，右边根本没跑。

> **没有 `||` 这个算子。** 想写中缀要用 `ORELSE`。

## 10.5 TRY / REPEAT / NTAC

```text
TRY disj1_tac      : a
TRY conj_tac       : a ∨ b
REPEAT strip_tac   : <closed>
NTAC 2 strip_tac   : a ∧ b ⇒ b
NTAC 1 strip_tac   : ∀b. a ∧ b ⇒ b
```

```sml
val _ = show "TRY disj1_tac     " (TRY disj1_tac) ``(a : bool) \/ b``
val _ = show "TRY conj_tac      " (TRY conj_tac) ``(a : bool) \/ b``
val _ = show "REPEAT strip_tac  " (REPEAT strip_tac) ``!a b : bool. a /\ b ==> b``
```

| 算子 | 语义 |
|---|---|
| `TRY tac` | 成功就用，失败就当没发生（**不会失败**） |
| `REPEAT tac` | 反复应用直到失败（**不会失败**） |
| `NTAC n tac` | 恰好应用 n 次，中途失败就失败 |

`TRY conj_tac` 对 `a ∨ b` 失败，于是原样返回 `a ∨ b` —— 这是 `TRY`
和 `ORELSE` 的关键区别：`TRY` 失败时不动目标。

## 10.6 FIRST

```text
FIRST [conj,disj]  : a
FIRST [disj,conj]  : a
```

```sml
val _ = show "FIRST [conj,disj] " (FIRST [conj_tac, disj1_tac]) ``(a : bool) \/ b``
```

`FIRST` 按顺序试，用**第一条能动的**。两个顺序都得到 `a`，因为只有
`disj1_tac` 能动。它和 `ORELSE` 的差别只是写法（列表 vs 二元）。

## 10.7 ALLGOALS

```text
conj_tac 之后   : T  ‖  T
ALLGOALS assume : T ⊢ T  ‖  T ⊢ T
一步到位           : <closed>
```

```sml
(* list_tactic 作用于"目标列表"，跟 tactic 作用于是另一个类型，
   所以 ALLGOALS 不能直接接在 THEN 右边 —— 先跑 conj_tac 拿到列表，
   再把 list_tactic 作用上去。 *)
val gls0 = #1 (conj_tac (gl ``(T : bool) /\ T``) (Context.snapshot ()))
val _ = out ("ALLGOALS assume : " ^
             fmtgs (#1 ((ALLGOALS (assume_tac (ASSUME ``T``))) gls0
                          (Context.snapshot ()))))
```

> **`ALLGOALS : tactic -> list_tactic`**，它作用的是"目标列表"不是"目标"。
> 所以 `conj_tac THEN ALLGOALS simp` 类型错 —— 要先拿到列表再作用。
> 想一步到位就用 `>>`（它是 gentactic 版，自动插入 `ALLGOALS`）。

## 10.8 一个真实的组合

```text
⊢ ∀l. LENGTH (MAP (λx. x + 1) l) = LENGTH l
⊢ ∀l. ¬NULL l ⇒ ∃h t. l = h::t
```

```sml
val _ = out (thm_to_string
               (prove(``!l : num list. LENGTH (MAP (\x. x + 1) l) = LENGTH l``,
                      Induct_on `l` >> simp [])))
val _ = out (thm_to_string
               (prove(``!l : num list. ~NULL l ==> ?h t. l = h :: t``,
                      Cases_on `l` >> simp [] >> metis_tac [])))
```

真实脚本里最常见的形状：`Induct/Cases >> simp [...] >> metis_tac [...]`。
**先用归纳或分情况拆开结构，再用化简器展开定义，最后用一阶推理收尾。**

## 10.9 坑位清单

1. **`THENL` 的列表长度必须恰好等于子目标数** → 多一个少一个都直接失败。
2. **`ALLGOALS` 是 `tactic -> list_tactic`** → 不能直接 `THEN ALLGOALS`；用 `>>` 或先拿列表。
3. **没有 `||` 算子** → 中缀的"否则"要写 `ORELSE`。
4. **`TRY` 失败时不动目标** → 它和 `ORELSE` 的区别：`TRY` 保留原目标。
5. **`REPEAT` 遇到一直成功的战术会不终止** → `REPEAT all_tac` 是死循环。
6. **`>>` 是 `THEN` 的 gentactic 版** → 两边都能是 `tactic` 或 `list_tactic`；日常优先用它。
7. **`>-` 只管第一个子目标** → 想管第 n 个要用 `THENL` 或连用多个 `>-`。
8. **`NTAC n tac` 中途失败就整体失败** → 不像 `TRY` 会兜住。
9. **`FIRST []` 一定失败** → 空列表没有"第一条能动的"。
10. **`e (r 1)` 类型错** → `r` 是 `int -> proof` 不是战术（09.4 节）。

---

上一章：[09 · 基本战术与目标栈](09-tactics.md) ·
下一章：[11 · 转换](11-conv.md)
