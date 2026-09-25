theory S16_hoare_wp
  imports Main
begin

section \<open>16.1 内核证明的主语言：霍尔三元组\<close>

text \<open>
  前面几章一直在讲内核\emph{是什么}。从本章开始讲\emph{怎么证明它}。
  l4v 用的主语言是霍尔逻辑在非确定性状态单子上的实例化。
  那个单子的类型在 @{verbatim "l4v/lib/Monads/nondet/Nondet_Monad.thy"} 第 36 行：

  @{verbatim "('s, 'a) nondet_monad = 's \<Rightarrow> ('a \<times> 's) set \<times> bool"}

  一个程序就是"给定起始状态，返回一组可能的（结果，新状态），
  外加一个失败位"。失败位为真，意思是这段计算里\emph{存在}一条失败的路径。
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

text \<open>
  这五个就是 l4v 里的 @{verbatim "return"}/@{verbatim "bind"}/@{verbatim "fail"}/
  @{verbatim "get"}/@{verbatim "put"}（依次在第 61、73、133、90、93 行），
  换个前缀以免和本章的引理撞名。
\<close>

subsection \<open>16.2 三元组不管失败：@{verbatim "valid"} 与 @{verbatim "no_fail"} 是两件事\<close>

text \<open>
  最容易搞错的一点在这里。@{verbatim "l4v/lib/Monads/nondet/Nondet_VCG.thy"}
  第 37 行的 @{verbatim "valid"} 定义里\emph{没有}失败位那一半
  （第 40 行只有一句蕴含）；非失败是另一个文件里的独立谓词：
  @{verbatim "Nondet_No_Fail.thy"} 第 24 行的 @{verbatim "no_fail"}。
  那份定义前面的注释（第 33 行）把后果说得很清楚：
  程序返回空集时三元组\emph{平凡成立}，
  所以 @{verbatim "assert P"} 不要求你证明 @{verbatim "P"}，
  而是让你\emph{拿到} @{verbatim "P"} 这个假设。
\<close>

definition valid :: "('s \<Rightarrow> bool) \<Rightarrow> ('s,'a) nondet \<Rightarrow> ('a \<Rightarrow> 's \<Rightarrow> bool) \<Rightarrow> bool" where
  "valid P m Q \<equiv> \<forall>s. P s \<longrightarrow> (\<forall>(r, s') \<in> fst (m s). Q r s')"

definition no_fail :: "('s \<Rightarrow> bool) \<Rightarrow> ('s,'a) nondet \<Rightarrow> bool" where
  "no_fail P m \<equiv> \<forall>s. P s \<longrightarrow> \<not> snd (m s)"

text \<open>
  于是本章的第一条定理是一条\emph{反直觉}的定理：
  一个必定失败的程序满足\emph{所有}三元组。
\<close>

lemma fail_satisfies_every_triple: "valid P kfail Q"
  by (simp add: valid_def kfail_def)

lemma fail_is_not_no_fail: "P s \<Longrightarrow> \<not> no_fail P kfail"
  by (auto simp: no_fail_def kfail_def)

text \<open>
  两条合起来才是日常要证的东西："这段代码跑得到的状态都满足后条件"
  \emph{并且}"这段代码在这些输入上不会失败"。
  内核证明里每一个 @{verbatim "wpc"} 目标都会同时生出这两类子目标，
  看到 @{verbatim "valid"} 里少了一半，别以为规范放松了。
\<close>

lemma no_fail_top_of_return: "no_fail P (kreturn x)"
  by (simp add: no_fail_def kreturn_def)

text \<open>
  下面这条照的是 @{verbatim "l4v/lib/Monads/nondet/Nondet_No_Fail.thy"}
  第 61--64 行的 @{verbatim "no_fail_bind"}：结论的前条件是
  两个前条件的\emph{合取}，而且必须借一次三元组才能推过去——
  只有 @{verbatim "no_fail"} 是推不出 @{verbatim "no_fail"} 的，
  中间那步 @{verbatim "valid"} 提供了"前一段的结果满足 @{verbatim "R"}"这条信息。
