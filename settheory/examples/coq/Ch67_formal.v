(* 第 67 章：传递集合与形式理论（冯琦 引言+§1.1-1.2）
   Hilbert 推导检查器（表达式 + 公理模式 a/c + 分离规则）；
   有序对单射性（定理 1.2）；康托尔对角线（定理 1.4 核心）。 *)
From Coq Require Import List Arith Lia.
Import ListNotations.

(* ---------- 定义 1.1：表达式（命题片段） ---------- *)

Inductive fml : Type :=
| Var (n : nat)
| Imp (p q : fml)
| Neg (p : fml).

Fixpoint eqb_fml (a b : fml) : bool :=
  match a, b with
  | Var m, Var n => Nat.eqb m n
  | Imp p1 q1, Imp p2 q2 => andb (eqb_fml p1 p2) (eqb_fml q1 q2)
  | Neg p, Neg q => eqb_fml p q
  | _, _ => false
  end.

(* ---------- 定义 1.22 (1)：公理模式识别 ---------- *)

(* (c) P -> (Q -> P)：内层后件须等于外层前件 *)
Definition is_axc (f : fml) : bool :=
  match f with
  | Imp p (Imp q r) => eqb_fml p r
  | _ => false
  end.

(* (a) ((P->(Q->R)) -> ((P->Q) -> (P->R))) *)
Definition is_axa (f : fml) : bool :=
  match f with
  | Imp (Imp p (Imp q r)) (Imp (Imp p2 q2) (Imp p3 r3)) =>
      andb (eqb_fml p p2) (andb (eqb_fml p p3)
        (andb (eqb_fml q q2) (eqb_fml r r3)))
  | _ => false
  end.

(* ---------- 定义 1.23：推导检查（公理实例或 MP） ---------- *)

Inductive just : Type :=
| JxA | JxC | JMP (i j : nat).

Fixpoint check (pre : list (fml * just)) (rest : list (fml * just)) : bool :=
  match rest with
  | [] => true
  | (f, JxA) :: rest' =>
      is_axa f && check (pre ++ [(f, JxA)]) rest'
  | (f, JxC) :: rest' =>
      is_axc f && check (pre ++ [(f, JxC)]) rest'
  | (f, JMP i j) :: rest' =>
      match nth_error pre i, nth_error pre j with
      | Some (Imp x y, _), Some (x', _) =>
          andb (eqb_fml x x') (andb (eqb_fml f y)
            (check (pre ++ [(f, JMP i j)]) rest'))
      | _, _ => false
      end
  end.

Definition check_derivation (l : list (fml * just)) : bool := check [] l.

(* ---------- 67.6：P -> P 的五步链 ---------- *)

Definition P : fml := Var 0.

Definition chain : list (fml * just) :=
  [ (Imp P (Imp (Imp P P) P), JxC);
    (Imp (Imp P (Imp (Imp P P) P))
        (Imp (Imp P (Imp P P)) (Imp P P)), JxA);
    (Imp (Imp P (Imp P P)) (Imp P P), JMP 1 0);
    (Imp P (Imp P P), JxC);
    (Imp P P, JMP 2 3) ].

Example chain_ok : check_derivation chain = true.
Proof. vm_compute. reflexivity. Qed.

(* 篡改链：交换 MP 实参（第 4 步小前提拿了第 3 步大前提） *)
Example chain_corrupted_rejected :
  check_derivation (firstn 4 chain ++ [(Imp P P, JMP 3 2)]) = false.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 定理 1.2：有序对由分量决定 ---------- *)

Lemma pair_inj : forall (a b c d : nat),
  (a, b) = (c, d) -> a = c /\ b = d.
Proof.
  intros a b c d H; injection H as H1 H2; split; assumption.
Qed.

(* ---------- 定理 1.4 核心：对角线法（无满射到特征函数全体） ---------- *)

Theorem no_surjection : forall f : nat -> (nat -> bool),
  exists D, forall i, f i <> D.
Proof.
  intros f.
  exists (fun i => negb (f i i)).
  intros i Hrewrite.
  assert (H : f i i = negb (f i i)).
  { rewrite Hrewrite. reflexivity. }
  destruct (f i i); simpl in H; discriminate.
Qed.
