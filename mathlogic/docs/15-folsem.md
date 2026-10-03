# 15 FOL 语义：一致性引理、代入交换与一阶理论

> 对书：EFT III / Mendelson §2.2 / Huth&Ryan §2.4

本章兑现 14 章登记的边界，并给出「一阶理论」的机器化样例。

## 交付内容

**旗舰一：满足一致性引理（EFT III.5 的 FOL 版，三通道零公理）**

```
eform_coincidence : 赋值只在 fv f 上一致 → 两语义 iff
```

- Coq 版五分支归纳：atom 走 eterm 一致性、fimp/fneg 走方向矩阵、
  **fall 分支是重头**——量化环境 `eupd e y v` 与 `eupd e2 y v`
  在 fv a 上逐点一致（m=y 处同 v、否则归 h）
- Lean 版 `have key` 前置统一处理双环境逐点等式

**旗舰二：代入交换的完整版（14 章 subst_comm 兑现）**

```
subst_all_eval : closedT s →
  eform e (subst f x s) ↔ eform (eupd e x (eterm e s)) f
```

∀ 分支的两场硬仗：

1. **y = x 路**（x 被束缚）：两层 `eupd (eupd e x U) x v` 的
   x 处「后写胜出」——pointwise 展开三个 if 直收；
2. **y ≠ x 路**：两层 eupd 的**换序**——
   `eupd (eupd e x U) y v` 与 `eupd (eupd e y v) x U'` 逐点一致
   （x 处同为闭项值 U=U'（闭项求值与环境无关）、y 处同 v、其他同 e）。
   闭项侧条件在这里兑现成 `closed_eval_inv` 引理。

**旗舰三：一阶理论样例**

- Isabelle：locale `strict_order`（irrefl+trans）→ 无 2-环/3-环 +
  `interpretation (<)` 实例化 + coincidence 的 blast 一行版
- Lean：`structure StrictOrder` → `noCycle2` + `ltNoCycle2` 实例

## 三家分工

| 通道 | 内容 |
|---|---|
| Coq | 一致性 + 完整代入交换（闭项侧条件）+ 两场 ∀ 硬仗全展开 |
| Lean | 一致性同构（have key 模式）+ 严格偏序 structure |
| Isabelle | locale 演示（教学重点：理论的模块化表达） |

## 坑位速记（本章实测——15 轮迭代）

- **Coq**：`destruct (Nat.eqb y x) eqn:E` **会把目标里的
  scrutinee 替换掉**（后续 rewrite E 找不到）——simpl 后的 if
  已变成 true/false 字面量；destruct 的 sumbool 参数序要与
  remove 体一致（`Nat.eq_dec y a` 不是 `a y`）；iff 的分量
  要显式 `.mp/.mpr`（09 章同款）；「destruct (m =? x) eqn:E1」
  后分支里目标已是字面量——多余的 `rewrite E1` 反而报错；
  `subst m` 在 m 被 Ex 吸收后变量消失。
- **Lean**：iff 不能直接 apply（是结构不是函数）——`.mp/.mpr`
  全显式；`List.mem_eraseDups` 不存在（核心库无此引理）——
  fv 定义去掉 eraseDups；filter 的 Bool 条件用 `simp [hmy]`
  单独一步消 decide；structure Prop 的字段要 `so.` 前缀。
- **Isabelle**：locale 实例化后定理带前缀
  （`lt_order.no_cycle2`）；schema 变量让 `by (fact ...)` 失败——
  `of x y` 显式实例化或 nat 标注。
