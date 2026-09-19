(* 06 元组与记录 —— 积类型 A * B、fst/snd、Record 建模 *)

Module Ex06TuplesRecords.

(* ---------- 元组：积类型 ---------- *)

Check (3, true).              (* (3, true) : nat * bool *)
Definition p : nat * bool := (3, true).

Compute (fst p).              (* = 3 : nat —— 第一个分量 *)
Compute (snd p).              (* = true : bool —— 第二个分量 *)

(* A * B 的 * 是类型层面的「积」记号（type_scope），
   与乘法无关——Locate "*" 可查证 *)

(* 嵌套元组：fst/snd 只拆最外层 *)
Definition q : (nat * nat) * bool := ((1, 2), true).
Compute (fst (fst q)).        (* = 1 : nat *)

(* let 解构：比连续 fst 可读得多 *)
Compute (let (x, y) := p in if y then x else 0).   (* = 3 *)

(* ---------- Record：带字段名的积类型 ---------- *)

Record Point : Type := {
  px : nat;
  py : nat
}.

Definition origin : Point := {| px := 0; py := 0 |}.
Definition p1 : Point := {| px := 2; py := 5 |}.

(* 字段名即投影函数 *)
Compute (px p1).              (* = 2 *)
Compute (py p1).              (* = 5 *)

Definition move_x (p : Point) (dx : nat) : Point :=
  {| px := px p + dx; py := py p |}.

Example move_ex : move_x p1 3 = {| px := 5; py := 5 |}.
Proof. reflexivity. Qed.

(* Record 的真身：只有一个构造子的 Inductive（实测打印） *)
Print Point.
(* Inductive Point : Type := Build_Point : nat -> nat -> Point *)

(* ---------- 参数化 Record ---------- *)

Record Trio (A : Type) : Type := {
  first : A;
  second : A;
  third : A
}.

Definition t1 : Trio nat := {| first := 1; second := 2; third := 3 |}.
Definition t2 : Trio bool := {| first := true; second := false; third := true |}.

(* 坑（实测）：参数化 Record 的投影自带显式类型参数——
   裸写 first t1 报错说 t1 该是 Type。要么传下划线让推断补全，
   要么用 Arguments 把参数设为隐式： *)
Compute (first _ t1).         (* = 1 *)
Arguments first {A}. Arguments second {A}. Arguments third {A}.
Compute (first t1).           (* = 1 *)
Compute (first t2).           (* = true *)

(* ---------- 字段名是全局的（实测坑） ---------- *)

(* 下面两行若同时解开注释，第二条会报 fx already exists：
   Record P1 : Type := { fx : nat }.
   Record P2 : Type := { fx : nat }.
   —— 字段名（投影函数名）进全局命名空间，不能重名。
   多个记录用同一名字段（如 name）时，只能定义一个。 *)

End Ex06TuplesRecords.
