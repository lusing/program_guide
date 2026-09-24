(* 23 工程化

   前 22 章讲的是"怎么证"，这一章讲"怎么保证别人跑你的脚本会得到
   同样的结果"。本教程的每条示例都过 run-all.sh 的七条判据，这一章
   把那七条拆开讲清楚，并给出脚本骨架。 *)

val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse
open arithmeticTheory listTheory

val _ = new_theory "Tut23"

fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")
fun p t tac = thm_to_string (prove (t, tac))

val _ = print "\n==== 23 开始 ====\n"

(* ------------------------------------------------------------------ *)
(* 23.1 骨架                                                          *)
(* ------------------------------------------------------------------ *)
val _ = sec "23.1 脚本骨架"
val _ = out ("每个示例文件都是同一个形状：")
val _ = out ("")
val _ = out ("  val _ = Feedback.set_trace \"Theory.save_thm_reporting\" 0")
val _ = out ("  val _ = Feedback.set_trace \"Definition.storage_message\" 0")
val _ = out ("  open HolKernel boolLib bossLib Parse     (* + 需要的理论 *)")
val _ = out ("  val _ = new_theory \"TutNN\"")
val _ = out ("  fun sec s = print (\"\\n\" ^ s ^ \"\\n\")   (* 分节 *)")
val _ = out ("  fun out s = print (s ^ \"\\n\")           (* 整行 *)")
val _ = out ("  val _ = print \"\\n==== NN 开始 ====\\n\"")
val _ = out ("  ... 若干 sec/out ...")
val _ = out ("  val _ = print \"\\n==== NN 结束 ====\\n\"")
val _ = out ("  val _ = export_theory ()")
val _ = out ("")
val _ = out ("`sec`/`out` 只有两个：分节用 sec，其它一律整行 out。")
val _ = out ("不写 `print` 的变体，是为了让输出**可以逐字节比对**。")

(* ------------------------------------------------------------------ *)
(* 23.2 两条必须关的 trace                                            *)
(* ------------------------------------------------------------------ *)
val _ = sec "23.2 两条必须关的 trace"
val _ = out ("Theory.save_thm_reporting —— 关掉后 save_thm / store_thm 不打印")
val _ = out ("                             \"Saved theorem ...\"。")
val _ = out ("Definition.storage_message —— 关掉后 Definition 不打印")
val _ = out ("                             \"Definition has been stored under ...\"。")
val _ = out ("为什么非关不可：这两条消息只出现在**其中一条入口**里。")
val _ = out ("不关掉，两条入口的输出就永远不可能逐字节一致，")
val _ = out ("第 7 条判据会一直红。")
val _ = out ("")
val _ = out ("trace 名字不能猜，猜错会直接抛异常：")
val _ = out ("  " ^ ((Feedback.set_trace "Datatype.storage_message" 0; "<ok>")
                     handle e => "<" ^ exn_to_string e ^ ">"))

(* ------------------------------------------------------------------ *)
(* 23.3 输出纪律                                                      *)
(* ------------------------------------------------------------------ *)
val _ = sec "23.3 输出纪律"
val _ = out ("正常输出 → stdout（print / out / sec）")
val _ = out ("诊断信息 → stderr（HOL 自己的报错走这里）")
val _ = out ("run-all.sh 把两者分开接：stdout 用来比对，stderr 必须为空。")
val _ = out ("")
val _ = out ("推论：脚本里**不要**往 stderr 写东西，也**不要**依赖")
val _ = out ("任何会随环境变化的东西（时间戳、PID、绝对路径、耗时）。")
val _ = out ("本章第一句打印的 Globals.version 是「版本号」，是常量，可以用；")
val _ = out ("而 `Theory \"X\" took 0.32s to build` 这种就不能进比对区间。")

(* ------------------------------------------------------------------ *)
(* 23.4 标记与区间                                                    *)
(* ------------------------------------------------------------------ *)
val _ = sec "23.4 标记与区间"
val _ = out ("`==== 23 开始 ====` 之前有引擎自己的寒暄：")
val _ = out ("  `<<HOL message: Created theory \"Tut23\">>`")
val _ = out ("`==== 23 结束 ====` 之后有构建系统的话：")
val _ = out ("  `Exporting theory \"Tut23\" ... done.`")
val _ = out ("  `Theory \"Tut23\" took 0.3s to build`")
val _ = out ("比对只取两个标记**之间**的部分，这样两边的噪声都被滤掉，")
val _ = out ("留下的全是脚本自己写的。")
val _ = out ("")
val _ = out ("抽取时匹配必须是**整行严格相等**，不能写子串匹配。")
val _ = out ("本章就是活的反例：上面两行把标记原样印在了正文里，")
val _ = out ("子串匹配会把第 46 行当成真的结束标记，区间当场被截断 ——")
val _ = out ("而「区间非空」「两条通道一致」这些判据照样全绿，")
val _ = out ("丢掉的半章没人发现。所以判据里还加了")
val _ = out ("「两个标记各**恰好出现一次**」这一条兜底。")

