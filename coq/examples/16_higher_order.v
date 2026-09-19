(* 16 高阶函数及其证明 —— 函数是值：组合、应用、定律 *)

From Coq Require Import List Arith.
Import ListNotations.

Module Ex16HigherOrder.

(* ---------- 函数是值 ---------- *)

Definition inc (n : nat) : nat := S n.

Definition apply_twice {A : Type} (f : A -> A) (x : A) : A :=
  f (f x).

Compute (apply_twice inc 5).              (* = 7 *)
Compute (apply_twice (fun n => n * 2) 5).  (* = 20 —— 匿名函数同样可传 *)

(* ---------- 组合 ---------- *)

Definition compose {A B C : Type} (f : B -> C) (g : A -> B) : A -> C :=
  fun x => f (g x).

Compute (compose inc inc 5).   (* = 7 *)
Check (compose S (fun n => n * 2)).  (* : nat -> nat —— 组合本身是个值 *)

(* ---------- 定律与证明 ---------- *)

Theorem map_compose : forall (A B C : Type)
                                 (f : B -> C) (g : A -> B) (xs : list A),
  map (compose f g) xs = map f (map g xs).
Proof.
  intros A B C f g xs. induction xs as [| x tl IH].
  - reflexivity.
  - simpl. rewrite IH. reflexivity.
Qed.

Theorem map_length : forall (A B : Type) (f : A -> B) (xs : list A),
  length (map f xs) = length xs.
Proof.
  intros A B f xs. induction xs as [| x tl IH].
  - reflexivity.
  - simpl. rewrite IH. reflexivity.
Qed.

(* filter 的幂等性：筛过的再筛一遍不变。
   注意 destruct (p x) eqn:E 的用法：filter 展开后 if p x 会
   再次出现，用 E 记住结果、rewrite E 才能继续。 *)

Theorem filter_idem : forall (A : Type) (p : A -> bool) (xs : list A),
  filter p (filter p xs) = filter p xs.
Proof.
  intros A p xs. induction xs as [| x tl IH].
  - reflexivity.
  - simpl. destruct (p x) eqn:E.
    + simpl. rewrite E. rewrite IH. reflexivity.
    + exact IH.
Qed.

(* fold_right 构造列表：cons 折叠是恒等 *)
Theorem fold_cons : forall (A : Type) (xs : list A),
  fold_right (fun x acc => x :: acc) [] xs = xs.
Proof.
  intros A xs. induction xs as [| x tl IH].
  - reflexivity.
  - simpl. rewrite IH. reflexivity.
Qed.

(* ---------- 心法 ---------- *)
(* 高阶函数的证明毫无新意：对 xs 归纳、基例 reflexivity、
   步例 simpl 后用 IH——与第 12 章一模一样。
   「函数当参数」不改变证明的形状，因为归纳发生在列表上。 *)

End Ex16HigherOrder.
