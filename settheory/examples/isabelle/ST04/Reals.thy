theory Reals
  imports "ZF-Constructible.Formula" "ZF.CardinalArith"
begin

text \<open>
第 04 章 实数：序数幂 ω^ω 与函数空间 ω→ω 的区分，
以及在 ZF 内做对角线论证的骨架。

注意记号陷阱：Jech 用 \<omega>\<omega> 同时表示（i）序数幂
（一个可数序数，第 02 章）与（ii) 函数空间 {f : f:\<omega>\<rightarrow>\<omega>}
（基数 2^\<aleph>0 侧，Baire 空间）。ZF 里两者是完全不同的对象。
\<close>

section \<open>函数空间在 ZF 中的形态\<close>

text \<open>ZF 的函数 = 单值关系；函数集 = Pi(A, B)：\<close>
thm Pi_def

text \<open>自然数函数的叠代应用有库词汇（fun_apply）：\<close>
thm apply_equality

section \<open>对角线骨架：任何 F : \<omega> \<rightarrow> (\<omega>\<rightarrow>\<omega>) 都会漏掉 g)\<close>

text \<open>对角函数 g(n) = F(n)(n) + 1 逐点区别于每个 F(n)。
在 ZF 里完整写出需要函数应用的外延性处理；这里把
构造做成显式定义并证明点态区别的核心引理。\<close>

definition diag_of :: "[i, i] \<Rightarrow> i" where
  "diag_of(F, n) \<equiv> succ(F`n`n)"

lemma diag_differs:
  assumes "F: \<omega> \<rightarrow> (\<omega> \<rightarrow> \<omega>)"
  shows "\<forall>n \<in> \<omega> . diag_of(F, n) \<noteq> (F`n)`n"
proof (intro ballI notI)
  fix n
  assume "n \<in> \<omega>"
  assume eq: "diag_of(F, n) = (F`n)`n"
  then have s: "succ((F`n)`n) = (F`n)`n" unfolding diag_of_def .
  have "(F`n)`n \<in> succ((F`n)`n)" by (rule succI1)
  then have "(F`n)`n \<in> (F`n)`n" by (simp only: s)
  then show False by (rule mem_irrefl)
qed

text \<open>结论：若把 F 视作"函数的枚举"，g = diag_of(F, \<cdot>)
      是逃逸者——实数（乃至 Baire 空间）不可数性的序数侧骨架。\<close>

end
