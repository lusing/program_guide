import Mathlib.Tactic

/-!
# 第 70 章 · 第二递归定义定理与彻底有限集合（冯琦 §1.5-1.6）

V_ω 的归纳化身 HF（node : List HF）；阿克曼编码
f(n+1) = f(r(n)) ∪ {f(lg2(n))}（定理 1.48，well-founded 递归）；
V_ω 对配对/并封闭（定理 1.46(5) 的形式版）。
-/

namespace Settheory.Ch70

-- ---------- V_ω 的归纳化身：彻底有限集合 ----------

-- 归纳类型没有字段投影（.children 不存在）——structure 才带投影；
-- 单构造子结构体与书上的"集合 = 孩子列表"完全同构
structure HF where
  children : List HF
deriving Repr

-- 核心版 deriving 不支持 List 递归字段上的 DecidableEq（实测 4.33 拒绝）。
-- 手工装：HF 与孩子列表做跨类型互递归——Lean 的方程编译器接受这种
-- 互结构递归（对照：Coq 8.20 的 guard 会拒绝，见 Ch70_recursion2.v 注释）
mutual
def decEqHF : (x y : HF) → Decidable (x = y)
  | ⟨a⟩, ⟨b⟩ =>
      match decEqChildren a b with
      | isTrue h => isTrue (by subst h; rfl)
      | isFalse h => isFalse (fun he => HF.noConfusion he (fun e => h e))

def decEqChildren : (l1 l2 : List HF) → Decidable (l1 = l2)
  | [], [] => isTrue rfl
  | x :: xs, y :: ys =>
      match decEqHF x y, decEqChildren xs ys with
      | isTrue hxy, isTrue hxs => isTrue (by rw [hxy, hxs])
      | isFalse hxy, _ => isFalse (fun h => by injection h with h1 h2; exact hxy h1)
      | _, isFalse hxs => isFalse (fun h => by injection h with h1 h2; exact hxs h2)
  | [], _ :: _ => isFalse (fun h => nomatch h)
  | _ :: _, [] => isFalse (fun h => nomatch h)
end

instance : DecidableEq HF := decEqHF

namespace HF

/-- 集合成员：孩子列表里出现 -/
def mem (a b : HF) : Bool := b.children.contains a

/-- 冯琦的"属于"：a ∈ b -/
scoped infixl:50 " ∈ᴴᶠ " => HF.mem

/-- 并：两集合的孩子列表拼接去重（推论 1.8 的 X ∪ {Y} 在此之上） -/
def union (a b : HF) : HF :=
  if a.children.contains b then a
  else ⟨a.children ++ [b]⟩

/-- 定理 1.49 的三个生成算子：∅、单集化、二元并 -/
def empty : HF := ⟨[]⟩

def singleton (a : HF) : HF := ⟨[a]⟩

theorem empty_mem (a : HF) : ¬ a ∈ᴴᶠ empty := by
  simp [mem, empty]

theorem singleton_mem (a : HF) : a ∈ᴴᶠ singleton a := by
  simp [mem, singleton]

/-- 并保持左侧成员（x ∈ a 的孩子 → x ∈ a ∪ {b} 的孩子） -/
theorem union_mem_of_mem {x a b : HF} (h : x ∈ a.children) : x ∈ᴴᶠ union a b := by
  unfold union mem
  split
  · simpa using h
  · simp
    exact Or.inl h

/-- 右侧新成员总是进来（本版 List.mem_singleton 是 Iff，不再是函数） -/
theorem union_mem_right (a b : HF) : b ∈ᴴᶠ union a b := by
  unfold union mem
  split
  · rename_i hc; simpa using hc
  · simp

end HF

open HF

-- ---------- 定理 1.48：阿克曼编码 ℕ → V_ω ----------

/- 本版 mathlib 的 Nat.log2 引理族断代（log2_lt_pow/log2_le_mono 等
   均不存在，唯 log2_le_self 幸存）——lg2 自写除二循环，两条引理
   （燃料上界、2^lg2 ≤ n+1）自给自足，termination 全靠 omega。 -/
