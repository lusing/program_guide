theory T32_sledgehammer
  imports Main
begin

section \<open>32.1 把"选引理"交给机器\<close>

text \<open>第 17 章的代价阶梯走到 @{verbatim "metis"} 那一级：你手工挑两三条
事实塞给它。挑哪几条？这就是 Sledgehammer（锤子）替你做的事：

  1. 把目标连同上下文翻译成一阶逻辑；
  2. 发给外部自动定理证明器（ATP）或 SMT 求解器；
  3. 拿到证明后，把用到的引理集合**最小化**；
  4. 回放（preplay）一条 Isabelle 能直接执行的命令
     ——@{verbatim "metis"}、@{verbatim "smt"}、@{verbatim "auto"} 等。

全程本地：发行版 @{verbatim "contrib/"} 里打包了 @{verbatim "e-3.2"}、
@{verbatim "cvc5-1.2.0"}、@{verbatim "z3-4.4.0pre"}、@{verbatim "verit"}、
@{verbatim "minisat"}（后两个也服务 Nitpick/HTTP 之外的离线场景），
不需要网络。\<close>

subsection \<open>32.2 第一个大坑：sledgehammer 是命令，不是方法\<close>

text \<open>@{verbatim "sledgehammer"} 在 Isabelle2025-2 里**只有命令形态**
（Outer_Syntax.command 注册，源码 @{verbatim "Sledgehammer/sledgehammer_commands.ML"}
里搜不到任何 Method.setup）。三条实测：

  - @{verbatim "by sledgehammer"} —— 语法错误；
  - @{verbatim "by (sledgehammer)"} —— 同样语法错误
    （报 @{verbatim "keyword ( expected"}，位置指到 lemma 行，极具误导性）；
  - @{verbatim "lemma ... sledgehammer [provers = e] by simp"} —— 正确。

命令在证明中间可以出现（它是诊断命令，跑 ATP、打建议，不改变目标），
真正闭合目标的是它**建议**的那条命令，由你显式写出来。这也正是批量构建
可验证的原因：建议含计时（如 @{verbatim "(0.0 ms)"}）不稳定，但落地的
@{verbatim "by (metis ...)"} 是确定性的。\<close>

lemma g1: "rev (xs @ ys) = rev ys @ rev xs"
  sledgehammer [provers = e]
  by simp

lemma g2: "P \<and> Q \<longrightarrow> Q \<and> P"
  sledgehammer [provers = cvc5]
  by blast

lemma g3: "map f (xs @ ys) = map f xs @ map f ys"
  sledgehammer [provers = "e z3"]
  by (metis map_append)

subsection \<open>32.3 问锤子要 prover 清单\<close>

text \<open>@{verbatim "sledgehammer supported_provers"} 列出所有已注册求解器。
本机输出（离线可用的是不带 @{verbatim "remote_"} 前缀且已安装的那批）：
@{verbatim "agsyhol, alt_ergo, cvc5, cvc5_proof, dummy_smtlib, e, iprover,
leo2, leo3, satallax, spass, vampire, vampire_smt_dt, vampire_smt_nodt,
verit, z3, zipperposition, remote_..."}。注意"supported"是**注册了配置**，
不等于本机装了（@{verbatim "vampire"} 在 Windows contrib 里就没有）。\<close>

lemma "1 = (1::nat)"
  sledgehammer supported_provers
  by simp

subsection \<open>32.4 metis：锤子最常递给你的锤柄\<close>

text \<open>一阶目标证明后，锤子几乎总是回放 @{verbatim "metis"}
（第 17 章讲过的逻辑完备核心 + 计时开销）。带事实的形态：\<close>

lemma append_cut: "xs @ ys = zs @ us \<Longrightarrow> length xs = length zs \<Longrightarrow> ys = us"
  sledgehammer [provers = e]
  by (metis append_eq_append_conv)

text \<open>读建议的姿势：盯着 @{verbatim "Try this:"} 后面那行，
连同它给出的事实列表，原样抄进你的 @{verbatim "by"}。事实列表越短越好——
这就是"最小化"（minimize）阶段的价值：锤子先拿到一大把引理证出来，
再逐条删到不可再删。\<close>

subsection \<open>32.5 smt：算术与量词的重炮\<close>

text \<open>@{verbatim "smt"} 方法把目标交给 SMT 求解器（默认 @{verbatim "z3"}），
带证书重放。它对线性算术、量词组合的目标几乎无往不利，代价是调用重、
结果难预测。两个实测小例：\<close>

lemma smt_linear: "\<not> (a \<le> b \<and> b \<le> a \<and> a \<noteq> (b::int))"
  by smt

text \<open>注意 smt 的边界：它走 Isabelle 的证书重建，**变量乘法视为
未解释函数**——@{verbatim "(x::int) * (y + z) = x * y + x * z"} 这种
环分配律它证不了（实测 @{verbatim "Failed to apply initial proof method"}）。
乘常数（线性）没问题：\<close>

lemma smt_const_ring: "(2::int) * (x + y) = x + x + y + y"
  by smt

subsection \<open>32.6 参数速查（实测有效项）\<close>

text \<open>方括号里写参数，逗号分隔，全都可以进 @{verbatim "sledgehammer_params"}
设默认值：

  - @{verbatim "provers = \"e cvc5 z3\""} —— 参赛名单（空格分隔）；
  - @{verbatim "timeout = 30"} —— 每个求解器的秒数（默认 5；Windows 上
    ATP 冷启动慢，建议放宽）；
  - @{verbatim "verbose = true"} —— 打印每一步，教学时开；
  - @{verbatim "isar_proofs = true"} —— 让它尝试生成 Isar 骨架
    （不是每条建议都能翻成 Isar，失败自动回落 one-liner）；
  - @{verbatim "max_facts"} —— 事实筛选上限，事实库大时调小加速；
  - @{verbatim "min = true"} —— 关掉最小化（默认开，关掉快但建议更啰嗦）。

子命令两枚：@{verbatim "sledgehammer supported_provers"}（32.3 用过）、
@{verbatim "sledgehammer min [provers = e]"}（单独跑最小化）。\<close>

sledgehammer_params [provers = "e cvc5"]

subsection \<open>32.7 什么时候别抡锤\<close>

text \<open>锤子翻不动三类墙：

  1. **归纳**：ATP 不做归纳，含 @{verbatim "Suc (Suc n)"} 结构的目标
     锤子只能瞎猜实例。归纳目标直接 @{verbatim "induct"}，锤子只能当辅助。
  2. **共归纳**：无限对象（第 26/36 章）连有限模型都没有。
  3. **重定义型目标**：结论是你新定义的 @{verbatim "foo"} 的展开，
     事实库里没有 @{verbatim "foo.simps"} 等价引理时，@{verbatim "[simp]"}
     声明比任何 prover 都快。

经验法则：目标里有"结构递归+等式"，先 @{verbatim "induct simp"}；
有"算术+量词"，@{verbatim "smt"}；有一阶逻辑味，先抡锤。\<close>

text \<open>下面是本章验证区间：把被机器认可的定理名打出来。\<close>

ML \<open>writeln "==== 32 开始 ===="\<close>

thm g1
thm g2
thm g3
thm append_cut
thm smt_linear
thm smt_const_ring

ML \<open>writeln "==== 32 结束 ===="\<close>

end
