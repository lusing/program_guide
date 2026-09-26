(* 10 递归函数 —— Fixpoint、结构递归、终止性检查（实测拒绝） *)

From Stdlib Require Import List Arith.
Import ListNotations.

Module Ex10Fixpoint.

(* ---------- 基本形态：在更小的子项上递归 ---------- *)

Fixpoint sum_to (n : nat) : nat :=
  match n with
  | O => 0
  | S k => S k + sum_to k      (* k 是 S k 的直接子项 —— 合法 *)
  end.

Compute (sum_to 4).            (* = 10：4+3+2+1 *)

(* ---------- 多参数：Coq 猜你在哪个参数上递归 ---------- *)

Fixpoint power (base : nat) (exp : nat) : nat :=
  match exp with
  | O => 1
  | S e => base * power base e
  end.

Print power.
(* 打印里能看到 {struct exp} —— Coq 记录了「在 exp 上结构递归」 *)

Compute (power 2 10).          (* = 1024 *)

(* ---------- 终止性检查：不是「更小」就拒绝（实测） ---------- *)

(* 直觉说「k - 1 不是子项，应该被拒」——实测 8.20.1/9.1.0 均放行！
   守卫检查器会展开定义：k - 1 展开后每个分支都是（常量或）
   子项，于是接受。这个函数真的终止（还沾了截断减法的光：
   bad_sum 1 = bad_sum 0 + 1，因为 0 - 1 = 0）。 *)
Fixpoint bad_sum (n : nat) : nat :=
  match n with
  | O => 0
  | S k => bad_sum (k - 1) + 1
  end.

Compute (bad_sum 3).          (* = 2 —— 注意不是 3：k=0 时 k-1 截断为 0 *)

(* 但在「参数本身」上递归，无论怎么包都过不了： *)
Fail Fixpoint bad2 (n : nat) : nat :=
  match n with
  | O => 0
  | S k => bad2 (n - 1)
  end.
(* Recursive call to bad2 has principal argument equal to
   "n - 1" instead of "k". —— 报错把「该用谁」说得明明白白 *)

Fail Fixpoint bad_loop (n : nat) : nat :=
  match n with
  | O => 0
  | S k => bad_loop n          (* 原地踏步 —— 显然不终止 *)
  end.

(* 为什么这么严格？Coq 的函数要参与逻辑推理。
   若允许不终止的递归，就能「证明」假命题（逻辑一致性问题），
   所以每个 Fixpoint 必须通过「递减检查」（guard condition）。 *)

(* ---------- 累加器写法：换个形状，仍是结构递归 ---------- *)

Fixpoint rev_acc {A : Type} (acc : list A) (xs : list A) : list A :=
  match xs with
  | [] => acc
  | h :: tl => rev_acc (h :: acc) tl    (* 递归在 tl 上 —— 合法 *)
  end.

Definition fast_rev {A : Type} (xs : list A) : list A :=
  rev_acc [] xs.

Compute (fast_rev [1; 2; 3]).   (* = [3;2;1] *)

(* ---------- 互递归：with ---------- *)

Fixpoint myeven (n : nat) : bool :=
  match n with
  | O => true
  | S k => myodd k
  end
with myodd (n : nat) : bool :=
  match n with
  | O => false
  | S k => myeven k
  end.

Compute (myeven 10).           (* = true *)
Compute (myodd 7).             (* = true *)

(* ---------- Fixpoint 也是普通函数值 ---------- *)

Check (sum_to).                (* sum_to : nat -> nat *)
Definition sum_10 : nat := sum_to 10.
Compute (sum_10).              (* = 55 *)

End Ex10Fixpoint.
