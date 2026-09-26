(* 05 表达式与运算符 —— 记号、nat 算术的坑、bool 与 if、Z 速览 *)

From Stdlib Require Import ZArith.

Module Ex05Expressions.

(* ---------- 记号是语法糖 ---------- *)

Locate "+".
(* nat_scope 里 "x + y" := Nat.add x y —— 三种解释中默认生效的这个 *)

Compute (Nat.add 2 3).   (* = 5 : nat *)
Compute (2 + 3).         (* = 5 : nat —— 与上一行完全等价 *)

(* ---------- nat 算术：两个必须牢记的坑 ---------- *)

Compute (1 - 2).    (* = 0 : nat —— 截断减法！没有负数，减到 0 为止 *)
Compute (7 / 2).    (* = 3 : nat *)
Compute (5 / 0).    (* = 0 : nat —— 除以 0 规定为 0，不崩溃 *)
Compute (5 mod 2).  (* = 1 : nat *)
Compute (0 mod 5).  (* = 0 : nat *)

Compute (Nat.max 3 7).    (* = 7 *)
Compute (Nat.min 3 7).    (* = 3 *)
Compute (Nat.pow 2 10).   (* = 1024 *)

(* nat 上没有一元负号（下面的句子解析不了，
   Fail 对语法错误同样有效——实测可以预言解析失败）： *)
Fail Check (- 1).

(* ---------- 比较：返回 bool（可计算的数据） ---------- *)

Compute (Nat.eqb 3 3).   (* = true : bool *)
Compute (Nat.leb 3 7).   (* = true : bool   也可写作 3 <=? 7 *)
Compute (Nat.ltb 7 3).   (* = false : bool  也可写作 7 <? 3  *)

Example leb_demo : Nat.eqb (3 + 4) 7 = true.
Proof. reflexivity. Qed.

(* ---------- bool 运算与 if ---------- *)

Compute (andb true false).   (* = false *)
Compute (orb true false).    (* = true *)
Compute (negb true).         (* = false *)

(* 大坑（实测）：Coq 的 if 不是「条件必须是 bool」，而是
   「条件可以是任何恰好两个构造子的归纳类型」——
   if 就是两分支 match 的语法糖：第一个构造子走 then，
   第二个走 else。nat 恰好只有 O 和 S 两个构造子： *)

Compute (if 1 then 2 else 3).   (* = 3 : nat —— 1 = S O，走了 else！ *)
Compute (if 0 then 2 else 3).   (* = 2 : nat —— 0 = O，走 then *)

(* bool 只是「两构造子俱乐部」里最常用的成员，日常写
   if b then .. else .. 时 b 几乎总是 bool；
   另一个常客是 sumbool（left/right），第 14 章会遇到。
   构造子数量不是两个就真的不行：Z 有 Z0/Zpos/Zneg 三个。 *)

Fail Compute (if 1%Z then 2 else 3).
(* 恰好两个构造子才允许 if —— 这条如期失败 *)

Definition abs_diff (a b : nat) : nat :=
  if Nat.leb a b then b - a else a - b.

Compute (abs_diff 3 8).   (* = 5 *)
Compute (abs_diff 8 3).   (* = 5 *)

(* ---------- Z 速览：要负数就换数系 ---------- *)

Compute (2 - 5)%Z.    (* = -3 : Z *)
Compute (- 3)%Z.      (* = -3 : Z —— 一元负号在 Z 上才有 *)
Compute (Z.pow 2 10). (* = 1024 : Z *)

(* %Z 是作用域限定符：只在这对括号里把数字与运算符解释成 Z。
   括号外的世界默认仍是 nat： *)
Compute (2 - 5).      (* = 0 : nat —— 对照 *)

End Ex05Expressions.
