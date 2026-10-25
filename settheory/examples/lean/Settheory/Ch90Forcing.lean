import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.List.Nodup

/-!
# 第 90 章 · 力迫基本理论与 CH/AC 独立性（冯琦第二卷 §3.1-3.3）

三件有限可证的引擎：

1. 定理 3.1（可数泛型滤子存在）的递归内核：一列「可相遇稠密集」配上
   选择函数，递归造出嵌套链；对角避让稠密集保证泛型分支不属于地基。
2. 力迫关系的最基本形态：条件 p 决定科恩实数第 n 位；决定集稠密，
   且前缀保持被决定的比特（真值引理的原子形态）。
3. ccc 的有限计数：Fn(n,2) 的反链注入 2^n 个全函数（反链至多 2^n）。
-/

namespace Settheory.Ch90

open List

/-! ## 一、稠密相遇链（定理 3.1 的递归引擎） -/

/-- q 延拓 p（q 更强）：q = p ++ r。书里记号 q ≤ p。 -/
def Ext (p q : List Bool) : Prop := ∃ r, q = p ++ r

/-- 一个带选择函数的稠密集：extend p 总把 p 延拓成 D 的成员。
    真正的稠密集 ∀p ∃q(q≤p ∧ q∈D) 非构造地给见证；可数传递模型里
    枚举稠密集后递归选见证——这正是定理 3.1 的证明。 -/
structure Dense where
  D : List Bool → Prop
  extend : List Bool → List Bool
  isExt : ∀ p, Ext p (extend p)
  hits : ∀ p, D (extend p)

/-- [k]! 取 List Dense 时需要默认值：恒真平凡稠密集。 -/
instance : Inhabited Dense :=
  ⟨{ D := fun _ => True, extend := fun p => p,
     isExt := fun p => ⟨[], (append_nil p).symm⟩, hits := fun _ => trivial }⟩

/-- 从给定条件 p 出发逐集延长：相邻两项由对应稠密集的 isExt 见证。 -/
def chainFrom : List Bool → List Dense → List (List Bool)
  | p, [] => [p]
  | p, d :: ds => p :: chainFrom (d.extend p) ds

@[simp] theorem chainFrom_nil (p : List Bool) :
    chainFrom p [] = [p] := rfl

@[simp] theorem chainFrom_cons (p : List Bool) (d : Dense) (ds : List Dense) :
    chainFrom p (d :: ds) = p :: chainFrom (d.extend p) ds := rfl

/-- 链头总是出发点。 -/
@[simp] theorem chainFrom_head (p : List Bool) (ds : List Dense) :
    (chainFrom p ds)[0]! = p := by
  cases ds <;> simp

/-- 从空条件出发的相遇链（定理 3.1 的构造）。 -/
def chain (ds : List Dense) : List (List Bool) := chainFrom [] ds

/-- 链上相邻条件逐层延拓：p_{j+1} 强于 p_j。 -/
theorem chain_nested : ∀ (p : List Bool) (ds : List Dense) (j : Nat),
    j + 1 < (chainFrom p ds).length →
      Ext ((chainFrom p ds)[j]!) ((chainFrom p ds)[j+1]!) := by
  intro p ds
  induction ds generalizing p with
  | nil => intro _ hj; simp at hj
  | cons d ds ih =>
    intro j hj
    cases j with
    | zero =>
      simp only [chainFrom_cons, chainFrom_head, getElem!_cons_succ]
      exact d.isExt p
    | succ j =>
      have hlen : j + 1 < (chainFrom (d.extend p) ds).length := by
        simp only [chainFrom_cons, length_cons] at hj; omega
      simpa only [chainFrom_cons, getElem!_cons_succ] using
        ih (d.extend p) j hlen

/-- 第 k 个稠密集在链的第 k+1 个节点处被相遇（定理 3.1 的记账）。
    谓词直接以函数应用书写（List Bool → Prop 无 ∈ 实例）。 -/
theorem chain_meets : ∀ (p : List Bool) (ds : List Dense) (k : Nat),
    k < ds.length → (ds[k]!).D (chainFrom p ds)[k+1]! := by
  intro p ds
  induction ds generalizing p with
  | nil => intro k hk; simp at hk
  | cons d ds ih =>
    intro k hk
    cases k with
    | zero =>
      simp only [chainFrom_cons, chainFrom_head, getElem!_cons_succ,
        getElem!_cons_zero]
      exact d.hits p
    | succ k =>
      simpa only [chainFrom_cons, getElem!_cons_succ] using
        ih (d.extend p) k (by simpa using hk)

/-- 泛型不在地基中：第 k 步在位置 k 翻转 b_k 的比特。 -/
def flipBit (b : List Bool) (k : Nat) : Bool := !(b[k]!)

