(* 04 类型系统 —— nat 的真身、万物皆有类型、多态与隐式参数 *)

Module Ex04Types.

(* ---------- nat 的真身 ---------- *)

Print nat.
(* Inductive nat : Set := O : nat | S : nat -> nat. *)

Check O.               (* O : nat *)
Check (S O).           (* 1 : nat *)
Check (S (S O)).       (* 2 : nat *)
Compute (S (S (S O))). (* = 3 : nat —— 打印时自动用数字记号 *)

(* 自然数是一根链条：3 就是 S (S (S O))。
   它不是 32/64 位机器整数——这牺牲了性能换来两个好处：
   1. 每个数只有两种「形状」（O 或 S _），归纳与归纳证明才成立；
   2. 类型上无溢出：数要多大有多大。
   但注意（实测）：「类型装得下」不等于「算得动」——
   Compute (Nat.pow 2 100) 会因一元表示直接内存耗尽，
   大数计算请用二进制的 N/Z（第 22 章）。 *)

(* ---------- 万物皆有类型，类型也有类型 ---------- *)

Check nat.      (* nat : Set *)
Check bool.     (* bool : Set *)
Check Set.      (* Set : Type *)
Check Type.     (* Type : Type —— 打印时隐藏了层级编号，初学不必深究 *)

Check (3 = 3).        (* 3 = 3 : Prop —— 等式是「命题」 *)
Check (Nat.eqb 3 3).  (* Nat.eqb 3 3 : bool —— 布尔是「数据」 *)
(* Prop 与 bool 的分工是 Coq 的重要主题，第 14 章展开 *)

(* ---------- 类型推断：标注可省则省 ---------- *)

Definition fortytwo := 42.
Check fortytwo.         (* fortytwo : nat —— 推断出来的 *)

Definition double (n : nat) : nat := 2 * n.
Definition double' n := 2 * n.
Check double'.          (* double' : nat -> nat —— 参数类型也能推 *)

(* 标注省了，检查一点没少： *)
Fail Check (double true).
(* The term "true" has type "bool" while it is expected to have
   type "nat". *)

(* ---------- 多态：类型做参数 ---------- *)

Check (@nil nat).
(* @nil nat : list nat —— 空表要说明「装什么」 *)

Check (cons true nil).
(* (true :: nil)%list : list bool —— 元素类型自动推断，
   打印时习惯用 :: 记号显示 *)

Definition id {A : Type} (a : A) : A := a.
(* {A : Type} 花括号 = 隐式参数：调用时不必写，由推断补全 *)

Check (id 10).        (* id 10 : nat *)
Check (id true).      (* id true : bool *)
Check (@id nat 10).   (* @id nat 10 : nat —— @ 表示「接下来手动给全参数」 *)

Compute (id 10).      (* = 10 : nat *)

(* ---------- 每个构造子只吃自己类型的参数 ---------- *)

Fail Check (S true).
(* The term "true" has type "bool" while it is expected to have
   type "nat". *)

End Ex04Types.
