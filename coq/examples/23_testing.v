(* 23 测试与断言风格 —— Example 即测试、负向断言、公理审查 *)

From Coq Require Import Arith List Bool.
Import ListNotations.

Module Ex23Testing.

(* ---------- 被测对象 ---------- *)

Definition inc (n : nat) : nat := S n.

Fixpoint all_even (l : list nat) : bool :=
  match l with
  | [] => true
  | n :: tl => andb (Nat.eqb (n mod 2) 0) (all_even tl)
  end.

(* ---------- 风格 1：Example + reflexivity = 单元测试 ---------- *)

Example test_inc_1 : inc 0 = 1.
Proof. reflexivity. Qed.

Example test_inc_41 : inc 41 = 42.
Proof. reflexivity. Qed.

Example test_all_even_1 : all_even [2; 4; 6] = true.
Proof. reflexivity. Qed.

Example test_all_even_2 : all_even [2; 3] = false.
Proof. reflexivity. Qed.

(* 每条 Example 都是回归测试：改坏 inc，全文件当场编译失败。
   Coq 的测试不用框架 —— 证明即测试。 *)

(* ---------- 风格 2：负向断言 ---------- *)

(* 「不等于」也是可测的：discriminate 处理具体值的否定 *)
Example test_inc_neg : inc 0 <> 2.
Proof. discriminate. Qed.

(* 风格 3：Fail 记录「应当不合法」的用法（第 3 章的老朋友） *)
Fail Check (inc true).      (* 类型误用，如期失败 *)

(* ---------- 风格 4：从测试升级为定理 ---------- *)

(* 测 3 个输入不如证全部输入。
   工作方式：先写一堆具体 Example（上面的）找到感觉，
   再把「想要的性质」一般化成 forall 命题。 *)

Theorem all_even_app : forall l1 l2 : list nat,
  all_even l1 = true -> all_even l2 = true
  -> all_even (l1 ++ l2) = true.
Proof.
  intros l1. induction l1 as [| x tl IH]; intros l2 H1 H2.
  - exact H2.
  - simpl in H1.
    apply andb_true_iff in H1.     (* && = true 拆成两个 = true *)
    destruct H1 as [Ex Et].
    simpl. rewrite Ex. simpl.
    apply IH; assumption.
Qed.

(* 这条定理覆盖了无穷多个测试用例——
   测试与证明的分界就在 forall：具体值是测试，
   量化命题是证明，而 Example 是通往 Theorem 的脚手架。 *)

End Ex23Testing.
