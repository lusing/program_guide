import Mathlib.Data.List.Basic

/-!
# 第 103 章 · 小型扩张与 Lévy 崩塌

锚点（有限影子）：
- `Cond`：Lévy 条件（键 (α,n)、值 β<α、键无重复）；
- `compat` 与 `unionC_cond`：相容条件的拼接仍是条件；
- `freshN`/`extend_dense`：稠密性 D(λ,β) 的书式证明——
  n₀ = （用过的 n 之和）+ 1，与书 p152 的
  n = 1 + max{m | ∃α (α,m) ∈ dom(q)} 同一机制；
- `unionC_set_eq`：并的集级交换——名字无关性的影子。
本体（定理 2.1 九款保持律、定理 2.2/2.3、定理 2.5）留在正文。
-/

namespace Settheory.Ch103

abbrev Triple : Type := ((ℕ × ℕ) × ℕ)

/-- 键 (α,n)；α ∈ [1,4]（有限宇宙），值 β < α。 -/
def wfT (x : Triple) : Prop := 1 ≤ x.1.1 ∧ x.1.1 ≤ 4 ∧ x.2 < x.1.1

def keysOf (p : List Triple) : List (ℕ × ℕ) := p.map Prod.fst

/-- Lévy 条件：良形 + 键无重复（Col(ω,<κ) 的有限影子）。 -/
def Cond (p : List Triple) : Prop :=
  (∀ x ∈ p, wfT x) ∧ (keysOf p).Nodup

/-- 扩展序 q ⊒ p：p 的键值都在 q 中（p ⊆ q）。 -/
def subsetC (p q : List Triple) : Prop := ∀ x ∈ p, x ∈ q

/-- 相容：公共键上取值一致。 -/
def compat (p q : List Triple) : Prop :=
  ∀ x ∈ p, ∀ y ∈ q, x.1 = y.1 → x.2 = y.2

/-- 部分函数并（后侧去掉已覆盖键）。 -/
def unionC (p q : List Triple) : List Triple :=
  p ++ q.filter (fun y => ¬ (y.1 ∈ keysOf p))

theorem unionC_left (p q : List Triple) : subsetC p (unionC p q) :=
  fun _ hx => List.mem_append_left _ hx

theorem unionC_cond (p q : List Triple) (hp : Cond p) (hq : Cond q) :
    Cond (unionC p q) := by
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
    · intro k hk j hj hkj
      obtain ⟨y, hy, hyj⟩ := List.mem_map.1 hj
      have hneg : ¬ y.1 ∈ keysOf p := by
        simpa using (List.mem_filter.1 hy).2
      exact hneg (by rw [hyj]; exact hkj ▸ hk)

/-- 集级交换：相容时两种并次序给出同一集合（同一部分函数）。 -/
theorem unionC_set_eq (p q : List Triple) (hc' : compat q p) :
    subsetC (unionC p q) (unionC q p) := by
  intro x hx
  rcases List.mem_append.1 hx with h | h
  · by_cases hkey : x.1 ∈ keysOf q
    · obtain ⟨y, hy, hxy⟩ := List.mem_map.1 hkey
      have hxe : x = y := Prod.ext hxy.symm (hc' y hy x h hxy).symm
      exact List.mem_append_left _ (hxe ▸ hy)
    · exact List.mem_append_right _ (List.mem_filter.2 ⟨h, by simp [hkey]⟩)
  · exact List.mem_append_left _ (List.mem_filter.1 h).1

/-- 成员不超过总和（自证小引理）。 -/
theorem mem_le_sum (l : List ℕ) (n : ℕ) (hn : n ∈ l) : n ≤ l.sum := by
  induction l generalizing n with
  | nil => exact absurd hn (by simp)
  | cons a t IH =>
    rcases List.mem_cons.1 hn with rfl | hm
    · simp only [List.sum_cons]
      omega
    · have h := IH n hm
      simp only [List.sum_cons]
      omega

/-- 书式新鲜槽号：n₀ =（已用 n 之和）+ 1——大于一切已用的 n。 -/
def freshN (l : ℕ) (p : List Triple) : ℕ :=
  ((p.filter (fun x => x.1.1 = l)).map (fun x => x.1.2)).sum + 1

theorem freshN_gt (l : ℕ) (p : List Triple) (x : Triple) (hx : x ∈ p)
    (hxl : x.1.1 = l) : x.1.2 < freshN l p := by
  have hmem : x.1.2 ∈ (p.filter (fun y => y.1.1 = l)).map (fun y => y.1.2) :=
    List.mem_map.2 ⟨x, List.mem_filter.2 ⟨hx, by simp [hxl]⟩, rfl⟩
  have h := mem_le_sum _ _ hmem
  unfold freshN
  omega

/-- 稠密性 D(λ,β)：任何条件都可扩展至含 ((λ,n₀),β)。 -/
theorem extend_dense (l β : ℕ) (hl1 : 1 ≤ l) (hl4 : l ≤ 4) (hβ : β < l)
    (p : List Triple) (hp : Cond p) :
    ∃ q, Cond q ∧ subsetC p q ∧ ((l, freshN l p), β) ∈ q := by
  have hnew : ((l, freshN l p), β).1 ∉ keysOf p := by
    intro hcontra
    obtain ⟨x, hx, hxe⟩ := List.mem_map.1 hcontra
    have h1 : x.1.1 = l := congrArg Prod.fst hxe
    have h2 : x.1.2 = freshN l p := congrArg Prod.snd hxe
    have hlt := freshN_gt l p x hx h1
    omega
  refine ⟨p ++ [((l, freshN l p), β)], ⟨?_, ?_⟩,
    fun _ hx => List.mem_append_left _ hx,
    List.mem_append_right _ (by simp)⟩
  · intro x hx
    rcases List.mem_append.1 hx with h | h
    · exact hp.1 x h
    · rcases List.mem_cons.1 h with rfl | h
      · exact ⟨hl1, hl4, hβ⟩
      · exact absurd h (by simp)
  · unfold keysOf
    rw [List.map_append]
    refine List.nodup_append.2 ⟨hp.2, by simp, ?_⟩
    intro k hk j hj hkj
    obtain ⟨z, hz, hzj⟩ := List.mem_map.1 hj
    rcases List.mem_singleton.1 hz with rfl
    exact hnew (by rw [hzj, ← hkj]; exact hk)

/-- 样本：键不相交的两条件相容；键相同值不同则不相容。 -/
example : compat [((2, 0), 1)] [((3, 1), 2)] := by
  intro x hx y hy hxy
  simp only [List.mem_singleton] at hx hy
  subst hx; subst hy
  exact absurd hxy (by decide)

example : ¬ compat [((2, 0), 1)] [((2, 0), 0)] := by
  intro hc
  have hm1 : ((2, 0), 1) ∈ [((2, 0), 1)] := by simp
  have hm2 : ((2, 0), 0) ∈ [((2, 0), 0)] := by simp
  have h : ((2, 0), 1).2 = ((2, 0), 0).2 :=
    hc ((2, 0), 1) hm1 ((2, 0), 0) hm2 rfl
  exact absurd h (by decide)

example (hp : Cond [((2, 0), 1)]) (hq : Cond [((3, 1), 2)]) :
    Cond (unionC [((2, 0), 1)] [((3, 1), 2)]) :=
  unionC_cond [((2, 0), 1)] [((3, 1), 2)] hp hq

end Settheory.Ch103