\<close>

lemma no_fail_bind:
  "no_fail P m \<Longrightarrow> valid Q m R \<Longrightarrow> (\<And>r. no_fail (R r) (f r))
   \<Longrightarrow> no_fail (\<lambda>s. P s \<and> Q s) (kbind m f)"
  by (fastforce simp: no_fail_def valid_def kbind_def split: prod.splits)

subsection \<open>16.3 最弱前置条件：@{verbatim "wp"} 是谓词，不是战术\<close>

text \<open>
  把 @{verbatim "valid"} 对前置条件求"最弱解"，就得到 @{verbatim "wp"}。
  注意它同样\emph{不看}失败位——失败位有自己的那个谓词。
\<close>

definition wp :: "('s,'a) nondet \<Rightarrow> ('a \<Rightarrow> 's \<Rightarrow> bool) \<Rightarrow> 's \<Rightarrow> bool" where
  "wp m Q s \<equiv> \<forall>(r, s') \<in> fst (m s). Q r s'"

definition wpnf :: "('s,'a) nondet \<Rightarrow> ('a \<Rightarrow> 's \<Rightarrow> bool) \<Rightarrow> 's \<Rightarrow> bool" where
  "wpnf m Q s \<equiv> wp m Q s \<and> \<not> snd (m s)"

lemma valid_iff_wp: "valid P m Q \<longleftrightarrow> (\<forall>s. P s \<longrightarrow> wp m Q s)"
  by (simp add: valid_def wp_def)

lemma wp_is_valid: "valid (wp m Q) m Q"
  by (simp add: valid_def wp_def)

lemma wp_is_the_weakest: "valid P m Q \<Longrightarrow> P s \<Longrightarrow> wp m Q s"
  by (auto simp: valid_def wp_def)

lemma wpnf_is_stronger_than_wp: "wpnf m Q s \<Longrightarrow> wp m Q s"
  by (simp add: wpnf_def)

lemma wpnf_of_fail_is_false: "\<not> wpnf kfail Q s"
  by (simp add: wpnf_def wp_def kfail_def)

lemma wp_fail_is_true: "wp kfail Q s"
  by (simp add: wp_def kfail_def)

lemma valid_no_fail_iff_wpnf:
  "valid P m Q \<and> no_fail P m \<longleftrightarrow> (\<forall>s. P s \<longrightarrow> wpnf m Q s)"
  by (auto simp: valid_def no_fail_def wpnf_def wp_def)

text \<open>
  @{thm valid_no_fail_iff_wpnf} 说的是：三元组加非失败，
  等于逐点上那个"更强的" @{verbatim "wpnf"}。
  而 @{thm wpnf_of_fail_is_false} 与 @{thm wp_fail_is_true} 摆在一起，
  就是 16.2 那两条的逐点版本——空返回时 @{verbatim "wp"} 真、
  @{verbatim "wpnf"} 假。
\<close>

subsection \<open>16.4 基本规则\<close>

lemma valid_return: "valid P (kreturn x) Q \<longleftrightarrow> (\<forall>s. P s \<longrightarrow> Q x s)"
  by (auto simp: valid_def kreturn_def)

lemma valid_get: "valid P kget (\<lambda>s s'. P s' \<and> s' = s)"
  by (simp add: valid_def kget_def)

lemma valid_put: "valid P (kput s') (\<lambda>_ s''. s'' = s')"
  by (simp add: valid_def kput_def)

lemma valid_bind:
  "valid P m Q \<Longrightarrow> (\<forall>r. valid (Q r) (f r) R) \<Longrightarrow> valid P (kbind m f) R"
  by (fastforce simp: valid_def kbind_def split: prod.splits)

lemma strengthen_pre:
  "(\<forall>s. P' s \<longrightarrow> P s) \<Longrightarrow> valid P m Q \<Longrightarrow> valid P' m Q"
  by (auto simp: valid_def)

lemma weaken_post:
  "(\<forall>r s. Q r s \<longrightarrow> R r s) \<Longrightarrow> valid P m Q \<Longrightarrow> valid P m R"
  by (fastforce simp: valid_def split: prod.splits)

