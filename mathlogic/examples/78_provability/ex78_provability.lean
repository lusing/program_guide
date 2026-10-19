/- ex78_provability.lean —— 可证性条件 D1-D3、对角化与 Löb 定理（郝 ch9.3+ch10）
   与 Coq 通道同账：der : Form → Prop（T ⊢ α）、□α = bwb_T(⌜α⌝) 的化身。
   Lean 侧用 structure Prov 打包六条假设（重言封闭+分离+D1/D2/D3+对角化），
   证明：D0、□g→□⊥ 账、¬□ 不动点 ⟺ con、(10.2)、Gödel II、Löb 步引理/
   公理 D4/规则形、Henkin 问题的答案。零公理（#print axioms 记账）。 -/

set_option linter.unusedVariables false

-- ---------- 1. 语法与语义骨架 ----------

inductive Form : Type where
  | atom : Nat → Form
  | fbot : Form
  | fimp : Form → Form → Form
  | fbox : Form → Form
  deriving Repr

open Form

/-- 命题赋值：atom 走 v、□ 子式走 bx（□ 非真值函数）。纯直觉主义解释。 -/
def mval (v : Nat → Prop) (bx : Form → Prop) : Form → Prop
  | atom n => v n
  | fbot => False
  | fimp b c => mval v bx b → mval v bx c
  | fbox x => bx x

/-- 直觉主义命题重言式 -/
def Taut (a : Form) : Prop :=
  ∀ (v : Nat → Prop) (bx : Form → Prop), mval v bx a

-- ---------- 2. 可证性条件打包 ----------

/-- 六条假设：der = T ⊢ α；重言式都是内定理；分离规则；D1/D2/D3；对角化。 -/
structure Prov where
  der : Form → Prop
  htaut : ∀ a, Taut a → der a
  hmp : ∀ a b, der (fimp a b) → der a → der b
  hd1 : ∀ a, der a → der (fbox a)                       -- (D1)
  hd2 : ∀ a b, der (fimp (fbox (fimp a b)) (fimp (fbox a) (fbox b)))  -- (D2)
  hd3 : ∀ a, der (fimp (fbox a) (fbox (fbox a)))        -- (D3)
  -- 对角化引理（9.3）作为显式假设：肉身由 75/77 章算术化供给
  hdiag : ∀ b, ∃ g, der (fimp g (fimp (fbox g) b)) ∧ der (fimp (fimp (fbox g) b) g)

variable {P : Prov}

-- ---------- 3. 三个组合子 ----------

/-- tauti：语义蕴涵 ⟹ 推演 -/
theorem tauti (a b : Form)
    (h : ∀ v bx, mval v bx a → mval v bx b) : P.der (fimp a b) :=
  P.htaut (fimp a b) h

/-- imp_trans：⊢a→b、⊢b→c ⟹ ⊢a→c -/
theorem imp_trans (a b c : Form)
    (hab : P.der (fimp a b)) (hbc : P.der (fimp b c)) : P.der (fimp a c) :=
  P.hmp (fimp b c) (fimp a c)
    (P.hmp (fimp a b) (fimp (fimp b c) (fimp a c))
      (tauti (fimp a b) (fimp (fimp b c) (fimp a c))
        (fun _ _ h1 h2 h3 => h2 (h1 h3))) hab) hbc

/-- imp_distr：⊢a→(b→c)、⊢a→b ⟹ ⊢a→c（S 组合子） -/
theorem imp_distr (a b c : Form)
    (h1 : P.der (fimp a (fimp b c))) (h2 : P.der (fimp a b)) : P.der (fimp a c) :=
  P.hmp (fimp a b) (fimp a c)
    (P.hmp (fimp a (fimp b c)) (fimp (fimp a b) (fimp a c))
      (tauti (fimp a (fimp b c)) (fimp (fimp a b) (fimp a c))
        (fun _ _ hab hb ha => hab ha (hb ha))) h1) h2

-- ---------- 4. (D0)：引理 10.1.1 ----------

theorem D0 (a c : Form) (hac : P.der (fimp a c)) :
    P.der (fimp (fbox a) (fbox c)) :=
  P.hmp _ _ (P.hd2 a c) (P.hd1 (fimp a c) hac)

-- ---------- 5. 一致性句子与 Gödel 句 ----------

def conf : Form := fimp (fbox fbot) fbot   -- con_T := ¬□⊥

/-- 关键账：g ↔ ¬□g 的不动点满足 ⊢ □g → □⊥ -/
theorem boxg_boxbot (g : Form)
    (hfwd : P.der (fimp g (fimp (fbox g) fbot))) :
    P.der (fimp (fbox g) (fbox fbot)) :=
  imp_distr _ _ _
    (imp_trans _ _ _ (D0 g (fimp (fbox g) fbot) hfwd) (P.hd2 (fbox g) fbot))
    (P.hd3 g)

