# 37 · 可计算性

**对标**: *Theorem Proving in Lean 4* 第12章（Axioms and Computation）延伸；Mathlib `Computability/` 库。

第26章讲了 Lean 的公理与内核计算（`decide`、`#reduce`）。本章更进一步：Lean/Mathlib 能**形式化"可计算性"本身**——
把"什么是算法""哪个函数可计算""停机问题为何不可判定"变成可证明的数学定理。这是数理逻辑与计算机科学的交汇点。

> 本章依赖 Mathlib（`Part`、`Computability` 库），在 Mathlib4 v4.35.0-rc3 下验证。

## 37.1 Part：可能无定义的值

可计算性理论的核心对象是**偏函数**——可能不终止/无定义的函数。Mathlib 用 `Part α` 建模：
它不是一个"值或错误"的数据类型（那是 `Option`），而是**一个命题 `Dom`（是否有定义）加上"若有定义则取值"**：

```lean
import Mathlib.Data.Part
import Mathlib.Computability.Primrec.Basic
import Mathlib.Computability.Partrec
import Mathlib.Computability.Halting

open Part Nat

#check (Part Nat)        -- Part ℕ : Type
#check @Part.Dom         -- @Dom : {α} → Part α → Prop（"有定义"是个命题）
#check @Part.get         -- @Part.get : (self : Part α) → self.Dom → α（取值需 Dom 证明）
#check @Part.bind        -- @Part.bind : Part α → (α → Part β) → Part β
#check (inferInstance : Monad Part)   -- inferInstance : Monad Part（Part 是单子）
#check (Part.none : Part Nat)         -- Part.none : Part ℕ（处处无定义）
```

`Part α` 本质是 `Σ (p : Prop), p → α`（一个命题 + 一个"命题成立时给出值"的函数）。
`Part.get o h` 要从 `o` 取值，必须先给出 `h : o.Dom`（`o` 有定义的证明）——这把"是否终止"提升成了**逻辑命题**，
于是"函数在某点有定义"本身就能被证明或证伪。`Part` 是单子（`pure`/`bind`），记法 `α →. β` 表示 `Part`-值偏函数。

> **版本陷阱**：`Part` 在 **Mathlib**（`Mathlib.Data.Part`）里，**不在纯 Lean 核心**——
> 纯 Lean 4.34.1 下 `#check Part` 报 unknown identifier。这与 Lean 3 把 `Part` 放核心不同。

## 37.2 原始递归与部分递归

Mathlib 用**归纳谓词**定义"可计算函数"的层级，构造子就是计算的基本操作：

```lean
#check @Nat.Primrec    -- Nat.Primrec : (ℕ → ℕ) → Prop（原始递归的全函数）
#check @Nat.Partrec    -- Nat.Partrec : (ℕ →. ℕ) → Prop（部分递归的偏函数）

-- Nat.Primrec 是归纳谓词：zero、succ 是原始递归的，且对复合/原始递归封闭
example : Nat.Primrec (fun _ => 0) := Nat.Primrec.zero
example : Nat.Primrec Nat.succ := Nat.Primrec.succ
```

`Nat.Primrec` 的构造子（见 `Mathlib/Computability/Primrec/Basic.lean`）包括：常零函数、后继函数、
投影、复合（`comp`）、原始递归（`prec`）——这正是教科书里"原始递归函数"的归纳定义。
`Nat.Partrec` 在此基础上再加 **`rfind`（无界搜索 / μ-算子）**，得到"部分递归函数"，
即图灵可计算函数的等价刻画。

对任意"可编码"类型（`Primcodable`），有泛化版本：

```lean
#check @Partrec      -- @Partrec : [Primcodable α] → [Primcodable σ] → (α →. σ) → Prop
#check @Computable   -- @Computable : [Primcodable α] → [Primcodable σ] → (α → σ) → Prop
```

`Computable f`（全函数可计算）= `Partrec (pure ∘ f)`。`Primcodable α` 表示"`α` 的元素能与 `Nat` 互相可计算地编码"，
这是把可计算性从 `Nat` 推广到 `List`、`Bool`、乘积等类型的桥梁。

## 37.3 停机问题不可判定

可计算性理论的皇冠明珠——**停机问题**——在 Mathlib 里是一条定理。`eval c n` 表示"用编码 `c` 的程序跑输入 `n`"，
`(eval c n).Dom` 即"该计算终止"。则：

```lean
#check @ComputablePred.halting_problem
-- ComputablePred.halting_problem : ∀ (n : ℕ), ¬ComputablePred fun c => (c.eval n).Dom
```

读法：**对任何固定输入 `n`，"程序 `c` 在 `n` 上是否停机"这个谓词不是可计算谓词**。
证明走经典的对角线论证（构造一个"若停机则死循环"的程序）。配套的还有 **Rice 定理**：

```lean
#check @ComputablePred.rice
-- ComputablePred.rice : ∀ (C : Set (ℕ →. ℕ)), ComputablePred (fun c => c.eval ∈ C) →
--   ∀ {f g}, Nat.Partrec f → Nat.Partrec g → f ∈ C → g ∈ C
```

Rice 定理说：**偏函数任何"非平凡的语义性质"都不可判定**（停机问题只是它的一个特例）。
此外 `Mathlib/Computability/Halting.lean` 还给出 `halting_problem_re`（停机问题是 recursively enumerable，
即半可判定）和 `halting_problem_not_re`（其补不是 RE）——精确刻画了停机问题在算术层级中的位置。

> **意义**：这些定理把"计算机的根本局限"形式化为 Lean 内核检验过的数学事实。
> 它们依赖 `Mathlib/Computability/` 下的一整套机器：`Primcodable` 编码、`PartrecCode`、
> 通用部分递归函数 `eval`（`Nat.Partrec.Code` 的求值器）。`Mathlib/Computability/Ackermann.lean`
> 还证明了 **Ackermann 函数是部分递归但非原始递归的**——对应第36章 `ack` 那个双参数递归。

## 37.4 与证明的关系

可计算性理论在 Lean 里的地位很特殊：它既是**被形式化的数学对象**（上面的定理），
又是 Lean **自身的运作机制**（内核靠归约/计算来检验 `rfl`、`decide`，见第26章）。
`Part` 把"计算可能不终止"纳入逻辑，`Partrec`/`Computable` 把"算法"纳入数学，
于是"Lean 能证明关于它自己所基于的计算模型的定理"——这是依赖类型证明助手的一大魅力。

---

> 上一章：[36 · 归纳类型深入](36-inductive-deep.md) ｜ 下一章：[38 · 惰性求值](38-lazy-evaluation.md) ｜ 返回：[README](../README.md)
