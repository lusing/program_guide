# 36 · 归纳类型深入

**对标**: *Theorem Proving in Lean 4* 第7章（Inductive Types）；*Reference* 第13章（Terms）。

第4章介绍了归纳类型的基本用法。本章深入它的几种**进阶形态**：Prop-值的归纳谓词、
互递归（mutual）、嵌套（nested）、索引族，以及作为"万有归纳类型"的 W-type，
最后讲良基递归（`termination_by`）如何让 Lean 接受非结构递归。全部在纯 Lean 4.34.1 验证。

## 36.1 归纳谓词：Prop-值的归纳类型

当归纳类型的结果落在 `Prop` 里，它定义的是一个**谓词**，构造子就是"推理规则"。
这是数学中归纳定义关系（偶数、可证明性、良序、子群闭包……）的标准手段。

```lean
inductive Even : Nat → Prop
  | zero : Even 0
  | succ : ∀ n, Even n → Even (n + 2)

-- 构造证明：把推理规则当构造子用
example : Even 4 := Even.succ 2 (Even.succ 0 Even.zero)

-- 加 2 保持偶数（就是 succ 规则）
theorem Even.add_two {n : Nat} (h : Even n) : Even (n + 2) := Even.succ n h
```

`Even : Nat → Prop` 是一个**索引**归纳类型（index 是那个 `Nat`）。`zero`/`succ` 不是数据构造子，
而是两条公理式规则。对谓词做 `induction` 就是"按它的定义做结构归纳"：

```lean
-- 每个偶数都等于某个 k 的两倍
theorem Even.exists_double {n : Nat} (h : Even n) : ∃ k, n = 2 * k := by
  induction h with
  | zero => exact ⟨0, by simp⟩
  | succ m hm ih =>
    obtain ⟨k, hk⟩ := ih      -- ih : ∃ k, m = 2 * k
    exact ⟨k + 1, by omega⟩   -- m + 2 = 2 * (k + 1)
```

`induction h` 在 `succ` 分支给出前驱 `m`、归纳假设 `ih`，且因为索引是 `m + 2`，
目标自动变成关于 `m + 2` 的命题——这正是索引归纳的威力。消去用 `cases h`（反演）：
对 `Even (n+2)` 做 `cases` 只会留下 `succ` 分支，`zero` 分支因索引不匹配被自动排除。

## 36.2 互递归：mutual inductive / mutual def

两个类型互相引用时，用 `mutual ... end` 块把它们绑在一起定义：

```lean
mutual
inductive Ev where
  | zero : Ev
  | so : Od → Ev      -- 引用了 Od
inductive Od where
  | se : Ev → Od      -- 引用了 Ev
end

#check (Ev.so (Od.se Ev.zero))   -- Ev.so (Od.se Ev.zero) : Ev
```

函数也能互递归（`mutual def`），Lean 把它们合并成一个良基递归：

```lean
mutual
def isEven : Nat → Bool
  | 0 => true
  | n + 1 => isOdd n
def isOdd : Nat → Bool
  | 0 => false
  | n + 1 => isEven n
end

#eval (isEven 4, isOdd 4)   -- (true, false)
```

> **版本陷阱**：旧资料里的 `mutual inductive Ev, Od ... end`（逗号分隔多类型）**已不被接受**，
> 会报 "unexpected token ','"。现代语法是 `mutual` 块内写**独立的** `inductive X where ...` 声明。

## 36.3 嵌套归纳：构造子里含容器

构造子参数里出现 `List (Tree α)` 这类"类型函子套自身"的，叫嵌套归纳类型。
Lean 内部会把它编译成真正的归纳类型 + 一个映射，使结构递归照常可用：

```lean
inductive Tree (α : Type u) where
  | leaf : α → Tree α
  | node : List (Tree α) → Tree α     -- 嵌套：List of Tree

def Tree.size : Tree α → Nat
  | .leaf _ => 1
  | .node ts => ts.foldl (fun acc t => acc + t.size) 0

#eval Tree.size (Tree.node [Tree.leaf 1, Tree.node [Tree.leaf 2]])   -- 2
```

注意递归发生在 `List` 的元素上，所以要用 `List.foldl`/`List.map` 这类容器递归子去遍历——
不能像普通归纳类型那样直接 `match` 出"子树"。

## 36.4 W-type：万有归纳类型

W-type（Wellfounded tree）是**所有归纳类型的公分母**：任何"良基树状"数据都能编码成它。
它只有**一个**构造子 `sup`，用两个参数描述"节点标签"和"每个标签的子节点形状"。

