(* ex78_provability.v —— 可证性条件 D1-D3、对角化与 Löb 定理（郝 ch9.3+ch10）
   抽象层：der : Form -> Prop 读作 T ⊢ α；□α 读作 bwb_T(⌜α⌝)。
   机器件：D0 条件引理 10.1.1；¬□ 不动点 ⟺ con 断言（第二定理内核）；
   (10.2) T ⊢ con → ¬□con；Gödel II（若 ⊢con 则 ⊢⊥）；Löb 步引理、
   公理 D4 与规则形（辛钦问题的答案：□ 的不动点恰为内定理）；Gödel II
   的 Löb 一行版；习题 10.4.1 等价替换引理。全部推导只用 D1/D2/D3 +
   直觉主义命题重言式 + 显式不动点——「证明论骨架」与「算术化肉身」
   （75/77 章）在此分离。零公理（Print Assumptions 记账）。 *)

From Stdlib Require Import List Arith.
Import ListNotations.

(* ---------- 1. 语法与语义骨架 ---------- *)

(* 模态式抽象语法：atom n | ⊥ | → | □。
   真实算术里 atom n 是算术公式的化身、□α 是 bwb_T(⌜α⌝) 的化身。 *)
Inductive Form : Type :=
| atom : nat -> Form
| fbot : Form
| fimp : Form -> Form -> Form
| fbox : Form -> Form.

(* 命题赋值：atom 赋 v，□ 子式赋 bx（□ 非真值函数，只能作任意一元谓词）。
   mval 是纯直觉主义解释——本章所有命题步骤都不需要经典。 *)
Fixpoint mval (v : nat -> Prop) (bx : Form -> Prop) (a : Form) : Prop :=
  match a with
  | atom n => v n
  | fbot => False
  | fimp b c => mval v bx b -> mval v bx c
  | fbox x => bx x
  end.

(* 直觉主义命题重言式：对所有赋值成真 *)
Definition Taut (a : Form) : Prop :=
  forall (v : nat -> Prop) (bx : Form -> Prop), mval v bx a.

(* ---------- 2. 可证性条件（Hilbert–Bernays–Löb） ---------- *)

Section Provability.

Variable der : Form -> Prop.                          (* T ⊢ α *)
Hypothesis Htaut : forall a, Taut a -> der a.         (* 重言式都是内定理 *)
Hypothesis Hmp   : forall a b, der (fimp a b) -> der a -> der b.  (* 分离 *)
Hypothesis Hd1   : forall a, der a -> der (fbox a).   (* (D1) ⊢α ⟹ ⊢□α *)
Hypothesis Hd2   : forall a b,
  der (fimp (fbox (fimp a b)) (fimp (fbox a) (fbox b))).        (* (D2) *)
Hypothesis Hd3   : forall a,
  der (fimp (fbox a) (fbox (fbox a))).                          (* (D3) *)
(* 对角化引理（9.3）作为显式假设：其算术化肉身由 75/77 章供给 *)
Hypothesis Hdiag : forall b, exists g,
  der (fimp g (fimp (fbox g) b)) /\ der (fimp (fimp (fbox g) b) g).

(* ---------- 3. 两个组合子：重言提升与链式传递 ---------- *)

(* tauti：语义蕴涵 ⟹ 推演（Htaut 的不动点用法） *)
Lemma tauti : forall a b,
  (forall v bx, mval v bx a -> mval v bx b) -> der (fimp a b).
Proof. intros a b H; apply Htaut; exact H. Qed.

(* imp_trans：⊢a→b、⊢b→c ⟹ ⊢a→c *)
Lemma imp_trans : forall a b c,
  der (fimp a b) -> der (fimp b c) -> der (fimp a c).
Proof.
  intros a b c Hab Hbc.
  assert (Ht : Taut (fimp (fimp a b) (fimp (fimp b c) (fimp a c)))).
  { intros v bx H1 H2 H3; exact (H2 (H1 H3)). }
  exact (Hmp _ _ (Hmp _ _ (Htaut _ Ht) Hab) Hbc).
Qed.

(* imp_distr：⊢a→(b→c)、⊢a→b ⟹ ⊢a→c（S 组合子：两个前件合并） *)
Lemma imp_distr : forall a b c,
  der (fimp a (fimp b c)) -> der (fimp a b) -> der (fimp a c).
Proof.
  intros a b c H1 H2.
  assert (Hsc : der (fimp (fimp a (fimp b c)) (fimp (fimp a b) (fimp a c)))).
  { apply tauti. intros v bx Hab Hb Ha; exact (Hab Ha (Hb Ha)). }
  exact (Hmp _ _ (Hmp _ _ Hsc H1) H2).
Qed.

(* ---------- 4. (D0)：引理 10.1.1 ---------- *)

