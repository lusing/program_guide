# 14 一阶逻辑：语法、自由变元与代入

> 对书：EFT II / Mendelson §2.2 / Huth&Ryan §2.2

一元片段（一元函数 + 一元谓词）——capture-avoiding 代入的机制
完整保留，记号负担压到最低。

## 交付内容（三通道零公理）

```
fv_subst_clause   fv(subst t x s) 的特征条款（含 In x (fv t) 条件）
subst_term_eval   eterm e (subst t x s) = eterm (eupd e x v) t
                  ——项代入与语义代入交换
substF 的 capture 规则现场（x 被 ∀ 束缚时代入不动）
```

## 本章最有价值的两个翻车

**1. fv 特征条款的第一版漏了 `In x (fv t)` 条件**：

```
错：In y (fv (subst t x s)) ↔ (In y (fv t) ∧ y≠x) ∨ In y (fv s)
对：... ↔ (In y (fv t) ∧ y≠x) ∨ (In x (fv t) ∧ In y (fv s))
```

错版在「y ∈ fv s 但 y ∉ fv t」时 RHS 真而 LHS 假——机器在
destruct 的第二分支上把矛盾顶了出来（`H : False` 而目标
`In y []`）。**变元重合的联动**是这种条款的隐藏维度。

**2. 语义代入引理的 RHS 写法**（Coq 版实锤）：

```
错：eupd e x (eterm fe e s) (eterm fe e t)   ← 对 eupd 求函数值！
对：eterm fe (eupd e x (eterm fe e s)) t     ← 环境级求值
```

变元号与论域同为 nat——**同型不挡混淆**，类型错误当场抓获；
`symmetry` 补上等式方向后通关。

## Agda 的 with 抽象作用域（本章坑位之王）

`with (y ≡ᵇ x)` 的抽象只作用于**子句目标**——where 块里
`(y ≡ᵇ x)` 保持原样，嵌套 with 各自归约互不通气。正确解法：
不用 where，两分支都 `refl`（外层 with 已把目标里的布尔归约掉）。
字面量 `3 ≡ᵇ 3` 归约成 true 后 false 分支**仍要求穷尽**——
给恒真 refl（语义无损）而非 `λ()`（等式目标不是函数，
ShouldBePi 拒绝）。

## 边界

公式层的 `subst_comm`（代入与语义交换的 ∀ 情形带 y ∉ fv s
侧条件）需要满足一致性引理（EFT III.5 的 FOL 版）与两次 eupd
的复合交换——15 章（FOL 语义）的内容，本章文档登记。

## 坑位速记（本章实测）

- **Coq**：`destruct (Nat.eqb z x) eqn:E` 会把目标里的 `z =? x`
  替换掉（后续 rewrite E 找不到）；`tauto` 对 `x = y` 与
  `y ≠ x` 的原子不匹配视为无关（等式方向要 symmetry/cong 手动桥）。
- **Agda**：见上节；另有 `Data.Nat.Properties` 无 `≡ᵇ-refl` 导出
  （自造或删引用）。
- **Lean**：`simp [substTerm, eterm, eupd, hz]` 的 hz（z ≠ x 事实）
  要进 simp 列表才能消 if。
