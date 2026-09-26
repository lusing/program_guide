# 44 · 证明校验与 grind

**对标**: *Reference* 第25章（Validating a Lean Proof）、第16章（The `grind` tactic）。

形式化证明的全部价值在于"可信"。本章回答两个问题：(1) Lean 凭什么相信一个证明？如何审计它没有作弊？
(2) 4.35 引入的新一代自动化战术 `grind` 能帮你把多少例行证明一键解决？

> 证明校验部分在 4.34.1 验证；`grind` 部分在 4.35.0-rc3 验证（grind 在 4.16+ 引入，4.34 起成熟）。

## 44.1 可信基：内核检查每一个证明

Lean 的信任根（trusted computing base）极小：**一个类型检查内核 + 三条公理**。
任何 `theorem`/`example` 最终都被精细化成一个 `Expr`（核心 λ-项），交给内核验证"它确实是该命题的证明"。
战术（`simp`/`omega`/`grind`）只是**生成证明项的工具**——它们可以错、可以崩，但只要内核接受了最终的项，
定理就成立。这就是为什么"用一堆黑盒战术"在 Lean 里依然可信：黑盒只负责造项，内核负责把关。

## 44.2 sorry：唯一的逃生门，也是唯一的毒

`sorry` 是一个"假装证明了"的战术，它把目标用 `sorryAx` 公理关闭。内核**接受**它，但这条公理是不一致的
（从 `sorryAx` 能推出任何命题），所以用了 `sorry` 的"证明"毫无价值：

```lean
theorem with_sorry : 1 = 2 := by sorry
-- 警告：declaration uses `sorry`
#print axioms with_sorry
-- 'with_sorry' depends on axioms: [sorryAx]
```

`sorry` 的正当用途只有一个：**开发途中占位**（先搭证明骨架，逐步填实）。但它绝不能留在最终代码里。
Lean 会在编译时对每个 `sorry` 发警告，CI 里通常用 `linter` 或脚本扫描，确保零 `sorry`。

> 注意第40章的 `plausible` 也会引入 `sorryAx`——它是测试工具，不是证明。`#print axioms` 能一眼看穿。

## 44.3 #print axioms：审计公理依赖

`#print axioms` 是审计的核心工具，列出定理传递依赖的所有公理：

```lean
theorem good : 2 + 2 = 4 := rfl
#print axioms good            -- 'good' does not depend on any axioms

open Classical in
theorem em_thm (p : Prop) : p ∨ ¬p := em p
#print axioms em_thm
-- 'em_thm' depends on axioms: [propext, Classical.choice, Quot.sound]

#print axioms Nat.add_comm    -- 'Nat.add_comm' does not depend on any axioms
```

Lean 的标准公理只有三条（见第26章）：

| 公理 | 含义 |
|---|---|
| `propext` | 命题外延性：`P ↔ Q` 则 `P`、`Q` 可互换 |
| `Classical.choice` | 经典选择公理（排中律、`by_contra`、`by_cases` 的根源） |
| `Quot.sound` | 商类型的 sound 性 |

加上危险的 `sorryAx`。审计时：
- `does not depend on any axioms` = 纯构造性/计算性证明，最干净。
- `[propext, Classical.choice, Quot.sound]` = 用了经典逻辑，**完全正常**（Mathlib 绝大多数定理如此）。
- `[sorryAx]` = **有问题**，证明无效。
- 出现你自己的 `axiom` = 检查它是否真的可信。

`Nat.add_comm` 不依赖任何公理（它是结构归纳证的），而排中律 `em_thm` 依赖三大公理——
这精确反映了"哪些数学是构造性的、哪些需要经典选择"。

## 44.4 项目级校验

单个定理用 `#print axioms`，整个项目则靠：

- **`lake build`**：编译即校验。任何无法被内核接受的"证明"都会编译失败，所以"build 通过"="所有定理被内核检验过"。
- **sorry 扫描**：CI 里 `lake build` 的输出含 `declaration uses sorry` 警告；可用脚本/linter 强制零警告。
- **`#print axioms` 批量审计**：对关键定理逐条检查公理依赖。
- **不要关内核检查**：`set_option debug.skipKernelTC true` 会跳过内核类型检查（仅用于调试性能），
  正式构建绝不能开——它会让未被验证的项混入。

第29章的 `vcgen`（程序验证）生成验证条件后，同样要由内核检验——它不绕过可信基，只是自动化生成待证项。

## 44.5 grind：新一代自动化战术

`grind` 是 Lean 4 核心（非 Mathlib）内置的通用自动化战术，目标是"一个战术解决大量例行目标"。
它综合了：**等式推理（congruence closure）+ 量词实例化 + 命题逻辑（含经典）+ 线性算术 + 结构归纳启发**。
Mathlib 已在 `hint` 战术里以高优先级注册它。

```lean
-- 等式 + 结构：List.append 的化简
example (l : List Nat) : (l ++ []).length = l.length := by grind

-- congruence：相等代入构造子/函数
example (a b : Nat) (h : a = b) (l : List Nat) : a :: l = b :: l := by grind
example {α : Type} (x y : α) (h : x = y) (f : α → Nat) : f x = f y := by grind
example (a b : Nat) (h : a = b) : a + 1 = b + 1 := by grind

-- 线性算术 + 假设
example (n : Nat) (h : n > 5) : n > 3 := by grind

-- 结合律这类等式
example (a b c : Nat) : a + (b + c) = a + b + c := by grind
```

这些目标过去要分别用 `simp`、`rw`、`congr`、`omega`、`ring` 组合，`grind` 往往一步搞定。
它的定位不是取代专用战术（`ring` 证环恒等式、`omega` 证 Presburger 算术仍更强更快），
而是兜底"混合了等式、量词、算术、命题结构"的杂糅目标。

## 44.6 grind 的用法与边界

```lean
-- grind 直接处理交换律（无需专用 ring）
example (a b : Nat) : a + b = b + a := by grind

-- grind 会用到上下文里的假设
example (a b : Nat) (h : a = b) : a + 1 = b + 1 := by grind
```

grind 也能接受额外的事实/实例作为参数（`grind [fact]`、`grind [= expr]` 等）来引导搜索；
当它失败时，通常退回更专用的战术（`ring`/`omega`/`simp`）或手工 `induction` 更稳。

| 目标形态 | 首选 | grind 是否合适 |
|---|---|---|
| 等式 + congruence + 量词杂糅 | `grind` | ✓ 强项 |
| 纯环恒等式 | `ring` | 可用但 `ring` 更专 |
| Presburger 算术（含 %、/） | `omega` | 部分（线性能做，取模弱） |
| 具体数值 | `norm_num`/`decide` | 不必 |
| 需要复杂归纳 | `induction` + 战术 | grind 有启发但非万能 |

`grind` 是 Lean 把"自动化"收归核心的标志：它和 `simp`（化简）、`omega`（算术）、`aesop`（搜索）一起，
构成现代 Lean 证明的自动化四件套。第19章的战术速查表应把它列为"等式+结构"类目标的首选。

> **版本提示**：`grind` 在 Lean 4.16+ 引入，4.34 已相当成熟，4.35 持续增强（更多 propagator、
> 与 `hint` 的集成）。本教程 `lean-toolchain` 标 v4.34.0，`grind` 可用；要体验最新特性可切到 4.35+。

---

> 上一章：[43 · 属性系统](43-attributes.md) ｜ 下一章：[30 · 附录：学习资源](30-appendix.md) ｜ 返回：[README](../README.md)
