From Stdlib Require Import List Arith Lia.
Import ListNotations.

(* fv(∃xψ) 需要删光 x 的全部出现——自造 wipe（Stdlib.remove 带判等参数） *)
Fixpoint wipe (x : nat) (l : list nat) : list nat :=
  match l with
  | [] => []
  | a :: l' => if a =? x then wipe x l' else a :: wipe x l'
  end.

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
  | exq x ψ => wipe x (fv ψ)
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

(* 项的大小（fsym 的 list 参数不给逐元素 IH——按测度归纳） *)
Fixpoint tsize (t : tm) : nat :=
  match t with
  | var _ => 1
  | fsym _ ts => fold_right (fun a m => tsize a + m) 1 ts
  end.

Lemma fr_pos : forall ts, 1 <= fold_right (fun a m => tsize a + m) 1 ts.
Proof.
  induction ts as [|a ts IH]; simpl; lia.
Qed.

Lemma tsize_elem : forall ts f t, In t ts -> tsize t < tsize (fsym f ts).
Proof.
  induction ts as [|a ts IH]; intros f t H; simpl; [contradiction|].
  pose proof (fr_pos ts) as Hfr.
  destruct H as [E|H].
  - subst. lia.
  - specialize (IH f t H). simpl in IH. lia.
Qed.

Lemma map_self : forall ts x,
    (forall t, In t ts -> substt t x (var x) = t) ->
    map (fun t => substt t x (var x)) ts = ts.
Proof.
  induction ts as [|a ts IHl]; intros x H; simpl.
  - reflexivity.
  - rewrite (H a (or_introl eq_refl)). f_equal.
    apply IHl. intros t0 Ht0. apply H. right; exact Ht0.
Qed.

Lemma substt_self : forall t x, substt t x (var x) = t.
Proof.
  assert (Hn : forall n t, tsize t <= n -> forall x, substt t x (var x) = t).
  { induction n as [|n IH]; intros t Hn x.
    - destruct t as [|f ts]; simpl in Hn; [lia| pose proof (fr_pos ts); lia].
    - destruct t as [n0|f ts]; simpl.
      + destruct (Nat.eqb_spec n0 x); [subst; reflexivity | reflexivity].
      + f_equal. apply map_self. intros t0 Ht0. apply IH.
        assert (Hs : tsize t0 < tsize (fsym f ts)) by
          (apply (tsize_elem _ f); exact Ht0).
        simpl in Hn, Hs. lia. }
  intros t x. apply (Hn (tsize t)); auto.
Qed.

Lemma substf_self : forall φ x, substf φ x (var x) = φ.
Proof.
  induction φ; intros x; simpl; try (rewrite IHφ; reflexivity).
  - f_equal. induction l as [|a l IHl]; simpl; auto.
    rewrite substt_self, IHl. reflexivity.
  - rewrite !substt_self. reflexivity.
  - rewrite IHφ1, IHφ2. reflexivity.
  - destruct (n =? x) eqn:E; simpl.
    + apply Nat.eqb_eq in E; subst; reflexivity.
    + rewrite IHφ. reflexivity.
Qed.

(* 新鲜性：x 不在 t 的自由变元中，则代入不动 t（d_sym/d_trans 要用） *)
Lemma map_fresh : forall ts x u,
    (forall t, In t ts -> substt t x u = t) ->
    map (fun t => substt t x u) ts = ts.
Proof.
  induction ts as [|a ts IHl]; intros x u H; simpl.
  - reflexivity.
  - rewrite (H a (or_introl eq_refl)). f_equal.
    apply IHl. intros t0 Ht0. apply H. right; exact Ht0.
Qed.

