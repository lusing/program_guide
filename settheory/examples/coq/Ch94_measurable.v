(* 第 94 章：有限幂集代数、有限超滤皆主、主超幂退化。 *)
From Coq Require Import List Bool.
Import ListNotations.

Module Ch94.

Section Finite.

Variable A : Type.
Variable eqb : A -> A -> bool.
Hypothesis eqb_eq : forall x y, eqb x y = true <-> x = y.

Definition subset := A -> bool.
Definition empty : subset := fun _ => false.
Definition full : subset := fun _ => true.
Definition inter (s t : subset) : subset := fun x => s x && t x.
Definition comp (s : subset) : subset := fun x => negb (s x).
Definition single (a : A) : subset := fun x => eqb a x.

Record Ultrafilter (U : subset -> Prop) : Prop := {
  uf_empty : ~ U empty;
  uf_full : U full;
  uf_inter : forall s t, U s -> U t -> U (inter s t);
  uf_up : forall s t, U s -> (forall x, s x = true -> t x = true) -> U t;
  uf_decide : forall s, U s \/ U (comp s)
}.

Lemma no_both : forall U (H : Ultrafilter U) s, U s -> U (comp s) -> False.
Proof.
  intros U H s Hs Hcs. destruct H as [He _ Hi Hu _].
  apply He. eapply (Hu (inter s (comp s))).
  - now apply Hi.
  - intros x Hx. unfold inter, comp, empty in *. simpl in Hx.
    destruct (s x); discriminate.
Qed.

Lemma principal_of_single : forall U (H : Ultrafilter U) a,
  U (single a) -> forall s, U s <-> s a = true.
Proof.
  intros U H a Ha s. split.
  - intro Hs. destruct (s a) eqn:E; auto.
    exfalso. apply (no_both U H s Hs).
    destruct H as [_ _ _ Hu _].
    eapply (Hu (single a)); auto.
    intros x Hx. unfold single, comp in *.
    apply eqb_eq in Hx. subst x. now rewrite E.
  - intro E. destruct H as [_ _ _ Hu _].
    eapply (Hu (single a)); auto.
    intros x Hx. unfold single in *.
    apply eqb_eq in Hx. now subst x.
Qed.

Definition complements (xs : list A) : subset :=
  fold_right (fun a rest => inter (comp (single a)) rest) full xs.

Lemma complements_false : forall xs x, In x xs -> complements xs x = false.
Proof.
  induction xs as [|a xs IH]; simpl; intros x Hx.
  - contradiction.
  - destruct Hx as [->|Hx].
    + unfold inter, comp, single.
      replace (eqb x x) with true by (symmetry; now apply eqb_eq).
      reflexivity.
    + unfold inter in *. now rewrite IH, andb_false_r.
Qed.

Lemma find_singleton_or_complements : forall U (H : Ultrafilter U) xs,
  (exists a, In a xs /\ U (single a)) \/ U (complements xs).
Proof.
  intros U H xs. induction xs as [|a xs IH]; simpl.
  - right. apply (uf_full _ H).
  - destruct (uf_decide _ H (single a)) as [Ha|Ha].
    + left. exists a. auto.
    + destruct IH as [(b & Hb & HU)|Hrest].
      * left. exists b. auto.
      * right. apply (uf_inter _ H); assumption.
Qed.

Theorem finite_ultrafilter_principal : forall U (H : Ultrafilter U) xs,
  (forall x, @In A x xs) -> exists a, forall s, U s <-> s a = true.
Proof.
  intros U H xs Hcover.
  destruct (find_singleton_or_complements U H xs) as [(a & _ & Ha)|HC].
  - exists a. now apply principal_of_single.
  - exfalso. apply (uf_empty _ H).
    destruct H as [_ _ _ Hu _].
    eapply (Hu (complements xs)); eauto.
    intros x Hx. rewrite (complements_false xs x (Hcover x)) in Hx.
    discriminate.
Qed.

(* 主超幂的相等判据：一致集属于主超滤，当且仅当两函数在焦点相等。 *)
Definition principal (U : subset -> Prop) (a : A) : Prop :=
  forall s, U s <-> s a = true.

Theorem principal_agreement : forall U a f g,
  principal U a -> (U (fun x => eqb (f x) (g x)) <-> eqb (f a) (g a) = true).
Proof. intros U a f g H. apply H. Qed.

End Finite.

End Ch94.
