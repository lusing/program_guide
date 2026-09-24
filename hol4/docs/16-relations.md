# 16 · 关系与闭包

> 对应示例：[`examples/16_relations/16_relations.sml`](../examples/16_relations/16_relations.sml)

关系在 HOL4 里就是 `α -> α -> bool`（二元谓词）。本章用它讲三件事：
**传递闭包**（`RTC` / `TC`）、**良基关系**（`WF`），以及
**良基递归的终止性证明** —— 最后一件是写非结构化递归时绕不开的。

## 16.1 关系

```text
类型   : :num -> num -> bool
逆     : rel_inv R
```

```sml
val _ = out ("类型   : " ^ (type_of ``($<) : num -> num -> bool`` |> type_to_string))
val _ = out ("逆     : " ^ (term_to_string ``rel_inv R``))
```

关系没有专门的类型构造子。`num -> num -> bool` 里那些函数就是关系，
`<`（要写成 `$<` 才能当值用）、`≤`、以及你自己写的任何二元谓词都是。

`relationTheory` 提供了一批常用运算：`rel_inv`（逆）、
`rrestrict`（限制）、`RUNION`（并）、`RINTER`（交）、`RDOM`/`RRANGE`（定义域/值域）。

## 16.2 传递闭包

```text
relationTheory 里的 RTC_* 定理：38 条，前 12 条： RTC_TRANSITIVE RTC_TRANS RTC_TC_RC RTC_TC_o_RC RTC_SUBSET RTC_strongind RTC_STRONG_INDUCT_RIGHT1 RTC_STRONG_INDUCT RTC_SINGLE RTC_RUNION RTC_RULES_RIGHT1 RTC_RULES
relationTheory 里的 TC_* 定理： 26 条，前 12 条： TC_TRANSITIVE TC_SUBSET TC_STRONG_INDUCT_RIGHT1 TC_STRONG_INDUCT_LEFT1 TC_STRONG_INDUCT TC_RULES TC_RTC TC_RIGHT1_I TC_RC_EQNS TC_MONOTONE TC_lifts_transitive_relations TC_lifts_monotonicities
⊢ R꙳ x x
⊢ R꙳ x y ∧ R꙳ y z ⇒ R꙳ x z
```

```sml
fun rnames pfx =
  let val ns = List.filter (fn n => String.isPrefix pfx n)
                           (map #1 (DB.theorems "relation"))
  in Int.toString (length ns) ^ " 条，前 12 条： " ^
     String.concatWith " " (List.take (ns, 12)) end
val _ = out (thm_to_string (DB.fetch "relation" "RTC_REFL"))
val _ = out (thm_to_string (DB.fetch "relation" "RTC_TRANS"))
```

`relationTheory` 里关于闭包有几十条定理，头文件能看到的不多，
所以这里用 `DB.theorems "relation"` 把名字全捞出来按前缀筛：
`DB.theorems` 返回 `(名字, 定理)` 的列表，`map #1` 只留名字。

两个闭包：

| 名字 | 含义 | 打印 |
|---|---|---|
| `RTC R x y` | **自反**传递闭包（x 走 0 步或多步到 y） | `R꙳ x y` |
| `TC R x y` | 传递闭包（至少一步） | `R⁺ x y` |

`RTC_REFL` 说"零步也算"：`⊢ R꙳ x x`。
`RTC_TRANS` 说"两段能接起来"：`⊢ R꙳ x y ∧ R꙳ y z ⇒ R꙳ x z`。

这两个定理是后面所有闭包推理的起点。**注意 `RTC_TRANS` 的方向**：
它是"左侧不动、右侧延伸"。把它当重写规则喂给 `metis` 时要小心（17 章会踩到）。

## 16.3 用 RTC 的归纳

```text
⊢ ∀R P. (∀x. P x x) ∧ (∀x y z. R x y ∧ P y z ⇒ P x z) ⇒ ∀x y. R꙳ x y ⇒ P x y
⊢ ∀R x y. R꙳ x y ⇒ R꙳ x y
⊢ ∀R x y z. R꙳ x y ⇒ R꙳ y z ⇒ R꙳ x z
```

```sml
val _ = out (thm_to_string (DB.fetch "relation" "RTC_INDUCT"))
val _ = out (p ``!(R : num -> num -> bool) x y z.
                 RTC R x y ==> RTC R y z ==> RTC R x z``
               (metis_tac [RTC_TRANS]))
```

