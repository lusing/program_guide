(* 第 84 章 · KP 与可采纳集合（冯琦第二卷 §1.1）。
   Δ₀（有界）表达式与 Δ₀-绝对性：传递子收藏上，有界量词的 M-守卫是冗余的。 *)
Require Import Arith Nat.

Section Admissible.

Variable S : Type.
Variable mem : S -> S -> Prop.

(* 有界（Δ₀）表达式：量词只以 (∀x∈t)/(∃x∈t) 的形式出现。 *)
Inductive bform : Type :=
| bmem : nat -> nat -> bform
| beq  : nat -> nat -> bform
| bneg : bform -> bform
| band : bform -> bform -> bform
| ball : nat -> nat -> bform -> bform   (* ∀v_i ∈ v_j. f *)
| bex  : nat -> nat -> bform -> bform.   (* ∃v_i ∈ v_j. f *)

Definition upd (e : nat -> S) (i : nat) (x : S) : nat -> S :=
  fun k => if Nat.eqb k i then x else e k.

(* 全论域语义：有界量词跑遍集合 e j 的全部元素。 *)
Fixpoint evalV (e : nat -> S) (f : bform) : Prop :=
  match f with
  | bmem i j   => mem (e i) (e j)
  | beq i j    => e i = e j
  | bneg p     => ~ evalV e p
  | band p q   => evalV e p /\ evalV e q
  | ball i j p => forall x, mem x (e j) -> evalV (upd e i x) p
  | bex i j p  => exists x, mem x (e j) /\ evalV (upd e i x) p
  end.

(* 相对化语义：有界量词只跑遍落在 M 里的那些元素。 *)
Fixpoint evalM (M : S -> Prop) (e : nat -> S) (f : bform) : Prop :=
  match f with
  | bmem i j   => mem (e i) (e j)
  | beq i j    => e i = e j
  | bneg p     => ~ evalM M e p
  | band p q   => evalM M e p /\ evalM M e q
  | ball i j p => forall x, mem x (e j) -> M x -> evalM M (upd e i x) p
  | bex i j p  => exists x, mem x (e j) /\ M x /\ evalM M (upd e i x) p
  end.

Definition Transitive (M : S -> Prop) : Prop :=
  forall x y, M x -> mem y x -> M y.

Lemma upd_eq : forall (e : nat -> S) i (x : S), upd e i x i = x.
Proof. intros. unfold upd. rewrite Nat.eqb_refl. reflexivity. Qed.

Lemma upd_neq : forall (e : nat -> S) i j (x : S), i <> j -> upd e i x j = e j.
Proof.
  intros e i j x Hne. unfold upd. destruct (Nat.eqb_spec j i) as [Heq|Hneq].
  - exfalso. apply Hne. symmetry. exact Heq.
  - reflexivity.
Qed.

(* 更新后的赋值仍全落在 M 中（只要新值在 M 中）。 *)
Lemma upd_M : forall (M : S -> Prop) (e : nat -> S) i (x : S),
  (forall k, M (e k)) -> M x -> forall k, M (upd e i x k).
Proof.
  intros M e i x Hall Hx k.
  destruct (Nat.eqb_spec k i) as [Heq|Hneq].
  - rewrite Heq. rewrite upd_eq. exact Hx.
  - rewrite (upd_neq e i k x) by (symmetry; exact Hneq). exact (Hall k).
Qed.

(* Δ₀-绝对性：M 传递且赋值全落在 M 中时，两种语义一致。 *)
Theorem delta0_absoluteness :
  forall (M : S -> Prop), Transitive M ->
  forall f, forall (e : nat -> S), (forall i, M (e i)) ->
  evalM M e f <-> evalV e f.
Proof.
  intros M Htrans f. induction f as [i j|i j|p IH|p IH q JH|i j p IH|i j p IH];
    intros e Hall; split.
  - intros H. exact H.          (* bmem -> *)
  - intros H. exact H.          (* bmem <- *)
  - intros H. exact H.          (* beq -> *)
  - intros H. exact H.          (* beq <- *)
  - intros Hn Hv. apply Hn. apply (proj2 (IH e Hall)). exact Hv.   (* bneg -> *)
  - intros Hn Hv. apply Hn. apply (proj1 (IH e Hall)). exact Hv.   (* bneg <- *)
  - intros [Hp Hq]. split; [apply (proj1 (IH e Hall)) | apply (proj1 (JH e Hall))]; assumption.
  - intros [Hp Hq]. split; [apply (proj2 (IH e Hall)) | apply (proj2 (JH e Hall))]; assumption.
  - (* ball, M -> V *)
    intros H x Hx.
    apply (proj1 (IH (upd e i x)
      (upd_M M e i x Hall (Htrans (e j) x (Hall j) Hx)))).
    apply H; [exact Hx | exact (Htrans (e j) x (Hall j) Hx)].
  - (* ball, V -> M：传递性让守卫自动成立 *)
    intros H x Hx Hm.
    apply (proj2 (IH (upd e i x) (upd_M M e i x Hall Hm))).
    apply H. exact Hx.
  - (* bex, M -> V *)
    intros [x [Hx [Hm Hp]]]. exists x. split; [exact Hx|].
    apply (proj1 (IH (upd e i x)
      (upd_M M e i x Hall (Htrans (e j) x (Hall j) Hx)))). exact Hp.
  - (* bex, V -> M：传递性补出守卫 *)
    intros [x [Hx Hp]]. exists x. split; [exact Hx|].
    split; [exact (Htrans (e j) x (Hall j) Hx)|].
    apply (proj2 (IH (upd e i x)
      (upd_M M e i x Hall (Htrans (e j) x (Hall j) Hx)))). exact Hp.
Qed.

(* 推论：Δ₀-分解（分离）在传递收藏上绝对——KP⁻ 的 Δ₀-分解原理
   之所以"舒适"，正因为它只用到这种绝对的存在性。 *)
Corollary delta0_separation_absolute :
  forall (M : S -> Prop) (t : S), Transitive M -> M t ->
  forall (p : bform), forall (e : nat -> S), (forall i, M (e i)) ->
  (exists x, mem x t /\ evalM M (upd e 0 x) p) <->
  (exists x, mem x t /\ evalV (upd e 0 x) p).
Proof.
  intros M t Htrans Ht p e Hall.
  split; intros [x [Hx Hp]].
  - exists x. split; [exact Hx|].
    apply (proj1 (delta0_absoluteness M Htrans p (upd e 0 x)
      (upd_M M e 0 x Hall (Htrans t x Ht Hx)))).
    exact Hp.
  - exists x. split; [exact Hx|].
    apply (proj2 (delta0_absoluteness M Htrans p (upd e 0 x)
      (upd_M M e 0 x Hall (Htrans t x Ht Hx)))).
    exact Hp.
Qed.

End Admissible.
