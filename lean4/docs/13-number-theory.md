# 13 · 数论

> 对应示例：`examples/10_mathlib_number_theory/number_theory.lean`

本章源码坐标：`Mathlib/Data/Nat/GCD/Basic.lean`（gcd）、`Mathlib/Data/Nat/Prime/Defs.lean`（素数定义）、`Mathlib/Data/Nat/ModEq.lean`（同余）、`Mathlib/Data/ZMod/`（模 n 环）、`Mathlib/FieldTheory/Finite/Basic.lean`（费马-欧拉定理）。

## 13.1 整除性

`a ∣ b` 是代数层级的通用关系（`Mathlib/Algebra/Divisibility/Basic.lean`），不只是 Nat 的：

```lean
import Mathlib.Data.Nat.GCD.Basic

-- ∣ 的类型类签名：Dvd.dvd {α : Type u} → α → α → Prop
#check ((2 : ℕ) ∣ 6)              -- Prop
#eval decide ((2 : ℕ) ∣ 6)        -- true（Prop 用 decide 求值，#eval 不能直接算命题）

-- 通用整除引理（所有幺半群可用）：
example {α : Type} [Monoid α] (a : α) : a ∣ a := dvd_refl a
example {α : Type} [Monoid α] {a b c : α} (h1 : a ∣ b) (h2 : b ∣ c) : a ∣ c := dvd_trans h1 h2

-- Nat 上的等价刻画（注意方向：b = c * a，Divisibility/Basic.lean:224）
example {a b : ℕ} : a ∣ b ↔ ∃ c : ℕ, b = c * a := dvd_iff_exists_eq_mul_left

-- Nat.dvd_add_iff_right 已并入 Lean 核心（Init/Data/Nat/Dvd.lean）：
-- k ∣ m → (k ∣ n ↔ k ∣ m + n)
example {a b c : ℕ} (h : a ∣ b) (h' : a ∣ b + c) : a ∣ c := (Nat.dvd_add_iff_right h).mpr h'
```

**命名观察**：`dvd_rfl` 是 `dvd_refl` 在 `Prop` 反射风格下的别名（`Mathlib/Algebra/Divisibility/Basic.lean:173`）。mathlib 里 `X_rfl`/`X_refl` 成对出现很常见。

## 13.2 最大公约数与互素

```lean
import Mathlib.Data.Nat.GCD.Basic

#eval Nat.gcd 12 8     -- 4

-- 核心 API（Nat 命名空间，点号记法驱动）
example (m n : ℕ) : Nat.gcd m n ∣ m := Nat.gcd_dvd_left m n
example (m n : ℕ) : Nat.gcd m n ∣ n := Nat.gcd_dvd_right m n
example {m n k : ℕ} (h1 : k ∣ m) (h2 : k ∣ n) : k ∣ Nat.gcd m n := Nat.dvd_gcd h1 h2

-- 欧几里得算法的形式化副产品：gcd 展开
#eval Nat.gcd 1071 462    -- 21

-- 互素：Nat.Coprime m n ↔ gcd m n = 1（Mathlib/Data/Nat/GCD/Basic.lean）
example : Nat.Coprime 8 15 := by decide
example {m n : ℕ} : Nat.Coprime m n ↔ Nat.gcd m n = 1 := Nat.coprime_iff_gcd_eq_one

-- 互素与整除（欧几里得引理的 Nat 形式）
example {p m n : ℕ} (hp : Nat.Coprime p m) (h : p ∣ m * n) : p ∣ n :=
  Nat.Coprime.dvd_of_dvd_mul_left hp h
```

## 13.3 素数

`Nat.Prime` 定义在 `Mathlib/Data/Nat/Prime/Defs.lean:42`，本质是"≥2 且因子只有 1 和自身"，内部基于 `_root_.Prime`（不可约元）。

