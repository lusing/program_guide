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
  @{verbatim "v"}（对象的内容）。这在真实规范里对应"抽象层不关心对象的
  具体初值，具体层必须选一个"——这类"具体层多出来的自由度"正是
  @{verbatim "corres"} 证明里 @{verbatim "P'"}（具体层前置条件）的用武之地。
\<close>

subsection \<open>18.6 非确定性的对应\<close>

text \<open>
  l4v 的 @{verbatim "corres"} 还带两个 @{verbatim "nf"}（no-fail）开关：
  抽象层会不会失败、具体层会不会失败。它们被分开是因为
  \emph{抽象层允许比具体层更不确定}：抽象层能失败的场合，
  具体层只要给出一个具体选择即可。
\<close>

datatype 'a with_fail = Ok 'a | Failed

definition refine_result :: "'a with_fail \<Rightarrow> 'a option" where
  "refine_result r \<equiv> case r of Ok x \<Rightarrow> Some x | Failed \<Rightarrow> None"

lemma concrete_choice_refines_abstract_failure:
  "refine_result (Ok x) = Some x"
  by (simp add: refine_result_def)

lemma abstract_failure_admits_any_concrete:
  "refine_result Failed = None"
  by (simp add: refine_result_def)

text \<open>
  换句话说：抽象层说"三种做法都行"，具体层说"我选第二种"——
  这是合法的精化；反过来（具体层比抽象层更不确定）则不合法。
\<close>

ML \<open>
  writeln (@{make_string} @{thm corres_object_at});
  writeln (@{make_string} @{thm corres_create})
\<close>

ML \<open>writeln "==== 18 结束 ===="\<close>

end
