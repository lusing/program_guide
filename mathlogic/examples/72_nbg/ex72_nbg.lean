/- ex72_nbg.lean —— 公理集合论 NBG 与序数（Mendelson §4.1-4.6）Lean 镜像
   fset 项代数+von Neumann 典范世界（vn 追加式+els 引理族）+
   Kuratowski 序对 4.3 特征性质+传递性真定理+有限选择公理+B1-B5 算子。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

-- ============ 一、有限集合项代数与 von Neumann 典范世界 ============

inductive Fset : Type where
  | atom (n : Nat)
  | br (xs : List Fset)

open Fset

def els : Fset → List Fset
  | .atom _ => []
  | .br l => l

def vn : Nat → Fset
  | 0 => .br []
  | k + 1 =>
      match vn k with
      | .br l => .br (l ++ [vn k])
      | .atom _ => .br []

theorem vn_br (k : Nat) : ∃ l, vn k = .br l := by
  induction k with
  | zero => exact ⟨[], rfl⟩
  | succ k ih =>
      obtain ⟨l, hl⟩ := ih
      exact ⟨l ++ [vn k], by simp [vn, hl]⟩

theorem els_vn_S (k : Nat) : els (vn (k + 1)) = els (vn k) ++ [vn k] := by
  obtain ⟨l, hl⟩ := vn_br k
  rw [vn, hl, els]; rfl

def vlen (x : Fset) : Nat := (els x).length

theorem vn_len (n : Nat) : vlen (vn n) = n := by
  induction n with
  | zero => rfl
  | succ n ih =>
      rw [vlen, els_vn_S, List.length_append]
      simp only [List.length_cons, List.length_nil, vlen] at ih ⊢
      omega

theorem vn_inj (a b : Nat) (h : vn a = vn b) : a = b := by
  have h2 : vlen (vn a) = vlen (vn b) := by rw [h]
  rw [vn_len, vn_len] at h2
  exact h2

-- 成员刻画：vn j ∈ els (vn k) ⟺ j < k
theorem vn_memb_lt : ∀ (j k : Nat), vn j ∈ els (vn k) → j < k := by
  intro j k
  induction k with
  | zero => intro h; cases h
  | succ k ih =>
      intro h
      rw [els_vn_S, List.mem_append] at h
      rcases h with h | h
      · exact Nat.lt_succ_of_lt (ih h)
      · rcases List.mem_cons.1 h with heq | h
        · have hk : j = k := vn_inj j k heq
          omega
        · cases h

theorem vn_lt_memb : ∀ (j k : Nat), j < k → vn j ∈ els (vn k) := by
  intro j k
  induction k with
  | zero => intro h; omega
  | succ k ih =>
      intro h
      rw [els_vn_S, List.mem_append]
      rcases Nat.eq_or_lt_of_le (Nat.le_of_lt_succ h) with heq | hlt
      · right; rw [heq]; exact List.Mem.head _
      · left; exact ih hlt

-- els 的元素刻画
theorem vn_els_ex : ∀ (k : Nat) (u : Fset), u ∈ els (vn k) → ∃ j, j < k ∧ u = vn j := by
  intro k
  induction k with
  | zero => intro u h; cases h
  | succ k ih =>
      intro u h
      rw [els_vn_S, List.mem_append] at h
      rcases h with h | h
      · obtain ⟨j, hj, huj⟩ := ih u h
        exact ⟨j, Nat.lt_succ_of_lt hj, huj⟩
      · rcases List.mem_cons.1 h with heq | h
        · exact ⟨k, Nat.lt_succ_self k, heq⟩
        · cases h

-- ============ 二、Kuratowski 序对：命题 4.3 特征性质 ============

def kur (x y : Fset) : Fset := .br [.br [x], .br [x, y]]

theorem kur_char (a b c d : Nat)
    (h : kur (vn a) (vn b) = kur (vn c) (vn d)) : a = c ∧ b = d := by
  unfold kur at h
  injection h with h1
  injection h1 with e1 e2
  injection e1 with e1'
  injection e1' with ea
  injection e2 with e4
  injection e4 with e5
  injection e5 with ea2 e6
  injection e6 with eb
  exact ⟨vn_inj _ _ ea, vn_inj _ _ eb⟩

-- ============ 三、von Neumann 序数：传递性真定理与反例 ============

def transP : Fset → Prop
  | .atom _ => True
  | .br ys => ∀ u ∈ ys, ∀ w ∈ els u, w ∈ ys

theorem vn_trans (n : Nat) : transP (vn n) := by
  induction n with
  | zero =>
      simp only [vn, transP]
      intro u hu; cases hu
  | succ n ih =>
      obtain ⟨l, hl⟩ := vn_br (n + 1)
      rw [hl]
      have hl2 : l = els (vn n) ++ [vn n] := by
        rw [← els_vn_S, hl]; rfl
      rw [hl2]
      intro u hu
      rw [List.mem_append] at hu
      rcases hu with hu | hu
      · obtain ⟨j, hj, huj⟩ := vn_els_ex n u hu
        rw [huj]
        intro w hw
        obtain ⟨i, hi, hwi⟩ := vn_els_ex j w hw
        rw [hwi, List.mem_append]
        exact Or.inl (vn_lt_memb i n (by omega))
      · rcases List.mem_cons.1 hu with heq | hu
        · rw [heq]
          intro w hw
          obtain ⟨i, hi, hwi⟩ := vn_els_ex n w hw
          rw [hwi, List.mem_append]
          exact Or.inl (vn_lt_memb i n hi)
        · cases hu

