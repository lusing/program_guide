/- ============================================================
   11 Π 与枚举集合（Nordström ch.6–7）—— Lean 侧
   空/单/双元素集合：⊥、⊤、Bool —— case 分析即消去子
   ============================================================ -/

/- ---------- 空集合 ⊥（Nordström 6.1 永假） ---------- -/

inductive Empty2 where

/-- 空集合的消去子：从空集合到任何类型（爆炸原理的原型） -/
def absurdE {A : Sort u} : Empty2 → A
  | e => nomatch e

/-- 逻辑否定 -/
def Not2 (A : Type) : Type := A → Empty2

/- ---------- 单元素集合 ⊤（6.2 真） ---------- -/

inductive Unit2 where
  | star : Unit2

/-- 单元素集合的消去子平凡：一切目标都能由 star 打发 -/
def unitElim {A : Sort u} (a : A) : Unit2 → A
  | .star => a

/- ---------- Bool（6.3） ---------- -/

inductive Bool2 where
  | true2 | false2

/-- if-then-else 即 Bool 的消去子 -/
def if2 {A : Sort u} (b : Bool2) (t e : A) : A :=
  match b with
  | .true2 => t
  | .false2 => e

def not2 : Bool2 → Bool2 := fun b => if2 b .false2 .true2
def and2 : Bool2 → Bool2 → Bool2 := fun a b => if2 a b .false2
def or2  : Bool2 → Bool2 → Bool2 := fun a b => if2 a .true2 b

/- ---------- case 分析的完备性 = 消去子的全部 ---------- -/

example : not2 .true2 = .false2 := rfl
example : and2 .true2 .false2 = .false2 := rfl
example : or2 .false2 .true2 = .true2 := rfl

-- 德摩根一条（四例 case 全自动）
example (a b : Bool2) : not2 (and2 a b) = or2 (not2 a) (not2 b) := by
  cases a <;> cases b <;> rfl

/- ---------- 构造子可分辨（判别性的机器面） ---------- -/

/-- true ≠ false：假设相等，沿等式搬运 true≠true 的证据 -/
def trueNeFalse : (.true2 : Bool2) = .false2 → Empty := fun h =>
  Bool2.noConfusion h

/-- 布尔的两个构造子把 Bool2 分成两半：0/2 ↔ 2/2 ——
    Nordström 的 Bool 规则（case 完备 + 构造子互斥） -/
def bool2Cases {P : Bool2 → Sort u}
    (pt : P .true2) (pf : P .false2) : (b : Bool2) → P b
  | .true2 => pt
  | .false2 => pf

/- ---------- Π 类型的再强调（7 章 Cartesian product of families） ---------- -/

/-- Π (b : Bool2). P b：双元素上的依赖函数 = 一对分量 -/
def bothCases (P : Bool2 → Type) (pt : P .true2) (pf : P .false2)
    : (b : Bool2) → P b := bool2Cases pt pf

-- 用一例：每个 Bool2-族上的选择函数
#check bothCases (fun b => if2 b Nat Int) (1 : Nat) (2 : Int)
-- 类型 (b : Bool2) → if2 b Nat Int —— 依赖函数的类型随 b 变

