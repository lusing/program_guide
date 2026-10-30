(* 第 105 章：Silver 条件（有限部分函数）的偏序律、合并与定向下界。 *)
From Coq Require Import List Arith Lia.
Import ListNotations.

Module Ch105.

(* 条件 = 三元组表 ((α,ξ),b)：b∈{0,1}（Add(α,α++) 的影子）。 *)
Definition wfT (x : (nat * nat) * nat) : Prop := snd x < 2.

Definition keysOf (p : list ((nat * nat) * nat)) : list (nat * nat) :=
  map fst p.

Definition SCond (p : list ((nat * nat) * nat)) : Prop :=
  (forall x, In x p -> wfT x) /\ NoDup (keysOf p).

(* 反向包含：q ≤ p ⟺ p ⊆ q。 *)
Definition extC (p q : list ((nat * nat) * nat)) : Prop :=
  forall x, In x p -> In x q.

Lemma extC_refl : forall p, extC p p.
Proof. intros p x Hx. exact Hx. Qed.

Lemma extC_trans : forall p q r,
  extC p q -> extC q r -> extC p r.
Proof.
  intros p q r H1 H2 x Hx. apply H2, H1, Hx.
Qed.

(* 偏序的反对称（列表层面：互相包含 ⟹ 同为成员集——以键值集等价计）。 *)
Lemma extC_antisym_mem : forall p q,
  extC p q -> extC q p -> forall x, In x p <-> In x q.
Proof.
  intros p q H1 H2 x. split; [apply H1 | apply H2].
Qed.

(* 相容：公共键上取值一致。 *)
Definition agree (p q : list ((nat * nat) * nat)) : Prop :=
  forall x y, In x p -> In y q -> fst x = fst y -> snd x = snd y.

(* 键相等（点级）。 *)
Definition key_eqb (k1 k2 : nat*nat) : bool :=
  andb (Nat.eqb (fst k1) (fst k2)) (Nat.eqb (snd k1) (snd k2)).

(* 合并。 *)
Definition unionC (p q : list ((nat * nat) * nat)) :=
  p ++ filter (fun y : (nat*nat)*nat =>
    negb (existsb (fun k : (nat*nat)*nat => key_eqb (fst y) (fst k)) p)) q.

(* 键成员的布尔判别与命题互译。 *)
Lemma eq_fst_eq_key : forall (y k : (nat*nat)*nat),
  fst y = fst k -> (fst y) = (fst k).
Proof. intros y k H. exact H. Qed.

Lemma key_eqb_iff : forall k1 k2, key_eqb k1 k2 = true <-> k1 = k2.
Proof.
  intros [a b] [c d]. unfold key_eqb. simpl.
  destruct (Nat.eqb_spec a c) as [E1|E1];
    destruct (Nat.eqb_spec b d) as [E2|E2]; simpl.
  - split; [intros _; f_equal; auto | reflexivity].
  - split; [discriminate | intros H; injection H; auto].
  - split; [discriminate | intros H; injection H; auto].
  - split; [discriminate | intros H; injection H; auto].
Qed.

Lemma existsb_key_iff : forall (q : list ((nat*nat)*nat)) (y : (nat*nat)*nat),
  existsb (fun k => key_eqb (fst y) (fst k)) q = true <->
  In (fst y) (keysOf q).
Proof.
  intros q y. induction q as [|a t IH].
  - simpl. split; [discriminate | contradiction].
  - split.
    + cbn [existsb]. intros H.
      apply Bool.orb_true_iff in H. destruct H as [H|H].
      * left. apply (proj1 (key_eqb_iff _ _)) in H.
        symmetry. exact H.
      * right. apply (proj1 IH). exact H.
    + unfold keysOf. rewrite map_cons. cbn [In].
      intros [H|H].
      * apply Bool.orb_true_intro. left.
        apply (proj2 (key_eqb_iff (fst y) (fst a))).
        symmetry. exact H.
      * apply Bool.orb_true_intro. right.
        apply (proj2 IH). exact H.
Qed.

Lemma unionC_left : forall p q, extC p (unionC p q).
Proof.
  intros p q x Hx. apply in_or_app. left. exact Hx.
Qed.

Lemma nodup_map_filter : forall (f : (nat*nat)*nat -> bool) l,
  NoDup (keysOf l) -> NoDup (keysOf (filter f l)).
