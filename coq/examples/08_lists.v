(* 08 列表 —— list 的真身、常用操作、fold 方向坑 *)

From Stdlib Require Import List Arith.
Import ListNotations.

Module Ex08Lists.

(* ---------- list 的真身 ---------- *)

Print list.
(* Inductive list (A : Type) : Type :=
     nil : list A | cons : A -> list A -> list A.
   —— 和 nat 同款设计：一个「底」构造子 + 一个「递归」构造子 *)

(* [1; 2] 只是 cons 1 (cons 2 nil) 的记号（需 Import ListNotations） *)
Check (1 :: 2 :: nil).        (* [1; 2] : list nat —— 打印也用记号 *)

(* ---------- 标准库常用操作 ---------- *)

Compute (length [1; 2; 3]).           (* = 3 *)
Compute (app [1; 2] [3; 4]).          (* = [1;2;3;4] *)
Compute ([1; 2] ++ [3; 4]).           (* 同上，++ 是 app 的记号 *)
Compute (rev [1; 2; 3]).              (* = [3;2;1] *)
Compute (concat [[1; 2]; [3]]).       (* = [1;2;3] —— 拍平一层 *)
Compute (seq 0 5).                    (* = [0;1;2;3;4] *)
Compute (map (fun n => n * 2) [1; 2; 3]).        (* = [2;4;6] *)
Compute (filter (fun n => Nat.eqb (n mod 2) 0) [1; 2; 3; 4]).
                                      (* = [2;4] —— 留偶数 *)

(* nth：越界时返回你给的默认值，不崩溃（坑：吞错） *)
Compute (nth 1 [10; 20; 30] 0).       (* = 20 *)
Compute (nth 5 [10; 20; 30] 0).       (* = 0 —— 越界时静默用默认值 *)

(* ---------- 自己写一遍：结构递归 ---------- *)

Fixpoint my_length {A : Type} (xs : list A) : nat :=
  match xs with
  | [] => 0
  | _ :: tl => S (my_length tl)
  end.

Fixpoint my_append {A : Type} (xs ys : list A) : list A :=
  match xs with
  | [] => ys
  | h :: tl => h :: my_append tl ys
  end.

Example my_length_ex : my_length [1; 2; 3] = 3.
Proof. reflexivity. Qed.

Example my_append_ex : my_append [1; 2] [3; 4] = [1; 2; 3; 4].
Proof. reflexivity. Qed.

(* head 没有默认值时怎么办？option（第 17 章专题） *)
Definition safe_head {A : Type} (xs : list A) : option A :=
  match xs with
  | [] => None
  | h :: _ => Some h
  end.

Compute (safe_head [10; 20]).   (* = Some 10 *)
Compute (safe_head []).         (* = None *)

(* ---------- fold：方向与参数顺序（两个大坑，实测） ---------- *)

(* fold_right f 初值 列表 —— 从右往左叠：
   f x1 (f x2 (f x3 初值)) *)
Compute (fold_right Nat.add 0 [1; 2; 3; 4]).   (* = 10 *)

(* fold_left f 列表 初值 —— 注意：列表在前、初值在后！
   f (f (f 初值 x1) x2) x3 *)
Compute (fold_left Nat.add [1; 2; 3; 4] 0).    (* = 10 *)

(* 两个 fold 的参数顺序不同（fold_right 是 f a l，
   fold_left 是 f l a）——初学者极易把初值放错位置。
   用一个非交换的叠法让方向差异显形： *)

Compute (fold_right (fun x acc => x :: acc) [] [1; 2; 3]).
                                      (* = [1;2;3] *)
Compute (fold_left (fun acc x => x :: acc) [1; 2; 3] []).
                                      (* = [3;2;1] —— 恰好是 rev！ *)

End Ex08Lists.
