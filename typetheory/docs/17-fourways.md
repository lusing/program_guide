# 17 四大证明助手对照实战

> 本章是前 16 章的总演习：**同一个开发流**（定义 → 引理 → 主定理
> → 断言）在 Lean / Coq / Agda 各走一遍，任务选了经典的
> `reverse (reverse xs) = xs`。Coq-HoTT 线在第五部分登场。
> 代码：`examples/17_fourways/`。

## 17.1 同一定理三份证明并排

任务分解（三家一致）：`rev` 用 append 定义 → 关键引理
`rev_append`（rev 与 ++ 交换）→ 主定理归纳。

**Lean**：

```lean
theorem rev_append {α : Type} (xs ys : List α)
    : rev (xs ++ ys) = rev ys ++ rev xs := by
  induction xs with
  | nil => simp [rev]
  | cons x xs ih => simp [rev, ih]

theorem rev_rev {α : Type} (xs : List α) : rev (rev xs) = xs := by
  induction xs with
  | nil => rfl
  | cons x xs ih => simp [rev, rev_append, ih]
```

**Coq**：

```coq
Lemma rev_append : forall (A : Type) (xs ys : list A),
  rev (xs ++ ys) = rev ys ++ rev xs.
Proof.
  intros A xs ys. induction xs as [| x xs IH]; simpl.
  - rewrite app_nil_r. reflexivity.
  - rewrite IH. rewrite app_assoc. reflexivity.
Qed.
```

**Agda**（没有 tactic，证明是组合子）：

```agda
rev-append []       ys = sym (++-identityʳ (rev ys))
rev-append (x ∷ xs) ys =
  trans (cong (_++ (x ∷ [])) (rev-append xs ys))
        (++-assoc (rev ys) (rev xs) (x ∷ []))

rev-rev (x ∷ xs) =
  trans (rev-append (rev xs) (x ∷ []))
        (cong (x ∷_) (rev-rev xs))
```

## 17.2 三种证明文化的分野

同一个数学内容，三种「劳动方式」：

| | Lean | Coq | Agda |
|---|---|---|---|
| 证明形态 | tactic + term 混合 | tactic 为主 | 纯项（组合子） |
| 自动化 | `simp [rev, ih]` 一发入魂（引理全家桶） | `rewrite` 手排次序 | 零自动化，`cong`/`trans` 手拼 |
| 交互模型 | 孔洞（`?`）+ 消息面板 | Proof General/CoqIDE 目标窗 | Emacs/VSCode 孔洞 + `C-c C-l` |
| 引理方向 | simp 自动双向 | rewrite 单向（`<-` 反向） | 自己挑 `sym` |
| 误出错时 | 错误信息常给出修复建议 | 目标窗直观看卡点 | 类型洞口直观看缺什么 |

经验法则：**Coq 适合「排兵布阵」型证明**（一大堆 rewrite 的次序
战术）；**Agda 适合「类型先行」的开发**（先写类型签名，洞口驱动）；
**Lean 两头兼顾外加最强的自动化**（simp/omega/decide），代价是要
了解 simp 集合的行为边界（12/13 章「iota 折叠看不见」系列）。

第四家 Coq-HoTT 的差异不在劳动方式而在**语义底座**（类型即空间），
19 章起展开。

## 17.3 生态与选型速查

| | 内核谱系 | 库 | 杀手级应用 |
|---|---|---|---|
| Coq | CIC | stdlib + Math-Comp | CompCert、四色定理、Math-Comp |
| Agda | MLTT | stdlib | 正确性验证研究、教学 |
| Lean 4 | CIC 变体 | **Mathlib**（单体大库） | Liquid Tensor Experiment、数学形式化 |
| Coq-HoTT | MLTT+UA | HoTT 库 | 同伦数学、立方 Agda 同族 |

本仓库另有四份专门教程可深入：
[coq](../coq)、[agda](../agda)、[lean4](../lean4)、[coq-hott](../coq-hott)。

> **坑位速记**
> ① Agda stdlib 2.3 的 `_++_` 等基础件在 `Data.List.Base`，
> `Data.List` 的 re-export 列表不含它（ModuleDoesntExport 警告
> 后接 NotInScope）；
> ② Coq `assert` 里的引理绑定名别与外层同名（`xs is already
> used`）；
> ③ Agda 证明里 `trans`/`cong` 的**链条顺序**即证明结构——
> 先想清楚「目标 = 中转1 ∘ 中转2」再下笔；
> ④ Lean `simp [rev, ih]` 的前提是引理形状能被 simp 重写——
> 方向不对就 `← ih` 或改写 `rev_append`。

---

上一章：[16 子集与强制](16-subtype.md) · 下一章：[18 提取与运行](18-extraction.md)
