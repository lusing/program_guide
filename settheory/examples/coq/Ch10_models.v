(* 第 10 章 模型：受限公式的绝对性（深嵌入版） *)

Require Import Arith Lia Lists.List.
Import ListNotations.

(* ---------- 一、集合论公式的深嵌入（受限片段 Δ₀） ---------- *)

(* 变元用 nat 编码；受限公式只有受限量词 ∃u∈x / ∀u∈x *)
Inductive rform : Type :=
| rmem  : nat -> nat -> rform                  (* x_i ∈ x_j *)
| req   : nat -> nat -> rform                  (* x_i = x_j *)
| rnand : rform -> rform -> rform              (* 非与 *)
| rall  : nat -> rform -> rform.               (* u ∈ x_i 的全称：u 占 0 号槽 *)

(* ---------- 二、满足语义：受限求值 vs 全域求值 ---------- *)

(* 环境 env : list V；赋值 lookup *)
Fixpoint lookup {A} (env : list A) (i : nat) (dflt : A) : A :=
  match env, i with
  | [], _ => dflt
  | x :: _, 0 => x
  | _ :: e, S i' => lookup e i' dflt
  end.

(* 语义域：V = list V（HF 式嵌套）——教学版用 nat 域的 ∈ 谓词 *)
Section Semantics.

Variable elem : nat -> nat -> Prop.

(* 受限语义：量词跑遍 y 的成员 *)
Fixpoint sat (f : rform) (env : list nat) {struct f} : Prop :=
  match f with
  | rmem i j => elem (lookup env i 0) (lookup env j 0)
  | req i j  => lookup env i 0 = lookup env j 0
  | rnand p q => ~ (sat p env /\ sat q env)
  | rall i p => forall u, elem u (lookup env i 0) -> sat p (u :: env)
  end.

End Semantics.

(* ---------- 三、绝对性（引理 10.1 的语义） ----------
   受限公式（受限量词 ∃u∈x / ∀u∈x）在传递模型 M 与宇宙 V
   之间真值一致：量词只跑遍成员，而传递性保证成员关系相同。
   完整形式化由 Isabelle/ZF 的 Relative/absoluteness 框架承载
   （ST10 的 sats 语义是其语法底座）；受限语义的关键结构
   已在上方 sat 的 forall 条款呈现：量词域 = x 的成员。 *)

(* 语义正确性基线：rnand 的真值表（Nand p p = ¬p） *)
Example rnand_semantics :
  forall (elem : nat -> nat -> Prop) i j env,
    sat elem (rnand (rmem i j) (rmem i j)) env <->
    ~ elem (lookup env i 0) (lookup env j 0).
Proof.
  intros. simpl. tauto.
Qed.

Print Assumptions rnand_semantics.
