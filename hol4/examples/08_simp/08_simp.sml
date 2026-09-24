(* 08 化简器

   HOL4 的日常工作里 80% 的工作是「把式子推到可以直接看出来的形状」，
   干这件事的是化简器。本章把 simp 家族逐个排开，用「残余目标」而不是
   "成功/失败「来对比它们。 *)

val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse
open arithmeticTheory listTheory

val _ = new_theory "Tut08"

fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")
fun p t tac = thm_to_string (prove (t, tac))

(* 残余目标：把"战术做完了还剩下什么"打印出来，比成功/失败信息量大得多。
   tactic 的类型是 goal -> goal list * validation，直接调用即可。 *)
(* HOL4 Trindemossen 里 tactic 的类型是
     goal -> Context.t -> goal list * validation
   手工调用时要自己递一个上下文快照进去。 *)
fun try_tac (tac : tactic) (gl : goal) =
  (SOME (#1 (tac gl (Context.snapshot ()))) handle _ => NONE)
fun residual t tac =
  case try_tac tac ([], t) of
    NONE => "<tactic failed>"
  | SOME [] => "<closed>"
  | SOME gls =>
      String.concatWith "  ‖  "
        (map (fn (asms, g) =>
                (if null asms then "" else
                   String.concatWith " ∧ " (map term_to_string asms) ^ " ⊢ ")
                ^ term_to_string g) gls)

val _ = print "\n==== 08 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 08.1 五兄弟：simp / rw / fs / gs / gvs                             *)
(* ------------------------------------------------------------------ *)
val _ = sec "08.1 五兄弟在同一批目标上的残余"
fun cmp nm g =
  (out ("-- " ^ nm ^ " : " ^ term_to_string g);
   out ("   simp[] : " ^ residual g (simp []));
   out ("   rw[]   : " ^ residual g (rw []));
   out ("   fs[]   : " ^ residual g (fs []));
   out ("   gs[]   : " ^ residual g (gs []));
   out ("   gvs[]  : " ^ residual g (gvs [])))
val _ = cmp "假设替换" ``(x : num) = 1 ==> f x = f 1``
val _ = cmp "假设互推" ``(f (x : num) = 1) ==> (x = 2) ==> f 2 = 1``
val _ = cmp "量词与合取" ``!a b : bool. a /\ b ==> b /\ a``
val _ = cmp "算术边界" ``(x : num) <= y ==> x < y``
val _ = cmp "条件未被分裂" ``!n : num. (if n = 0 then 0 else 1) <= 1``

(* ------------------------------------------------------------------ *)
(* 08.2 化简不等于引入蕴含：先把 ⇒ 拆开，假设才进得了 simpset         *)
(* ------------------------------------------------------------------ *)
val _ = sec "08.2 假设是一堆重写规则：几次传球才到位"
val g2 = ``(x : num) = a + 1 ==> (a = b + 1) ==> (b = 0) ==> x = 2``
val _ = out ("目标          : " ^ term_to_string g2)
val _ = out ("直接 fs[]     : " ^ residual g2 (fs []))
val _ = out ("先拆再 fs[]   : " ^ residual g2 (strip_tac >> fs []))
val _ = out ("先拆再 gs[]   : " ^ residual g2 (strip_tac >> gs []))
val _ = out ("先拆再 rw[]   : " ^ residual g2 (strip_tac >> rw []))

(* ------------------------------------------------------------------ *)
(* 08.3 simp 是"有方向的"：只用方程的一侧                             *)
(* ------------------------------------------------------------------ *)
val _ = sec "08.3 方向性"
Definition twice_def:
  twice n = n + n
End
(* 转换可能抛 UNCHANGED —— 作为演示必须显式兜住。 *)
fun convres nm c t =
  out (nm ^ " : " ^ (thm_to_string (c t) handle UNCHANGED => "<unchanged>"))
val _ = out ("twice_def : " ^ thm_to_string twice_def)
val _ = out ("默认方向  : " ^ (EVAL ``twice 3`` |> concl |> term_to_string))
val _ = convres "数字上反向" (SIMP_CONV (srw_ss ()) [Once twice_def]) ``6 : num``
val _ = convres "显式反向  " (SIMP_CONV (srw_ss ()) [GSYM twice_def]) ``3 + 3``

(* ------------------------------------------------------------------ *)
(* 08.4 simp only：只许用我给的                                       *)
(* ------------------------------------------------------------------ *)
val _ = sec "08.4 simp only"
val _ = out ("simp      : " ^ p ``0 + n + 0 = n`` (simp []))
val _ = out ("simp only : " ^ residual ``0 + n + 0 = (n : num)`` (simp [Once ADD_0]))
val _ = out ("只 minus  : " ^ residual ``0 + n + 0 = (n : num)`` (simp []))

(* ------------------------------------------------------------------ *)
(* 08.5 条件分裂：if-then-else 与 SUC/CASE                            *)
(* ------------------------------------------------------------------ *)
val _ = sec "08.5 条件分裂"
val _ = out ("if : " ^ p ``!b : bool. (if b then 1 else 2) = (if b then 1 else 2)``
               (Cases_on `b` >> simp []))
val _ = out ("自动裂 if : " ^ p ``!n : num. (if n = 0 then 0 else 1) < 2``
               (rw []))
val _ = out ("合取拆分  : " ^ p ``!a b : bool. a /\ b ==> b`` (rw []))

(* ------------------------------------------------------------------ *)
(* 08.6 SIMP_CONV：把化简器当函数用                                   *)
(* ------------------------------------------------------------------ *)
val _ = sec "08.6 化简器作为值"
val _ = out (thm_to_string (SIMP_CONV (srw_ss ()) [] ``((1 : num) + 2) * 0``))
val _ = out (thm_to_string (SIMP_CONV (srw_ss ()) [twice_def] ``twice 4 + twice 0``))
val _ = out (thm_to_string (SIMP_CONV bool_ss [] ``(T /\ p) = (p : bool)``))

(* ------------------------------------------------------------------ *)
(* 08.7 把定理放进状态里的 simpset                                    *)
(* ------------------------------------------------------------------ *)
val _ = sec "08.7 状态里的 simpset"
val _ = out ("加入前 : " ^ residual ``twice 1 = (2 : num)`` (simp []))
val _ = out ("用 nth  : " ^ residual ``twice 1 = (2 : num)`` (simp [twice_def]))

(* ------------------------------------------------------------------ *)
(* 08.8 化简器算不动的地方交给算术决策过程                            *)
(* ------------------------------------------------------------------ *)
val _ = sec "08.8 化简器的边界"
val _ = out ("simp : " ^ residual ``x + y = (y : num) + x`` (simp []))
val _ = out ("rw   : " ^ p ``x + y = (y : num) + x`` (rw []))
val _ = out ("rw 也救不了抽掉前提的截断减法：")
val _ = out ("把 y 卡住才行：" ^ p ``(x : num) - x = 0`` (rw []))

val _ = print "\n==== 08 结束 ====\n"

val _ = export_theory ()
