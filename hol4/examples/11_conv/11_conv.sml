(* 11 转换（conversions）

   转换是「把一个项变成另一个项的定理」的函数：
     conv : term -> thm            （什么都没改时抛 UNCHANGED）
   它是化简器、重写引擎、决策过程的公共接口；战术之所以能动目标，
   多半是因为内部调用了转换。 *)

val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse
open arithmeticTheory listTheory

val _ = new_theory "Tut11"

fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")
(* 转换在"什么都没改"时抛 UNCHANGED，演示必须显式兜住。 *)
fun cr nm (c : conv) t =
  out (nm ^ " : " ^ (thm_to_string (c t)
                     handle UNCHANGED => "<unchanged>"
                          | _ => "<exception>"))

Definition f11_def:
  f11 n = n + 0
End

val _ = print "\n==== 11 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 11.1 转换就是一个函数：项进、等式定理出                            *)
(* ------------------------------------------------------------------ *)
val _ = sec "11.1 基本转换"
val _ = cr "BETA_CONV      " BETA_CONV ``(\x : num. x + 1) 3``
val _ = cr "REWR_CONV      " (REWR_CONV f11_def) ``f11 (2 : num)``
val _ = cr "REWR_CONV GSYM " (REWR_CONV (GSYM f11_def)) ``(2 : num) + 0``
val _ = cr "NO_CONV        " NO_CONV ``1 : num``
val _ = cr "ALL_CONV       " ALL_CONV ``1 : num``

(* ------------------------------------------------------------------ *)
(* 11.2 组合子：THENC / ORELSEC / REPEATC                             *)
(* ------------------------------------------------------------------ *)
val _ = sec "11.2 组合子"
val _ = cr "BETA THENC simp" (BETA_CONV THENC SIMP_CONV (srw_ss ()) [])
           ``(\x : num. x + 1) 3``
val _ = cr "NO ORELSEC ALL " (NO_CONV ORELSEC ALL_CONV) ``1 : num``
val _ = cr "REPEATC        " (REPEATC (REWR_CONV f11_def))
           ``f11 (f11 (2 : num))``
val _ = cr "TRY_CONV       " (TRY_CONV (REWR_CONV f11_def)) ``(2 : num) + 0``
val _ = cr "CHANGED_CONV   " (CHANGED_CONV (REWR_CONV f11_def)) ``f11 (2 : num)``
val _ = cr "QCONV          " (QCONV (REWR_CONV f11_def)) ``(2 : num) + 0``

(* ------------------------------------------------------------------ *)
(* 11.3 深度：ONCE / TOP / DEPTH / REDEPTH                            *)
(* ------------------------------------------------------------------ *)
val _ = sec "11.3 深入到哪一层"
val t11 = ``f11 (f11 (2 : num)) + f11 0``
val _ = cr "ONCE_DEPTH     " (ONCE_DEPTH_CONV (REWR_CONV f11_def)) t11
val _ = cr "TOP_DEPTH      " (TOP_DEPTH_CONV (REWR_CONV f11_def)) t11
val _ = cr "DEPTH_CONV     " (DEPTH_CONV (REWR_CONV f11_def)) t11
val _ = cr "REDEPTH        " (REDEPTH_CONV (REWR_CONV f11_def)) t11

(* ------------------------------------------------------------------ *)
(* 11.4 定位子项：RATOR / RAND / ABS_CONV                             *)
(* ------------------------------------------------------------------ *)
val _ = sec "11.4 指向子项"
val t12 = ``f11 1 + f11 (2 : num)``
val _ = cr "RAND_CONV      " (RAND_CONV (REWR_CONV f11_def)) t12
val _ = cr "RATOR>RAND     " (RATOR_CONV (RAND_CONV (REWR_CONV f11_def))) t12
val _ = cr "ABS_CONV       " (ABS_CONV (REWR_CONV f11_def)) ``\x : num. f11 x``

(* ------------------------------------------------------------------ *)
(* 11.5 CONV_TAC：把转换抬进目标                                      *)
(* ------------------------------------------------------------------ *)
val _ = sec "11.5 CONV_TAC"
(* tactic 在 Trindemossen 里的类型是 goal -> Context.t -> ...，手工调用要递快照。 *)
fun try_tac (tac : tactic) (gl : goal) =
  (SOME (#1 (tac gl (Context.snapshot ()))) handle _ => NONE)
fun fmtg (asms, g) =
  (if null asms then "" else String.concatWith " ∧ " (map term_to_string asms) ^ " ⊢ ")
  ^ term_to_string g
fun fmtgs gls = if null gls then "<closed>"
                else String.concatWith "  ‖  " (map fmtg gls)
fun gl (t : term) : goal = ([], t)
fun show nm tac t =
  out (nm ^ " : " ^ (case try_tac tac (gl t) of
                       NONE => "<tactic failed>"
                     | SOME gls => fmtgs gls))
val _ = show "CONV_TAC 直接打目标  " (CONV_TAC (REWR_CONV f11_def))
             ``f11 (2 : num) = 2``
val _ = show "CONV_TAC SIMP_CONV   " (CONV_TAC (SIMP_CONV (srw_ss ()) [f11_def]))
             ``f11 (f11 (2 : num)) = 2``
val _ = show "CONV_TAC 之后留 T    " (CONV_TAC (SIMP_CONV (srw_ss ()) []) >> simp [])
             ``(\x : num. x + 1) 3 = 4``

(* ------------------------------------------------------------------ *)
(* 11.6 手写一个自己的转换                                            *)
(* ------------------------------------------------------------------ *)
val _ = sec "11.6 手写转换"
(* 展开 f11 之后立刻把加法算掉：两步转换串起来就是一个新转换。 *)
fun unfold_f11 (tm : term) =
  (TRY_CONV (REWR_CONV f11_def) THENC SIMP_CONV (srw_ss ()) []) tm
val _ = cr "unfold_f11     " unfold_f11 ``f11 (3 : num)``
val _ = show "直接打整个目标 " (CONV_TAC unfold_f11 >> simp []) ``f11 (3 : num) = 3``
val _ = show "定位到左边再打 " (CONV_TAC (RATOR_CONV (RAND_CONV unfold_f11)) >> simp [])
             ``f11 (3 : num) = 3``

(* ------------------------------------------------------------------ *)
(* 11.7 化简器与求值器本身也是转换                                    *)
(* ------------------------------------------------------------------ *)
val _ = sec "11.7 化简器与求值器"
val _ = cr "SIMP_CONV      " (SIMP_CONV (srw_ss ()) [f11_def]) ``f11 3 + f11 0``
val _ = cr "arith_ss       " (SIMP_CONV arith_ss []) ``(x : num) < x + 1``
val _ = cr "ARITH_CONV     " numLib.ARITH_CONV ``(3 : num) + 1 = 4``
val _ = cr "EVAL_CONV      " computeLib.EVAL_CONV ``LENGTH [1; 2; 3]``

(* ------------------------------------------------------------------ *)
(* 11.8 转换失败在证明里意味着什么                                    *)
(* ------------------------------------------------------------------ *)
val _ = sec "11.8 失败即不动"
val _ = cr "打不中就原地不动" (REWR_CONV f11_def) ``(2 : num) + 0``
val _ = out ("所以 QCONV / TRY_CONV 才是写脚本时的常态：")
val _ = cr "TRY 兜住       " (TRY_CONV (REWR_CONV f11_def)) ``(2 : num) + 0``

val _ = print "\n==== 11 结束 ====\n"

val _ = export_theory ()
