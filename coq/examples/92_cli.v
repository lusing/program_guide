(* 76 quickchick 命令行与变异测试 —— 从编译期内嵌执行到独立 runner：
   感叹号注解三分法（分节 Section、测试 QuickChick、变异 Mutant）、quickChick
   命令行十二选项、变异测试方法论（种 mutant、杀 mutant、幸存者即盲区），
   案例为 QuickChick 官方 stack-compiler（Exp 表达式语言 + Stack 栈机编译器）的内联精简版 *)

Set Warnings "-extraction-opaque-accessed,-extraction".
Set Warnings "-notation-overridden,-parsing".

From QuickChick Require Import QuickChick Tactics.
Import QcDefaultNotation. Open Scope qc_scope.

From Stdlib Require Import Arith List. Import ListNotations.

Module Ex76Cli.

(* ---------- 76.1 Exp：表达式语言、eval 与第一个变异注解 ---------- *)

(* 官方案例本是 stack-compiler/ 目录下的 Exp.v 与 Stack.v 两个文件（配 _CoqProject
   与 Makefile）；这里内联进同一 Module 便于单文件编译。以感叹号开头的注释是
   quickChick 命令行工具的注解，对 rocq compile 只是普通注释，编译无碍。 *)

(*! Section arithmetic_expressions *)

Inductive exp : Type :=
| ANum : nat -> exp
| APlus : exp -> exp -> exp
| AMinus : exp -> exp -> exp
| AMult : exp -> exp -> exp.

QCDerive (Arbitrary, Show) for exp.

Fixpoint eval (e : exp) : nat :=
  match e with
  | ANum n => n
(*! *)
  | APlus e1 e2 => (eval e1) + (eval e2)
(*!! Plus-copy-paste-error *)
(*! | APlus e1 e2 => (eval e1) + (eval e1) *)
  | AMinus e1 e2 => (eval e1) - (eval e2)
  | AMult e1 e2 => (eval e1) * (eval e2)
  end.

(* ---------- 76.2 optimize：官方教程的填空作业、测试注解与分节 ---------- *)

(* 官方 Exp.v 在 optimize 处留了填空作业（TODO: FILL ME DURING TUTORIAL!）：
   只给出「APlus e (ANum 0) => optimize e」一个分支和兜底「| _ => ANum 0」。
   完整解答：加 0、减 0 两侧都消去，其余情形对子表达式递归优化。 *)

(*! Section optimizations *)(*! extends arithmetic_expressions *)

Fixpoint optimize (e : exp) : exp :=
  match e with
  | ANum n => ANum n
  | APlus e (ANum 0)  => optimize e
  | APlus (ANum 0) e  => optimize e
  | APlus e1 e2 => APlus (optimize e1) (optimize e2)
(*! *)
  | AMinus e (ANum 0) => optimize e
(*!! Minus-Reverse *)
(*!
  | AMinus (ANum 0) e => optimize e
*)
  | AMinus e1 e2 => AMinus (optimize e1) (optimize e2)
  | AMult e1 e2 => AMult (optimize e1) (optimize e2)
  end.

Definition optimize_correct_prop (e : exp) := eval (optimize e) = eval e?.

(*! QuickChick optimize_correct_prop. *)
(* 注解把同名性质登记给 quickChick CLI；内嵌的执行版命令统一放在文件
   末尾的执行区（模块外）——每条 QuickChick 命令各自触发一次抽取并
   当场编译运行。内嵌命令允许匿名性质，注解必须具名——执行区最后
   一条内嵌命令合法，却写不成注解。 *)

(* ---------- 76.3 Stack：栈机、编译器填空作业与被抓个正着的新手错误 ---------- *)

(*! Section stack_instructions *)(*! extends arithmetic_expressions *)

Inductive sinstr : Type :=
| SPush : nat -> sinstr
| SPlus : sinstr
| SMinus : sinstr
| SMult : sinstr.