(* ------------------------------------------------------------------ *)
(* 23.5 七条判据                                                      *)
(* ------------------------------------------------------------------ *)
val _ = sec "23.5 七条判据"
val _ = out ("每条通道各自过 1–5：")
val _ = out ("  1. 退出码 0")
val _ = out ("  2. stderr 为空")
val _ = out ("  3. 开始 / 结束两个标记各**恰好出现一次**（整行严格相等）")
val _ = out ("  4. 标记区间非空，且不含 [[:cntrl:]] 控制字符")
val _ = out ("  5. 区间无溃逃痕迹")
val _ = out ("跨通道再过 6–7：")
val _ = out ("  6. run1 与 run2 的区间逐字节一致（运行间确定性）")
val _ = out ("  7. run1 与 hm 的区间逐字节一致（两条独立入口一致）")
val _ = out ("")
val _ = out ("第 4 条为什么写 POSIX 字符类而不是 [^[:print:]]：")
val _ = out ("  在 LC_ALL=C 下，后者的补集会把 CJK 的 UTF-8 高字节")
val _ = out ("  全判成「非可打印」，本章这一行就会被误杀。")

(* ------------------------------------------------------------------ *)
(* 23.6 溃逃痕迹必须是组合                                            *)
(* ------------------------------------------------------------------ *)
val _ = sec "23.6 溃逃痕迹"
val _ = out ("`prove` 失败时会往 stdout 打印")
val _ = out ("    Proof of ... failed. First unsolved sub-goal is ...")
val _ = out ("然后抛异常。如果只用关键字列表去匹配 `failed.`，")
val _ = out ("任何一句「这一条失败了」的中文说明都会被误判。")
val _ = out ("所以判据写成**组合**：横幅行 `Proof of` 后面必须紧跟着")
val _ = out ("单独一行的 `failed.`，两者同时出现才算数。")
val _ = out ("同样的道理，**所有单行判据都必须锚定行首**。`Static Errors`")
val _ = out ("`Uncaught exception` 这几个词本章就印在上面两行里（在引号中、")
val _ = out ("行中间），裸的子串匹配会把「讲解」当成「痕迹」，三条通道全红 ——")
val _ = out ("而脚本其实一点毛病都没有。真实错误行的形状是")
val _ = out ("    bad.sml:4: error: Pattern and expression have ...")
val _ = out ("    Uncaught exception at ./basis/FinalPolyML.sml:492: ...")
val _ = out ("所以 `: error:` 那条要连带「源文件名 + 行号」一起匹配。")
val _ = out ("反过来，`Exception raised at ...` **不算**痕迹：")
val _ = out ("19.3 / 22.4 / 23.2 这几节是故意 handle 住异常打印出来做演示的，")
val _ = out ("它们是预期输出，退出码也还是 0。")

(* ------------------------------------------------------------------ *)
(* 23.7 可重入                                                        *)
(* ------------------------------------------------------------------ *)
val _ = sec "23.7 可重入"
val _ = out ("Holmake 会缓存：脚本没改，它直接加载上次编好的理论文件。")
val _ = out ("所以脚本**第二次跑的时候环境是干净的**，第一次留下的")
val _ = out ("ML 绑定、trace 设置、定理都不在。")
val _ = out ("推论：")
val _ = out ("  - 不能依赖上一次运行定义的常量；")
val _ = out ("  - 不能在脚本里假设某个定理「应该还在」；")
val _ = out ("  - 重名会被拒：" ^ ((save_thm ("dup_test", TRUTH);
                                    save_thm ("dup_test", TRUTH); "<允许>")
                                   handle e => "<" ^ exn_to_string e ^ ">"))

(* ------------------------------------------------------------------ *)
(* 23.8 一个真实的坑：中文引号                                        *)
(* ------------------------------------------------------------------ *)
val _ = sec "23.8 中文引号"
val _ = out ("写中文说明时想用引号，别用 ASCII 双引号：")
val _ = out ("  错：out (\"规则生成的是\"最小集合\"（归纳的）。\")")
val _ = out ("  对：out (\"规则生成的是「最小集合」（归纳的）。\")")
val _ = out ("SML 把第一个内部引号当字符串结束，报错点是")
val _ = out ("`parse error: expected closing parenthesis`，")
val _ = out ("离真正的原因有十万八千里。本教程写的时候踩了 6 次，")
val _ = out ("于是有了 check-quotes.py 这个前置检查。")

(* ------------------------------------------------------------------ *)
(* 23.9 一个正常的小证明收尾                                          *)
(* ------------------------------------------------------------------ *)
val _ = sec "23.9 收尾"
val _ = out ("骨架 + 纪律都到位之后，剩下就是正常的活：")
val _ = out ("  " ^ p ``!l : num list. LENGTH (MAP (\x. x + 1) l) = LENGTH l``
                (Induct_on `l` >> rw []))

val _ = print "\n==== 23 结束 ====\n"

val _ = export_theory ()
