theory T13_isar_advanced
  imports Main
begin

section \<open>13.1 Isar 的进阶句式\<close>

text \<open>本章处理真实项目里绕不开的句法：@{verbatim "obtain"}、
@{verbatim "consider"}、@{verbatim "subgoal"}、@{verbatim "fix"}。
它们解决的是"事实怎么取出来""分支怎么摆平"。\<close>

ML \<open>writeln "==== 13 开始 ===="\<close>

subsection \<open>13.2 obtain：从存在量词里取出证人\<close>

lemma obtain_demo: "(\<exists>x. P x) \<longrightarrow> (\<exists>x. P x \<or> Q x)"
proof
  assume "\<exists>x. P x"
  then obtain x where "P x" by blast
  then have "P x \<or> Q x" by (rule disjI1)
  then show "\<exists>x. P x \<or> Q x" by (rule exI)
qed

text \<open>@{verbatim "obtain"} 等价于一次 @{verbatim "exE"}：
把 @{verbatim "∃x. P x"} 变成"有某个 x 满足 P x"，
之后 x 就是可用变量。\<close>

subsection \<open>13.3 consider：把多种可能摆成显式分支\<close>

lemma consider_demo: "A \<or> B \<longrightarrow> B \<or> A"
proof
  assume "A \<or> B"
  then consider "A" | "B" by blast
  then show "B \<or> A"
  proof cases
    case 1
    then show ?thesis by (rule disjI2)
  next
    case 2
    then show ?thesis by (rule disjI1)
  qed
qed

text \<open>@{verbatim "consider"} 把"若干种可能"摆成显式分支，
@{verbatim "proof cases"} 里用 @{verbatim "case 1"} @{verbatim "case 2"}
逐个接住。比 @{verbatim "erule disjE"} 更可读，尤其是三个以上分支时。\<close>

subsection \<open>13.4 subgoal for：给子目标命名变量\<close>

lemma subgoal_demo: "(\<forall>x::nat. P x \<longrightarrow> Q x) \<Longrightarrow> P n \<Longrightarrow> Q n"
  apply (subgoal_tac "P n \<longrightarrow> Q n")
   apply (erule mp)
   apply assumption
  apply (drule spec)
  apply assumption
  done

text \<open>上面是 apply 风格的"手动插子目标"。Isar 里更常见的写法是
@{verbatim "subgoal premises prems"} 或直接把变量提出来：\<close>

lemma subgoal_named: "(\<forall>x::nat. P x \<longrightarrow> Q x) \<Longrightarrow> P n \<Longrightarrow> Q n"
proof -
  assume all: "\<forall>x::nat. P x \<longrightarrow> Q x" and pn: "P n"
  from spec[OF all, of n] have "P n \<longrightarrow> Q n" .
  from this and pn show "Q n" by (rule mp)
qed

subsection \<open>13.5 fix / assume / show：块内量化\<close>

lemma fix_demo: "(\<And>x::nat. P x) \<Longrightarrow> (\<forall>x. P x)"
proof
  fix x
  assume h: "\<And>x::nat. P x"
  from h show "P x" .
qed

subsection \<open>13.6 方法组合子：; 与 all_goals\<close>

fun len2 :: "'a list \<Rightarrow> nat" where
  "len2 [] = 0"
| "len2 (x # xs) = 1 + len2 xs"

lemma len2_append: "len2 (xs @ ys) = len2 xs + len2 ys"
  by (induction xs; simp)

text \<open>@{verbatim ";"} 把上一个方法产生的所有子目标都交给下一个方法，
@{verbatim "induction xs; simp"} 就是"归纳完再全化简"的简写。
这一行写法在小型引理里非常常见。\<close>

lemma len2_len: "len2 xs = length xs"
  by (induction xs; simp)

ML \<open>writeln "==== 13 结束 ===="\<close>

end
