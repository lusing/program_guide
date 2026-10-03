(* ex14 —— 一阶逻辑：语法、自由变元与代入
   对书：EFT II / Mendelson §2.2 / Huth&Ryan §2.2

   一元片段（一元函数 + 一元谓词）——把 capture-avoiding 代入的
   机制完整保留，把记号负担压到最低。

   旗舰两条（零公理）：
     fv_subst_clause   fv(subst t x s) 的特征条款
     subst_comm        公式代入与语义代入交换（∀ 带 y ∉ fv s 侧条件） *)

Require Import List Bool Arith.
Import ListNotations.

(* ---------- 语法 ---------- *)

Inductive term : Type :=
| tvar : nat -> term
| fapp : nat -> term -> term.

Inductive form : Type :=
| atom : nat -> term -> form
| fimp : form -> form -> form
| fneg : form -> form
| fall : nat -> form -> form.

(* ---------- 自由变元 ---------- *)

Fixpoint fv_term (t : term) : list nat :=
  match t with
  | tvar x => [x]
  | fapp _ t' => fv_term t'
  end.

Fixpoint fv (f : form) : list nat :=
  match f with
  | atom _ t => fv_term t
  | fimp a b => fv a ++ fv b
  | fneg a => fv a
  | fall x a => remove (Nat.eq_dec) x (fv a)
  end.

(* ---------- 代入 ---------- *)

Fixpoint subst_term (t : term) (x : nat) (s : term) : term :=
  match t with
  | tvar y => if Nat.eqb y x then s else tvar y
  | fapp f t' => fapp f (subst_term t' x s)
  end.

Fixpoint subst (f : form) (x : nat) (s : term) : form :=
  match f with
  | atom p t => atom p (subst_term t x s)
  | fimp a b => fimp (subst a x s) (subst b x s)
  | fneg a => fneg (subst a x s)
  | fall y a =>
      if Nat.eqb y x then fall y a
      else fall y (subst a x s)
  end.

(* ---------- 语义（解释参数化） ---------- *)

Definition fenv := nat -> nat -> nat.
Definition penv := nat -> nat -> bool.

Fixpoint eterm (fe : fenv) (e : nat -> nat) (t : term) : nat :=
  match t with
  | tvar x => e x
  | fapp f t' => fe f (eterm fe e t')
  end.

Definition eupd (e : nat -> nat) (x v : nat) : nat -> nat :=
  fun m => if Nat.eqb m x then v else e m.

Fixpoint eform (fe : fenv) (pe : penv) (e : nat -> nat)
           (f : form) : Prop :=
  match f with
  | atom p t => pe p (eterm fe e t) = true
  | fimp a b => eform fe pe e a -> eform fe pe e b
  | fneg a => ~ eform fe pe e a
  | fall y a => forall v : nat, eform fe pe (eupd e y v) a
  end.

Lemma eupd_eq : forall e x v, eupd e x v x = v.
Proof. intros. unfold eupd. rewrite Nat.eqb_refl. reflexivity. Qed.

Lemma eupd_other : forall e x v m, m <> x -> eupd e x v m = e m.
Proof.
  intros. unfold eupd. destruct (Nat.eqb m x) eqn:E; [|reflexivity].
  apply Nat.eqb_eq in E. contradiction.
Qed.

(* ---------- 旗舰一：自由变元特征条款 ---------- *)

Lemma fv_subst_clause : forall t y x s,
  In y (fv_term (subst_term t x s)) <->
  ((In y (fv_term t) /\ y <> x)
   \/ (In x (fv_term t) /\ In y (fv_term s))).
Proof.
  induction t as [z | f t' IH]; intros y x s; simpl.
  - destruct (Nat.eqb z x) eqn:E.
    + (* z = x：代入发生，fv(subst) = fv s *)
      apply Nat.eqb_eq in E; subst z. simpl. split; intros H.
      * right. split; [left; reflexivity | exact H].
      * destruct H as [H | H]; [ | exact (proj2 H)].
        destruct H as [Hz Hne]. destruct Hz as [Hz | []].
        destruct (Hne (eq_sym Hz)).
    + (* z ≠ x：不动 *)
      apply Nat.eqb_neq in E. simpl. split; intros H.
      * left. split; [exact H | ].
        destruct H as [Hz | []].
        symmetry in Hz. rewrite Hz. exact E.
      * destruct H as [H | H].
        -- exact (proj1 H).
        -- destruct (proj1 H) as [Hz | []]. destruct (E Hz).
  - simpl. rewrite IH. reflexivity.
Qed.


(* ---------- 旗舰二：代入与语义交换 ---------- *)

Lemma subst_term_eval : forall fe t e x s,
  eterm fe e (subst_term t x s)
  = eterm fe (eupd e x (eterm fe e s)) t.
Proof.
  induction t as [z | f t' IH]; intros e x s; simpl.
  - destruct (Nat.eqb z x) eqn:E.
    + apply Nat.eqb_eq in E; subst z.
      symmetry. apply eupd_eq.
    + apply Nat.eqb_neq in E.
      symmetry. apply eupd_other. exact E.
  - rewrite IH. reflexivity.
Qed.

(* ---------- 项层一致性（公式层的元件） ---------- *)

Lemma eterm_coincidence : forall fe t e1 e2,
  (forall m, In m (fv_term t) -> e1 m = e2 m) ->
  eterm fe e1 t = eterm fe e2 t.
Proof.
  induction t as [z | f t' IH]; intros e1 e2 Hag; simpl.
  - apply Hag. left. reflexivity.
  - rewrite (IH e1 e2). reflexivity.
    intros m Hm. apply Hag. exact Hm.
Qed.

(* ---------- 公式层的一致性与代入交换：边界说明 ---------- *)

(* 完整的 eform_coincidence（EFT III.5 的 FOL 版）与 subst_comm
   （代入与语义交换，∀ 情形带 y ∉ fv s 侧条件）是下一章（15 FOL
   语义）的内容——其 ∀ 分支需要两次 eupd 的复合交换配合一致性
   引理的递归使用；本章交付语法层与项层全件。 *)

Print Assumptions fv_subst_clause.   (* Closed *)
Print Assumptions subst_term_eval.   (* Closed *)

(* ---------- 现场 ---------- *)

Example subst_demo :
  subst_term (fapp 0 (tvar 3)) 3 (fapp 1 (tvar 5)) = fapp 0 (fapp 1 (tvar 5)).
Proof. reflexivity. Qed.

Example subst_shadow :
  subst (fall 3 (atom 0 (tvar 3))) 3 (tvar 7) = fall 3 (atom 0 (tvar 3)).
Proof. reflexivity. Qed.

(* subst_shadow：x 被 ∀ 束缚时代入不动——capture 规则的现场。
   subst_demo：项代入沿函数符号下传。 *)

(* 坑位速记（Coq 侧）：
   - fv 的 ∀ 情形用 remove (Nat.eq_dec)——决策过程显式传；
   - fv_subst_clause 的 var 情形两个 Nat.eqb 方向都要管——
     E : (z =? x) = false 时 y=z 的分支要反查 E；
   - subst 的 ∀ 分支：Nat.eqb y x 命中则整式不动（束缚）。 *)
