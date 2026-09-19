(* 24 综合实战 —— 表达式解释器、常量折叠优化器、
   优化器正确性（两个 pass 的组合证明）、抽取到 OCaml *)

From Coq Require Import List Arith String ZArith Extraction.

Module Ex24Project.

(* ---------- 一、语言：带变量的算术表达式（第 19 章加强版） ---------- *)

Inductive aexp : Type :=
  | AConst (n : nat)
  | AVar (x : string)
  | APlus (a1 a2 : aexp)
  | AMinus (a1 a2 : aexp)
  | AMult (a1 a2 : aexp).

Definition state := string -> nat.

Fixpoint aeval (a : aexp) (st : state) : nat :=
  match a with
  | AConst n => n
  | AVar x => st x
  | APlus a1 a2 => aeval a1 st + aeval a2 st
  | AMinus a1 a2 => aeval a1 st - aeval a2 st
  | AMult a1 a2 => aeval a1 st * aeval a2 st
  end.

Definition st1 : state := fun x =>
  if String.eqb x "x" then 10 else 0.

Example run1 : aeval (APlus (AVar "x") (AMult (AConst 2) (AConst 3))) st1 = 16.
Proof. reflexivity. Qed.

(* ---------- 二、优化 pass 1：吃掉 0 + e（第 19 章原样） ---------- *)

Definition optimize0_plus (e1 e2 : aexp) : aexp :=
  match e1 with
  | AConst 0 => e2
  | _ => APlus e1 e2
  end.

Fixpoint optimize0 (a : aexp) : aexp :=
  match a with
  | AConst n => AConst n
  | AVar x => AVar x
  | APlus e1 e2 => optimize0_plus (optimize0 e1) (optimize0 e2)
  | AMinus e1 e2 => AMinus (optimize0 e1) (optimize0 e2)
  | AMult e1 e2 => AMult (optimize0 e1) (optimize0 e2)
  end.

(* ---------- 三、优化 pass 2：常量折叠 ---------- *)

Fixpoint const_fold (a : aexp) : aexp :=
  match a with
  | APlus e1 e2 =>
      match const_fold e1, const_fold e2 with
      | AConst n1, AConst n2 => AConst (n1 + n2)
      | e1', e2' => APlus e1' e2'
      end
  | AMinus e1 e2 =>
      match const_fold e1, const_fold e2 with
      | AConst n1, AConst n2 => AConst (n1 - n2)
      | e1', e2' => AMinus e1' e2'
      end
  | AMult e1 e2 =>
      match const_fold e1, const_fold e2 with
      | AConst n1, AConst n2 => AConst (n1 * n2)
      | e1', e2' => AMult e1' e2'
      end
  | AConst n => AConst n
  | AVar x => AVar x
  end.

Compute (const_fold (APlus (AConst 2) (AMult (AConst 3) (AConst 4)))).
(* = AConst 14 —— 整棵子树被折成一个数 *)

(* ---------- 四、两个 pass 的正确性 ---------- *)

Lemma optimize0_plus_correct : forall (u v : aexp) (st : state),
  aeval (optimize0_plus u v) st = aeval u st + aeval v st.
Proof.
  intros u v st. unfold optimize0_plus.
  destruct u; simpl; try reflexivity.
  destruct n; reflexivity.
Qed.

Theorem optimize0_correct : forall (a : aexp) (st : state),
  aeval (optimize0 a) st = aeval a st.
Proof.
  intros a st. induction a; simpl.
  - reflexivity.
  - reflexivity.
  - rewrite optimize0_plus_correct. rewrite IHa1, IHa2. reflexivity.
  - rewrite IHa1, IHa2. reflexivity.
  - rewrite IHa1, IHa2. reflexivity.
Qed.

(* 常量折叠的正确性：双 scrutinee 的 match 用
   rewrite <- IH 把两边对齐后，destruct 两下全收 *)
Theorem const_fold_correct : forall (a : aexp) (st : state),
  aeval (const_fold a) st = aeval a st.
Proof.
  intros a st. induction a; simpl.
  - reflexivity.
  - reflexivity.
  - rewrite <- IHa1. rewrite <- IHa2.
    destruct (const_fold a1) eqn:E1; destruct (const_fold a2) eqn:E2;
      reflexivity.
  - rewrite <- IHa1. rewrite <- IHa2.
    destruct (const_fold a1) eqn:E1; destruct (const_fold a2) eqn:E2;
      reflexivity.
  - rewrite <- IHa1. rewrite <- IHa2.
    destruct (const_fold a1) eqn:E1; destruct (const_fold a2) eqn:E2;
      reflexivity.
Qed.

(* ---------- 五、组合成流水线，正确性免费合成 ---------- *)

Definition pipeline (a : aexp) : aexp := const_fold (optimize0 a).

Theorem pipeline_correct : forall (a : aexp) (st : state),
  aeval (pipeline a) st = aeval a st.
Proof.
  intros a st.
  unfold pipeline.
  rewrite const_fold_correct.
  rewrite optimize0_correct.
  reflexivity.
Qed.
(* 组合的正确性 = 两个 pass 正确性的接力，两行 rewrite。
   「验证过的变换按任何顺序组合仍然正确」——
   这正是 CompCert 类项目的组织方式。 *)

Example pipeline_demo :
  pipeline (APlus (AConst 0) (AMult (AConst 3) (AConst 4))) = AConst 12.
Proof. reflexivity. Qed.
(* 0 被吃掉、常量被折掉，一次到位，且 pipeline_correct 担保语义不变 *)

(* ---------- 六、抽取：把验证过的代码变成 OCaml ---------- *)

Recursive Extraction pipeline.
(* 输出的 OCaml 代码可以在 OCaml 工程里直接编译使用——
   证明留在 Coq 世界，计算落到真实世界。
   注意（实测坑）：必须先 From Coq Require Import Extraction，
   裸写 Recursive Extraction 报 illegal begin of vernac *)

End Ex24Project.
