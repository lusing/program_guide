(* ex20_seqfol.v —— EFT 矢列演算 S 的 FOL 版：量词与等词（书 ch IV）
   最小语言：¬ ∨ ∃ ≡（∧ → ∀ 为缩写）。矢列 = 前件公式表 + 单一后件。
   规则即构造子：Assm/Ant/PC/Ctr/∨A/∨S(a)(b)/∃S/∃A(侧条件)/≡/Sub。
   机器件：可导规则（TND/链式 Ch/双重否定消去/等词对称传递/∀ 实例化/
   MP）+ 群论例（右幺+右逆+结合 ⇒ 存在左逆——书 IV.6 的等式链现场）+
   协调性（Inc ⟺ 推出一切，书 IV.7.2）+ 命题片段可靠性。 *)

(* ---------- 1. 语法：项与公式 ---------- *)

Inductive tm : Type :=
| var : nat -> tm
| fsym : nat -> list tm -> tm.        (* 函词 f 施于参数表 *)

Fixpoint substt (t : tm) (x : nat) (u : tm) : tm :=
  match t with
  | var n => if n =? x then u else var n
  | fsym f ts => fsym f (map (fun t => substt t x u) ts)
  end.

Fixpoint fvt (t : tm) : list nat :=
  match t with
  | var n => [n]
  | fsym _ ts => flat_map fvt ts
  end.