def genBuildFrom : Nat → List (List Bool) → List Bool
  | _, [] => []
  | k, b :: bs => flipBit b k :: genBuildFrom (k + 1) bs

@[simp] theorem genBuildFrom_nil (k : Nat) : genBuildFrom k [] = [] := rfl

@[simp] theorem genBuildFrom_cons (k : Nat) (b : List Bool)
    (bs : List (List Bool)) :
    genBuildFrom k (b :: bs) = flipBit b k :: genBuildFrom (k + 1) bs := rfl

/-- 生成串第 j 位恰为第 j 个地基分支第 k0+j 位的翻转。 -/
theorem genBuildFrom_bit (bs : List (List Bool)) :
    ∀ (k0 j : Nat) (_hj : j < bs.length),
      (genBuildFrom k0 bs)[j]! = flipBit (bs[j]!) (k0 + j) := by
  induction bs with
  | nil => intro k0 j hj; simp at hj
  | cons b bs ih =>
    intro k0 j hj
    cases j with
    | zero =>
      simp only [genBuildFrom_cons, getElem!_cons_zero, Nat.add_zero]
    | succ j =>
      have hidx : k0 + (j + 1) = (k0 + 1) + j := by omega
      rw [hidx]
      simpa only [genBuildFrom_cons, getElem!_cons_succ] using
        ih (k0 + 1) j (by simpa using hj)

/-- 泛型分支与每个地基分支 b_k 在第 k 位不同：它不等于任何 b_k
    （例 3.3 中「对角避让」稠密集的有限版本）。 -/
theorem generic_avoids (bs : List (List Bool)) (k : Nat)
    (hk : k < bs.length) :
    (genBuildFrom 0 bs)[k]! ≠ (bs[k]!)[k]! := by
  rw [genBuildFrom_bit bs 0 k hk]
  simp only [flipBit, Nat.zero_add]
  have neq : ∀ (x : Bool), (!x) ≠ x := by decide
  exact neq _

/-! ## 二、决定稠密集与力迫的原子形态 -/

/-- 决定第 n 位的延长：无条件补零到长度 n+1；若 n 已在定义域内，
    n+1-p.length = 0，追加空表（保持幂等）。 -/
def decider (n : Nat) (p : List Bool) : List Bool :=
  p ++ replicate (n + 1 - p.length) false

/-- 常零表任意一位的 getElem? 都是 some false。 -/
lemma get?_replicate_false : ∀ (k m : Nat) (_h : m < k),
    (replicate k false : List Bool)[m]? = some false
  | k + 1, 0, _ => rfl
  | k + 1, m + 1, _ => by
      rw [replicate_succ, getElem?_cons_succ]
      exact get?_replicate_false k m (by omega)
  | 0, m, h => by omega

theorem decider_ext (n : Nat) (p : List Bool) : Ext p (decider n p) :=
  ⟨replicate (n + 1 - p.length) false, rfl⟩

/-- 决定稠密性：任何条件都能延拓到第 n 位被决定。 -/
theorem decider_decides (n : Nat) (p : List Bool) :
    n < (decider n p).length := by
  dsimp only [decider]
  rw [length_append, length_replicate]
  by_cases h : n < p.length
  · have z : n + 1 - p.length = 0 := by omega
    rw [z, add_zero]; exact h
  · have le : p.length ≤ n := by omega
    rw [Nat.add_sub_of_le (le.trans (by omega))]; omega

/-- 尚未决定时延长部分补的都是 0：第 n 位被力迫为 0。 -/
theorem decider_fresh (n : Nat) (p : List Bool) (h : p.length ≤ n) :
    (decider n p)[n]! = false := by
  dsimp only [decider]
  set k : Nat := n + 1 - p.length with hkdef
  have hbit : n - p.length < k := by
    obtain ⟨d, hd⟩ := Nat.exists_eq_add_of_le h
    have h1 : n - p.length = d := by rw [hd]; simp
    rw [h1, hkdef, hd, Nat.add_assoc, Nat.add_sub_cancel_left]
    exact Nat.lt_succ_self d
  rw [getElem!_eq_getElem?_getD, getElem?_append_right h,
    get?_replicate_false k (n - p.length) hbit]
  simp

/-- 演示：把「决定第 n 位」的稠密集串起来，链长逐步增长，
    相遇性由 chain_meets 记账。 -/
def denseDecide (n : Nat) : Dense where
  D := fun p => n < p.length
  extend := decider n
  isExt := decider_ext n
  hits := decider_decides n

#eval (chainFrom [] [denseDecide 0, denseDecide 1, denseDecide 2]).map
  (fun p => p.length)

