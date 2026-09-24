(* 24 综合：一个表达式编译器

   把前 23 章的东西凑成一个能站得住的小工程：
   定义一门语言 → 写它的语义 → 写一台机器 → 写编译器 → 证明编译器对。
   最后再加一个"保持语义的优化"作为收尾。 *)

val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse simpLib
open arithmeticTheory listTheory

val _ = new_theory "Tut24"

fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")
fun p t tac = thm_to_string (prove (t, tac))
fun ev t = EVAL t |> concl |> term_to_string

val _ = print "\n==== 24 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 24.1 语法                                                          *)
(* ------------------------------------------------------------------ *)
val _ = sec "24.1 语法"
val _ = Datatype `expr = Cst num | Add expr expr | Mul expr expr`
val _ = out ("四个赠品里的穷举：" ^ thm_to_string (DB.fetch "Tut24" "expr_nchotomy"))
val _ = out ("区分性：" ^ thm_to_string (DB.fetch "Tut24" "expr_distinct"))
val _ = out ("归纳原理：" ^ thm_to_string (DB.fetch "Tut24" "expr_induction"))

(* ------------------------------------------------------------------ *)
(* 24.2 语义                                                          *)
(* ------------------------------------------------------------------ *)
val _ = sec "24.2 语义"
Definition eval_def:
  (eval (Cst n) = n) /\
  (eval (Add e1 e2) = eval e1 + eval e2) /\
  (eval (Mul e1 e2) = eval e1 * eval e2)
End
val _ = out (thm_to_string eval_def)
val _ = out ("求值：" ^ ev ``eval (Add (Cst 2) (Mul (Cst 3) (Cst 4)))``)

(* ------------------------------------------------------------------ *)
(* 24.3 一台栈机                                                      *)
(* ------------------------------------------------------------------ *)
val _ = sec "24.3 栈机"
val _ = Datatype `instr = Push num | IAdd | IMul`
(* 栈不够时 HD/TL 会给出 HOL 里的"某个 num"，不影响我们只跑合法程序的用法。 *)
Definition run_def:
  (run ([] : instr list) st = st) /\
  (run (Push n :: is) st = run is (n :: st)) /\
  (run (IAdd :: is) st = run is (HD st + HD (TL st) :: TL (TL st))) /\
  (run (IMul :: is) st = run is (HD st * HD (TL st) :: TL (TL st)))
End
val _ = out (thm_to_string run_def)
val _ = out ("跑一段：" ^ ev ``run [Push 2; Push 3; IAdd] ([] : num list)``)

(* ------------------------------------------------------------------ *)
(* 24.4 编译器                                                        *)
(* ------------------------------------------------------------------ *)
val _ = sec "24.4 编译器"
Definition compile_def:
  (compile (Cst n) = [Push n]) /\
  (compile (Add e1 e2) = compile e1 ++ compile e2 ++ [IAdd]) /\
  (compile (Mul e1 e2) = compile e1 ++ compile e2 ++ [IMul])
End
val _ = out (thm_to_string compile_def)
val _ = out ("编译：" ^ ev ``compile (Add (Cst 2) (Mul (Cst 3) (Cst 4)))``)
val _ = out ("先跑一遍确认没错：")
val _ = out ("  " ^ ev ``run (compile (Add (Cst 2) (Mul (Cst 3) (Cst 4)))) []``)

(* ------------------------------------------------------------------ *)
(* 24.5 关键引理：指令序列是可拼接的                                  *)
(* ------------------------------------------------------------------ *)
val _ = sec "24.5 拼接引理"
val _ = out ("主定理要处理 compile e1 ++ compile e2 ++ [IAdd]，")
val _ = out ("所以先要一条「两段指令接起来跑」的引理。")
val _ = out ("它对 is1 做归纳，同时**把 st 泛化**（否则归纳假设不够用）：")
val run_append = store_thm ("run_append",
  ``!is1 is2 st. run (is1 ++ is2) st = run is2 (run is1 st)``,
  Induct >> rw [run_def] >> Cases_on `h` >> rw [run_def])
val _ = out ("  " ^ thm_to_string run_append)

(* ------------------------------------------------------------------ *)
(* 24.6 主定理                                                        *)
(* ------------------------------------------------------------------ *)
val _ = sec "24.6 编译器正确"
val _ = out ("形式：对任意表达式和任意初始栈，编译后跑出来的栈 = 原栈前面")
val _ = out ("压上 eval 的结果。写成带 st 的形式，归纳才做得动。")
val compile_correct = store_thm ("compile_correct",
  ``!e st. run (compile e) st = eval e :: st``,
  Induct
  >> rw [compile_def, eval_def, run_def, run_append])
(* 最后一步的 `eval e2 + eval e1 = eval e1 + eval e2` 由 rw 自带的算术
   归一化解决。**不要**再加 ADD_COMM / MULT_COMM：把它们当重写规则喂给
   rw 会让化简器来回翻，实测跑不完。 *)
