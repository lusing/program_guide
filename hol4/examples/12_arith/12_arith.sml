(* 12 自然数算术

   `num` 是 Peano 自然数，不是机器整数：没有负数，减法在 0 处截断。
   本章把这套算术的规则、决策过程和它咬人的地方过一遍。 *)

val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse
open arithmeticTheory

val _ = new_theory "Tut12"

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

val _ = print "\n==== 12 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 12.1 num 是 Peano 数：SUC 与数字字面量                             *)
(* ------------------------------------------------------------------ *)
val _ = sec "12.1 Peano 与自然数字面量"
(* 关键点：字面量 3 和 SUC (SUC (SUC 0)) 是**两个不同的项**，
   `3` 是二进制 numeral（numeralTheory），`SUC` 链是 Peano 构造子。
   它们可以证成相等，但不是同一个项 —— 06.4 节那个坑的根源就在这。 *)
val _ = out ("字面量 3        : " ^ term_to_string ``3 : num``)
val _ = out ("SUC(SUC(SUC 0)) : " ^ term_to_string ``SUC (SUC (SUC 0))``)
val _ = out ("两者能证相等    : " ^ p ``SUC (SUC (SUC 0)) = (3 : num)`` (rw []))
val _ = out ("类型            : " ^ (type_of ``3 : num`` |> type_to_string))
val _ = out ("num 没有负数：  " ^
             (EVAL ``(1 : num) - 2`` |> concl |> term_to_string))

(* ------------------------------------------------------------------ *)
(* 12.2 加减乘的基本定理                                              *)
(* ------------------------------------------------------------------ *)
val _ = sec "12.2 基本定理"
val _ = out (thm_to_string ADD_0)
val _ = out (thm_to_string ADD_COMM)
val _ = out (thm_to_string MULT_COMM)
val _ = out (thm_to_string ADD_ASSOC)
val _ = out (thm_to_string (DB.fetch "arithmetic" "ADD_SYM"))

(* ------------------------------------------------------------------ *)
(* 12.3 截断减法：整数直觉在这里会出错                                *)
(* ------------------------------------------------------------------ *)
val _ = sec "12.3 截断减法"
val _ = out ((EVAL ``(3 : num) - 5`` |> concl |> term_to_string))
val _ = out ("n - m + m ≠ n ：" ^
             (EVAL ``((3 : num) - 5) + 5`` |> concl |> term_to_string))
val _ = out ("加上前提才行   ：" ^ p ``!n m : num. m <= n ==> n - m + m = n`` (rw []))
val _ = out ("减法自己的定理 ：" ^ thm_to_string SUB_ADD)

(* ------------------------------------------------------------------ *)
(* 12.4 决策过程：DECIDE / arith_ss / rw                              *)
(* ------------------------------------------------------------------ *)
val _ = sec "12.4 Presburger 算术决策过程"
val _ = out ("DECIDE 线性     : " ^ thm_to_string (DECIDE ``!n : num. n < n + 1``))
val _ = out ("DECIDE 常数倍   : " ^ thm_to_string (DECIDE ``3 * (x : num) < 3 * x + 1``))
val _ = out ("（乘常数还是 Presburger —— `3 * x` 只是 x+x+x。）")
val _ = out ("")
val _ = out ("两条硬边界（用 show 直接调战术，不会触发 prove 的失败横幅）：")
val _ = show "DECIDE 量词交替" DECIDE_TAC ``!n : num. ?m. m > n``
val _ = show "DECIDE 两变量乘" DECIDE_TAC ``!n m : num. n * m = 0 ==> n = 0 \/ m = 0``
val _ = out ("第二条要自己分情况：")
val _ = out ("  " ^ p ``!n m : num. n * m = 0 ==> n = 0 \/ m = 0``
               (Cases_on `n` >> rw [] >> Cases_on `m` >> rw [] >> DECIDE_TAC))
val _ = out ("")
val _ = out ("rw 比 DECIDE 强的地方：它会**分构造子情况**再化简。")
val _ = show "rw 线性        " (rw []) ``!n : num. n + 1 > n``
val _ = show "rw 缺前提的减法" (rw []) ``!n m : num. n - m + m = n``
val _ = show "rw 带前提的减法" (rw []) ``!n m : num. m <= n ==> n - m + m = n``
val _ = out ("（rw 在算术上比想象的强：别急着给它加 ADD_COMM / MULT_COMM，")
val _ = out ("  把它们当重写规则喂进去反而可能让化简器跑不完 —— 见 24.6 节。）")

(* ------------------------------------------------------------------ *)
(* 12.5 < 与 SUC                                                      *)
(* ------------------------------------------------------------------ *)
val _ = sec "12.5 序与 SUC"
val _ = out ("n < SUC n : " ^ p ``!n : num. n < SUC n`` (rw []))
val _ = out ("SUC 单调   : " ^ p ``!n m : num. n < m ==> SUC n < SUC m`` (rw []))
val _ = out ("反方向     : " ^ p ``!n m : num. SUC n < SUC m ==> n < m`` (rw []))

(* ------------------------------------------------------------------ *)
(* 12.6 DIV 与 MOD                                                    *)
(* ------------------------------------------------------------------ *)
val _ = sec "12.6 除法与取模"
val _ = out ("7 DIV 3    : " ^ (EVAL ``(7 : num) DIV 3`` |> concl |> term_to_string))
val _ = out ("7 MOD 3    : " ^ (EVAL ``(7 : num) MOD 3`` |> concl |> term_to_string))
val _ = out ("除法算法   : " ^ thm_to_string DIVISION)
val _ = out ("MOD 有界   : " ^ thm_to_string MOD_LESS)

(* ------------------------------------------------------------------ *)
(* 12.7 归纳 + 算术：求和公式                                         *)
(* ------------------------------------------------------------------ *)
val _ = sec "12.7 归纳与算术配合"
Definition sumto_def:
  (sumto 0 = 0) /\
  (sumto (SUC n) = sumto n + SUC n)
End
(* 二次的恒等式要 ring 工具，这里只证线性的：决策过程 + 归纳就够。 *)
val _ = out (thm_to_string (prove(``!n : num. n <= sumto n``,
                                  Induct_on `n` >> rw [sumto_def])))
val _ = out (thm_to_string (prove(``!n : num. sumto (SUC n) = sumto n + SUC n``,
                                  rw [sumto_def])))
val _ = out ("求值校核   : " ^ (EVAL ``sumto 10`` |> concl |> term_to_string))

val _ = print "\n==== 12 结束 ====\n"

val _ = export_theory ()
