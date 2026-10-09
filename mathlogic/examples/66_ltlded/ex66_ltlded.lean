/- ex37 —— 时态演绎系统 L（Ben-Ari 3e ch14）Lean 镜像
   lth 深嵌入（六公理 + MP/Gen□/GenX）+ lth_sound（对一切路径解释
   可靠；归纳公理对距离归纳）+ 14.2/14.4 原式推导。命题模式取
   Ben-Ari「全体重言」的构造性子集（K3 反证式会破坏零公理账本）。 -/

inductive Lform : Type
  | atom (p : Nat)
  | not (a : Lform)
  | and (a b : Lform)
  | imp (a b : Lform)
  | next (a : Lform)   -- X
  | box (a : Lform)    -- □
  deriving Repr

open Lform

-- 路径语义：解释 = 状态×原子 ↦ 真值；路径 = nat
abbrev Iass := Nat → Nat → Bool

def lsat (I : Iass) (k : Nat) (f : Lform) : Prop :=
  match f with
  | .atom p => I k p = true
  | .not a => ¬ lsat I k a
  | .and a b => lsat I k a ∧ lsat I k b
  | .imp a b => lsat I k a → lsat I k b
  | .next a => lsat I (k + 1) a
  | .box a => ∀ j, k ≤ j → lsat I j a

inductive Lth : Lform → Prop
  | pK1 (a b) : Lth (.imp a (.imp b a))
  | pK2 (a b c) : Lth (.imp (.imp a (.imp b c)) (.imp (.imp a b) (.imp a c)))
  | pAnd1 (a b) : Lth (.imp (.and a b) a)
  | pAnd2 (a b) : Lth (.imp (.and a b) b)
  | pAndI (a b) : Lth (.imp a (.imp b (.and a b)))
  | pPair (c a b) : Lth (.imp (.imp c a) (.imp (.imp c b) (.imp c (.and a b))))
  | pTrans (a b c) : Lth (.imp (.imp a b) (.imp (.imp b c) (.imp a c)))
  | lMP (a b) : Lth (.imp a b) → Lth a → Lth b
  | lGen (a) : Lth a → Lth (.box a)
  | lGenX (a) : Lth a → Lth (.next a)
  | lDist (a b) : Lth (.imp (.box (.imp a b)) (.imp (.box a) (.box b)))
  | lDistX (a b) : Lth (.imp (.next (.imp a b)) (.imp (.next a) (.next b)))
  | lExp (a) : Lth (.imp (.box a) (.and a (.next (.box a))))
  | lInd (a) : Lth (.imp (.box (.imp a (.next a))) (.imp a (.box a)))
  | lLin (a) : Lth (.imp (.next a) (.not (.next (.not a))))

open Lth

/-- 旗舰：对一切路径解释可靠 -/
theorem lth_sound : ∀ {f}, Lth f → ∀ (I : Iass) k, lsat I k f := by
  intro f h
  induction h with
  | pK1 a b => intro I k ha _; exact ha
  | pK2 a b c => intro I k h1 h2 ha; exact h1 ha (h2 ha)
  | pAnd1 a b => intro I k h; exact h.1
  | pAnd2 a b => intro I k h; exact h.2
  | pAndI a b => intro I k ha hb; exact ⟨ha, hb⟩
  | pPair c a b =>
    intro I k h1 h2 hc; exact ⟨h1 hc, h2 hc⟩
  | pTrans a b c =>
    intro I k hab hbc ha; exact hbc (hab ha)
  | lMP a b h1 h2 ih1 ih2 =>
    intro I k; exact ih1 I k (ih2 I k)
  | lGen a h ih =>
    intro I k j hj; exact ih I j
  | lGenX a h ih =>
    intro I k; exact ih I (k + 1)
  | lDist a b =>
    intro I k hbox ha j hj
    exact hbox j hj (ha j hj)
  | lDistX a b =>
    intro I k hnx ha
    exact hnx ha
  | lExp a =>
    intro I k hbox
    refine ⟨hbox k (Nat.le_refl k), ?_⟩
    intro j hj
    exact hbox j (Nat.le_trans (Nat.le_succ k) hj)
  | lInd a =>
    intro I k hstep ha j hj
    have hchain : ∀ d, lsat I (k + d) a := by
      intro d
      induction d with
      | zero => simp [Nat.add_zero]; exact ha
      | succ d ihd =>
        have hle : k ≤ k + d := Nat.le_add_right k d
        exact hstep (k + d) hle ihd
    have hj' : j = k + (j - k) := by omega
    rw [hj']; exact hchain (j - k)
  | lLin a =>
    intro I k hnx hnn; exact hnn hnx

/- ============ Ben-Ari 14.2 / 14.4 原式推导 ============ -/

/-- 定理 14.2（前向）：X(p∧q) → (Xp ∧ Xq) -/
theorem th142_fwd (a b : Lform) :
    Lth (.imp (.next (.and a b)) (.and (.next a) (.next b))) :=
  lMP _ _
    (lMP _ _
      (pPair (.next (.and a b)) (.next a) (.next b))
      (lMP _ _ (lDistX (.and a b) a) (lGenX _ (pAnd1 a b))))
    (lMP _ _ (lDistX (.and a b) b) (lGenX _ (pAnd2 a b)))

/-- 定理 14.4（收缩）：p ∧ X□p → □p（不变式方法的演算化身） -/
theorem th144_contraction (a : Lform) :
    Lth (.imp (.and a (.next (.box a))) (.box a)) := by
  -- (1) X□a → X(a ∧ X□a)
  have hxr : Lth (.imp (.next (.box a)) (.next (.and a (.next (.box a))))) :=
    lMP _ _ (lDistX (.box a) (.and a (.next (.box a))))
      (lGenX _ (lExp a))
  -- (2) r → Xr
  have hrr : Lth (.imp (.and a (.next (.box a)))
                      (.next (.and a (.next (.box a))))) :=
    lMP _ _ (lMP _ _
      (pTrans (.and a (.next (.box a))) (.next (.box a))
              (.next (.and a (.next (.box a)))))
      (pAnd2 a (.next (.box a)))) hxr
  -- (3) 归纳：□(r→Xr) 与 r 给出 □r
  have hgr : Lth (.box (.imp (.and a (.next (.box a)))
                             (.next (.and a (.next (.box a)))))) :=
    lGen _ hrr
  have hind : Lth (.imp (.and a (.next (.box a)))
                        (.box (.and a (.next (.box a))))) :=
    lMP _ _ (lInd (.and a (.next (.box a)))) hgr
  -- (4) □r → □a
  have hbra : Lth (.imp (.box (.and a (.next (.box a)))) (.box a)) :=
    lMP _ _ (lDist (.and a (.next (.box a))) a)
      (lGen _ (pAnd1 a (.next (.box a))))
  -- (5) 组装
  exact lMP _ _ (lMP _ _
    (pTrans (.and a (.next (.box a)))
            (.box (.and a (.next (.box a)))) (.box a))
    hind) hbra

#print axioms lth_sound
#print axioms th144_contraction
