(* 95 堆谓词 —— heap/hprop、\[] 与 \[P]、~~>、\*、hexists、外延公理与基本定律 *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 Hprop 章。 *)

Set Implicit Arguments.
From SLF Require Import LibSepReference.
Import ProgramSyntax.

Implicit Types n m : int.
Implicit Types p q : loc.

(* ---------- 95.1 状态的数学模型：heap 与 fmap ---------- *)

Definition heap : Type := fmap loc val.

Notation "h1 \u h2" := (Fmap.union h1 h2) (at level 37, right associativity).

(* ---------- 95.2 堆谓词与五大组合子 ---------- *)

Definition hprop : Type := heap -> Prop.

Implicit Type H : hprop.

Definition hempty : hprop :=
  fun (h:heap) => (h = Fmap.empty).

Notation "\[]" := (hempty) (at level 0).

Definition hpure (P:Prop) : hprop :=
  fun (h:heap) => (h = Fmap.empty) /\ P.

Notation "\[ P ]" := (hpure P) (at level 0, format "\[ P ]").

Definition hsingle (p:loc) (v:val) : hprop :=
  fun (h:heap) => (h = Fmap.single p v).

Notation "p '~~>' v" := (hsingle p v) (at level 32).

Definition hstar (H1 H2 : hprop) : hprop :=
  fun (h:heap) => exists h1 h2, H1 h1
                             /\ H2 h2
                             /\ Fmap.disjoint h1 h2
                             /\ h = h1 \u h2.

Notation "H1 '\*' H2" := (hstar H1 H2) (at level 41, right associativity).

Definition hexists (A:Type) (J:A->hprop) : hprop :=
  fun (h:heap) => exists x, J x h.

Notation "'\exists' x1 .. xn , H" :=
  (hexists (fun x1 => .. (hexists (fun xn => H)) ..))
  (at level 39, x1 binder, H at level 50, right associativity,
   format "'[' '\exists' '/ '  x1  ..  xn , '/ '  H ']'").

(* ---------- 95.3 外延公理：hprop 的相等判定 ---------- *)

Axiom predicate_extensionality : forall (A:Type) (P Q:A->Prop),
  (forall x, P x <-> Q x) ->
  P = Q.

Lemma hprop_eq : forall (H1 H2:hprop),
  (forall (h:heap), H1 h <-> H2 h) ->
  H1 = H2.
Proof using. apply predicate_extensionality. Qed.

(* ---------- 95.4 后条件与 \*+ 记号 ---------- *)

Implicit Type Q : val -> hprop.

Notation "Q \*+ H" := (fun x => hstar (Q x) H) (at level 40).

Axiom functional_extensionality : forall A B (f g:A->B),
  (forall x, f x = g x) ->
  f = g.

Lemma qprop_eq : forall (Q1 Q2:val->hprop),
  (forall (v:val), Q1 v = Q2 v) ->
  Q1 = Q2.
Proof using. apply functional_extensionality. Qed.

(* ---------- 95.5 基本算子的引入与反转引理 ---------- *)

Implicit Types P : Prop.
Implicit Types v : val.

Lemma hempty_intro :
  \[] Fmap.empty.
Proof using.
  hnf. auto.
Qed.

Lemma hpure_intro : forall P,
  P ->
  \[P] Fmap.empty.
Proof using. introv M. hnf. auto. Qed.

Lemma hsingle_intro : forall p v,
  (p ~~> v) (Fmap.single p v).
Proof using. intros. hnf. auto. Qed.

Lemma hstar_intro : forall H1 H2 h1 h2,
  H1 h1 ->
  H2 h2 ->
  Fmap.disjoint h1 h2 ->
  (H1 \* H2) (h1 \u h2).
Proof using. intros. exists* h1 h2. Qed.

Lemma hexists_intro : forall A (x:A) (J:A->hprop) h,
  J x h ->
  (\exists x, J x) h.
Proof using. introv M. hnf. eauto. Qed.

Lemma hempty_inv : forall h,
  \[] h ->
  h = Fmap.empty.
Proof using. introv M. hnf in M. auto. Qed.

Lemma hpure_inv : forall P h,
  \[P] h ->
  P /\ h = Fmap.empty.
Proof using. introv M. hnf in M. autos*. Qed.

Lemma hsingle_inv: forall p v h,
  (p ~~> v) h ->
  h = Fmap.single p v.
Proof using. introv M. hnf in M. auto. Qed.

Lemma hstar_inv : forall H1 H2 h,
  (H1 \* H2) h ->
  exists h1 h2, H1 h1 /\ H2 h2 /\ Fmap.disjoint h1 h2 /\ h = h1 \u h2.
Proof using. introv M. hnf in M. eauto. Qed.

Lemma hexists_inv : forall A (J:A->hprop) h,
  (\exists x, J x) h ->
  exists x, J x h.
Proof using. introv M. hnf in M. eauto. Qed.

(* ---------- 95.6 分离合取的基本定律（含练习解答） ---------- *)

Module HpropProofs.

Lemma hstar_hexists : forall A (J:A->hprop) H,
  (\exists x, J x) \* H = \exists x, (J x \* H).
Proof using.
  intros. apply hprop_eq. split.
  { intros (h1&h2&M1&M2&D&U). destruct M1 as (x&M1). exists* x h1 h2. }
  { intros (x&M). destruct M as (h1&h2&M1&M2&D&U). exists h1 h2.
    splits~. exists* x. }
