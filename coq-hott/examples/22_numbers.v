(** 示例 22：自然数与整数
    集合层面的普通数学：算术、序、以及"它们都是集合"这件事。

    对应文档：docs/22-numbers.md *)

Require Import HoTT.
Local Open Scope path_scope.

Definition sec_22_BEGIN := tt.   Check sec_22_BEGIN.

(** * 22.1 [nat]：HoTT 自己的自然数 *)

Definition sec_22_1_nat := tt.   Check sec_22_1_nat.

Print nat.
Check O.
Check S.
Check nat_add.
Check nat_mul.
Check nat_sub.

(** 【坑】算术记号都在 [nat_scope] 里，而 [+]、[*] 在默认的
    [type_scope] 里分别表示和类型与积类型。必须写 [%nat]：*)
Compute (2 + 3)%nat.
Compute (2 * 3)%nat.
Compute (5 - 3)%nat.
Compute (3 - 5)%nat.   (* 截断减法：不够减就是 0 *)

(** 数字字面量默认也不是 nat（[0] 是截断层级，[1] 是 [idpath]），
    所以处处都要 [%nat]，这是本库最劝退的细节之一。 *)

(** * 22.2 算术定律 *)

Definition sec_22_2_arith := tt.   Check sec_22_2_arith.

Check nat_add_comm.
Check nat_add_assoc.
Check nat_mul_comm.
Check nat_mul_assoc.

(** 用它们重写时别忘了 scope：*)
Definition add_comm_demo (n m : nat) : (n + m)%nat = (m + n)%nat
  := nat_add_comm n m.
Check add_comm_demo.

(** * 22.3 序关系 *)

Definition sec_22_3_order := tt.   Check sec_22_3_order.

Check leq.
Check lt.
Check leq_refl.
Check leq_trans.

(** 【坑】[<=] 与 [<] 也在 [nat_scope] 里；而且它们是 [Type0] 中的命题，
    不是布尔值——所以"判定"要另说（[Decidable]）。 *)
Check (fun (n m : nat) => (n <= m)%nat).
Check Decidable.

(** * 22.4 [nat] 是集合 *)

Definition sec_22_4_hset := tt.   Check sec_22_4_hset.

Definition hset_nat : IsHSet nat := _.
Check hset_nat.

(** 因此在 [nat] 上，所有路径都是平凡的，证两条路径相等只需 [hset_path2]：*)
Definition two_nat_paths {n m : nat} (p q : n = m) : p = q := hset_path2 p q.
Check two_nat_paths.

(** 后继是单射（这不需要任何公理）：*)
Check path_nat_succ.

(** * 22.5 [Int]：两份 [nat] 背靠背 *)

Definition sec_22_5_int := tt.   Check sec_22_5_int.

Print Int.
Check negS.
Check zero.
Check posS.
Check int_of_nat.

(** [Int] 也有自己的数字记号（[int_scope]）：*)
Compute (2 + 3)%int.
Compute (-3)%int.
Compute (0 - 5)%int.

(** 后继与前驱互为逆：*)
Check int_succ.
Check int_pred.
Check int_succ_pred.
Check int_pred_succ.

(** 加法交换律：*)
Check int_add_comm.

(** * 22.6 [Int] 是集合，且有整环结构 *)

Definition sec_22_6_structure := tt.   Check sec_22_6_structure.

Definition hset_int : IsHSet Int := _.
Check hset_int.

Check int_add.
Check int_neg.
Check int_mul.

(** * 22.7 一个完整的例子：归纳证明 nat 上的性质 *)

Definition sec_22_7_induction := tt.   Check sec_22_7_induction.

(** [n + 0 = n] 需要归纳（[nat_add] 递归在第一个参数上，
    所以 [0 + n = n] 是定义性的，[n + 0 = n] 不是）。 *)
Definition add_zero_r (n : nat) : (n + 0)%nat = n.
Proof.
  induction n as [|n IH].
  - reflexivity.
  - cbn. exact (ap S IH).
Defined.
Check add_zero_r.

(** 而 [0 + n = n] 直接成立：*)
Definition add_zero_l (n : nat) : (0 + n)%nat = n := 1.
Check add_zero_l.

Definition sec_22_END := tt.   Check sec_22_END.