(* (D0)：若 ⊢ a→c 则 ⊢ □a→□c（D1 与 D2 的联合） *)
Lemma D0 : forall a c, der (fimp a c) -> der (fimp (fbox a) (fbox c)).
Proof.
  intros a c Hac.
  exact (Hmp _ _ (Hd2 a c) (Hd1 (fimp a c) Hac)).
Qed.

(* 习题 10.4.1（Rautenberg 引理）：⊢α↔β ⟹ ⊢□α↔□β——「代回」的合法性 *)
Lemma box_mono : forall a b,
  der (fimp a b) -> der (fimp b a) ->
  der (fimp (fbox a) (fbox b)) /\ der (fimp (fbox b) (fbox a)).
Proof.
  intros a b Hab Hba; split; apply D0; assumption.
Qed.

(* ---------- 5. 一致性句子与 Gödel 句（定理 10.4.1 断言） ---------- *)

Definition conf : Form := fimp (fbox fbot) fbot.    (* con_T := ¬□⊥ *)

(* 关键账：g ↔ ¬□g 的不动点满足 ⊢ □g → □⊥。
   前腿 D0+D2，后腿 D3——正是第二定理「形式化」的骨架。 *)
Lemma boxg_boxbot : forall g,
  der (fimp g (fimp (fbox g) fbot)) -> der (fimp (fbox g) (fbox fbot)).
Proof.
  intros g Hfwd.
  assert (H1 := D0 g (fimp (fbox g) fbot) Hfwd).  (* ⊢ □g→□(□g→⊥) *)
  assert (H2 := Hd2 (fbox g) fbot).               (* ⊢ □(□g→⊥)→(□□g→□⊥) *)
  assert (H3 := Hd3 g).                           (* ⊢ □g→□□g *)
  exact (imp_distr _ _ _ (imp_trans _ _ _ H1 H2) H3).
Qed.

(* 定理 10.4.1 断言：¬□ 的不动点在 T 等价意义下唯一——都等价于 con *)
Theorem godel_sentence_iff_con : forall g,
  der (fimp g (fimp (fbox g) fbot)) ->
  der (fimp (fimp (fbox g) fbot) g) ->
  der (fimp g conf) /\ der (fimp conf g).
Proof.
  intros g Hfwd Hrev.
  assert (Hbb := boxg_boxbot g Hfwd).              (* ⊢ □g→□⊥ *)
  (* con → g：(□g→□⊥)→(con→(□g→⊥)) 与 (□g→⊥)→g 经 Hmp 接上 Hbb *)
  assert (Hc1 : der (fimp (fimp (fbox g) (fbox fbot))
                          (fimp conf (fimp (fbox g) fbot)))).
  { apply tauti. intros v bx H1 Hc Hbg; exact (Hc (H1 Hbg)). }
  assert (Hcon_g : der (fimp conf g)).
  { exact (imp_trans _ _ _ (Hmp _ _ Hc1 Hbb) Hrev). }
  (* g → con：⊥→g 是重言式，D0 得 □⊥→□g；与 Hfwd 拼 *)
  assert (Hbg : der (fimp (fbox fbot) (fbox g))).
  { apply D0. apply tauti. intros v bx Hf; contradiction. }
  assert (Hc2 : der (fimp (fimp (fbox fbot) (fbox g))
                          (fimp (fimp g (fimp (fbox g) fbot)) (fimp g conf)))).
  { apply tauti. intros v bx H1 H2 Hg Hb; exact (H2 Hg (H1 Hb)). }
  assert (Hg_con : der (fimp g conf)).
  { exact (Hmp _ _ (Hmp _ _ Hc2 Hbg) Hfwd). }
  exact (conj Hg_con Hcon_g).
Qed.

(* ---------- 6. (10.2) 与 Gödel 第二不完备性定理 ---------- *)

(* (10.2)：T ⊢ con → ¬□con——「若我一致，则我证不出我的一致性」 *)
Theorem con_unprovable_formal : der (fimp conf (fimp (fbox conf) fbot)).
Proof.
  destruct (Hdiag fbot) as [g [Hfwd Hrev]].
  destruct (godel_sentence_iff_con g Hfwd Hrev) as [Hg_con Hcon_g].
  assert (Hbb : der (fimp (fbox g) (fbox fbot))).
  { exact (boxg_boxbot g Hfwd). }
  (* ⊢ □con→□g（D0 作用于 con→g），接 □g→□⊥ 得 □con→□⊥ *)
  assert (H1 := D0 _ _ Hcon_g).              (* ⊢ □con→□g *)
  assert (H2 := imp_trans _ _ _ H1 Hbb).     (* ⊢ □con→□⊥ *)
  (* 命题整理：(□con→□⊥) → (con→(□con→⊥))，再与 H2 作分离 *)
  assert (Ht : der (fimp (fimp (fbox conf) (fbox fbot))
                          (fimp conf (fimp (fbox conf) fbot)))).
  { apply tauti. intros v bx Hab Hc Hbc; exact (Hc (Hab Hbc)). }
  exact (Hmp _ _ Ht H2).
