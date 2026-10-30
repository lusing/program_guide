(* 106 非干扰与安全多执行：从两次执行到状态划分 *)
(* 取材 Software Foundations 卷七 Security Foundations 的 Noninterference 章。 *)

From Stdlib Require Import Arith.Arith.
From Stdlib Require Import Bool.Bool.
From Stdlib Require Import Lia.
From Stdlib Require Import Strings.String.
From Stdlib Require Import FunctionalExtensionality.

Open Scope string_scope.

(* ---------- 106.1 自包含的全映射与更新记号 ---------- *)

Definition total_map (A : Type) : Type := string -> A.

Definition t_empty {A : Type} (v : A) : total_map A :=
  fun _ => v.

Definition t_update {A : Type} (m : total_map A)
                    (x : string) (v : A) : total_map A :=
  fun x' => if String.eqb x x' then v else m x'.

Notation "'__' '!->' v" := (t_empty v)
  (at level 100, right associativity).

Notation "x '!->' v ';' m" := (t_update m x v)
  (at level 100, v constr at level 100, right associativity).

Lemma t_apply_empty : forall (A : Type) (x : string) (v : A),
  (__ !-> v) x = v.
Proof. reflexivity. Qed.

Lemma t_update_eq : forall (A : Type) (m : total_map A) x v,
  (x !-> v ; m) x = v.
Proof.
  intros A m x v. unfold t_update.
  rewrite String.eqb_refl. reflexivity.
Qed.

Lemma t_update_neq : forall (A : Type) (m : total_map A) x1 x2 v,
  x1 <> x2 ->
  (x1 !-> v ; m) x2 = m x2.
Proof.
  intros A m x1 x2 v Hneq. unfold t_update.
  destruct (String.eqb_spec x1 x2).
  - subst x2. contradiction.
  - reflexivity.
Qed.

Lemma t_update_same : forall (A : Type) (m : total_map A) x,
  (x !-> m x ; m) = m.
