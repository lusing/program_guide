(* 05 数据类型

   `Datatype` 不只是一个类型声明：它会一次性证明并存入一组定理
   （区分性、单射性、穷举、归纳原理、case 合同性）。本章把这些「赠品"
   全部列出来，并演示它们在证明里怎么用。 *)

val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse
open arithmeticTheory listTheory

val _ = new_theory "Tut05"

fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")
fun names pfx =
  String.concatWith " " (List.filter (fn n => String.isPrefix pfx n)
                                     (map #1 (DB.theorems "Tut05")))

val _ = print "\n==== 05 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 05.1 一个最普通的数据类型                                          *)
(* ------------------------------------------------------------------ *)
val _ = sec "05.1 定义一个数据类型"
val _ = Datatype `bt = Lf | Nd bt num bt`
val _ = out ("Nd 的类型：" ^ (type_of ``Nd`` |> type_to_string))
val _ = out ("Lf 的类型：" ^ (type_of ``Lf`` |> type_to_string))

(* ------------------------------------------------------------------ *)
(* 05.2 Datatype 送的定理                                             *)
(* ------------------------------------------------------------------ *)
val _ = sec "05.2 自动生成了哪些定理"
val _ = out ("bt_ 前缀：" ^ names "bt_")
val _ = out ("datatype 前缀：" ^ names "datatype")

(* ------------------------------------------------------------------ *)
(* 05.3 它们各是什么                                                  *)
(* ------------------------------------------------------------------ *)
val _ = sec "05.3 三件赠品：distinct / 11 / nchotomy"
val _ = out (thm_to_string (DB.fetch "Tut05" "bt_distinct"))
val _ = out (thm_to_string (DB.fetch "Tut05" "bt_11"))
val _ = out (thm_to_string (DB.fetch "Tut05" "bt_nchotomy"))

(* ------------------------------------------------------------------ *)
(* 05.4 case 表达式                                                   *)
(* ------------------------------------------------------------------ *)
val _ = sec "05.4 case 表达式"
val _ = out (term_to_string ``case t of Lf => 0 | Nd l n r => n``)
val _ = out (thm_to_string (EVAL ``case Nd Lf 5 Lf of Lf => 0 | Nd l n r => n``))
val _ = out ("case 的合同性定理：" ^ thm_to_string (DB.fetch "Tut05" "bt_case_cong"))

(* ------------------------------------------------------------------ *)
(* 05.5 用 nchotomy 与 distinct 做证明                                *)
(* ------------------------------------------------------------------ *)
val _ = sec "05.5 用赠品做证明"
val _ = out (thm_to_string
               (prove(``!t : bt. ~(t = Lf) ==> ?l n r. t = Nd l n r``,
                      Cases_on `t` >> simp [] >> metis_tac [])))
val _ = out (thm_to_string
               (prove(``!l (n : num) r l' n' r'. Nd l n r = Nd l' n' r' ==> n = n'``,
                      simp [])))

(* ------------------------------------------------------------------ *)
(* 05.6 多态数据类型与列表                                            *)
(* ------------------------------------------------------------------ *)
val _ = sec "05.6 多态数据类型"
(* 类型参数不用显式声明：构造器参数里出现的 quoted 类型变量（'a）会被
   自动提升为类型参数。 *)
val _ = Datatype `mytree = Leaf | Node 'a mytree mytree`
val _ = out ("Node : " ^ (type_of ``Node`` |> type_to_string))
val _ = out ("生成定理：" ^ names "mytree_")

(* ------------------------------------------------------------------ *)
(* 05.7 互递归数据类型                                                *)
(* ------------------------------------------------------------------ *)
val _ = sec "05.7 互递归数据类型"
val _ = Datatype `
  evenlist = ENil | ECons num oddlist ;
  oddlist  = OCons num evenlist`
val _ = out ("ECons : " ^ (type_of ``ECons`` |> type_to_string))
val _ = out ("OCons : " ^ (type_of ``OCons`` |> type_to_string))
val _ = out ("生成定理：" ^ names "evenlist_" ^ " | " ^ names "oddlist_")

val _ = print "\n==== 05 结束 ====\n"

val _ = export_theory ()
