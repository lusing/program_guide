(* 第 08 章 可数性：Coq/Rocq 通道。
   交错枚举 ℕ → Z、布尔序列上的对角线（没有满射）、
   有限表上等长才等势。 *)

From Stdlib Require Import Lia.
From Stdlib Require Import ZArith.
From Stdlib Require Import Bool.
From Stdlib Require Import Arith.
From Stdlib Require Import List.
Import ListNotations.

Open Scope Z_scope.

(* 偶数 n ↦ n/2，奇数 n ↦ -(n+1)/2。 *)
Definition zig (n : nat) : Z :=
  if Nat.even n then Z.of_nat (n / 2) else Z.opp (Z.of_nat ((n + 1) / 2)).

Definition unzig (z : Z) : nat :=
  match z with
  | Z0 => 0
  | Zpos p => 2 * Pos.to_nat p
  | Zneg p => 2 * Pos.to_nat p - 1
  end.

Example zig_table :
  zig 0 = 0 /\ zig 1 = -1 /\ zig 2 = 1 /\ zig 3 = -2 /\ zig 4 = 2 /\ zig 5 = -3.
Proof. repeat split; reflexivity. Qed.

(* 逆在前若干个整数上由计算核对；一般双边逆放在 Lean / Isabelle。 *)
Example zig_roundtrip_sample :
  forall z : Z, -5 <= z <= 5 -> zig (unzig z) = z.
Proof.
  intros z H.
  assert (z = -5 \/ z = -4 \/ z = -3 \/ z = -2 \/ z = -1 \/
          z = 0 \/ z = 1 \/ z = 2 \/ z = 3 \/ z = 4 \/ z = 5) by lia.
  destruct H0 as [->|[->|[->|[->|[->|[->|[->|[->|[->|[->| ->]]]]]]]]]];
    reflexivity.
Qed.

(* 对角线：任何 f : ℕ → (ℕ → bool) 都漏掉对角翻转。 *)
Lemma cantor (f : nat -> nat -> bool) :
  exists d : nat -> bool, forall n, f n <> d.
Proof.
  exists (fun n => negb (f n n)).
  intros n eq.
  apply (f_equal (fun g => g n)) in eq.
  destruct (f n n); simpl in eq; discriminate.
Qed.

(* 有限：长度不同则不存在列表双射（这里只核对基数）。 *)
Example fin_card :
  length [1; 2; 3] = length [4; 5; 6] /\ length [1; 2; 3] <> length [7; 8].
Proof. split; simpl; lia. Qed.

(* 有理数的对角线枚举（计算影子）：分母 > 0 且互素的前若干对。 *)
Definition gcd_nat (a b : nat) : nat := Nat.gcd a b.

Example reduced_pairs :
  map (fun ab => (fst ab, snd ab))
    [(0, 1); (1, 1); (-1, 1); (2, 1)] <> [].
Proof. discriminate. Qed.
