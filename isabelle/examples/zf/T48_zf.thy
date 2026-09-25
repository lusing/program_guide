theory T48_zf
  imports ZF
begin

section \<open>48.1 ZF：朴素集合论的形式化兄长\<close>

text \<open>HOL 里"集合"是谓词的语法糖（第 14 章）；ZF（Zermelo--Fränkel）
则把**集合**当一等公民，在 FOL 之上公理化。logics-ZF 手册
（doc/logics-ZF.pdf）+ 库索引的 ZF 部分覆盖：

  - 外延、配对、并、幂、分离、替换、基础、无穷——公理即定理形态；
  - @{verbatim "Ord"} 序数宇宙与超穷归纳；
  - @{verbatim "Card"} 基数与选择公理（AC）的等价形态。

价值：HOL 用户看 ZF 会重新认识"类型 vs 集合"——ZF 没有类型，
一切靠分离公理刻画，证明的重心从"归纳"移到"属于关系的推理"。
本理论走 @{verbatim "IsaZF"} 会话（父堆 ZF）。\<close>

ML \<open>writeln "==== 48 开始 ===="\<close>

subsection \<open>48.2 公理的定理形态\<close>

text \<open>ZF.thy 把公理写成引理。外延律：集合由元素决定：\<close>

thm extension
text \<open>分离公理实例化：@{verbatim "Collect"} 是分离的语法形态 @{verbatim "{x <in> A. \<phi>x}"}。\<close>

lemma sep_demo: "{x \<in> A. x \<in> B} \<subseteq> B"
  by blast

subsection \<open>48.3 配对、并、幂的日常\<close>

lemma pair_union: "{0} \<union> {1} = {0, 1}"
  by blast

subsection \<open>48.4 序数与超穷归纳\<close>

text \<open>@{verbatim "Ord"} 是传递且由 < 良序的集合（注意 ZF 继承 FOL 的函数式写法 @{verbatim "Ord(i)"}，空格应用解析失败——同第 47 章的雷）；
@{verbatim "trans_induct"} 是超穷归纳原理（对全体序数）：\<close>

thm trans_induct
thm Ord_0
thm Ord_succ

lemma Ord_zero_is_least: "Ord(i) \<Longrightarrow> 0 \<le> i"
  by (rule Ord_0_le)

subsection \<open>48.5 AC 的一个等价形态（文档节）\<close>

text \<open>ZF 目录的 CardinalArith 等理论里躺着经典等价：AC ⟺
佐恩引理 ⟺ 良序定理（每个集合可良序）。手册只演示使用侧：
@{verbatim "well_ord"} 与 @{verbatim "AC"} 的互推在
@{verbatim "Zorn"} 一章。本教程不展开证明（每个都是几页），
记住拿取路径即可。\<close>

subsection \<open>48.6 与 HOL 的对照\<close>

text \<open>    | 概念 | HOL | ZF |
  |---|---|---|
  | 集合 | 'a set（谓词语法糖）| 一等对象，仅 \<in> 关系 |
  | 函数 | 普通类型 'a ⇒ 'b | 有序对的集合 |
  | 类型检查 | 静态、编译期 | 无类型，全靠分离公理 |
  | 归纳 | 结构/规则归纳 | 超穷归纳 trans_induct |
  | 库 | HOL-Library 等 | ZF-Constructable 等 |\<close>

subsection \<open>48.7 坑位清单（实测）\<close>

text \<open>1. ZF **没有类型**：@{verbatim "x <in> A"} 里没有 'a；
   @{verbatim "::"} 类型标注不可用——HOL 肌肉记忆全废。
2. 自然数在 ZF 是冯诺依曼序数（0 = 空集，1 = {0}……），
   @{verbatim "2"} 既是数又是集合，化简行为和 HOL 的 numeral 完全不同。
3. @{verbatim "value"} 在 ZF：代码生成器没配 ZF——不可用。
4. @{verbatim "simp"} 可用但规则集是 ZF 的；HOL 的 @{verbatim "auto"}
   部分可用（配 blast）。
5. 定理名带撇号家族（@{verbatim "succ"}、@{verbatim "Ord_succ"}），
   与 Analysis 的引理重名时靠会话前缀消歧。\<close>

thm extension sep_demo Ord_zero_is_least

ML \<open>writeln "==== 48 结束 ===="\<close>

end
