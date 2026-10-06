(* ex18 —— 前束范式与子句形：量词穿越的等价保持
   对书：Mendelson §2.10 / EFT VIII.4 / Ben-Ari 3e §9.2

   论域取 bool（二元量词）——「x ∉ FV(Q) 则换 x 处赋值
   不改变 Q」由一致性引理的布尔版承担。

   旗舰四条（全部零公理）：
     all_and_split  ∀x.(P∧Q) → (∀x.P ∧ ∀x.Q)
     all_or_mono    (∀x.P) → ∀x.(P∨Q)
     all_and_join   (∀x.P) ∧ Q → ∀x.(P∧Q)（x∉FV Q）
     all_or_swap    (∀x.P) ∨ Q → ∀x.(P∨Q)（x∉FV Q）

   完整 PNF 算法（变元标准化+量词逐层前移+¬/→ 的经典改写）
   作为文档——四条构件正是其循环不变式的核心。 *)

From Stdlib Require Import List Bool Arith.
Import ListNotations.

Inductive pform : Type :=
| patom : nat -> nat -> pform
| pand : pform -> pform -> pform
| por : pform -> pform -> pform
| pneg : pform -> pform
| pall : nat -> pform -> pform.

Definition penv := nat -> nat -> bool.

Definition eupdb (e : nat -> bool) (y : nat) (v : bool) : nat -> bool :=
  fun m => if Nat.eqb m y then v else e m.

Fixpoint peval (pe : penv) (e : nat -> bool) (f : pform) : Prop :=
  match f with
  | patom p x => pe p x = true
  | pand a b => peval pe e a /\ peval pe e b
  | por a b => peval pe e a \/ peval pe e b
  | pneg a => ~ peval pe e a
  | pall y a => forall v : bool, peval pe (eupdb e y v) a
  end.

Fixpoint pfv (f : pform) : list nat :=
  match f with
  | patom _ x => [x]
  | pand a b => pfv a ++ pfv b
  | por a b => pfv a ++ pfv b
  | pneg a => pfv a
  | pall y a => remove (Nat.eq_dec) y (pfv a)
  end.

(* In x l /\ x <> y -> In x (remove y l)——in_remove 的逆向 *)
Lemma keep_remove : forall y l z,
  In z l -> z <> y -> In z (remove (Nat.eq_dec) y l).