text \<open>
  顺序组合就是把前一段的后条件交给后一段当前置条件：@{thm valid_bind}。
  @{thm strengthen_pre} 这条方向要盯住——它说"前条件\emph{更小}也能用"，
  也就是允许你\emph{多加}假设。l4v 里这条是
  @{verbatim "hoare_pre_imp"}（第 93 行）和它的旋转形式
  @{verbatim "hoare_weaken_pre"}（第 97 行），
  @{verbatim "wp_pre"} 属性（第 112 行那组 @{verbatim "hoare_pre"}）
  就是 @{verbatim "wp"} 战术用来"先把前置条件换成一个特征变元"的那一步。
  这段路径都在 @{verbatim "l4v/lib/Monads/nondet/Nondet_VCG.thy"} 里。
\<close>

definition invariant_on :: "('s,'a) nondet \<Rightarrow> ('s \<Rightarrow> bool) \<Rightarrow> bool" where
  "invariant_on m P \<equiv> valid P m (\<lambda>_ s. P s)"

lemma invariant_on_return: "invariant_on (kreturn x) P"
  by (simp add: invariant_on_def valid_return)

lemma invariant_on_put: "P s' \<Longrightarrow> invariant_on (kput s') P"
  by (simp add: invariant_on_def valid_def kput_def)

lemma invariant_on_bind:
  assumes "invariant_on m P" and "\<And>r. invariant_on (f r) P"
  shows "invariant_on (kbind m f) P"
proof -
  from assms(1) have 1: "valid P m (\<lambda>_ s. P s)" by (simp add: invariant_on_def)
  from assms(2) have 2: "\<And>r. valid P (f r) (\<lambda>_ s. P s)" by (simp add: invariant_on_def)
  show ?thesis
    unfolding invariant_on_def
    by (rule valid_bind [OF 1]) (simp add: 2)
qed

text \<open>
  l4v 给"后条件与前条件相同"这种三元组起了个缩写
  @{verbatim "invariant f P"}（ @{verbatim "Nondet_VCG.thy"} 第 45--48 行），
  读作 @{verbatim "f"} 保住 @{verbatim "P"}。第 17 章那一大堆不变式，
  证的就是这种形状的东西。
\<close>

subsection \<open>16.5 @{verbatim "assert"}：它给的是假设，不是义务\<close>

text \<open>
  @{verbatim "Nondet_Monad.thy"} 第 137--142 行连着定义了
  @{verbatim "assert"} 与 @{verbatim "assert_opt"}：
  前者是 @{verbatim "if P then return () else fail"}，
  后者是 @{verbatim "case v of None \<Rightarrow> fail | Some v \<Rightarrow> return v"}。
  本章的模型照抄（第 145--146 行还有一个能读状态的 @{verbatim "state_assert"}，
  一并给出）。
\<close>

definition kassert :: "bool \<Rightarrow> ('s,unit) nondet" where
  "kassert P \<equiv> if P then kreturn () else kfail"

definition kassert_opt :: "'a option \<Rightarrow> ('s,'a) nondet" where
  "kassert_opt v \<equiv> case v of None \<Rightarrow> kfail | Some v \<Rightarrow> kreturn v"

definition kstate_assert :: "('s \<Rightarrow> bool) \<Rightarrow> ('s,unit) nondet" where
  "kstate_assert P \<equiv> kbind kget (\<lambda>s. kassert (P s))"

lemma valid_kassert: "valid Q (kassert P) R \<longleftrightarrow> (\<forall>s. Q s \<longrightarrow> P \<longrightarrow> R () s)"
  by (auto simp: valid_def kassert_def kreturn_def kfail_def split: if_splits)

lemma no_fail_kassert: "no_fail Q (kassert P) \<longleftrightarrow> (\<forall>s. Q s \<longrightarrow> P)"
  by (auto simp: no_fail_def kassert_def kreturn_def kfail_def split: if_splits)