> **版本陷阱**：Lean 4 **核心默认不提供** `W`/`WType`（`#check W` 报 unknown identifier）。
> 它在 Mathlib（`Mathlib.Data.WType` 一类）里；纯 Lean 环境下自己定义只需两行：

```lean
inductive W (α : Type u) (β : α → Type v) where
  | sup (a : α) (f : β a → W α β)
```

`α` 是标签类型（每个标签是一种构造子），`β a` 是标签 `a` 的"子节点索引类型"（arity）。
`sup a f` 表示"一个根标签为 `a`、第 `i` 个子树是 `f i` 的树"。

用它编码自然数（`zero` 无子节点 → arity `Empty`；`succ` 一个子节点 → arity `Unit`）：

```lean
def NatBeta (b : Bool) : Type := if b then Unit else Empty   -- false=zero, true=succ
abbrev NatW := W Bool NatBeta

def zeroW : NatW := W.sup false Empty.elim          -- arity 是 Empty，函数空定义
def succW (n : NatW) : NatW := W.sup true (fun _ => n)   -- arity 是 Unit，唯一子树是 n

#check (succW (succW zeroW))   -- succW (succW zeroW) : NatW
```

W-type 的意义在于：归纳类型的递归子（recursor）可以统一用 W-type 的良基递归导出，
这是依赖类型论里"归纳 = 良基树"这一视角的形式化。第25章的依赖类型、本章的良基递归都与此相通。

## 36.5 归纳族与索引（回顾深化）

索引归纳类型（inductive family）让构造子的**结果类型随索引变化**，从而把不变量编进类型：

```lean
inductive Vect (α : Type u) : Nat → Type u where
  | nil : Vect α 0
  | cons : α → Vect α n → Vect α (n + 1)

#check (Vect.cons 1 Vect.nil : Vect Nat 1)
-- Vect.cons 1 Vect.nil : Vect Nat (0 + 1)
```

注意 `#check` 显示的是 `Vect Nat (0 + 1)` 而非 `Vect Nat 1`：`cons` 的结果索引是 `n + 1`，
其中 `n = 0`（来自 `nil`），Lean 打印时**不自动归约** `0 + 1`（虽然它与 `1` 定义相等，类型标注 `: Vect Nat 1` 能通过）。
第25章会讲这种"索引算术"如何把长度约束变成编译期检查。

## 36.6 良基递归：termination_by 与 Acc

结构递归（每个递归调用都作用在更小的构造子上）Lean 自动接受。但很多自然递归不是结构的
（如 `div2 (n+2) = div2 n + 1` 跳两步、Ackermann 双参数）。这时用 `termination_by` 指定一个**递减的测度**，
Lean 用良基归纳验证终止：

```lean
def div2 : Nat → Nat
  | 0 => 0
  | 1 => 0
  | n + 2 => div2 n + 1
termination_by x => x          -- 测度：x 本身，每步严格减小
#eval div2 10   -- 5

def ack : Nat → Nat → Nat
  | 0, m => m + 1
  | n + 1, 0 => ack n 1
  | n + 1, m + 1 => ack n (ack (n + 1) m)
termination_by x y => (x, y)   -- 字典序测度：先比 x 再比 y
#eval ack 2 3   -- 9
```

当默认测度不够时，加 `decreasing_by` 手动给出"严格递减"的证明（常用 `omega`/`simp_arith`）。

良基递归的理论基础是 `Acc`（可及性）与 `WellFounded`：

```lean
#check @Acc
-- @Acc : {α : Sort u_1} → (α → α → Prop) → α → Prop
#check @WellFounded.fix
-- @WellFounded.fix : WellFounded r → ((x : α) → ((y : α) → r y x → C y) → C x) → (x : α) → C x

-- Nat 上 < 是良基的——这正是 termination_by 能通过的根据
example : WellFounded (· < · : Nat → Nat → Prop) := Nat.lt_wfRel.wf
```

`Acc r a` 意为"`a` 在关系 `r` 下可及"（`a` 的所有 `r`-前驱都可及）。`WellFounded r` 即"所有元素都可及"，
它给出的 `WellFounded.fix` 就是良基递归子——`termination_by` 本质上是在帮你构造一个 `Acc` 证明。
理解这一点，就理解了为什么 Lean 能"相信"一个非结构递归会终止。

---

> 上一章：[35 · conv 转换战术](35-conv.md) ｜ 下一章：[37 · 可计算性](37-computability.md) ｜ 返回：[README](../README.md)
