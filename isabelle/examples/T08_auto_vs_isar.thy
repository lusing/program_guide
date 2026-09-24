theory T08_auto_vs_isar
  imports Main
begin

section \<open>8.1 自动化方法的分工\<close>

text \<open>Isabelle 有一整柜自动化方法。知道"先叫谁"比死记语法重要：
@{verbatim "simp"} 重写，@{verbatim "auto"} 重写+拆分，@{verbatim "blast"}
做命题逻辑，@{verbatim "force"} 重写+拆分+搜索，@{verbatim "metis"}
是定理搜索器。本章在同一批命题上试它们。\<close>

ML \<open>writeln "==== 08 开始 ===="\<close>

subsection \<open>8.2 同一命题，不同方法\<close>

lemma A1: "(A \<and> B) \<longrightarrow> B"
  by simp

lemma A2: "(A \<and> B) \<longrightarrow> B"
  by blast

lemma A3: "(A \<and> B) \<longrightarrow> B"
  by auto

lemma A4: "(\<forall>x. P x \<and> Q x) \<longrightarrow> (\<forall>x. P x)"
  by blast

lemma A5: "(\<exists>x. P x) \<and> (\<exists>x. Q x) \<longleftrightarrow> (\<exists>x y. P x \<and> Q y)"
  by blast

text \<open>纯命题/量词的活交给 @{verbatim "blast"}：它不解函数方程，
但拆连接词、找量词实例很利落。@{verbatim "auto"} 更像
"simp + 拆分连接词 + 一点搜索"，能吃下多数日常目标。\<close>

subsection \<open>8.3 需要等式推理时，simp 才能上场\<close>

fun my_rev :: "'a list \<Rightarrow> 'a list" where
  "my_rev [] = []"
| "my_rev (x # xs) = my_rev xs @ [x]"

lemma my_rev_app: "my_rev (xs @ ys) = my_rev ys @ my_rev xs"
  by (induction xs) simp_all

lemma "my_rev (my_rev [1::nat, 2, 3]) = [1, 2, 3]"
  by (simp add: my_rev_app)

text \<open>这三条如果换成 @{verbatim "blast"} 一定失败：
blast 不知道 @{verbatim "my_rev"} 的方程。
经验顺序：simp → auto → force → blast → metis。\<close>

subsection \<open>8.4 apply 风格 vs Isar 风格\<close>

lemma apply_style: "my_rev (my_rev xs) = xs"
  apply (induction xs)
   apply simp
  apply (simp add: my_rev_app)
  done

lemma isar_style: "my_rev (my_rev xs) = xs"
proof (induction xs)
  case Nil
  then show ?case by simp
next
  case (Cons a xs)
  then show ?case by (simp add: my_rev_app)
qed

text \<open>两种风格证明的是同一件事。apply 风格里目标必须靠脑补；
Isar 风格把 @{verbatim "case"} 名与当前目标摆在明面上，
是维护大型理论时的默认选择。第 12、13 章系统讲 Isar。\<close>

subsection \<open>8.5 什么时候该收手\<close>

text \<open>自动化不是越猛越好：@{verbatim "blast"} 在含大量等式的
目标上会指数爆炸，@{verbatim "metis"} 更是"证明很好，人看不懂"。
工程上的取舍：把关键步骤写成显式引理，最后一行留给自动化。\<close>

ML \<open>writeln "==== 08 结束 ===="\<close>

end
