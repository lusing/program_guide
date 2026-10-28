(* 第 98 章：布尔项 Def 算子——谓词外延性与参数局部性。 *)
From Coq Require Import List Arith Bool Lia.
Import ListNotations.

Module Ch98.

(* 布尔项：self 是 x∈P；mem a 是参数 a∈P；eq a 是 x=a。 *)
Inductive BTerm (A : Type) : Type :=
| bself : BTerm A
| bmem : A -> BTerm A
| beq : A -> BTerm A
| band : BTerm A -> BTerm A -> BTerm A
| bnot : BTerm A -> BTerm A.

Arguments bself {A}.
Arguments bmem {A} _.
Arguments beq {A} _.
Arguments band {A} _ _.
Arguments bnot {A} _.

Fixpoint params {A} (t : BTerm A) : list A :=
  match t with
  | bself => []
  | bmem a => [a]
  | beq a => [a]
  | band l r => params l ++ params r
  | bnot l => params l
  end.

Fixpoint beval {A} (eqb : A -> A -> bool) (P : A -> bool)
    (t : BTerm A) (x : A) : bool :=
  match t with
  | bself => P x
  | bmem a => P a
  | beq a => eqb x a
  | band l r => beval eqb P l x && beval eqb P r x
  | bnot l => negb (beval eqb P l x)
  end.

(* 谓词外延性：外延相等 ⟹ 定义内容相同（L[U] 只依赖 U 外延）。 *)
Theorem eval_ext : forall (A : Type) (eqb : A -> A -> bool) (P Q : A -> bool),
  (forall a, P a = Q a) -> forall (t : BTerm A) (x : A),
  beval eqb P t x = beval eqb Q t x.
Proof.
  intros A eqb P Q hPQ.
  induction t; intros x; simpl.
  - rewrite hPQ. reflexivity.
  - rewrite hPQ. reflexivity.
  - reflexivity.
  - rewrite IHt1, IHt2. reflexivity.
  - rewrite IHt. reflexivity.
Qed.

(* 参数局部性：P、Q 在 R 上一致、x 满足 R、参数都满足 R
   ⟹ 求值一致（L[U]=L[Ũ] 截断的影子）。 *)
Theorem eval_local : forall (A : Type) (eqb : A -> A -> bool)
    (P Q : A -> bool) (R : A -> Prop),
  (forall a, R a -> P a = Q a) ->
  forall x, R x ->
  forall t, (forall a, In a (params t) -> R a) ->
  beval eqb P t x = beval eqb Q t x.
Proof.
  intros A eqb P Q R hR x Hx t.
  induction t; simpl; intros Hparam.
  - apply hR. exact Hx.
  - apply hR. apply Hparam. left. reflexivity.
  - reflexivity.
  - assert (Hp1 : forall a, In a (params t1) -> R a).
    { intros a Ha. apply Hparam. apply in_or_app. left. exact Ha. }
    assert (Hp2 : forall a, In a (params t2) -> R a).
    { intros a Ha. apply Hparam. apply in_or_app. right. exact Ha. }
    rewrite (IHt1 Hp1), (IHt2 Hp2). reflexivity.
  - rewrite (IHt Hparam). reflexivity.
Qed.

(* 样本：三点宇宙上焦点 2 的主测度。 *)
Definition peq2 (n : nat) : bool := Nat.eqb n 2.

Example sample_self : beval Nat.eqb peq2 bself 2 = true.
Proof. reflexivity. Qed.

Example sample_self_other : beval Nat.eqb peq2 bself 0 = false.
Proof. reflexivity. Qed.

Example sample_and :
  beval Nat.eqb peq2 (band (beq 2) bself) 2 = true.
Proof. reflexivity. Qed.

End Ch98.
