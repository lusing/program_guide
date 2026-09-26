(* 02 工具链与「问问题」的艺术

   coqc 编译本文件时，会把下列问询命令的结果打印出来：
   - Print   ：这个类型/符号是怎么定义的？
   - About   ：这个常量的类型、参数、所在的模块？
   - Locate  ：这个记号（+、=、::）绑定到哪个真身？
   - Search  ：库里有哪些定理长得像我需要的形状？

   运行方式（在 coq 目录下）：
     .\build.ps1 -File 02_toolchain.v
   或直接：
     & G:\scoop\apps\coq\current\bin\coqc.exe examples\02_toolchain.v
*)

Module Ex02Toolchain.

(* ---------- Print：查看定义的真身 ---------- *)

Print nat.
(* Inductive nat : Set := O : nat | S : nat -> nat.
   —— nat 不是机器整数，只有两个构造子：O 和 S *)

Print bool.
(* Inductive bool : Set := true : bool | false : bool. *)

Print Nat.add.
(* Nat.add =
   fix add (n m : nat) {struct n} : nat :=
     match n with
     | 0 => m
     | S p => S (add p m)
     end
      : nat -> nat -> nat
   —— 我们写的 n + m，其实是 Nat.add n m：
   在第一个参数上递归，n 为 0 时直接返回 m *)

(* ---------- About：查看符号的档案 ---------- *)

About Nat.add.
(* Nat.add : nat -> nat -> nat
   Expands to: Constant Corelib.Init.Nat.add`n      ——9.x 起前言库拆成 Corelib（Init/Prelude），`n        Stdlib（Arith/List/...）两层 *)

About eq.
(* eq : forall {A : Type}, A -> A -> Prop
   —— x = y 其实是项 eq x y，它是一个 Inductive；
   证明 = x = y 就是构造 eq 这个类型的居民 *)

(* ---------- Locate：定位记号的真身 ---------- *)

Locate "+".
(* 一个 "+" 绑着三种解释：
   "{ A } + { B }" := sumbool A B : type_scope
   "A + { B }"     := sumor A B   : type_scope
   "x + y"         := Nat.add x y : nat_scope   <-- 默认生效的这个 *)

Locate "::".
(* "x :: y" := cons x y : list_scope —— 绑到 list 的 cons 构造子 *)

(* ---------- Search：按形状搜定理 ---------- *)

Search (_ + 0).
(* plus_n_O : forall n : nat, n = n + 0
   —— 结论形状匹配「某东西 + 0」的定理全部列出 *)

Search (S _ <= S _).
(* le_n_S : forall n m : nat, n <= m -> S n <= S m
   le_S_n : forall n m : nat, S n <= S m -> n <= m *)

(* 搜索结果可能很长；配合关键字过滤更好用：
   Search (_ <= _) "le_n_S".   —— 只看名字含 le_n_S 的结果 *)

End Ex02Toolchain.