-- 反例：{1,2} 不传递——vn 0 ∈ vn 1 但 vn 0 ∉ {vn 1, vn 2}
example : ¬ transP (.br [vn 1, vn 2]) := by
  intro h
  have h1 : vn 1 ∈ [vn 1, vn 2] := List.Mem.head _
  have h2 : ∀ w ∈ els (vn 1), w ∈ [vn 1, vn 2] := h _ h1
  have heq0 : els (vn 0) = [] := rfl
  have h0 : vn 0 ∈ els (vn 1) := by
    rw [els_vn_S, heq0]
    exact List.Mem.head _
  have h3 := h2 _ h0
  rcases List.mem_cons.1 h3 with he | h4
  · exact Nat.noConfusion (vn_inj _ _ he)
  · rcases List.mem_cons.1 h4 with he | h5
    · exact Nat.noConfusion (vn_inj _ _ he)
    · cases h5

-- ============ 四、有限选择公理：构造性、零公理 ============

theorem fin_ac (L : List (List Fset))
    (hne : ∀ x ∈ L, ∃ a, a ∈ x) :
    ∃ c : List Fset, c.length = L.length ∧
      ∀ i, i < L.length → (c.getD i (.atom 0)) ∈ (L.getD i []) := by
  induction L with
  | nil =>
      refine ⟨[], rfl, ?_⟩
      intro i hi; simp only [List.length_nil] at hi; omega
  | cons x L ih =>
      obtain ⟨a, ha⟩ := hne x (List.Mem.head _)
      obtain ⟨c, hlen, hc⟩ := ih (fun y hy => hne y (List.Mem.tail _ hy))
      refine ⟨a :: c, ?_, ?_⟩
      · simp [hlen]
      · intro i hi
        match i with
        | 0 => exact ha
        | i + 1 =>
            have : i < L.length := by simp at hi; omega
            exact hc i this

-- ============ 五、类存在公理的成员表算子现场（B1-B5）============

-- 有限论域 {0..K-1}：一元类=成员表 nat->bool；二元类=双参表
def Erel (K : Nat) : Nat → Nat → Bool :=
  fun u v => (u < K && v < K) && (u < v)          -- B1 ∈-关系（von Neumann 表）
def opInter (X Y : Nat → Bool) : Nat → Bool :=
  fun u => X u && Y u                              -- B2 交
def opCompl (X : Nat → Bool) : Nat → Bool :=
  fun u => !X u                                    -- B3 补
def opDom (R : Nat → Nat → Bool) (K : Nat) : Nat → Bool :=
  fun u => (List.range K).any (fun v => R u v)     -- B4 域
def opCross (X : Nat → Bool) (K : Nat) : Nat → Nat → Bool :=
  fun u v => X u && (v < K)                        -- B5 X×V
def opSwap (R : Nat → Nat → Bool) : Nat → Nat → Bool :=
  fun u v => R v u                                 -- B6/B7 轮换/对换的二元化身

theorem opInter_ok (X Y : Nat → Bool) (u : Nat) :
    opInter X Y u = true ↔ (X u = true ∧ Y u = true) := by
  simp only [opInter, Bool.and_eq_true]

theorem opCompl_ok (X : Nat → Bool) (u : Nat) :
    opCompl X u = true ↔ X u = false := by
  simp only [opCompl, Bool.not_eq_true']

theorem opDom_ok (R : Nat → Nat → Bool) (K u : Nat) :
    opDom R K u = true ↔ ∃ v, v < K ∧ R u v = true := by
  simp only [opDom, List.any_eq_true, List.mem_range]

theorem opCross_ok (X : Nat → Bool) (K u v : Nat) :
    opCross X K u v = true ↔ (X u = true ∧ v < K) := by
  simp only [opCross, Bool.and_eq_true]
  exact ⟨fun h => ⟨h.1, by simpa using h.2⟩, fun h => ⟨h.1, by simpa using h.2⟩⟩

theorem opSwap_ok (R : Nat → Nat → Bool) (u v : Nat) :
    opSwap R u v = true ↔ R v u = true := Iff.rfl

-- 现场对账：K=4 论域上 ∈-表驱动的一串算子计算
example :
    ((List.range 5).map (fun u => opInter (fun v => v < 3) (fun v => 1 <= v) u),
     (List.range 4).map (fun u => opDom (Erel 4) 4 u),
     (List.range 3).map (fun u => opCompl (fun v => v < 2) u))
    = ([false, true, true, false, false],
       [true, true, true, false],
       [false, false, true]) := by native_decide

-- ============ 账本 ============

#print axioms vn_trans
#print axioms kur_char
#print axioms fin_ac
#print axioms opDom_ok
