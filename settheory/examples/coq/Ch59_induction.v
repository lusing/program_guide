(* 第 59 章：归纳与递归的机器化（Makinson Ch4）
   奇数和定理（简单归纳）、Fibonacci（累积递归）+ 调用计数证书、
   Ackermann（嵌套 fix 良基递归）。 *)
From Coq Require Import List Arith Lia.
Import ListNotations.

(* ---------- 简单递归与简单归纳 ---------- *)

Fixpoint sum_odd (n : nat) : nat :=
  match n with
  | 0 => 0
  | S k => sum_odd k + (2 * k + 1)
  end.

Theorem odd_sum : forall n, sum_odd n = n * n.
Proof.
  induction n as [|k IH]; simpl.
  - lia.
  - rewrite IH. lia.
Qed.

(* n! > 2^n 于 n ≥ 4（基在 4） *)
Fixpoint fact (n : nat) : nat :=
  match n with 0 => 1 | S k => (S k) * fact k end.

Theorem fact_gt_pow : forall n, 4 <= n -> fact n > 2 ^ n.
Proof.
  assert (H4 : fact 4 > 2 ^ 4) by (vm_compute; lia).
  induction n as [|k IH]; intros Hle.
  - lia.
  - destruct (Nat.eq_dec (S k) 4) as [hk | hk].
    + assert (hk' : k = 3) by lia.
      subst k. exact H4.
    + assert (Hk : 4 <= k) by lia.
      specialize (IH Hk).
      simpl in *.
      assert (Hmul : (k + 1) * fact k >= (k + 1) * 2 ^ k)
        by (apply Nat.mul_le_mono_l; lia).
      assert (Hk1 : k + 1 >= 5) by lia.
      nia.
Qed.

(* ---------- Fibonacci：累积递归 + 调用计数 ---------- *)

Fixpoint fib (n : nat) : nat :=
  match n with
  | 0 => 0
  | S n' => match n' with
            | 0 => 1
            | S n'' => fib n' + fib n''
            end
  end.

(* 朴素递归的加法次数：T(n) = T(n-1) + T(n-2) + 1 *)
Fixpoint fib_addcount (n : nat) : nat :=
  match n with
  | 0 => 0
  | S n' => match n' with
            | 0 => 0
            | S n'' => S (fib_addcount n' + fib_addcount n'')
            end
  end.

Example cert_fib10 : fib 10 = 55.
Proof. vm_compute. reflexivity. Qed.

(* 一元 nat 下的可判上限：fib 15 = 610（更大值由 Julia/Python 通道算） *)
Example cert_fib15 : fib 15 = 610.
Proof. vm_compute. reflexivity. Qed.

(* T(n) = Fib(n+1) - 1：朴素 F(15) 做 986 次加法 *)
Example cert_addcount : fib_addcount 15 = 986.
Proof. vm_compute. reflexivity. Qed.

Example cert_addcount_small : fib_addcount 8 = 33.
Proof. vm_compute. reflexivity. Qed.

(* 记忆化（线性）：线性复杂度的对照证书 *)
Fixpoint fib_pair (n : nat) : (nat * nat) :=
  match n with
  | 0 => (0, 0)
  | S n' => match n' with
            | 0 => (1, 0)
            | S _ =>
                let (a, b) := fib_pair n' in (a + b, a)
            end
  end.

Definition fib_memo (n : nat) : nat := fst (fib_pair n).

Example cert_memo : fib_memo 15 = 610.
Proof. vm_compute. reflexivity. Qed.

(* ---------- Ackermann：嵌套 fix（结构守卫通过） ---------- *)

Fixpoint ack (m n : nat) : nat :=
  match m with
  | 0 => S n
  | S m' =>
      let f := fix inner (k : nat) : nat :=
                  match k with
                  | 0 => ack m' 1
                  | S k' => ack m' (inner k')
                  end in
      f n
  end.

Example cert_ack_small : ack 2 3 = 9 /\ ack 3 3 = 61.
Proof. vm_compute. repeat split. Qed.

Example cert_ack_shape : ack 0 5 = 6 /\ ack 1 2 = 4 /\ ack 2 2 = 7.
Proof. vm_compute. repeat split. Qed.