Proof.
  intros f l. induction l as [|a t IH]; intros H; simpl.
  - constructor.
  - unfold keysOf in *. simpl.
    destruct (f a) eqn:E; simpl.
    + inversion H as [|x l' Hnotin Hnd]; subst.
      constructor; [| apply IH; assumption].
      intros Hin.
      apply (proj1 (in_map_iff fst (filter f t) (fst a))) in Hin.
      destruct Hin as [z [Hfz Hz]].
      apply (proj1 (filter_In f z t)) in Hz. destruct Hz as [Hz _].
      apply Hnotin. rewrite <- Hfz. apply in_map. exact Hz.
    + apply IH. inversion H; assumption.
Qed.

Lemma unionC_cond : forall p q,
  SCond p -> SCond q -> SCond (unionC p q).
Proof.
  intros p q (hw & hnd) (hw' & hnd'). split.
  - intros x Hx. apply in_app_or in Hx.
    destruct Hx as [H|H].
    + apply hw, H.
    + apply hw'. apply filter_In in H. destruct H as [H _]; exact H.
  - unfold unionC, keysOf. rewrite map_app.
    apply NoDup_app.
    + exact hnd.
    + apply nodup_map_filter. exact hnd'.
    + intros a Ha Hb.
      apply (proj1 (in_map_iff fst
        (filter (fun y => negb (existsb (fun k => key_eqb (fst y) (fst k)) p)) q) a)) in Hb.
      destruct Hb as [y [Hfy Hy]].
      apply (proj1 (filter_In _ y q)) in Hy.
      destruct Hy as [Hy Hb'].
      simpl in Hb'.
      apply Bool.negb_true_iff in Hb'.
      apply Bool.not_true_iff_false in Hb'.
      assert (Hne : ~ In (fst y) (keysOf p)).
      { intros Hky. apply (proj2 (existsb_key_iff p y)) in Hky.
        congruence. }
      apply Hne. unfold keysOf in Ha. rewrite Hfy. exact Ha.
Qed.

(* 两两相容族的并是公共下界（引理 2.6 定向完全性/大拿的有限影子）。 *)
Lemma master_bound : forall p q,
  agree p q ->
  extC p (unionC p q) /\ extC q (unionC p q).
Proof.
  intros p q Hag. split; [apply unionC_left|].
  intros y Hy.
  destruct (existsb (fun k => key_eqb (fst y) (fst k)) p) eqn:E.
  - apply (proj1 (existsb_key_iff p y)) in E.
    apply (proj1 (in_map_iff fst p (fst y))) in E.
    destruct E as [x [Hfx Hx]].
    assert (Hex : y = x).
    { destruct y as [[a b] c]. destruct x as [[d e] f].
      simpl in Hfx. injection Hfx as Hd He.
      subst d. subst e.
      assert (Hcf : c = f).
      { assert (Hfc := Hag (a, b, f) (a, b, c) Hx Hy (eq_refl (a, b))).
        simpl in Hfc. symmetry. exact Hfc. }
      rewrite Hcf. reflexivity. }
    rewrite Hex. apply in_or_app. left. exact Hx.
  - apply in_or_app. right. apply filter_In. split; [exact Hy|].
    apply Bool.negb_true_iff. rewrite E. reflexivity.
Qed.

(* 支撑与 Easton 条款（定义 2.9/2.10 影子）。 *)
Definition support (p : list ((nat * nat) * nat)) : list nat :=
  map (fun x => fst (fst x)) p.

Definition easton_ok (p : list ((nat * nat) * nat)) (mu : nat) : Prop :=
  length (filter (fun a => a <? mu) (support p)) < mu.

Lemma easton_small : forall p,
  length p <= 2 -> easton_ok p 3.
Proof.
  intros p H.
  assert (Hf : forall (f : nat -> bool) l, length (filter f l) <= length l).
  { intros f. induction l as [|a t IH]; simpl.
    - reflexivity.
    - destruct (f a); simpl.
      + apply le_n_S. exact IH.
      + apply Nat.le_le_succ_r. exact IH. }
  unfold easton_ok, support.
  pose proof (Hf (fun a => a <? 3) (map (fun x => fst (fst x)) p)) as H1.
  rewrite length_map in H1.
  lia.
Qed.

End Ch105.