Lemma substt_fresh : forall t x u, ~ In x (fvt t) -> substt t x u = t.
Proof.
  assert (Hn : forall n t, tsize t <= n ->
      forall x u, ~ In x (fvt t) -> substt t x u = t).
  { induction n as [|n IH]; intros t Hn x u Hfr.
    - destruct t as [|f ts]; simpl in Hn; [lia| pose proof (fr_pos ts); lia].
    - destruct t as [n0|f ts]; simpl.
      + destruct (Nat.eqb_spec n0 x) as [E|E].
        * exfalso. subst. simpl in Hfr. tauto.
        * reflexivity.
      + f_equal. apply map_fresh. intros t0 Ht0.
        assert (Hs : tsize t0 < tsize (fsym f ts)) by
          (apply (tsize_elem _ f); exact Ht0).
        simpl in Hn, Hs.
        apply IH; [lia|].
        simpl in Hfr. intros Hin. apply Hfr.
        apply in_flat_map. exists t0. split; [exact Ht0| exact Hin]. }
  intros t x u Hfr. apply (Hn (tsize t)); auto.
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
  assert (S m <= m) by (apply Hm; auto). lia.
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
    + apply (Ant Γ).
      * apply incl_tl, incl_tl, incl_refl.
      * exact Hc.
    + apply Assm. right; left; reflexivity.
Qed.

(* 5.3(a) 等词对称（证明里挑新鲜变元做 Sub 的槽） *)
Lemma notin_app1 : forall (x : nat) (l1 l2 : list nat),
    ~ In x (l1 ++ l2) -> ~ In x l1.
Proof. intros x l1 l2 H Hc. apply H. apply in_or_app. left; exact Hc. Qed.

Lemma notin_app2 : forall (x : nat) (l1 l2 : list nat),
    ~ In x (l1 ++ l2) -> ~ In x l2.
Proof. intros x l1 l2 H Hc. apply H. apply in_or_app. right; exact Hc. Qed.

Lemma notin5 : forall (x : nat) (a b c d e : list nat),
    ~ In x (a ++ b ++ c ++ d ++ e) -> ~ In x b /\ ~ In x c /\ ~ In x d.
Proof.
  intros x a b c d e H.
  pose proof (notin_app2 x a (b ++ c ++ d ++ e) H) as H1.
  pose proof (notin_app1 x b (c ++ d ++ e) H1) as Hb.
  pose proof (notin_app2 x b (c ++ d ++ e) H1) as H2.
  pose proof (notin_app1 x c (d ++ e) H2) as Hc'.
  pose proof (notin_app2 x c (d ++ e) H2) as H3.
  pose proof (notin_app1 x d e H3) as Hd.
  auto.
Qed.

Lemma d_sym : forall Γ t1 t2, der Γ (eqf t1 t2) -> der Γ (eqf t2 t1).
Proof.
  intros Γ t1 t2 H.
  destruct (pick_fresh (fvt t1 ++ fvt t2 ++ fv_l Γ)) as [x Hx].
  pose proof (notin_app1 x (fvt t1) (fvt t2 ++ fv_l Γ) Hx) as Hx1.
  apply d_ch with (χ := eqf t1 t2); [exact H|].
  assert (E : substf (eqf (var x) t1) x t2 = eqf t2 t1).
  { simpl. rewrite Nat.eqb_refl, (substt_fresh t1 x t2); [reflexivity|exact Hx1]. }
  rewrite <- E. apply Sub with (x := x) (φ := eqf (var x) t1).
  simpl. rewrite Nat.eqb_refl, (substt_fresh t1 x t1); [apply Ref|exact Hx1].
Qed.

(* 5.3(b) 等词传递 *)
Lemma d_trans : forall Γ t1 t2 t3,
    der Γ (eqf t1 t2) -> der Γ (eqf t2 t3) -> der Γ (eqf t1 t3).
Proof.
  intros Γ t1 t2 t3 H12 H23.
  destruct (pick_fresh (fvt t1 ++ fvt t3 ++ fv_l Γ)) as [x Hx].
  pose proof (notin_app1 x (fvt t1) (fvt t3 ++ fv_l Γ) Hx) as Hx1.
  apply d_ch with (χ := eqf t2 t3); [exact H23|].
  assert (E : substf (eqf t1 (var x)) x t3 = eqf t1 t3).
  { simpl. rewrite Nat.eqb_refl, (substt_fresh t1 x t3); [reflexivity|exact Hx1]. }
  rewrite <- E. apply Sub with (x := x) (φ := eqf t1 (var x)).
  simpl. rewrite Nat.eqb_refl, (substt_fresh t1 x t2); [exact H12|exact Hx1].
