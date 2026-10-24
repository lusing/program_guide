import Mathlib.SetTheory.Ordinal.Arithmetic
import Mathlib.SetTheory.Ordinal.CantorNormalForm
import Mathlib.SetTheory.Ordinal.Enum
import Mathlib.SetTheory.Ordinal.FixedPoint
import Mathlib.SetTheory.Ordinal.Veblen
import Mathlib.Tactic

open scoped Ordinal
open Order

/-!
# 第 72 章 · 秩序与序数算术（冯琦 §1.8.1-1.8.3）

序数算术的官方锚点全家桶：命题 1.25/1.26 的三款递归式、不可交换
三见证（1+ω = ω < ω+1、2·ω = ω < ω·2、右分配律失效）、康托尔
范式（定理 1.80 的 `Ordinal.CNF`）、正规函数不动点定理（定理
1.74 的 `nfp`/`not_bddAbove_fp`）与 ε₀（`epsilon_zero_eq_nfp`）。
雪崩映射（定义 1.71）落在 `Ordinal.enumOrd` 一族上。
-/

namespace Settheory.Ch72

-- ---------- 命题 1.25/1.26：三款递归式 ----------

/-- 加法的零款与后继款。`Ordinal.add_succ` 已弃用——α+(β+1) =
(α+β)+1 恰是 `add_assoc`（Ordinal 有 `AddMonoidWithOne` 实例，
根命名空间的引理直接可用；注意方向：add_assoc 是 (a+b)+c →
a+(b+c)，书的后继款要取 .symm）。 -/
example (a : Ordinal) : a + 0 = a := add_zero a

example (a b : Ordinal) : a + (b + 1) = a + b + 1 := (add_assoc a b 1).symm

/-- 乘法的后继款 α·(β+1) = α·β + α——左分配律 `mul_add` 加
`mul_one`。 -/
example (a b : Ordinal) : a * (b + 1) = a * b + a := by
  rw [mul_add, mul_one]

/-- 极限款的代表：n + ω = ω（左加被极限吞并）。 -/
example (n : ℕ) : (n : Ordinal) + ω = ω := Ordinal.natCast_add_omega0 n

-- ---------- 不可交换三见证 ----------

/-- 见证一：1 + ω = ω。 -/
theorem one_add_omega : (1 : Ordinal) + ω = ω := Ordinal.one_add_omega0

/-- 见证一的另一侧：ω < ω + 1——不塌缩。
（点记号被 Quot 头部劫持，`Order.succ` 须写全。） -/
theorem omega_lt_omega_add_one : ω < ω + 1 :=
  Order.lt_succ_iff.2 le_rfl

/-- 见证二：2 · ω = ω——水平排 ω 条两元素线仍是一条 ω
（命题 1.26 的官方化身 `natCast_mul_omega0`；显式 ↑2 避开
数字/转换的 defeq 泥潭——B1 实测 rfl 对 (2:Ordinal) = 1+1 失败）。 -/
theorem two_mul_omega : ((2 : ℕ) : Ordinal) * ω = ω :=
  Ordinal.natCast_mul_omega0 (by norm_num)

/-- 数字 2 与 succ 1 的互认：2 与 1+1 之间必须走 `one_add_one_eq_two`
（B1 实测：正向 rfl 不成立），而 1+1 = succ 1 由 rfl 收尾——rw 的
自动 rfl 只在较弱透明度上尝试，须显式补 rfl。 -/
private theorem two_eq_succ_one : (2 : Ordinal) = Order.succ 1 := by
  rw [← one_add_one_eq_two]
  rfl

/-- ω · 2 = ω + ω：`mul_succ` 拆开后两项归位。 -/
theorem omega_mul_two : ω * 2 = ω + ω := by
  rw [two_eq_succ_one, Ordinal.mul_succ, mul_one]

/-- 见证二的反侧：ω < ω · 2。 -/
theorem omega_lt_omega_mul_two : ω < ω * 2 := by
  rw [omega_mul_two]
  have h : ω + 0 < ω + ω := (add_lt_add_iff_left ω).2 Ordinal.omega0_pos
  rwa [add_zero] at h

/-- 见证三：右分配律失效——(ω+1)·(1+1) = ω·(1+1)+1 ≠
ω·(1+1)+1·(1+1)。乘开左项：吸收链 (ω+1)+(ω+1) = ω+(1+(ω+1)) =
ω+((1+ω)+1) = ω+(ω+1) = (ω+ω)+1——1+ω = ω 在中段吞并。 -/
theorem no_right_distrib :
    (ω + 1) * (1 + 1) ≠ ω * (1 + 1) + (1 : Ordinal) * (1 + 1) := by
  have step1 : (ω + 1) * (1 + 1) = (ω + 1) + (ω + 1) := by
    rw [show (1 : Ordinal) + 1 = Order.succ 1 from rfl, Ordinal.mul_succ, mul_one]
  have lhs : (ω + 1) * (1 + 1) = ω * (1 + 1) + 1 := by
    rw [step1]
    calc (ω + 1) + (ω + 1) = ω + (1 + (ω + 1)) := add_assoc ω 1 (ω + 1)
      _ = ω + ((1 + ω) + 1) := by rw [add_assoc]
      _ = ω + (ω + 1) := by rw [Ordinal.one_add_omega0]
      _ = (ω + ω) + 1 := (add_assoc ω ω 1).symm
      _ = ω * (1 + 1) + 1 := by
          rw [show ω * (1 + 1) = ω * Order.succ 1 from rfl, Ordinal.mul_succ,
            mul_one]
  have rhs : (1 : Ordinal) * (1 + 1) = 1 + 1 := by rw [one_mul]
  rw [lhs, rhs, ← add_assoc]
  -- 右侧 ≡ succ(ω·(1+1)+1)：后继严格增大（succ ≡ +1 是 rfl 级）
  exact ne_of_lt (Order.lt_succ_iff.2 le_rfl)

