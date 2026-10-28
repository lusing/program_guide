(* 34 证明即项：Curry–Howard 落地 —— 命题是类型，证明是程序 *)

From Stdlib Require Import Arith List.
From Stdlib Require Import FunctionalExtensionality ProofIrrelevance.
Import ListNotations.

Module Ex49ProofTerms.

(* ---------- 49.1 ev：证据是数据 ---------- *)

Inductive ev : nat -> Prop :=
  | ev_0 : ev 0
  | ev_SS (n : nat) (H : ev n) : ev (S (S n)).

Theorem ev_4 : ev 4.
Proof.
  apply ev_SS. apply ev_SS. apply ev_0.
Qed.

Print ev_4.

Check (ev_SS 2 (ev_SS 0 ev_0) : ev 4).

(* ---------- 49.2 Proof/Qed 内部：填洞 ---------- *)

Theorem ev_4s : ev 4.
Proof.
  Show Proof.
  apply ev_SS.
  Show Proof.
  apply ev_SS.
  Show Proof.
  apply ev_0.
  Show Proof.
Qed.

Theorem ev_4a : ev 4.
Proof.
  apply (ev_SS 2 (ev_SS 0 ev_0)).
Qed.

Definition ev_4d : ev 4 := ev_SS 2 (ev_SS 0 ev_0).

Print ev_4s.
Print ev_4a.
Print ev_4d.

Fail Check (ev_SS 2 ev_0 : ev 4).

(* ---------- 49.3 forall 与 -> 就是函数 ---------- *)

Theorem ev_plus4 : forall n, ev n -> ev (4 + n).
Proof.
  intros n H. simpl.
  apply ev_SS. apply ev_SS. apply H.
Qed.

Print ev_plus4.

Definition ev_plus4' : forall n, ev n -> ev (4 + n) :=
  fun n => fun (H : ev n) => ev_SS (S (S n)) (ev_SS n H).

Definition ev_plus4'' (n : nat) (H : ev n) : ev (4 + n) :=
  ev_SS (S (S n)) (ev_SS n H).

Check (ev_plus4'' : forall n : nat, ev n -> ev (4 + n)).

Definition ev_plus2 : Prop := forall n, forall (E : ev n), ev (n + 2).
Definition ev_plus2' : Prop := forall n, forall (_ : ev n), ev (n + 2).
Definition ev_plus2'' : Prop := forall n, ev n -> ev (n + 2).

(* ---------- 49.4 用策略写程序 ---------- *)

Definition add2 : nat -> nat.
Proof.
  intros n.
  Show Proof.
  apply S.
  apply S.
  exact n.
Defined.

Print add2.
Compute (add2 2).

Definition add2o : nat -> nat.
Proof.
  intros n. apply S. apply S. exact n.
Qed.

Compute (add2o 2).
Fail Check (eq_refl 4 : add2o 2 = 4).

(* ---------- 49.5 连接词是归纳类型 ---------- *)

Print prod.

Module MyProps.

Inductive and (P Q : Prop) : Prop :=
  | conj : P -> Q -> and P Q.

Inductive or (P Q : Prop) : Prop :=
  | or_introl : P -> or P Q
  | or_intror : Q -> or P Q.

Inductive ex {A : Type} (P : A -> Prop) : Prop :=
  | ex_intro : forall x : A, P x -> ex P.

Inductive True : Prop := I : True.

Inductive False : Prop := .

End MyProps.

Definition proj1'' P Q (HPQ : P /\ Q) : P :=
  match HPQ with
  | conj HP HQ => HP
  end.

Definition and_comm'_aux P Q (H : P /\ Q) : Q /\ P :=
  match H with
  | conj HP HQ => conj HQ HP
  end.

Definition and_comm' P Q : P /\ Q <-> Q /\ P :=
  conj (and_comm'_aux P Q) (and_comm'_aux Q P).

Definition inj_l : forall (P Q : Prop), P -> P \/ Q :=
  fun P Q HP => or_introl HP.

Definition or_elim : forall (P Q R : Prop), (P \/ Q) -> (P -> R) -> (Q -> R) -> R :=
  fun P Q R HPQ HPR HQR =>
    match HPQ with
    | or_introl HP => HPR HP
    | or_intror HQ => HQR HQ
    end.

Definition some_nat_is_even : exists n : nat, ev n :=
  ex_intro ev 4 (ev_SS 2 (ev_SS 0 ev_0)).

Definition dist_exists_or_term (X : Type) (P Q : X -> Prop) :
  (exists x : X, P x \/ Q x) -> (exists x : X, P x) \/ (exists x : X, Q x) :=
  fun H => match H with
           | ex_intro _ x Hx =>
               match Hx with
               | or_introl HPx => or_introl (ex_intro _ x HPx)
               | or_intror HQx => or_intror (ex_intro _ x HQx)
               end
           end.

(* ---------- 49.6 True、False 与爆炸原理 ---------- *)

Fail Definition contra : False := 42.

