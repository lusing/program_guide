# 07 · 归纳证明

> 对应示例：[`examples/07_induction/07_induction.sml`](../examples/07_induction/07_induction.sml)

归纳是 HOL4 里唯一能对付 `∀n` / `∀l` 的工具。本章把四种常用归纳
（结构归纳、datatype 归纳、强归纳、良基归纳）各跑一遍，并演示
**归纳假设不够强时怎么泛化** —— 这是新手卡壳最久的地方。

## 07.1 结构归纳

`Induct_on` 用类型自带的归纳定理，自动把归纳假设装进当前目标：

```text
⊢ ∀n. 0 + n = n
⊢ ∀l. LENGTH (REVERSE l) = LENGTH l
```

```sml
val _ = out (p ``!n : num. 0 + n = n`` (Induct_on `n` >> simp []))
val _ = out (p ``!l : num list. LENGTH (REVERSE l) = LENGTH l``
               (Induct_on `l` >> simp []))
```

第二个证明看着像作弊：`REVERSE (h::t)` 展开成 `REVERSE t ++ [h]`，
`LENGTH (… ++ [h])` 由 `LENGTH_APPEND` 化成 `LENGTH (REVERSE t) + 1`，
归纳假设正好接上。这类"定义 + 定理都在默认 simpset 里"的证明，
一行 `simp` 就够了。

## 07.2 归纳定理的形状

归纳定理就是 `∀P. … ⇒ ∀x. P x` 形状的普通定理，可以打印出来看：

```text
⊢ ∀P. P [] ∧ (∀t. P t ⇒ ∀h. P (h::t)) ⇒ ∀l. P l
<<HOL message: Defined type: "bt7">>
⊢ ∀P. P Lf7 ∧ (∀b b0. P b ∧ P b0 ⇒ ∀n. P (Nd7 b n b0)) ⇒ ∀b. P b
```

```sml
val _ = out (thm_to_string list_induction)
val _ = Datatype `bt7 = Lf7 | Nd7 bt7 num bt7`
val _ = out (thm_to_string (DB.fetch "Tut07" "bt7_induction"))
```

`list_induction` 有 ML 绑定（它是 `listTheory` 的），`bt7_induction` 没有 ——
`Datatype` 只登记不给绑定，得 `DB.fetch`（05 章）。

树的那条里 `(∀b b0. P b ∧ P b0 ⇒ ∀n. P (Nd7 b n b0))`：
两个子树的归纳假设先给，`n` 放在最后 —— 因为它不是递归位置。

## 07.3 树上的归纳

```text
⊢ ∀t. 0 < size7 t + 1
```

```sml
Definition size7_def:
  (size7 Lf7 = 0) /\
  (size7 (Nd7 l n r) = 1 + size7 l + size7 r)
End
val _ = out (p ``!t : bt7. 0 < size7 t + 1``
               (Induct_on `t` >> simp [size7_def]))
```

`Induct_on \`t\`` 会挑 `bt7_induction`。两个子树的归纳假设加上算术化简，
一步收尾。

## 07.4 强归纳

`completeInduct_on` 给出**所有更小的值**都成立的归纳假设，
适合"步长不是 1"的递归：

```text
<<HOL warning: Context.snapshot: ambient context read while a proof was running (in Tut07)>>
⊢ ∀n. n ≤ n
⊢ ∀n. n ≠ 0 ⇒ ∃m. n = SUC m
```

```sml
val _ = out (p ``!n : num. n <= n`` (completeInduct_on `n` >> rw []))
val _ = out (p ``!n : num. ~(n = 0) ==> ?m. n = SUC m``
               (completeInduct_on `n` >> rw [] >> Cases_on `n` >> simp []))
```

第二条里 `Cases_on \`n\`` 是必需的：归纳假设只覆盖 `m < n`，
而 `n = 0` 的情况要单独分出来。

## 07.5 良基归纳

良基归纳是强归纳的一般化：沿**一个自己选的良基关系**下降：

```text
⊢ ∀R. WF R ⇒ ∀P. (∀x. (∀y. R y x ⇒ P y) ⇒ P x) ⇒ ∀x. P x
WF_measure: ⊢ ∀m. WF (measure m)
half_ind：⊢ ∀P. (∀n. (¬(n < 2) ⇒ P (n − 2)) ⇒ P n) ⇒ ∀v. P v
```