Proof.
  intros A m x. apply functional_extensionality. intro x'.
  unfold t_update. destruct (String.eqb_spec x x').
  - subst x'. reflexivity.
  - reflexivity.
Qed.

Definition X : string := "X".
Definition Y : string := "Y".
Definition state := total_map nat.

(* ---------- 106.2 为什么单执行定义失败 ---------- *)

Definition secure_f (pi si : nat) : nat * nat :=
  (pi + 1, pi + si * 2).

Definition broken_sec_def (f : nat -> nat -> nat * nat) :=
  forall pi si, fst (f pi si) <> si.

Example example_secure_f : secure_f 7 8 = (8, 23).
Proof. reflexivity. Qed.

Lemma broken_sec_def_rejects_secure_f : ~ broken_sec_def secure_f.
Proof. intros Hc. apply (Hc 7 8). reflexivity. Qed.

Definition insecure_f (pi si : nat) : nat * nat :=
  (si + 1, pi + si * 2).

Lemma broken_sec_def_accepts_insecure_f : broken_sec_def insecure_f.
Proof.
  unfold broken_sec_def, insecure_f. intros pi si. simpl. lia.
Qed.

(* ---------- 106.3 纯函数的非干扰 ---------- *)

Definition noninterferent {PI SI PO SO : Type}
    (f : PI -> SI -> PO * SO) :=
  forall (pi : PI) (si1 si2 : SI),
    fst (f pi si1) = fst (f pi si2).

Lemma noninterferent_secure_f : noninterferent secure_f.
Proof. unfold noninterferent, secure_f. simpl. reflexivity. Qed.

Lemma interferent_insecure_f : ~ noninterferent insecure_f.
Proof.
  unfold noninterferent. intros contra.
  specialize (contra 42 3 7). simpl in contra. discriminate contra.
Qed.

Definition less_obvious_f1 (pi si : nat) : nat * nat :=
  (si * 0, pi + si).

Lemma noninterferent_less_obvious_f1 : noninterferent less_obvious_f1.
Proof.
  unfold noninterferent, less_obvious_f1. intros pi si1 si2. simpl.
  rewrite Nat.mul_0_r. rewrite Nat.mul_0_r. reflexivity.
Qed.

Definition less_obvious_f2 (pi si : nat) : nat * nat :=
  (if Nat.eqb si 1 then si * pi else pi, pi + si).

Lemma po_equal_pi_f2 : forall si pi,
  (if Nat.eqb si 1 then si * pi else pi) = pi.
Proof.
  intros si pi. destruct (Nat.eqb si 1) eqn:Eq.
  - apply Nat.eqb_eq in Eq. subst si. rewrite Nat.mul_1_l. reflexivity.
  - reflexivity.
Qed.

Lemma noninterferent_less_obvious_f2 : noninterferent less_obvious_f2.
Proof.
  unfold noninterferent, less_obvious_f2. intros pi si1 si2.
  rewrite po_equal_pi_f2. rewrite po_equal_pi_f2. reflexivity.
Qed.

Definition less_obvious_f3 (pi si : nat) : nat * nat :=
  (if Nat.eqb si 0 then 1 else 0, pi + si).

Lemma interferent_less_obvious_f3 : ~ noninterferent less_obvious_f3.
Proof.
  unfold noninterferent, less_obvious_f3. intros contra.
  specialize (contra 42 0 10). simpl in contra. discriminate contra.
Qed.

(* 标准练习：六个函数分别给出构造性证明或具体反例。 *)

Definition obvious_f1 (pi si : nat) : nat * nat := (0, 0).

Lemma prove_or_disprove_obvious_f1 :
  noninterferent obvious_f1 \/ ~ noninterferent obvious_f1.
Proof.
  left. unfold noninterferent, obvious_f1. reflexivity.
Qed.

Definition obvious_f2 (pi si : nat) : nat * nat :=
  (pi + 2 * si, 2 * pi + si).

Lemma prove_or_disprove_obvious_f2 :
  noninterferent obvious_f2 \/ ~ noninterferent obvious_f2.
Proof.
  right. unfold noninterferent, obvious_f2. intros contra.
  specialize (contra 0 0 1). simpl in contra. discriminate contra.
Qed.

Definition less_obvious_f4 (pi si : nat) : nat * nat :=
  (if Nat.eqb si 0 then si * pi else pi, pi + si).

Lemma prove_or_disprove_less_obvious_f4 :
  noninterferent less_obvious_f4 \/ ~ noninterferent less_obvious_f4.
Proof.
  right. unfold noninterferent, less_obvious_f4. intros contra.
  specialize (contra 2 0 1). simpl in contra. discriminate contra.
Qed.

Definition less_obvious_f5 (pi si : nat) : nat * nat :=
  (if Nat.eqb si 0 then si + pi else pi, pi + si).

Lemma prove_or_disprove_less_obvious_f5 :
  noninterferent less_obvious_f5 \/ ~ noninterferent less_obvious_f5.
Proof.
  left. unfold noninterferent, less_obvious_f5.
  intros pi [| si1] [| si2]; reflexivity.
Qed.

Definition less_obvious_f6 (pi si : nat) : nat * nat :=
  (if Nat.ltb si pi then 0 else pi, pi + si).

Lemma prove_or_disprove_less_obvious_f6 :
  noninterferent less_obvious_f6 \/ ~ noninterferent less_obvious_f6.
Proof.
  right. unfold noninterferent, less_obvious_f6. intros contra.
  specialize (contra 1 0 1). simpl in contra. discriminate contra.
Qed.

Definition noninterferent_diff_si {PI SI PO SO : Type}
    (f : PI -> SI -> PO * SO) :=
  forall (pi : PI) (si1 si2 : SI),
    si1 <> si2 -> fst (f pi si1) = fst (f pi si2).

Lemma noninterferent_diff_si_same : forall (f : nat -> nat -> nat * nat),
  noninterferent_diff_si f <-> noninterferent f.
Proof.
  intros f. split.
  - intros H pi si1 si2. destruct (Nat.eq_dec si1 si2) as [Heq | Hneq].
    + subst si2. reflexivity.
    + apply H. exact Hneq.
  - intros H pi si1 si2 _. apply H.
Qed.

(* ---------- 106.4 过强定义与可划分性 ---------- *)

Definition too_strong_sec_def {PI SI PO SO : Type}
    (f : PI -> SI -> PO * SO) :=
  forall (pi1 pi2 : PI) (si1 si2 : SI),
    fst (f pi1 si1) = fst (f pi2 si2).

Lemma secure_f_rejected_again : ~ too_strong_sec_def secure_f.
Proof.
  unfold too_strong_sec_def, secure_f. intros contra.
  specialize (contra 0 1 0 0). discriminate contra.
Qed.

Definition splittable {PI SI PO SO : Type}
    (f : PI -> SI -> PO * SO) :=
  exists (pf : PI -> PO) (sf : PI -> SI -> SO),
    forall pi si, f pi si = (pf pi, sf pi si).

Theorem splittable_noninterferent : forall (PI SI PO SO : Type)
    (f : PI -> SI -> PO * SO),
  splittable f -> noninterferent f.
Proof.
  unfold splittable, noninterferent.
  intros PI SI PO SO f [pf [sf H]] pi si1 si2.
  rewrite H. rewrite H. simpl. reflexivity.
Qed.

Theorem noninterferent_splittable : forall (PI SI PO SO : Type)
    (some_si : SI) (f : PI -> SI -> PO * SO),
  noninterferent f -> splittable f.
Proof.
  unfold splittable, noninterferent.
  intros PI SI PO SO some_si f NI.
  exists (fun pi => fst (f pi some_si)).
  exists (fun pi si => snd (f pi si)).
  intros pi si. rewrite (NI _ _ si).
  destruct (f pi si) as [po so]. reflexivity.
Qed.

(* ---------- 106.5 安全多执行：安全性与透明性 ---------- *)

Definition sme {PI SI PO SO : Type} (some_si : SI)
    (f : PI -> SI -> PO * SO) : PI -> SI -> PO * SO :=
  fun pi si => (fst (f pi some_si), snd (f pi si)).

Theorem noninterferent_sme : forall (PI SI PO SO : Type)
    (some_si : SI) (f : PI -> SI -> PO * SO),
  noninterferent (sme some_si f).
Proof. intros PI SI PO SO some_si f pi si1 si2. reflexivity. Qed.

Theorem transparent_sme : forall (PI SI PO SO : Type)
    (some_si : SI) (f : PI -> SI -> PO * SO),
  noninterferent f -> forall pi si, f pi si = sme some_si f pi si.
Proof.
  unfold noninterferent, sme. intros PI SI PO SO some_si f NI.
  intros pi si. rewrite (NI _ _ si).
  destruct (f pi si) as [po so]. reflexivity.
Qed.

Example example_sme_insecure_f : sme 0 insecure_f 1 7 = (1, 15).
Proof. reflexivity. Qed.

Lemma constant_sme_insecure_f : forall pi si,
  fst (sme 0 insecure_f pi si) = 1.
Proof. unfold sme, insecure_f. reflexivity. Qed.

Definition another_insecure_f2 (pi si : nat) : nat * nat :=
  (if Nat.eqb si 0 then 2 * pi else pi, pi + si).

Lemma sme_another_insecure_f2 : forall pi si,
  sme 0 another_insecure_f2 pi si = (2 * pi, pi + si).
Proof. intros pi si. reflexivity. Qed.

Definition another_insecure_f3 (pi si : nat) : nat * nat :=
  (if Nat.eqb si pi then si * pi else pi, pi + si).

Lemma sme_another_insecure_f3 : forall pi si,
  sme 0 another_insecure_f3 pi si = (pi, pi + si).
Proof. intros [| pi] si; reflexivity. Qed.

Lemma sme_correct_so : forall (PI SI PO SO : Type)
    (some_si : SI) (f : PI -> SI -> PO * SO) (pi : PI) (si : SI),
  snd (f pi si) = snd (sme some_si f pi si).
Proof. reflexivity. Qed.

(* ---------- 106.6 标签、公开等价与状态转换器 ---------- *)

Inductive label : Type :=
  | public
  | secret.

Definition label_map := total_map label.

Definition label_eqb (l1 l2 : label) : bool :=
  match l1, l2 with
  | public, public | secret, secret => true
  | _, _ => false
  end.

Declare Scope label_scope.
Infix "=?" := label_eqb : label_scope.
Delimit Scope label_scope with label.
Open Scope label_scope.

Lemma label_eqb_spec : forall l1 l2 : label,
  reflect (l1 = l2) (l1 =? l2).
Proof.
  intros [|] [|]; constructor; (reflexivity || discriminate).
Qed.

Definition pub_equiv (L : label_map) (s1 s2 : state) :=
  forall x : string, L x = public -> s1 x = s2 x.

Lemma pub_equiv_refl : forall (L : label_map) (s : state),
  pub_equiv L s s.
Proof. intros L s x Hx. reflexivity. Qed.

Lemma pub_equiv_sym : forall (L : label_map) (s1 s2 : state),
  pub_equiv L s1 s2 -> pub_equiv L s2 s1.
Proof.
  unfold pub_equiv. intros L s1 s2 H x Px. symmetry. apply H. exact Px.
Qed.

Lemma pub_equiv_trans : forall (L : label_map) (s1 s2 s3 : state),
  pub_equiv L s1 s2 -> pub_equiv L s2 s3 -> pub_equiv L s1 s3.
Proof.
  unfold pub_equiv. intros L s1 s2 s3 H12 H23 x Px.
  rewrite H12 by exact Px. apply H23. exact Px.
Qed.

Definition noninterferent_state (L : label_map) (f : state -> state) :=
  forall s1 s2,
    pub_equiv L s1 s2 -> pub_equiv L (f s1) (f s2).

Definition tid (s : state) : state := s.

Lemma noninterferent_tid : forall L : label_map,
  noninterferent_state L tid.
Proof.
  unfold noninterferent_state, tid. intros L s1 s2 PEq. exact PEq.
Qed.

Definition tconstX (c : nat) (s : state) : state := (X !-> c ; s).

Definition LXP : label_map := (X !-> public ; __ !-> secret).

Lemma LXP_public : forall x, LXP x = public -> x = X.
Proof.
  unfold LXP. intros x Hx.
  destruct (String.eqb_spec x X).
  - subst x. reflexivity.
  - rewrite t_update_neq in Hx.
    + rewrite t_apply_empty in Hx. discriminate Hx.
    + intro contra. subst x. contradiction.
Qed.

Lemma noninterferent_tconstX : forall c,
  noninterferent_state LXP (tconstX c).
Proof.
  unfold noninterferent_state, tconstX. intros c s1 s2 PEq x Px.
  apply LXP_public in Px. subst x.
  repeat rewrite t_update_eq. reflexivity.
Qed.

Definition tincX (s : state) : state := (X !-> s X + 1 ; s).

Lemma noninterferent_tincX : noninterferent_state LXP tincX.
Proof.
  unfold noninterferent_state, tincX. intros s1 s2 PEq x Px.
  apply LXP_public in Px. subst x. repeat rewrite t_update_eq.
  f_equal. apply PEq. reflexivity.
Qed.

Definition tincY (s : state) : state := (Y !-> s Y + 1 ; s).

Lemma noninterferent_tincY : noninterferent_state LXP tincY.
Proof.
  unfold noninterferent_state, tincY. intros s1 s2 PEq x Px.
  apply LXP_public in Px. subst x.
  rewrite t_update_neq by discriminate.
  rewrite t_update_neq by discriminate.
  apply PEq. reflexivity.
Qed.

Definition tYtoX (s : state) : state := (X !-> s Y ; s).

Lemma LXPX : LXP X = public.
Proof. reflexivity. Qed.

Lemma interferent_YtoX : ~ noninterferent_state LXP tYtoX.
Proof.
  unfold noninterferent_state, tYtoX. intros Hc.
  set (s1 := Y !-> 0 ; __ !-> 0).
  set (s2 := Y !-> 1 ; __ !-> 0).
  assert (Peq : pub_equiv LXP s1 s2).
  { clear Hc. intros x H. apply LXP_public in H. subst x. reflexivity. }
  specialize (Hc s1 s2 Peq X LXPX). vm_compute in Hc. discriminate Hc.
Qed.

Definition tXtimesYtoX (s : state) : state := (X !-> s X * s Y ; s).

Lemma interferent_tXtimesYtoX : ~ noninterferent_state LXP tXtimesYtoX.
Proof.
  unfold noninterferent_state, tXtimesYtoX. intros Hc.
  set (s1 := X !-> 1 ; Y !-> 0 ; __ !-> 0).
  set (s2 := X !-> 1 ; Y !-> 1 ; __ !-> 0).
  assert (Peq : pub_equiv LXP s1 s2).
  { clear Hc. intros x H. apply LXP_public in H. subst x. reflexivity. }
  specialize (Hc s1 s2 Peq X LXPX). vm_compute in Hc. discriminate Hc.
Qed.

(* ---------- 106.7 状态划分、合并与两种非干扰的等价 ---------- *)

Definition split_state (s : state) (L : label_map) (l : label) : state :=
  fun x : string => if L x =? l then s x else 0.

Definition merge_states (ps ss : state) (L : label_map) : state :=
  fun x : string => if L x =? public then ps x else ss x.

Definition split_state_fun (L : label_map) (mf : state -> state) :=
  fun ps ss : state =>
    let ms := mf (merge_states ps ss L) in
    (split_state ms L public, split_state ms L secret).

Definition pub_equiv_split (L : label_map) (s1 s2 : state) :=
  forall x : string,
    split_state s1 L public x = split_state s2 L public x.

Theorem pub_equiv_split_iff : forall L s1 s2,
  pub_equiv L s1 s2 <-> pub_equiv_split L s1 s2.
Proof.
  unfold pub_equiv, pub_equiv_split, split_state. intros L s1 s2. split.
  - intros H x. destruct (label_eqb_spec (L x) public).
    + apply H. exact e.
    + reflexivity.
  - intros H x Hx. specialize (H x).
    destruct (label_eqb_spec (L x) public).
    + exact H.
    + contradiction.
Qed.

Theorem pub_equiv_merge_states : forall L ps ss1 ss2,
  pub_equiv L (merge_states ps ss1 L) (merge_states ps ss2 L).
Proof.
  unfold pub_equiv, merge_states. intros L ps ss1 ss2 x Hx.
  rewrite Hx. reflexivity.
Qed.

Theorem merge_states_split_state : forall s L,
  merge_states (split_state s L public) (split_state s L secret) L = s.
Proof.
  unfold merge_states, split_state. intros s L.
  apply functional_extensionality. intro x.
  destruct (L x); reflexivity.
Qed.

Theorem noninterferent_state_ni : forall L f,
  noninterferent_state L f <-> noninterferent (split_state_fun L f).
Proof.
  unfold noninterferent_state, noninterferent, split_state_fun.
  intros L f. split.
  - intros H ps ss1 ss2. simpl.
    assert (H' : pub_equiv L (merge_states ps ss1 L)
                             (merge_states ps ss2 L)).
    { apply pub_equiv_merge_states. }
    apply H in H'. rewrite pub_equiv_split_iff in H'.
    unfold pub_equiv_split in H'.
    apply functional_extensionality. apply H'.
  - intros H s1 s2 Hequiv. simpl in H.
    rewrite pub_equiv_split_iff in *. unfold pub_equiv_split in *.
    intro x.
    specialize (H (split_state s1 L public)
                  (split_state s1 L secret)
                  (split_state s2 L secret)).
    rewrite merge_states_split_state in H.
    apply functional_extensionality in Hequiv. rewrite Hequiv in H.
    rewrite merge_states_split_state in H.
    rewrite H. reflexivity.
Qed.

(* ---------- 106.8 状态转换器的安全多执行 ---------- *)

Definition sme_state (f : state -> state) (L : label_map) : state -> state :=
  fun s => merge_states (f (split_state s L public)) (f s) L.

Theorem noninterferent_sme_state : forall L f,
  noninterferent_state L (sme_state f L).
Proof.
  unfold noninterferent_state, sme_state. intros L f s1 s2 Hequiv.
  rewrite pub_equiv_split_iff in Hequiv. unfold pub_equiv_split in Hequiv.
  apply functional_extensionality in Hequiv. rewrite Hequiv.
  apply pub_equiv_merge_states.
Qed.

Lemma pub_equiv_split_state : forall (L : label_map) s,
  pub_equiv L (split_state s L public) s.
Proof.
  unfold pub_equiv, split_state. intros L s x Hx.
  destruct (label_eqb_spec (L x) public).
  - reflexivity.
  - contradiction.
Qed.

Lemma merge_state_pub_equiv : forall L ss ps,
  pub_equiv L ps ss -> merge_states ps ss L = ss.
Proof.
  unfold pub_equiv, merge_states. intros L ss ps H.
  apply functional_extensionality. intros x. destruct (L x) eqn:Heq.
  - rewrite H by exact Heq. reflexivity.
  - reflexivity.
Qed.

Theorem transparent_sme_state : forall f L,
  noninterferent_state L f -> forall s, f s = sme_state f L s.
Proof.
  intros f L Hni s. unfold sme_state. symmetry.
  apply merge_state_pub_equiv. apply Hni. apply pub_equiv_split_state.
Qed.

Lemma split_state_public_id : forall s L x,
  L x = public -> split_state s L public x = s x.
Proof. intros s L x H. unfold split_state. rewrite H. reflexivity. Qed.

Lemma split_state_secret_zero : forall s L x,
  L x = secret -> split_state s L public x = 0.
Proof. intros s L x H. unfold split_state. rewrite H. reflexivity. Qed.

Lemma merge_states_update_pub_fst : forall (L : label_map) x v s1 s2,
  L x = public ->
  merge_states (x !-> v ; s1) s2 L = (x !-> v ; merge_states s1 s2 L).
Proof.
  intros L x v s1 s2 Hx. apply functional_extensionality. intros y.
  unfold merge_states. destruct (String.eqb_spec x y).
  - subst y. rewrite Hx. repeat rewrite t_update_eq. reflexivity.
  - repeat rewrite t_update_neq by assumption. reflexivity.
Qed.

Lemma merge_states_update_pub_snd : forall (L : label_map) x v s1 s2,
  L x = public ->
  merge_states s1 (x !-> v ; s2) L = merge_states s1 s2 L.
Proof.
  intros L x v s1 s2 Hx. apply functional_extensionality. intros y.
  unfold merge_states. destruct (String.eqb_spec x y).
  - subst y. rewrite Hx. reflexivity.
  - rewrite t_update_neq by assumption. reflexivity.
Qed.

Lemma sme_state_update_pub : forall (x : string) (e : state -> nat) L s,
  L x = public ->
  sme_state (fun s => (x !-> e s ; s)) L s
    = (x !-> e (split_state s L public) ; s).
Proof.
  intros x e L s Hx. unfold sme_state.
  rewrite merge_states_update_pub_fst by assumption.
  rewrite merge_states_update_pub_snd by assumption.
  rewrite merge_state_pub_equiv.
  - reflexivity.
  - apply pub_equiv_split_state.
Qed.

Lemma sme_state_tYtoX : sme_state tYtoX LXP = tconstX 0.
Proof.
  apply functional_extensionality. intros s. unfold tYtoX, tconstX.
  assert (HX : LXP X = public). { reflexivity. }
  assert (HY : LXP Y = secret). { reflexivity. }
  rewrite sme_state_update_pub by assumption.
  rewrite split_state_secret_zero by assumption. reflexivity.
Qed.

Definition tXplusYtoX (s : state) : state := (X !-> s X + s Y ; s).

Lemma sme_state_tXplusYtoX : sme_state tXplusYtoX LXP = tid.
Proof.
  apply functional_extensionality. intros s. unfold tXplusYtoX, tid.
  assert (HX : LXP X = public). { reflexivity. }
  assert (HY : LXP Y = secret). { reflexivity. }
  rewrite sme_state_update_pub by assumption.
  rewrite split_state_public_id by assumption.
  rewrite split_state_secret_zero by assumption.
  rewrite Nat.add_0_r. apply t_update_same.
Qed.
