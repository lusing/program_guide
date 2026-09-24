(* 20 简化器进阶：simpset

   第 8 章把 simp 家族当作「几个不同力度的按钮」来用。这一章打开盖子：
   simpset 里装的是重写规则、合同性（cong）规则和定向策略三样东西，
   而 `simp` 之所以不会死循环，靠的是第三样。 *)

val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse simpLib
open arithmeticTheory listTheory

val _ = new_theory "Tut20"

fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")
fun p t tac = thm_to_string (prove (t, tac))
fun ev t = EVAL t |> concl |> term_to_string
(* SIMP_CONV 在"什么都没改"时抛 UNCHANGED，演示必须自己兜住 *)
fun sc nm ss ths t =
  out ("  " ^ nm ^ " : " ^
       (thm_to_string (SIMP_CONV ss ths t) handle UNCHANGED => "<UNCHANGED>"))

val _ = print "\n==== 20 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 20.1 四个现成的 simpset                                            *)
(* ------------------------------------------------------------------ *)
val _ = sec "20.1 四个现成的 simpset"
val _ = out ("同一个项 `LENGTH ([] : num list)` 在四个 simpset 下：")
val _ = sc "bool_ss " bool_ss      [] ``LENGTH ([] : num list)``
val _ = sc "std_ss  " std_ss       [] ``LENGTH ([] : num list)``
val _ = sc "arith_ss" arith_ss     [] ``LENGTH ([] : num list)``
val _ = sc "srw_ss()" (srw_ss ())  [] ``LENGTH ([] : num list)``
val _ = out ("bool_ss 只认命题演算，连 LENGTH 都不认识；")
val _ = out ("srw_ss() 在 std_ss 之上再挂上所有已注册数据类型的展开规则。")
val _ = out ("同一个项 `(1 : num) < 2` 在四个 simpset 下：")
val _ = sc "bool_ss " bool_ss      [] ``(1 : num) < 2``
val _ = sc "std_ss  " std_ss       [] ``(1 : num) < 2``
val _ = sc "arith_ss" arith_ss     [] ``(1 : num) < 2``
val _ = sc "srw_ss()" (srw_ss ())  [] ``(1 : num) < 2``

(* ------------------------------------------------------------------ *)
(* 20.2 装配自己的 simpset                                            *)
(* ------------------------------------------------------------------ *)
val _ = sec "20.2 装配：++"
val _ = out ("bool_ss 加上 ETA_ss 才认 η 化简：")
val _ = sc "bool_ss          " bool_ss [] ``(\x. f x) = f``
val _ = sc "bool_ss++ETA_ss  " (bool_ss ++ boolSimps.ETA_ss) [] ``(\x. f x) = f``
val _ = out ("`++` 的类型是 simpset -> ssfrag -> simpset，右边是一「片段」，")
val _ = out ("可以带自己的重写规则、conv、cong、甚至一个 filter。")
val _ = out ("临时加规则用 SIMP_CONV 的第二个参数更省事：")
val _ = sc "srw_ss + ADD_ASSOC" (srw_ss ()) [ADD_ASSOC] ``(a : num) + b + c``

(* ------------------------------------------------------------------ *)
(* 20.3 为什么不会死循环：定向                                        *)
(* ------------------------------------------------------------------ *)
val _ = sec "20.3 定向：simp 为什么不循环"
val _ = out ("ADD_COMM 说的是 m + n = n + m，两个方向都能匹配。")
val _ = out ("但 simp 按自己的项序把规则定向后，只往「变小」的一侧走：")
val _ = sc "a + b" bool_ss [ADD_COMM] ``(a : num) + b``
val _ = sc "b + a" bool_ss [ADD_COMM] ``(b : num) + a``
val _ = out ("a + b 本来就「更小」，所以 UNCHANGED；b + a 被翻成 a + b 后停下。")
val _ = out ("REWRITE_CONV 没有这一层保护：")
val _ = out ("  REWRITE_CONV [ADD_COMM] `a + b` 会 a+b → b+a → a+b → …… 一直转下去。")
val _ = out ("  想只翻一次，用 Once：")
val _ = out ("  " ^ thm_to_string (REWRITE_CONV [Once ADD_COMM] ``(a : num) + b``))
val _ = out ("（这条不能用脚本验证 —— 它会真的跑不完；run-all.sh 的看门狗"
             ^ "就是为这种情况准备的。）")

