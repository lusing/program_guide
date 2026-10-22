import Mathlib.Data.Nat.GCD.Basic
import Mathlib.Data.Nat.Prime.Defs
import Mathlib.Data.Nat.Prime.Infinite
import Mathlib.Tactic

/-!
# 第 69 章 · 有限与无限、整数与有理数（冯琦 §1.3.5 + §1.4）

典型序的"正方形式"配对（定义 1.33 / 定理 1.25(4)）；奇偶析因配对
J（命题 1.10(2)）；欧几里得素数定理与最小素因子的官方锚点；
贝祖表示（定理 1.34 的 gcdA/gcdB 形态）。
-/

namespace Settheory.Ch69

-- ---------- 典型序：层 = max，上边界 < 右边界（定义 1.33） ----------

/-- gtyp(a,b)：点 (a,b) 在典型序中的名次——第 k=max 层从 k² 起，
上边界（a<b）占前 b 个位置，右边界（a≥b）随后。 -/
def gtyp (a b : ℕ) : ℕ := if a < b then b * b + a else a * a + a + b

-- 螺旋次序抽样（定理 1.25(4) 的 g 在 0..3 层的取值）
example : [gtyp 0 0, gtyp 0 1, gtyp 1 0, gtyp 1 1, gtyp 0 2, gtyp 1 2,
    gtyp 2 0, gtyp 2 1, gtyp 2 2, gtyp 0 3] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] := by
  decide

/-- g 在 5×5 网格上是单射且落在 0..24 内（决定性验证）——
定理 1.25(4) 的有限影子。 -/
example : (((List.range 25).map (fun i => gtyp (i / 5) (i % 5))).eraseDups.length = 25
    ∧ ((List.range 25).map (fun i => gtyp (i / 5) (i % 5))).all (· < 25)) := by
  decide

-- ---------- 奇偶析因配对 J（命题 1.10(2)：J(m,n) = 2^m(2n+1) − 1） ----------

def jpair (m n : ℕ) : ℕ := 2 ^ m * (2 * n + 1) - 1

example : [jpair 0 0, jpair 1 0, jpair 0 1, jpair 2 0, jpair 1 1] = [0, 1, 2, 3, 5] := by
  decide

/-- 2-adic 赋值（燃料版）：v2 n = n 中因子 2 的重数。
Nat.factorization 是 Finsupp 构造——kernel 不可约，decide 一律卡死；
手写除二循环即可全核可算。 -/
def v2aux : ℕ → ℕ → ℕ
  | 0, _ => 0
  | _ + 1, 0 => 0
  | fuel + 1, n + 1 => if (n + 1) % 2 = 0 then 1 + v2aux fuel ((n + 1) / 2) else 0

def v2 (n : ℕ) : ℕ := v2aux n n

/-- J 的逆：m = 2-adic 赋值（J+1 的因子 2 的重数），n = 去幂后减一除二 -/
def junpair (j : ℕ) : ℕ × ℕ :=
  (v2 (j + 1), ((j + 1) / 2 ^ v2 (j + 1) - 1) / 2)

-- 往返恒等（0..99 全检）：J 是双射的有限见证
example : ∀ j < 100, jpair (junpair j).1 (junpair j).2 = j := by
  decide

-- ---------- 欧几里得素数定理（定理 1.32）与最小素因子（引理 1.5） ----------

/-- 官方锚点：Nat.exists_infinite_primes——"存在任意大的素数" -/
theorem euclid_book (n : ℕ) : ∃ p, n ≤ p ∧ p.Prime :=
  Nat.exists_infinite_primes n

/-- 引理 1.5 素因子存在性：minFac 即"最小素因子"的官方形态
（本版签名：minFac_prime 要 n ≠ 1；minFac_dvd 是命题不是函数） -/
theorem prime_factor_exists {n : ℕ} (hn : 1 < n) : ∃ p, p.Prime ∧ p ∣ n :=
  ⟨n.minFac, Nat.minFac_prime (by omega), Nat.minFac_dvd n⟩

/-- 欧几里得构造的有限重演：前 k 个素数之积 +1 的最小素因子是新的 -/
-- （minFac 走 Nat.find，kernel 不可约、decide 卡死；Nat.Prime 的
-- 试除判定实例可全核归约——积的计算 rfl，素性 decide）
example : ((List.take 5 [2, 3, 5, 7, 11, 13]).foldl (· * ·) 1) + 1 = 2311 := by
  rfl

-- 欧几里得构造的有限重演：前 5 个素数之积 +1 = 2311 仍是素数——
-- "积+1 永远给出新素数"在第六次构造上现场兑现。
-- （GCD.Basic 进场后素性判定的实例路径变深，decide 须抬递归上限）
set_option maxRecDepth 100000 in
example : Nat.Prime 2311 := by decide

-- ---------- 贝祖表示（定理 1.34：gcd = u·m + v·n） ----------

/-- 官方锚点：Nat.gcd_eq_gcd_ab——gcdA/gcdB 即贝祖系数（ℤ 值版本：
gcdA : ℕ → ℕ → ℤ，等式两侧都在 ℤ 里读） -/
theorem bezout_book (m n : ℕ) :
    (m : ℤ) * Nat.gcdA m n + (n : ℤ) * Nat.gcdB m n = (m.gcd n : ℤ) :=
  (Nat.gcd_eq_gcd_ab m n).symm

-- 具体见证：gcd(240, 46) = 2 = 240·(−9) + 46·47（gcdA 非核可算，
-- 手算系数、norm_num 只验算）
example : (240 : ℤ) * (-9) + 46 * 47 = (Nat.gcd 240 46 : ℤ) := by norm_num

-- ---------- 显式因子引理（引理 1.7：素数整除乘积则整除其一） ----------

theorem prime_dvd_mul_book {p m n : ℕ} (hp : p.Prime) : p ∣ m * n ↔ p ∣ m ∨ p ∣ n :=
  hp.dvd_mul

end Settheory.Ch69
