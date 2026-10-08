/- ex51 —— 图论专题（Jongsma ch8）Lean 镜像
   握手引理（真归纳）+ 哥尼斯堡/K5/K3,3 现场算术 + Ham 圈检查器
   + 首适贪心着色两定理（合法性与色号界）。
   搜索型结果（Euler 回路 / Ham 穷举 / χ 精确值）在 Prolog 通道。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

-- ---------- 1. 握手引理（书 Prop 8.1.1） ----------

def lsum (l : List Nat) : Nat := l.foldr (· + ·) 0

theorem lsum_cons (x : Nat) (l : List Nat) : lsum (x :: l) = x + lsum l := rfl

/-- 度数：边表递归（多重图标准口径——自环两端各计一次）。
    这样 vdeg_cons 是定义方程，握手引理无需简单图假设 -/
def vdeg : Nat → List (Nat × Nat) → Nat
  | _, [] => 0
  | v, (a, b) :: E =>
      vdeg v E + (if v = a then 1 else 0) + (if v = b then 1 else 0)

theorem vdeg_cons (v a b : Nat) (E : List (Nat × Nat)) :
    vdeg v ((a, b) :: E)
      = vdeg v E + (if v = a then 1 else 0) + (if v = b then 1 else 0) := rfl

theorem lsum_map_add3 (f g h : Nat → Nat) : ∀ vs : List Nat,
    lsum (vs.map (fun v => f v + g v + h v))
      = lsum (vs.map f) + lsum (vs.map g) + lsum (vs.map h) := by
  intro vs
  induction vs with
  | nil => rfl
  | cons x xs ih =>
      rw [List.map_cons, List.map_cons, List.map_cons, List.map_cons,
          lsum_cons, lsum_cons, lsum_cons, lsum_cons]
      omega

theorem lsum_zero : ∀ vs : List Nat, lsum (vs.map (fun v => vdeg v [])) = 0 := by
  intro vs
  induction vs with
  | nil => rfl
  | cons x xs ih =>
      have h0 : vdeg x [] = 0 := rfl
      rw [List.map_cons, lsum_cons, h0, ih]

-- 标记函数的和恰为 1 或 0（Nodup 保证顶点不重计）
theorem sum_tag_zero (a : Nat) : ∀ vs : List Nat, a ∉ vs →
    lsum (vs.map (fun v => if v = a then 1 else 0)) = 0 := by
  intro vs h
  induction vs with
  | nil => rfl
  | cons x xs ih =>
      by_cases hxa : x = a
      · exact absurd (by rw [← hxa]; exact List.mem_cons_self) h
      · rw [List.map_cons, lsum_cons, if_neg hxa, Nat.zero_add]
        exact ih (fun hc => h (List.mem_cons_of_mem _ hc))

theorem sum_tag_one (a : Nat) : ∀ vs : List Nat, vs.Nodup → a ∈ vs →
    lsum (vs.map (fun v => if v = a then 1 else 0)) = 1 := by
  intro vs
  induction vs with
  | nil => intro _ hin; cases hin
  | cons x xs ih =>
      intro hnd hin
      obtain ⟨hnx, hnd'⟩ := List.nodup_cons.mp hnd
      by_cases hxa : x = a
      · rw [hxa, List.map_cons, lsum_cons, if_pos rfl,
            sum_tag_zero a xs (hxa ▸ hnx)]
      · have hin' : a ∈ xs := (List.mem_cons.mp hin).resolve_left
                       (fun he => hxa he.symm)
        rw [List.map_cons, lsum_cons, if_neg hxa, Nat.zero_add]
        exact ih hnd' hin'

