import Mathlib.Data.List.Basic
import Mathlib.Data.Finset.Basic
import Mathlib.Data.Finset.Prod

/-!
# 第 108 章 · 恰当迭代与 PFA

锚点（有限影子）：
- `glue`/`take_glue`：拼接协调——q_{n+1} ↾ αₙ = qₙ（引理 2.27
  递归构造的协调条款）；
- `keys_append`/`keys_glue`/`keys_take`：支撑账——极限条件的
  支撑含于各段支撑之并（可数支撑迭代在极限步的有限影子）、
  限制只缩不小；
- `predense_product`：两步迭代的证书复合（引理 2.26 影子）：
  分量准稠密 ⟹ 积序准稠密；
- 样本宇宙沿 107 章 extT；(1,1) 与 (1,2) 在积序中不相容
  （反链相乘 4 = 2×2 的 cc 保持影子）。
本体（引理 2.27/定理 2.15、定义 2.22 PFA、定理 2.16/2.17、
引理 2.28 的拉弗提升）留在正文。
-/

namespace Settheory.Ch108

open Finset

variable {ι : Type}

/-- 相容：两条件有公共延展（沿 107 章，对任意条件类型）。 -/
def Compat (ext : ι → Finset ι) (r p : ι) : Prop :=
  ∃ s, s ∈ ext r ∧ s ∈ ext p

/-- A 在 q 之下准稠密（沿 107 章）。 -/
def PredenseBelow (ext : ι → Finset ι) (A : Finset ι) (q : ι) : Prop :=
  ∀ r ∈ ext q, ∃ p ∈ A, Compat ext r p

/-- 样本宇宙（沿 107 章）：根 0 分叉到终端 1、2。 -/
def extT : ℕ → Finset ℕ
  | 0 => {0, 1, 2}
  | 1 => {1}
  | 2 => {2}
  | _ => ∅

theorem compat_10 : Compat extT 0 1 := ⟨1, by decide, by decide⟩
theorem compat_11 : Compat extT 1 1 := ⟨1, by decide, by decide⟩
theorem compat_22 : Compat extT 2 2 := ⟨2, by decide, by decide⟩

theorem predense_12_0 : PredenseBelow extT {1, 2} 0 := by
  intro r hr
  simp only [extT, mem_insert, mem_singleton] at hr
  rcases hr with rfl | rfl | rfl
  · exact ⟨1, by decide, compat_10⟩
  · exact ⟨1, by decide, compat_11⟩
  · exact ⟨2, by decide, compat_22⟩

/-! ## 一、两步迭代的积序与证书复合（引理 2.26 影子） -/

/-- 两步迭代的延展集：分量延展的笛卡尔积。 -/
def ext2 (ext₁ ext₂ : ℕ → Finset ℕ) (p : ℕ × ℕ) : Finset (ℕ × ℕ) :=
  ext₁ p.1 ×ˢ ext₂ p.2

/-- 证书复合：分量准稠密 ⟹ 积序准稠密（引理 2.26 的有限影子）：
  (M,ℙ)-泛型条件 q₀ 与 (M[G],Q)-泛型条件 q₁ 合成
  (M,ℙ*Q)-泛型条件 (q₀,q₁)。 -/
theorem predense_product {ext₁ ext₂ : ℕ → Finset ℕ}
    {A B : Finset ℕ} {q₀ q₁ : ℕ}
    (hA : PredenseBelow ext₁ A q₀) (hB : PredenseBelow ext₂ B q₁) :
    PredenseBelow (fun p => ext2 ext₁ ext₂ p) (A ×ˢ B) (q₀, q₁) := by
  intro r hr
  have hr' : r ∈ (ext₁ q₀) ×ˢ (ext₂ q₁) := hr
  obtain ⟨hr₀, hr₁⟩ := Finset.mem_product.mp hr'
  obtain ⟨a, ha, s, hs, hsa⟩ := hA r.1 hr₀
  obtain ⟨b, hb, t, ht, htb⟩ := hB r.2 hr₁
  exact ⟨(a, b), Finset.mem_product.mpr ⟨ha, hb⟩,
    (s, t), Finset.mem_product.mpr ⟨hs, ht⟩, Finset.mem_product.mpr ⟨hsa, htb⟩⟩

/-- 积序实例：{1,2}×{1,2} 在 (0,0) 之下准稠密。 -/
example : PredenseBelow (fun p => ext2 extT extT p) ({1, 2} ×ˢ {1, 2}) (0, 0) :=
  predense_product predense_12_0 predense_12_0

/-- 积序反链样本：(1,1) 与 (1,2) 不相容——第二分量 1 与 2
不相容（反链相乘：2×2 = 4 元反链）。 -/
example : ¬ Compat (fun p => ext2 extT extT p) (1, 1) (1, 2) := by
  rintro ⟨s, hs, hs'⟩
  have h1 : s ∈ (extT 1) ×ˢ (extT 1) := hs
  have h2 : s ∈ (extT 1) ×ˢ (extT 2) := hs'
  obtain ⟨-, e1⟩ := Finset.mem_product.mp h1
  obtain ⟨-, e2⟩ := Finset.mem_product.mp h2
  simp only [extT, mem_singleton] at e1 e2
  rw [e2] at e1
  omega

/-! ## 二、支撑限制与拼接（引理 2.27 构造的协调条款） -/

/-- 条件 = 坐标表（坐标 → 非平凡条件值）；支撑 = 坐标集
（可数支撑的有限影子：平凡坐标不上表）。 -/
def Keys (q : List (Nat × Nat)) : Finset Nat := (q.map Prod.fst).toFinset

