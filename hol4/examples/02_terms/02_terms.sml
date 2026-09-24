(* 02 项、类型与引号

   HOL4 的一切都写在 SML 的字符串化「引号」里：引号内是逻辑层（项 / 类型），
   引号外是元语言层（SML）。本章把这条边界讲清楚。 *)

val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse
open arithmeticTheory listTheory

val _ = new_theory "Tut02"

fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")

val _ = print "\n==== 02 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 02.1 两种引号：``...`` 是项，`...` 是 quotation（片段表）        *)
(* ------------------------------------------------------------------ *)
val _ = sec "02.1 两种引号"
(* 单反引号得到 term frag list（"quotation"）：语法层还没解析成项。
   双反引号得到 term：已经过解析器、带类型。 *)
val q : term frag list = `p /\ q`
val _ = out ("`p /\\ q` 是 term frag list，长度 = " ^ Int.toString (length q))
val _ = out ("其中唯一的片段是 " ^
             (case hd q of QUOTE s => "QUOTE \"" ^ s ^ "\"" | ANTIQUOTE _ => "<antiq>"))
val _ = out ("``p /\\ q`` 是项，类型是 " ^ (type_of ``p /\ q`` |> type_to_string))
val _ = out ("TAUT 直接吃 quotation：" ^ thm_to_string (tautLib.TAUT `p \/ ~p`))

(* ------------------------------------------------------------------ *)
(* 02.2 类型引号：类型也写在引号里                                    *)
(* ------------------------------------------------------------------ *)
val _ = sec "02.2 类型引号"
val _ = out (":num      = " ^ type_to_string ``:num``)
val _ = out (":bool     = " ^ type_to_string ``:bool``)
val _ = out (":num list = " ^ type_to_string ``:num list``)
val _ = out (":num # bool = " ^ type_to_string ``:num # bool``)

(* ------------------------------------------------------------------ *)
(* 02.3 Unicode 打印开关：PP.avoid_unicode                             *)
(* ------------------------------------------------------------------ *)
val _ = sec "02.3 Unicode 打印开关"
val _ = set_trace "PP.avoid_unicode" 1
val _ = out ("avoid_unicode=1: " ^ term_to_string ``!x. x IN s ==> ~(x = 0:num)``)
val _ = set_trace "PP.avoid_unicode" 0
val _ = out ("avoid_unicode=0: " ^ term_to_string ``!x. x IN s ==> ~(x = 0:num)``)

(* ------------------------------------------------------------------ *)
(* 02.4 HOL 与 ML 的三处写法差异                                      *)
(* ------------------------------------------------------------------ *)
val _ = sec "02.4 HOL 与 ML 的写法差异"
val _ = out ("HOL 列表用分号：  " ^ term_to_string ``[1; 2; 3]``)
val _ = out ("HOL 元组用 #：    " ^ type_to_string ``:num # bool``)
val _ = out ("中缀转前缀加 $：  " ^ term_to_string ``($+) 3 4``)
val _ = out ("MAP 一个加法函数： " ^ term_to_string ``MAP ($+ 1) [1; 2; 3]``)
val _ = out ("它的值：          " ^ (EVAL ``MAP ($+ 1) [1; 2; 3]`` |> concl |> term_to_string))

(* ------------------------------------------------------------------ *)
(* 02.5 解析与打印：字符串 ↔ 项                                      *)
(* ------------------------------------------------------------------ *)
val _ = sec "02.5 解析与打印"
val _ = out ("parse： " ^ (Parse.Term [QUOTE "1 + 2"] |> term_to_string))
val _ = out ("回环：  " ^ (term_to_string ``SUC (SUC 0)``))
val _ = out ("再解析： " ^ (Parse.Term [QUOTE (term_to_string ``SUC (SUC 0)``)]
                            |> term_to_string))

(* ------------------------------------------------------------------ *)
(* 02.6 保留词：UNION / INSERT / SUBSET 写成项要加 $                  *)
(* ------------------------------------------------------------------ *)
val _ = sec "02.6 保留词要加 $"
val _ = out ("$UNION  = " ^ (type_of ``$UNION`` |> type_to_string))
val _ = out ("$INSERT = " ^ (type_of ``$INSERT`` |> type_to_string))
val _ = out ("$SUBSET = " ^ (type_of ``$SUBSET`` |> type_to_string))

(* ------------------------------------------------------------------ *)
(* 02.7 类型变量与多态                                                *)
(* ------------------------------------------------------------------ *)
val _ = sec "02.7 多态与类型实例化"
val _ = out ("LENGTH  : " ^ (type_of ``LENGTH`` |> type_to_string))
val _ = out ("LENGTH@num : " ^ (inst [alpha |-> ``:num``] ``LENGTH``
                                 |> type_of |> type_to_string))
val _ = out ("HD      : " ^ (type_of ``HD`` |> type_to_string))

val _ = print "\n==== 02 结束 ====\n"

val _ = export_theory ()
