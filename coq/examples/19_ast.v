(* 19 表达式求值器：AST 入门 —— 定义语言、写解释器、证优化器正确 *)

From Coq Require Import List Arith String.

Module Ex19Ast.

(* ---------- 一门小小的算术语言 ---------- *)

Inductive aexp : Type :=
  | AConst (n : nat)          (* 字面量 *)
  | AVar (x : string)         (* 变量 *)
  | APlus (a1 a2 : aexp)      (* a1 + a2 *)
  | AMinus (a1 a2 : aexp)     (* a1 - a2 *)
  | AMult (a1 a2 : aexp).     (* a1 * a2 *)

(* 这就是「用归纳类型定义语法树」：每个构造子是一种语法形态，
   表达式 2 + (x * 3) 就是：
   APlus (AConst 2) (AMult (AVar "x") (AConst 3)) *)

(* ---------- 状态：变量到值的映射 ---------- *)

Definition state := string -> nat.

(* ---------- 求值器 ---------- *)

Fixpoint aeval (a : aexp) (st : state) : nat :=
  match a with
  | AConst n => n
  | AVar x => st x
  | APlus a1 a2 => aeval a1 st + aeval a2 st
  | AMinus a1 a2 => aeval a1 st - aeval a2 st
  | AMult a1 a2 => aeval a1 st * aeval a2 st
  end.

(* 一个具体状态：x 映到 5，其他变量是 0 *)
Definition st1 : state := fun x =>
  if String.eqb x "x" then 5 else 0.

Example eval_ex1 : aeval (APlus (AVar "x") (AConst 1)) st1 = 6.
Proof. reflexivity. Qed.

Example eval_ex2 :
  aeval (AMinus (AMult (AVar "x") (AConst 3)) (AConst 2)) st1 = 13.
Proof. reflexivity. Qed.

(* ---------- 优化器：把 0 + e 化简成 e ---------- *)

(* 单独把「加法的情况判断」做成 smart constructor，
    主函数和主定理都会干净得多（正文详述为什么） *)
Definition optimize_plus (e1 e2 : aexp) : aexp :=
  match e1 with
  | AConst 0 => e2
  | _ => APlus e1 e2
  end.

Fixpoint optimize (a : aexp) : aexp :=
  match a with
  | AConst n => AConst n
  | AVar x => AVar x
  | APlus e1 e2 => optimize_plus (optimize e1) (optimize e2)
  | AMinus e1 e2 => AMinus (optimize e1) (optimize e2)
  | AMult e1 e2 => AMult (optimize e1) (optimize e2)
  end.

Compute (optimize (APlus (AConst 0) (AVar "y"))).
(* = AVar "y" —— 0 + y 被吃掉 *)

Compute (optimize (APlus (APlus (AConst 0) (AVar "x")) (AConst 0))).
(* = APlus (AVar "x") (AConst 0)
   —— 递归生效（里层的 0 + x 被吃），
      但 x + 0 保留（优化器只认 0 在左边的模式，
      e + 0 的折叠留给第 24 章当练习） *)

(* ---------- 正确性定理 ---------- *)

(* 第一步：smart constructor 自己的正确性 —— 对任意 u v 都成立 *)
Lemma optimize_plus_correct : forall (u v : aexp) (st : state),
  aeval (optimize_plus u v) st = aeval u st + aeval v st.
Proof.
  intros u v st.
  unfold optimize_plus.
  destruct u; simpl; try reflexivity.
  destruct n; reflexivity.
Qed.

(* 第二步：主定理——对 a 归纳，APlus 分支引用小引理 *)
Theorem optimize_correct : forall (a : aexp) (st : state),
  aeval (optimize a) st = aeval a st.
Proof.
  intros a st. induction a; simpl.
  - reflexivity.
  - reflexivity.
  - rewrite optimize_plus_correct. rewrite IHa1, IHa2. reflexivity.
  - rewrite IHa1, IHa2. reflexivity.
  - rewrite IHa1, IHa2. reflexivity.
Qed.

(* 「优化器不改变程序含义」——一行定理，机器背书。
   这就是「验证编译器/优化 pass」的最小完整样本：
   CompCert 做的事情在结构上与这 40 行无异。 *)

End Ex19Ast.