-- ---------- 运算律（定理 1.75/1.76 官方形态） ----------

example (a b c : Ordinal) : (a + b) + c = a + (b + c) := add_assoc a b c

/-- 左分配律成立（`LeftDistribClass Ordinal` 实例）。 -/
example (a b c : Ordinal) : a * (b + c) = a * b + a * c := mul_add a b c

/-- 乘法结合律（`Monoid Ordinal` 实例——注意没有交换律实例）。 -/
example (a b c : Ordinal) : (a * b) * c = a * (b * c) := mul_assoc a b c

-- ---------- 定理 1.80：康托尔范式的官方化身 ----------

/-- `Ordinal.CNF ω o` 把 o 分解成指数-系数表；`eval ∘ coeff`
重构出 o——范式的存在性。 -/
theorem cnf_reconstruct (o : Ordinal) :
    Ordinal.CNF.eval ω (Ordinal.CNF.coeff ω o) = o :=
  Ordinal.CNF.eval_coeff ω o

/-- 范式的唯一性：系数函数单射。 -/
theorem cnf_unique (x y : Ordinal) :
    Ordinal.CNF.coeff ω x = Ordinal.CNF.coeff ω y ↔ x = y :=
  Ordinal.CNF.coeff_inj

/-- 系数是自然数：CNF 表中每项的第二分量 < ω（0 < kᵢ < ω）。 -/
example {x : Ordinal × Ordinal} (h : x ∈ Ordinal.CNF ω (ω * 2 + 3)) :
    x.2 < ω :=
  Ordinal.CNF.snd_lt Ordinal.one_lt_omega0 h

-- ---------- 定义 1.71：雪崩映射/自然列表的官方化身 ----------

section EnumOrd

variable {s : Set Ordinal} (hs : ¬BddAbove s)

/-- 无界序数集 s 的自然列表：`enumOrd s` 从第 0 项起按 ∈-序
枚举 s（贪心取最小）。 -/
example : StrictMono (Ordinal.enumOrd s) := Ordinal.enumOrd_strictMono hs

/-- 列表恰好吃满 s：值域 = s。 -/
example : Set.range (Ordinal.enumOrd s) = s := Ordinal.range_enumOrd hs

/-- 引理 1.13 的影子：自然列表处处 ≥ 恒等——雪崩序不小于
自然序。 -/
example : id ≤ Ordinal.enumOrd s := Ordinal.id_le_enumOrd hs

end EnumOrd

-- ---------- 定理 1.74：正规函数的不动点定理 ----------

/-- 三条装配线都是正规函数（严格单增 + 极限连续）。 -/
example (a : Ordinal) : IsNormal (a + ·) := Ordinal.isNormal_add_right a

example {a : Ordinal} (h : 0 < a) : IsNormal (a * ·) :=
  Ordinal.isNormal_mul_right h

/-- ω 幂的正规性（取 a := ω，侧条件 1 < ω 即 `one_lt_omega0`）。
⚠️ 不能写 `IsNormal (a ^ ·)`：匿名洞 `·` 被贪婪定型为 ℕ，`^` 于是
解析成 Monoid 的 npow（指数 ℕ）而非 Ordinal.opow——宇宙签名
{0, u+1} 的分裂就是这么来的。显式 `fun x : Ordinal =>` 钉死指数
类型。 -/
example {a : Ordinal} (h : 1 < a) : IsNormal (fun x : Ordinal => a ^ x) :=
  Ordinal.isNormal_opow h

/-- 不动点的构造：从种子 a 迭代 f 共 ω 次取 sup，`nfp f a` 是
≥ a 的最小不动点（f (nfp f a) = nfp f a）。 -/
example (f : Ordinal → Ordinal) (H : IsNormal f) (a : Ordinal) :
    f (Ordinal.nfp f a) = Ordinal.nfp f a :=
  Ordinal.nfp_fp H a

/-- nfp 就是 ω-迭代的 sup——书页"β_{n+1} = f(β_n)、λ = sup_n β_n"
的逐字官方版。 -/
example (f : Ordinal → Ordinal) (a : Ordinal) :
    ⨆ n : ℕ, f^[n] a = Ordinal.nfp f a :=
  Ordinal.iSup_iterate_eq_nfp f a

/-- 不动点集无界：定理 1.74 的 club 之"无界"半（闭性由连续性
自动持有，`IsNormal` 定义即含极限连续）。 -/
example (f : Ordinal → Ordinal) (H : IsNormal f) :
    ¬BddAbove (Function.fixedPoints f) :=
  Ordinal.not_bddAbove_fp H

/-- ε₀ = ω^ε₀：α ↦ ω^α 的第一个不动点，推论 1.11 的官方化身。 -/
theorem omega_opow_epsilon : (ω : Ordinal) ^ ε₀ = ε₀ := by
  rw [Ordinal.epsilon_zero_eq_nfp]
  exact Ordinal.nfp_fp (Ordinal.isNormal_opow Ordinal.one_lt_omega0) 0

/-- ε₀ 的最小性：任何满足 ω^o ≤ o 的 o 都 ≥ ε₀。 -/
example (o : Ordinal) (h : (ω : Ordinal) ^ o ≤ o) : ε₀ ≤ o :=
  Ordinal.epsilon_zero_le_of_omega0_opow_le h

end Settheory.Ch72