Qed.

(* ---------- 5. 量词可导规则（书 IV.5） ---------- *)

(* 5.5(a1)：Γ ⊢ ∀xφ 则 Γ ⊢ φ[t/x]——∀-左实例化 *)
Lemma d_all_inst : forall Γ x φ t, der Γ (all x φ) -> der Γ (substf φ x t).
Proof.
  intros Γ x φ t H. unfold all in H.
  apply PC with (ψ := substf φ x t).
  - apply Assm. left; reflexivity.
  - apply Ctr with (ψ := exq x (neg φ)).
    + apply ExS with (x := x) (φ := neg φ) (t := t).
      apply Assm. left; reflexivity.
    + apply (Ant Γ).
      * apply incl_tl, incl_tl, incl_refl.
      * exact H.
Qed.

(* 5.1(a)：Γ ⊢ φ 则 Γ ⊢ ∃xφ（见证取 x 自己） *)
Lemma d_exi_self : forall Γ x φ, der Γ φ -> der Γ (exq x φ).
Proof.
  intros Γ x φ H. apply ExS with (x := x) (φ := φ) (t := var x).
  rewrite substf_self. exact H.
Qed.

(* 乘法左槽/右槽的同余（书 5.4(b) 的特化；新鲜性内部处理） *)
Lemma d_congr_l : forall Γ a b u,
    der Γ (eqf a b) -> der Γ (eqf (fsym 0 [a; u]) (fsym 0 [b; u])).