```lean
import Mathlib.Data.Nat.Prime.Basic

-- 判定走 Decidable 实例
example : Nat.Prime 7 := by decide
example : ¬ Nat.Prime 10 := by decide

-- 等价刻画（prime_def_lt 系列）
example {p : ℕ} : Nat.Prime p ↔ 2 ≤ p ∧ ∀ m < p, m ∣ p → m = 1 := Nat.prime_def_lt

-- 素数的核心性质：p ∣ a*b → p ∣ a ∨ p ∣ b（点号记法）
example {p a b : ℕ} (hp : Nat.Prime p) : p ∣ a * b ↔ p ∣ a ∨ p ∣ b := hp.dvd_mul

-- 最小因子：minFac（Euclid 证明的引擎，见 13.6）
#eval Nat.minFac 15    -- 3
example {n : ℕ} (h : n ≠ 1) : Nat.Prime (Nat.minFac n) := Nat.minFac_prime h
```

## 13.4 模运算：Nat.ModEq 与 ZMod

mathlib 有**两套**模运算 API，风格迥异：

**`Nat.ModEq`**（`Mathlib/Data/Nat/ModEq.lean`）：命题风格，`a ≡ b [MOD n]` 是 Prop：

```lean
import Mathlib.Data.Nat.ModEq

example : 5 ≡ 2 [MOD 3] := by decide

-- 核心刻画（注意 13.x 版本是 Int 整除）
example {a b n : ℕ} : a ≡ b [MOD n] ↔ (n : ℤ) ∣ (b : ℤ) - a := Nat.modEq_iff_dvd

-- 同余是 congruence：保持加减乘幂
example {a b c d n : ℕ} (h1 : a ≡ b [MOD n]) (h2 : c ≡ d [MOD n]) :
    a + c ≡ b + d [MOD n] := h1.add h2
example {a b c d n : ℕ} (h1 : a ≡ b [MOD n]) (h2 : c ≡ d [MOD n]) :
    a * c ≡ b * d [MOD n] := h1.mul h2
```

**`ZMod n`**（`Mathlib/Data/ZMod/Basic.lean`）：类型风格，`ZMod n` 是**真正的环**，p 素数时是**域**：

```lean
import Mathlib.Data.ZMod.Basic
import Mathlib.Algebra.Field.ZMod     -- Field (ZMod p) 实例（ZMod.lean:30）

-- ZMod 里等式就是同余，环战术直接可用
example : (5 : ZMod 3) = 2 := by decide
example (x y : ZMod 7) : (x + y)^2 = x^2 + 2*x*y + y^2 := by ring

-- p 素数时 ZMod p 是域：逆元、除法、field_simp 全套可用
example [Fact (Nat.Prime 7)] (x : ZMod 7) (hx : x ≠ 0) : x * x⁻¹ = 1 :=
  mul_inv_cancel₀ hx

-- ZMod 与 ModEq 的互转
example {a b n : ℕ} : a ≡ b [MOD n] ↔ (a : ZMod n) = (b : ZMod n) :=
  (ZMod.natCast_eq_natCast_iff a b n).symm
```

**实践建议**：需要"环结构 + 自动化"时用 ZMod；需要在 Nat 不等式/整除链里穿插时用 ModEq。mathlib 证明数论定理时两者都常见。

## 13.5 费马小定理与欧拉定理

源码：`Mathlib/FieldTheory/Finite/Basic.lean`（不是 `Mathlib/NumberTheory/Fermat.lean`——那是**费马数**！名字陷阱）。

```lean
import Mathlib.FieldTheory.Finite.Basic
import Mathlib.Data.Nat.ModEq

-- 欧拉定理（Nat.ModEq.pow_totient，Basic.lean:563）：
-- φ n 是 Euler totient，记法源自 scoped 打开 Nat
open Nat in
example {x n : ℕ} (h : Nat.Coprime x n) : x ^ φ n ≡ 1 [MOD n] :=
  Nat.ModEq.pow_totient h

-- 费马小定理（ZMod 版，Basic.lean:611）：
example {p : ℕ} [Fact p.Prime] {a : ZMod p} (ha : a ≠ 0) : a ^ (p - 1) = 1 :=
  ZMod.pow_card_sub_one_eq_one ha

-- 推论：a^p ≡ a (mod p)（含 a = 0 情形）
example {p : ℕ} [Fact p.Prime] (a : ZMod p) : a ^ p = a :=
  ZMod.pow_card a
```

## 13.6 经典证明案例一：素数无穷多（Euclid）