/-- 前缀保持已决定的比特：这是「p ⊩ g(n)=b ⇒ 任何含 p 的泛型都如此」
    的全部内容（真值引理的原子条款）。 -/
theorem forced_bit (p g : List Bool) (hpg : Ext p g) (i : Nat)
    (hi : i < p.length) : g[i]? = p[i]? := by
  rcases hpg with ⟨r, rfl⟩
  rw [getElem?_append_left hi]

/-! ## 三、Fn(n,2) 的反链 ≤ 2^n（ccc 的有限计数） -/

/-- 部分二值函数（条件）：None 表示该坐标尚未定义。 -/
def fill0 : {n : Nat} → (Fin n → Option Bool) → (Fin n → Bool) :=
  fun f i => (f i).getD false

/-- 相容：公共定义域上取值一致。 -/
def compat {n : Nat} (f g : Fin n → Option Bool) : Prop :=
  ∀ i : Fin n, ∀ b c : Bool, f i = some b → g i = some c → b = c

/-- 相冲 ⇒ 零填充全函数不同：填充把反链单射到 2^n 个全函数。 -/
theorem incompatible_fill_diff {n : Nat} {f g : Fin n → Option Bool}
    (h : ¬ compat f g) : fill0 f ≠ fill0 g := by
  have key : ∃ (i : Fin n) (b c : Bool),
      f i = some b ∧ g i = some c ∧ b ≠ c := by
    -- ¬(∀i b c, f i=some b → g i=some c → b=c) 手工逐层取出反例
    have h1 : ∃ (i : Fin n), ¬(∀ (b c : Bool),
        f i = some b → g i = some c → b = c) := by
      simpa [compat] using h
    rcases h1 with ⟨i, h2⟩
    -- 若 f i 无人认领，则该坐标的全称式空洞成立，与 h2 矛盾
    have hf : ∃ (b : Bool), f i = some b := by
      by_contra hn
      have h4 : ∀ (b : Bool), f i ≠ some b := by
        intro b hb; exact hn ⟨b, hb⟩
      exact h2 (fun b c hb _ => (h4 b hb).elim)
    have hg : ∃ (c : Bool), g i = some c := by
      by_contra hn
      have h4 : ∀ (c : Bool), g i ≠ some c := by
        intro c hc; exact hn ⟨c, hc⟩
      exact h2 (fun b c _ hc => (h4 c hc).elim)
    rcases hf with ⟨b, hfb⟩
    rcases hg with ⟨c, hgc⟩
    have hbc : b ≠ c := by
      intro e
      exact h2 (fun b' c' hfb' hgc' => by
        have eb : b' = b := Option.some_injective _ (hfb'.symm.trans hfb)
        have ec : c' = c := Option.some_injective _ (hgc'.symm.trans hgc)
        rw [eb, ec, e])
    exact ⟨i, b, c, hfb, hgc, hbc⟩
  rcases key with ⟨i, b, c, hf, hg, hbc⟩
  intro heq
  have h1 : fill0 f i = b := by simp [fill0, hf]
  have h2 : fill0 g i = c := by simp [fill0, hg]
  rw [heq] at h1
  rw [h1] at h2
  exact hbc h2

/-- 反链的零填充像两两不同。 -/
theorem antichain_fill_inj {n : Nat} (A : List (Fin n → Option Bool))
    (ha : ∀ f ∈ A, ∀ g ∈ A, f ≠ g → ¬ compat f g) (hn : A.Nodup) :
    (map fill0 A).Nodup := by
  rw [List.nodup_map_iff_inj_on hn]
  intro f hf g hg heq
  by_contra hne
  exact incompatible_fill_diff (ha f hf g hg hne) heq

/-- Fn(n,2) 的反链至多 2^n（有限 Δ-系统计数：零填充全函数恰 2^n 个）。 -/
theorem antichain_bound {n : Nat} (A : List (Fin n → Option Bool))
    (ha : ∀ f ∈ A, ∀ g ∈ A, f ≠ g → ¬ compat f g) (hn : A.Nodup) :
    A.length ≤ 2 ^ n := by
  have hi : (map fill0 A).Nodup := antichain_fill_inj A ha hn
  have hc : (map fill0 A).length ≤ Fintype.card (Fin n → Bool) :=
    hi.length_le_card
  rw [length_map] at hc
  rwa [Fintype.card_fun, Fintype.card_fin, Fintype.card_bool] at hc

-- Fn(3,2) 有 3^3 = 27 个条件；其反链至多 2^3 = 8 个。
#eval Fintype.card (Fin 3 → Option Bool)
#eval Fintype.card (Fin 3 → Bool)

end Settheory.Ch90
