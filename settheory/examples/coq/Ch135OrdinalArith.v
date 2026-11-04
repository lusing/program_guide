(* 第 135 章 Coq：ω^ω 窗口内的序数加法（书 4.4.1-4.4.2）。

   表示：CNF 系数表（低位在前）：α = c0 + c1·ω + ... + ck·ω^k。
   加法的闭式（由超穷递归定理 4.4.1 展开而来）：
   设 β 的最高非零项在指数 k，则
     α + β = Σ_{e<k} β_e·ω^e + (α_k + β_k)·ω^k + Σ_{e>k} α_e·ω^e
   ——β 之下全按 β，之上全按 α，交叉处相加。右吸收律是它的推论。 *)

Require Import List Arith Lia.
Import ListNotations.

Definition omegaC : list nat := [0; 1].
Definition oneC : list nat := [1].

(* nth 取项（缺省 0）；firstn/skipn 切段 *)
Definition oadd (a b : list nat) : list nat :=
  match b with
  | [] => a                                   (* β = 0：α + 0 = α *)
  | _ =>
    let k := length b - 1 in
    firstn k b ++ [nth k a 0 + nth k b 0] ++ skipn (S k) a
  end.

(* ---------- 定理 1：有限 + ω = ω（右吸收，书例 4.4.2(3)(4)） ---------- *)

Theorem nat_plus_omega : forall n : nat, oadd [n] omegaC = omegaC.
Proof. reflexivity. Qed.

(* 更一般：有限 + (m + ω) = m + ω —— 左边的有限项与 β 的低项
   一起被吸收，只留 β 的原样 *)
Theorem nat_plus_limit : forall n m : nat, oadd [n] [m; 1] = [m; 1].
Proof. intros; reflexivity. Qed.

(* ---------- 定理 2：ω + m 保留（不吸收——方向不对称！） ---------- *)

Theorem omega_plus_nat : forall m : nat, oadd omegaC [m] = [m; 1].
Proof. intros; reflexivity. Qed.

(* ---------- 样本计算（书例 4.4.2 全录） ---------- *)

Example e1 : oadd [2] [1] = [3].                (* 2+1 = 3 *)
Proof. reflexivity. Qed.

Example e2 : oadd [0; 1] [0; 1] = [0; 2].       (* ω+ω = ω·2 *)
Proof. reflexivity. Qed.

Example e3 : oadd [3; 1] [0; 1] = [0; 2].       (* (3+ω)+ω：低项 3 被吸收 *)
Proof. reflexivity. Qed.

Example e4 : oadd [0; 2] [1; 1] = [1; 3].       (* ω·2 + (1+ω) = 1+ω·3 *)
Proof. reflexivity. Qed.

Example e5 : oadd [1] [0; 1] = oadd [2] [0; 1]. (* 1+ω = 2+ω *)
Proof. reflexivity. Qed.

Example e6 : oadd [0; 2] [3] = [3; 2].          (* ω·2 + 3 *)
Proof. reflexivity. Qed.

(* ---------- 结构性定理：α + 0 = α（加法第一条款） ---------- *)

Theorem oadd_zero_r : forall a, oadd a [] = a.
Proof. intros a. reflexivity. Qed.
