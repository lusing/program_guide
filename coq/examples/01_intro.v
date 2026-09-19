(* 01 认识 Coq —— Check / Compute / 证明，三种对话方式

   与 Coq 打交道，本质上就是三种句子：
   - Check   ：问「这个项是什么类型？」
   - Compute ：问「这个表达式算出来是什么？」
   - Example ：下一个断言，然后交出证明，让 Coq 检查

   本文件同时用来验证：.v 源文件使用 UTF-8 编码时，
   中文注释可以正常通过 coqc 编译。
*)

Module Ex01Intro.

(* ---------- Check：类型是一切的起点 ---------- *)

Check 0.
(* 0 : nat —— 字面量 0 的类型是 nat（自然数） *)

Check (S (S (S O))).
(* 3 : nat —— S 是「后继」构造子，S (S (S O)) 就是 3，
   Coq 打印时自动用数字记号显示 *)

Check (fun n => n + 1).
(* fun n => n + 1 : nat -> nat —— 一个从 nat 到 nat 的函数 *)

Check (fun A (a : A) => a).
(* fun A a => a : forall A : Type, A -> A —— 多态恒等函数 *)

(* ---------- Compute：让 Coq 真正算一算 ---------- *)

Compute (2 + 2).
(* = 4 : nat *)

Compute (6 * 7).
(* = 42 : nat *)

Compute (Nat.eqb 42 42).
(* = true : bool *)

(* ---------- Example：断言 + 证明 + 封印 ---------- *)

Example plus_2_2 : 2 + 2 = 4.
Proof. reflexivity. Qed.
(* Proof 进入证明模式；reflexivity 检查等式两边是否
   化简到同一个值；Qed 封印整个证明并做最终类型检查。
   三行合起来读作：「我断言 2 + 2 = 4，证明是 reflexivity。」 *)

(* 例子里能写的东西，定理里一样能写 —— Example 与
   Theorem 在 Coq 眼里是同一种东西（都产生一个证明项）。 *)

Theorem six_times_seven : 6 * 7 = 42.
Proof. reflexivity. Qed.

End Ex01Intro.
