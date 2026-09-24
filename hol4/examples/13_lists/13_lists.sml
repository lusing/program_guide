(* 13 列表

   listTheory 是 HOL4 里用得最多的库。本章把它最常用的函数和定理列出来，
   再用三个证明演示「先化简、再归纳」这条主线。 *)

val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse
open arithmeticTheory listTheory

val _ = new_theory "Tut13"

fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")
fun p t tac = thm_to_string (prove (t, tac))
fun eval1 t = EVAL t |> concl |> term_to_string
(* 打印成定理的样子（带 ⊢），这样"函数名"和"解说标签"不会粘在一起。 *)
fun ev t = thm_to_string (EVAL t)

val _ = print "\n==== 13 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 13.1 语法：分号、::、[]                                            *)
(* ------------------------------------------------------------------ *)
val _ = sec "13.1 语法"
val _ = out (term_to_string ``[1; 2; 3]``)
val _ = out (term_to_string ``(1 : num) :: (2 :: [])``)
val _ = out ("类型：" ^ (type_of ``[1; 2; 3]`` |> type_to_string))

(* ------------------------------------------------------------------ *)
(* 13.2 基本函数                                                      *)
(* ------------------------------------------------------------------ *)
val _ = sec "13.2 基本函数"
val _ = out (ev ``LENGTH [1; 2; 3]``)
val _ = out (ev ``[1; 2] ++ [3]``)
val _ = out (ev ``MAP (\x. x + 1) [1; 2; 3]``)
val _ = out (ev ``FILTER (\x. x < 3) [1; 2; 3; 4]``)
val _ = out (ev ``REVERSE [1; 2; 3]``)
val _ = out (ev ``FOLDR ($+ ) 0 [1; 2; 3]``)
val _ = out (ev ``FOLDL ($+ ) 0 [1; 2; 3]``)
val _ = out (ev ``MEM (2 : num) [1; 2; 3]``)
val _ = out (ev ``EL 1 [10; 20; 30]``)
val _ = out (ev ``ZIP ([1; 2], [3; 4])``)
val _ = out (ev ``FLAT [[1; 2]; [3]]``)
val _ = out (ev ``TAKE 2 [1; 2; 3]``)
val _ = out (ev ``DROP 2 [1; 2; 3]``)
val _ = out (ev ``NULL ([] : num list)``)

(* ------------------------------------------------------------------ *)
(* 13.3 常用定理                                                      *)
(* ------------------------------------------------------------------ *)
val _ = sec "13.3 常用定理"
val _ = out (thm_to_string (DB.fetch "list" "APPEND_NIL"))
val _ = out (thm_to_string (DB.fetch "list" "LENGTH_APPEND"))
val _ = out (thm_to_string (DB.fetch "list" "MAP_APPEND"))
val _ = out (thm_to_string (DB.fetch "list" "MEM_APPEND"))
val _ = out (thm_to_string (DB.fetch "list" "list_induction"))

(* ------------------------------------------------------------------ *)
(* 13.4 三个证明：化简 + 归纳                                         *)
(* ------------------------------------------------------------------ *)
val _ = sec "13.4 三个证明"
val _ = out (p ``!l : num list. LENGTH (MAP (\x. x + 1) l) = LENGTH l``
               (Induct_on `l` >> rw []))
val _ = out (p ``!l : 'a list. MAP ((f : 'b -> 'c) o (g : 'a -> 'b)) l =
                        MAP f (MAP g l)`` (Induct_on `l` >> rw []))
val _ = out (p ``!l : num list. REVERSE (REVERSE l) = l``
               (Induct_on `l` >> rw []))

(* ------------------------------------------------------------------ *)
(* 13.5 第二个证明之所以成立：先要一条 APPEND 上的引理                *)
(* ------------------------------------------------------------------ *)
val _ = sec "13.5 引理先行"
val _ = out (p ``!l1 l2 : num list. REVERSE (l1 ++ l2) = REVERSE l2 ++ REVERSE l1``
               (Induct_on `l1` >> rw []))

(* ------------------------------------------------------------------ *)
(* 13.6 列表归纳什么时候不够用                                        *)
(* ------------------------------------------------------------------ *)
val _ = sec "13.6 归纳假设的方向"
val _ = out (p ``!l : num list. LENGTH (FILTER P l) <= LENGTH l``
               (Induct_on `l` >> rw []))
val _ = out ("FOLD 的左右相等要先证结合律引理 —— 这是 13.5 那条路的升级版")

val _ = print "\n==== 13 结束 ====\n"

val _ = export_theory ()
