theory Integers
  imports "ZF.Int"
begin

text \<open>第 69 章：有限与无限、整数与有理数（冯琦 §1.3.5 + §1.4）。
Isabelle/ZF 的官方整数 \<^term>\<open>int\<close> 用等价类构造；冯琦用典型
代表元。这里以官方环律为对照锚点，复刻书页 61 的分情形结构。\<close>

subsection \<open>官方锚点：ZF/Int 的整数环\<close>

text \<open>ZF/Int.thy：\<^term>\<open>zadd\<close>、\<^term>\<open>zmult\<close> 的交换/结合律
与分配律——定理 1.31 的官方版本：\<close>

lemma zadd_commute_check: "z $+ w = w $+ z"
  by (rule zadd_commute)

lemma zmult_commute_check: "z $* w = w $* z"
  by (rule zmult_commute)

subsection \<open>冯琦的典型代表元（定义 1.36 的形状）\<close>

text \<open>负整数编码为有序对 \<^term>\<open>\<langle>1, \<langle>m, 1\<rangle>\<rangle>\<close>（符号位+数值位，
补码思想的集合论原型）。绝对值函数：\<close>

definition absz :: "i \<Rightarrow> i" where
  "absz(z) \<equiv> if znegative(z) then $- z else z"

lemma absz_neg [simp]: "znegative(z) \<Longrightarrow> absz(z) = $- z"
  by (simp add: absz_def)

lemma absz_pos [simp]: "\<not> znegative(z) \<Longrightarrow> absz(z) = z"
  by (simp add: absz_def)

end
