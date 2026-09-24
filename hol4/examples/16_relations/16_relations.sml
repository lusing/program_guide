(* 16 关系、闭包与良基

   关系在 HOL4 里就是 `α -> α -> bool`。本章用它讲三件事：
   传递闭包（RTC/TC）、良基关系（WF）、以及良基递归的终止性证明。 *)

val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse
open arithmeticTheory listTheory relationTheory

val _ = new_theory "Tut16"

fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")
fun p t tac = thm_to_string (prove (t, tac))
(* 列出某前缀的定理名。DB.theorems 返回的是 (名字, 定理) 的列表。 *)
fun rnames pfx =
  let val ns = List.filter (fn n => String.isPrefix pfx n)
                           (map #1 (DB.theorems "relation"))
  in Int.toString (length ns) ^ " 条，前 12 条： " ^
     String.concatWith " " (List.take (ns, 12)) end

val _ = print "\n==== 16 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 16.1 关系就是二元谓词                                              *)
(* ------------------------------------------------------------------ *)
val _ = sec "16.1 关系"
val _ = out ("类型   : " ^ (type_of ``($<) : num -> num -> bool`` |> type_to_string))
val _ = out ("逆     : " ^ (term_to_string ``rel_inv R``))

(* ------------------------------------------------------------------ *)
(* 16.2 闭包：RTC 与 TC                                               *)
(* ------------------------------------------------------------------ *)
val _ = sec "16.2 传递闭包"
val _ = out ("relationTheory 里的 RTC_* 定理：" ^ rnames "RTC_")
val _ = out ("relationTheory 里的 TC_* 定理： " ^ rnames "TC_")
val _ = out (thm_to_string (DB.fetch "relation" "RTC_REFL"))
val _ = out (thm_to_string (DB.fetch "relation" "RTC_TRANS"))

(* ------------------------------------------------------------------ *)
(* 16.3 RTC 的归纳原理                                                *)
(* ------------------------------------------------------------------ *)
val _ = sec "16.3 用 RTC 的归纳"
val _ = out (thm_to_string (DB.fetch "relation" "RTC_INDUCT"))
val _ = out (p ``!R : num -> num -> bool. !x y. RTC R x y ==> RTC R x y``
               (metis_tac []))
val _ = out (p ``!(R : num -> num -> bool) x y z.
                 RTC R x y ==> RTC R y z ==> RTC R x z``
               (metis_tac [RTC_TRANS]))

(* ------------------------------------------------------------------ *)
(* 16.4 良基：没有无穷下降链                                          *)
(* ------------------------------------------------------------------ *)
val _ = sec "16.4 良基"
val _ = out (thm_to_string (DB.fetch "prim_rec" "WF_measure"))
val _ = out (thm_to_string (DB.fetch "relation" "WF_INDUCTION_THM"))
val _ = out ("relationTheory 里跟 WF 有关的定理：" ^ rnames "WF_")

(* ------------------------------------------------------------------ *)
(* 16.5 良基递归：终止性义务的写法                                    *)
(* ------------------------------------------------------------------ *)
val _ = sec "16.5 良基递归"
Definition half2_def:
  half2 n = if n < 2 then n else half2 (n - 2)
Termination
  WF_REL_TAC `measure (\n. n)` >> rw []
End
val _ = out (thm_to_string half2_def)
val _ = out ("求值：" ^ (EVAL ``half2 10`` |> concl |> term_to_string))
val _ = out ("归纳原理：" ^ thm_to_string half2_ind)

(* ------------------------------------------------------------------ *)
(* 16.6 终止性证明过不了会长什么样                                    *)
(* ------------------------------------------------------------------ *)
val _ = sec "16.6 测度选错的后果"
val _ = out ("measure 必须是良基关系上的下降：")
val _ = out ("  用 measure (\\n. n) 时，递归调用 half2 (n - 2) 要证 n - 2 < n，")
val _ = out ("  由 n >= 2 推出；simp 里的算术过程直接把它收掉。")
val _ = out ("  换成 measure (\\n. 0) 就会留下 0 < 0 这样不可证的目标。")

(* ------------------------------------------------------------------ *)
(* 16.7 用良基归纳手动证明                                            *)
(* ------------------------------------------------------------------ *)
val _ = sec "16.7 手动良基归纳"
val _ = out (p ``!n : num. half2 n <= n``
               (ho_match_mp_tac (DB.fetch "Tut16" "half2_ind")
                >> rpt strip_tac >> rw [Once half2_def] >> DECIDE_TAC))

val _ = print "\n==== 16 结束 ====\n"

val _ = export_theory ()
