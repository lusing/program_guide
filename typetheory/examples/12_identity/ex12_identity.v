(* ============================================================ *)
(* 12 相等类型与 J（Nordström ch.8）—— Coq 侧手工课              *)
(* 先看 eq 的真身，再用 eq_ind 亲手推四件套                       *)
(* ============================================================ *)

Print eq.
(* Inductive eq (A : Type) (x : A) : A -> Prop :=  eq_refl : x = x
   —— 与 Lean 版 MyEq 同构：refl 唯一构造子          *)

Print eq_ind.
(* forall (A : Type) (x : A) (P : A -> Prop),
       P x -> forall y : A, x = y -> P y
   —— 这就是 J：命题版消去子                        *)

Print eq_rect.
(* eq_rect 是 Type 版（大消去）：transport 的原生形态 *)

(* ---- 四件套：全部用 eq_ind 手推 ---- *)

Theorem my_sym : forall (A : Type) (x y : A), x = y -> y = x.
Proof.
  intros A x y H.
  apply (eq_ind x (fun z => z = x) (eq_refl x) y H).
Qed.

Theorem my_trans : forall (A : Type) (x y z : A), x = y -> y = z -> x = z.
Proof.
  intros A x y z H1 H2.
  apply (eq_ind y (fun w => x = w) H1 z H2).
Qed.

Theorem my_cong : forall (A B : Type) (f : A -> B) (x y : A),
  x = y -> f x = f y.
Proof.
  intros A B f x y H.
  apply (eq_ind x (fun z => f x = f z) (eq_refl (f x)) y H).
Qed.

Theorem my_subst : forall (A : Type) (P : A -> Prop) (x y : A),
  x = y -> P x -> P y.
Proof.
  intros A P x y H HP.
  apply (eq_ind x (fun z => P z) HP y H).
Qed.

(* ---- transport 的 Type 版：eq_rect 直用 ---- *)

Definition my_transport (A : Type) (Q : A -> Type) (x y : A)
  (H : x = y) (q : Q x) : Q y :=
  eq_rect x Q q y H.

(* 长度证据跟着向量走 *)
Definition VecN (n : nat) : Type :=
  nat * nat * nat.  (* 教学占位：真实长度索引见 13 章 *)

Check (my_transport nat (fun n => VecN n) 2 2 eq_refl).

(* ---- 内涵 vs 外延：J 推不出 funext ---- *)
(* 处处相等推不出函数相等——Coq 把它做成【可选公理】： *)
Require Import FunctionalExtensionality.

Theorem funext_demo : forall (f g : nat -> nat),
  (forall n, f n = g n) -> f = g.
Proof.
  intros f g H. apply functional_extensionality. exact H.
Qed.

Print Assumptions funext_demo.
(* depends on: functional_extensionality —— 不走 J！ *)