`RTC_INDUCT` 是闭包自带的归纳原理，读法如下：

```
要证  ∀x y. R꙳ x y ⇒ P x y
只需  ① ∀x. P x x                     （零步的情况）
     ② ∀x y z. R x y ∧ P y z ⇒ P x z   （加一步在"左边"）
```

注意 ② 的形状：**一步 `R x y` 加在左边**，归纳假设 `P y z` 管右边那一段。
这叫"**右归纳**"（因为延伸发生在右侧的起点）。

`relationTheory` 同时提供了 `RTC_INDUCT_RIGHT1`（一步加在**右端**），
两步走同一个方向时用它更顺手 —— 17 章证 `RTC ⊆ path` 时必须换用它。

后两行是"闭包推理的最小示范"：`metis_tac []` 处理自反这条平凡目标，
`metis_tac [RTC_TRANS]` 把两段接起来。

> **别试图用 `metis_tac [RTC_TRANS]` 证明任意方向的闭包拼接。**
> `RTC_TRANS` 是单向的，`metis` 会一直试着把它往两个方向实例化，
> 很容易搜到不终止（本教程的验证脚本加了看门狗才把它变成可诊断的失败）。

## 16.4 良基

```text
⊢ ∀m. WF (measure m)
⊢ ∀R. WF R ⇒ ∀P. (∀x. (∀y. R y x ⇒ P y) ⇒ P x) ⇒ ∀x. P x
relationTheory 里跟 WF 有关的定理：14 条，前 12 条： WF_TC_EQN WF_TC WF_SUBSET WF_RECURSION_THM WF_PULL WF_NOT_REFL WF_noloops WF_irreflexive WF_inv_image WF_INDUCTION_THM WF_EQ_WFP WF_EQ_INDUCTION_THM
```

```sml
val _ = out (thm_to_string (DB.fetch "prim_rec" "WF_measure"))
val _ = out (thm_to_string (DB.fetch "relation" "WF_INDUCTION_THM"))
```

**良基**（well-founded）说的是"没有无穷下降链"：`WF R` 意味着
不存在 `… R x2 R x1 R x0` 这样永远往下降的序列。它是递归终止性的形式依据。

`WF_INDUCTION_THM` 是良基关系的归纳原理，读法：

```
要证  ∀x. P x
只需  ∀x. (∀y. R y x ⇒ P y) ⇒ P x
```

也就是"假设所有比 x 小的都成立，推出 x 成立"。这就是**强归纳**的抽象版。

> **`WF_measure` 在 `prim_recTheory` 里，不在 `relationTheory` 里。**
> 这一条在本机实测确认过：`relationTheory` 里没有 `WF_measure`，也没有
> `WF_LESS`。找不到定理时先 `DB.find`（22 章），别死磕一个理论。

`measure f` 是构造良基关系最常用的手段：`WF_measure` 保证
`measure f` 良基（因为它落在 `num` 的 `<` 上，而 `<` 是良基的）。

## 16.5 良基递归

```text
<<HOL warning: Context.snapshot: ambient context read while a proof was running (in Tut16)>>
⊢ ∀n. half2 n = if n < 2 then n else half2 (n − 2)
求值：half2 10 = 0
归纳原理：⊢ ∀P. (∀n. (¬(n < 2) ⇒ P (n − 2)) ⇒ P n) ⇒ ∀v. P v
```

```sml
Definition half2_def:
  half2 n = if n < 2 then n else half2 (n - 2)
Termination
  WF_REL_TAC `measure (\n. n)` >> rw []
End
val _ = out (thm_to_string half2_def)
val _ = out ("求值：" ^ (EVAL ``half2 10`` |> concl |> term_to_string))
val _ = out ("归纳原理：" ^ thm_to_string half2_ind)
```

`half2` 每次减 2，不符合"对直接前驱递归"的结构要求，
所以必须给出**终止性证明**。`Definition … Termination … End` 的写法是：

```sml
Definition <名字>:
  <方程>
Termination
  WF_REL_TAC `measure (\n. <测度>)` >> <证测度下降的战术>
End
```

`WF_REL_TAC` 会为每个递归调用生成一条"新参数在关系上小于旧参数"的义务。
这里就是 `n - 2 < n`（在 `¬ n < 2` 的前提下），`rw []` 一步收掉。

定义成功后 HOL4 自动生成两条东西：

