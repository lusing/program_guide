(* 69 属性测试入门 —— 从 Example 到 QuickChick：removeP 反例、修复回归、四要素总览 *)

Set Warnings "-extraction-opaque-accessed,-extraction".
Set Warnings "-notation-overridden,-parsing".

From QuickChick Require Import QuickChick.
From Stdlib Require Import List ZArith. Import ListNotations.

Module Ex69Quickstart.

(* ---------- 69.1 有 bug 的 remove 与它的规格 ---------- *)

Fixpoint remove (x : nat) (l : list nat) : list nat :=
  match l with
    | []   => []
  | h::t => if h =? x then t else h :: remove x t
  end.

Conjecture removeP : forall x l, ~ (In x (remove x l)).

QuickChick removeP.

(* 一次实测输出（随机测试，具体数字每次运行都会变）：
     0
     [0, 0]
     Failed! After 17 tests and 12 shrinks
   含义：x = 0、l = [0; 0] 时性质失败——17 次随机测试找到出错输入，
   12 次收缩把它化小为最小反例。 *)

(* ---------- 69.2 补上递归调用，重新测试 ---------- *)

Fixpoint remove' (x : nat) (l : list nat) : list nat :=
  match l with
    | []   => []
  | h::t => if h =? x then remove' x t else h :: remove' x t
  end.

Conjecture removeP' : forall x l, ~ (In x (remove' x l)).

QuickChick removeP'.

(* +++ Passed 10000 tests *)

(* ---------- 69.3 insert：写性质抓 bug 的完整循环 ---------- *)

Fixpoint insert (x : nat) (l : list nat) : list nat :=
  match l with
  | [] => [x]
  | y::t => if y <? x then insert x t else y::t
  end.

Conjecture insertP : forall x l, In x (insert x l).

QuickChick insertP.

Conjecture insertP2 : forall x y l, In y l -> In y (insert x l).

QuickChick insertP2.

Fixpoint insert' (x : nat) (l : list nat) : list nat :=
  match l with
  | [] => [x]
  | y::t => if y <? x then y :: insert' x t else x :: y :: t
  end.

Conjecture insertP' : forall x l, In x (insert' x l).

QuickChick insertP'.

Conjecture insertP2' : forall x y l, In y l -> In y (insert' x l).

QuickChick insertP2'.

(* ---------- 69.4 四要素速览：Show 打印、Arbitrary 生成与收缩 ---------- *)

Inductive color := Red | Green | Blue | Yellow.

QCDerive Show for color.
QCDerive Arbitrary for color.

Definition genColor : G color := arbitrary.

Sample genColor.

End Ex69Quickstart.
