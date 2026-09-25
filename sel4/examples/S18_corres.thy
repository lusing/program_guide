theory S18_corres
  imports Main
begin

section \<open>18.1 从抽象规范到设计规范\<close>

text \<open>
  seL4 有两份"可读的"规范：
  \begin{itemize}
    \item @{verbatim "spec/abstract/"}：\emph{抽象规范}（A），直接写内核做什么，
          用的是第 7 章那个非确定性状态单子；
    \item @{verbatim "spec/haskell/"} 与由它生成的 @{verbatim "spec/design/"}：
          \emph{设计规范}（H/D），数据类型与 C 更接近（@{verbatim "word"}、
          显式的位运算、确定的实现选择）。
  \end{itemize}

  两者之间的关系叫 \emph{数据精化}，用 @{verbatim "corres"} 表达
  （@{verbatim "l4v/lib/Corres_UL.thy"}、@{verbatim "CorresK/"}）：

  @{verbatim "corres_underlying R nf nf' r P P' a c"}

  读作"在状态关系 R 下，抽象程序 a 与具体程序 c 行为一致"。
\<close>

ML \<open>writeln "==== 18 开始 ===="\<close>

subsection \<open>18.2 两层状态与状态关系\<close>

type_synonym aref = nat

record astate =
  a_objs :: "aref \<Rightarrow> bool"

record cstate =
  c_objs :: "aref \<Rightarrow> nat option"

definition state_relation :: "astate \<Rightarrow> cstate \<Rightarrow> bool" where
  "state_relation as cs \<equiv> \<forall>p. a_objs as p = (c_objs cs p \<noteq> None)"

text \<open>
  抽象层只记"这个地址有没有对象"（布尔），具体层记"这个地址上存了什么"。
  关系 @{verbatim "state_relation"} 把后者投影成前者——
  这就是数据精化里最常见的形状：\emph{抽象是具体的函数}。
\<close>

