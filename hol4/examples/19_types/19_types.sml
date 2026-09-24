(* 19 类型

   HOL 的项是**先有类型再有含义**的：`1 + T` 连「错」都算不上，它根本不是
   一个项。这一章看类型的读法、类型缩写、参数化数据类型，以及 HOL 里
   一个很硬的约束：类型变量不能被「定义」出来。 *)

val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse
open arithmeticTheory listTheory optionTheory sumTheory

val _ = new_theory "Tut19"

fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")
fun p t tac = thm_to_string (prove (t, tac))
fun ev t = EVAL t |> concl |> term_to_string
fun ty t = type_to_string (type_of t)
fun tyq q = type_to_string q
fun th thy n = thm_to_string (DB.fetch thy n)

val _ = print "\n==== 19 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 19.1 类型的读法                                                    *)
(* ------------------------------------------------------------------ *)
val _ = sec "19.1 类型怎么看"
val _ = out ("``:num``        : " ^ tyq ``:num``)
val _ = out ("``:bool``       : " ^ tyq ``:bool``)
val _ = out ("``:num -> num`` : " ^ tyq ``:num -> num``)
val _ = out ("``:num # bool`` : " ^ tyq ``:num # bool``)
val _ = out ("``:num list``   : " ^ tyq ``:num list``)
val _ = out ("``:'a``         : " ^ tyq ``:'a``)
val _ = out ("type_of ``1``           : " ^ ty ``1 : num``)
val _ = out ("type_of ``\\x. x``      : " ^ ty ``\x. x``)
val _ = out ("type_of ``MAP``         : " ^ ty ``MAP``)
val _ = out ("type_of ``\\x. x + 1``  : " ^ ty ``\(x : num). x + 1``)
val _ = out ("``1`` 不带标注时是 : " ^ ty ``1``)
val _ = out ("（数字默认 num，比较运算会把它钉成 num；"
             ^ "真正的多态常量如 MAP 打印出 α β。）")

(* ------------------------------------------------------------------ *)
(* 19.2 拆类型                                                        *)
(* ------------------------------------------------------------------ *)
val _ = sec "19.2 拆开一个类型"
val _ = out ("dest_type ``:num list`` = " ^
  (let val (s, l) = dest_type ``:num list``
   in s ^ " [" ^ String.concatWith ", " (map type_to_string l) ^ "]" end))
val _ = out ("dom_rng ``:num -> bool`` 的定义域 = " ^
             type_to_string (#1 (dom_rng ``:num -> bool``)))
val _ = out ("dom_rng ``:num -> bool`` 的值域 = " ^
             type_to_string (#2 (dom_rng ``:num -> bool``)))
val _ = out ("is_vartype ``:'a``  = " ^ Bool.toString (is_vartype ``:'a``))
val _ = out ("is_vartype ``:num`` = " ^ Bool.toString (is_vartype ``:num``))

(* ------------------------------------------------------------------ *)
(* 19.3 类型不匹配是什么样子                                          *)
(* ------------------------------------------------------------------ *)
val _ = sec "19.3 类型不匹配"
val _ = out ("拿 bool 当 num 用，mk_comb 直接拒绝：")
val _ = out ("  " ^ ((term_to_string (mk_comb (``$+ : num -> num -> num``, ``T``)))
                     handle e => "<" ^ exn_to_string e ^ ">"))
val _ = out ("注意措辞是 incompatible types —— 它连算一算都不肯，"
             ^ "因为项根本没构造出来。")
val _ = out ("反过来，类型对了才能谈值：")
val _ = out ("  " ^ ev ``(1 : num) + 2``)

(* ------------------------------------------------------------------ *)
(* 19.4 类型缩写                                                      *)
(* ------------------------------------------------------------------ *)
val _ = sec "19.4 类型缩写 type_abbrev"
val _ = type_abbrev ("pnum", ``:num # num``)
val _ = out ("缩写只是个名字，打印时会被展开：")
val _ = out ("  " ^ tyq ``: pnum``)
val _ = out ("所以 ``:pnum`` 和 ``:num # num`` 是同一个类型：")
val _ = out ("  " ^ Bool.toString (``: pnum`` = ``: num # num``))
val _ = out ("用到缩写上的函数照常工作：")
Definition swap_def:
  swap (pp : pnum) = (SND pp, FST pp)
End
val _ = out ("  " ^ thm_to_string swap_def)
val _ = out ("  " ^ ev ``swap (1, 2)``)

(* ------------------------------------------------------------------ *)
(* 19.5 参数化数据类型                                                *)
(* ------------------------------------------------------------------ *)
val _ = sec "19.5 参数化数据类型"
(* 类型参数不写在左边：HOL4 从右边出现的类型变量推断出来。
   写成 `tree 'a = ...` 会被拒：to_tyspecs: Omit arguments to new type *)
val _ = Datatype `tree = Lf | Nd tree 'a tree`
val _ = out ("类型：" ^ tyq ``: 'a tree``)
val _ = out ("构造子 Nd 的类型：" ^ ty ``Nd``)
val _ = out ("tree_induction：")
val _ = out ("  " ^ th "Tut19" "tree_induction")
val _ = out ("tree_nchotomy：")
val _ = out ("  " ^ th "Tut19" "tree_nchotomy")
val _ = out ("tree_11（注入性）：")
val _ = out ("  " ^ th "Tut19" "tree_11")
val _ = out ("tree_Axiom（原始递归原理）：")
val _ = out ("  " ^ th "Tut19" "tree_Axiom")

(* ------------------------------------------------------------------ *)
(* 19.6 多态数据类型上的函数                                          *)
(* ------------------------------------------------------------------ *)
val _ = sec "19.6 在多态类型上写函数"
Definition tsize_def:
  (tsize Lf = 0) /\
  (tsize (Nd l a r) = tsize l + tsize r + 1)
End
val _ = out (thm_to_string tsize_def)
val _ = out ("tsize 的类型：" ^ ty ``tsize``)
val _ = out ("求值：" ^ ev ``tsize (Nd Lf (9 : num) (Nd Lf 8 Lf))``)
val _ = out ("tsize Lf 归零："
             ^ p ``!t : num tree. tsize t = 0 ==> t = Lf``
                 (Cases >> rw [tsize_def] >> DECIDE_TAC))

(* ------------------------------------------------------------------ *)
(* 19.7 内置的多态类型                                                *)
(* ------------------------------------------------------------------ *)
val _ = sec "19.7 内置的 option / sum"
val _ = out ("``:num option`` = " ^ tyq ``:num option``)
val _ = out ("option_nchotomy : " ^ th "option" "option_nchotomy")
val _ = out ("THE             : " ^ th "option" "THE_DEF")
val _ = out ("OPTION_MAP      : " ^ th "option" "OPTION_MAP_DEF")
val _ = out ("``:num + bool`` = " ^ tyq ``:num + bool``)
val _ = out ("sum_case        : " ^ th "sum" "sum_case_def")
val _ = out ("（option/sum 的定理在 optionTheory / sumTheory，不在 listTheory。）")

val _ = print "\n==== 19 结束 ====\n"

val _ = export_theory ()
