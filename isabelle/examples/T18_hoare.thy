theory T18_hoare
  imports "HOL-Hoare.Hoare_Logic"
begin

section \<open>18.1 从手写规则到使用 HOL-Hoare\<close>

text \<open>本章直接使用 Isabelle2026 发行版的 HOL-Hoare 会话。
它提供 WHILE 语言、部分正确性与完全正确性语义、验证条件生成器，
以及从完全正确性定理提取结果的定理。\<close>

ML \<open>writeln "==== 18 开始 ===="\<close>

subsection \<open>18.2 三元组到底断言什么\<close>

text \<open>Sem 是程序的大步语义；Valid 是部分正确性，ValidTC 是完全正确性。
打印定义和两条连接定理，明确它们不是同一个概念。\<close>

thm Valid_def
thm ValidTC_def
thm tc_implies_pc
thm Sem_deterministic

subsection \<open>18.3 从 VARS 到状态元组\<close>

text \<open>VARS 后面的名字组成程序状态。赋值、条件和断言由语法翻译器
转换成 Basic、Seq、Cond、While 及状态上的谓词。\<close>

thm SkipRule
thm BasicRule
thm SeqRule
thm CondRule

subsection \<open>18.4 第一个程序：赋值与 vcg\<close>

lemma increment: "VARS (x::int)
  {x = a}
  x := x + 1
  {x = a + 1}"
  by vcg_simp

text \<open>小写 a 是逻辑变量，用来记住 x 的初值；它不在 VARS 列表里，
因此不会被程序赋值改变。\<close>

thm increment

subsection \<open>18.5 条件与顺序\<close>

lemma maximum: "VARS (x::int) y m
  {True}
  IF x < y THEN m := y ELSE m := x FI
  {m = max x y}"
  by vcg_simp

subsection \<open>18.6 循环部分正确性：不变式\<close>

lemma power_pc: "VARS (p::int) i
  {True}
  p := 1;
  i := 0;
  WHILE i < n
  INV {p = x^i \<and> i \<le> n}
  DO p := p * x;
     i := i + 1
  OD
  {p = x^n}"
  apply vcg_simp
  by auto

text \<open>循环不变式必须同时完成三件事：初始化后成立、循环体保持它、
它与循环条件为假共同推出后件。n 是自然数，i 也由上下文推断为 nat。\<close>

thm power_pc
thm WhileRule

subsection \<open>18.7 vcg 不是自动证明器\<close>

lemma reverse_pc: "VARS (xs::int list) ys
  {xs = X}
  ys := [];
  WHILE xs \<noteq> []
  INV {rev xs @ ys = rev X}
  DO ys := hd xs # ys;
     xs := tl xs
  OD
  {ys = rev X}"
  apply vcg_simp
  apply (simp add: neq_Nil_conv)
  apply auto
  done

text \<open>这里先用 vcg_simp 生成并化简验证条件，再用列表引理和 auto
处理剩余目标。VCG 只负责把程序语义目标变成 HOL 目标，不负责发明数学证明。\<close>

subsection \<open>18.8 部分正确性不保证终止\<close>

lemma divergence_pc: "VARS (x::nat)
  {True}
  WHILE True
  INV {True}
  DO SKIP
  OD
  {False}"
  by vcg_simp

text \<open>这条定理不是矛盾：循环没有终态，所以“若终止则满足后件” vacuously 成立。
把它与下面的完全正确性例子对照，就能看清方括号三元组多出的保证。\<close>

thm divergence_pc

subsection \<open>18.9 完全正确性：VAR 与 vcg_tc\<close>

lemma power_tc: "VARS (p::int) i
  [True]
  p := 1;
  i := 0;
  WHILE i < n
  INV {p = x^i \<and> i \<le> n}
  VAR {n - i}
  DO p := p * x;
     i := i + 1
  OD
  [p = x^n]"
  apply vcg_tc_simp
  by auto

text \<open>变式 n-i 是 nat。每次进入循环体时有 i<n，执行 i:=i+1 后它严格减小；
不变式中的 i\<le>n 同时排除了自然数截断减法掩盖不终止的可能。\<close>

thm power_tc
thm WhileRuleTC

subsection \<open>18.10 列表程序与终止性\<close>

lemma reverse_tc: "VARS (xs::int list) ys
  [xs = X]
  ys := [];
  WHILE xs \<noteq> []
  INV {rev xs @ ys = rev X}
  VAR {length xs}
  DO ys := hd xs # ys;
     xs := tl xs
  OD
  [ys = rev X]"
  apply vcg_tc_simp
  apply (auto simp: neq_Nil_conv)
  done

subsection \<open>18.11 从完全正确性提取结果\<close>

lemmas power_pc_from_tc = tc_implies_pc[OF power_tc]

text \<open>完全正确性蕴含部分正确性，所以刚才的 power_tc 可以直接得到
一个花括号三元组。更一般地，tc_extract_function 给出满足后件的选择函数。\<close>

thm power_pc_from_tc
thm tc_extract_function

subsection \<open>18.12 HOL-Hoare 其他模块与使用边界\<close>

text \<open>Hoare_Logic_Abort 用 option 状态建模运行时错误；Pointers0、Heap、
HeapSyntax 与 Pointer_Examples 处理指针程序；SepLogHeap 和 Separation
提供分离逻辑断言；SchorrWaite 是更大的指针算法案例。
这些扩展与 Hoare_Logic 定义了同名语义常数，应按需选择理论，
不要把所有模块无差别地同时导入。\<close>

ML \<open>writeln "==== 18 结束 ===="\<close>

end
