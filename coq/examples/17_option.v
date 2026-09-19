(* 17 Option：安全建模 —— 用类型消灭「查无此值」 *)

From Coq Require Import List Arith.
Import ListNotations.

Module Ex17Option.

(* ---------- 为什么需要 option ---------- *)

(* 第 8 章的坑：nth 越界返回默认值，错误被吞。option 版把
   「可能失败」写进类型：失败不再是值，而是类型里明说的 None。 *)

Fixpoint nth_option {A : Type} (n : nat) (xs : list A) : option A :=
  match n, xs with
  | O, x :: _ => Some x
  | S k, _ :: tl => nth_option k tl
  | _, _ => None
  end.

Compute (nth_option 1 [10; 20; 30]).   (* = Some 20 *)
Compute (nth_option 5 [10; 20; 30]).   (* = None —— 越界明说 *)

(* ---------- option 上的编程 ---------- *)

Definition option_map {A B : Type} (f : A -> B) (o : option A) : option B :=
  match o with
  | Some x => Some (f x)
  | None => None
  end.

Definition default {A : Type} (d : A) (o : option A) : A :=
  match o with
  | Some x => x
  | None => d
  end.

Definition bind {A B : Type} (o : option A) (f : A -> option B) : option B :=
  match o with
  | Some x => f x
  | None => None
  end.

Compute (option_map S (Some 3)).   (* = Some 4 *)
Compute (option_map S None).       (* = None —— 失败自动传播 *)
Compute (default 0 (Some 5)).      (* = 5 *)
Compute (default 0 None).          (* = 0 —— 兜底要显式 *)

(* ---------- 链式：可能失败的计算串联 ---------- *)

Definition safe_div (a b : nat) : option nat :=
  if Nat.eqb b 0 then None else Some (a / b).

(* 「列表前两个元素相除」——任何一步失败整体就是 None *)
Definition div_heads (xs : list nat) : option nat :=
  bind (nth_option 0 xs) (fun a =>
    bind (nth_option 1 xs) (fun b => safe_div a b)).

Compute (div_heads [10; 2]).    (* = Some 5 *)
Compute (div_heads [10]).       (* = None —— 第二个元素不存在 *)
Compute (div_heads [10; 0]).    (* = None —— 除零 *)
Compute (div_heads [10; 5]).    (* = Some 2 *)

(* ---------- 证明 ---------- *)

Theorem option_map_id : forall (A : Type) (o : option A),
  option_map (fun x => x) o = o.
Proof.
  intros A o. destruct o.
  - reflexivity.
  - reflexivity.
Qed.

Theorem bind_none : forall (A B : Type) (f : A -> option B),
  bind None f = None.
Proof.
  intros A B f. reflexivity.
Qed.

Theorem nth_option_map : forall (A B : Type) (f : A -> B) (n : nat) (xs : list A),
  option_map f (nth_option n xs) = nth_option n (map f xs).
Proof.
  intros A B f n. induction n as [| n IH]; intros xs.
  - destruct xs as [| x tl].
    + reflexivity.
    + reflexivity.
  - destruct xs as [| x tl].
    + reflexivity.
    + simpl. apply IH.
Qed.

(* 这是个「双维归纳」的例子：对 n 归纳、对 xs 分情况。
   注意 intros xs 放在 induction 之后——n 归纳时 xs 保持
   任意（IH 对所有 xs 成立），这是第 12 章坑 2 的正面示范。 *)

End Ex17Option.
