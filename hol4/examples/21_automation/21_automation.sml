(* 21 自动化：决策过程与自动战术

   HOL4 里有四台"能自己把活干完"的机器：求值器、Presburger 算术判定、
   命题判定、一阶判定。这一章逐个看它们各自能干什么、在哪一步收手，
   以及"把它们接起来"的标准手法。 *)

val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse simpLib
open arithmeticTheory listTheory

val _ = new_theory "Tut21"

fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")
fun p t tac = thm_to_string (prove (t, tac))
fun ev t = EVAL t |> concl |> term_to_string
fun sc nm ss ths t =
  out ("  " ^ nm ^ " : " ^
       (thm_to_string (SIMP_CONV ss ths t) handle UNCHANGED => "<UNCHANGED>"))
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

val _ = print "\n==== 21 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 21.1 一台机器一句话                                                *)
(* ------------------------------------------------------------------ *)
val _ = sec "21.1 四台机器"
val _ = out ("求值器      EVAL            —— 把闭项算成值")
val _ = out ("算术判定    DECIDE_TAC      —— Presburger 算术（加减、常数乘法、不等号）")
val _ = out ("命题判定    TAUT_PROVE      —— 命题演算（含 bool 变量）")
val _ = out ("一阶判定    metis_tac       —— 一阶逻辑 + 等词")
val _ = out ("")
val _ = out ("它们的关系不是「谁更强」，而是「谁认识哪些符号」：")
val _ = out ("  EVAL 只认可执行的方程，DECIDE 只认算术符号，")
val _ = out ("  TAUT 只认命题连接词，metis 认全称量词和等词但不认算术。")

(* ------------------------------------------------------------------ *)
(* 21.2 求值器                                                        *)
(* ------------------------------------------------------------------ *)
val _ = sec "21.2 求值器"
Definition fact_def:
  (fact 0 = 1) /\ (fact (SUC n) = SUC n * fact n)
End
val _ = out (thm_to_string (EVAL ``fact 6``))
val _ = out (thm_to_string (EVAL ``REVERSE [1; 2; 3]``))
val _ = out ("有变量时它一步都走不动：")
val _ = out ("  " ^ thm_to_string (EVAL ``LENGTH (l : num list)``))
val _ = out ("（结果是 `⊢ LENGTH l = LENGTH l` —— 一个重言式，不是化简。）")

(* ------------------------------------------------------------------ *)
(* 21.3 算术判定                                                      *)
(* ------------------------------------------------------------------ *)
val _ = sec "21.3 DECIDE_TAC / ARITH_CONV"
val _ = out ("DECIDE_TAC 直接证：" ^ p ``(x : num) < x + 1`` DECIDE_TAC)
val _ = out ("不等号链：" ^ p ``(x : num) <= y ==> y < z ==> x < z`` DECIDE_TAC)
val _ = out ("numLib.ARITH_CONV 把命题化成 T/F：")
val _ = out ("  " ^ thm_to_string (numLib.ARITH_CONV ``(x : num) < x + 1``))
val _ = out ("  （要用 numLib.ARITH_CONV，裸 ARITH_CONV 在本版本没有绑定。）")
val _ = out ("" )
val _ = out ("它不认识量词 —— 带量词的目标直接上 DECIDE_TAC：")
val _ = show "DECIDE 带量词  " DECIDE_TAC ``!n : num. ?m. m > n``
val _ = out ("量词拆掉、witness 给上之后就行：")
val _ = out ("  " ^ p ``!n : num. ?m. m > n``
                (strip_tac >> qexists_tac `n + 1` >> DECIDE_TAC))
val _ = out ("它也不认识乘法里的两个变量（那就不是 Presburger 了）：")
val _ = show "DECIDE 两变量乘" DECIDE_TAC ``!n m : num. n * m = 0 ==> n = 0 \/ m = 0``
val _ = out ("所以 `∀n. n ≤ n * n` 得靠归纳 + 化简，DECIDE_TAC 单独上不行：")
val _ = out ("  " ^ p ``!n : num. n <= n * n``
                 (Induct_on `n` >> rw [MULT_CLAUSES]))

(* ------------------------------------------------------------------ *)
(* 21.4 命题判定                                                      *)
(* ------------------------------------------------------------------ *)
val _ = sec "21.4 TAUT_PROVE"
val _ = out ("参数是**项**不是引号：tautLib.TAUT_PROVE ``…``")
val _ = out ("  " ^ thm_to_string (tautLib.TAUT_PROVE ``(a : bool) /\ b ==> b``))
val _ = out ("  " ^ thm_to_string (tautLib.TAUT_PROVE
              ``((a : bool) ==> b) ==> (b ==> c) ==> a ==> c``))
