(* 10 战术算子：把战术当值来组合

   单个战术只能解决一步；真正的证明脚本是「战术 + 算子」的表达式。
   本章把六个算子逐个放在同一个目标上，用残余目标对比它们干了什么。 *)

val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse
open arithmeticTheory listTheory

val _ = new_theory "Tut10"

fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")
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

val _ = print "\n==== 10 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 10.1 THEN：`>>`（gentactic 版）与 `THEN`（tactic 版）             *)
(* ------------------------------------------------------------------ *)
val _ = sec "10.1 THEN：顺序作用到所有子目标"
val t1 = ``(T : bool) /\ b``
val _ = show "conj_tac          " conj_tac t1
val _ = show "conj_tac THEN simp" (conj_tac THEN simp []) t1
val _ = show "conj_tac >> simp  " (conj_tac >> simp []) t1
val _ = show "simp 单独         " (simp []) t1

(* ------------------------------------------------------------------ *)
(* 10.2 THENL：给每个子目标分别发一张牌                              *)
(* ------------------------------------------------------------------ *)
val _ = sec "10.2 THENL：按位置发不同的战术"
val t2 = ``(T : bool) /\ (c = (c : bool))``
val _ = show "THENL [simp,all]  " (conj_tac THENL [simp [], all_tac]) t2
val _ = show "THENL [all,simp]  " (conj_tac THENL [all_tac, simp []]) t2
val _ = show "THENL 数量不对    " (conj_tac THENL [all_tac]) t2

(* ------------------------------------------------------------------ *)
(* 10.3 >- ：把第 1 个子目标单独提出来管                              *)
(* ------------------------------------------------------------------ *)
val _ = sec "10.3 >- 只管第一个子目标"
val _ = show "conj_tac >- simp  " (conj_tac >- simp []) t2
val _ = show "(>- 后再 >>)      " (conj_tac >- simp [] >> all_tac) t2

(* ------------------------------------------------------------------ *)
(* 10.4 ORELSE：失败就换一条                                          *)
(* ------------------------------------------------------------------ *)
val _ = sec "10.4 ORELSE"
val _ = show "disj1_tac         " disj1_tac ``(a : bool) \/ b``
val _ = show "conj_tac || disj  " (conj_tac ORELSE disj1_tac) ``(a : bool) \/ b``
val _ = show "conj_tac || and   " (conj_tac ORELSE disj1_tac) ``(a : bool) /\ b``

(* ------------------------------------------------------------------ *)
(* 10.5 TRY / REPEAT / NTAC                                           *)
(* ------------------------------------------------------------------ *)
val _ = sec "10.5 TRY / REPEAT / NTAC"
val _ = show "TRY disj1_tac     " (TRY disj1_tac) ``(a : bool) \/ b``
val _ = show "TRY conj_tac      " (TRY conj_tac) ``(a : bool) \/ b``
val _ = show "REPEAT strip_tac  " (REPEAT strip_tac) ``!a b : bool. a /\ b ==> b``
val _ = show "NTAC 2 strip_tac  " (NTAC 2 strip_tac) ``!a b : bool. a /\ b ==> b``
val _ = show "NTAC 1 strip_tac  " (NTAC 1 strip_tac) ``!a b : bool. a /\ b ==> b``

(* ------------------------------------------------------------------ *)
(* 10.6 FIRST：按顺序试到第一条能动的                                 *)
(* ------------------------------------------------------------------ *)
val _ = sec "10.6 FIRST"
val _ = show "FIRST [conj,disj] " (FIRST [conj_tac, disj1_tac]) ``(a : bool) \/ b``
val _ = show "FIRST [disj,conj] " (FIRST [disj1_tac, conj_tac]) ``(a : bool) \/ b``

(* ------------------------------------------------------------------ *)
(* 10.7 ALLGOALS：对所有当前子目标做同一件事                          *)
(* ------------------------------------------------------------------ *)
val _ = sec "10.7 ALLGOALS"
(* list_tactic 作用于"目标列表"，跟 tactic 作用于是另一个类型，
   所以 ALLGOALS 不能直接接在 THEN 右边 —— 先跑 conj_tac 拿到列表，
   再把 list_tactic 作用上去。 *)
val gls0 = #1 (conj_tac (gl ``(T : bool) /\ T``) (Context.snapshot ()))
val _ = out ("conj_tac 之后   : " ^ fmtgs gls0)
val _ = out ("ALLGOALS assume : " ^
             fmtgs (#1 ((ALLGOALS (assume_tac (ASSUME ``T``))) gls0
                          (Context.snapshot ()))))
val _ = show "一步到位          " (rpt conj_tac >> simp []) ``(T : bool) /\ T /\ T``

(* ------------------------------------------------------------------ *)
(* 10.8 组合起来的真实样子                                            *)
(* ------------------------------------------------------------------ *)
val _ = sec "10.8 一个真实的组合"
val _ = out (thm_to_string
               (prove(``!l : num list. LENGTH (MAP (\x. x + 1) l) = LENGTH l``,
                      Induct_on `l` >> simp [])))
val _ = out (thm_to_string
               (prove(``!l : num list. ~NULL l ==> ?h t. l = h :: t``,
                      Cases_on `l` >> simp [] >> metis_tac [])))

val _ = print "\n==== 10 结束 ====\n"

val _ = export_theory ()
