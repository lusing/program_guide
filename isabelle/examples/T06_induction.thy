theory T06_induction
  imports Main
begin

section \<open>6.1 induct：把证明拆成基例与归纳步骤\<close>

text \<open>归纳是 HOL 证明的主力。本章逐帧回放第 2 章那条
@{verbatim "shu_append"}，看清每个阶段的目标长什么样，
并还原一次"归纳变量没泛化"的经典翻车。\<close>

ML \<open>writeln "==== 06 开始 ===="\<close>

fun shu :: "'a list \<Rightarrow> 'a list" where
  "shu [] = []"
| "shu (x # xs) = shu xs @ [x]"

subsection \<open>6.2 Isar 风格：case Nil / case Suc\<close>

lemma shu_append: "shu (xs @ ys) = shu ys @ shu xs"
proof (induction xs)
  case Nil
  then show ?case by simp
next
  case (Cons a xs)
  then show ?case by simp
qed

text \<open>归纳自带两个子目标：@{verbatim "Nil"} 与 @{verbatim "Suc"}；
@{verbatim "then"} 把归纳前提带进下一步。同样的证明用 apply 风格
是三行——目标只能脑补，这是第 12 章转向 Isar 的理由之一。\<close>

lemma shu_append_apply: "shu (xs @ ys) = shu ys @ shu xs"
  apply (induction xs)
   apply simp
  apply simp
  done

subsection \<open>6.3 归纳泛化：itrev 案例\<close>

fun itrev :: "'a list \<Rightarrow> 'a list \<Rightarrow> 'a list" where
  "itrev [] ys = ys"
| "itrev (x # xs) ys = itrev xs (x # ys)"

text \<open>想证 @{verbatim "itrev xs [] = shu xs"}：归纳步骤里出现
@{verbatim "itrev xs [a]"}，而归纳前提只谈 @{verbatim "itrev xs []"}，
一步就卡死。出路是把命题先泛化成带自由变量 ys 的形式，
证完再代特例：\<close>

lemma itrev_shu: "itrev xs ys = shu xs @ ys"
proof (induction xs arbitrary: ys)
  case Nil
  then show ?case by simp
next
  case (Cons a xs)
  then show ?case by simp
qed

corollary itrev_shu_empty: "itrev xs [] = shu xs"
  by (simp add: itrev_shu)

text \<open>@{verbatim "arbitrary: ys"} 的作用：让 ys 随归纳重新命名，
归纳前提变成"对当前 ys 任意取值都成立"。没有它，
@{verbatim "Suc"} 情形里的 @{verbatim "itrev xs (a # ys)"}
与前提对不上号。\<close>

subsection \<open>6.4 cases：有限分支的归纳表亲\<close>

lemma nat_0_or_Suc: "n = 0 \<or> (\<exists>m. n = Suc m)"
  by (cases n) auto

value "(case (1::nat) of 0 \<Rightarrow> (0::nat) | Suc n \<Rightarrow> n)"

subsection \<open>6.5 观察归纳原理本身\<close>

text \<open>@{verbatim "shu.induct"} 是 datatype 送给归纳的"提词器"：
两个前提对应两个构造器。打印出来看看。\<close>

ML \<open>writeln (@{make_string} @{thm shu.induct})\<close>

lemma shu_shu: "shu (shu xs) = xs"
  by (induction xs) (auto simp: shu_append)

lemma shu_shu_shu: "shu (shu (shu xs)) = shu xs"
  by (simp add: shu_shu)

ML \<open>writeln "==== 06 结束 ===="\<close>

end