Definition false_implies_zero_eq_one : False -> 0 = 1 :=
  fun contra => match contra with end.

Definition ex_falso_quodlibet' : forall P : Prop, False -> P :=
  fun P contra => match contra with end.

(* ---------- 49.7 等号也是归纳出来的 ---------- *)

Module EqPlay.

Inductive eq {X : Type} : X -> X -> Prop :=
  | eq_refl : forall x, eq x x.

Notation "x == y" := (eq x y)
  (at level 70, no associativity) : type_scope.

Lemma four : 2 + 2 == 1 + 3.
Proof.
  apply eq_refl.
Qed.

Print four.

Definition four' : 2 + 2 == 1 + 3 := eq_refl 4.

Definition singleton : forall (X : Type) (x : X), [] ++ [x] == x :: [] :=
  fun (X : Type) (x : X) => eq_refl [x].

Definition eq_add : forall (n1 n2 : nat), n1 == n2 -> S n1 == S n2 :=
  fun n1 n2 Heq =>
    match Heq with
    | eq_refl n => eq_refl (S n)
    end.

Theorem eq_add_s : forall (n1 n2 : nat), n1 == n2 -> S n1 == S n2.
Proof.
  intros n1 n2 Heq.
  Fail rewrite Heq.
  destruct Heq as [n].
  Fail reflexivity.
  apply eq_refl.
Qed.

Lemma equality__leibniz_equality : forall (X : Type) (x y : X),
  x == y -> forall (P : X -> Prop), P x -> P y.
Proof.
  intros X x y Heq P Hp.
  destruct Heq as [z]. exact Hp.
Qed.

Definition equality__leibniz_equality_term : forall (X : Type) (x y : X),
  x == y -> forall P : X -> Prop, P x -> P y :=
  fun X x y Heq P =>
    match Heq in u == v return P u -> P v with
    | eq_refl _ => fun Hp => Hp
    end.

Lemma leibniz_equality__equality : forall (X : Type) (x y : X),
  (forall P : X -> Prop, P x -> P y) -> x == y.
Proof.
  intros X x y H.
  exact (H (fun z => x == z) (eq_refl x)).
Qed.

End EqPlay.

(* ---------- 49.8 inversion 到底做了什么 ---------- *)

Theorem inv_or_demo : forall (P Q : Prop), P \/ Q -> Q \/ P.
Proof.
  intros P Q H. inversion H as [HP | HQ].
  - right. exact HP.
  - left. exact HQ.
Qed.

Theorem inv_and_demo : forall (P Q : Prop), P /\ Q -> Q /\ P.
Proof.
  intros P Q H. inversion H as [HP HQ]. split.
  - exact HQ.
  - exact HP.
Qed.

Theorem inv_eq_demo : forall (n m : nat), S n = S m -> n = m.
Proof.
  intros n m H. inversion H. reflexivity.
Qed.

Theorem inv_Sn_O : forall n : nat, S n = 0 -> False.
Proof.
  intros n H. inversion H.
Qed.

(* ---------- 49.9 内核只检查三件事 ---------- *)

Fail Definition or_bogus : forall P Q, P \/ Q -> P :=
  fun (P Q : Prop) (A : P \/ Q) =>
    match A with
    | or_introl H => H
    end.

Fail Fixpoint infinite_loop {X : Type} (n : nat) {struct n} : X :=
  infinite_loop n.

Fail Definition falso : False := infinite_loop 0.

(* ---------- 49.10 证明无关性要请出公理 ---------- *)

Module PEPI.

Definition propositional_extensionality : Prop :=
  forall (P Q : Prop), (P <-> Q) -> P = Q.

Definition proof_irrelevance_prop : Prop :=
  forall (P : Prop) (pf1 pf2 : P), pf1 = pf2.

End PEPI.

Print Assumptions functional_extensionality.
Print Assumptions proof_irrelevance.

Fail Definition pe_attempt : PEPI.propositional_extensionality :=
  fun (P Q : Prop) (H : P <-> Q) => eq_refl (P <-> Q).

Print proof_irrelevance.

(* ---------- 49.11 项式证明小练 ---------- *)

Definition and_assoc' : forall P Q R : Prop,
  P /\ (Q /\ R) -> (P /\ Q) /\ R :=
  fun P Q R H =>
    match H with
    | conj HP (conj HQ HR) => conj (conj HP HQ) HR
    end.

Definition curry' : forall P Q R : Prop, ((P /\ Q) -> R) -> P -> Q -> R :=
  fun P Q R f HP HQ => f (conj HP HQ).

Definition uncurry' : forall P Q R : Prop, (P -> Q -> R) -> (P /\ Q) -> R :=
  fun P Q R f HPQ =>
    match HPQ with
    | conj HP HQ => f HP HQ
    end.

Definition de_morgan_not_or' : forall P Q : Prop, ~ (P \/ Q) -> ~ P /\ ~ Q :=
  fun P Q H =>
    conj (fun HP => H (or_introl HP)) (fun HQ => H (or_intror HQ)).

End Ex49ProofTerms.
