(* 第 78 章：奇异基数假设——银杰与嘎尔文-海纳（冯琦 §2.4）——Coq 通道 *)
(* 引理 2.15 第一步的编码 X↦f_X，其单射性内核是「截断码随位数单调精化、
   顶位码决定一切」。这里用 nat 的低 m 位（= X mod 2^m，即位掩码
   Nat.land X (2^m − 1)）把它完整机器化。 *)
From Coq Require Import Bool List Arith Lia.
Import ListNotations.
Set Warnings "-deprecated-since-8.17,-deprecated".

Module Ch78.

(* 截断码：trunc X m = X 的低 m 位 = X mod 2^m。对应 f_X(α) 只依赖
   X∩ℵ_{g(α)} 的局部性。 *)
Definition trunc (X m : nat) : nat := X mod Nat.pow 2 m.

(* 辅助：b | b*c，故对 b*c 取模后再对 b 取模 = 直接对 b 取模。
   内核是 mod_mul_r：a mod (b*c) = a mod b + b*((a/b) mod c)，右侧再对 b
   取模时 b*(…) 项消失。 *)
Lemma mod_mod_mul : forall a b c, b <> 0 -> c <> 0 -> (a mod (b * c)) mod b = a mod b.
Proof.
  intros a b c Hb Hc. symmetry.
  apply Nat.mod_unique with (q := (a / b) mod c).
  - apply Nat.mod_upper_bound; exact Hb.
  - rewrite Nat.add_comm. apply Nat.mod_mul_r; assumption.
Qed.

(* 单调精化：先截到 n 位、再截到 m 位（m≤n）等于直接截到 m 位。
   对应「f_X(α) 的低位码只依赖低位」——正是它使相等集被第一个分歧点封顶。 *)
Lemma trunc_local : forall X m n,
  m <= n -> trunc (trunc X n) m = trunc X m.
Proof.
  intros X m n Hmn. unfold trunc.
  assert (Hpow : Nat.pow 2 n = Nat.pow 2 m * Nat.pow 2 (n - m)).
  { rewrite <- Nat.pow_add_r. replace (m + (n - m)) with n by lia. reflexivity. }
  rewrite Hpow. apply mod_mod_mul; apply Nat.pow_nonzero; lia.
Qed.

(* 顶位码决定一切：X、Y 都 < 2^n 时，n 位截断码相等 ⟹ X=Y。
   对应「存在 α 使 f_X(α)≠f_Y(α) 则 X≠Y」的 contrapositive。 *)
Lemma trunc_inj_top : forall n X Y,
  X < Nat.pow 2 n -> Y < Nat.pow 2 n -> trunc X n = trunc Y n -> X = Y.
Proof.
  intros n X Y HX HY H. unfold trunc in H.
  rewrite Nat.mod_small in H by exact HX.
  rewrite Nat.mod_small in H by exact HY.
  exact H.
Qed.

(* 具体计算例：低 3 位截断把 0..9、255 映到 mod 8 的余数。 *)
Example trunc_demo :
  map (fun X => trunc X 3) [0;1;7;8;9;255] = [0;1;7;0;1;7].
Proof. reflexivity. Qed.

(* 单射性在 n=3、X,Y<8 上的核对：直接调用 trunc_inj_top（2^3 计算为 8）。 *)
Example trunc_inj_demo :
  forall X Y, X < 8 -> Y < 8 -> trunc X 3 = trunc Y 3 -> X = Y.
Proof.
  intros X Y HX HY H.
  change 8 with (Nat.pow 2 3) in HX, HY.
  exact (trunc_inj_top 3 X Y HX HY H).
Qed.

End Ch78.
