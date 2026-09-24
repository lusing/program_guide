(* 18 记录类型（record）

   多字段的构造器用起来像元组，但字段有名字：取值、更新、相等判定
   都按名字走。这一章看 Datatype 为记录生成了哪些定理，以及「字段更新"
   在 HOL 里到底是什么。 *)

val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse
open arithmeticTheory listTheory

val _ = new_theory "Tut18"

fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")
fun p t tac = thm_to_string (prove (t, tac))
fun ev t = EVAL t |> concl |> term_to_string
fun tb n = DB.fetch "Tut18" n
fun th n = thm_to_string (tb n)

val _ = print "\n==== 18 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 18.1 声明一个记录类型                                              *)
(* ------------------------------------------------------------------ *)
val _ = sec "18.1 声明"
val _ = Datatype `pt = <| x : num ; y : num |>`
val _ = out ("生成的定理里有这些名字：")
val _ = out (String.concatWith " "
  (List.filter (fn s => String.isPrefix "pt_" s orelse s = "FORALL_pt"
                        orelse s = "EXISTS_pt")
               (map #1 (DB.theorems "Tut18"))))

(* ------------------------------------------------------------------ *)
(* 18.2 字面量、取值、更新                                            *)
(* ------------------------------------------------------------------ *)
val _ = sec "18.2 字面量 / 取值 / 更新"
val _ = out ("字面量        : " ^ term_to_string ``<| x := 1 ; y := 2 |>``)
val _ = out ("带类型标注    : " ^ term_to_string ``(<| x := 1 ; y := 2 |> : pt)``)
val _ = out ("取值 p.x      : " ^ term_to_string ``(p : pt).x``)
val _ = out ("单字段更新    : " ^ term_to_string ``(p : pt) with y := 3``)
val _ = out ("函数式更新    : " ^ term_to_string ``(p : pt) with x updated_by f``)
val _ = out ("整块覆盖      : " ^ term_to_string ``(p : pt) with <| x := 5 ; y := 6 |>``)
val _ = out ("求值 取值     : " ^ ev ``(<| x := 1 ; y := 2 |> : pt).x``)
val _ = out ("求值 更新     : " ^ ev ``(<| x := 1 ; y := 2 |> : pt) with y := 9``)
(* with 是**后缀**且左结合，但 `:=` 右边会尽量多吃，所以要显式加括号：
   写成 p with x := 3 with y := 4 会被解析成 p with x := (3 with y := 4)。 *)
val _ = out ("求值 链式更新 : "
             ^ ev ``((<| x := 1 ; y := 2 |> : pt) with x := 3) with y := 4``)
val _ = out ("求值 整块覆盖 : "
             ^ ev ``(<| x := 1 ; y := 2 |> : pt) with <| x := 5 ; y := 6 |>``)
val _ = out ("求值 updated_by : "
             ^ ev ``(<| x := 1 ; y := 2 |> : pt) with x updated_by (\n. n + 10)``)

(* ------------------------------------------------------------------ *)
(* 18.3 Datatype 为记录生成的定理                                     *)
(* ------------------------------------------------------------------ *)
val _ = sec "18.3 生成的定理"
val _ = out ("pt_accessors（取值就是投影）：")
val _ = out ("  " ^ th "pt_accessors")
val _ = out ("pt_accfupds（更新只动一个字段）：")
val _ = out ("  " ^ th "pt_accfupds")
val _ = out ("pt_component_equality（两个记录相等 ⇔ 逐字段相等）：")
val _ = out ("  " ^ th "pt_component_equality")
val _ = out ("pt_literal_11（字面量相等 ⇔ 逐字段相等）：")
val _ = out ("  " ^ th "pt_literal_11")
val _ = out ("pt_literal_nchotomy（任何记录都能写成字面量）：")
val _ = out ("  " ^ th "pt_literal_nchotomy")
val _ = out ("pt_induction：")
val _ = out ("  " ^ th "pt_induction")
val _ = out ("FORALL_pt（把 ∀p 拆成 ∀各字段）：")
val _ = out ("  " ^ th "FORALL_pt")

(* ------------------------------------------------------------------ *)
(* 18.4 "更新"是真在改数据吗                                          *)
(* ------------------------------------------------------------------ *)
val _ = sec "18.4 with 不是赋值"
val _ = out ("pt_fupdfupds（同一字段连着更新两次 = 复合）：")
val _ = out ("  " ^ th "pt_fupdfupds")
val _ = out ("pt_fupdcanon（不同字段的更新可以换序）：")
val _ = out ("  " ^ th "pt_fupdcanon")
val _ = out ("pt_fupdselfid（用原值更新 = 不动）：")
val _ = out ("  " ^ th "pt_fupdselfid")
val _ = out ("用原值更新一次，记录不变："
             ^ p ``!p : pt. p with x := p.x = p`` (rw [tb "pt_component_equality"]))
val _ = out ("两个字段各更新一次，结果与顺序无关："
             ^ p ``!p : pt. (p with x := 1) with y := 2
                          = (p with y := 2) with x := 1``
                 (rw [tb "pt_component_equality"]))

(* ------------------------------------------------------------------ *)
(* 18.5 记录 vs 元组                                                  *)
(* ------------------------------------------------------------------ *)
val _ = sec "18.5 记录和元组比"
val _ = out ("同一个东西写成元组：")
val _ = out ("  " ^ type_to_string ``: num # num``)
val _ = out ("取值要用 FST/SND：" ^ ev ``FST (1, 2)``)
val _ = out ("记录按名字取：" ^ ev ``(<| x := 1 ; y := 2 |> : pt).y``)
val _ = out ("三个以上字段时，元组的第 4 个分量没有内置投影函数，"
             ^ "记录的字段名是自带的。")

(* ------------------------------------------------------------------ *)
(* 18.6 带参数的记录类型                                              *)
(* ------------------------------------------------------------------ *)
val _ = sec "18.6 多态记录"
val _ = Datatype `pair = <| fst : 'a ; snd : 'b ; tag : 'c |>`
val _ = out ("类型：" ^ type_to_string ``: (num, bool, num) pair``)
val _ = out ("取值：" ^ ev ``(<| fst := 1 ; snd := T ; tag := 7 |>
                            : (num, bool, num) pair).fst``)
val _ = out ("生成的 component_equality：")
val _ = out ("  " ^ th "pair_component_equality")
val _ = out ("（字段名跟内置函数 FST/SND 同名也没关系：它们在不同的命名空间。）")

val _ = print "\n==== 18 结束 ====\n"

val _ = export_theory ()