lemma relation_is_functional:
  "state_relation as cs \<Longrightarrow> state_relation as cs' \<Longrightarrow>
   (\<forall>p. (c_objs cs p \<noteq> None) = (c_objs cs' p \<noteq> None))"
  by (auto simp: state_relation_def)

text \<open>
  后面推翻一条 @{verbatim "corres_underlying"} 需要一个具体的相关状态对，
  这里先备一份"两边都空"的。
\<close>

definition as0 :: astate where
  "as0 \<equiv> \<lparr> a_objs = \<lambda>_. False \<rparr>"

definition cs0 :: cstate where
  "cs0 \<equiv> \<lparr> c_objs = \<lambda>_. None \<rparr>"

lemma as0_cs0_related [simp]: "state_relation as0 cs0"
  by (simp add: state_relation_def as0_def cs0_def)

subsection \<open>18.3 corres 的定义\<close>

text \<open>
  模型里用确定性的函数代替单子，于是 @{verbatim "corres"} 退化成
  "在相关状态下，两边的输出相关"。这已经足够说明它的形状。
\<close>

definition corres :: "(astate \<Rightarrow> cstate \<Rightarrow> bool) \<Rightarrow>
                      ('a \<Rightarrow> 'b \<Rightarrow> bool) \<Rightarrow>
                      (astate \<Rightarrow> 'a \<times> astate) \<Rightarrow>
                      (cstate \<Rightarrow> 'b \<times> cstate) \<Rightarrow> bool" where
  "corres R M a c \<equiv> \<forall>as cs. R as cs \<longrightarrow>
      M (fst (a as)) (fst (c cs)) \<and> R (snd (a as)) (snd (c cs))"

text \<open>
  注意这个定义里没有"两层状态类型相同"的假设：
  @{verbatim "astate"} 与 @{verbatim "cstate"} 是两个不同的类型，
  靠 @{verbatim "R"} 联系起来。这正是数据精化与"程序相等"的区别。
\<close>

subsection \<open>18.4 两个操作的对应证明\<close>

definition a_object_at :: "aref \<Rightarrow> astate \<Rightarrow> bool \<times> astate" where
  "a_object_at p as \<equiv> (a_objs as p, as)"

definition c_object_at :: "aref \<Rightarrow> cstate \<Rightarrow> bool \<times> cstate" where
  "c_object_at p cs \<equiv> (c_objs cs p \<noteq> None, cs)"

lemma corres_object_at:
  "corres state_relation (\<lambda>x y. x = y) (a_object_at p) (c_object_at p)"
  by (simp add: corres_def state_relation_def a_object_at_def c_object_at_def)

text \<open>
  @{thm corres_object_at} 是 l4v 里最常见的一类对应定理：
  "查询"类操作，抽象层与具体层只差一个投影。
\<close>

definition a_create :: "aref \<Rightarrow> astate \<Rightarrow> unit \<times> astate" where
  "a_create p as \<equiv> ((), as\<lparr> a_objs := (a_objs as)(p := True) \<rparr>)"

definition c_create :: "aref \<Rightarrow> nat \<Rightarrow> cstate \<Rightarrow> unit \<times> cstate" where
  "c_create p v cs \<equiv> ((), cs\<lparr> c_objs := (c_objs cs)(p \<mapsto> v) \<rparr>)"

lemma corres_create:
  "corres state_relation (\<lambda>_ _. True) (a_create p) (c_create p v)"
  by (auto simp: corres_def state_relation_def a_create_def c_create_def)

subsection \<open>18.5 修改类的对应最容易写错的方向\<close>

definition a_delete :: "aref \<Rightarrow> astate \<Rightarrow> unit \<times> astate" where
  "a_delete p as \<equiv> ((), as\<lparr> a_objs := (a_objs as)(p := False) \<rparr>)"

definition c_delete :: "aref \<Rightarrow> cstate \<Rightarrow> unit \<times> cstate" where
  "c_delete p cs \<equiv> ((), cs\<lparr> c_objs := (c_objs cs)(p := None) \<rparr>)"

lemma corres_delete:
  "corres state_relation (\<lambda>_ _. True) (a_delete p) (c_delete p)"
  by (auto simp: corres_def state_relation_def a_delete_def c_delete_def)

text \<open>
  注意 @{verbatim "c_create"} 比 @{verbatim "a_create"} 多一个参数
  @{verbatim "v"}（对象的内容）：抽象层不关心新建对象的初值，具体层必须选一个。
  真实规范里这类"具体层多出来的自由度"不需要额外机制——
  它就是 18.6 那条主句允许的：具体层的每个结果只要\emph{能}在抽象层的结果里找到解释即可。
  反过来，抽象层\emph{交不出}结果时具体层也不能交出来，这一条才是失败位的用处。
\<close>

subsection \<open>18.6 把真实定义搬进来：失败位与量化方向\<close>

text \<open>
  18.3 那份定义是教学模型。真实的 @{verbatim "corres_underlying"} 定义在
  @{verbatim "l4v/lib/Corres_UL.thy"} 第 17--26 行，
  seL4 只用它的一个实例 @{verbatim "corres"}
  （@{verbatim "l4v/proof/refine/Corres.thy"} 第 11 行把
  @{verbatim "srel"} 定成 @{verbatim "state_relation"}、
  两个开关定成 @{verbatim "False"}/@{verbatim "True"}）。
  这里把第 7 章那个单子的类型和这份定义抄一份：
\<close>

type_synonym ('s, 'a) nmonad = "'s \<Rightarrow> ('a \<times> 's) set \<times> bool"

definition corres_underlying ::
  "('s \<times> 't) set \<Rightarrow> bool \<Rightarrow> bool \<Rightarrow> ('a \<Rightarrow> 'b \<Rightarrow> bool)
   \<Rightarrow> ('s \<Rightarrow> bool) \<Rightarrow> ('t \<Rightarrow> bool)
   \<Rightarrow> ('s, 'a) nmonad \<Rightarrow> ('t, 'b) nmonad \<Rightarrow> bool"
where
  "corres_underlying srel nf nf' rrel G G' \<equiv> \<lambda>m m'.
     \<forall>s s'. (s, s') \<in> srel \<longrightarrow> G s \<and> G' s' \<longrightarrow>
       (nf \<longrightarrow> \<not> snd (m s)) \<longrightarrow>
       (\<forall>(r', t') \<in> fst (m' s'). \<exists>(r, t) \<in> fst (m s). (t, t') \<in> srel \<and> rrel r r') \<and>
       (nf' \<longrightarrow> \<not> snd (m' s'))"

text \<open>
  唯一的改动是把那对状态先拆好再量词：真实定义把 @{verbatim "srel"} 的元素
  当成一对来量化的，这里改成两个变量加一条 @{verbatim "(s, s') \<in> srel"}，
  语义一字不差。原因是 Isabelle 的化简器碰到前者会把一个 @{verbatim "case"}
  留在假设里不肯拆，而本章下面几条要用 @{verbatim "blast"} 从这条定义里取出
  \emph{扁平}的结论（"@{verbatim "m'"} 不许失败"、
  "@{verbatim "m"} 交不出结果则 @{verbatim "m'"} 也交不出"），
  带着 @{verbatim "case"} 的假设它就推不动了。
  这是"@{verbatim "corres"} 展开之后不能手工硬啃"的一个具体表现，
  18.7 那套方法存在的原因也是这个。
\<close>

text \<open>
  两处和直觉相反的地方，这一节把它们各做成一条定理。
  \begin{enumerate}
    \item 主句的量词是"每个\emph{具体}结果都得有一个\emph{抽象}结果来解释"
          （外层跑 @{verbatim "m'"}、内层跑 @{verbatim "m"}）。
          所以具体层不能凭空造结果，只能在抽象层允许的结果里挑；
          抽象层给两个、具体层固定给其中一个，是合法的精化。
    \item 两个开关不对称：@{verbatim "corres"} 取 @{verbatim "nf = False"}、
          @{verbatim "nf' = True"}。"不许失败"这条义务落在\emph{具体}层，
          抽象层没有这个义务。真正的自由在 @{verbatim "G"}/@{verbatim "G'"}：
          它们把讨论域限定在双方都不失败的那些状态上，
          失败分支要么像 @{verbatim "corres_nassert_both"} 那样被前件挡在外面，
          要么根本不进入。
  \end{enumerate}
\<close>

definition sreln :: "(astate \<times> cstate) set" where
  "sreln \<equiv> {(as, cs). state_relation as cs}"

definition nreturn :: "'a \<Rightarrow> ('s, 'a) nmonad" where
  "nreturn x \<equiv> \<lambda>s. ({(x, s)}, False)"

definition nfail :: "('s, 'a) nmonad" where
  "nfail \<equiv> \<lambda>s. ({}, True)"

definition nassert :: "bool \<Rightarrow> ('s, unit) nmonad" where
  "nassert P \<equiv> if P then nreturn () else nfail"

lemma corres_underlyingI':
  assumes rv: "\<And>s s' r' t'. \<lbrakk>(s, s') \<in> srel; G s; G' s'; (r', t') \<in> fst (m' s')\<rbrakk>
                 \<Longrightarrow> \<exists>(r, t) \<in> fst (m s). (t, t') \<in> srel \<and> rrel r r'"
    and nf:  "nf \<Longrightarrow> (\<And>s s'. \<lbrakk>(s, s') \<in> srel; G s; G' s'\<rbrakk> \<Longrightarrow> \<not> snd (m s))"
    and nf': "nf' \<Longrightarrow> (\<And>s s'. \<lbrakk>(s, s') \<in> srel; G s; G' s'\<rbrakk> \<Longrightarrow> \<not> snd (m' s'))"
  shows "corres_underlying srel nf nf' rrel G G' m m'"
  using assms unfolding corres_underlying_def by blast

lemma corres_underlyingD:
  assumes c: "corres_underlying srel nf nf' rrel G G' m m'"
    and rel: "(s, s') \<in> srel"
    and gs: "G s" "G' s'"
    and res: "(r', t') \<in> fst (m' s')"
    and nf: "nf \<Longrightarrow> \<not> snd (m s)"
  shows "\<exists>(r, t) \<in> fst (m s). (t, t') \<in> srel \<and> rrel r r'"
  using c rel gs res nf unfolding corres_underlying_def by blast

text \<open>
  下面这条是全章最有用的一条：只要找出\emph{一个}具体结果
  在抽象层没有解释，@{verbatim "corres_underlying"} 就被推翻。
  它是 18.3 那个确定性模型里根本没有的形状。
\<close>

lemma corres_no_match_refuted:
  assumes rel: "(s, s') \<in> srel" and g: "G s" "G' s'"
    and res: "(r', t') \<in> fst (m' s')"
    and none: "\<And>r t. \<lbrakk>(r, t) \<in> fst (m s); (t, t') \<in> srel\<rbrakk> \<Longrightarrow> \<not> rrel r r'"
    and nf: "nf \<longrightarrow> \<not> snd (m s)"
  shows "\<not> corres_underlying srel nf nf' rrel G G' m m'"
  using assms unfolding corres_underlying_def by blast

text \<open>
  下面两条是"@{verbatim "corres"} 里失败位到底管住了什么"的正面回答。
  注意两条都把抽象层那个开关写成了 @{verbatim "False"}，没有写成变量
  @{verbatim "nf"}——这不是偷懒：@{verbatim "corres_underlying"} 的主句整个挂在
  @{verbatim "(nf \<longrightarrow> \<not> snd (m s)) \<longrightarrow>"} 下面，
  抽象层在这个状态上\emph{允许}失败时（@{verbatim "nf"} 为真而 @{verbatim "m"}
  确实失败了），这条对应关系对具体层什么都不要求，
  于是"@{verbatim "m'"} 不许失败""@{verbatim "m'"} 也交不出结果"两条结论都不成立。
  真实的 @{verbatim "corres"} 恰好取 @{verbatim "nf = False"}
  （@{verbatim "l4v/proof/refine/Corres.thy"} 第 11 行），所以这两条在那里是白送的。
\<close>

lemma corres_concrete_no_fail:
  assumes c: "corres_underlying srel False True rrel G G' m m'"
    and rel: "(s, s') \<in> srel" and gs: "G s" "G' s'"
  shows "\<not> snd (m' s')"
  using assms unfolding corres_underlying_def by blast

lemma corres_abstract_empty:
  assumes c: "corres_underlying srel False nf' rrel G G' m m'"
    and rel: "(s, s') \<in> srel" and gs: "G s" "G' s'" and empty: "fst (m s) = {}"
  shows "fst (m' s') = {}"
  using assms unfolding corres_underlying_def by blast

text \<open>
  再往下三条把上面那段话变成机器可查的断言。前两条是同一件事的两面：
  具体层可以\emph{少给}结果（在抽象层允许的里面挑一个），
  不可以\emph{多给}结果（凭空造一个抽象层没有的）。
\<close>

definition a_select2 :: "(astate, nat) nmonad" where
  "a_select2 \<equiv> \<lambda>as. ({(0, as), (1, as)}, False)"

definition c_pick :: "nat \<Rightarrow> (cstate, nat) nmonad" where
  "c_pick x \<equiv> \<lambda>cs. ({(x, cs)}, False)"

lemma concrete_may_pick_one_abstract_result:
  "corres_underlying sreln False True (=) (\<lambda>_. True) (\<lambda>_. True) a_select2 (c_pick 1)"
  by (rule corres_underlyingI')
     (auto simp: sreln_def a_select2_def c_pick_def state_relation_def)

lemma concrete_cannot_invent_a_result:
  "\<not> corres_underlying sreln False True (=) (\<lambda>_. True) (\<lambda>_. True) a_select2 (c_pick 7)"
  by (rule corres_no_match_refuted [where s = as0 and s' = cs0],
      auto simp: sreln_def state_relation_def as0_def cs0_def a_select2_def c_pick_def)

text \<open>
  第三条是失败位：抽象层\emph{交不出}结果时具体层不是随意的，
  它也必须交不出结果（至于它自己置不置失败位，@{verbatim "nf = False"} 不管）。
\<close>

lemma corres_forces_concrete_silent_when_abstract_fails:
  assumes c: "corres_underlying sreln False True rrel (\<lambda>_. True) (\<lambda>_. True) nfail m'"
    and rel: "(as, cs) \<in> sreln"
  shows "fst (m' cs) = {}"
  using corres_abstract_empty [OF c rel] by (simp add: nfail_def)

text \<open>
  最后是 @{verbatim "l4v/lib/Corres_UL.thy"} 第 831 行那条 @{verbatim "corres_assert"}
  的模型版本：两边同时 assert 是可以对应的，条件正是把假设写进
  @{verbatim "G"}/@{verbatim "G'"}（真实规则里写成 @{verbatim "(%_. P)"} 与
  @{verbatim "(%_. Q)"}）。这就是"失败分支怎么办"的官方答案——
  \emph{不在前件覆盖的状态里谈它}。
\<close>

lemma corres_nassert_both:
  "corres_underlying sreln nf nf' (\<lambda>_ _. True) (\<lambda>_. P) (\<lambda>_. Q) (nassert P) (nassert Q)"
  by (rule corres_underlyingI')
     (auto simp: sreln_def nassert_def nreturn_def nfail_def)

subsection \<open>18.7 组合：真实库里那两条规则的形状\<close>

text \<open>
  上面全是"一步"的对应。真实证明里一个系统调用是几十步 @{verbatim "bind"} 串起来的，
  所以要有一条\emph{拆开}的规则。@{verbatim "l4v/lib/Corres_UL.thy"} 第 290 行的
  @{verbatim "corres_split"} 就是这一条，它额外要求两条 @{verbatim "wp"} 前提
  （"@{verbatim "a"} 跑完之后 @{verbatim "R"} 成立"），因为后半段的
  前件 @{verbatim "R rv"} 要靠它保住。本章不搬 @{verbatim "wp"}，
  只搬两个不需要它的特例：第 93 行 @{verbatim "corres_return"} 的形状，
  和第 766 行 @{verbatim "corres_assert_assume_l"}。
  先把 @{verbatim "bind"} 抄一份。
\<close>

definition nbind :: "('s, 'a) nmonad \<Rightarrow> ('a \<Rightarrow> ('s, 'b) nmonad) \<Rightarrow> ('s, 'b) nmonad"
  (infixl "\<bind>\<^sub>n" 90) where
  "m \<bind>\<^sub>n f \<equiv> \<lambda>s. (\<Union>(r, t) \<in> fst (m s). fst (f r t),
                     snd (m s) \<or> (\<exists>(r, t) \<in> fst (m s). snd (f r t)))"

lemma nbind_nassert [simp]:
  "(nassert P \<bind>\<^sub>n f) = (\<lambda>s. if P then f () s else ({}, True))"
  by (simp add: nbind_def nassert_def nreturn_def nfail_def)

text \<open>
  下面这条把 @{verbatim "l4v/lib/Corres_UL.thy"} 第 93 行那条
  @{verbatim "corres_return"} 的\emph{形状}原样解释了一遍：两个
  @{verbatim "return"} 的对应不是一个定理，而是一个\emph{等价式}，
  右边那个 @{text "\<exists>s s'. (s, s') \<in> sr"} 就是"这座桥得真的有人走过"。
  少了它，@{verbatim "corres"} 在一座空桥上对任何返回值关系都成立——
  这正是第 17 章那条"状态关系是关系不是函数"的副作用。
\<close>

lemma corres_nreturn:
  "corres_underlying srel nf nf' rrel (\<lambda>_. P) (\<lambda>_. Q) (nreturn x) (nreturn y) =
     ((P \<and> Q \<and> (\<exists>s s'. (s, s') \<in> srel)) \<longrightarrow> rrel x y)"
  by (auto simp: corres_underlying_def nreturn_def)

lemma corres_empty_srel_trivial:
  "corres_underlying {} nf nf' rrel (\<lambda>_. True) (\<lambda>_. True) (nreturn x) (nreturn y)"
  by (simp add: corres_nreturn)

text \<open>
  最后这条是 @{verbatim "corres_assert_assume_l"}（同文件第 766 行）的模型版本。
  真实那条写的是 @{verbatim "(P and (\<lambda>s. P'))"}——第 17 章那个谓词上的
  @{verbatim "and"}；这里没引 @{verbatim "Fun_Pred_Syntax"}，
  把它展开成 @{verbatim "(\<lambda>s. P s \<and> A)"} 写。它说的是同一件事：
  在一边加一个 @{verbatim "assert"}，\emph{不}需要证失败分支怎么对应，
  只是把那条假设搬进前置条件里。
\<close>

lemma corres_assert_assume_l_model:
  assumes c: "corres_underlying srel nf nf' rrel P Q (f ()) g"
  shows "corres_underlying srel nf nf' rrel (\<lambda>s. P s \<and> A) Q (nassert A \<bind>\<^sub>n f) g"
  using assms unfolding corres_underlying_def
  by (auto simp: split_def)

ML \<open>
  writeln (@{make_string} @{thm corres_object_at});
  writeln (@{make_string} @{thm concrete_may_pick_one_abstract_result});
  writeln (@{make_string} @{thm concrete_cannot_invent_a_result});
  writeln (@{make_string} @{thm corres_underlyingD});
  writeln (@{make_string} @{thm corres_concrete_no_fail});
  writeln (@{make_string} @{thm corres_abstract_empty});
  writeln (@{make_string} @{thm corres_nreturn});
  writeln (@{make_string} @{thm corres_assert_assume_l_model})
\<close>

ML \<open>writeln "==== 18 结束 ===="\<close>

end
