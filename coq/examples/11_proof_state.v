(* 11 证明状态与 tactic 机理 —— 目标、上下文、策略如何一步步吃掉目标
   本文件的注释里画出了每一步的证明状态。在 CoqIDE / coqtop 里
   逐句执行，亲眼对照这些「快照」是理解 Coq 的最快路径。 *)

From Stdlib Require Import Arith.

Module Ex11ProofState.

(* ---------- 一个完整证明的状态演变 ---------- *)

Theorem plus_n_O : forall n : nat, n + 0 = n.
Proof.
  (* 进入证明模式时的状态：
     ============================
     forall n : nat, n + 0 = n *)

  intros n.
  (* 把 forall 的变量收进上下文：
     n : nat
     ============================
     n + 0 = n *)

  induction n as [| n IH].
  (* 在 n 上归纳，目标裂成两个（基例 + 步例）：

     目标 1（基例，n := 0）：
     ============================
     0 + 0 = 0

     目标 2（步例，as 模式给步例绑定 n 和 IH）：
     n : nat
     IH : n + 0 = n          <- 归纳假设：要证 S n，先白送你 n
     ============================
     S n + 0 = S n *)

  - reflexivity.
  (* 子弹 - 处理第一个目标；0 + 0 化简得 0 = 0，自反性关闭。
     剩下目标 2。 *)

  - simpl.
  (* 把 S n + 0 按 Nat.add 定义展开一步：
     n : nat
     IH : n + 0 = n
     ============================
     S (n + 0) = S n *)

  rewrite IH.
  (* 用 IH 把目标里的 n + 0 替换成 n：
     ============================
     S n = S n *)

  reflexivity.
  (* 两边相同，关闭最后一个目标；证明完成。 *)

Qed.
(* Qed 之前，策略脚本被编译成证明项，交内核复查。 *)

(* ---------- 子弹的层级 ---------- *)
(* 上面只用到一层 -。目标嵌套深时按层级用：
   第一层 - ，第二层 + ，第三层 * ，再深就要重新组织证明了。
   子弹的意义：每个目标必须被「点名处理」，漏一个 Qed 就报错
   （Attempt to save an incomplete proof）——这是证明完整性的
   第一道保险。第 14 章的逻辑证明里会大量出现三层结构。 *)

(* ---------- apply 与 exact：调用已有定理 ---------- *)

Check Nat.add_0_r.
(* Nat.add_0_r : forall n : nat, n + 0 = n
   —— 我们手证的 plus_n_O，标准库本来就有（名字不同） *)

Example apply_demo : forall n : nat, n + 0 = n.
Proof.
  intros n.
  apply Nat.add_0_r.
  (* 目标正是定理的结论，apply 自动对齐参数，一步关闭 *)
Qed.

Example exact_demo : forall n : nat, n + 0 = n.
Proof.
  intros n.
  exact (Nat.add_0_r n).
  (* exact 更直接：把证明项原样交出，类型必须与目标一字不差 *)
Qed.

(* apply 与 exact 的分工：apply 做「目标 vs 结论」的匹配推理，
   能自动补参数；exact 不做推理，是什么就是什么。日常 apply 多、
   exact 用于「我知道答案就是它」的收尾。 *)

End Ex11ProofState.
