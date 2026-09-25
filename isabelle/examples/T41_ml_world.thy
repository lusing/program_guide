theory T41_ml_world
  imports Main
begin

text \<open>implementation 手册（implementation.pdf）的前几章讲"Isabelle/ML"
这门方言：**不是**独立的 ML，而是嵌在证明环境里的 ML——每一段代码
都能通过反引号（antiquotation）直接引用**当前上下文里的定理、项、类型**，
编译期检查、无需字符串拼名字。这一对（ML 块 + 反引号）是后面一切
tactic（第 42 章）、工具、定制方法的基座。\<close>

ML \<open>writeln "==== 41 开始 ===="\<close>

subsection \<open>41.2 两种 ML 块：ML 与 ML_val\<close>

text \<open>cartouche 括起的 @{verbatim ML} 块**执行**代码；
@{verbatim ML_val} 块只编译与求值顶层绑定（类似 REPL 一行），
适合写"应当有这个值"的检查。两者的输出都进构建日志：\<close>

ML \<open>
  val answer = 6 * 7
  val _ = writeln ("answer = " ^ string_of_int answer)
\<close>

ML_val \<open>
  val ok = 1 + 1 = 2
  val _ = if not ok then error "断言失败" else ()
\<close>

subsection \<open>41.3 反引号：编译期引用逻辑对象\<close>

text \<open>反引号 @{verbatim "@{...}"} 把 Isabelle 侧的对象变成 ML 侧的值。
拼错名字 = 编译错误（构建拒绝），不是运行时惊喜。核心四件：\<close>

lemma cons_swap: "xs @ [] = xs"
  by simp

ML \<open>
  val t = @{thm cons_swap}          (* 定理：thm *)
  val tm = @{term "1 + (2::nat)"}   (* 项：term *)
  val ty = @{typ "nat list"}        (* 类型：typ *)
  val c = @{const_name Cons}        (* 常量名：string *)
  val _ = writeln (@{make_string} t);
  val _ = writeln (@{make_string} tm);
  val _ = writeln (@{make_string} ty);
  val _ = writeln c
\<close>

text \<open>@{verbatim "@{make_string}"}（或 @{verbatim "@{make_string x}"}）
把任意 ML 值变字符串，是教程里打印观察的主力。
@{verbatim "@{lemma ... by ...}"} 现场证一条小定理：\<close>

ML \<open>
  val mini = @{lemma "a \<and> b \<Longrightarrow> b \<and> a" for a b :: bool by blast}
  val _ = writeln (@{make_string} mini)
\<close>

subsection \<open>41.4 上下文：theory、context、proof state\<close>

text \<open>Isabelle 的世界有两层上下文：@{verbatim "theory"}（全局、
单调累积）与 @{verbatim "Proof.context"}（证明局部）。ML 里用
@{verbatim "@{context}"} / @{verbatim "@{theory}"} 拿当前值：\<close>

ML \<open>
  val thy = @{theory}
  val ctxt = @{context}
  val _ = writeln ("theory 名: " ^ Context.theory_name {long = false} thy)
\<close>

text \<open>证明上下文能查到理论里的定理（按名字取）：
@{verbatim "Proof_Context.get_thm"} 拿不到会抛异常，
@{verbatim "can"} 包一层变布尔探针：\<close>

ML_val \<open>
  val has_cons_swap = can (Proof_Context.get_thm @{context}) "cons_swap"
  val has_bogus = can (Proof_Context.get_thm @{context}) "no_such_thm"
  val _ = writeln ("cons_swap 在库: " ^ @{make_string} has_cons_swap)
  val _ = writeln ("no_such_thm 在库: " ^ @{make_string} has_bogus)
\<close>

subsection \<open>41.5 输出通道与纪律\<close>

text \<open>四个输出函数，纪律不同：

  - @{verbatim "writeln"}：普通信息（教程标记区间用它，可验证）；
  - @{verbatim "tracing"}：调试追踪（构建里也进日志，但语义上"可丢"）；
  - @{verbatim "warning"}：带前缀 warning（要节制）；
  @{verbatim "error"}：抛异常中断（只用于"不该发生"）。

教程的验证脚本只比对 @{verbatim "writeln"} 出来的标记区间，
@{verbatim "tracing"} 的内容两遍可能不同（并行/缓存），别放进关键区间。\<close>

subsection \<open>41.6 坑位清单（实测）\<close>

text \<open>1. ML 块里的中文：源文件是 UTF-8，ML 字符串常量里的中文
   在 Windows 控制台可能显示乱码，但字节比对不受影响（标记行
   本身是中文，已全章验证）。
2. @{verbatim "@{thm 名字"} 打错 = **编译错误**，构建直接失败——
   这正是反引号的价值，别用字符串拼名字绕过它。
3. @{verbatim "ML_val"} 里写 @{verbatim "val _ = ..."} 之外的顶层
   表达式：警告"值被丢弃"，构建不失败但污染日志。
4. @{verbatim "@{context}"} 在 @{verbatim "ML"} 块（理论级）里拿到
   的是**全局上下文**的 Proof.context，没有证明局部假设——
   证明局部的上下文要走第 42 章的 tactic 通道。
5. 反引号在**字符串字面量内**不展开：@{verbatim "\"@{thm x}\""}
   就是六个字符的普通串。\<close>

thm cons_swap

ML \<open>writeln "==== 41 结束 ===="\<close>

end