mathlib 的证明在 `Mathlib/Data/Nat/Prime/Infinite.lean:35`，只有约 10 行，核心引擎是 `Nat.minFac`（最小因子函数）：

```lean
import Mathlib.Data.Nat.Prime.Infinite

-- 定理本身
#check Nat.exists_infinite_primes
-- ∀ (n : ℕ), ∃ p, n ≤ p ∧ Nat.Prime p

-- mathlib 的证明骨架（可直接编译）：
-- 注意阶乘后缀记法 n ! 需要 open Nat
open Nat in
theorem euclid_demo (n : ℕ) : ∃ p, n ≤ p ∧ Nat.Prime p :=
  let p := Nat.minFac (n ! + 1)        -- 取 n!+1 的最小素因子
  have f1 : n ! + 1 ≠ 1 := ne_of_gt <| Nat.succ_lt_succ <| Nat.factorial_pos _
  have pp : Nat.Prime p := Nat.minFac_prime f1
  have np : n ≤ p :=
    Nat.le_of_not_ge fun h =>
      have h₁ : p ∣ n ! := Nat.dvd_factorial (Nat.minFac_pos _) h
      have h₂ : p ∣ 1 := (Nat.dvd_add_iff_right h₁).2 (Nat.minFac_dvd _)
      pp.not_dvd_one h₂
  ⟨p, np, pp⟩
```

**读法**：设 `p = minFac(n!+1)`。若 `p ≤ n`，则 `p ∣ n!`（`Nat.dvd_factorial`）；又 `p ∣ n!+1`（minFac 整除目标），故 `p ∣ 1`，与 `p` 素矛盾。

## 13.7 经典证明案例二：√2 是无理数

源码：`Mathlib/NumberTheory/Real/Irrational.lean:144`。mathlib 走的是**更一般的定理**路线：

```lean
import Mathlib.NumberTheory.Real.Irrational

-- 一般定理：n 不是完全平方 ⟺ √n 无理
#check @irrational_sqrt_natCast_iff
-- {n : ℕ} → (Irrational √↑n ↔ ¬IsSquare n)

-- 素数推出非平方：
#check @Nat.Prime.irrational_sqrt
-- {p : ℕ} → Nat.Prime p → Irrational √↑p

-- √2 无理：一行组装
theorem irrational_sqrt_two' : Irrational √2 := by
  simpa using Nat.prime_two.irrational_sqrt

-- 甚至可以直接 decide（库提供了 Decidable 实例；
-- 但 Nat.sqrt.iter 是 sealed 的，需 unseal 才能算出值）
unseal Nat.sqrt.iter in
example : Irrational √24 := by decide
```

**对比教科书证明**（"设 √2 = p/q 最简，则 p²=2q²，2∣p，矛盾"）：mathlib 的版本把这个论证抽象成了 `IsSquare` 与 `Irrational` 的一般理论——这是 mathlib 的典型美学：**不为单个定理写证明，为定理的"一般形式"建 API**。

## 13.8 唯一分解

`UniqueFactorizationMonoid`（`Mathlib/RingTheory/UniqueFactorizationDomain/`）给出任意 UFD 的分解理论；Nat 的具体 API 在 `Mathlib/Data/Nat/Factorization/Basic.lean`：

```lean
import Mathlib.Data.Nat.Factorization.Basic

-- n.factorization：ℕ →₀ ℕ（有限支撑的素因子指数函数）
#eval (60 : ℕ).factorization 2    -- 2（60 = 2²·3·5）
#eval (60 : ℕ).factorization 3    -- 1

-- 支撑集是素因子集合
#eval (60 : ℕ).primeFactors       -- {2, 3, 5}（Finset）

-- 乘积重构（Factorization/Defs.lean:96；旧名 factorization_prod_pow_eq_self 已废弃）
example (n : ℕ) (hn : n ≠ 0) : n.factorization.prod (· ^ ·) = n :=
  Nat.prod_factorization_pow_eq_self hn
```

---

> 上一章：[12 · 代数结构](12-algebra.md) ｜ 下一章：[14 · 实分析](14-analysis.md) ｜ 返回：[README](../README.md)