Qed.

(* Gödel II（定理 10.4.1(1) 的机器面）：若 T ⊢ con 则 T ⊢ ⊥。
   元数学读法：一致的 T 不可能证明自身一致性。 *)
Theorem goedel_second : der conf -> der fbot.
Proof.
  intros Hcon.
  assert (Hneg : der (fimp (fbox conf) fbot)).
  { exact (Hmp _ _ (con_unprovable_formal) Hcon). }
  exact (Hmp _ _ Hneg (Hd1 conf Hcon)).
Qed.

(* ---------- 7. Löb 定理（定理 10.4.2） ---------- *)

(* Löb 步引理：h ↔ (□h→a) 的不动点满足 ⊢ □h→□a（书中 (10.4) 前半） *)
Lemma lob_step : forall a h,
  der (fimp h (fimp (fbox h) a)) -> der (fimp (fbox h) (fbox a)).
Proof.
  intros a h Hfwd.
  assert (H1 := D0 h (fimp (fbox h) a) Hfwd).   (* ⊢ □h→□(□h→a) *)
  assert (H2 := Hd2 (fbox h) a).                (* ⊢ □(□h→a)→(□□h→□a) *)
  assert (H3 := Hd3 h).                         (* ⊢ □h→□□h *)
  exact (imp_distr _ _ _ (imp_trans _ _ _ H1 H2) H3).
Qed.

(* Löb 公理形（(D4)）：⊢ □(□a→a) → □a *)
Theorem lob_axiom : forall a,
  der (fimp (fbox (fimp (fbox a) a)) (fbox a)).
Proof.
  intros a.
  destruct (Hdiag a) as [h [Hfwd Hrev]].
  assert (H4 := lob_step a h Hfwd).          (* ⊢ □h→□a *)
  (* (□h→□a) ⟹ (□a→a)→(□h→a) ⟹（接 Hrev）(□a→a)→h *)
  assert (H5 : der (fimp (fimp (fbox a) a) (fimp (fbox h) a))).
  { assert (Ht : der (fimp (fimp (fbox h) (fbox a))
                          (fimp (fimp (fbox a) a) (fimp (fbox h) a)))).
    { apply tauti. intros v bx H4' Hla Hbh; exact (Hla (H4' Hbh)). }
    exact (Hmp _ _ Ht H4). }
  assert (H6 := imp_trans _ _ _ H5 Hrev).    (* ⊢ (□a→a)→h *)
  (* D0：⊢ □(□a→a)→□h；接 H4 得 □(□a→a)→□a *)
  exact (imp_trans _ _ _ (D0 _ _ H6) H4).
Qed.

(* Löb 规则形（定理 10.4.2(2)）：若 ⊢ □a→a 则 ⊢ a *)
Theorem lob_rule : forall a, der (fimp (fbox a) a) -> der a.
Proof.
  intros a Hla.
  destruct (Hdiag a) as [h [Hfwd Hrev]].
  assert (H4 := lob_step a h Hfwd).          (* ⊢ □h→□a *)
  (* ⊢ □h→a（H4 接 Hla），再接 Hrev 得 ⊢ h *)
  assert (Hha := imp_trans _ _ _ H4 Hla).    (* ⊢ □h→a *)
  assert (Hh := Hmp _ _ Hrev Hha).           (* ⊢ h *)
  (* ⊢ □h（D1），接 H4 与 Hla 得 ⊢ a *)
  assert (Hbh := Hd1 h Hh).
  exact (Hmp _ _ Hla (Hmp _ _ H4 Hbh)).
Qed.

(* 推论 10.4.1（Henkin/辛钦问题的答案）：□ 的不动点恰为内定理——
   若 x ↔ □x 则 ⊢ x（「我可证」的自指者说的必定是真话） *)
Theorem henkin_answer : forall x,
  der (fimp x (fbox x)) -> der (fimp (fbox x) x) -> der x.
Proof.
  intros x Hfwd Hrev.
  (* 不动点给出 □x→x（Hrev），Löb 规则直接封口 *)
  exact (lob_rule x Hrev).
Qed.

(* Gödel II 的 Löb 一行版：取 a=⊥，⊢ □⊥→⊥ 即 ⊢con，Löb 给 ⊢⊥ *)
Theorem goedel_second_via_lob : der conf -> der fbot.
Proof.
  intros Hcon; exact (lob_rule fbot Hcon).
Qed.

End Provability.

(* ---------- 8. 记账 ---------- *)

Print Assumptions goedel_second.
Print Assumptions lob_axiom.
Print Assumptions lob_rule.
Print Assumptions henkin_answer.
