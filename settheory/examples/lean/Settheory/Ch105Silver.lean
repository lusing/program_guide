import Mathlib.Data.List.Basic
import Mathlib.Data.Finset.Basic
import Mathlib.Data.Finset.Card

/-!
# 第 105 章 · Silver 力迫

锚点（有限影子）：
- `SCond`：Silver 型条件——有限部分函数（坐标 (α,ξ)、值 0/1，
  Add(α,α⁺⁺) 的影子），键无重复；
- `extC`：反向包含序（q ≤ p ⟺ p ⊆ q）——自反/传递
  （Task 20 Step 2 指定件：条件延长的偏序律）；
- `agree`/`unionC`：相容条件的合并；
- `support`/`easton_ok`：Easton 支撑（|spt ∩ μ| < μ）；
- `master_bound`：两两相容族的并是其下界——引理 2.6 定向
  完全性（大拿/master condition）的有限影子。
本体（定义 2.7–2.11、引理 2.6/2.7、定理 2.10）留在正文。
-/

namespace Settheory.Ch105

abbrev Triple : Type := ((ℕ × ℕ) × ℕ)

def wfT (x : Triple) : Prop := x.2 < 2

def keysOf (p : List Triple) : List (ℕ × ℕ) := p.map Prod.fst

def SCond (p : List Triple) : Prop :=
  (∀ x ∈ p, wfT x) ∧ (keysOf p).Nodup

/-- 反向包含：q ≤ p ⟺ p 的键值都在 q 中。 -/
def extC (p q : List Triple) : Prop := ∀ x ∈ p, x ∈ q

theorem extC_refl (p : List Triple) : extC p p :=
  fun _ hx => hx

theorem extC_trans {p q r : List Triple}
    (h₁ : extC p q) (h₂ : extC q r) : extC p r :=
  fun x hx => h₂ x (h₁ x hx)

/-- 相容：公共键上取值一致。 -/
def agree (p q : List Triple) : Prop :=
  ∀ x ∈ p, ∀ y ∈ q, x.1 = y.1 → x.2 = y.2

def unionC (p q : List Triple) : List Triple :=
  p ++ q.filter (fun y => ¬ (y.1 ∈ keysOf p))

theorem unionC_left (p q : List Triple) : extC p (unionC p q) :=
  fun _ hx => List.mem_append_left _ hx

theorem unionC_cond {p q : List Triple}
    (hp : SCond p) (hq : SCond q) :
    SCond (unionC p q) := by
  obtain ⟨hwf, hnd⟩ := hp
  obtain ⟨hwf', hnd'⟩ := hq
  refine ⟨?_, ?_⟩
  · intro x hx
    rcases List.mem_append.1 hx with h | h
    · exact hwf x h
    · exact hwf' x (List.mem_filter.1 h).1
  · unfold keysOf unionC
    rw [List.map_append]
    refine List.nodup_append.2 ⟨hnd, ?_, ?_⟩
    · exact List.Nodup.sublist
        (List.Sublist.map Prod.fst (List.filter_sublist)) hnd'
    · intro k hk j hjmem hkj
      obtain ⟨y, hy, hyj⟩ := List.mem_map.1 hjmem
      have hneg : ¬ y.1 ∈ keysOf p := by
        simpa using (List.mem_filter.1 hy).2
      rw [hyj, ← hkj] at hneg
      exact hneg hk

/-- 支撑：条件中出现的 α-坐标全体（定义 2.9 影子）。 -/
def support (p : List Triple) : List ℕ :=
  (keysOf p).map Prod.fst

/-- Easton 支撑条款：|spt(p) ∩ μ| < μ（正则 μ）。 -/
def easton_ok (p : List Triple) (μ : ℕ) : Prop :=
    (List.filter (fun a => a < μ) (support p)).length < μ

/-- 键数不超过支撑数——|dom| ≤ 2 ⟹ |spt ∩ 3| < 3。 -/
theorem easton_small_sample {p : List Triple} (h : p.length ≤ 2) :
    easton_ok p 3 := by
  have hfil : (List.filter (fun a => a < 3) (support p)).Sublist (support p) :=
    List.filter_sublist
  have hsub : (List.filter (fun a => a < 3) (support p)).length
      ≤ (support p).length := List.Sublist.length_le hfil
  have hmap : (support p).length ≤ p.length := by
    simp [support, keysOf]
  have h2 : (support p).length ≤ 2 := Nat.le_trans hmap h
  have h3 : (List.filter (fun a => a < 3) (support p)).length ≤ 2 :=
    Nat.le_trans hsub h2
  unfold easton_ok
  omega

/-- 两两相容族的并是公共下界（引理 2.6 定向完全性的有限影子：
大拿/master condition）。 -/
theorem master_bound (p q : List Triple) (ha : agree p q) :
    extC p (unionC p q) ∧ extC q (unionC p q) := by
  constructor
  · exact unionC_left p q
  · intro y hy
    by_cases hkey : y.1 ∈ keysOf p
    · obtain ⟨x, hx, hxy⟩ := List.mem_map.1 hkey
      have hyx : y = x := Prod.ext hxy.symm (ha x hx y hy hxy).symm
      rw [hyx]
      exact List.mem_append_left _ hx
    · exact List.mem_append_right _ (List.mem_filter.2 ⟨hy, by simp [hkey]⟩)

end Settheory.Ch105