Proof.
  intros y l. induction l as [|a l' IH]; intros z Hin Hne;
    simpl in Hin; simpl.
  - contradiction.
  - destruct (Nat.eq_dec y a) as [Heq | Hnd].
    + destruct Hin as [Heq' | Hin'].
      * exfalso. apply Hne. exact (eq_trans (eq_sym Heq') (eq_sym Heq)).
      * simpl. apply IH; assumption.
    + destruct Hin as [Heq' | Hin']; simpl.
      * left. exact Heq'.
      * right. apply IH; assumption.
Qed.

(* ---------- 一致性引理（15 章配方） ---------- *)

Lemma peval_coincidence : forall pe f e1 e2,
  (forall m, In m (pfv f) -> e1 m = e2 m) ->
  (peval pe e1 f <-> peval pe e2 f).
Proof.
  induction f as [p x | a IHa b IHb | a IHa b IHb | a IHa | y a IHa];
    intros e1 e2 Hag; simpl.
  - split; intros H; exact H.
  - assert (Ha : forall m, In m (pfv a) -> e1 m = e2 m).
    { intros m Hm. apply Hag. apply in_or_app. left. exact Hm. }
    assert (Hb : forall m, In m (pfv b) -> e1 m = e2 m).
    { intros m Hm. apply Hag. apply in_or_app. right. exact Hm. }
    split; intros [H1 H2]; split.
    + apply (proj1 (IHa e1 e2 Ha)). exact H1.
    + apply (proj1 (IHb e1 e2 Hb)). exact H2.
    + apply (proj2 (IHa e1 e2 Ha)). exact H1.
    + apply (proj2 (IHb e1 e2 Hb)). exact H2.
  - assert (Ha : forall m, In m (pfv a) -> e1 m = e2 m).
    { intros m Hm. apply Hag. apply in_or_app. left. exact Hm. }
    assert (Hb : forall m, In m (pfv b) -> e1 m = e2 m).
    { intros m Hm. apply Hag. apply in_or_app. right. exact Hm. }
    split; intros [H1 | H2].
    + left. apply (proj1 (IHa e1 e2 Ha)). exact H1.
    + right. apply (proj1 (IHb e1 e2 Hb)). exact H2.
    + left. apply (proj2 (IHa e1 e2 Ha)). exact H1.
    + right. apply (proj2 (IHb e1 e2 Hb)). exact H2.
  - assert (Ha : forall m, In m (pfv a) -> e1 m = e2 m).
    { intros m Hm. apply Hag. exact Hm. }
    split; intros H H1.
    + apply H. apply (proj2 (IHa e1 e2 Ha)). exact H1.
    + apply H. apply (proj1 (IHa e1 e2 Ha)). exact H1.
  - assert (Hsub : forall v,
      (forall m, In m (pfv a) -> eupdb e1 y v m = eupdb e2 y v m)).
    { intros v m Hm. unfold eupdb.
      destruct (Nat.eqb m y) eqn:E; [reflexivity|].
      apply Nat.eqb_neq in E.
      apply Hag. apply keep_remove; [exact Hm | exact E]. }
    split; intros H v.
    + apply (proj1 (IHa (eupdb e1 y v) (eupdb e2 y v) (Hsub v))).
      apply H.
    + apply (proj2 (IHa (eupdb e1 y v) (eupdb e2 y v) (Hsub v))).
      apply H.
Qed.

(* ---------- 辅助：x ∉ FV(f) 则换 x 处赋值不改变语义 ---------- *)

Lemma peval_irrelevant_at : forall pe f y v e,
  ~ In y (pfv f) ->
  peval pe e f <-> peval pe (eupdb e y v) f.
Proof.
  intros pe f y v e Hy.
  apply peval_coincidence.
  intros m Hm. unfold eupdb.
  destruct (Nat.eqb m y) eqn:E; [ | reflexivity].
  apply Nat.eqb_eq in E. subst m.
  exfalso. apply Hy.
  (* In y (pfv f) 矛盾——但 Hm : In y (pfv f)?? Hm 的变元是 m=y *)
  exact Hm.
Qed.

(* ---------- 旗舰四条（全部零公理） ---------- *)

Theorem all_and_split : forall pe e y P Q,
  peval pe e (pall y (pand P Q)) ->
  peval pe e (pand (pall y P) (pall y Q)).
Proof.
  intros pe e y P Q H. split; intros v; specialize (H v); destruct H; assumption.
Qed.

Theorem all_or_mono : forall pe e y P Q,
  peval pe e (pall y P) ->
  peval pe e (pall y (por P Q)).
Proof.
  intros pe e y P Q HP v. left. apply HP.
Qed.

Theorem all_and_join : forall pe e y P Q,
  ~ In y (pfv Q) ->
  peval pe e (pand (pall y P) Q) ->
  peval pe e (pall y (pand P Q)).
Proof.
  intros pe e y P Q HQf [HP HQ] v. split.
  - apply HP.
  - apply (proj1 (peval_irrelevant_at pe Q y v e HQf)).
    exact HQ.
Qed.

Theorem all_or_swap : forall pe e y P Q,
  ~ In y (pfv Q) ->
  peval pe e (por (pall y P) Q) ->
  peval pe e (pall y (por P Q)).
Proof.
  intros pe e y P Q HQf [HP | HQ] v.
  - left. apply HP.
  - right. apply (proj1 (peval_irrelevant_at pe Q y v e HQf)).
    exact HQ.
Qed.

Print Assumptions peval_coincidence.  (* Closed *)
Print Assumptions all_and_join.      (* Closed *)
Print Assumptions all_or_swap.       (* Closed *)

(* ---------- 现场演示：量词前移一步 ---------- *)

(* ( ∀1. P(1) ) ∧ Q(2)  ⟹  ∀1.( P(1) ∧ Q(2) )——1 ∉ FV(Q(2))={2} ✓ *)
Example pull_one :
  forall pe e,
    peval pe e (pand (pall 1 (patom 0 1)) (patom 1 2)) ->
    peval pe e (pall 1 (pand (patom 0 1) (patom 1 2))).
Proof.
  intros pe e. apply all_and_join.
  simpl. intros [H | H]; [discriminate H | contradiction].
Qed.

(* 坑位速记（Coq 侧）：
   - fall 分支的一致性：两侧 eupdb 的 if 同时展开——
     连续两次 destruct 同一 eqb（第一次定分支、第二次匹配两侧）；
   - irrelevant_at 的 y ∈ pfv 矛盾：Hag 的 Hm 已是 In m (pfv f)
     且 m=y——直接 exact Hm（remove 后的成员用于子公式、
     原成员用于矛盾）；
   - all_and_join / all_or_swap 的侧条件在 Q 侧——不对称！
     P 侧被量词管住不需要条件。 *)
