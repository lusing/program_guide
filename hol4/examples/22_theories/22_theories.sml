(* 22 理论与构建

   一个 HOL4 脚本不是一个"跑一遍就完"的程序，它是一份**理论**：
   跑完会把所有定义和定理写进一张表，别人可以只加载这张表而不重跑证明。
   这一章看这张表长什么样、怎么查、怎么被 Holmake 缓存。 *)

val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse
open arithmeticTheory listTheory

val _ = new_theory "Tut22"

fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")
fun p t tac = thm_to_string (prove (t, tac))
fun pd pts = String.concatWith " " (map (fn ((t, n), _) => t ^ "$" ^ n) pts)
fun ntheorems thy = Int.toString (length (DB.theorems thy))

val _ = print "\n==== 22 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 22.1 当前理论                                                      *)
(* ------------------------------------------------------------------ *)
val _ = sec "22.1 当前理论"
val _ = out ("Globals.version : " ^ Int.toString (Globals.version))
val _ = out ("current_theory  : " ^ current_theory ())
val _ = out ("本理论现在有几条定理：" ^ ntheorems "Tut22")
val _ = out ("（刚 new_theory，一条都还没有。）")

(* ------------------------------------------------------------------ *)
(* 22.2 祖先                                                          *)
(* ------------------------------------------------------------------ *)
val _ = sec "22.2 祖先"
val _ = out ("ancestry 里前 8 个：" ^ String.concatWith " " (List.take (ancestry "Tut22", 8)))
val _ = out ("ancestry 总数    ：" ^ Int.toString (length (ancestry "Tut22")))
val _ = out ("顺序是「最近的在前面」：hol 在最末，list 在中间。")
val _ = out ("open 一个理论只是让它里面的 ML 绑定可见，")
val _ = out ("祖先列表是另一回事 —— 它由 new_theory 时的依赖决定。")

(* ------------------------------------------------------------------ *)
(* 22.3 定理是怎么登记的                                              *)
(* ------------------------------------------------------------------ *)
val _ = sec "22.3 四条登记通道"
Definition mylen_def:
  (mylen ([] : num list) = 0) /\
  (mylen (h :: t) = mylen t + 1)
