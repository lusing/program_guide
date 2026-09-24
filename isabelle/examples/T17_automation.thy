theory T17_automation
  imports Main
begin

section \<open>17.1 自动化的工具箱\<close>

text \<open>本章盘点"想不出证明时该叫谁来"。按代价从低到高：
@{verbatim "simp"} → @{verbatim "auto"} → @{verbatim "force"} →
@{verbatim "blast"} → @{verbatim "meson"} → @{verbatim "metis"}。
以及"找不到引理"时的检索手段 @{verbatim "find_theorems"}。\<close>

ML \<open>writeln "==== 17 开始 ===="\<close>

subsection \<open>17.2 metis：一阶搜索器\<close>

lemma metis_demo1: "A \<and> B \<longrightarrow> B \<and> A"
  by metis

lemma metis_demo2: "(\<exists>x. P x) \<and> (\<exists>x. Q x) \<longrightarrow> (\<exists>x. P x \<or> Q x)"
  by metis

text \<open>@{verbatim "metis"} 做的是"给一堆事实，找一阶证明"，
它不理解函数定义，但很擅长把已有引理拼起来：\<close>

lemma metis_demo3: "xs @ (ys @ zs) = (xs @ ys) @ zs \<Longrightarrow> xs @ ys @ zs = xs @ (ys @ zs)"
  by metis

subsection \<open>17.3 显式喂引理给 metis\<close>

lemma append_assoc_rev: "(xs @ ys) @ zs = xs @ (ys @ zs)"
  by simp

lemma metis_with_facts: "rev (rev (xs @ ys)) = xs @ ys"
  by (metis rev_append rev_rev_ident)

text \<open>括号里的 @{verbatim "metis"} 是"方法带参数"：显式列出要用的引理。
不加参数时 metis 会用上下文里的所有事实，规模一大就变慢。\<close>

subsection \<open>17.4 meson 与 blast 的分工\<close>

lemma meson_demo: "(A \<longrightarrow> B) \<and> A \<longrightarrow> B"
  by meson

lemma blast_demo: "(A \<or> B) \<and> \<not> A \<longrightarrow> B"
  by blast

subsection \<open>17.5 find_theorems：库里有什么\<close>

text \<open>@{verbatim "find_theorems"} 按模式搜事实。它的输出会作为
Output 消息出现在构建日志里——本教程的实测输出就是这么来的。\<close>

find_theorems "rev (_ @ _) = _"

find_theorems name: "List.rev"

subsection \<open>17.6 反例与压力测试：quickcheck 的位置\<close>

text \<open>@{verbatim "quickcheck"} 在提交证明前先"跑数据"找反例，
能省下大量"证一个假命题"的时间。它会往日志里写
@{verbatim "Counterexample found"} 或 @{verbatim "No counterexample"}。
由于反例搜索依赖随机种子，本教程不把它的输出放进
逐字节比对区间——只把它当交互工具用。\<close>

text \<open>自检的低成本替代：先用 @{verbatim "value"} 拿具体数据"试算"，
发现不对再回到引理。下面两条就是"手测"出来的正确/错误对照：\<close>

value "rev ([1::nat] @ [2])"
value "rev [1::nat] @ rev [2]"

text \<open>对照可见：@{verbatim "rev (xs @ ys)"} 不等于
@{verbatim "rev xs @ rev ys"}，正确形式是我们熟悉的 @{verbatim "rev_append"}：\<close>

lemma "rev (xs @ ys) = rev ys @ rev xs"
  by (induction xs) simp_all

ML \<open>writeln "==== 17 结束 ===="\<close>

end