/-- 限制：前 k 个坐标（自建 take'，方程可控）。 -/
def take' : Nat → List (Nat × Nat) → List (Nat × Nat)
  | 0, _ => []
  | _ + 1, [] => []
  | k + 1, x :: xs => x :: take' k xs

/-- 丢弃：k 之后的部分（自建 drop'）。 -/
def drop' : Nat → List (Nat × Nat) → List (Nat × Nat)
  | 0, l => l
  | _ + 1, [] => []
  | n + 1, _ :: xs => drop' n xs

def restrict (k : Nat) (q : List (Nat × Nat)) : List (Nat × Nat) :=
  take' k q

/-- 拼接：先取 q 的全部坐标，再接 r 在 q 长度之外的部分。 -/
def glue (q r : List (Nat × Nat)) : List (Nat × Nat) :=
  q ++ drop' q.length r

/-- 自建件：drop' 的成员来自原表（列表版支撑账）。 -/
theorem mem_of_mem_drop' :
    ∀ (n : Nat) (l : List (Nat × Nat)) (a : Nat × Nat), a ∈ drop' n l → a ∈ l
  | 0, _, _, h => h
  | _ + 1, [], _, h => nomatch h
  | n + 1, _ :: xs, a, h =>
      List.mem_cons.mpr (Or.inr (mem_of_mem_drop' n xs a h))

/-- 自建件：take' 的成员来自原表。 -/
theorem mem_of_mem_take' :
    ∀ (k : Nat) (l : List (Nat × Nat)) (a : Nat × Nat), a ∈ take' k l → a ∈ l
  | 0, _, _, h => nomatch h
  | _ + 1, [], _, h => nomatch h
  | k + 1, _ :: xs, a, h =>
      (List.mem_cons.mp h).elim
        (fun he => List.mem_cons.mpr (Or.inl he))
        (fun hr => List.mem_cons.mpr (Or.inr (mem_of_mem_take' k xs a hr)))

/-- 自建件：take' 到自身长度恰还原（拼接协调的核心方程）。 -/
theorem take'_app_self :
    ∀ (q s : List (Nat × Nat)), take' q.length (q ++ s) = q
  | [], _ => rfl
  | x :: xs, s => by
    show x :: take' (List.length xs) (xs ++ s) = x :: xs
    rw [take'_app_self xs s]

/-- 支撑并集：拼接的支撑 = 两段支撑之并（极限步的支撑账）。 -/
theorem keys_append (q r : List (Nat × Nat)) :
    Keys (q ++ r) = Keys q ∪ Keys r := by
  ext i
  simp only [Keys, List.mem_toFinset, Finset.mem_union, List.mem_append, List.mem_map]
  constructor
  · rintro ⟨p, hp | hp, hpi⟩
    · exact Or.inl ⟨p, hp, hpi⟩
    · exact Or.inr ⟨p, hp, hpi⟩
  · rintro (⟨p, hp, hpi⟩ | ⟨p, hp, hpi⟩)
    · exact ⟨p, Or.inl hp, hpi⟩
    · exact ⟨p, Or.inr hp, hpi⟩

/-- 丢弃不添支撑：r 的尾段支撑含于 r 的支撑。 -/
theorem keys_drop (r : List (Nat × Nat)) (n : Nat) :
    Keys (drop' n r) ⊆ Keys r := by
  intro i hi
  simp only [Keys, List.mem_toFinset, List.mem_map] at hi ⊢
  obtain ⟨p, hp, hpi⟩ := hi
  exact ⟨p, mem_of_mem_drop' n r p hp, hpi⟩

/-- 限制只缩不小支撑。 -/
theorem keys_take (q : List (Nat × Nat)) (k : Nat) :
    Keys (restrict k q) ⊆ Keys q := by
  intro i hi
  simp only [Keys, restrict, List.mem_toFinset, List.mem_map] at hi ⊢
  obtain ⟨p, hp, hpi⟩ := hi
  exact ⟨p, mem_of_mem_take' k q p hp, hpi⟩

/-- 拼接协调：取 glue 的前 length q 个坐标恰还原 q
（引理 2.27：q_{n+1} ↾ αₙ = qₙ）。 -/
theorem take_glue (q r : List (Nat × Nat)) :
    restrict q.length (glue q r) = q :=
  take'_app_self q (drop' q.length r)

/-- 拼接的支撑含于两段支撑之并。 -/
theorem keys_glue (q r : List (Nat × Nat)) :
    Keys (glue q r) ⊆ Keys q ∪ Keys r := by
  rw [show glue q r = q ++ drop' q.length r from rfl, keys_append]
  exact Finset.union_subset Finset.subset_union_left
    (Finset.Subset.trans (keys_drop r q.length) Finset.subset_union_right)

/-! ## 三、样本账（决定性核查） -/

def qA : List (Nat × Nat) := [(2, 1)]
def rB : List (Nat × Nat) := [(0, 2), (4, 1), (9, 2)]

example : glue qA rB = [(2, 1), (4, 1), (9, 2)] := by decide
example : restrict 1 (glue qA rB) = qA := by decide
example : Keys (glue qA rB) = {2, 4, 9} := by decide
example : Keys (glue qA rB) ⊆ Keys qA ∪ Keys rB := keys_glue qA rB
example : Keys (restrict 1 rB) ⊆ Keys rB := keys_take rB 1

end Settheory.Ch108
