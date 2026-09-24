(* 03 元语言：SML

   HOL4 的「元语言」是 Standard ML —— 项、类型、定理都是 SML 的值，战术是
   SML 的函数。本章只讲写 HOL4 脚本真正用到的那一小块 SML。 *)

val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse
open arithmeticTheory listTheory

val _ = new_theory "Tut03"

fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")

val _ = print "\n==== 03 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 03.1 值绑定与 it                                                    *)
(* ------------------------------------------------------------------ *)
val _ = sec "03.1 值绑定"
val n = 1 + 2
val _ = out ("n = " ^ Int.toString n)
(* 交互式 REPL 里顶层最后一个值会留在 it 里；`hol run`（批处理入口）
   没有 it，脚本不能依赖它 —— 这是「能交互」和「可重跑」的一处差别。 *)
val _ = out ("n 的类型由推断给出（int）：" ^ Int.toString (n + 1))

(* ------------------------------------------------------------------ *)
(* 03.2 函数：curried 与元组两种写法                                   *)
(* ------------------------------------------------------------------ *)
val _ = sec "03.2 函数"
fun add_t (x, y) = x + y
fun add_c x y = x + y
val _ = out ("add_t (3,4) = " ^ Int.toString (add_t (3, 4)))
val _ = out ("add_c 3 4   = " ^ Int.toString (add_c 3 4))
val _ = out ("偏应用 add_c 3 : int -> int，" ^ Int.toString (add_c 3 10))

(* ------------------------------------------------------------------ *)
(* 03.3 模式匹配与 option                                              *)
(* ------------------------------------------------------------------ *)
val _ = sec "03.3 模式匹配与 option"
fun first l = case l of [] => NONE | x :: _ => SOME x
val _ = out ("first []     = " ^ (case first ([] : int list) of NONE => "NONE" | SOME x => Int.toString x))
val _ = out ("first [7;8]  = " ^ (case first [7, 8] of NONE => "NONE" | SOME x => Int.toString x))
fun len [] = 0
  | len (_ :: t) = 1 + len t
val _ = out ("len [1;2;3] = " ^ Int.toString (len [1, 2, 3]))

(* ------------------------------------------------------------------ *)
(* 03.4 异常：handle 是脚本里最常用的兜底                              *)
(* ------------------------------------------------------------------ *)
val _ = sec "03.4 异常"
val _ = out ("3 div 0 被兜住 = " ^ Int.toString (3 div 0 handle _ => ~1))
val _ = out ("hd [] 被兜住   = " ^ Int.toString (hd ([] : int list) handle _ => ~1))

(* ------------------------------------------------------------------ *)
(* 03.5 三个组合子：o、|>、$                                          *)
(* ------------------------------------------------------------------ *)
val _ = sec "03.5 组合子"
val _ = out ("(Int.toString o (fn x => x + 1)) 41 = " ^ (Int.toString o (fn x => x + 1)) 41)
val _ = out ("41 |> (fn x => x + 1) |> Int.toString = " ^ (41 |> (fn x => x + 1) |> Int.toString))
val _ = out ("$ 是中缀的右结合应用：" ^ Int.toString ((fn x => x + 1) $ 40 + 1))
val _ = out ("用在定理上：" ^ (EVAL ``1 + 1`` |> concl |> term_to_string))

(* ------------------------------------------------------------------ *)
(* 03.6 列表与字符串：脚本里真正会写的那些                              *)
(* ------------------------------------------------------------------ *)
val _ = sec "03.6 列表与字符串"
val _ = out ("map (fn x => x * 2) [1;2;3] 的 SML 写法 = " ^
             String.concatWith ";" (map Int.toString (map (fn x => x * 2) [1, 2, 3])))
val _ = out ("foldl 求和 = " ^ Int.toString (foldl (fn (x, a) => x + a) 0 [1, 2, 3, 4]))
val _ = out ("String.concatWith = " ^ String.concatWith ", " ["a", "b", "c"])

(* ------------------------------------------------------------------ *)
(* 03.7 顶层的 val _ = 惯用法                                          *)
(* ------------------------------------------------------------------ *)
val _ = sec "03.7 val _ = 惯用法"
val _ = List.app (fn x => print ("  " ^ Int.toString x ^ "\n")) [1, 2, 3]
val _ = out ("遍历结束，返回 unit，不污染环境")

val _ = print "\n==== 03 结束 ====\n"

val _ = export_theory ()