val _ = out ("  " ^ thm_to_string compile_correct)
val _ = out ("")
val _ = out ("证明只有三行，但每一行的分量：")
val _ = out ("  Induct         —— 用 expr_induction，st 自动被泛化；")
val _ = out ("  rw [...]      —— 展开 compile / eval / run，用 run_append 把")
val _ = out ("                   `compile e1 ++ compile e2 ++ [IAdd]` 拆开，")
val _ = out ("                   最后一步的 `eval e2 + eval e1 = eval e1 + eval e2`")
val _ = out ("                   由 rw 自带的算术归一化解决。")

(* ------------------------------------------------------------------ *)
(* 24.7 一个保持语义的优化                                            *)
(* ------------------------------------------------------------------ *)
val _ = sec "24.7 常量折叠"
(* 想写 `case (opt e1, opt e2) of (Cst m, Cst n) => ...` 是很自然的，
   但那样化简器会卡住：它没法对一个**非常量**的 scrutinee 做 case 分裂。
   把"两边都是常量"的判断拆成一个独立的二元函数，模式就是常量了。 *)
Definition opt_add_def:
  (opt_add (Cst m) (Cst n)   = Cst (m + n)) /\
  (opt_add (Cst m) (Add a b) = Add (Cst m) (Add a b)) /\
  (opt_add (Cst m) (Mul a b) = Add (Cst m) (Mul a b)) /\
  (opt_add (Add a b) e2      = Add (Add a b) e2) /\
  (opt_add (Mul a b) e2      = Add (Mul a b) e2)
End
Definition opt_mul_def:
  (opt_mul (Cst m) (Cst n)   = Cst (m * n)) /\
  (opt_mul (Cst m) (Add a b) = Mul (Cst m) (Add a b)) /\
  (opt_mul (Cst m) (Mul a b) = Mul (Cst m) (Mul a b)) /\
  (opt_mul (Add a b) e2      = Mul (Add a b) e2) /\
  (opt_mul (Mul a b) e2      = Mul (Mul a b) e2)
End
Definition opt_def:
  (opt (Cst n) = Cst n) /\
  (opt (Add e1 e2) = opt_add (opt e1) (opt e2)) /\
  (opt (Mul e1 e2) = opt_mul (opt e1) (opt e2))
End
val _ = out (thm_to_string opt_def)
val _ = out ("跑一下：")
val _ = out ("  " ^ ev ``opt (Add (Cst 2) (Mul (Cst 3) (Cst 4)))``)
val _ = out ("它产生的指令更少：")
val _ = out ("  " ^ ev ``compile (opt (Add (Cst 2) (Mul (Cst 3) (Cst 4))))``)

(* ------------------------------------------------------------------ *)
(* 24.8 优化不改变语义                                                *)
(* ------------------------------------------------------------------ *)
val _ = sec "24.8 引理先行"
val _ = out ("先给两个辅助函数各自的引理 —— 它们的模式都是常量，")
val _ = out ("两个 Cases 就能分干净：")
val opt_add_sound = store_thm ("opt_add_sound",
  ``!a b. eval (opt_add a b) = eval a + eval b``,
  Cases >> Cases >> rw [opt_add_def, eval_def])
val _ = out ("  " ^ thm_to_string opt_add_sound)
val opt_mul_sound = store_thm ("opt_mul_sound",
  ``!a b. eval (opt_mul a b) = eval a * eval b``,
  Cases >> Cases >> rw [opt_mul_def, eval_def])
val _ = out ("  " ^ thm_to_string opt_mul_sound)
val _ = out ("有了这两条，主定理就只剩一层归纳：")
val opt_sound = store_thm ("opt_sound", ``!e. eval (opt e) = eval e``,
  Induct >> rw [opt_def, eval_def, opt_add_sound, opt_mul_sound])
val _ = out ("  " ^ thm_to_string opt_sound)

(* ------------------------------------------------------------------ *)
(* 24.8 优化之后再编译，结果一样                                      *)
(* ------------------------------------------------------------------ *)
val _ = sec "24.9 两个定理合起来"
val _ = out ("把 opt_sound 和 compile_correct 拼起来，就得到")
val _ = out ("「优化后的程序跑出来的值不变」：")
val _ = out ("  " ^ p ``!e st. run (compile (opt e)) st = eval e :: st``
                (rw [compile_correct, opt_sound]))
val _ = out ("")
val _ = out ("这正是本教程想给的东西：机器只负责执行，")
val _ = out ("人负责把「为什么对」讲清楚，而 HOL 负责检查你讲得对不对。")

(* ------------------------------------------------------------------ *)
(* 24.10 回顾                                                         *)
(* ------------------------------------------------------------------ *)
val _ = sec "24.10 这一路用到的东西"
val _ = out ("05 章  Datatype 的赠品（nchotomy / distinct / induction）")
val _ = out ("06 章  递归定义与终止性检查")
val _ = out ("07 章  归纳假设不够强时怎么泛化（run_append 的 st）")
val _ = out ("08 章  化简器把定义展开")
val _ = out ("13 章  列表上的 APPEND / HD / TL")
val _ = out ("12 章  最后一步的线性算术")
val _ = out ("22 章  store_thm 把引理存进理论，供后面 fetch")
val _ = out ("23 章  让上面这一切能被别人复现的脚本纪律")

val _ = print "\n==== 24 结束 ====\n"

val _ = export_theory ()
