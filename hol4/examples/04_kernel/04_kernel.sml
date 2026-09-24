(* 04 内核：定理与推导规则

   HOL4 的可靠性来自「小内核」：所有定理最终都由少数几条原始规则造出来。
   本章不用任何战术，只用规则手工搭几个定理，看清 thm 到底是什么。 *)

val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse
open arithmeticTheory

val _ = new_theory "Tut04"

fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")

val _ = print "\n==== 04 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 04.1 定理 = 假设集合 + 结论                                         *)
(* ------------------------------------------------------------------ *)
val _ = sec "04.1 定理的三要素"
val th = ASSUME ``p : bool``
val _ = out (thm_to_string th)
val _ = out ("hyp   长度 = " ^ Int.toString (length (hyp th)))
val _ = out ("concl      = " ^ (concl th |> term_to_string))
val _ = out ("dest_thm   = " ^ Int.toString (length (#1 (dest_thm th))) ^ " 条假设")

(* ------------------------------------------------------------------ *)
(* 04.2 自反、对称、传递                                               *)
(* ------------------------------------------------------------------ *)
val _ = sec "04.2 REFL / SYM / TRANS"
val _ = out (thm_to_string (REFL ``1 : num``))
val _ = out (thm_to_string (SYM (REFL ``1 : num``)))
val ab = ASSUME ``(a : num) = b``
val bc = ASSUME ``(b : num) = c``
val _ = out (thm_to_string (TRANS ab bc))

(* ------------------------------------------------------------------ *)
(* 04.3 合同性：MK_COMB / AP_TERM / AP_THM                             *)
(* ------------------------------------------------------------------ *)
val _ = sec "04.3 合同性"
val _ = out (thm_to_string (AP_TERM ``SUC`` ab))
val _ = out (thm_to_string (AP_THM (REFL ``(f : num -> bool)``) ``x : num``))
val _ = out (thm_to_string (MK_COMB (REFL ``(f : num -> bool)``, ab)))

(* ------------------------------------------------------------------ *)
(* 04.4 抽象与 β：ABS / BETA_CONV                                     *)
(* ------------------------------------------------------------------ *)
val _ = sec "04.4 抽象与 β"
val _ = out (thm_to_string (BETA_CONV ``(\x : num. x + 1) 3``))
val _ = out (thm_to_string (ABS ``x : num`` (REFL ``x : num``)))

(* ------------------------------------------------------------------ *)
(* 04.5 蕴含：ASSUME / DISCH / MP                                      *)
(* ------------------------------------------------------------------ *)
val _ = sec "04.5 蕴含"
val imp = DISCH ``p : bool`` (ASSUME ``p : bool``)
val _ = out (thm_to_string imp)
val _ = out (thm_to_string (MP imp (ASSUME ``p : bool``)))
val _ = out (thm_to_string (IMP_TRANS (ASSUME ``(p : bool) ==> q``)
                                      (ASSUME ``q ==> r``)))

(* ------------------------------------------------------------------ *)
(* 04.6 实例化与推广：SPEC / GEN / INST                                *)
(* ------------------------------------------------------------------ *)
val _ = sec "04.6 量化"
val allth = ASSUME ``!(n : num). P n``
val _ = out (thm_to_string (SPEC ``3 : num`` allth))
val _ = out (thm_to_string (GEN ``n : num`` (SPEC ``n : num`` allth)))
val _ = out (thm_to_string (INST [``P : num -> bool`` |-> ``Q : num -> bool``] allth))

(* ------------------------------------------------------------------ *)
(* 04.7 纯手工搭一条定理：                                             *)
(*       从 f = g 推出 f x = g x                                       *)
(* ------------------------------------------------------------------ *)
val _ = sec "04.7 手工搭一条定理"
val fg = ASSUME ``(f : num -> bool) = g``
val manual = MK_COMB (fg, REFL ``x : num``)
val _ = out (thm_to_string manual)
val _ = out ("它和战术版本等价：" ^
             thm_to_string (prove(``(f : num -> bool) = g ==> f x = g x``,
                                  DISCH_TAC >> ASM_REWRITE_TAC [])))

(* ------------------------------------------------------------------ *)
(* 04.8 内核的边界：mk_thm 是 oracle，会被打标                         *)
(* ------------------------------------------------------------------ *)
val _ = sec "04.8 oracle 会被打标"
val real = prove(``1 = 1``, simp [])
val _ = out ("真证明的 oracle 标记：NONE? " ^
             (case Theory.oracle_string_of real of NONE => "是" | SOME s => "否：" ^ s))
val _ = out ("内核只接受规则造出来的定理；mk_thm 能凭空造，但会留下标记。")

val _ = print "\n==== 04 结束 ====\n"

val _ = export_theory ()