```sml
val _ = out (thm_to_string WF_INDUCTION_THM)
val _ = out ("WF_measure: " ^ thm_to_string (DB.fetch "prim_rec" "WF_measure"))
Definition half_def:
  half n = if n < 2 then n else half (n - 2)
Termination
  WF_REL_TAC `measure (\n. n)` >> simp []
End
val _ = out ("half_ind：" ^ thm_to_string half_ind)
```

> `WF_measure` 在 **`prim_recTheory`** 里，不在 `relationTheory`；
> `relationTheory` 里也没有 `WF_LESS`。找定理时用 `DB.find` 搜名字
> （22.4 节），比翻手册快。

`half` 的递归步长是 2，`num_induction` 走不动，`half_ind` 才是配套的原理。

## 07.6 泛化：带累加器的 reverse

**这一节是本章的重点。** 带累加器的函数，只有把累加器留在 `∀` 里
（即不对它做归纳），归纳假设才够用：

```text
⊢ ∀xs acc. revacc xs acc = REVERSE xs ⧺ acc
⊢ ∀xs. revacc [] xs = xs
```

```sml
Definition revacc_def:
  (revacc [] acc = acc) /\
  (revacc (x :: xs) acc = revacc xs (x :: acc))
End
val _ = out (p ``!xs acc : num list. revacc xs acc = REVERSE xs ++ acc``
               (Induct_on `xs` >> simp [revacc_def]))
```

如果写成 `!xs. revacc xs [] = REVERSE xs`（只对 `xs` 归纳、`acc` 固定成 `[]`），
归纳假设是 `revacc xs [] = REVERSE xs`，而归纳步需要的是
`revacc xs (x :: acc) = …` —— 对不上。**把会变的量放进 `∀`** 就是泛化。

## 07.7 多变量归纳

```text
⊢ ∀n m. n + m = m + n
```

```sml
val _ = out (p ``!n m : num. n + m = m + n``
               (Induct_on `n` >> Induct_on `m` >> simp []))
```

先归纳哪个变量决定了归纳假设的形状。这里先 `n` 后 `m`，
`ADD_SUC` / `ADD_0` 正好能对上；反过来可能要额外的引理。

## 07.8 Cases 与 Induct 的分工

只要"分情况"不要"归纳假设"时用 `Cases_on`，它更便宜也不会引入无用的假设：

```text
⊢ ∀l. l = [] ∨ ∃h t. l = h::t
⊢ ∀n. n = 0 ∨ ∃m. n = SUC m
```

```sml
val _ = out (p ``!l : num list. l = [] \/ ?h t. l = h :: t``
               (Cases_on `l` >> simp []))
```

> 经验法则：目标里出现**递归调用**→ 用 `Induct_on`；
> 只是"这个值可能是哪种形状"→ 用 `Cases_on`。

## 07.9 坑位清单

1. **归纳假设不够强 → 把变化的量放进 `∀`** → `!xs acc. …` 而不是 `!xs. … []`（07.6 节的核心）。
2. **`Datatype` 生成的 `_induction` 没有 ML 绑定** → 要 `DB.fetch "理论名" "t_induction"`。
3. **`WF_measure` 在 `prim_recTheory`** → 不在 `relationTheory`；`relationTheory` 里也没有 `WF_LESS`。
4. **`completeInduct_on` 之后常常还要 `Cases_on`** → 归纳假设只覆盖严格更小的值，`n = 0` 得单独分。
5. **`Induct_on` 挑哪个归纳定理看类型** → 想指定就用 `ho_match_mp_tac (DB.fetch …)`。
6. **`Induct` 和 `Induct_on` 不同** → `Induct` 用目标里第一个全称量词；`Induct_on \`x\`` 指定变量。
7. **多变量归纳的顺序影响归纳假设** → 换个顺序可能要额外引理；试不出来就先泛化。
8. **`num_induction` 走不动步长 > 1 的递归** → 用 `Definition` 生成的 `_ind`（如 `half_ind`）。
9. **`Termination` 块会打一条 `Context.snapshot` 警告** → 一次性、两条入口一致，不影响比对。
10. **该 `Cases_on` 的地方别用 `Induct_on`** → 白白引入递归假设，证明反而更难收。

---

上一章：[06 · 递归定义与终止性](06-recursion.md) ·
下一章：[08 · 化简器](08-simp.md)
