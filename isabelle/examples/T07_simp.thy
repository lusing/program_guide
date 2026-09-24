theory T07_simp
  imports Main
begin

section \<open>7.1 simp：化简器的脾气与调教手册\<close>

text \<open>simp 是 Isabelle 里使用频率最高的方法：把目标与前提
当作方程组，从左到右重写直到不动点。本章拆开看它怎么工作、
什么时候失灵、怎么调教。\<close>

ML \<open>writeln "==== 07 开始 ===="\<close>

subsection \<open>7.2 重写的方向性：方程从左向右用\<close>

fun double :: "nat \<Rightarrow> nat" where
  "double 0 = 0"
| "double (Suc n) = Suc (Suc (double n))"

text \<open>@{verbatim "double.simps"} 的方向是
@{verbatim "double (Suc n) ⟶ Suc (Suc (double n))"}：
左边必须是"构造器打头"的图案，重写才会终止。\<close>

lemma "double (double (Suc 0)) = (4::nat)"
  by simp

text \<open>反过来叙述就不一定证得动了：目标里先出现
@{verbatim "(4::nat)"} 时，simp 没有"反方向"的规则可用。
写定义时永远让递归调用出现在方程右边，这是 simp 世界的铁律。\<close>

subsection \<open>7.3 add 与 del：临时扩编与开除\<close>

lemma double_comm: "double n = 2 * n"
  by (induction n) auto

lemma "2 * (3::nat) = double 3"
  by (simp add: double_comm)

text \<open>@{verbatim "add: double_comm"} 只在这一条命令里生效。
要全局开除某条规则用 @{verbatim "del"}——比如标准库把
@{verbatim "Suc"} 展开成 @{verbatim "n + 1"} 的方向，
有时会朝你不想要的地方推。\<close>

text \<open>下面这条看似最朴素，其实证不动：simp 不会把字面量 3
展开成 \<open>Suc (Suc (Suc 0))\<close> 去匹配 \<open>double\<close> 的方程。
展开数字字面量要换方法：\<close>

lemma "double 3 = (6::nat)"
  by eval

lemma "double (Suc (Suc (Suc 0))) = (Suc (Suc (Suc (Suc (Suc (Suc 0))))))"
  by simp

subsection \<open>7.4 assumptions：前提也会被重写\<close>

text \<open>simp 默认把前提也化简（@{verbatim "assms"} 模式）：
假设里的 @{verbatim "m = 0"} 会被替换进目标。\<close>

lemma assumes "m = (0::nat)" shows "double (Suc m) = 2"
  by (simp add: assms)

lemma "m = (0::nat) \<Longrightarrow> double m = 0"
  by simp

subsection \<open>7.5 split：if 与 case 的展开开关\<close>

lemma "double (if n = 0 then 0 else double n) \<ge> (0::nat)"
  by simp

lemma "double (if n = 0 then 0 else 1) \<le> (4::nat)"
  by (simp split: if_split)

text \<open>@{verbatim "split: if_split"} 告诉 simp：把 if 按条件劈成
两条子目标分别处理；@{verbatim "if_split_asm"} 是劈前提的版本。
不劈的时候，simp 面对含 if 的目标常常"化简不动"就停——
这是初学者第二常见的困惑（第一是归纳变量没泛化）。\<close>

lemma "case n of 0 \<Rightarrow> True | Suc m \<Rightarrow> True"
  apply (cases n)
   apply simp
  apply simp
  done

subsection \<open>7.6 失灵现场与诊断\<close>

text \<open>simp 失灵的三大信号：
(1) 目标原封不动返回——没有匹配的规则，先确认是否真的是 simp 规则；
(2) 目标来回横跳——两条规则方向冲突，考虑 @{verbatim "del"}；
(3) 只剩一个卡住的项——缺一条辅助引理，先证它再 @{verbatim "add"}。
诊断工具 @{verbatim "simp_trace"} 在第 22 章演示；
日常先试 @{verbatim "auto"} 与 @{verbatim "blast"}。\<close>

lemma "(\<exists>x. P x) \<longrightarrow> (\<exists>x. P x \<or> Q x)"
  by blast

ML \<open>writeln "==== 07 结束 ===="\<close>

end
