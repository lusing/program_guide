(* ============================================================ *)
(* 10 MLTT 的判断形式与一般规则 —— Coq 侧                        *)
(* 四种判断 + 前提/对称/传递/替换，与 Lean 版同构                *)
(* ============================================================ *)

Require Import Arith Lia.

(* ---- 判断 a : A ---- *)
Check (1 : nat).
Check (fun n => n + 1).

(* ---- 判断 A type（类型的资格） ---- *)
Definition NatFun : Type := nat -> nat.
Check NatFun.

(* ---- 判断 a ≡ b : A：定义相等（reflexivity 的地盘） ---- *)
Example defEq1 : (fun n => n + 1) 3 = 4 := eq_refl.
Example defEq2 : (2 + 2 : nat) = 4 := eq_refl.

(* ---- 判断 A ≡ B ---- *)
Example tyEq : NatFun = (nat -> nat) := eq_refl.

(* ---- 一般规则（Nordström 5.3） ---- *)

(* 前提 *)
Theorem hyp_rule : forall (P : nat -> Prop) n, P n -> P n.
Proof. intros P n H. exact H. Qed.

(* 对称 *)
Theorem sym_rule : forall a b : nat, a = b -> b = a.
Proof. intros a b H. apply eq_sym. exact H. Qed.

(* 传递 *)
Theorem trans_rule : forall a b c : nat, a = b -> b = c -> a = c.
Proof. intros a b c H1 H2. apply eq_trans with (y := b); assumption. Qed.

(* 替换：a = b ⟹ P a ⟹ P b *)
Theorem subst_rule : forall a b : nat, a = b ->
  forall P : nat -> Prop, P a -> P b.
Proof. intros a b H P Ha. apply (eq_ind a P Ha b H). Qed.

(* 同余（替换的特例） *)
Theorem cong_rule : forall (f : nat -> nat) a b, a = b -> f a = f b.
Proof. intros f a b H. rewrite H. reflexivity. Qed.

(* ---- eq_ind 就是 J：打印出来看 ---- *)
Print eq_ind.
(* forall A x (P : A -> Prop), P x -> forall y, x = y -> P y
   —— 12 章手工把它从归纳定义里推出来 *)

(* ---- 上下文里的判断 ---- *)
Section Ctx.
  Variables (alpha : Type) (a b : alpha).
  Hypothesis h : a = b.
  Theorem in_ctx : b = a.
  Proof. apply eq_sym. exact h. Qed.
End Ctx.

(* ---- 定义相等 ≠ 命题相等：n + 0 与 n ---- *)
(* Coq 的 + 递归在第一参数：0 + n 折叠，n + 0 要证明 *)
Example defeq_dir1 : forall n, 0 + n = n := fun n => eq_refl.
Theorem not_defeq : forall n, n + 0 = n.
Proof. induction n as [| n IH]; simpl; [reflexivity | rewrite IH; reflexivity]. Qed.
