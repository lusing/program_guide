(* 09 目标栈与基本战术

   交互式开发时，证明是「目标栈」上的一个栈帧：`g` 压栈、`e` 变换栈顶、
   `b` 回退、`drop` 丢弃、`top_thm` 收成品。

   重要事实（实测）：批处理入口（`hol run`）下 `p()` **不打印目标项**，
   只打印 `OK..` / `N subgoals:` / `Goal proved.` 这类状态行。想「看见目标"
   只能自己把目标项打印出来 —— 本章为此造了一个小工具 `step`。 *)

val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse proofManagerLib
open arithmeticTheory listTheory

val _ = new_theory "Tut09"

fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")

(* tactic 的类型是 goal -> Context.t -> goal list * validation，
   手工调用要自己递一个上下文快照。 *)
fun step (tac : tactic) (gl : goal) = #1 (tac gl (Context.snapshot ()))
fun fmtg (asms, g) =
  (if null asms then "" else String.concatWith " ∧ " (map term_to_string asms) ^ " ⊢ ")
  ^ term_to_string g
fun fmtgs gls =
  if null gls then "<closed>"
  else String.concatWith "  ‖  " (map fmtg gls)
(* 只作用在栈顶：这正是 `e` 的语义。 *)
fun top_step tac gls = if null gls then gls else step tac (hd gls) @ tl gls
fun gl (t : term) : goal = ([], t)

val _ = print "\n==== 09 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 09.1 目标栈五件套                                                  *)
(* ------------------------------------------------------------------ *)
val _ = sec "09.1 g / e / p / drop / top_thm"
val _ = drop_all ()
val _ = g `!l : num list. LENGTH (REVERSE l) = LENGTH l`
val _ = p ()
val _ = e (Induct_on `l`)
val _ = p ()
val _ = e (simp [])
val _ = p ()
val _ = e (simp [])
val _ = out ("证完：" ^ thm_to_string (top_thm ()))

(* ------------------------------------------------------------------ *)
(* 09.2 自己把栈打印出来                                              *)
(* ------------------------------------------------------------------ *)
val _ = sec "09.2 自己打印每一步的残余"
val g0 : goal = ([], ``!l : num list. LENGTH (REVERSE l) = LENGTH l``)
val _ = out ("初始   : " ^ fmtgs [g0])
val s1 = step (Induct_on `l`) g0
val _ = out ("Induct : " ^ fmtgs s1)
val s2 = top_step (simp []) s1
val _ = out ("simp#1 : " ^ fmtgs s2)
val s3 = top_step (simp []) s2
val _ = out ("simp#2 : " ^ fmtgs s3)

(* ------------------------------------------------------------------ *)
(* 09.3 六个基本战术                                                  *)
(* ------------------------------------------------------------------ *)
val _ = sec "09.3 六个基本战术"
val conjg : goal = ([], ``!a b : bool. a /\ b ==> b /\ a``)
val _ = out ("strip_tac      : " ^ fmtgs (step strip_tac conjg))
val _ = out ("rpt strip_tac  : " ^ fmtgs (step (rpt strip_tac) conjg))
val _ = out ("conj_tac       : " ^ fmtgs (step conj_tac (gl ``(a : bool) /\ b``)))
val _ = out ("EXISTS_TAC     : " ^ fmtgs (step (qexists_tac `0`)
                                            (gl ``?n : num. n = 0``)))
val _ = out ("DISJ1_TAC      : " ^ fmtgs (step disj1_tac (gl ``a \/ (b : bool)``)))
val _ = out ("EQ_TAC         : " ^ fmtgs (step EQ_TAC (gl ``(a : bool) = b``)))
val _ = out ("Cases_on       : " ^ fmtgs (step (Cases_on `l`)
                                            (gl ``!l : num list. l = l``)))

(* ------------------------------------------------------------------ *)
(* 09.4 旋转与批量：r / all_tac / REPEAT                              *)
(* ------------------------------------------------------------------ *)
val _ = sec "09.4 目标栈上的旋转"
val _ = drop_all ()
val _ = g `(1 : num) = 1 /\ (2 = 2) /\ (3 = 3)`
val _ = e (rpt conj_tac)
val _ = p ()
val _ = r 1   (* r : int -> proof，它直接改当前证明，不是战术 *)
val _ = p ()
val _ = e (simp [])
val _ = p ()
val _ = restart ()
val _ = e (simp [])
val _ = out ("一并处理：" ^ thm_to_string (top_thm ()))

(* ------------------------------------------------------------------ *)
(* 09.5 看不到假设时：打印开关                                        *)
(* ------------------------------------------------------------------ *)
val _ = sec "09.5 打印开关"
val sg : goal = ([], ``(f (x : num) = 1) ==> x = 0 ==> f 0 = 1``)
val _ = out ("默认打印 : " ^ fmtgs (step strip_tac sg))
val _ = set_trace "types" 1
val _ = out ("types=1  : " ^ fmtgs (step strip_tac sg))
val _ = set_trace "types" 0
val _ = out ("关回去   : " ^ fmtgs (step strip_tac sg))

val _ = print "\n==== 09 结束 ====\n"

val _ = export_theory ()
