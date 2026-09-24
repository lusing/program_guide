(* 14 量词与一阶自动化

   `simp` 管重写，`metis`/`PROVE_TAC` 管一阶推理。本章划清二者的分工，
   并演示「自动化到不了的地方」是什么样子。 *)

val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse
open arithmeticTheory listTheory

val _ = new_theory "Tut14"

fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")
fun p t tac = thm_to_string (prove (t, tac))
fun try_tac (tac : tactic) (gl : goal) =
  (SOME (#1 (tac gl (Context.snapshot ()))) handle _ => NONE)
fun gl (t : term) : goal = ([], t)
fun show nm tac t =
  out (nm ^ " : " ^ (case try_tac tac (gl t) of
                       NONE => "<tactic failed>"
                     | SOME [] => "<closed>"
                     | SOME gls => String.concatWith "  ‖  "
                         (map (fn (asms, g) =>
                            (if null asms then "" else
                               String.concatWith " ∧ " (map term_to_string asms) ^ " ⊢ ")
                            ^ term_to_string g) gls)))

val _ = print "\n==== 14 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 14.1 纯命题：PROVE_TAC 与 TAUT                                     *)
(* ------------------------------------------------------------------ *)
val _ = sec "14.1 纯命题"
val _ = out (p ``(a : bool) /\ b ==> b`` (PROVE_TAC []))
val _ = out (thm_to_string (tautLib.TAUT_PROVE ``(a : bool) \/ ~a``))
val _ = out ("排中律也可以由 rw 证明：" ^ p ``(a : bool) \/ ~a`` (rw []))
val _ = out (p ``((a : bool) ==> b) ==> ~b ==> ~a`` (PROVE_TAC []))

(* ------------------------------------------------------------------ *)
(* 14.2 metis_tac：全称量化 + 传递性                                  *)
(* ------------------------------------------------------------------ *)
val _ = sec "14.2 metis_tac"
val _ = out (p ``(!x : num. P x ==> Q x) ==> (!x. P x) ==> !x. Q x``
               (metis_tac []))
val _ = out (p ``(!x y z : num. R x y /\ R y z ==> R x z) ==>
                R a b ==> R b c ==> R a c`` (metis_tac []))
val _ = out (p ``(?x : num. P x) ==> (?x. P x \/ Q x)`` (metis_tac []))

(* ------------------------------------------------------------------ *)
(* 14.3 存在量词：给出 witness                                        *)
(* ------------------------------------------------------------------ *)
val _ = sec "14.3 存在量词"
val _ = out (p ``?n : num. n > 0`` (qexists_tac `1` >> rw []))
val _ = out (p ``!m : num. ?n. n > m`` (strip_tac >> qexists_tac `m + 1` >> rw []))
val _ = show "忘了 witness " (metis_tac []) ``?n : num. n > 0``

(* ------------------------------------------------------------------ *)
(* 14.4 二者的分工：simp 重写，metis 推理                             *)
(* ------------------------------------------------------------------ *)
val _ = sec "14.4 分工"
Definition step_def:
  step x = x + 1
End
val _ = show "只 simp   " (simp [step_def]) ``(step (x : num) = x + 2) ==> F``
val _ = show "只 metis  " (metis_tac []) ``(step (x : num) = x + 2) ==> F``
val _ = show "simp>>met " (simp [step_def] >> metis_tac [])
           ``(step (x : num) = x + 2) ==> x + 1 = x + 2``

(* ------------------------------------------------------------------ *)
(* 14.5 自动化的边界：需要归纳的地方                                  *)
(* ------------------------------------------------------------------ *)
val _ = sec "14.5 边界"
val _ = show "metis 直上" (metis_tac []) ``!l : num list. LENGTH (REVERSE l) = LENGTH l``
val _ = out ("换成归纳  ：" ^ p ``!l : num list. LENGTH (REVERSE l) = LENGTH l``
               (Induct_on `l` >> rw []))
val _ = show "线性算术 rw 过 " (rw []) ``!n : num. n + n >= n``
val _ = show "非线性 rw 不灵" (rw []) ``!n : num. n * n >= n``
val _ = out ("非线性项（乘法）一旦出现在归纳假设里，决策过程也接不住：")
val _ = out ("  ∀n. n * n ≥ n 需要归纳 + 单调性引理，不是一条 rw 能收掉的事。")

(* ------------------------------------------------------------------ *)
(* 14.6 一阶自动化的代价：给它多少它就多慢                            *)
(* ------------------------------------------------------------------ *)
val _ = sec "14.6 代价"
val _ = out ("把已知定理喂给 metis：" ^
             p ``!a b c : num. a <= b ==> b <= c ==> a <= c``
               (metis_tac [LESS_EQ_TRANS]))
val _ = show "什么都不喂    " (metis_tac [])
             ``!a b c : num. a <= b ==> b <= c ==> a <= c``
val _ = out ("rw 也能收（它内部装着传递性）：" ^
             p ``!a b c : num. a <= b ==> b <= c ==> a <= c`` (rw []))

val _ = print "\n==== 14 结束 ====\n"

val _ = export_theory ()
