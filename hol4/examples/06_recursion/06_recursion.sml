(* 06 递归定义与终止性

   HOL4 里没有「随便写的递归」：每个定义都必须通过终止性检查，否则 TFL
   （Total Function Library）会拒绝。本章从结构递归一直走到「必须手写
   良基关系「的例子，并演示自带的归纳定理怎么用。 *)

val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse
open arithmeticTheory listTheory

val _ = new_theory "Tut06"

fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")

val _ = print "\n==== 06 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 06.1 结构递归：不用写终止性证明                                    *)
(* ------------------------------------------------------------------ *)
val _ = sec "06.1 结构递归"
Definition mylen_def:
  (mylen [] = 0) /\
  (mylen (x :: xs) = 1 + mylen xs)
End
val _ = out (thm_to_string mylen_def)
val _ = out ("求值：" ^ (EVAL ``mylen [1; 2; 3]`` |> concl |> term_to_string))

(* ------------------------------------------------------------------ *)
(* 06.2 定义顺手带来的归纳定理                                        *)
(* ------------------------------------------------------------------ *)
val _ = sec "06.2 结构递归换不来额外的归纳定理"
val _ = out ("mylen_ind = " ^ thm_to_string mylen_ind)
val _ = out ("它是平凡的：每步递归都是结构下降，没有可证的归纳义务；")
val _ = out ("要归纳时用 listTheory 给类型准备的 list_induction 即可。")

(* ------------------------------------------------------------------ *)
(* 06.3 非结构递归：要交终止性证明                                    *)
(* ------------------------------------------------------------------ *)
val _ = sec "06.3 良基递归：欧几里得最大公约数"
Definition mygcd_def:
  mygcd a b = if b = 0 then a else mygcd b (a MOD b)
Termination
  WF_REL_TAC `measure (\(a, b). b)` >> rw []
End
val _ = out (thm_to_string mygcd_def)
val _ = out ("求值：" ^ (EVAL ``mygcd 12 8`` |> concl |> term_to_string))
val _ = out ("再求值：" ^ (EVAL ``mygcd 1071 462`` |> concl |> term_to_string))
val _ = out ("这次 _ind 不平凡：" ^ thm_to_string mygcd_ind)

(* ------------------------------------------------------------------ *)
(* 06.4 多参数 / 多重递归：斐波那契                                   *)
(* ------------------------------------------------------------------ *)
val _ = sec "06.4 多重递归"
(* 写法一：用 SUC 模式。定义能过终止性检查，但**算不动** ——
   HOL4 的十进制字面量是二进制 numeral（numeralTheory），不是 SUC 链，
   而 SUC (SUC n) 这种嵌套模式匹配不上 numeral。 *)
Definition fib_def:
  (fib 0 = 0) /\
  (fib (SUC 0) = 1) /\
  (fib (SUC (SUC n)) = fib (SUC n) + fib n)
End
val _ = out (thm_to_string fib_def)
val _ = out ("EVAL ``fib 10``        = " ^ (EVAL ``fib 10`` |> concl |> term_to_string))
val _ = out ("  ↑ 原地踏步：算不动，只给出 fib 10 = fib 10。")
val _ = out ("EVAL ``fib (SUC (SUC 0))`` = "
             ^ (EVAL ``fib (SUC (SUC 0))`` |> concl |> term_to_string))
val _ = out ("  ↑ 把参数写成 SUC 链，求值器先把 SUC (SUC 0) 折成 2，然后就卡住了。")
(* 写法二：用数值模式 + 显式良基关系。这次能算。 *)
Definition fib2_def:
  fib2 n = if n = 0 then 0 else if n = 1 then 1 else fib2 (n - 1) + fib2 (n - 2)
Termination
  WF_REL_TAC `measure I` >> rw [] >> DECIDE_TAC
End
val _ = out (thm_to_string fib2_def)
val _ = out ("EVAL ``fib2 10``       = " ^ (EVAL ``fib2 10`` |> concl |> term_to_string))
val _ = out ("  ↑ 这次算得动：模式是 n = 0 / n = 1，numeral 能直接判定。")

(* ------------------------------------------------------------------ *)
(* 06.5 互递归定义                                                    *)
(* ------------------------------------------------------------------ *)
val _ = sec "06.5 互递归定义"
Definition evenp_def:
  (evenp 0 = T) /\
  (evenp (SUC n) = oddp n) /\
  (oddp 0 = F) /\
  (oddp (SUC n) = evenp n)
End
val _ = out (thm_to_string evenp_def)
val _ = out ("evenp 6 = " ^ (EVAL ``evenp 6`` |> concl |> term_to_string))
val _ = out ("oddp 6  = " ^ (EVAL ``oddp 6`` |> concl |> term_to_string))

(* ------------------------------------------------------------------ *)
(* 06.6 用 _ind 定理跑一次归纳证明                                    *)
(* ------------------------------------------------------------------ *)
val _ = sec "06.6 用 _ind 定理做归纳"
val _ = out (thm_to_string
               (prove(``!l : num list. mylen l = LENGTH l``,
                      Induct_on `l` >> simp [mylen_def])))
val _ = out (thm_to_string
               (prove(``!n : num. (evenp n = T) \/ (evenp n = F)``,
                      Induct_on `n` >> simp [evenp_def])))

(* ------------------------------------------------------------------ *)
(* 06.7 什么时候"它不是结构递归"： onwards                            *)
(* ------------------------------------------------------------------ *)
val _ = sec "06.7 定义必须全覆盖且无重叠"
val _ = out (thm_to_string (DB.fetch "Tut06" "mylen_def"))
val _ = out ("等式 LHS 覆盖了 [] 与 ::，互不重叠 —— TFL 才生成 _eqn 定理。")

val _ = print "\n==== 06 结束 ====\n"

val _ = export_theory ()
