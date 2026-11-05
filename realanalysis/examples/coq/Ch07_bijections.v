(* 第 07 章 双射：Coq/Rocq 通道。
   在有限类型与整数/实数函数上核对像、原像、单射/满射/双射、
   双射⇔可逆、复合。 *)

From Stdlib Require Import Arith.
From Stdlib Require Import ZArith.
From Stdlib Require Import Reals.
From Stdlib Require Import Lia.
From Stdlib Require Import Lra.
From Stdlib Require Import List.
From Stdlib Require Import Bool.
Import ListNotations.
Open Scope Z_scope.

(* ================================================================ *)
(* 像与原像（有限列表影子）                                         *)
(* ================================================================ *)

Definition image (A : list Z) (f : Z -> Z) : list Z :=
  map f A.

Definition preimage (A : list Z) (f : Z -> Z) (y : Z) : list Z :=
  filter (fun x => Z.eqb (f x) y) A.

Example const_image :
  image [1; 2; 3] (fun _ => 1) = [1; 1; 1].
Proof. reflexivity. Qed.

(* 在 {-5..5} 上，平方原像 16 恰为 [4; -4]（filter 保序）。 *)
Example sq_preimage_16 :
  preimage [-5; -4; -3; -2; -1; 0; 1; 2; 3; 4; 5]
           (fun x => x * x) 16 = [-4; 4].
Proof. reflexivity. Qed.

(* ================================================================ *)
(* 单射 / 满射 / 双射（命题版）                                      *)
(* ================================================================ *)

Definition injective {A B : Type} (f : A -> B) : Prop :=
  forall x1 x2 : A, f x1 = f x2 -> x1 = x2.

Definition surjective {A B : Type} (f : A -> B) : Prop :=
  forall y : B, exists x : A, f x = y.

Definition bijective {A B : Type} (f : A -> B) : Prop :=
  injective f /\ surjective f.

(* x ↦ 2x 在 Z 上单射。 *)
Lemma mul2_inj : injective (fun x : Z => 2 * x).
Proof.
  intros x1 x2 H. lia.
Qed.

(* x ↦ x² 在 Z 上非单射。 *)
Lemma sq_not_inj : ~ injective (fun x : Z => x * x).
Proof.
  intros H.
  specialize (H 2 (-2)%Z).
  assert (E : (2 * 2 = (-2) * (-2))%Z) by lia.
  specialize (H E). discriminate.
Qed.

(* bool → unit 常值：满射非单射。 *)
Lemma const_surj_not_inj :
  surjective (fun _ : bool => tt) /\ ~ injective (fun _ : bool => tt).
Proof.
  split.
  - intros []. exists true. reflexivity.
  - intros H. specialize (H true false eq_refl). discriminate.
Qed.

(* unit → bool，* ↦ true：单射非满射。 *)
Lemma inj_not_surj :
  injective (fun _ : unit => true) /\ ~ surjective (fun _ : unit => true).
Proof.
  split.
  - intros [] [] _. reflexivity.
  - intros H. destruct (H false) as [[] hf]. discriminate.
Qed.

(* x ↦ 2x 在 R 上双射，逆为 /2。 *)
Open Scope R_scope.

Lemma mul2_bij_R : bijective (fun x : R => 2 * x).
Proof.
  split.
  - intros x1 x2 H. lra.
  - intros y. exists (y / 2). field.
Qed.

(* 定理 7.15 的显式形状：加倍给出双边逆（一般情形需选择公理）。 *)
Definition mul2_inv (y : R) : R := y / 2.

Lemma mul2_left_inv : forall x, mul2_inv (2 * x) = x.
Proof. intros. unfold mul2_inv. field. Qed.

Lemma mul2_right_inv : forall y, 2 * mul2_inv y = y.
Proof. intros. unfold mul2_inv. field. Qed.

(* 复合：g∘f。 *)
Definition compose {A B C : Type} (g : B -> C) (f : A -> B) : A -> C :=
  fun x => g (f x).

Lemma comp_example :
  forall x : R,
    compose (fun z => z * z) (fun x => 2 * x) x = 4 * (x * x).
Proof. intros. unfold compose. ring. Qed.

(* 双射对复合封闭。 *)
Lemma bij_comp {A B C : Type} (f : A -> B) (g : B -> C) :
  bijective f -> bijective g -> bijective (compose g f).
Proof.
  intros [fi fs] [gi gs]. split.
  - intros x1 x2 H. apply fi. apply gi. exact H.
  - intros z. destruct (gs z) as [y Hy]. destruct (fs y) as [x Hx].
    exists x. unfold compose. rewrite Hx. exact Hy.
Qed.

(* 与逆复合得恒等。 *)
Lemma mul2_inv_id_l : forall x, compose mul2_inv (fun x => 2 * x) x = x.
Proof. apply mul2_left_inv. Qed.

Lemma mul2_inv_id_r : forall y, compose (fun x => 2 * x) mul2_inv y = y.
Proof. apply mul2_right_inv. Qed.
