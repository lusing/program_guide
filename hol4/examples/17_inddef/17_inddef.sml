(* 17 归纳定义（Hol_reln）

   `Datatype` 定义数据，`Definition` 定义函数，而「由规则生成的谓词"
   用 `Hol_reln`。它会一次性给出四样东西：规则、case 分析、
   规则归纳、强归纳。 *)

val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse
open arithmeticTheory listTheory relationTheory

val _ = new_theory "Tut17"

fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")
fun p t tac = thm_to_string (prove (t, tac))
fun tnames pfx =
  String.concatWith " " (List.filter (fn n => String.isPrefix pfx n)
                                     (map #1 (DB.theorems "Tut17")))

val _ = print "\n==== 17 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 17.1 用规则定义一个谓词                                            *)
(* ------------------------------------------------------------------ *)
val _ = sec "17.1 Hol_reln"
val _ = Hol_reln `even 0 /\ (!n. even n ==> even (n + 2))`
val _ = out ("生成的定理：" ^ tnames "even_")
val _ = out (thm_to_string (DB.fetch "Tut17" "even_rules"))

(* ------------------------------------------------------------------ *)
(* 17.2 用规则构造实例                                                *)
(* ------------------------------------------------------------------ *)
val _ = sec "17.2 用规则证实例"
(* even_rules 是一个合取，先把两条规则拆出来。 *)
val even_rules = DB.fetch "Tut17" "even_rules"
val even0   = CONJUNCT1 even_rules
val evenstep = CONJUNCT2 even_rules
(* 递推一次：MATCH_MP 给出 even (n + 2)，再用 SIMP_CONV 把算术化简掉。 *)
fun step_even th = CONV_RULE (SIMP_CONV arith_ss []) (MATCH_MP evenstep th)
val e2 = step_even even0
val e4 = step_even e2
val e6 = step_even e4
val _ = out (thm_to_string e2)
val _ = out (thm_to_string e4)
val _ = out (thm_to_string e6)
(* 拆开之后，一步能到的目标 metis_tac 自己就找得到 --
   注意它做的是纯一阶匹配，even 4 要先化算术，所以它办不到。 *)
val _ = out ("一步可及："
             ^ p ``even (0 + 2)`` (metis_tac [even0, evenstep]))

(* ------------------------------------------------------------------ *)
(* 17.3 case 分析：从"它是怎么来的"倒推                               *)
(* ------------------------------------------------------------------ *)
val _ = sec "17.3 cases 定理"
val _ = out (thm_to_string (DB.fetch "Tut17" "even_cases"))
val _ = out (p ``even 1 ==> F``
               (strip_tac >> imp_res_tac (DB.fetch "Tut17" "even_cases")
                >> rw [] >> DECIDE_TAC))

(* ------------------------------------------------------------------ *)
(* 17.4 规则归纳                                                      *)
(* ------------------------------------------------------------------ *)
val _ = sec "17.4 规则归纳"
val _ = out (thm_to_string (DB.fetch "Tut17" "even_ind"))
val _ = out ("偶数的 n 都能被 2 整除：" ^
             p ``!n. even n ==> EVEN n``
               (ho_match_mp_tac (DB.fetch "Tut17" "even_ind") >> rw []
                >> rw [EVEN_ADD]))

(* ------------------------------------------------------------------ *)
(* 17.5 强归纳版本                                                    *)
(* ------------------------------------------------------------------ *)
val _ = sec "17.5 强归纳"
val _ = out (thm_to_string (DB.fetch "Tut17" "even_strongind"))

(* ------------------------------------------------------------------ *)
(* 17.6 带参数的归纳定义：闭包                                        *)
(* ------------------------------------------------------------------ *)
val _ = sec "17.6 一个关系上的归纳定义"
val _ = Hol_reln `path (R : num -> num -> bool) x x /\
                  (!y z. path R x y /\ R y z ==> path R x z)`
val _ = out ("生成的定理：" ^ tnames "path_")
val _ = out (thm_to_string (DB.fetch "Tut17" "path_rules"))
val _ = out (thm_to_string (DB.fetch "Tut17" "path_ind"))
(* 注意目标的形状：R 和 x 留在项里当自由变量，只把"被归纳的那个"写成 ∀y。
   如果写成 !R x y. path R x y ==> RTC R x y，ho_match_mp_tac 会报 not a comb。 *)
val _ = out ("path 就是可达（⊆ RTC）：" ^
             p ``!y. path (R : num -> num -> bool) x y ==> RTC R x y``
               (ho_match_mp_tac (DB.fetch "Tut17" "path_ind")
                >> rw [RTC_REFL] >> metis_tac [RTC_TRANS, RTC_SINGLE]))
(* 反方向：RTC 的归纳定理库里现成，但要挑"从右边加一步"的那个。
   RTC_INDUCT 是从左边加一步（R x y /\ P y z），跟 path 的构造方向对不上。 *)
val _ = out ("RTC_INDUCT        : " ^ thm_to_string RTC_INDUCT)
val _ = out ("RTC_INDUCT_RIGHT1 : " ^ thm_to_string RTC_INDUCT_RIGHT1)
val _ = out ("path_rules 拆开：")
val _ = out ("  自反 " ^ thm_to_string (CONJUNCT1 (SPEC_ALL (DB.fetch "Tut17" "path_rules"))))
val _ = out ("  步进 " ^ thm_to_string (CONJUNCT2 (SPEC_ALL (DB.fetch "Tut17" "path_rules"))))
val _ = out ("反过来 RTC ⊆ path：" ^
             p ``!x y. RTC (R : num -> num -> bool) x y ==> path R x y``
               (ho_match_mp_tac RTC_INDUCT_RIGHT1 >> rw []
                >> metis_tac [CONJUNCT1 (SPEC_ALL (DB.fetch "Tut17" "path_rules")),
                              CONJUNCT2 (SPEC_ALL (DB.fetch "Tut17" "path_rules"))]))

(* ------------------------------------------------------------------ *)
(* 17.7 归纳定义 vs 递归函数                                          *)
(* ------------------------------------------------------------------ *)
val _ = sec "17.7 什么时候用哪个"
val _ = out ("规则生成的是「最小集合」（归纳的），函数是「确定性计算」（递归的）。")
val _ = out ("差别：even 4 要用规则推两步；evenf 4 直接算。")
Definition evenf_def:
  evenf n = (n MOD 2 = 0)
End
val _ = out (thm_to_string evenf_def)
val _ = out ("求值：" ^ (EVAL ``evenf 7`` |> concl |> term_to_string))
val _ = out ("把两边的偶数概念接起来：")
val _ = out (p ``!n. even n ==> evenf n``
               (ho_match_mp_tac (DB.fetch "Tut17" "even_ind") >> rw [evenf_def]
                >> rw [EVEN_ADD]))
val _ = out ("（反方向要说明「能被 2 整除的数都能推出来」，留给练习。）")

val _ = print "\n==== 17 结束 ====\n"

val _ = export_theory ()