/-- 握手引理：顶点覆盖所有边端 ⇒ Σdeg = 2·|E|（书 Prop 8.1.1） -/
theorem handshake : ∀ (E : List (Nat × Nat)) (vs : List Nat),
    vs.Nodup → (∀ e ∈ E, e.1 ∈ vs ∧ e.2 ∈ vs) →
    lsum (vs.map (fun v => vdeg v E)) = 2 * E.length := by
  intro E
  induction E with
  | nil => intro vs _ _; rw [lsum_zero]; rfl
  | cons ab E' ih =>
      intro vs hnd hcov
      obtain ⟨ha, hb⟩ := hcov ab (List.mem_cons_self)
      rw [List.map_congr_left (fun (v : Nat) (_ : v ∈ vs) =>
            vdeg_cons v ab.1 ab.2 E'),
          lsum_map_add3 (fun v => vdeg v E')
            (fun v => if v = ab.1 then 1 else 0)
            (fun v => if v = ab.2 then 1 else 0) vs,
          sum_tag_one ab.1 vs hnd ha, sum_tag_one ab.2 vs hnd hb,
          ih vs hnd (fun e he => hcov e (List.mem_cons_of_mem _ he)),
          List.length_cons]
      omega

-- ---------- 2. 现场一：哥尼斯堡七桥（书例 8.1.1/8.1.2） ----------
-- A=0 B=1 C=2 D=3；两对平行桥如实入表（多重图的边表化身）
def KonE : List (Nat × Nat) :=
  [(0,1),(0,1),(0,2),(0,2),(0,3),(1,3),(2,3)]

theorem Kon_degrees :
    (List.range 4).map (fun v => vdeg v KonE) = [5,3,3,3] := rfl

-- 四个奇点：Euler 回路的必要条件（每点偶度，书 §8.1.4）不满足
theorem Kon_four_odd :
    ([5,3,3,3].filter (fun d => d % 2 == 1)).length = 4 := rfl

theorem Kon_handshake :
    lsum ((List.range 4).map (fun v => vdeg v KonE)) = 2 * 7 := rfl

-- ---------- 3. 现场二：平面性的算术面（书 §8.3） ----------

def K5E : List (Nat × Nat) :=
  [(0,1),(0,2),(0,3),(0,4),(1,2),(1,3),(1,4),(2,3),(2,4),(3,4)]

def K33E : List (Nat × Nat) :=
  [(0,3),(0,4),(0,5),(1,3),(1,4),(1,5),(2,3),(2,4),(2,5)]

-- K5：V=5 E=10 破坏边-顶点不等式 E ≤ 3(V-2)（Thm 8.3.2）⇒ 非平面
theorem K5_beats_ineq : 3 * (5 - 2) < K5E.length := by decide

-- K3,3：V=6 E=9 破坏二部广义不等式 E ≤ 2(V-2)（Thm 8.3.3）⇒ 非平面
theorem K33_beats_bip : 2 * (6 - 2) < K33E.length := by decide

theorem K5_handshake :
    lsum ((List.range 5).map (fun v => vdeg v K5E)) = 2 * 10 := rfl

-- ---------- 4. Hamilton 圈检查器（书例 8.2.2） ----------

def adjb (E : List (Nat × Nat)) (u v : Nat) : Bool :=
  E.any (fun e => (u == e.1 && v == e.2) || (v == e.1 && u == e.2))

def adjchain (adj : Nat → Nat → Bool) : List Nat → Bool
  | [] => true
  | x :: t =>
      match t with
      | [] => true
      | y :: _ => adj x y && adjchain adj t

def lastl : Nat → List Nat → Nat
  | d, [] => d
  | _, x :: t => lastl x t

-- 合法 Hamilton 圈：长 n、无重复、链上相邻皆边、首尾相接
def isHamCyc (adj : Nat → Nat → Bool) (n : Nat) (l : List Nat) : Bool :=
  (l.length == n)
  && (l.eraseDups.length == n)
  && adjchain adj l
  && (match l with
      | [] => true
      | x :: _ => adj (lastl 0 l) x)

def C5E : List (Nat × Nat) := [(0,1),(1,2),(2,3),(3,4),(4,0)]

theorem C5_is_ham : isHamCyc (adjb C5E) 5 [0,1,2,3,4] = true := by decide

theorem K5_is_ham : isHamCyc (adjb K5E) 5 [0,1,2,3,4] = true := by decide

-- 二部完全图平衡判据（书 Ex 8.2.17）：K_m,n 有 Ham 圈 ⟺ m=n
-- ——K3,3（3=3）有圈、K3,4（3≠4）无圈；穷举在 Prolog 通道
theorem K33_unbalanced : 3 ≠ 4 := by decide

-- ---------- 5. 首适贪心着色（书 §8.4.6 / Ex 8.4.21） ----------

-- 已着色邻居的色表：col 作用于 0..d-1 中 v 的邻居
def nbcol (adj : Nat → Nat → Bool) (col : Nat → Nat) (d v : Nat) : List Nat :=
  ((List.range d).filter (fun u => adj u v)).map col

-- 最小未用色：在 0..|L| 中取第一个不在 L 的颜色
def pick (L : List Nat) : Nat :=
  match (List.range (L.length + 1)).filter (fun c => !L.contains c) with
  | c :: _ => c
  | [] => 0

-- 鸽笼：range n 的元素全落在 L 里 ⇒ n ≤ |L|。
-- 账本警示：本版 core 无干净的鸽笼件；此处经 stdlib 的
-- List.erase 引理族（传递依赖 Classical.choice）达成——
-- pick_notin 及下游 greedy_valid/greedy_chroma 的账本因此
-- 含 [Classical.choice]，Coq 侧对应件零公理（NoDup_incl_length）
theorem range_pigeonhole : ∀ (n : Nat) (L : List Nat),
    (∀ x, x ∈ List.range n → x ∈ L) → n ≤ L.length := by
  intro n
  induction n with
  | zero => intro L _; exact Nat.zero_le _
  | succ n' ih =>
      intro L hsub
      have hn : n' ∈ L :=
        hsub n' (by rw [List.range_succ]
                    exact List.mem_append_right _ (List.mem_singleton.mpr rfl))
      have h1 : ∀ x, x ∈ List.range n' → x ∈ L.erase n' := by
        intro x hx
        have hxlt : x < n' := List.mem_range.mp hx
        exact (List.mem_erase_of_ne (fun he => by omega)).mpr
                (hsub x (by rw [List.range_succ]
                            exact List.mem_append_left _ hx))
      have h2 := ih (L.erase n') h1
      rw [List.length_erase_of_mem hn] at h2
      have h3 : 0 < L.length := List.length_pos_of_mem hn
      omega

theorem pick_notin : ∀ L : List Nat, pick L ∉ L := by
  intro L
  unfold pick
  match h : (List.range (L.length + 1)).filter (fun c => !L.contains c) with
  | c :: _ =>
      intro hmem
      have hcm : c ∈ (List.range (L.length + 1)).filter
                   (fun c => !L.contains c) :=
        h ▸ List.mem_cons_self
      have hf := (List.mem_filter.mp hcm).2
      rw [List.contains_iff.mpr hmem] at hf
      exact Bool.noConfusion hf
  | [] =>
      exfalso
      have hpg : L.length + 1 ≤ L.length := by
        apply range_pigeonhole (L.length + 1) L
        intro x hx
        by_cases hcx : L.contains x = true
        · exact List.contains_iff.mp hcx
        · exfalso
          have hcf : L.contains x = false := by
            cases hcc : L.contains x with
            | true => exact absurd hcc hcx
            | false => rfl
          have hfilt : x ∈ (List.range (L.length + 1)).filter
                         (fun c => !L.contains c) :=
            List.mem_filter.mpr ⟨hx, by rw [hcf]; rfl⟩
          rw [h] at hfilt
          cases hfilt
      omega

theorem pick_le : ∀ L : List Nat, pick L ≤ L.length := by
  intro L
  unfold pick
  match h : (List.range (L.length + 1)).filter (fun c => !L.contains c) with
  | c :: _ =>
      have hcm : c ∈ (List.range (L.length + 1)).filter
                   (fun c => !L.contains c) :=
        h ▸ List.mem_cons_self
      have hlt : c < L.length + 1 :=
        List.mem_range.mp (List.mem_filter.mp hcm).1
      show c ≤ L.length
      omega
  | [] => exact Nat.zero_le _

-- 贪心主定义：按顶点号 0,1,2,… 依次上色
def greedy (adj : Nat → Nat → Bool) : Nat → Nat → Nat
  | 0, _ => 0
  | d'+1, v =>
      if v < d' then greedy adj d' v
      else pick (nbcol adj (greedy adj d') d' v)

theorem greedy_step (adj : Nat → Nat → Bool) (d' v : Nat) :
    greedy adj (d'+1) v
      = (if v < d' then greedy adj d' v
         else pick (nbcol adj (greedy adj d') d' v)) := rfl

theorem greedy_self (adj : Nat → Nat → Bool) (d' : Nat) :
    greedy adj (d'+1) d' = pick (nbcol adj (greedy adj d') d' d') := by
  show (if d' < d' then greedy adj d' d'
        else pick (nbcol adj (greedy adj d') d' d'))
       = pick (nbcol adj (greedy adj d') d' d')
  rw [if_neg (Nat.lt_irrefl d')]

-- 合法性：对称 + 无自环的邻接下，相邻两点异色
theorem greedy_valid (adj : Nat → Nat → Bool)
    (Hsym : ∀ u v, adj u v = adj v u) (Hirr : ∀ v, adj v v = false) :
    ∀ d i j, i < d → j < d → adj i j = true →
    greedy adj d i ≠ greedy adj d j := by
  intro d
  induction d with
  | zero => intro i j hi _ _; omega
  | succ d' ih =>
      intro i j hi hj haij
      by_cases hi' : i < d'
      · by_cases hj' : j < d'
        · rw [greedy_step adj d' i, greedy_step adj d' j,
              if_pos hi', if_pos hj']
          exact ih i j hi' hj' haij
        · have hjq : j = d' := by omega
          rw [hjq] at haij
          rw [hjq]
          rw [greedy_step adj d' i, if_pos hi', greedy_self adj d']
          intro heq
          have hni : greedy adj d' i ∉ nbcol adj (greedy adj d') d' d' :=
            fun hin => pick_notin _ (heq ▸ hin)
          exact hni
            (List.mem_map.mpr
              ⟨i, List.mem_filter.mpr ⟨List.mem_range.mpr hi', haij⟩, rfl⟩)
      · have hiq : i = d' := by omega
        by_cases hj' : j < d'
        · rw [hiq] at haij
          rw [hiq, greedy_self adj d', greedy_step adj d' j, if_pos hj']
          intro heq
          have hnj : greedy adj d' j ∉ nbcol adj (greedy adj d') d' d' :=
            fun hin => pick_notin _ (heq.symm ▸ hin)
          exact hnj
            (List.mem_map.mpr
              ⟨j, List.mem_filter.mpr ⟨List.mem_range.mpr hj', by
                 rw [Hsym]; exact haij⟩, rfl⟩)
        · have hjq : j = d' := by omega
          rw [hiq, hjq] at haij
          rw [Hirr d'] at haij
          exact Bool.noConfusion haij

-- 色号上界：v 的色 ≤ 已着色邻居数 ≤ deg(v)——χ ≤ Δ+1 的机器核
theorem greedy_chroma (adj : Nat → Nat → Bool) : ∀ d v, v < d →
    greedy adj d v ≤ ((List.range d).filter (fun u => adj u v)).length := by
  intro d
  induction d with
  | zero => intro v hv; omega
  | succ d' ih =>
      intro v hv
      by_cases hv' : v < d'
      · rw [greedy_step adj d' v, if_pos hv', List.range_succ,
            List.filter_append, List.length_append]
        exact Nat.le_trans (ih v hv') (Nat.le_add_right _ _)
      · have hvq : v = d' := by omega
        rw [hvq, greedy_self adj d']
        have h1 := pick_le (nbcol adj (greedy adj d') d' d')
        unfold nbcol at h1
        rw [List.length_map] at h1
        rw [List.range_succ, List.filter_append, List.length_append]
        exact Nat.le_trans h1 (Nat.le_add_right _ _)

-- ---------- 6. 现场三：Petersen 图（书例 8.4.4c：χ=3） ----------
-- 外五边形 0-1-2-3-4；辐条 i-i+5；内五星 5-7,7-9,9-6,6-8,8-5
def PetE : List (Nat × Nat) :=
  [(0,1),(1,2),(2,3),(3,4),(4,0),
   (0,5),(1,6),(2,7),(3,8),(4,9),
   (5,7),(7,9),(9,6),(6,8),(8,5)]

theorem Pet_handshake :
    lsum ((List.range 10).map (fun v => vdeg v PetE)) = 2 * 15 := rfl

-- 首适贪心在顶点自然序下的 Petersen 着色：全表 ≤ 2（χ=3 上界侧；
-- 下界（无 2 着色——含奇圈 C5）由 Prolog 通道穷举）
#eval (List.range 10).map (fun v => greedy (adjb PetE) 10 v)

-- 输出着色对每条边异色（合法性检查的数值面）
#eval PetE.all (fun e =>
  !(greedy (adjb PetE) 10 e.1 == greedy (adjb PetE) 10 e.2))

-- ---------- 7. 冒烟与账本 ----------

#eval (List.range 4).map (fun v => vdeg v KonE)   -- [5,3,3,3]
#eval (K5E.length, K33E.length)                    -- (10, 9)
#eval greedy (adjb K5E) 5 0                        -- 0

#print axioms handshake
#print axioms greedy_valid
#print axioms greedy_chroma
#print axioms pick_notin
#print axioms C5_is_ham