Inductive fm : Type :=
| rat : nat -> list tm -> fm          (* 关系词 R t1..tn *)
| eqf : tm -> tm -> fm                (* t ≡ t' *)
| neg : fm -> fm
| disj : fm -> fm -> fm
| exq : nat -> fm -> fm.              (* ∃x φ；∀x φ := ¬∃x¬φ *)

Fixpoint fv (φ : fm) : list nat :=
  match φ with
  | rat _ ts => flat_map fvt ts
  | eqf t1 t2 => fvt t1 ++ fvt t2
  | neg ψ => fv ψ
  | disj ψ χ => fv ψ ++ fv χ
  | exq x ψ => remove x (fv ψ)
  end.

Fixpoint substf (φ : fm) (x : nat) (u : tm) : fm :=
  match φ with
  | rat r ts => rat r (map (fun t => substt t x u) ts)
  | eqf t1 t2 => eqf (substt t1 x u) (substt t2 x u)
  | neg ψ => neg (substf ψ x u)
  | disj ψ χ => disj (substf ψ x u) (substf χ x u)
  | exq y ψ => if y =? x then exq y ψ else exq y (substf ψ x u)
  end.

Definition conj (φ ψ : fm) : fm := neg (disj (neg φ) (neg ψ)).
Definition imp (φ ψ : fm) : fm := disj (neg φ) ψ.
Definition all (x : nat) (φ : fm) : fm := neg (exq x (neg φ)).

Definition fv_l (Γ : list fm) : list nat := flat_map fv Γ.

(* ---------- 2. 矢列演算 S（书 IV.2/IV.4 全规则） ---------- *)

Inductive der : list fm -> fm -> Prop :=
| Assm : forall Γ φ, In φ Γ -> der Γ φ
| Ant : forall Γ Γ' φ, incl Γ Γ' -> der Γ φ -> der Γ' φ
| PC : forall Γ ψ φ, der (ψ :: Γ) φ -> der (neg ψ :: Γ) φ -> der Γ φ
| Ctr : forall Γ φ ψ,
    der (neg φ :: Γ) ψ -> der (neg φ :: Γ) (neg ψ) -> der Γ φ
| OrA : forall Γ φ ψ χ,
    der (φ :: Γ) χ -> der (ψ :: Γ) χ -> der (disj φ ψ :: Γ) χ
| OrSl : forall Γ φ ψ, der Γ φ -> der Γ (disj φ ψ)
| OrSr : forall Γ φ ψ, der Γ ψ -> der Γ (disj φ ψ)
| ExS : forall Γ x φ t, der Γ (substf φ x t) -> der Γ (exq x φ)
| ExA : forall Γ x φ ψ y,
    ~ In y (fv_l (exq x φ :: ψ :: Γ)) ->
    der (substf φ x (var y) :: Γ) ψ -> der (exq x φ :: Γ) ψ
| Ref : forall Γ t, der Γ (eqf t t)
| Sub : forall Γ x φ t t',
    der Γ (substf φ x t) -> der (eqf t t' :: Γ) (substf φ x t').

(* ---------- 3. 代入引理 ---------- *)

Lemma substt_self : forall t x, substt t x (var x) = t.
Proof.
  induction t as [n|f ts IH]; intros x; simpl.
  - destruct (n =? x) eqn:E.
    + apply Nat.eqb_eq in E; subst; reflexivity.
    + reflexivity.
  - f_equal. induction ts as [|a ts' IHts]; simpl; auto.
    rewrite IH, IHts. reflexivity.
Qed.

Lemma substf_self : forall φ x, substf φ x (var x) = φ.
Proof.
  induction φ; intros x; simpl; try (rewrite IHφ; reflexivity).
  - f_equal.
    induction l as [|a l IHl]; simpl; auto.
    rewrite substt_self, IHl. reflexivity.
  - rewrite !substt_self. reflexivity.
  - rewrite IHφ1, IHφ2. reflexivity.
  - destruct (n =? x) eqn:E; simpl.
    + apply Nat.eqb_eq in E; subst; reflexivity.
    + rewrite IHφ. reflexivity.
Qed.

(* 新鲜性：x 不在 t 的自由变元中，则代入不动 t（d_sym/d_trans 要用） *)
Lemma substt_fresh : forall t x u, ~ In x (fvt t) -> substt t x u = t.
Proof.
  induction t as [n|f ts IH]; intros x u H; simpl.
  - destruct (n =? x) eqn:E.
    + apply Nat.eqb_eq in E; subst. simpl in H. destruct H; auto.
    + reflexivity.
  - f_equal. induction ts as [|a ts' IHts]; simpl; auto.
    rewrite (IH a x u). auto. rewrite IHts; auto.
Qed.

Lemma maxl : forall L : list nat, exists m, forall n, In n L -> n <= m.
Proof.
  induction L as [|a L IH]; [exists 0; intros n H; destruct H|].
  destruct IH as [m Hm]. exists (Nat.max a m).
  intros n Hc. destruct Hc as [E|Hc].
  - subst; apply Nat.le_max_l.
  - apply Nat.max_le_iff. right. apply Hm; auto.
Qed.

Lemma pick_fresh : forall L : list nat, exists n, ~ In n L.
Proof.
  intros L. destruct (maxl L) as [m Hm].
  exists (S m). intros Hc.
  assert (S m <= m) by (apply Hm; auto). omega.
Qed.

(* ---------- 4. 可导规则（书 IV.3/IV.5） ---------- *)

(* 3.1 排中律：Γ ⊢ φ∨¬φ *)
Lemma d_tnd : forall Γ φ, der Γ (disj φ (neg φ)).
Proof.
  intros Γ φ. apply PC with (ψ := φ).
  - apply OrSl, Assm. left; reflexivity.
  - apply OrSr, Assm. left; reflexivity.
Qed.

(* 双重否定消去：Γ ⊢ ¬¬φ 则 Γ ⊢ φ *)
Lemma d_nne : forall Γ φ, der Γ (neg (neg φ)) -> der Γ φ.
Proof.
  intros Γ φ H. apply PC with (ψ := φ).
  - apply Assm. left; reflexivity.
  - apply Ctr with (ψ := neg φ).
    + apply Assm. left; reflexivity.
    + apply (Ant Γ).
      * apply incl_tl, incl_tl, incl_refl.
      * exact H.
Qed.

(* Ch 链式规则：Γ ⊢ χ 且 χ::Γ ⊢ ψ 则 Γ ⊢ ψ *)
Lemma d_ch : forall Γ χ ψ, der Γ χ -> der (χ :: Γ) ψ -> der Γ ψ.
Proof.
  intros Γ χ ψ Hc Hs. apply PC with (ψ := χ).
  - exact Hs.
  - apply Ctr with (ψ := χ).
    + apply (Ant (neg χ :: Γ)).
      * apply incl_cons; simpl; auto.
      * apply incl_cons_l.
      * apply incl_refl.
      * exact Hc.
    + apply Assm. left; reflexivity.
Qed.

(* 5.3(a) 等词对称（证明里挑新鲜变元做 Sub 的槽） *)
Lemma d_sym : forall Γ t1 t2, der Γ (eqf t1 t2) -> der Γ (eqf t2 t1).
Proof.
  intros Γ t1 t2 H.
  destruct (pick_fresh (fvt t1 ++ fvt t2 ++ fv_l Γ)) as [x Hx].
  apply d_ch with (χ := eqf t1 t2); [exact H|].
  apply Sub with (x := x) (φ := eqf (var x) t1).
  simpl. rewrite (substt_fresh t1 x (var t2)).
  - apply Ref.
  - intros Hc. apply in_app_iff in Hc as [Hc|Hc].
    + apply in_app_iff in Hc as [Hc|Hc]; auto.
      unfold fv_l in Hx. eapply in_flat_map; eauto.
    + apply in_app_iff in Hc as [Hc|Hc]; auto.
      unfold fv_l in Hx. eapply in_flat_map; eauto.
Qed.

(* 5.3(b) 等词传递 *)
Lemma d_trans : forall Γ t1 t2 t3,
    der Γ (eqf t1 t2) -> der Γ (eqf t2 t3) -> der Γ (eqf t1 t3).
Proof.
  intros Γ t1 t2 t3 H12 H23.
  destruct (pick_fresh (fvt t1 ++ fvt t3 ++ fv_l Γ)) as [x Hx].
  apply d_ch with (χ := eqf t2 t3); [exact H23|].
  apply Sub with (x := x) (φ := eqf t1 (var x)).
  apply (Ant Γ); auto.
  - apply incl_cons_l.
  - simpl. rewrite (substt_fresh t1 x (var t3)).
    + reflexivity.
    + intros Hc. apply in_app_iff in Hc as [Hc|Hc]; auto.
      unfold fv_l in Hx. eapply in_flat_map; eauto.
Qed.
