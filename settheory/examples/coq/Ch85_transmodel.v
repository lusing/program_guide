(* 第 85 章 · 传递模型与内在模型论（冯琦第二卷 §1.2）。
   例 1.7：传递载体把相对化的同一律还原成外延公理。
   定理 1.22：对存在见证封闭的子载体与原结构初等。 *)
Require Import Nat.

Section Transmodel.

Variable S : Type.
Variable mem : S -> S -> Prop.

Definition Transitive (M : S -> Prop) : Prop :=
  forall x y, M x -> mem y x -> M y.

Definition Extensional : Prop :=
  forall a b, (forall x, mem x a <-> mem x b) -> a = b.

Lemma relativized_extensionality :
  Extensional ->
  forall M, Transitive M ->
  forall a b, M a -> M b ->
  ((forall x, M x -> (mem x a <-> mem x b)) <-> a = b).
Proof.
  intros Hext M Htr a b Ha Hb.
  split.
  - intros H.
    apply Hext. intros x. split.
    + intros Hxa. apply (H x (Htr a x Ha Hxa)). exact Hxa.
    + intros Hxb. apply (H x (Htr b x Hb Hxb)). exact Hxb.
  - intros -> x _. split; intro H; exact H.
Qed.

Inductive fm : Type :=
| feq : nat -> nat -> fm
| fneg : fm -> fm
| fand : fm -> fm -> fm
| fex : nat -> fm -> fm.

Definition update (e : nat -> S) (i : nat) (x : S) : nat -> S :=
  fun k => if Nat.eqb k i then x else e k.

Fixpoint val (e : nat -> S) (p : fm) (R : S -> Prop) : Prop :=
  match p with
  | feq i j => e i = e j
  | fneg q => ~ val e q R
  | fand q r => val e q R /\ val e r R
  | fex i q => exists x, R x /\ val (update e i x) q R
  end.

Definition envIn (B : S -> Prop) (e : nat -> S) : Prop :=
  forall k, B (e k).

Lemma envIn_update : forall B e i x,
  envIn B e -> B x -> envIn B (update e i x).
Proof.
  intros B e i x He Hx k.
  unfold update. destruct (Nat.eqb k i).
  - exact Hx.
  - apply He.
Qed.

(* 定理 1.22：B ⊆ A，且每个存在公式的 A-见证都能改选在 B 中。 *)
Theorem tarski_agreement :
  forall (A B : S -> Prop),
  (forall x, B x -> A x) ->
  (forall p e i, envIn B e ->
     val e (fex i p) A -> exists x, B x /\ val (update e i x) p A) ->
  forall p e, envIn B e -> (val e p B <-> val e p A).
Proof.
  intros A B Hsub Hclosed.
  induction p; intros e He; simpl.
  - split; intro H; exact H.
  - split; intros Hn Hp; apply Hn; apply (IHp e He); exact Hp.
  - split; intros [H1 H2]; split.
    + apply (IHp1 e He). exact H1.
    + apply (IHp2 e He). exact H2.
    + apply (IHp1 e He). exact H1.
    + apply (IHp2 e He). exact H2.
  - split.
    + intros [x [HxB Hx]].
      exists x. split.
      * apply Hsub. exact HxB.
      * apply IHp. apply envIn_update; assumption. exact Hx.
    + intros H.
      destruct (Hclosed p e n He H) as [x [HxB HxA]].
      exists x. split.
      * exact HxB.
      * apply IHp. apply envIn_update; assumption. exact HxA.
Qed.

End Transmodel.