Fixpoint execute (stack : list nat) (prog : list sinstr) : list nat :=
  match (prog, stack) with
  | (nil,             _           ) => stack
  | (SPush n::prog',  _           ) => execute (n::stack) prog'
  | (SPlus::prog',    m::n::stack') => execute ((m+n)::stack') prog'
  | (SMinus::prog',   m::n::stack') => execute ((m-n)::stack') prog'
  | (SMult::prog',    m::n::stack') => execute ((m*n)::stack') prog'
  | (_::prog',        _           ) => execute stack prog'
  end.

Module StackRookie.

(* 官方 Stack.v 的另一道填空（TODO: WRITE DURING TUTORIAL!）：按直觉
   「左操作数先压栈」写编译器——里面埋着一个新手错误，先让性质说话。 *)

Fixpoint compile (e : exp) : list sinstr :=
  match e with
  | ANum n => [SPush n]
  | APlus  e1 e2 => compile e1 ++ compile e2 ++ [SPlus]
  | AMinus e1 e2 => compile e1 ++ compile e2 ++ [SMinus]
  | AMult  e1 e2 => compile e1 ++ compile e2 ++ [SMult]
  end.

Definition compiles_correctly (e : exp) := (execute [] (compile e)) = [eval e]?.

End StackRookie.

(* ---------- 76.4 修复并记档：正确代码做 base，踩过的坑做成 mutant ---------- *)

Module StackFixed.

(* 修复：右操作数先压栈。二目指令弹出 m（栈顶）、n 后计算 m+n / m-n / m*n，
   右者先压则栈顶 m 恰为左操作数。修好后再把刚踩过的坑「记档」为 mutant：
   base 是正确代码，被杀的变体收进单感叹号注解，随时接受套件的考核。 *)

Fixpoint compile (e : exp) : list sinstr :=
  match e with
  | ANum n => [SPush n]
(*! *)
  | APlus  e1 e2 => compile e2 ++ compile e1 ++ [SPlus]
  | AMinus e1 e2 => compile e2 ++ compile e1 ++ [SMinus]
  | AMult  e1 e2 => compile e2 ++ compile e1 ++ [SMult]
(*!! Wrong associativity *)
(*!
  | APlus  e1 e2 => compile e1 ++ compile e2 ++ [SPlus]
  | AMinus e1 e2 => compile e1 ++ compile e2 ++ [SMinus]
  | AMult  e1 e2 => compile e1 ++ compile e2 ++ [SMult]
*)
  end.

Definition compiles_correctly (e : exp) := (execute [] (compile e)) = [eval e]?.

(*! QuickChick compiles_correctly. *)
(* 修复后回归通过（执行区验证）；变异测试的验收标准随之反转——mutant
   「Wrong associativity」在这条性质下必须失败：被杀死才说明性质灵敏；
   quickChick 的 -m 与 -tag 就是逐个验收 mutant 的开关。 *)

End StackFixed.

End Ex76Cli.

(* 内嵌执行命令统一放在模块外：QuickChick 2.2 的抽取管线对模块内
   上下文生成的 OCaml 引用缺少模块限定，会报 Unbound value
   quickchick；命令放到模块外、引用模块内容则一切正常。
   StackRookie 与 StackFixed 里的 compiles_correctly 重名，
   用全限定名区分。 *)

Import Ex76Cli.

QuickChick optimize_correct_prop.
(* +++ Passed 10000 tests (0 discards)。 *)

QuickChick (fun e => eval (optimize e) = eval e?).
(* 同样 +++ Passed 10000 tests (0 discards)。 *)

QuickChick StackRookie.compiles_correctly.
(* 一次实测（随机测试，数字每次会变）：
     AMinus (ANum 0) (ANum 1)
     *** Failed after 3 tests and 2 shrinks. (0 discards)
   反例 e = 0 - 1：Rookie 版编译出 [SPush 0; SPush 1; SMinus]，SMinus 从栈顶
   依次弹出 m=1、n=0，算得 1-0=1；而 eval (0-1) = 0。减法不交换——「左操作数
   先压栈」让它沉入栈底，弹出时左右颠倒。 *)

QuickChick StackFixed.compiles_correctly.
(* +++ Passed 10000 tests (0 discards)：修复后回归通过。 *)