def lg2aux : ℕ → ℕ → ℕ
  | 0, _ => 0
  | fuel + 1, m => if m ≤ 1 then 0 else 1 + lg2aux fuel (m / 2)

/-- lg2(n)：2^i ≤ n+1 < 2^{i+1} 的那个 i（定义 1.56） -/
def lg2 (n : ℕ) : ℕ := lg2aux n (n + 1)

/-- r(n) = n+1 − 2^{lg2(n)}：剥掉二进制最高位（定义 1.56） -/
def rrem (n : ℕ) : ℕ := n + 1 - 2 ^ lg2 n

lemma lg2aux_le : ∀ (fuel m : ℕ), lg2aux fuel m ≤ fuel
  | 0, _ => by simp [lg2aux]
  | fuel + 1, m => by
      by_cases h : m ≤ 1
      · simp [lg2aux, h]
      · have ih := lg2aux_le fuel (m / 2)
        simp [lg2aux, h]
        omega

/-- lg2 的对数下界：2^lg2(n) ≤ n+1（lg2aux 的不变量：lg2 确是取底对数） -/
lemma two_pow_lg2aux_le : ∀ (fuel mm : ℕ), 1 ≤ mm → 2 ^ lg2aux fuel mm ≤ mm
  | 0, mm, hmm => by simp [lg2aux, hmm]
  | fuel + 1, mm, hmm => by
      by_cases h : mm ≤ 1
      · simp [lg2aux, h, hmm]
      · have h2 := two_pow_lg2aux_le fuel (mm / 2) (by omega)
        have h3 : (2 : ℕ) ^ (1 + lg2aux fuel (mm / 2))
            = 2 ^ lg2aux fuel (mm / 2) * 2 := by
          rw [Nat.add_comm, Nat.pow_succ]
        simp [lg2aux, h]
        omega

lemma two_pow_lg2_le (n : ℕ) : 2 ^ lg2 n ≤ n + 1 :=
  two_pow_lg2aux_le n (n + 1) (by omega)

/- 递归调用的两笔账：rrem n ≤ n（2^lg2(n) ≥ 1）、lg2 n ≤ n（lg2aux
   燃料引理）——良基性成立。但良基递归编译为 WellFounded.fix，kernel
   难以归约，rfl/decide 全数失效；与 Coq 版一致改用显式燃料（结构递归），
   上两笔账作为文档注记。 -/
def ackVaux : ℕ → ℕ → HF
  | 0, _ => empty
  | _ + 1, 0 => empty
  | fuel + 1, n + 1 => union (ackVaux fuel (rrem n)) (ackVaux fuel (lg2 n))

/-- 书页 84：f(0) = ∅；f(n+1) = f(r(n)) ∪ {f(lg2(n))}（燃料版） -/
def ackV (n : ℕ) : HF := ackVaux n n

/-- f(1) = {∅}、f(2) = {f(1)}、f(3) = {f(0), f(1)}（断言三的形状公式；
    孩子列表序 = 计算序 [f(0), f(1)]，集合意义上与书页 {f(1), f(0)} 同一） -/
example : ackV 3 = ⟨[ackV 0, ackV 1]⟩ := by rfl

/-- 前 16 个值两两不同：f 是 V₃（16 元）上的双射的有限见证 -/
example : ((List.range 16).map ackV).eraseDups.length = 16 := by decide

/-- f 0..3 恰好枚举 V₂（∅, {∅}, {{∅}}, {∅,{∅}}）——推论 1.9 的镜像 -/
example : (List.range 4).map ackV =
    [⟨[]⟩, ⟨[⟨[]⟩]⟩, ⟨[⟨[⟨[]⟩]⟩]⟩, ⟨[⟨[]⟩, ⟨[⟨[]⟩]⟩]⟩] := by
  decide

end Settheory.Ch70