lemma no_fail_kassert_trivial: "no_fail (\<lambda>_. P) (kassert P)"
  by (simp add: no_fail_kassert)

lemma valid_kstate_assert:
  "valid Q (kstate_assert P) R \<longleftrightarrow> (\<forall>s. Q s \<longrightarrow> P s \<longrightarrow> R () s)"
  by (auto simp: valid_def no_fail_def kstate_assert_def kassert_def kbind_def kget_def
                 kreturn_def kfail_def split: if_splits)

text \<open>
  @{thm valid_kassert} 与 @{thm no_fail_kassert} 是一对镜子：
  三元组那一半里 @{verbatim "P"} 出现在\emph{假设}的位置，
  非失败那一半里它才出现在\emph{义务}的位置。
  @{thm no_fail_kassert_trivial} 就是 l4v 那条
  @{verbatim "no_fail_assert"}（ @{verbatim "Nondet_No_Fail.thy"}
  第 106--108 行，标着 @{verbatim "[wp]"}）。
  第 08 章说"错误路径也要证"，具体就是 @{verbatim "no_fail"} 这一半：
  只交三元组， @{verbatim "assert"} 一条都没检查过。
\<close>

lemma kassert_opt_Some: "kassert_opt (Some v) = kreturn v"
  by (simp add: kassert_opt_def)

lemma kassert_opt_None_is_fail: "kassert_opt None = kfail"
  by (simp add: kassert_opt_def kfail_def)

subsection \<open>16.6 一个内核风格的例子\<close>

text \<open>
  下面这段模拟"取一个槽位里的能力，要求它非空，然后返回它"。
  真实代码是 @{verbatim "l4v/spec/abstract/CSpaceAcc_A.thy"} 第 29 行的
  @{verbatim "get_cap"}：它那串 @{verbatim "case obj of"} 里，
  认不出的对象类型直接走 @{verbatim "fail"}（第 39 行），
  最后一句是第 40 行的 @{verbatim "assert_opt (caps cref)"}。
  下面这对引理就是把那两句各证一遍。
\<close>

type_synonym cslot = nat

datatype cap = NullCap | EndpointCap nat

record kstate =
  ks_caps :: "cslot \<Rightarrow> cap"

definition get_cap :: "cslot \<Rightarrow> (kstate,cap) nondet" where
  "get_cap sl \<equiv> \<lambda>s. ({(ks_caps s sl, s)}, False)"

definition get_cap_nonnull :: "cslot \<Rightarrow> (kstate,cap) nondet" where
  "get_cap_nonnull sl \<equiv> kbind (get_cap sl) (kassert_opt \<circ> (\<lambda>c. if c = NullCap then None else Some c))"

lemma get_cap_returns_slot_content:
  "valid (\<lambda>s. True) (get_cap sl) (\<lambda>c s. c = ks_caps s sl)"
  by (simp add: valid_def get_cap_def)

lemma get_cap_nonnull_ok:
  "valid (\<lambda>s. ks_caps s sl \<noteq> NullCap) (get_cap_nonnull sl)
         (\<lambda>c s. c = ks_caps s sl)"
  by (fastforce simp: valid_def get_cap_nonnull_def get_cap_def kbind_def kassert_opt_def
                 kreturn_def kfail_def split: option.splits prod.splits)

lemma get_cap_nonnull_no_fail:
  "no_fail (\<lambda>s. ks_caps s sl \<noteq> NullCap) (get_cap_nonnull sl)"
  by (fastforce simp: no_fail_def get_cap_nonnull_def get_cap_def kbind_def kassert_opt_def
                 kreturn_def kfail_def split: option.splits prod.splits)

text \<open>
  上面两条是"正常路径"的完整一对：三元组给出结果， @{verbatim "no_fail"} 保证不失败。
  下面是那对\emph{陷阱}定理——槽位为空时三元组\emph{照样}成立，
  哪怕把后条件写成"@{verbatim "False"}"也不影响，
  因为 @{verbatim "get_cap_nonnull"} 在这条路径上返回的是空集。
  真正拒绝这条路径的只有 @{verbatim "no_fail"}。
