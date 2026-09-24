(* 15 集合与谓词

   HOL4 里「集合」就是谓词：`α set` 是 `α -> bool` 的缩写。所以集合运算
   就是逻辑运算，而集合相等就是谓词等价（外延性）。 *)

val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse
open arithmeticTheory listTheory pred_setTheory

val _ = new_theory "Tut15"

fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")
fun p t tac = thm_to_string (prove (t, tac))
fun eval1 t = EVAL t |> concl |> term_to_string
(* 打印成定理的样子（带 ⊢），避免"解说标签"和"函数名"粘在一起。 *)
fun ev t = thm_to_string (EVAL t)

val _ = print "\n==== 15 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 15.1 集合就是谓词                                                  *)
(* ------------------------------------------------------------------ *)
val _ = sec "15.1 集合就是谓词"
val _ = out ("类型      : " ^ (type_of ``{} : num set`` |> type_to_string))
val _ = out ("谓词即集合：" ^ (type_of ``\x : num. x < 3`` |> type_to_string))
val _ = out ("缩写展开  ：" ^ term_to_string ``({x | x < (3 : num)} : num set)``)

(* ------------------------------------------------------------------ *)
(* 15.2 语法与求值                                                    *)
(* ------------------------------------------------------------------ *)
val _ = sec "15.2 语法"
val _ = out (ev ``(1 : num) IN {1; 2; 3}``)
val _ = out (ev ``(4 : num) INSERT {1; 2; 3}``)
val _ = out (ev ``({1; 2; 3} : num set) DELETE 1``)
val _ = out ("UNION  : " ^ (term_to_string ``({1; 2} : num set) UNION {3}``))
val _ = out ("INTER  : " ^ (term_to_string ``({1; 2} : num set) INTER {2; 3}``))
val _ = out ("DIFF   : " ^ (term_to_string ``({1; 2} : num set) DIFF {2}``))
val _ = out ("IMAGE  : " ^ (term_to_string ``IMAGE (\x : num. x + 1) {1; 2}``))
val _ = out (ev ``({1; 2} : num set) SUBSET {1; 2; 3}``)
val _ = out (ev ``CARD ({1; 2; 3} : num set)``)
val _ = out (ev ``FINITE ({1; 2; 3} : num set)``)
val _ = out (ev ``({1; 2} : num set) PSUBSET {1; 2; 3}``)

(* ------------------------------------------------------------------ *)
(* 15.3 外延性：集合相等 = 逐点等价                                   *)
(* ------------------------------------------------------------------ *)
val _ = sec "15.3 外延性"
val _ = out (thm_to_string EXTENSION)
val _ = out (p ``!s t : num set. s = t <=> !x. x IN s <=> x IN t`` (metis_tac [EXTENSION]))

(* ------------------------------------------------------------------ *)
(* 15.4 三个证明：德摩根 / IMAGE / CARD                               *)
(* ------------------------------------------------------------------ *)
val _ = sec "15.4 集合上的证明"
val _ = out (p ``!(s : num set) t u. s INTER (t UNION u) =
                  (s INTER t) UNION (s INTER u)``
               (rw [EXTENSION] >> metis_tac []))
val _ = out (p ``!(s : num set) t. COMPL (s UNION t) = COMPL s INTER COMPL t``
               (rw [EXTENSION] >> metis_tac []))
val _ = out (p ``!f : num -> num. !s t. IMAGE f (s UNION t) = IMAGE f s UNION IMAGE f t``
               (rw [EXTENSION] >> metis_tac []))

(* ------------------------------------------------------------------ *)
(* 15.5 有限集合与基数                                                *)
(* ------------------------------------------------------------------ *)
val _ = sec "15.5 有限集与基数"
val _ = out (thm_to_string CARD_INSERT)
val _ = out (p ``!s : num set. FINITE s ==> CARD ((0 : num) INSERT s) <= CARD s + 1``
               (rw [CARD_INSERT]))
val _ = out ("列表转集合的项：" ^ (term_to_string ``set_of_list [1; 2; 3]``))
(* 注意 EVAL 的结果：它**证不出**两个集合相等，只能把相等展开成逐点条件。
   这正是「集合 = 谓词」的直接后果 —— 见下面正文。 *)
val _ = out ("求值（注意结果）：")
val _ = out ("  " ^ eval1 ``set_of_list [1; 2; 3] = ({1; 2; 3} : num set)``)

(* ------------------------------------------------------------------ *)
(* 15.6 集合运算在 simp 里的样子                                      *)
(* ------------------------------------------------------------------ *)
val _ = sec "15.6 化简器认识集合"
val _ = out (p ``!x : num. x IN ({} : num set) <=> F`` (rw []))
val _ = out (p ``!s : num set. s SUBSET s`` (rw []))
val _ = out (p ``!x : num. !s. x IN s ==> x IN (s UNION {x})`` (rw []))

val _ = print "\n==== 15 结束 ====\n"

val _ = export_theory ()
