theory S16_hoare_wp
  imports Main
begin

section \<open>16.1 内核证明的主语言：霍尔三元组\<close>

text \<open>
  前面几章一直在讲内核\emph{是什么}。从本章开始讲\emph{怎么证明它}。
  l4v 用的主语言是霍尔逻辑在非确定性状态单子上的实例化，
  定义在 @{verbatim "l4v/lib/Monads/nondet/Nondet_Monad.thy"} 与
  @{verbatim "wp/"} 目录下的 @{verbatim "WP"}、@{verbatim "WPC"} 等理论里。

  核心只有一个谓词 @{verbatim "valid"}（也写作
  @{verbatim "\<lbrace>P\<rbrace> f \<lbrace>Q\<rbrace>"}），读作"从满足 P 的状态出发，
  f 的每个可能结果都满足 Q，而且 f 不会失败"。
\<close>

ML \<open>writeln "==== 16 开始 ===="\<close>

type_synonym ('s,'a) nondet = "'s \<Rightarrow> (('a \<times> 's) set \<times> bool)"

definition kreturn :: "'a \<Rightarrow> ('s,'a) nondet" where
  "kreturn x \<equiv> \<lambda>s. ({(x, s)}, False)"

definition kbind :: "('s,'a) nondet \<Rightarrow> ('a \<Rightarrow> ('s,'b) nondet) \<Rightarrow> ('s,'b) nondet" where
  "kbind m f \<equiv> \<lambda>s. (\<Union>p \<in> fst (m s). fst (f (fst p) (snd p)),
                    snd (m s) \<or> (\<exists>p \<in> fst (m s). snd (f (fst p) (snd p))))"

definition kfail :: "('s,'a) nondet" where "kfail \<equiv> \<lambda>s. ({}, True)"

definition kget :: "('s,'s) nondet" where "kget \<equiv> \<lambda>s. ({(s, s)}, False)"

definition kput :: "'s \<Rightarrow> ('s,unit) nondet" where "kput s' \<equiv> \<lambda>s. ({((), s')}, False)"

subsection \<open>16.2 valid 的定义\<close>

definition valid :: "('s \<Rightarrow> bool) \<Rightarrow> ('s,'a) nondet \<Rightarrow> ('a \<Rightarrow> 's \<Rightarrow> bool) \<Rightarrow> bool" where
  "valid P m Q \<equiv> \<forall>s. P s \<longrightarrow> (\<forall>(r, s') \<in> fst (m s). Q r s') \<and> \<not> snd (m s)"

definition wp :: "('s,'a) nondet \<Rightarrow> ('a \<Rightarrow> 's \<Rightarrow> bool) \<Rightarrow> 's \<Rightarrow> bool" where
  "wp m Q s \<equiv> (\<forall>(r, s') \<in> fst (m s). Q r s') \<and> \<not> snd (m s)"

lemma valid_iff_wp: "valid P m Q \<longleftrightarrow> (\<forall>s. P s \<longrightarrow> wp m Q s)"
  by (simp add: valid_def wp_def)

text \<open>
  @{thm valid_iff_wp} 说明 @{verbatim "valid"} 就是"前置条件蕴含最弱前置条件"。
  @{verbatim "wp"} 是\emph{最弱}的：它精确刻画了"哪些状态能保证 Q"。
\<close>

subsection \<open>16.3 基本规则\<close>

lemma valid_return: "valid P (kreturn x) Q \<longleftrightarrow> (\<forall>s. P s \<longrightarrow> Q x s)"
  by (simp add: valid_def kreturn_def)

text \<open>
  注意 @{verbatim "valid"} 里那个 @{verbatim "\<not> snd"}：
  \emph{失败的程序不满足任何 valid}。这一点与教科书上的霍尔逻辑不同，
  因为教科书里没有"失败"这个状态。l4v 把它并进同一个谓词，
  好处是每条定理都自带"不会失败"这一半。
\<close>

lemma fail_is_not_valid: "P s \<Longrightarrow> \<not> valid P kfail Q"
  by (auto simp: valid_def kfail_def)

text \<open>
  上面这条才是 l4v 里的真实语义：@{verbatim "no_fail"} 是
  @{verbatim "valid"} 的一部分。这也是为什么内核证明里
  @{verbatim "not (valid P f Q)"} 往往不是"后条件错了"，
  而是"这段路径会失败"——两者在同一个谓词里，排查时要分开看。