\<close>

lemma null_slot_triple_still_holds:
  "valid (\<lambda>s. ks_caps s sl = NullCap) (get_cap_nonnull sl) (\<lambda>_ _. False)"
  by (fastforce simp: valid_def get_cap_nonnull_def get_cap_def kbind_def kassert_opt_def
                 kreturn_def kfail_def split: option.splits prod.splits)

lemma null_slot_does_fail:
  "\<not> no_fail (\<lambda>s. ks_caps s sl = NullCap) (get_cap_nonnull sl)"
proof
  assume nf: "no_fail (\<lambda>s. ks_caps s sl = NullCap) (get_cap_nonnull sl)"
  let ?s = "\<lparr> ks_caps = \<lambda>_. NullCap \<rparr>"
  from nf have "\<not> snd (get_cap_nonnull sl ?s)"
    by (auto simp: no_fail_def)
  moreover have "snd (get_cap_nonnull sl ?s)"
    by (simp add: get_cap_nonnull_def get_cap_def kbind_def kassert_opt_def kfail_def)
  ultimately show False by blast
qed

text \<open>
  把 @{thm null_slot_triple_still_holds} 与 @{thm null_slot_does_fail}
  并排放在一起看，就是这一章的全部教训：
  \emph{三元组不会替你排除失败路径}。
  l4v 的规范文档里那句
  "Proving non-failure is done via a separate predicate and calculus"
  说的正是这件事。
\<close>

subsection \<open>16.7 @{verbatim "validE"}：带错误码的那一半\<close>

text \<open>
  第 08 章的 @{verbatim "se_monad"} 把结果装成一个和类型：
  错误码在 @{verbatim "Inl"}、正常值在 @{verbatim "Inr"}，
  所以它的三元组有\emph{两个}后条件。@{verbatim "Nondet_VCG.thy"} 第 54 行的
  @{verbatim "validE"} 就是把两半拼进普通 @{verbatim "valid"}：
  正常值走 @{verbatim "Q"}，异常值走 @{verbatim "E"}。
\<close>

definition validE ::
  "('s \<Rightarrow> bool) \<Rightarrow> ('s,'e + 'a) nondet \<Rightarrow> ('a \<Rightarrow> 's \<Rightarrow> bool)
     \<Rightarrow> ('e \<Rightarrow> 's \<Rightarrow> bool) \<Rightarrow> bool" where
  "validE P m Q E \<equiv> valid P m (\<lambda>v s. case v of Inr r \<Rightarrow> Q r s | Inl e \<Rightarrow> E e s)"

lemma validE_valid:
  "validE P m Q E \<longleftrightarrow>
     (\<forall>s. P s \<longrightarrow> (\<forall>(v, s') \<in> fst (m s). case v of Inr r \<Rightarrow> Q r s' | Inl e \<Rightarrow> E e s'))"
  by (simp add: validE_def valid_def)

lemma validE_split:
  "valid P m (\<lambda>v s. case v of Inr r \<Rightarrow> Q r s | Inl e \<Rightarrow> E e s) \<Longrightarrow> validE P m Q E"
  by (simp add: validE_def)

text \<open>
  注意 @{verbatim "validE"} 里\emph{也没有}失败位——和第 08 章那句话对齐：
  @{verbatim "throwError"} 只是把错误码当\emph{结果}交出去（走 @{verbatim "E"}
  那一支），失败位仍然是假的；它和 @{verbatim "fail"}
  （返回集合为空、失败位置真）是两回事。
  前件里 @{verbatim "seL4_Error"} 满天飞的三元组，
  和"这段代码可能失败"仍然是两个不同的证明目标。
\<close>

ML \<open>
  writeln (@{make_string} @{thm fail_satisfies_every_triple});
  writeln (@{make_string} @{thm valid_no_fail_iff_wpnf});
  writeln (@{make_string} @{thm no_fail_kassert});
  writeln (@{make_string} @{thm valid_bind})
\<close>

ML \<open>writeln "==== 16 结束 ===="\<close>

end
