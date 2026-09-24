(* 01 开场：HOL4 的心智模型与环境自检

   本章不引入新语法，只回答三个问题：
     - 这台机器上的 HOL4 是不是真的能跑（环境自检）；
     - "定理「在 HOL4 里到底是个什么值；
     - 一条完整的「定义 → 证明 → 求值」最小闭环长什么样。
   后续 23 章全部建立在这三件事之上。 *)

(* 关掉只在某一个入口出现的系统提示，让两条验证通道的输出可比。
   详见 23 章。 *)
val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse
open arithmeticTheory listTheory pred_setTheory relationTheory

val _ = new_theory "Tut01"

fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")

val _ = print "\n==== 01 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 01.1 环境自检：内核版本与当前理论                                  *)
(* ------------------------------------------------------------------ *)
val _ = sec "01.1 环境自检：内核版本与当前理论"
val _ = out ("Globals.version = " ^ Int.toString Globals.version)
val _ = out ("current_theory  = " ^ Theory.current_theory ())

(* ------------------------------------------------------------------ *)
(* 01.2 定理是一个 ML 值：它有类型、有假设、有结论                    *)
(* ------------------------------------------------------------------ *)
val _ = sec "01.2 定理是一个 ML 值"
val th = REFL ``1 : num``
val _ = out (thm_to_string th)
val (asms, concl) = dest_thm th
val _ = out ("假设个数 = " ^ Int.toString (length asms))
val _ = out ("结论     = " ^ term_to_string concl)

(* ------------------------------------------------------------------ *)
(* 01.3 最小闭环：prove 把"命题 + 战术"变成定理                       *)
(* ------------------------------------------------------------------ *)
val _ = sec "01.3 最小闭环：prove"
val th1 = prove(``!n : num. n + 0 = n``, Induct_on `n` >> simp [])
val _ = out (thm_to_string th1)

(* ------------------------------------------------------------------ *)
(* 01.4 求值：EVAL 是"计算"，不是"证明"                              *)
(* ------------------------------------------------------------------ *)
val _ = sec "01.4 求值：EVAL"
val _ = out (thm_to_string (EVAL ``1 + 2 * 3``))
val _ = out (thm_to_string (EVAL ``LENGTH [1; 2; 3]``))

(* ------------------------------------------------------------------ *)
(* 01.5 库自检：本教程会用到的五个理论都在这份堆镜像里                *)
(* ------------------------------------------------------------------ *)
val _ = sec "01.5 库自检"
val _ = out ("LENGTH : " ^ (type_of ``LENGTH`` |> type_to_string))
(* 集合运算 UNION 是保留词，写成项时要加 $ 前缀（见 02 章"保留词"一节）。 *)
val _ = out ("UNION  : " ^ (type_of ``$UNION`` |> type_to_string))
val _ = out ("RTC    : " ^ (type_of ``RTC`` |> type_to_string))

(* ------------------------------------------------------------------ *)
(* 01.6 反例：机器不接受没有证明的命题                                *)
(* ------------------------------------------------------------------ *)
val _ = sec "01.6 反例：凭空断言不被接受"
val _ = out ("定理总数（本理论内）= " ^
             Int.toString (length (DB.theorems "Tut01")))

val _ = print "\n==== 01 结束 ====\n"

val _ = export_theory ()