val _ = out ("  " ^ thm_to_string (tautLib.TAUT_PROVE ``(a : bool) \/ ~a``))
val _ = out ("带量词的它其实也能过，那是因为量词被当成了原子命题：")
val _ = out ("  " ^ thm_to_string (tautLib.TAUT_PROVE ``!x : bool. x \/ ~x``))

(* ------------------------------------------------------------------ *)
(* 21.5 一阶判定                                                      *)
(* ------------------------------------------------------------------ *)
val _ = sec "21.5 metis_tac"
val _ = out ("等词是对称的：" ^ p ``(f (x : num) = f y) = (f y = f x)``
                (metis_tac []))
val _ = out ("把已有定理喂给它，它替你做 Modus Ponens：")
val mem_pos = prove(``!l : num list. !x. MEM x l ==> LENGTH l > 0``,
                    Induct_on `l` >> rw [])
val _ = out ("  已知：" ^ thm_to_string mem_pos)
val _ = out ("  求证：" ^ p ``MEM (1 : num) l ==> LENGTH l > 0``
                            (metis_tac [mem_pos]))
val _ = out ("")
val _ = out ("但那条「已知」本身 metis 证不出来 —— 它不会分构造子：")
val _ = show "metis 直上    " (metis_tac [])
             ``!l : num list. !x. MEM x l ==> LENGTH l > 0``
val _ = out ("真正的分工长这样：")
val _ = out ("  " ^ p ``!l : num list. !x. MEM x l ==> LENGTH l > 0``
                     (Induct_on `l` >> rw []))
val _ = out ("  Induct 负责拆结构、rw 负责展开定义 —— metis 只在最后拼逻辑。")

(* ------------------------------------------------------------------ *)
(* 21.6 PROVE_TAC 与 RES_TAC                                          *)
(* ------------------------------------------------------------------ *)
val _ = sec "21.6 两个便宜的替代品"
val _ = out ("PROVE_TAC 是「只用假设里的命题逻辑」：")
val _ = out ("  " ^ p ``(a : bool) /\ b ==> b /\ a`` (PROVE_TAC []))
val _ = out ("RES_TAC 把假设里的蕴含反复套用，直到没新东西：")
val _ = out ("  " ^ p ``((a : bool) ==> b) ==> a ==> b`` (strip_tac >> RES_TAC))
val _ = out ("这两个都比 metis_tac 便宜，能用就用。")

(* ------------------------------------------------------------------ *)
(* 21.7 组合的标准形状                                                *)
(* ------------------------------------------------------------------ *)
val _ = sec "21.7 接起来的顺序"
val _ = out ("1) 先看是不是闭项            → EVAL")
val _ = out ("2) 再看是不是纯算术          → DECIDE_TAC / ARITH_CONV")
val _ = out ("3) 再看是不是纯命题          → TAUT_PROVE / PROVE_TAC")
val _ = out ("4) 剩下的：先用 rw/simp 把结构拆开、把定义展开，")
val _ = out ("   再让 DECIDE_TAC 或 metis_tac 收尾。")
val _ = out ("一个四步都过不了、必须人手工的例子：带累加器的反转。")
Definition revacc_def:
  (revacc [] acc = acc) /\
  (revacc (h::t) acc = revacc t (h::acc))
End
val _ = out ("  直接归纳：" )
val _ = show "  只用 rw    " (Induct_on `l` >> rw [revacc_def])
             ``!l : num list. revacc l [] = REVERSE l``
val _ = out ("  归纳假设是 revacc t [] = REVERSE t，而目标里 acc 变成了 [h]，")
val _ = out ("  套不上 —— 这正是 13.6 说的「归纳假设的方向」问题。")
val _ = out ("  把结论推广（让 acc 也变成全称量词）就能过：")
val _ = out ("  " ^ p ``!l acc : num list. revacc l acc = REVERSE l ++ acc``
                     (Induct_on `l` >> rw [revacc_def]))
val _ = out ("  （推广归纳假设这一步，四台机器都替你做不了。）")

(* ------------------------------------------------------------------ *)
(* 21.8 自动化的代价                                                  *)
(* ------------------------------------------------------------------ *)
val _ = sec "21.8 代价"
val _ = out ("1) metis_tac 不会告诉你「差在哪」，只说 no solution found；")
val _ = out ("2) 喂给它的定理越多越慢，而且**方向不对称的定理会让它不终止**；")
val _ = out ("3) 自动证明出来的项可能很长，人读不懂，也就没法维护；")
val _ = out ("4) 一条自动证明今天能过，明天库里某个定理改名就过不了。")
val _ = out ("所以教程里的做法是：能写清楚的步骤自己写，")
val _ = out ("只在「这一步显然」的地方交给机器。")

val _ = print "\n==== 21 结束 ====\n"

val _ = export_theory ()
