(* 22 数值专题 —— nat 的成本、N/Z 二进制、lia 自动算术 *)

From Coq Require Import ZArith Arith Lia.

Module Ex22Numbers.

(* ---------- nat 的成本模型：一元表示 ---------- *)

Compute (Nat.pow 2 16).       (* = 65536 —— 65536 个 S，还能愉快地算 *)
(* Compute (Nat.pow 2 100).   —— 千万别试：一元表示要 10^30 个构造子，
   实测直接内存耗尽（第 4 章的坑） *)

(* ---------- Z / N：二进制表示 ---------- *)

Print Z.
(* Inductive Z : Set :=
     Z0 : Z | Zpos : positive -> Z | Zneg : positive -> Z
   —— Z0 是零，Zpos/Zneg 是正负的二进制（positive）编码 *)

Compute (Z.pow 2 64).        (* = 18446744073709551616 —— 瞬间 *)
Compute (Z.pow 2 100).       (* = 1267650600228229401496703205376 *)

(* N：只有非负的版本，同样二进制 *)
Compute (N.pow 2 64).
Check N.
(* N : Set —— 与 Z 的关系类似 nat 与 Z 的关系：无符号版 *)

(* ---------- nat 与 Z/N 互通 ---------- *)

Compute (Z.of_nat 42).       (* = 42%Z *)
Compute (N.of_nat 42).       (* = 42%N *)
Compute (Z.to_nat (Z.pow 2 16)).   (* = 65536 —— 转回 nat 又变一元！ *)

(* ---------- 证明用 nat，计算用 Z：但 Z 上也能证 ---------- *)

(* lia：线性整数算术的自动证明器（nat/Z 通吃） *)
Theorem nat_lia : forall n m : nat, n <= m -> n + 0 <= m.
Proof.
  intros n m H.
  lia.        (* 不用归纳，lia 直接收 *)
Qed.

(* 注意 %Z：Z 上的 <= 和 - 需要作用域限定，
   裸写会被当成 nat 的运算（实测坑） *)
Theorem z_lia : forall a b : Z, (a <= b)%Z -> (a - b <= 0)%Z.
Proof.
  intros a b H.
  lia.
Qed.

(* lia 的能力边界：线性。带乘未知数的不行：
   Fail 的目标 forall n, n * n >= 0 在 nat 上 reflexivity 就行，
   但 Z 上 n*n>=0 需要非线性引理（Z.square_nonneg），lia 管不了。 *)

(* ---------- 选型速记 ---------- *)
(* nat：写证明的首选（归纳形状简单，全书示例都用它）
   Z  ：计算与有符号运算的首选
   N  ：无符号二进制（不需要负数时的 Z）
   桥  ：Z.of_nat / Z.to_nat / N.of_nat / N.to_nat
        （转换有成本：nat<->二进制是 O(n) 与 O(log n) 的形状变换）*)

End Ex22Numbers.
