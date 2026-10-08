From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.
Definition lsum (l : list nat) : nat := fold_right Nat.add 0 l.
Lemma lsum_cons : forall x l, lsum (x :: l) = x + lsum l. Proof. reflexivity. Qed.
Lemma sum_tag_zero : forall a vs, ~ In a vs ->
    lsum (map (fun v => if Nat.eqb v a then 1 else 0) vs) = 0.
Proof.
  intros a vs; induction vs as [|x vs IH]; intros Hnin.
  - reflexivity.
  - cbn [map]. destruct (Nat.eqb x a) eqn:E.
    + apply Nat.eqb_eq in E. subst x.
      exfalso; apply Hnin; left; reflexivity.
    + assert (Ht : ~ In a vs) by (intro Hc; apply Hnin; right; exact Hc).
      rewrite lsum_cons. rewrite IH by exact Ht. reflexivity.
Qed.

Lemma sum_tag_one : forall a vs, NoDup vs -> In a vs ->
    lsum (map (fun v => if Nat.eqb v a then 1 else 0) vs) = 1.
Proof.
  intros a vs; induction vs as [|x vs IH]; intros Hnd Hin.
  - contradiction.
  - inversion Hnd as [|? ? Hnin Hnd']; subst.
    cbn [map]. destruct Hin as [Ha | Hin].
    + subst x. rewrite lsum_cons, Nat.eqb_refl, (sum_tag_zero a vs Hnin).
      reflexivity.
    + destruct (Nat.eqb x a) eqn:E.
      * apply Nat.eqb_eq in E. subst x.
        exfalso; apply Hnin; left; assumption.
      * rewrite lsum_cons. rewrite IH by assumption. reflexivity.
Qed.

