# 21 可判定性与 SMT：判定层的机器面

> 对书：Mendelson §3.6/ch5 / EFT X / Ben-Ari 3e Ch12

命题逻辑可判定（02/07 章的判定器）；一阶逻辑**不可判定**
（Church 定理）但**半可判定**（完备性 ⟹ 有效式可枚举）。
本章是文档章 + 机器现场——判定层的「机器面」用各家的
决策程序实例展示。

## 判定层级（文档主线）

```
命题逻辑        可判定（真值表/DPLL）           02/09 章已交付
Presburger 算术  可判定（Cooper 算法）           Isabelle presburger 现场
有界量词片段     可判定（有限展开）              Lean boundedAll 现场
一阶逻辑        不可判定（Church）但 r.e.       文档
PA / 二阶       更不可判定                      22 章（不完备性）
```

## 机器现场

**Isabelle（presburger 现场三连）**：

```isabelle
lemma presburger_demo:
  "∀x::int. ∃y. 2 * y ≤ x ∧ x < 2 * y + 2"
  by presburger
```

`presburger` 方法是 Cooper 算法的实现——整数量词消去，
线性算术的完全决策程序（非启发式）。与 DPLL（09 章）构成
「组合决策」的两半（布尔 + 算术 = SMT 的 DPLL(T) 架构，
文档说明）。

**Lean（Decidable 的命题面）**：

```lean
example (x y : Nat) : Decidable (x = y) := instDecidableEqNat x y
```

`Decidable P` 类型的**存在性**即「P 可判定」的机器表述——
decide 求值、instance 搜索、内核转换都走这里。bounded 量词的
可判定性来自 `List.all` 的有限性——unbounded 量词破坏
有限性正是一阶不可判定的起点。

## Church 定理与 sledgehammer（文档）

一阶有效式集 r.e. 但非递归——**sledgehammer 的有限资源
搜索在不可判定问题上的角色**：它找的是**引理组合**（若找到
则证明完备），不是判定器。SMT solver（z3/cvc5/vampire 均在
Isabelle contrib 里）作为 backend 时同样受不可判定性约束——
能答 UNSAT 的只有片段（命题/线性算术）。

## 坑位速记（本章实测）

- **Isabelle**：`(induct rule: nat.induct)` 与 `(rule nat.induct)`
  在带 `assumes` 的引理上均解不出第二子目标——**P 是自由
  谓词变元时归纳法不会自动吃假设**（要 `intro allI` 后 fix x，
  而 `induction_schema` 对非自由 P 报 dest_Free 异常）——
  最终删除该演示引理（教学价值由 22 章接管）；
  `presburger` 对 `mod` 的分情况直接收。
- **Lean**：`/- … -/` 文档注释**必须紧接声明**——放在两个
  example 之间报 unexpected token `/-`；参数序错误
  （`evalProp [] []` 的 List/Nat→Bool 混位）——删掉简化。
