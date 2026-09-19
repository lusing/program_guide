(* 12 归纳证明 —— induction、归纳假设 IH、四类常见目标 *)

From Coq Require Import Arith List.
Import ListNotations.

Module Ex12Induction.

Fixpoint double (n : nat) : nat :=
  match n with
  | O => O
  | S k => S (S (double k))
  end.

Fixpoint my_append {A : Type} (xs ys : list A) : list A :=
  match xs with
  | [] => ys
  | h :: tl => h :: my_append tl ys
  end.

(* ---------- 例 1：入门款 n + 0 = n ---------- *)

Theorem plus_n_O : forall n : nat, n + 0 = n.
Proof.
  intros n. induction n as [| n IH].
  - (* 基例：0 + 0 = 0 *) reflexivity.
  - (* 步例：S n + 0 = S n *)
    simpl.          (* 左边按定义展开：S (n + 0) = S n *)
    rewrite IH.     (* 用归纳假设替换 n + 0 *)
    reflexivity.
Qed.

(* ---------- 例 2：交换律（更真实的工作量） ---------- *)

Theorem plus_comm : forall n m : nat, n + m = m + n.
Proof.
  intros n m. induction n as [| n IH].
  - simpl. rewrite plus_n_O. reflexivity.
    (* 基例化简后是 m = m + 0。注意：这里的 plus_n_O 是本章
       自己证的那个（n + 0 = n 方向），rewrite 正向把 m + 0
       替换成 m。同名定理方向可能不同——rewrite 前 Check 一下 *)
  - simpl. rewrite IH. rewrite plus_n_Sm. reflexivity.
    (* 步例：S (n + m) = m + S n
       IH 把 n + m 换成 m + n；
       plus_n_Sm : S (n + m) = n + S m 把 S (m + n) 换成 m + S n *)
Qed.

(* ---------- 例 3：自定义函数的定律 double n = n + n ---------- *)

Theorem double_plus : forall n : nat, double n = n + n.
Proof.
  induction n as [| n IH].
  - reflexivity.
  - simpl. rewrite IH. rewrite <- plus_n_Sm. reflexivity.
Qed.

(* ---------- 例 4：列表上归纳（方法完全相同） ---------- *)

Theorem my_app_nil_r : forall (A : Type) (xs : list A),
  my_append xs [] = xs.
Proof.
  intros A xs. induction xs as [| x tl IH].
  - reflexivity.                    (* 空表拼空表 = 空表 *)
  - simpl. rewrite IH. reflexivity. (* 头保住，尾交给 IH *)
Qed.

(* ---------- 例 5：从证据归纳（归纳谓词第 15 章展开） ---------- *)

(* 对「命题的证明」本身做归纳是 Coq 的高级武器，第 15 章见。 *)

(* ---------- 心法 ---------- *)
(* 归纳证明的通用剧本，只有三步：
   1. induction x as [| 模式变量 IH] —— 目标按构造子分裂
   2. 基例通常 reflexivity 收掉
   3. 步例 simpl 展开，rewrite IH 替换，reflexivity 收尾
   卡住时 90% 是步例里还差一个「方向」或「形状」的引理——
   用 Search 找（第 2 章），别硬扛。 *)

End Ex12Induction.
