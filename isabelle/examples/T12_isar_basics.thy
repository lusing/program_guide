theory T12_isar_basics
  imports Main
begin

section \<open>12.1 Isar：可阅读的证明脚本\<close>

text \<open>Isar 是 Isabelle 的结构化证明语言：把证明写成
"假设—结论—理由"的链条，机器校验、人也读得懂。
本章过一遍最常用的句式。\<close>

ML \<open>writeln "==== 12 开始 ===="\<close>

subsection \<open>12.2 have / show / then\<close>

lemma isar_have: "A \<and> B \<longrightarrow> B \<and> A"
proof
  assume h: "A \<and> B"
  from h have b: "B" by (rule conjunct2)
  from h have a: "A" by (rule conjunct1)
  from b a show "B \<and> A" by (rule conjI)
qed

text \<open>@{verbatim "have"} 声明中间结论，@{verbatim "show"} 声明
当前目标；@{verbatim "from x and y show"} 把事实喂给方法。
@{verbatim "⟨B⟩"} 这种引号语法引用的是前一句定理文本本身。\<close>

subsection \<open>12.3 moreover / ultimately：并列推理\<close>

lemma isar_moreover: "A \<and> B \<longrightarrow> B \<and> A"
proof
  assume h: "A \<and> B"
  moreover have "B" by (rule conjunct2[OF h])
  moreover have "A" by (rule conjunct1[OF h])
  ultimately show "B \<and> A" by blast
qed

subsection \<open>12.4 also / finally：等式链\<close>

fun dbl :: "nat \<Rightarrow> nat" where
  "dbl 0 = 0"
| "dbl (Suc n) = Suc (Suc (dbl n))"

lemma isar_calc: "dbl n + dbl n = dbl (n + n)"
proof (induction n)
  case 0
  then show ?case by simp
next
  case (Suc n)
  have "dbl (Suc n) + dbl (Suc n) = Suc (Suc (Suc (Suc (dbl n + dbl n))))"
    by simp
  also have "\<dots> = Suc (Suc (Suc (Suc (dbl (n + n)))))"
    by (simp add: Suc.IH)
  also have "\<dots> = dbl (Suc n + Suc n)"
    by simp
  finally show ?case .
qed

text \<open>@{verbatim "also … finally"} 把一串等式串成链，
@{verbatim "\<dots>"} 指代上一步的右侧。适合"逐步变形"的证明。\<close>

subsection \<open>12.5 by / .. / . 三种收尾\<close>

lemma dot_demo: "A \<longrightarrow> A"
proof (rule impI)
  assume a: "A"
  from a show "A" .
qed

lemma double_dot_demo: "A \<and> A \<longrightarrow> A"
  apply (rule impI)
  apply (erule conjunct1)
  done

text \<open>@{verbatim "by m"} = @{verbatim "proof m qed"}；
@{verbatim ".."} = @{verbatim "by"} 加默认规则；
@{verbatim "."} = 只做一次默认规则（@{verbatim "standard"}）。
写作上：一行能说清用 @{verbatim "by"}，需要分步骤用 @{verbatim "proof"}。\<close>

subsection \<open>12.6 结构化归纳的 case 名\<close>

fun myrev :: "'a list \<Rightarrow> 'a list" where
  "myrev [] = []"
| "myrev (x # xs) = myrev xs @ [x]"

lemma myrev_append: "myrev (xs @ ys) = myrev ys @ myrev xs"
proof (induction xs)
  case Nil
  then show ?case by simp
next
  case (Cons a xs)
  then show ?case by simp
qed

lemma myrev_idem: "myrev (myrev xs) = xs"
proof (induction xs)
  case Nil
  then show ?case by simp
next
  case (Cons a xs)
  then show ?case by (simp add: myrev_append)
qed

ML \<open>writeln "==== 12 结束 ===="\<close>

end
