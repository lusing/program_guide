(* 第 103 章：Lévy 条件、相容性与稠密性 D(λ,β) 的书式证明。 *)
From Coq Require Import List Arith Lia.
Import ListNotations.

Module Ch103.

(* 条件 = 三元组表 ((α,n),β)：键 (α,n) 无重复、α∈[1,4]、β<α。 *)
Definition wfT (x : (nat * nat) * nat) : Prop :=
  1 <= fst (fst x) <= 4 /\ snd x < fst (fst x).

Definition keysOf (p : list ((nat * nat) * nat)) : list (nat * nat) :=
  map fst p.

Definition Cond (p : list ((nat * nat) * nat)) : Prop :=
  (forall x, In x p -> wfT x) /\ NoDup (keysOf p).

Definition compat (p q : list ((nat * nat) * nat)) : Prop :=
  forall x y, In x p -> In y q -> fst x = fst y -> snd x = snd y.

(* ── 一、稠密性 D(λ,β)：n₀ = 已用 n 之和 + 1（书 p152 公式） ── *)

Fixpoint sumL (l : list nat) : nat :=
  match l with [] => 0 | a :: t => a + sumL t end.

Lemma mem_le_sum : forall (l : list nat) n, In n l -> n <= sumL l.
Proof.
  induction l as [|a t IH]; simpl; intros n Hn.
  - contradiction.
  - destruct Hn as [->|Hn].
    + lia.
    + specialize (IH n Hn). lia.
Qed.

Definition freshN (l : nat) (p : list ((nat * nat) * nat)) : nat :=
  1 + sumL (map (fun z => snd (fst z))
             (filter (fun z => Nat.eqb (fst (fst z)) l) p)).

Lemma freshN_gt : forall l p x, In x p -> fst (fst x) = l ->
  snd (fst x) < freshN l p.
Proof.
  intros l p x Hx Hl.
  assert (Hmem : In (snd (fst x))
            (map (fun z => snd (fst z))
                 (filter (fun z => Nat.eqb (fst (fst z)) l) p))).
  { apply (proj2 (in_map_iff _ _ _)). exists x. split.
    - reflexivity.
    - apply filter_In. split; [exact Hx|]. apply Nat.eqb_eq. exact Hl. }
  pose proof (mem_le_sum _ _ Hmem) as Hle.
  unfold freshN. lia.
Qed.

Theorem extend_dense : forall l beta p,
  1 <= l -> l <= 4 -> beta < l -> Cond p ->
  exists q,
    (forall x, In x p -> In x q) /\ In ((l, freshN l p), beta) q /\ Cond q.
Proof.
  intros l beta p Hl1 Hl4 Hbeta [hw hnd].
  exists (p ++ ((l, freshN l p), beta) :: nil).
  split; [|split].
  - intros x Hx. apply in_or_app. left; exact Hx.
  - apply in_or_app. right. left. reflexivity.
  - split.
    + intros x Hx. apply in_app_or in Hx.
      destruct Hx as [H|H].
      * apply hw; exact H.
      * destruct H as [E|[]]. subst x. unfold wfT. simpl.
        repeat split; lia.
    + unfold keysOf. rewrite map_app. simpl.
      apply NoDup_app.
      * exact hnd.
      * apply NoDup_cons; [simpl; tauto | constructor].
      * intros a Ha Hb.
        simpl in Hb. destruct Hb as [Hb|[]]. subst a.
        apply (proj1 (in_map_iff _ _ _)) in Ha.
        destruct Ha as [x [Hfx Hx]].
        assert (Hl : fst (fst x) = l).
        { pose proof (f_equal (@fst _ _) Hfx) as Hc. simpl in Hc. exact Hc. }
        pose proof (freshN_gt l p x Hx Hl) as Hgt.
        assert (Hs : snd (fst x) = freshN l p).
        { pose proof (f_equal (@snd _ _) Hfx) as Hc. simpl in Hc. exact Hc. }
        lia.
Qed.

(* ── 二、样本：相容/不相容与稠密扩展的具体形状 ── *)

Example sample_compat : compat [((2,0),1)] [((3,1),2)].
Proof.
  intros x y Hx Hy Hxy.
  simpl in Hx, Hy, Hxy.
  destruct Hx as [Hx|[]]; destruct Hy as [Hy|[]]; subst.
  injection Hxy as E1 E2. lia.
Qed.

Example sample_not_compat : ~ compat [((2,0),1)] [((2,0),0)].
Proof.
  intros hc.
  assert (H : 1 = 0).
  { apply (hc ((2,0),1) ((2,0),0)); simpl; auto. }
  discriminate.
Qed.

(* 稠密扩展样本：freshN 2 [((2,5),0)] = 6（λ=2 的已用 n 只有 5，
   n₀ = 1+5——大于一切已用槽号）。 *)
Example sample_fresh : freshN 2 [((2,5),0)] = 6.
Proof. reflexivity. Qed.

End Ch103.
