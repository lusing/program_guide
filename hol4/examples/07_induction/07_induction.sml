(* 07 归纳证明

   归纳是 HOL4 里唯一能对付 `∀n` 的工具。本章把四种常用归纳
   （结构归纳、 datatype 归纳、强归纳、良基归纳）各跑一遍，并演示
   "归纳假设不够强「时怎么泛化。 *)

val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse
open arithmeticTheory listTheory relationTheory

val _ = new_theory "Tut07"

fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")
fun p t tac = thm_to_string (prove (t, tac))

val _ = print "\n==== 07 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 07.1 结构归纳：Induct_on 会自动安装归纳假设                        *)
(* ------------------------------------------------------------------ *)
val _ = sec "07.1 结构归纳"
val _ = out (p ``!n : num. 0 + n = n`` (Induct_on `n` >> simp []))
val _ = out (p ``!l : num list. LENGTH (REVERSE l) = LENGTH l``
               (Induct_on `l` >> simp []))

(* ------------------------------------------------------------------ *)
(* 07.2 归纳定理就是" ∀P. ... ⇒ ∀x. P x "形状的定理                   *)
(* ------------------------------------------------------------------ *)
val _ = sec "07.2 归纳定理的形状"
val _ = out (thm_to_string list_induction)
val _ = Datatype `bt7 = Lf7 | Nd7 bt7 num bt7`
(* Datatype 只把定理存进理论，不建立 ML 绑定，所以要用 DB.fetch 取回。 *)
val _ = out (thm_to_string (DB.fetch "Tut07" "bt7_induction"))

(* ------------------------------------------------------------------ *)
(* 07.3 按 datatype 的归纳定理做分支                                  *)
(* ------------------------------------------------------------------ *)
val _ = sec "07.3 树上的归纳"
Definition size7_def:
  (size7 Lf7 = 0) /\
  (size7 (Nd7 l n r) = 1 + size7 l + size7 r)
End
val _ = out (p ``!t : bt7. 0 < size7 t + 1``
               (Induct_on `t` >> simp [size7_def]))

(* ------------------------------------------------------------------ *)
(* 07.4 强归纳（completeInduct_on）：递归步长不是 1                   *)
(* ------------------------------------------------------------------ *)
val _ = sec "07.4 强归纳"
val _ = out (p ``!n : num. n <= n`` (completeInduct_on `n` >> rw []))
val _ = out (p ``!n : num. ~(n = 0) ==> ?m. n = SUC m``
               (completeInduct_on `n` >> rw [] >> Cases_on `n` >> simp []))

(* ------------------------------------------------------------------ *)
(* 07.5 良基归纳：沿一个自己选的关系下降                              *)
(* ------------------------------------------------------------------ *)
val _ = sec "07.5 良基归纳"
val _ = out (thm_to_string WF_INDUCTION_THM)
val _ = out ("WF_measure: " ^ thm_to_string (DB.fetch "prim_rec" "WF_measure"))
Definition half_def:
  half n = if n < 2 then n else half (n - 2)
Termination
  WF_REL_TAC `measure (\n. n)` >> simp []
End
val _ = out ("half_ind：" ^ thm_to_string half_ind)

(* ------------------------------------------------------------------ *)
(* 07.6 归纳假设不够强时：把累加器放进量化                            *)
(* ------------------------------------------------------------------ *)
val _ = sec "07.6 泛化：带累加器的 reverse"
Definition revacc_def:
  (revacc [] acc = acc) /\
  (revacc (x :: xs) acc = revacc xs (x :: acc))
End
(* 只对 xs 做归纳、acc 保持在 ∀ 里，归纳假设才够用。 *)
val _ = out (p ``!xs acc : num list. revacc xs acc = REVERSE xs ++ acc``
               (Induct_on `xs` >> simp [revacc_def]))
val _ = out (p ``!xs : num list. revacc [] xs = xs`` (simp [revacc_def]))

(* ------------------------------------------------------------------ *)
(* 07.7 多变量归纳的顺序很重要                                        *)
(* ------------------------------------------------------------------ *)
val _ = sec "07.7 多变量归纳"
val _ = out (p ``!n m : num. n + m = m + n``
               (Induct_on `n` >> Induct_on `m` >> simp []))

(* ------------------------------------------------------------------ *)
(* 07.8 该 Cases 的地方别 Induct                                      *)
(* ------------------------------------------------------------------ *)
val _ = sec "07.8 Cases 与 Induct 的分工"
val _ = out (p ``!l : num list. l = [] \/ ?h t. l = h :: t``
               (Cases_on `l` >> simp []))
val _ = out (p ``!n : num. n = 0 \/ ?m. n = SUC m``
               (Cases_on `n` >> simp []))

val _ = print "\n==== 07 结束 ====\n"

val _ = export_theory ()