(* ------------------------------------------------------------------ *)
(* 20.4 假设是重写规则，但只有 simp/rw/fs 会自动用                     *)
(* ------------------------------------------------------------------ *)
val _ = sec "20.4 假设传播"
val _ = out ("SIMP_CONV 的第二个参数是「额外的假设」，它会当重写规则用：")
val _ = sc "带假设 x = 3 " (srw_ss ()) [ASSUME ``(x : num) = 3``] ``x + 1``
val _ = out ("但它不会替你把前提拆开：")
val _ = sc "不拆前提     " (srw_ss ()) []
          ``(x : num) = 3 ==> x + 1 = 4``
val _ = out ("`simp`/`rw`/`fs` 会先拆再化，所以它们能过：")
val _ = out ("  " ^ p ``(x : num) = 3 ==> x + 1 = 4`` (rw []))
val _ = out ("注意 SIMP_CONV 打出来的 ` [.] ⊢ x + 1 = 4`：方括号里的点")
val _ = out ("代表「用掉了一条假设」，是化简器留下的痕迹，不是输出噪声。")

(* ------------------------------------------------------------------ *)
(* 20.5 合同性规则：同时化简两侧                                      *)
(* ------------------------------------------------------------------ *)
val _ = sec "20.5 cong：化简儿子之前先看父亲"
val _ = out ("AND_CONG  : " ^ thm_to_string (DB.fetch "bool" "AND_CONG"))
val _ = out ("IMP_CONG  : " ^ thm_to_string (DB.fetch "bool" "IMP_CONG"))
val _ = out ("COND_CONG : " ^ thm_to_string (DB.fetch "bool" "COND_CONG"))
val _ = out ("OR_CONG   : " ^ thm_to_string (DB.fetch "bool" "OR_CONG"))
val _ = out ("LET_CONG  : " ^ thm_to_string (DB.fetch "bool" "LET_CONG"))
val _ = out ("「合同性」说的是：要化简 P ∧ Q，可以先化简 P 和 Q。")
val _ = out ("带条件的那些更妙 —— IMP_CONG 允许在化简结论时用上前提：")
val _ = sc "if p then 1 else 2" (srw_ss ()) []
          ``(p : bool) ==> (if p then 1 else 2 : num) = 1``
val _ = out ("simp 能把 if 的两个分支分别化简，靠的就是 COND_CONG 里")
val _ = out ("那两条带前提的等式（Q ⇒ x = x'）和（¬Q ⇒ y = y'）。")

(* ------------------------------------------------------------------ *)
(* 20.6 AC：把结合交换交给专门机制                                    *)
(* ------------------------------------------------------------------ *)
val _ = sec "20.6 AC"
val _ = out ("交换律交给定向去解有个副作用：它只认一种「规范序」。")
val _ = out ("想把 a + b + c 归一成某个固定形状，用 AC：")
val _ = sc "AC ADD_ASSOC ADD_COMM" bool_ss
          [AC ADD_ASSOC ADD_COMM] ``(a : num) + b + c``
val _ = out ("AC 把两条定理交给化简器里的 AC 机制，不再走逐条重写。")

(* ------------------------------------------------------------------ *)
(* 20.7 simp 做不到的事                                               *)
(* ------------------------------------------------------------------ *)
val _ = sec "20.7 边界"
val _ = out ("1) 不做归纳。LENGTH (REVERSE l) = LENGTH l 它一点办法都没有；")
val _ = out ("2) 不做非线性算术。`n * n >= n` 这种要自己给引理；")
val _ = out ("3) 不会为了用某条规则去「造」一个中间步骤；")
val _ = out ("4) 用 UNCHANGED 表示「没改动」——这是异常，不是返回值。")
val _ = out ("边界 4 的实际后果：")
(* 同一个调用，一个项改得动、一个改不动 —— 后者直接抛异常，
   不 handle 的话脚本就在这里 abort 了。 *)
val _ = out ("  改得动： " ^ thm_to_string (SIMP_CONV bool_ss [] ``(a : bool) /\ T``))
val _ = out ("  改不动： " ^ ((thm_to_string (SIMP_CONV bool_ss [] ``(a : bool) /\ b``))
                     handle UNCHANGED => "<抛 UNCHANGED —— 没改动时它抛异常>"))

val _ = print "\n==== 20 结束 ====\n"

val _ = export_theory ()