End
val _ = out ("Definition 之后：" ^ ntheorems "Tut22" ^ " 条")
val _ = out ("  它给出 ML 绑定 mylen_def，但 DB.theorems 数不到它 ——")
val _ = out ("  定义存在**另一张表**里，要用 DB.definitions 看：")
val _ = out ("  " ^ String.concatWith " " (map #1 (DB.definitions "Tut22")))
val _ = out ("  不过 DB.fetch 两张表都查，所以按名字取是没问题的。")
val _ = Datatype `mystep = Zero | Succ mystep`
val _ = out ("Datatype 之后  ：" ^ ntheorems "Tut22" ^ " 条")
val _ = out ("  它登记了 mystep_* 一串，但**不给 ML 绑定**，要自己 DB.fetch。")
val myind = store_thm ("myind",
  ``!P. P [] /\ (!h t. P t ==> P (h :: t)) ==> !l : num list. P l``,
  rw [] >> Induct_on `l` >> rw [])
val _ = out ("store_thm 之后 ：" ^ ntheorems "Tut22" ^ " 条")
val _ = out ("  store_thm 两头都给：ML 绑定 + 理论登记。")
val _ = out ("  " ^ thm_to_string myind)
val _ = save_thm ("mylen_twice", prove (``mylen [1; 2] = 2``, EVAL_TAC))
val _ = out ("save_thm 之后  ：" ^ ntheorems "Tut22" ^ " 条")
val _ = out ("  " ^ thm_to_string (DB.fetch "Tut22" "mylen_twice"))
val _ = out ("（save_thm 只登记，不建 ML 绑定，适合「只要存档」的引理。）")
val _ = out ("重名会被拒：" ^ ((save_thm ("mylen_twice", myind); "<允许>")
                                handle e => "<" ^ exn_to_string e ^ ">"))

(* ------------------------------------------------------------------ *)
(* 22.4 查库                                                          *)
(* ------------------------------------------------------------------ *)
val _ = sec "22.4 四种查法"
val _ = out ("DB.theorems  —— 列出一个理论里所有定理：")
val _ = out ("  " ^ String.concatWith " " (map #1 (DB.theorems "Tut22")))
val _ = out ("DB.fetch     —— 按 (理论, 名字) 精确取：")
val _ = out ("  " ^ thm_to_string (DB.fetch "Tut22" "mylen_def"))
val _ = out ("DB.find      —— 按名字子串搜（返回 理论$名字）：")
val _ = out ("  " ^ pd (DB.find "LENGTH_APP"))
val _ = out ("DB.match     —— 按**项的形状**搜：")
val _ = out ("  " ^ pd (DB.match [] ``_ + 0``))
val _ = out ("DB.apropos   —— 按「项里出现过哪些常量」搜，最宽："
             ^ Int.toString (length (DB.apropos ``LENGTH``)) ^ " 条")
val _ = out ("查不到的时候：")
val _ = out ("  " ^ ((thm_to_string (DB.fetch "NoSuchThy" "x"))
                     handle e => "<" ^ exn_to_string e ^ ">"))

(* ------------------------------------------------------------------ *)
(* 22.5 命名                                                          *)
(* ------------------------------------------------------------------ *)
val _ = sec "22.5 命名"
val _ = out ("全名是 `理论$名字`，打印时理论名常常被省略，冲突时才出现：")
val _ = out ("  " ^ term_to_string ``$+``)
val _ = out ("约定：定义叫 `f_def`，方程引理叫 `f_ind` / `f_cases` / `f_rules`，")
val _ = out ("区分性叫 `t_distinct`，单射叫 `t_11`，穷举叫 `t_nchotomy`。")
val _ = out ("这些约定是 Datatype / Definition / Hol_reln 自动遵守的，")
val _ = out ("自己 store_thm 时照着取，别人才能猜到你的定理叫什么。")

(* ------------------------------------------------------------------ *)
(* 22.6 构建：Holmake 缓存了什么                                      *)
(* ------------------------------------------------------------------ *)
val _ = sec "22.6 构建"
val _ = out ("一个 TutNNScript.sml 跑完会留下：")
val _ = out ("  TutNNTheory.{sig,sml,dat,uo,ui}  —— 理论本身（二进制 + 源）")
val _ = out ("  TutNNTheory.uo 是 Holmake 的构建目标，也是依赖单位。")
val _ = out ("  .hol/logs/TutNNTheory             —— 脚本的 stdout 落在哪儿")
val _ = out ("  .hol/obj/, .hol/deps/             —— 目标文件与依赖信息")
val _ = out ("Holmake 靠时间戳决定要不要重编：脚本没动就直接加载理论文件，")
val _ = out ("不再跑一遍证明。这也是本教程脚本必须**可重入**的原因 ——")
val _ = out ("第二次跑的时候，环境里已经没有第一次留下的状态了。")

(* ------------------------------------------------------------------ *)
(* 22.7 两条入口                                                      *)
(* ------------------------------------------------------------------ *)
val _ = sec "22.7 两条入口的差别"
val _ = out ("`hol run Foo.sml`   —— 直接跑；脚本输出进 stdout；未捕获异常退 1。")
val _ = out ("`Holmake FooTheory.uo` —— 走构建系统；脚本输出进 .hol/logs/FooTheory；")
val _ = out ("                          失败同样退 1，但会留下日志。")
val _ = out ("交互式 REPL（`hol < Foo.sml`）—— **不要用来验证**：")
val _ = out ("  它遇到未捕获异常会打印后继续，退出码仍是 0。")
val _ = out ("  看起来跑完了，其实中间死在某一行。")
val _ = out ("所以 run-all.sh 只认前两条，而且要求两者输出逐字节一致。")

val _ = print "\n==== 22 结束 ====\n"

val _ = export_theory ()
