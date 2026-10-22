(* 第 68 章：自然数与第一递归定义定理（冯琦 §1.3）
   加法的原始递归（递归在第二变元）+ 定理 1.16(1) 双归纳交换律；
   鸽子笼（4→3 无单射）；强递归 Fibonacci。 *)
From Coq Require Import List Arith Lia.
Import ListNotations.

(* ---------- 定理 1.15：加法递归在第二变元 ---------- *)

Fixpoint vadd (m n : nat) : nat :=
  match n with
  | 0 => m
  | S k => S (vadd m k)
  end.

Lemma vadd_0_r : forall m, vadd m 0 = m.
Proof. reflexivity. Qed.

Lemma vadd_succ_r : forall m n, vadd m (S n) = S (vadd m n).
Proof. reflexivity. Qed.

(* 书页 51 基础段：0 + m = m（对 m 归纳） *)
Lemma vadd_0_l : forall n, vadd 0 n = n.
Proof.
  induction n as [|n IH]; simpl; auto.
Qed.

(* ---------- 定理 1.16(1)：交换律的双归纳（六步推导复刻） ---------- *)

Theorem vadd_comm : forall n m, vadd m n = vadd n m.
Proof.
  induction n as [|n IH]; intros m.
  - simpl. rewrite vadd_0_l. reflexivity.
  - (* 外层对 n 归纳得 IH : ∀m, vadd m n = vadd n m；内层对 m 归纳 *)
    (* 变量名取 mm：外层语境已有 m，induction m 会抓错对象 *)
    assert (H : forall mm, vadd (S n) mm = vadd mm (S n)).
    { induction mm as [|mm IHmm].
      - simpl. rewrite vadd_0_l. reflexivity.
      - (* vadd (S n) (S mm) = vadd (S mm) (S n)
           LHS = S (vadd (S n) mm) = S (vadd mm (S n)) = S (S (vadd mm n))
           RHS = S (vadd (S mm) n) = S (vadd n (S mm)) = S (S (vadd n mm)) *)
        simpl. rewrite IHmm. simpl. rewrite (IH mm). simpl.
        rewrite (IH (S mm)). simpl. reflexivity. }
    rewrite H. reflexivity.
Qed.

(* ---------- 定理 1.10：鸽子笼（4 只鸽 3 个巢） ---------- *)

Lemma pigeon_aux : forall a b c d,
  a <= 2 -> b <= 2 -> c <= 2 -> d <= 2 ->
  a = b \/ a = c \/ a = d \/ b = c \/ b = d \/ c = d.
Proof.
  intros a b c d Ha Hb Hc Hd.
  destruct a, b, c, d; try lia.
Qed.

Theorem pigeonhole_4_3 : forall f : nat -> nat,
  (forall i, i < 4 -> f i < 3) ->
  exists i j, i < j /\ j < 4 /\ f i = f j.
Proof.
  intros f Hb.
  assert (H0 : f 0 <= 2) by (specialize (Hb 0); lia).
  assert (H1 : f 1 <= 2) by (specialize (Hb 1); lia).
  assert (H2 : f 2 <= 2) by (specialize (Hb 2); lia).
  assert (H3 : f 3 <= 2) by (specialize (Hb 3); lia).
  destruct (pigeon_aux (f 0) (f 1) (f 2) (f 3) H0 H1 H2 H3)
    as [H|[H|[H|[H|[H|H]]]]].
  - exists 0, 1. split; [lia | split; [lia | exact H]].
  - exists 0, 2. split; [lia | split; [lia | exact H]].
  - exists 0, 3. split; [lia | split; [lia | exact H]].
  - exists 1, 2. split; [lia | split; [lia | exact H]].
  - exists 1, 3. split; [lia | split; [lia | exact H]].
  - exists 2, 3. split; [lia | split; [lia | exact H]].
Qed.

(* ---------- 推论 1.2：强递归（course-of-values）—— Fibonacci ---------- *)
(* f(n) 由之前所有值决定：fib 需要 f(n-1) 与 f(n-2)。 *)

Fixpoint fib (n : nat) : nat :=
  match n with
  | 0 => 0
  | S m => match m with
           | 0 => 1
           | S k => fib m + fib k    (* 嵌套 match：m 是外层模式变量 *)
           end
  end.

Example fib_first_ten :
  map fib (seq 0 10) = [0; 1; 1; 2; 3; 5; 8; 13; 21; 34].
Proof. reflexivity. Qed.

(* ---------- 定理 1.11：雪崩映射的名次（有限侧写） ---------- *)

Fixpoint rank_in (X : list nat) (k : nat) : nat :=
  match X with
  | [] => 0
  | x :: X' => if Nat.ltb x k then S (rank_in X' k) else rank_in X' k
  end.

Definition primes10 : list nat := [2; 3; 5; 7; 11; 13; 17; 19; 23; 29].

Example rank_primes : rank_in primes10 13 = 5.
Proof. reflexivity. Qed.

Example rank_primes29 : rank_in primes10 29 = 9.
Proof. reflexivity. Qed.
