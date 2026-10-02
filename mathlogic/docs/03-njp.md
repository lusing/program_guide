# 03 自然演绎 NJp：规则即程序

> 对书：Huth&Ryan §1.2 / Mints §2.2 / Ben-Ari 3e Ch3（对照）/ Mendelson §1.4（Hilbert 对照）

自然演绎的每条规则，在类型论系里字面就是一个程序：
∧I=配对、∧E=投影、∨I=注入、∨E=分情况、→I=λ、→E=应用、⊥E=空消解。
在 LCF 系里规则是内核定理（Isabelle 的 `conjI`/`mp` 有专名；
HOL4 的 `DISJ1_TAC`/`RES_TAC` 是定理持续器）。

## 五家同一组定理

| 定理 | 构造可证 | 坑点 |
|---|---|---|
| ∧ 交换、∨ 交换 | ✓ | — |
| de Morgan ¬(p∨q)→¬p∧¬q 及逆 | ✓ 两个方向 | 对偶的 ¬(p∧q)→¬p∨¬q 要等 04 章 |
| 拒取式 MT | ✓ | — |
| ex falso、K 公理 | ✓ | — |
| curry/uncurry | ✓ | 「→I/E 的代数」预告 12 章 Curry–Howard |

## HOL4 首战实录（最有教学价值的一节）

HOL4 的 `REPEAT STRIP_TAC` 是**双向**工作：

```
目标 q ∧ p            ← 前件的 ∧ 拆成假设，目标侧的 ∧ 也拆掉
目标 ~p / ~q          ← 连 ~ 的合取目标都替你铺好
假设 q（不是 p ∨ q！） ← 前件的 ∨ 也直接分好情况
```

探针（自写 dump tactic）实测：`p ∨ q ⇒ q ∨ p` 经 `REPEAT STRIP_TAC`
后第一分支的假设直接就是 `q`。由此踩出的系列坑：

- `CONJ_TAC`/`POP_ASSUM DISJ_CASES_TAC` 常常根本轮不到——目标已被拆完；
- `ASM_REWRITE_TAC` 只吃「等式」假设，原子布尔假设要用 `ACCEPT_TAC`；
- `DISJ1 : thm -> term -> thm` 与 `DISJ2 : term -> thm -> thm`
  **签名不对称**（报错文本逐次拼出来的事实）；
- `DISJ*_TAC` 把注入项留成子目标，不查假设；
- 上下文自由变量的手动定理构造（`DISJ1 (ASSUME …) …`）会报
  "Can't alpha convert"——纯命题复合式交给 `PROVE_TAC` 最稳。

## Isabelle：规则有专名的 Isar

```isabelle
lemma nd_or_comm: "P \<or> Q \<Longrightarrow> Q \<or> P"
proof (erule disjE)
  assume P: P
  show "Q \<or> P" using P by (rule disjI2)
next
  assume Q: Q
  show "Q \<or> P" using Q by (rule disjI1)
qed
```

`conjI/conjE/disjI1/disjI2/disjE/impI/mp/notI/notE/FalseE` 全是内核定理，
Isar 里 `by (rule 名字)` 直接当方法用——ND 规则表在 Isabelle 是「查表可得」。

## 坑位速记

- **Coq**：`intros [HP | HQ]` 即 ∨E；`split` 即 ∧I；
  全部 `Print Assumptions` 均 Closed——NJp 片段零公理。
- **Agda**：`¬_` 展开即 `→ ⊥`；`⊥-elim` 对 `()` 荒谬模式收尾；
  de-morgan₂ 的目标是函数——子句按参数模式分支。
- **Lean**：`h.elim Or.inr Or.inl` 一行做完 ∨E；
  `fun ⟨hp, hq⟩ => …` 的 λ 模式匹配完全合法。
- **Isabelle**：`assume A: A and P` 未命名的 `and P` 不给标签——
  引用时报 Undefined fact；`(rule P)` 把 fact 当定理用是合法的。
- **HOL4**：见上节五连坑；验证必须 `hol run`（REPL 管道假绿）。