Qed.

(* 练习（3 星）：空谓词是 \* 的单位元。用到 Fmap.union_empty_l。 *)

Lemma hstar_hempty_l : forall H,
  \[] \* H = H.
Proof using.
  intros. apply hprop_eq. split.
  { intros (h1&h2&M1&M2&D&U). hnf in M1. subst h1.
    rewrite Fmap.union_empty_l in U. subst. auto. }
  { intros M. hnf. exists (Fmap.empty:heap) h. splits~.
    { hnf. auto. }
    { rewrite Fmap.union_empty_l. auto. } }
Qed.

Lemma hprop_op_comm : forall (op:hprop->hprop->hprop),
  (forall H1 H2 h, op H1 H2 h -> op H2 H1 h) ->
  (forall H1 H2, op H1 H2 = op H2 H1).
Proof using. introv M. intros. apply hprop_eq. split; apply M. Qed.

Lemma hstar_comm : forall H1 H2,
   H1 \* H2 = H2 \* H1.
Proof using.
  (* Exploit symmetry. *)
  apply hprop_op_comm.
  (* Unfold the definition of [star]. *)
  introv (h1&h2&M1&M2&D&U).
  exists h2 h1. subst. splits~.
  (* Exploit commutativity of disjoint union *)
  { rewrite Fmap.union_comm_of_disjoint; auto. }
Qed.

(* 练习（1 星，选做）：补全结合律的另一半（右到左）。 *)

Lemma hstar_assoc : forall H1 H2 H3,
  (H1 \* H2) \* H3 = H1 \* (H2 \* H3).
Proof using.
  intros. apply hprop_eq. split.
  { intros (h'&h3&M1&M2&D&U). destruct M1 as (h1&h2&M3&M4&D'&U').
    subst h'. rewrite Fmap.disjoint_union_eq_l in D.
    exists h1 (h2 \u h3). splits.
    { apply M3. }
    { exists* h2 h3. }
    { rewrite* @Fmap.disjoint_union_eq_r. }
    { rewrite* @Fmap.union_assoc in U. } }
  { intros (h1&h23&M1&M2&D&U). destruct M2 as (h2&h3&M3&M4&D'&U').
    subst h23. rewrite Fmap.disjoint_union_eq_r in D.
    exists (h1 \u h2) h3. splits.
    { exists* h1 h2. }
    { apply M4. }
    { rewrite* @Fmap.disjoint_union_eq_l. }
    { rewrite* <- @Fmap.union_assoc in U. } }
Qed.

Lemma hstar_hempty_r : forall H,
  H \* \[] = H.
Proof using.
  intros. rewrite hstar_comm. rewrite hstar_hempty_l. auto.
Qed.

(* 练习（1 星）：交换律与结合律的合体。 *)

Lemma hstar_comm_assoc : forall H1 H2 H3,
  H1 \* H2 \* H3 = H2 \* H1 \* H3.
Proof using.
  intros. rewrite <- hstar_assoc. rewrite (hstar_comm H1 H2).
  rewrite hstar_assoc. auto.
Qed.

(* 练习（4 星）：从星号里抽出纯事实。
   逐点相等（对每个 h 是 Prop 等价），所以先用命题外延公理。 *)

Lemma hstar_hpure_l : forall P H h,
  (\[P] \* H) h = (P /\ H h).
Proof using.
  intros. apply propositional_extensionality. split.
  { intros (h1&h2&M1&M2&D&U). hnf in M1. destruct M1 as (E1&P').
    subst h1. rewrite Fmap.union_empty_l in U. subst h. splits*. }
  { intros (P'&M). hnf. exists (Fmap.empty:heap) h. splits*.
    { hnf. splits*. }
    { rewrite Fmap.union_empty_l. auto. } }
Qed.

End HpropProofs.

(* ---------- 95.7 等价的另类定义（选读） ---------- *)

Lemma hempty_eq_hpure_true :
  \[] = \[True].
Proof using.
  unfold hempty, hpure. apply hprop_eq. intros h. iff Hh.
  { auto. }
  { destruct Hh. auto. }
Qed.

Definition hempty' : hprop :=
  \[True].

Lemma hpure_eq_hexists_proof : forall P,
  \[P] = (\exists (p:P), \[]).
Proof using.
  unfold hempty, hpure, hexists. intros P.
  apply hprop_eq. intros h. iff Hh.
  { destruct Hh as (E&p). exists p. auto. }
  { destruct Hh as (p&E). auto. }
Qed.

Definition hpure' (P:Prop) : hprop :=
  \exists (p:P), \[].

(* ---------- 95.8 外延公理的推导（选读） ---------- *)

Module Extensionality.

Axiom propositional_extensionality : forall (P Q:Prop),
  (P <-> Q) ->
  P = Q.

Axiom functional_extensionality : forall A B (f g:A->B),
  (forall x, f x = g x) ->
  f = g.

(* 练习（1 星）：用上面两条公理推出谓词外延公理。 *)

Lemma predicate_extensionality_derived : forall A (P Q:A->Prop),
  (forall x, P x <-> Q x) ->
  P = Q.
Proof using.
  intros A P Q H. apply functional_extensionality. intros x.
  apply propositional_extensionality. apply H.
Qed.

End Extensionality.