/-- 定理 10.4.1 断言：¬□ 的不动点在 T 等价意义下唯一——都等价于 con -/
theorem godel_sentence_iff_con (g : Form)
    (hfwd : P.der (fimp g (fimp (fbox g) fbot)))
    (hrev : P.der (fimp (fimp (fbox g) fbot) g)) :
    P.der (fimp g conf) ∧ P.der (fimp conf g) := by
  have hbb := boxg_boxbot g hfwd                -- ⊢ □g→□⊥
  -- con → g：(□g→□⊥)→(con→(□g→⊥)) 与 hrev 拼
  have hc1 : P.der (fimp (fimp (fbox g) (fbox fbot))
                         (fimp conf (fimp (fbox g) fbot))) :=
    tauti _ _ (fun _ _ h1 hc hbg => hc (h1 hbg))
  have hcon_g : P.der (fimp conf g) :=
    imp_trans _ _ _ (P.hmp _ _ hc1 hbb) hrev
  -- g → con：⊥→g 是重言式，D0 得 □⊥→□g；与 hfwd 拼
  have hbg : P.der (fimp (fbox fbot) (fbox g)) :=
    D0 _ _ (tauti _ _ (fun _ _ hf => hf.elim))
  have hc2 : P.der (fimp (fimp (fbox fbot) (fbox g))
                         (fimp (fimp g (fimp (fbox g) fbot)) (fimp g conf))) :=
    tauti _ _ (fun _ _ h1 h2 hg hb => h2 hg (h1 hb))
  exact ⟨P.hmp _ _ (P.hmp _ _ hc2 hbg) hfwd, hcon_g⟩

-- ---------- 6. (10.2) 与 Gödel 第二不完备性定理 ----------

/-- (10.2)：T ⊢ con → ¬□con -/
theorem con_unprovable_formal :
    P.der (fimp conf (fimp (fbox conf) fbot)) := by
  obtain ⟨g, hfwd, hrev⟩ := P.hdiag fbot
  obtain ⟨_, hcon_g⟩ := godel_sentence_iff_con g hfwd hrev
  have hbb := boxg_boxbot g hfwd
  have h1 := D0 _ _ hcon_g                -- ⊢ □con→□g
  have h2 := imp_trans _ _ _ h1 hbb       -- ⊢ □con→□⊥
  have ht : P.der (fimp (fimp (fbox conf) (fbox fbot))
                         (fimp conf (fimp (fbox conf) fbot))) :=
    tauti _ _ (fun _ _ hab hc hbc => hc (hab hbc))
  exact P.hmp _ _ ht h2

/-- Gödel II（机器面）：若 T ⊢ con 则 T ⊢ ⊥ -/
theorem goedel_second (hcon : P.der conf) : P.der fbot :=
  P.hmp _ _ (P.hmp _ _ con_unprovable_formal hcon) (P.hd1 conf hcon)

-- ---------- 7. Löb 定理（定理 10.4.2） ----------

/-- Löb 步引理：h ↔ (□h→a) 满足 ⊢ □h→□a（书中 (10.4) 前半） -/
theorem lob_step (a h : Form)
    (hfwd : P.der (fimp h (fimp (fbox h) a))) :
    P.der (fimp (fbox h) (fbox a)) :=
  imp_distr _ _ _
    (imp_trans _ _ _ (D0 h (fimp (fbox h) a) hfwd) (P.hd2 (fbox h) a))
    (P.hd3 h)

/-- Löb 公理形（(D4)）：⊢ □(□a→a) → □a -/
theorem lob_axiom (a : Form) :
    P.der (fimp (fbox (fimp (fbox a) a)) (fbox a)) := by
  obtain ⟨h, hfwd, hrev⟩ := P.hdiag a
  have h4 := lob_step a h hfwd            -- ⊢ □h→□a
  have h5 : P.der (fimp (fimp (fbox a) a) (fimp (fbox h) a)) :=
    P.hmp _ _ (tauti (fimp (fbox h) (fbox a))
      (fimp (fimp (fbox a) a) (fimp (fbox h) a))
      (fun _ _ h4' hla hbh => hla (h4' hbh))) h4
  have h6 := imp_trans _ _ _ h5 hrev      -- ⊢ (□a→a)→h
  exact imp_trans _ _ _ (D0 _ _ h6) h4

/-- Löb 规则形（定理 10.4.2(2)）：若 ⊢ □a→a 则 ⊢ a -/
theorem lob_rule (a : Form) (hla : P.der (fimp (fbox a) a)) : P.der a := by
  obtain ⟨h, hfwd, hrev⟩ := P.hdiag a
  have h4 := lob_step a h hfwd
  have hha := imp_trans _ _ _ h4 hla      -- ⊢ □h→a
  have hh := P.hmp _ _ hrev hha           -- ⊢ h
  exact P.hmp _ _ hla (P.hmp _ _ h4 (P.hd1 h hh))

/-- 推论 10.4.1：□ 的不动点恰为内定理（「我可证」的自指者必真） -/
theorem henkin_answer (x : Form)
    (hfwd : P.der (fimp x (fbox x))) (hrev : P.der (fimp (fbox x) x)) :
    P.der x :=
  lob_rule x hrev

/-- Gödel II 的 Löb 一行版：a=⊥ 时 □⊥→⊥ 即 con -/
theorem goedel_second_via_lob (hcon : P.der conf) : P.der fbot :=
  lob_rule fbot hcon

-- ---------- 8. 记账 ----------

#print axioms boxg_boxbot
#print axioms godel_sentence_iff_con
#print axioms con_unprovable_formal
#print axioms goedel_second
#print axioms lob_axiom
#print axioms lob_rule
#print axioms henkin_answer
