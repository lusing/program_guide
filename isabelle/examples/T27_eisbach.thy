theory T27_eisbach
  imports Main "HOL-Eisbach.Eisbach_Tools"
begin

section \<open>27.1 为什么要自定义证明方法\<close>

text \<open>第 8 章教了 apply 风格、第 12–13 章教了 Isar。两者都是**用现成方法**
（@{verbatim "simp"}/@{verbatim "rule"}/@{verbatim "metis"}/@{verbatim "blast"}）。
当同一个"套路"在证明里出现五六次时，把它命名成一个方法，就能：

  1. 让 apply 链像 Isar 一样有语义分段；
  2. 把 @{verbatim "simp add: foo bar baz"} 这种"打包假设"集中管理；
  3. 在 @{verbatim "match"} 里按目标形状分派。

这就是 **Eisbach**（@{verbatim "method"} 命令 + @{verbatim "match"} 方法）
解决的问题。它需要 HOL 之外的 @{verbatim "HOL-Eisbach"} 会话：本教程的 ROOT
把父会话从 @{verbatim "HOL"} 改成 @{verbatim "HOL-Eisbach"}，全量 build 多约 20 秒。\<close>

ML \<open>writeln "==== 27 开始 ===="\<close>

subsection \<open>27.2 最小方法：命名一串 introduction\<close>

text \<open>@{verbatim "method intro_pair = (rule conjI | rule impI)"}：
@{verbatim "|"} 是**顺序回退**（试第一条，失败试第二条），语义与 apply 风格
的 @{verbatim "(rule A ORELSE rule B)"} 对齐。\<close>

method intro_pair = (rule conjI | rule impI)

text \<open>演示 @{verbatim "intro_pair"} 的**顺序回退**：目标 @{verbatim "P \<longrightarrow> Q \<and> R"}
先用 @{verbatim "impI"}（@{verbatim "conjI"} 不匹配、失败），进入
@{verbatim "P \<Longrightarrow> Q \<and> R"} 后再用 @{verbatim "conjI"}。\<close>

lemma "P \<longrightarrow> Q \<and> R"
  apply intro_pair
  apply intro_pair
  oops

text \<open>@{verbatim "oops"} 是因为 @{verbatim "Q"} @{verbatim "R"} 都是原子命题、
没有前提可用；这里只演示方法能走通两步。真正能闭合的见下面
@{verbatim "intro_pair_works"}。\<close>

lemma intro_pair_works: "P \<Longrightarrow> Q \<Longrightarrow> P \<and> Q"
  apply intro_pair
  apply assumption
  apply assumption
  done

subsection \<open>27.3 项参数：@{verbatim "for"}\<close>

text \<open>@{verbatim "for X :: 'a"} 声明"**项**"参数（按位置传）。下面
@{verbatim "allE_at"} 把 @{verbatim "erule allE[where x = X]"} 打包成方法，
从 @{verbatim "\<forall>x. P x"} 得到 @{verbatim "P X"}。\<close>

method allE_at for X :: nat = (erule allE[where x = X], assumption)

lemma "(\<forall>x::nat. x = x) \<Longrightarrow> (0::nat) = 0"
  by (allE_at 0)

subsection \<open>27.4 事实参数：@{verbatim "uses"}\<close>

text \<open>@{verbatim "uses defs"} 声明"**事实**"参数（调用点用 @{verbatim "[thm1, thm2]"}
按位置传，或 @{verbatim "defs: thm1 thm2"} 命名传）。\<close>

method simp_plus uses defs = simp add: defs

lemma "rev (rev xs) = (xs :: 'a list)"
  by (simp_plus defs: rev_rev_ident)

subsection \<open>27.5 @{verbatim "match conclusion"}：按目标形状分派\<close>

text \<open>@{verbatim "match conclusion in ... for ..."} 是 Eisbach 的**核心结构**：
拿到目标后按模式匹配、绑定变量、进入 @{verbatim \<open>\<open>...\<close>\<close>} 里的
方法序列。下面在"目标是 @{verbatim "P \<and> Q"}"时打印两支、走 @{verbatim "rule conjI"}，
否则回退到 @{verbatim "simp"}。\<close>

method split_or_simp =
  (match conclusion in
    "P \<and> Q" for P Q \<Rightarrow> \<open>print_term P, print_term Q, rule conjI\<close>
  \<bar> _ \<Rightarrow> \<open>simp\<close>)

lemma "P \<Longrightarrow> Q \<Longrightarrow> P \<and> Q"
  apply split_or_simp    \<comment> \<open>目标是 @{verbatim "P \<and> Q"}：走 @{verbatim "conjI"}，拆成 P、Q 两个子目标\<close>
  apply assumption
  apply split_or_simp    \<comment> \<open>剩下的目标是 @{verbatim "Q"}：走 @{verbatim "simp"} 分支，直接闭合\<close>
  done

lemma "P \<and> P \<Longrightarrow> P"
  apply split_or_simp    \<comment> \<open>目标是 @{verbatim "P"}：走 @{verbatim "simp"} 分支，直接闭合\<close>
  done

subsection \<open>27.6 @{verbatim "match premises"}：找一条可用假设\<close>

text \<open>@{verbatim "match premises in U: \"P \<and> Q\" for P Q \<Rightarrow> ..."}
在**当前上下文假设**里找一条形状匹配的，命名成 @{verbatim "U"}。\<close>

method destruct_and =
  (match premises in U: "P \<and> Q" for P Q \<Rightarrow> \<open>rule conjunct1[OF U]\<close>)

lemma "P \<and> Q \<Longrightarrow> P"
  by destruct_and

subsection \<open>27.7 递归：@{verbatim "same+"} 与自引用\<close>

text \<open>@{verbatim "m+"} 让方法 @{verbatim "m"} 反复应用直到失败。这条语法
跟 apply 风格一致，Eisbach 直接沿用。\<close>

method my_intro = (rule conjI | rule impI | rule allI)

lemma "(\<forall>x. P x) \<longrightarrow> P y"
  apply (my_intro+)
  apply (erule allE)
  apply assumption
  done

subsection \<open>27.8 与 @{verbatim "ML_method"} 的分界\<close>

text \<open>更底层的做法是写 @{verbatim "ML_method"}（直接给 @{verbatim "(context, ...)"}.
Eisbach 的定位是"90% 的场景够用、比 @{verbatim "ML_method"} 短得多"；真要做
交互式证明分析器、复杂 goal-case 分派，才下沉到 Isabelle/ML。
本教程**不**演示 @{verbatim "ML_method"}（第 1 章"工具链边界"里说过，ML 层不在覆盖范围）。\<close>

ML \<open>writeln "==== 27 结束 ===="\<close>

end