\<close>

lemma valid_get: "valid P kget (\<lambda>s s'. P s' \<and> s' = s)"
  by (simp add: valid_def kget_def)

lemma valid_put: "valid P (kput s') (\<lambda>_ s''. s'' = s')"
  by (simp add: valid_def kput_def)

subsection \<open>16.4 组合规则：这才是日常用的\<close>

lemma valid_bind:
  "valid P m Q \<Longrightarrow> (\<forall>r. valid (Q r) (f r) R) \<Longrightarrow> valid P (kbind m f) R"
  by (auto simp: valid_def kbind_def; blast)

text \<open>
  @{thm valid_bind} 是顺序组合规则：先证明第一段，再把它的后条件
  当作第二段的\emph{前}条件。l4v 里 @{verbatim "wp"} 战术做的就是
  把一整段 do 记号反复应用这条规则，最后剩下一堆算术与集合条件。
\<close>

lemma strengthen_pre:
  "(\<forall>s. P' s \<longrightarrow> P s) \<Longrightarrow> valid P m Q \<Longrightarrow> valid P' m Q"
  by (auto simp: valid_def)

lemma weaken_post:
  "(\<forall>r s. Q r s \<longrightarrow> R r s) \<Longrightarrow> valid P m Q \<Longrightarrow> valid P m R"
  by (auto simp: valid_def) blast

subsection \<open>16.5 一个内核风格的例子\<close>

text \<open>
  下面这段模拟"取一个槽位里的能力，要求它非空，然后返回它"。
  真实代码就是 @{verbatim "CSpaceAcc_A.thy"} 第 29 行的
  @{verbatim "get_cap"} 加上一个 @{verbatim "assert"}。
\<close>

type_synonym cslot = nat

datatype cap = NullCap | EndpointCap nat

record kstate =
  ks_caps :: "cslot \<Rightarrow> cap"

definition get_cap :: "cslot \<Rightarrow> (kstate,cap) nondet" where
  "get_cap sl \<equiv> \<lambda>s. ({(ks_caps s sl, s)}, False)"

definition get_cap_nonnull :: "cslot \<Rightarrow> (kstate,cap) nondet" where
  "get_cap_nonnull sl \<equiv> kbind (get_cap sl)
      (\<lambda>c. if c = NullCap then kfail else kreturn c)"

lemma get_cap_returns_slot_content:
  "valid (\<lambda>s. True) (get_cap sl) (\<lambda>c s. c = ks_caps s sl)"
  by (simp add: valid_def get_cap_def)

lemma get_cap_nonnull_ok:
  "valid (\<lambda>s. ks_caps s sl \<noteq> NullCap) (get_cap_nonnull sl)
         (\<lambda>c s. c = ks_caps s sl)"
  by (auto simp: valid_def get_cap_nonnull_def get_cap_def kbind_def kreturn_def kfail_def
           split: if_splits)

lemma get_cap_nonnull_fails_on_null:
  "\<not> valid (\<lambda>s. ks_caps s sl = NullCap) (get_cap_nonnull sl) (\<lambda>_ _. True)"
proof
  assume v: "valid (\<lambda>s. ks_caps s sl = NullCap) (get_cap_nonnull sl) (\<lambda>_ _. True)"
  let ?s = "\<lparr> ks_caps = \<lambda>_. NullCap \<rparr>"
  from v have "\<not> snd (get_cap_nonnull sl ?s)" by (auto simp: valid_def)
  then show False
    by (simp add: get_cap_nonnull_def get_cap_def kbind_def kfail_def)
qed

text \<open>
  最后两条是一对：\emph{槽非空时成功，槽为空时失败}。
  真实内核里 @{verbatim "get_cap"} 用 @{verbatim "assert_opt"} 而不是
  @{verbatim "if"}，效果相同。把"成功"与"失败"两条都写出来，
  是 l4v 证明的标准做法——只写成功那条会漏掉整类错误路径。
\<close>

ML \<open>
  writeln (@{make_string} @{thm valid_bind});
  writeln (@{make_string} @{thm get_cap_nonnull_ok})
\<close>

ML \<open>writeln "==== 16 结束 ===="\<close>

end
