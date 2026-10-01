(* ============================================================ *)
(* 06 System F —— Coq 侧：多态作为 Coq 的日常                   *)
(* Coq 的 ∀ 早就是 λ2 的 ∀；这里演示一份代码多种类型、           *)
(* 多态 Church 数在两个不同实例化下求值                          *)
(* ============================================================ *)

Require Import List Arith Bool.
Import ListNotations.

(* ---- 一份代码，两种（无限种）类型 ---- *)
Definition pid {A : Type} (x : A) : A := x.

Compute (pid 41).                       (* nat *)
Compute (pid true).                     (* bool *)
Compute (pid (fun n : nat => n + 1)).   (* nat -> nat *)
Check (pid 3, pid true).                (* (nat * bool)%type *)

(* 同一个 pid 出现在两个类型下——03 章 I I 的翻案 *)
Check (pid (pid 3)).

(* ---- 多态 Church 数：∀X. (X→X)→X→X ---- *)
Definition cn (n : nat) : forall X : Type, (X -> X) -> X -> X :=
  fun X f x => Nat.iter n f x.

(* 类型就是 System F 的主类型 *)
Check cn : forall n : nat, forall X : Type, (X -> X) -> X -> X.

(* 实例化到 nat：f := succ，x := 0 *)
Compute (cn 5 nat S 0).                 (* = 5 *)

(* 实例化到 bool：f := negb，x := true —— 同一份代码另一种类型 *)
Compute (cn 5 bool negb true).          (* = false：奇数次翻转 *)
Compute (cn 4 bool negb true).          (* = true *)

(* 实例化到 list nat：f := map S，x := [0] —— 迭代三次得 [3] *)
Compute (cn 3 (list nat) (map S) (0 :: nil)).  (* = [3] *)

(* ---- 运算符也多态 ---- *)
Definition cadd : forall X : Type,
  (forall X, (X -> X) -> X -> X) -> (forall X, (X -> X) -> X -> X)
  -> forall X, (X -> X) -> X -> X :=
  fun _ m n X f x => m X f (n X f x).

Compute (cadd nat (cn 2) (cn 3) nat S 0).   (* = 5：传入未实例化的多态值 *)

(* ---- Girard/Reynolds 的世界：F 强规范化，ω 不可类型化 ---- *)
(* λ(x:∀X.X→X). x 太「多态」而不能自应用：
   x x 需要 x : ∀X.X→X 同时是箭头类型——forall 不是箭头 *)
Fail Check (fun (x : forall X, X -> X) => x x).

(* 历史注脚：F 的强规范化（Girard 1972）比 λ→ 难得多——
   证明要过「消去剪枝」的坎， Reynolds 用它证明隐式多态的
   不可表达性（类型擦除会崩）。 *)
