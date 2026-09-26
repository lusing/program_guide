# 04 · 归纳类型

> 对应示例：`examples/02_inductive_types/inductive_types.lean`

归纳类型是 Lean 数据与命题的统一构造方式。核心源码位置：`Init/Prelude.lean`（Nat/Bool/Prod/Sum 等）、`Init/Data/List/Basic.lean`、`Init/Data/Option/Basic.lean`。

## 4.1 枚举类型

```lean
inductive Weekday where
  | monday | tuesday | wednesday | thursday | friday | saturday | sunday
  deriving Repr, DecidableEq   -- 自动生成打印与可判定相等实例

#check Weekday.monday   -- Weekday
#eval Weekday.friday    -- Weekday.friday
#eval Weekday.friday == Weekday.monday   -- false（DecidableEq 生效）
```

## 4.2 参数化归纳类型

```lean
-- Option：可能有值（some）也可能没有（none）——替代 null 的函数式方案
-- 真实定义在 Init/Prelude.lean：
-- inductive Option (α : Type u) where | none | some (val : α)

#check (some 5 : Option Nat)    -- Option Nat
#check (none : Option Nat)      -- Option Nat

-- Option 的核心 API（Init/Data/Option/Basic.lean）
#eval (some 3).getD 0        -- 3（带默认值取出）
#eval (none : Option Nat).getD 0   -- 0
#eval (some 3).map (· * 2)   -- some 6
#eval (some 3).isSome        -- true

-- Option 在工程上的意义：把"可能失败"显式编码进类型
def head? {α : Type} : List α → Option α
  | []    => none
  | x::_  => some x
#eval head? [1, 2, 3]        -- some 1
#eval head? ([] : List Nat)  -- none
```

## 4.3 递归归纳类型与自动生成的递归子

```lean
-- 手写自然数（Init/Prelude.lean 中 Nat 的定义与此相同）
inductive MyNat where
  | zero : MyNat
  | succ : MyNat → MyNat
  deriving Repr

-- 每个归纳类型自动生成一个"递归子/消去子"（recursor），它是归纳原理：
-- MyNat.rec : {motive : MyNat → Sort u} →
--   motive MyNat.zero →
--   ((n : MyNat) → motive n → motive n.succ) →
--   (t : MyNat) → motive t
-- 这就是数学归纳法/结构递归的**类型化表达**：给一个零的情形、
-- 一个后继情形的"构造步骤"，就得到对所有 MyNat 的函数/证明。

-- 用递归子直接定义加法（了解原理即可，实战用 match/等式编译器）
-- 注意：裸递归子没有代码生成支持，需标 noncomputable，演示用 #reduce 而非 #eval
noncomputable def myAdd : MyNat → MyNat → MyNat :=
  fun m => MyNat.rec (motive := fun _ => MyNat)
    m (fun _ ih => MyNat.succ ih)

open MyNat in
#reduce myAdd (succ (succ zero)) (succ zero)   -- MyNat.succ (succ (succ zero))
```

## 4.4 参数 vs 索引

这是归纳类型最重要的设计区分（以 `MyVec` 为例）：

```lean
inductive MyVec (α : Type) : Nat → Type where
  | nil  : MyVec α 0
  | cons : α → MyVec α n → MyVec α (n + 1)
```

- **参数** `α`：所有构造子共用，不出现在每个构造子的返回类型变化中（写在冒号左边）
- **索引** `Nat`：每个构造子可以返回**不同**索引的实例（写在冒号右边）

判断法则：如果某个"类型变量"在不同构造子的返回值里取不同的具体值，它必须是索引。

```lean
#check MyVec.nil                        -- MyVec α 0
#check MyVec.cons 1 MyVec.nil           -- MyVec Nat 1

-- 安全索引访问：Fin n 是"小于 n 的自然数"，越界在类型层面就被排除
def vGet {α : Type} {n : Nat} (v : MyVec α n) (i : Fin n) : α :=
  match v, i with
  | MyVec.cons x _,  ⟨0, _⟩    => x
  | MyVec.cons _ xs, ⟨k+1, hk⟩ => vGet xs ⟨k, Nat.lt_of_succ_lt_succ hk⟩
```

## 4.5 归纳命题（inductive Prop）

归纳类型不止能造数据，还能造**命题**——这是 Mathlib 中大量定义（Even、Nat.Prime 的辅助、`IsOpen` 内部、关系闭包等）的基础：

```lean
-- 偶数的归纳定义
inductive Even : Nat → Prop where
  | zero : Even 0
  | add2 : Even n → Even (n + 2)

example : Even 4 := Even.add2 (Even.add2 Even.zero)

-- 互指归纳（mutual）：偶数/奇数互相定义
mutual
  inductive Even' : Nat → Prop where
    | zero : Even' 0
    | succ : Odd' n → Even' (n + 1)
  inductive Odd' : Nat → Prop where
    | succ : Even' n → Odd' (n + 1)
end

example : Odd' 3 := Odd'.succ (Even'.succ (Odd'.succ Even'.zero))
```

## 4.6 deriving：自动派生实例

`deriving` 让编译器自动实现常用类型类（`Init/Prelude.lean` 及 `Lean/Elab/Deriving/`）：

```lean
inductive Color where
  | red | green | blue
  deriving Repr, DecidableEq, BEq, Inhabited, Ord, Hashable

#eval Color.red                      -- Color.red（Repr）
#eval Color.red == Color.blue        -- false（BEq）
#eval (default : Color)              -- Color.red（Inhabited：默认取第一个构造子）
#eval compare Color.red Color.blue   -- Ordering.lt（Ord：按构造子顺序）
#eval hash Color.green               -- 哈希值（Hashable）

-- 结构类型也能 deriving（第9章），还可以自定义 deriving handler
```

常用派生：`Repr`（打印）、`DecidableEq`（相等可判定，启用 `==` 和 decide）、`Inhabited`（默认值）、`Ord`（排序）、`Hashable`（哈希）、`ToJson`/`FromJson`（Batteries 提供）。

---

> 上一章：[03 · 依赖类型与宇宙](03-universes.md) ｜ 下一章：[05 · 模式匹配与递归](05-pattern-matching.md) ｜ 返回：[README](../README.md)