- `half2_def` —— 就是上面那条方程；
- `half2_ind` —— **配套的归纳原理**（最后一行），形状是良基归纳的特化：
  `∀P. (∀n. (¬(n < 2) ⇒ P (n − 2)) ⇒ P n) ⇒ ∀v. P v`。
  有了它，手写的证明就能照着"减 2"的递归结构走（16.7）。

`half2 10 = 0` 是求值校核：`10 → 8 → 6 → 4 → 2 → 0`，到 0 时 `0 < 2` 成立，返回 0。

> 输出里那条 `<<HOL warning: Context.snapshot …>>` 是**终止性证明过程中**
> 读 ambient context 触发的警告，不是错误，也不会影响结果。
> 三条通道里它都出现且完全一致，所以验证脚本照判通过。

## 16.6 测度选错的后果

```text
measure 必须是良基关系上的下降：
  用 measure (\n. n) 时，递归调用 half2 (n - 2) 要证 n - 2 < n，
  由 n >= 2 推出；simp 里的算术过程直接把它收掉。
  换成 measure (\n. 0) 就会留下 0 < 0 这样不可证的目标。
```

这一节是纯粹的"解说"（没有新输出），因为它要讲的是**失败长什么样**：

- 选 `measure (\n. n)`（用参数本身当测度）：终止性义务是 `n - 2 < n`，
  在前提 `¬ n < 2`（即 `n ≥ 2`）下成立，`rw []` 里的算术过程直接收掉。
- 选 `measure (\n. 0)`（常数测度）：义务退化成 `0 < 0`，**不可证**。
  这时 `Definition` 会失败，脚本 abort，并打印出未解决的目标。

**判据**：终止性义务应当形如"新测度 < 旧测度"，且能从递归分支的守卫条件推出。
如果义务是 `0 < 0`、`n < n` 这种，说明测度没选对 ——
换一个真正反映"递归在变小"的量。

## 16.7 手动良基归纳

```text
⊢ ∀n. half2 n ≤ n
```

```sml
val _ = out (p ``!n : num. half2 n <= n``
               (ho_match_mp_tac (DB.fetch "Tut16" "half2_ind")
                >> rpt strip_tac >> rw [Once half2_def] >> DECIDE_TAC))
```

最后一个证明把 16.4 和 16.5 串起来了。要证 `half2 n ≤ n`，
用 `half2` **自己的**归纳原理（`half2_ind`），而不是 `Induct_on \`n\``：

1. `ho_match_mp_tac half2_ind` —— 把目标化成良基归纳的形式
   （`ho_` 前缀表示"高阶匹配"，能处理归纳原理里的谓词变量）；
2. `rpt strip_tac` —— 拆掉 `∀n` 和前提 `¬(n < 2) ⇒ P (n-2)`；
3. `rw [Once half2_def]` —— 展开**一次** `half2`；
   用 `Once` 是为了防止化简器反复展开（`half2` 的分支里有 `if`）；
4. `DECIDE_TAC` —— 剩下的线性算术。

> 用 `Once <def>` 而不是 `<def>`，是展开递归定义时的好习惯：
> 递归方程两侧的"自我引用"会让化简器反复展开，容易跑不完。

## 16.8 坑位清单

1. **`WF_measure` 在 `prim_recTheory`，不在 `relationTheory`** → 也没有 `WF_LESS`。
2. **`RTC_TRANS` 是单向的** → 喂给 `metis` 容易搜到不终止；要控制方向。
3. **`RTC_INDUCT` 一步加在左边** → 需要加在右端时用 `RTC_INDUCT_RIGHT1`。
4. **`<$` 这类中缀当值用要加 `$`** → ``($<) : num -> num -> bool``。
5. **`measure` 必须是"真在下降"的量** → 常数测度会留下 `0 < 0`。
6. **`Definition … Termination … End` 才有 `_ind`** → 普通 `Definition` 不给良基归纳原理。
7. **递归定义要用 `rw [Once def]` 展开** → 否则化简器可能反复展开。
8. **`ho_match_mp_tac` 用于带谓词变量的归纳原理** → 普通 `match_mp_tac` 匹配不上。
9. **`RTC` 是自反传递闭包、`TC` 不是** → 打印上分别是 `R꙳` 和 `R⁺`。
10. **终止性证明会打印 `Context.snapshot` 警告** → 它是良性的，三条通道里一致出现。

---

上一章：[15 · 集合与谓词](15-sets.md) ·
下一章：[17 · 归纳定义](17-inddef.md)
