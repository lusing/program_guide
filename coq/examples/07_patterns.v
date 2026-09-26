(* 07 模式匹配 —— match 的全部词汇、穷尽性、冗余分支（实测错误） *)

From Stdlib Require Import List.
Import ListNotations.

Module Ex07Patterns.

(* ---------- 基本 match：按构造子分支 ---------- *)

Definition is_zero (n : nat) : bool :=
  match n with
  | O => true
  | S _ => false      (* S 后面的分量用通配符 _ 忽略 *)
  end.

Compute (is_zero 0).          (* = true *)
Compute (is_zero 5).          (* = false *)

(* ---------- 模式的四类词汇 ---------- *)

(* 1. 构造子模式；2. 变量模式（绑定分量）；3. 通配符；4. 字面量 *)

Definition classify (n : nat) : nat :=
  match n with
  | 0 => 0             (* 字面量 0 就是 O *)
  | 1 => 1             (* 字面量 1 就是 S O，Coq 负责展开匹配 *)
  | 2 => 2
  | S (S (S _)) => 3   (* 嵌套模式：至少 3 *)
  end.

Compute (classify 2).         (* = 2 *)
Compute (classify 7).         (* = 3 *)

(* ---------- 嵌套模式 + 多 scrutinee ---------- *)

Definition second (xs : list nat) : option nat :=
  match xs with
  | _ :: y :: _ => Some y    (* 第二个元素：嵌套两层 *)
  | _ => None
  end.

Compute (second [10; 20; 30]).   (* = Some 20 *)
Compute (second [10]).           (* = None *)

Definition both (b1 b2 : bool) : bool :=
  match b1, b2 with
  | true, true => true
  | _, _ => false
  end.

Compute (both true true).     (* = true *)
Compute (both true false).    (* = false *)

(* 元组解构在 match 里最自然 *)
Definition add3 (p : nat * (nat * nat)) : nat :=
  match p with
  | (a, (b, c)) => a + b + c
  end.

Compute (add3 (1, (2, 3))).   (* = 6 *)

(* option 的 match 是「安全拆箱」的标准姿势 *)
Definition default_zero (o : option nat) : nat :=
  match o with
  | Some n => n
  | None => 0
  end.

(* ---------- 穷尽性检查：漏分支 = 编译错误（实测） ---------- *)

Fail Definition missing (b : bool) : nat :=
  match b with
  | true => 1
  end.
(* Error: Non exhaustive pattern-matching:
   no clause found for pattern "false" *)

(* ---------- 冗余分支 = 编译错误（实测，8.20/9.1） ---------- *)

Fail Definition redundant (b : bool) : nat :=
  match b with
  | true => 1
  | false => 2
  | _ => 3       (* 前两支已覆盖全部，这支永不可达 *)
  end.
(* Error: Pattern "_" is redundant in this clause. *)

(* ---------- match 是表达式，不是语句 ---------- *)

Definition neg (b : bool) : bool :=
  if b then false else true.   (* if 本身就是两分支 match 的糖 *)

Compute (match 3 with 0 => 0 | S _ => 1 end).   (* = 1 —— 有值、有类型 *)

End Ex07Patterns.