Proof.
  intros Γ a b u H.
  destruct (pick_fresh (fvt a ++ fvt b ++ fvt u ++ fvt (fsym 0 [a;u]) ++ fv_l Γ)) as [x Hx].
  destruct (notin5 x (fvt a) (fvt b) (fvt u) (fvt (fsym 0 [a; u])) (fv_l Γ) Hx)
    as [Hxb [Hxu _]].
  assert (E : substf (eqf (fsym 0 [var x; u]) (fsym 0 [b; u])) x b
              = eqf (fsym 0 [b; u]) (fsym 0 [b; u])).
  { simpl. rewrite Nat.eqb_refl, !substt_fresh by assumption. reflexivity. }
  assert (E2 : substf (eqf (fsym 0 [var x; u]) (fsym 0 [b; u])) x a
               = eqf (fsym 0 [a; u]) (fsym 0 [b; u])).
  { simpl. rewrite Nat.eqb_refl, !substt_fresh by assumption. reflexivity. }
  apply d_ch with (χ := eqf b a).
  - apply d_sym. exact H.
  - rewrite <- E2. apply Sub with (x := x)
      (φ := eqf (fsym 0 [var x; u]) (fsym 0 [b; u])) (t := b) (t' := a).
    rewrite E. apply Ref.
Qed.

Lemma d_congr_r : forall Γ a b u,
    der Γ (eqf a b) -> der Γ (eqf (fsym 0 [u; a]) (fsym 0 [u; b])).
Proof.
  intros Γ a b u H.
  destruct (pick_fresh (fvt a ++ fvt b ++ fvt u ++ fvt (fsym 0 [u;a]) ++ fv_l Γ)) as [x Hx].
  destruct (notin5 x (fvt a) (fvt b) (fvt u) (fvt (fsym 0 [u; a])) (fv_l Γ) Hx)
    as [Hxb [Hxu _]].
  assert (E : substf (eqf (fsym 0 [u; var x]) (fsym 0 [u; b])) x b
              = eqf (fsym 0 [u; b]) (fsym 0 [u; b])).
  { simpl. rewrite Nat.eqb_refl, !substt_fresh by assumption. reflexivity. }
  assert (E2 : substf (eqf (fsym 0 [u; var x]) (fsym 0 [u; b])) x a
               = eqf (fsym 0 [u; a]) (fsym 0 [u; b])).
  { simpl. rewrite Nat.eqb_refl, !substt_fresh by assumption. reflexivity. }
  apply d_ch with (χ := eqf b a).
  - apply d_sym. exact H.
  - rewrite <- E2. apply Sub with (x := x)
      (φ := eqf (fsym 0 [u; var x]) (fsym 0 [u; b])) (t := b) (t' := a).
    rewrite E. apply Ref.
Qed.

(* ---------- 6. 群论例（书 IV.6：右幺+右逆+结合 ⇒ 存在左逆） ---------- *)

Definition mul (a b : tm) : tm := fsym 0 [a; b].
Definition eg : tm := fsym 1 [].

(* 变元：0=x（主元），10=y（左逆见证），11=z（y 的右逆见证）；
   公理约束变元 3,4,5 与 7,8——与 0,10,11 错开，实例化不撞 binder *)
Definition phi0 : fm :=
  all 3 (all 4 (all 5 (eqf (mul (mul (var 3) (var 4)) (var 5))
                           (mul (var 3) (mul (var 4) (var 5)))))).
Definition phi1 : fm := all 3 (eqf (mul (var 3) eg) (var 3)).
Definition phi2 : fm := all 7 (exq 8 (eqf (mul (var 7) (var 8)) eg)).
Definition Γgr : list fm := [phi0; phi1; phi2].

Definition A1 : fm := eqf (mul (var 0) (var 10)) eg.   (* x·y ≡ e *)
Definition A2 : fm := eqf (mul (var 10) (var 11)) eg.  (* y·z ≡ e *)
Definition G0 : fm := eqf (mul (var 10) (var 0)) eg.   (* y·x ≡ e *)

Lemma gr_incl_A1 : incl Γgr (A1 :: Γgr).
Proof.
  red; intros a Ha. simpl in Ha. destruct Ha as [E|[E|[E|[]]]]; subst.
  - right; left; reflexivity.
  - right; right; left; reflexivity.
  - right; right; right; left; reflexivity.
Qed.

Lemma gr_incl_ctx : incl Γgr (A2 :: A1 :: Γgr).
Proof.
  red; intros a Ha. simpl in Ha. destruct Ha as [E|[E|[E|[]]]]; subst.
  - right; right; left; reflexivity.
  - right; right; right; left; reflexivity.
  - right; right; right; right; left; reflexivity.
Qed.

(* 等式链：A2, A1, Γ ⊢ y·x ≡ e（书 IV.6 行 2-23 的链条） *)
Lemma chain : der (A2 :: A1 :: Γgr) G0.
Proof.
  assert (Hi0 : In phi0 (A2 :: A1 :: Γgr)) by (apply gr_incl_ctx; left; reflexivity).
  assert (Hi1 : In phi1 (A2 :: A1 :: Γgr)) by (apply gr_incl_ctx; right; left; reflexivity).
  (* 右幺实例：(yx)e ≡ yx *)
  assert (c1 : der (A2::A1::Γgr)
      (eqf (mul (mul (var 10) (var 0)) eg) (mul (var 10) (var 0)))).
  { exact (d_all_inst _ 3 (eqf (mul (var 3) eg) (var 3))
      (mul (var 10) (var 0)) (Assm _ phi1 Hi1)). }
  pose proof (Assm (A2::A1::Γgr) A2 (or_introl eq_refl)) as hA2.
  pose proof (d_sym _ _ _ hA2) as hA2s.
  (* (e≡yz) 同余到右槽：p1: yx ≡ (yx)(yz) *)
  pose proof (d_congr_r _ eg (mul (var 10) (var 11)) (mul (var 10) (var 0)) hA2s) as c2.
  pose proof (d_sym _ _ _ c1) as c1s.
  pose proof (d_trans _ (mul (var 10) (var 0)) (mul (mul (var 10) (var 0)) eg)
      (mul (mul (var 10) (var 0)) (mul (var 10) (var 11))) c1s c2) as p1.
  (* 结合实例 (y,x,yz)：c3: (yx)(yz) ≡ y(x(yz)) *)
  assert (h1 : der (A2::A1::Γgr) (all 4 (all 5
      (eqf (mul (mul (var 10) (var 4)) (var 5))
           (mul (var 10) (mul (var 4) (var 5))))))).
  { exact (d_all_inst _ 3
      (all 4 (all 5 (eqf (mul (mul (var 3) (var 4)) (var 5)) (mul (var 3) (mul (var 4) (var 5))))))
      (var 10) (Assm _ phi0 Hi0)). }
  assert (h2 : der (A2::A1::Γgr) (all 5
      (eqf (mul (mul (var 10) (var 0)) (var 5))
           (mul (var 10) (mul (var 0) (var 5)))))).
  { exact (d_all_inst _ 4
      (all 5 (eqf (mul (mul (var 10) (var 4)) (var 5)) (mul (var 10) (mul (var 4) (var 5)))))
      (var 0) h1). }
  assert (c3 : der (A2::A1::Γgr)
      (eqf (mul (mul (var 10) (var 0)) (mul (var 10) (var 11)))
           (mul (var 10) (mul (var 0) (mul (var 10) (var 11)))))).
  { exact (d_all_inst _ 5
      (eqf (mul (mul (var 10) (var 0)) (var 5)) (mul (var 10) (mul (var 0) (var 5))))
      (mul (var 10) (var 11)) h2). }
  pose proof (d_trans _ (mul (var 10) (var 0)) (mul (mul (var 10) (var 0)) (mul (var 10) (var 11))) (mul (var 10) (mul (var 0) (mul (var 10) (var 11)))) p1 c3) as p2.
  (* 结合实例 (x,y,z) 再取对称：c4: x(yz) ≡ (xy)z *)
  assert (h3 : der (A2::A1::Γgr) (all 4 (all 5
      (eqf (mul (mul (var 0) (var 4)) (var 5))
           (mul (var 0) (mul (var 4) (var 5))))))).
  { exact (d_all_inst _ 3
      (all 4 (all 5 (eqf (mul (mul (var 3) (var 4)) (var 5)) (mul (var 3) (mul (var 4) (var 5))))))
      (var 0) (Assm _ phi0 Hi0)). }
  assert (h4 : der (A2::A1::Γgr) (all 5
      (eqf (mul (mul (var 0) (var 10)) (var 5))
           (mul (var 0) (mul (var 10) (var 5)))))).
  { exact (d_all_inst _ 4
      (all 5 (eqf (mul (mul (var 0) (var 4)) (var 5)) (mul (var 0) (mul (var 4) (var 5)))))
      (var 10) h3). }
  assert (c4' : der (A2::A1::Γgr)
      (eqf (mul (mul (var 0) (var 10)) (var 11))
           (mul (var 0) (mul (var 10) (var 11))))).
  { exact (d_all_inst _ 5
      (eqf (mul (mul (var 0) (var 10)) (var 5)) (mul (var 0) (mul (var 10) (var 5))))
      (var 11) h4). }
  pose proof (d_sym _ _ _ c4') as c4.
  (* 同余到 y·_ 槽：p3: yx ≡ y((xy)z) *)
  pose proof (d_congr_r _ (mul (var 0) (mul (var 10) (var 11))) (mul (mul (var 0) (var 10)) (var 11)) (var 10) c4) as c5.
  pose proof (d_trans _ (mul (var 10) (var 0)) (mul (var 10) (mul (var 0) (mul (var 10) (var 11)))) (mul (var 10) (mul (mul (var 0) (var 10)) (var 11))) p2 c5) as p3.
  (* A1（xy≡e）同余：p4: yx ≡ y(ez) *)
  pose proof (Assm (A2::A1::Γgr) A1 (or_intror (or_introl eq_refl))) as hA1.
  pose proof (d_congr_l _ (mul (var 0) (var 10)) eg (var 11) hA1) as c6a.
  pose proof (d_congr_r _ (mul (mul (var 0) (var 10)) (var 11)) (mul eg (var 11)) (var 10) c6a) as c6.
  pose proof (d_trans _ (mul (var 10) (var 0)) (mul (var 10) (mul (mul (var 0) (var 10)) (var 11))) (mul (var 10) (mul eg (var 11))) p3 c6) as p4.
  (* 结合实例 (y,e,z)：(ye)z ≡ y(ez)，取对称得 y(ez) ≡ (ye)z *)
  assert (h6 : der (A2::A1::Γgr) (all 5
      (eqf (mul (mul (var 10) eg) (var 5)) (mul (var 10) (mul eg (var 5)))))).
  { exact (d_all_inst _ 4
      (all 5 (eqf (mul (mul (var 10) (var 4)) (var 5)) (mul (var 10) (mul (var 4) (var 5)))))
      eg h1). }
  assert (c7 : der (A2::A1::Γgr)
      (eqf (mul (mul (var 10) eg) (var 11)) (mul (var 10) (mul eg (var 11))))).
  { exact (d_all_inst _ 5
      (eqf (mul (mul (var 10) eg) (var 5)) (mul (var 10) (mul eg (var 5))))
      (var 11) h6). }
  pose proof (d_sym _ _ _ c7) as c7s.
  (* 右幺实例 (ye)≡y 再同余左槽：(ye)z ≡ yz *)
  assert (c8 : der (A2::A1::Γgr)
      (eqf (mul (var 10) eg) (var 10))).
  { exact (d_all_inst _ 3 (eqf (mul (var 3) eg) (var 3))
      (var 10) (Assm _ phi1 Hi1)). }
  pose proof (d_congr_l _ (mul (var 10) eg) (var 10) (var 11) c8) as c9.
  pose proof (d_trans _ (mul (var 10) (mul eg (var 11)))
      (mul (mul (var 10) eg) (var 11)) (mul (var 10) (var 11)) c7s c9) as p5.
  pose proof (d_trans _ (mul (var 10) (var 0)) (mul (var 10) (mul eg (var 11)))
      (mul (var 10) (var 11)) p4 p5) as p6.
  (* A2 收口：yx ≡ e *)
  exact (d_trans _ (mul (var 10) (var 0)) (mul (var 10) (var 11)) eg p6 hA2).
Qed.

(* ExA 侧条件的新鲜性（具体公式上 vm_compute 全算死） *)
Lemma fresh11 : ~ In 11 (fv_l (exq 8 (eqf (mul (var 10) (var 8)) eg)
                                 :: G0 :: A1 :: Γgr)).
Proof.
  intro H. vm_compute in H.
  repeat (destruct H as [E|H]; [discriminate|]). contradiction.
Qed.

Lemma fresh10 : ~ In 10 (fv_l (exq 8 (eqf (mul (var 0) (var 8)) eg)
                                 :: exq 10 G0 :: Γgr)).
Proof.
  intro H. vm_compute in H.
  repeat (destruct H as [E|H]; [discriminate|]). contradiction.
Qed.

(* 打包：Γ ⊢ ∃y y·x ≡ e——ϕ2 的两个实例经 ExA 消解、d_ch 剪掉（b3 的机器化身） *)
Theorem grp_left_inv : der Γgr (exq 10 G0).
Proof.
  assert (dis2 : der (exq 8 (eqf (mul (var 10) (var 8)) eg) :: A1 :: Γgr) G0).
  { apply ExA with (x := 8) (φ := eqf (mul (var 10) (var 8)) eg) (y := 11).
    - exact fresh11.
    - exact chain. }
  assert (inst2y : der Γgr (exq 8 (eqf (mul (var 10) (var 8)) eg))).
  { exact (d_all_inst _ 7 (exq 8 (eqf (mul (var 7) (var 8)) eg))
      (var 10) (Assm Γgr phi2 (or_intror (or_intror (or_introl eq_refl))))). }
  assert (cut2 : der (A1 :: Γgr) G0).
  { apply d_ch with (χ := exq 8 (eqf (mul (var 10) (var 8)) eg)).
    - apply (Ant Γgr).
      + exact gr_incl_A1.
      + exact inst2y.
    - exact dis2. }
  assert (gen : der (A1 :: Γgr) (exq 10 G0)).
  { apply d_exi_self. exact cut2. }
  assert (dis1 : der (exq 8 (eqf (mul (var 0) (var 8)) eg) :: Γgr) (exq 10 G0)).
  { apply ExA with (x := 8) (φ := eqf (mul (var 0) (var 8)) eg) (y := 10).
    - exact fresh10.
    - exact gen. }
  assert (inst2x : der Γgr (exq 8 (eqf (mul (var 0) (var 8)) eg))).
  { exact (d_all_inst _ 7 (exq 8 (eqf (mul (var 7) (var 8)) eg))
      (var 0) (Assm Γgr phi2 (or_intror (or_intror (or_introl eq_refl))))). }
  apply d_ch with (χ := exq 8 (eqf (mul (var 0) (var 8)) eg)).
  - exact inst2x.
  - exact dis1.
Qed.

(* ---------- 7. 协调性（书 IV.7） ---------- *)

Definition ders (Φ : list fm) (φ : fm) : Prop :=
  exists Γ, incl Γ Φ /\ der Γ φ.

(* 7.2：Inc Φ 当且仅当 Φ 推出一切公式（矛盾臂机器证） *)
Lemma inc_ders_all : forall Φ ψ0,
    ders Φ ψ0 -> ders Φ (neg ψ0) -> forall ψ, ders Φ ψ.
Proof.
  intros Φ ψ0 [Γ1 [H1 D1]] [Γ2 [H2 D2]] ψ.
  exists (Γ1 ++ Γ2). split.
  - red; intros a Ha.
    assert (Ha2 : In a Γ1 \/ In a Γ2) by (apply in_app_iff; exact Ha).
    destruct Ha2 as [Ha2|Ha2].
    + exact (H1 a Ha2).
    + exact (H2 a Ha2).
  - apply Ctr with (ψ := ψ0).
    + apply (Ant Γ1).
      * red; intros a Ha. right. apply in_app_iff. left; exact Ha.
      * exact D1.
    + apply (Ant Γ2).
      * red; intros a Ha. right. apply in_app_iff. right; exact Ha.
      * exact D2.
Qed.

(* ---------- 8. 命题片段可靠性（S 的骨架；ExS/ExA/Ref/Sub 超出命题语义） ---------- *)

Inductive derp : list fm -> fm -> Prop :=
| pAssm : forall Γ φ, In φ Γ -> derp Γ φ
| pAnt : forall Γ Γ' φ, incl Γ Γ' -> derp Γ φ -> derp Γ' φ
| pPC : forall Γ ψ φ, derp (ψ :: Γ) φ -> derp (neg ψ :: Γ) φ -> derp Γ φ
| pCtr : forall Γ φ ψ,
    derp (neg φ :: Γ) ψ -> derp (neg φ :: Γ) (neg ψ) -> derp Γ φ
| pOrA : forall Γ φ ψ χ,
    derp (φ :: Γ) χ -> derp (ψ :: Γ) χ -> derp (disj φ ψ :: Γ) χ
| pOrSl : forall Γ φ ψ, derp Γ φ -> derp Γ (disj φ ψ)
| pOrSr : forall Γ φ ψ, derp Γ ψ -> derp Γ (disj φ ψ).

Definition comp (α : fm -> bool) : Prop :=
  (forall φ, α (neg φ) = negb (α φ))
  /\ (forall φ ψ, α (disj φ ψ) = orb (α φ) (α ψ)).

(* 注意：第 1 节的公式缩写 conj（fm 上的 ∧）遮蔽了 stdlib 的合取构造子，
   故用 tactic 级的 split 造 comp 见证 *)
Lemma mkcomp : forall α (H1 : forall φ, α (neg φ) = negb (α φ))
    (H2 : forall φ ψ, α (disj φ ψ) = orb (α φ) (α ψ)), comp α.
Proof. intros α H1 H2. unfold comp. split; assumption. Qed.

Lemma in_cons2 : forall (a b : fm) (l : list fm), In a l -> In a (b :: l).
Proof. intros a b l H. right. exact H. Qed.

Theorem derp_sound : forall Γ φ, derp Γ φ ->
    forall α, comp α -> (forall ψ, In ψ Γ -> α ψ = true) -> α φ = true.
Proof.
  intros Γ0 φ0 Hd0 α Hc HΓ. revert HΓ.
  induction Hd0 as
    [Γ φ HIn |Γ Γ' φ Hin Hd IH |Γ ψ φ Hd1 IH1 Hd2 IH2
    |Γ φ ψ Hd1 IH1 Hd2 IH2 |Γ φ ψ χ Hd1 IH1 Hd2 IH2
    |Γ φ ψ Hd IH |Γ φ ψ Hd IH]; intros HΓ;
    unfold comp in Hc; destruct Hc as [Hn Ho].
  - (* Assm *) apply HΓ; exact HIn.
  - (* Ant *) apply IH. intros ψ2 H2. apply HΓ. apply Hin. exact H2.
  - (* PC *) destruct (α ψ) eqn:Eψ.
    + apply IH1. intros ψ2 H2.
      destruct H2 as [E|H2]; [rewrite <- E; exact Eψ | apply HΓ; exact H2].
    + apply IH2. intros ψ2 H2.
      destruct H2 as [E|H2]; [rewrite <- E; rewrite Hn, Eψ; reflexivity
                             | apply HΓ; exact H2].
  - (* Ctr *) destruct (α φ) eqn:Ef.
    + reflexivity.
    + exfalso.
      assert (Enf : α (neg φ) = true) by (rewrite Hn, Ef; reflexivity).
      assert (G1 : α ψ = true).
      { apply IH1. intros ψ2 H2.
        destruct H2 as [E|H2]; [rewrite <- E; exact Enf | apply HΓ; exact H2]. }
      assert (G2 : α (neg ψ) = true).
      { apply IH2. intros ψ2 H2.
        destruct H2 as [E|H2]; [rewrite <- E; exact Enf | apply HΓ; exact H2]. }
      rewrite Hn, G1 in G2. discriminate.
  - (* OrA *) assert (Ed : α (disj φ ψ) = true)
      by (apply HΓ; left; reflexivity).
    rewrite (Ho φ ψ) in Ed.
    destruct (α φ) eqn:E1.
    + apply IH1. intros ψ2 H2.
      destruct H2 as [E|H2]; [rewrite <- E; exact E1
                             | apply HΓ; apply in_cons2; exact H2].
    + destruct (α ψ) eqn:E2.
      * apply IH2. intros ψ2 H2.
        destruct H2 as [E|H2]; [rewrite <- E; exact E2
                             | apply HΓ; apply in_cons2; exact H2].
      * simpl in Ed. rewrite ?E1 in Ed. rewrite ?E2 in Ed.
        simpl in Ed. discriminate.
  - (* OrSl *) rewrite (Ho φ ψ), (IH HΓ). reflexivity.
  - (* OrSr *) rewrite (Ho φ ψ), (IH HΓ). destruct (α φ); reflexivity.
Qed.

(* 命题骨架赋值：原子 (rat 0 []) 为假、其余原子为真 *)
Fixpoint val0 (φ : fm) : bool :=
  match φ with
  | rat 0 _ => false
  | rat _ _ => true
  | eqf _ _ => true
  | neg ψ => negb (val0 ψ)
  | disj ψ χ => orb (val0 ψ) (val0 χ)
  | exq _ _ => true
  end.

Lemma val0_comp : comp val0.
Proof.
  split.
  - intros φ. reflexivity.
  - intros φ ψ. reflexivity.
Qed.

(* 推论：命题片段协调——空前提推不出假原子（书 IV.7 精神） *)
Corollary derp_consistent : ~ derp [] (rat 0 []).
Proof.
  intros Hd.
  assert (Hv : val0 (rat 0 []) = true).
  { apply (derp_sound [] _ Hd val0 val0_comp).
    intros ψ H. simpl in H. contradiction. }
  vm_compute in Hv. discriminate.
Qed.

(* ---------- 9. 冒烟与账本 ---------- *)

(* 现场小推导：⊢ (P ∨ ¬P) *)
Check (d_tnd [] (rat 0 [])).
(* 群论例目标 *)
Check (grp_left_inv : der Γgr (exq 10 (eqf (mul (var 10) (var 0)) eg))).
Compute (fv (exq 8 (eqf (mul (var 10) (var 8)) eg))).   (* = [10] *)

Print Assumptions grp_left_inv.
Print Assumptions inc_ders_all.
Print Assumptions derp_sound.
