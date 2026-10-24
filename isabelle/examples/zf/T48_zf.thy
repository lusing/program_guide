theory T48_zf
  imports ZF
begin

section \<open>48.1 ZF：公理集合论的形式化\<close>

text \<open>Isabelle/ZF 在 FOL（一阶逻辑，第 47 章）之上公理化
Zermelo--Fraenkel 集合论。与 HOL 的根本区别：

  - HOL 有类型系统，集合是谓词的语法糖（@{verbatim "'a set"}）；
  - ZF **没有类型**，一切对象都是集合（类型 @{verbatim "i"}），
    靠公理约束属于关系 @{verbatim "\<in>"}。

Isabelle/ZF 的库覆盖（库索引见发行版 ZF 会话目录）：

  - 公理底座（ZF_Base）：外延、并、幂、无穷、基础、替换；
  - 集合运算（upair/equalities）：无序对、交、差、cons、succ；
  - 有序对与函数（pair/func）：Pair、Pi、Lambda、apply；
  - 良基与递归（WF）：wf、wfrec；
  - 序数（Ordinal）：Transset、Ord、超穷归纳 trans_induct；
  - 自然数（Nat）：nat 作为最小不动点、nat_induct、nat_rec；
  - 有限集（Finite）：Fin 算子、FiniteFun；
  - 基数（Cardinal）：等势、Schroeder-Bernstein；
  - 整数（Int）：自然数对的等价类；
  - 列表（List）：list(A) 数据类型；
  - 选择公理（AC/Zorn）：AC 公理、Zorn 引理。

本理论走 @{verbatim "IsaTutZF"} 会话（父堆 ZF）。\<close>

ML \<open>writeln "==== 48 开始 ===="\<close>


subsection \<open>48.2 公理的定理形态\<close>

text \<open>ZF_Base 把六条公理写成 Isabelle 定理。外延律：
两个集合相等当且仅当互相包含：\<close>

thm extension

text \<open>并集公理：@{verbatim "A \<in> \<Union>(C)"} 当且仅当存在 @{verbatim "B \<in> C"}
使得 @{verbatim "A \<in> B"}：\<close>

thm Union_iff

text \<open>幂集公理：@{verbatim "A \<in> Pow(B)"} 当且仅当 @{verbatim "A \<subseteq> B"}：\<close>

thm Pow_iff

text \<open>无穷公理：存在包含空集且对 succ 封闭的集合：\<close>

thm infinity

text \<open>基础公理（正则公理）：每个非空集合都有 @{verbatim "\<in>"}-极小元：\<close>

thm foundation

text \<open>替换公理模式：若 @{verbatim "P"} 在 @{verbatim "A"} 上是函数的，
则 @{verbatim "PrimReplace(A,P)"} 收集所有像：\<close>

thm replacement

text \<open>从替换可以推出分离公理。@{verbatim "Collect(A,P)"} 即
@{verbatim "{x \<in> A. P(x)"}，其核心等价的 @{verbatim "separation"}
由化简器直接展开：\<close>

lemma separation_demo: "a \<in> {x \<in> A. P(x)} \<longleftrightarrow> a \<in> A \<and> P(a)"
  by simp


subsection \<open>48.3 有界量词\<close>

text \<open>ZF 大量使用有界量词 @{verbatim "\<forall>x\<in>A. P(x)"} 和
@{verbatim "\<exists>x\<in>A. P(x)"}（缩写 @{verbatim "Ball"} 和 @{verbatim "Bex"}）。
引入规则与 HOL 的 @{verbatim "ballI"} / @{verbatim "bexI"} 对应：\<close>

lemma ball_demo:
  assumes "\<And>x. x \<in> A \<Longrightarrow> P(x)"
  shows "\<forall>x\<in>A. P(x)"
  using assms by (rule ballI)

lemma bex_demo:
  assumes "P(a)" and "a \<in> A"
  shows "\<exists>x\<in>A. P(x)"
  using assms by (rule bexI)

text \<open>消去规则：从 @{verbatim "\<forall>x\<in>A. P(x)"} 和 @{verbatim "x \<in> A"}
得到 @{verbatim "P(x)"}：\<close>

lemma bspec_demo:
  assumes "\<forall>x\<in>A. P(x)" and "x \<in> A"
  shows "P(x)"
  using assms by (rule bspec)


subsection \<open>48.4 无序对、二元运算与 cons\<close>

text \<open>@{verbatim "Upair(a,b)"} 是无序对 @{verbatim "{a,b}"}。
二元并、交、差都从它定义：@{verbatim "A \<union> B = \<Union>(Upair(A,B))"}。
@{verbatim "cons(a,A) = Upair(a,a) \<union> A"} 把元素加入集合。
@{verbatim "succ(i) = cons(i,i)"} 是序数后继。\<close>

lemma Upair_iff: "c \<in> Upair(a,b) \<longleftrightarrow> c = a \<or> c = b"
  by simp

lemma Un_iff: "c \<in> A \<union> B \<longleftrightarrow> c \<in> A \<or> c \<in> B"
  by simp

lemma Int_iff: "c \<in> A \<inter> B \<longleftrightarrow> c \<in> A \<and> c \<in> B"
  by simp

lemma Diff_iff: "c \<in> A - B \<longleftrightarrow> c \<in> A \<and> c \<notin> B"
  by simp

lemma cons_iff: "a \<in> cons(b,A) \<longleftrightarrow> a = b \<or> a \<in> A"
  by simp

lemma succ_iff: "i \<in> succ(j) \<longleftrightarrow> i = j \<or> i \<in> j"
  by (simp add: succ_iff)

text \<open>集合枚举语法 @{verbatim "{a,b,c}"} 是 @{verbatim "cons(a,cons(b,cons(c,0)))"}
的语法糖。单元素集 @{verbatim "{a}"} 就是 @{verbatim "cons(a,0)"}：\<close>

lemma singleton_iff: "a \<in> {b} \<longleftrightarrow> a = b"
  by simp

lemma pair_union: "{0} \<union> {1} = {0, 1}"
  by blast


subsection \<open>48.5 基础公理的推论\<close>

text \<open>基础公理直接推出 @{verbatim "\<in>"} 的反自反性和反对称性。
任何集合不能属于自己：\<close>

lemma no_self_mem: "a \<notin> a"
  by (rule mem_not_refl)

text \<open>若 @{verbatim "a \<in> b"} 则 @{verbatim "b \<notin> a"}：\<close>

lemma mem_asym_demo:
  assumes "a \<in> b"
  shows "b \<notin> a"
  using assms by (blast elim: mem_asym)

text \<open>@{verbatim "succ"} 的单射性和 @{verbatim "succ(n) \<noteq> 0"}
也都从基础公理推出：\<close>

thm succ_inject_iff
thm succ_not_0


subsection \<open>48.6 有序对、积与函数空间\<close>

text \<open>@{verbatim "Pair(a,b)"}（记号 @{verbatim "\<langle>a,b\<rangle>"}）是有序对。
Isabelle/ZF 用对称定义 @{verbatim "{{a,a},{a,b}}"}——比 Kuratowski
原始定义在化简器里表现更好。@{verbatim "fst"} 和 @{verbatim "snd"}
用 @{verbatim "THE"}（确定描述）提取分量：\<close>

lemma Pair_inject: "\<langle>a,b\<rangle> = \<langle>c,d\<rangle> \<Longrightarrow> a = c \<and> b = d"
  by simp

text \<open>@{verbatim "Sigma(A,B)"}（记号 @{verbatim "\<Sum>x\<in>A. B(x)"}）
是依赖积；非依赖版本 @{verbatim "A \<times> B"} 是笛卡尔积。
@{verbatim "Pi(A,B)"}（记号 @{verbatim "\<Prod>x\<in>A. B(x)"}）是依赖函数空间；
非依赖版本 @{verbatim "A \<rightarrow> B"} 是普通函数空间：\<close>

text \<open>@{verbatim "Lambda(A,f)"}（记号 @{verbatim "\<lambda>x\<in>A. f(x)"}）
构造函数——它是有序对的集合：\<close>

lemma lam_type_demo:
  assumes "\<And>x. x \<in> A \<Longrightarrow> f(x) \<in> B(x)"
  shows "(\<lambda>x\<in>A. f(x)) \<in> Pi(A,B)"
  using assms by (rule lam_type)

text \<open>函数应用 @{verbatim "f`a"}（注意反引号，不是 HOL 的空格应用）：\<close>

lemma beta_demo:
  assumes "a \<in> A"
  shows "(\<lambda>x\<in>A. f(x)) ` a = f(a)"
  using assms by (rule beta)

text \<open>应用不在定义域的元素得到 @{verbatim "0"}（空集）：\<close>

thm apply_0

text \<open>函数外延：两个函数如果在所有输入上相等则相等：\<close>

thm fun_extension


subsection \<open>48.7 关系运算\<close>

text \<open>ZF 里关系就是有序对的集合。@{verbatim "converse(r)"} 是逆关系，
@{verbatim "domain(r)"} / @{verbatim "range(r)"} / @{verbatim "field(r)"}
分别是定义域、值域、域。@{verbatim "r `` A"} 是像，
@{verbatim "restrict(r,A)"} 是限制：\<close>

lemma domain_lambda:
  shows "domain(\<lambda>x\<in>A. f(x)) = A"
  by (rule domain_lam)

lemma image_lambda:
  assumes "C \<subseteq> A"
  shows "(\<lambda>x\<in>A. f(x)) `` C = {f(x). x \<in> C}"
  using assms by (rule image_lam)

text \<open>@{verbatim "Image"} 的中缀记号是 @{verbatim "``"}（两个反引号）：\<close>

thm image_def


subsection \<open>48.8 描述与条件\<close>

text \<open>@{verbatim "THE x. P(x)"} 是确定描述（Hilbert 的 ι 算子）。
若恰好有一个 @{verbatim "x"} 满足 @{verbatim "P"}，则 @{verbatim "THE x. P(x)"}
等于那个 @{verbatim "x"}：\<close>

lemma the_equality_demo:
  assumes "P(a)" and "\<And>x. P(x) \<Longrightarrow> x = a"
  shows "(THE x. P(x)) = a"
  using assms by (rule the_equality)

text \<open>若不存在唯一的 @{verbatim "x"}，@{verbatim "THE"} 返回 @{verbatim "0"}：\<close>

thm the_0

text \<open>@{verbatim "if P then a else b"} 是条件表达式：\<close>

lemma if_true_demo: "(if True then a else b) = a"
  by simp

lemma if_false_demo: "(if False then a else b) = b"
  by simp


subsection \<open>48.9 子集与集合等式\<close>

text \<open>@{verbatim "A \<subseteq> B"} 定义为 @{verbatim "\<forall>x\<in>A. x \<in> B"}。
子集引入规则：\<close>

lemma subsetI_demo:
  assumes "\<And>x. x \<in> A \<Longrightarrow> x \<in> B"
  shows "A \<subseteq> B"
  using assms by (rule subsetI)

text \<open>集合等式的标准证法是双向子集：\<close>

lemma equality_demo:
  assumes "A \<subseteq> B" and "B \<subseteq> A"
  shows "A = B"
  using assms by (rule equalityI)

text \<open>Cantor 定理：没有从 @{verbatim "A"} 到 @{verbatim "Pow(A)"} 的满射：\<close>

thm cantor


subsection \<open>48.10 良基关系与良基递归\<close>

text \<open>@{verbatim "wf(r)"} 表示关系 @{verbatim "r"} 是良基的：
每个非空集合都有 @{verbatim "r"}-极小元。定义直接对应：\<close>

text \<open>@{verbatim "wf(r) \<equiv> \<forall>Z. Z = 0 \<or> (\<exists>x\<in>Z. \<forall>y. \<langle>y,x\<rangle> \<in> r \<longrightarrow> y \<notin> Z)"}\<close>

text \<open>良基归纳：若 @{verbatim "wf(r)"} 且 @{verbatim "P"} 对
所有 @{verbatim "r"}-前驱成立则 @{verbatim "P(x)"} 成立，
则 @{verbatim "P"} 对所有 @{verbatim "x"} 成立：\<close>

thm wf_induct

text \<open>良基递归定理 @{verbatim "wfrec"}：在良基关系上定义函数：\<close>

thm wfrec

text \<open>@{verbatim "Memrel(A)"} 是集合 @{verbatim "A"} 上的属于关系
（作为有序对集合）。基础公理保证 @{verbatim "wf(Memrel(A))"}：\<close>

thm wf_Memrel


subsection \<open>48.11 传递集与序数\<close>

text \<open>@{verbatim "Transset(i)"}：@{verbatim "i"} 是传递集
（每个元素也是子集）：\<close>

thm Transset_def

text \<open>三种等价刻画：\<close>

lemma Transset_iff_Pow_demo: "Transset(A) \<longleftrightarrow> A \<subseteq> Pow(A)"
  by (rule Transset_iff_Pow)

lemma Transset_iff_Union_demo: "Transset(A) \<longleftrightarrow> \<Union>(A) \<subseteq> A"
  by (rule Transset_iff_Union_subset)

text \<open>@{verbatim "Ord(i)"}：@{verbatim "i"} 是序数（传递且每个元素传递）。
冯诺依曼序数：@{verbatim "0 = \<emptyset>"}, @{verbatim "1 = {0}"},
@{verbatim "2 = {0,1}"}, @{verbatim "\<omega> = nat"}：\<close>

thm Ord_def

lemma Ord_0_demo: "Ord(0)"
  by simp

lemma Ord_succ_demo: "Ord(i) \<Longrightarrow> Ord(succ(i))"
  by (rule Ord_succ)

text \<open>@{verbatim "i < j"} 定义为 @{verbatim "i \<in> j \<and> Ord(j)"}。
@{verbatim "i \<le> j"} 定义为 @{verbatim "i < succ(j)"}：\<close>

thm lt_def

text \<open>序数的三歧性（线性序）：\<close>

thm Ord_linear

text \<open>超穷归纳——对全体序数归纳，三种情况（零、后继、极限）：\<close>

thm trans_induct

text \<open>序数情形分解：每个序数要么是 0，要么是后继序数，要么是极限序数：\<close>

thm Ord_cases

text \<open>不存在所有序数的集合（Burali-Forti 悖论）：\<close>

thm ON_class

text \<open>@{verbatim "Limit(i)"}：@{verbatim "i"} 是极限序数
（非零且对后继封闭）：\<close>

thm Limit_def


subsection \<open>48.12 自然数\<close>

text \<open>@{verbatim "nat"} 定义为最小不动点：
@{verbatim "nat = lfp(Inf, \<lambda>X. {0} \<union> {succ(i). i \<in> X})"}。
展开后 @{verbatim "nat = {0} \<union> {succ(x). x \<in> nat}"}：\<close>

thm nat_unfold

text \<open>类型检查：@{verbatim "0 \<in> nat"} 和 @{verbatim "n \<in> nat \<Longrightarrow> succ(n) \<in> nat"}：\<close>

lemma nat_0_demo: "0 \<in> nat"
  by simp

lemma nat_succ_demo: "n \<in> nat \<Longrightarrow> succ(n) \<in> nat"
  by simp

text \<open>数学归纳法：\<close>

thm nat_induct

text \<open>自然数的情形分解：\<close>

thm natE

text \<open>@{verbatim "nat_rec"} 是自然数上的原始递归算子，
用 @{verbatim "wfrec(Memrel(nat),...)"} 定义：\<close>

thm nat_rec_0
thm nat_rec_succ

text \<open>每个自然数都是序数：\<close>

thm nat_into_Ord

text \<open>@{verbatim "nat"} 本身是极限序数（即 @{verbatim "\<omega>"}）：\<close>

thm Limit_nat


subsection \<open>48.13 有限集\<close>

text \<open>@{verbatim "Fin(A)"} 是 @{verbatim "A"} 的有限子集算子，
用归纳定义（@{verbatim "0 \<in> Fin(A)"}，若 @{verbatim "a \<in> A"} 且
@{verbatim "b \<in> Fin(A)"} 则 @{verbatim "cons(a,b) \<in> Fin(A)"}）：\<close>

thm Fin.intros

text \<open>有限集归纳：\<close>

thm Fin_induct

text \<open>两个有限集的并仍有限：\<close>

thm Fin_UnI

text \<open>@{verbatim "Finite(A)"} 定义为 @{verbatim "\<exists>n\<in>nat. A \<approx> n"}
（与某个自然数等势）：\<close>

thm Finite_def


subsection \<open>48.14 基数与等势\<close>

text \<open>@{verbatim "A \<approx> B"}（等势）：存在 @{verbatim "A"} 到 @{verbatim "B"} 的双射：\<close>

thm eqpoll_def

text \<open>@{verbatim "A \<lesssim> B"}（弱支配）：存在 @{verbatim "A"} 到 @{verbatim "B"} 的单射：\<close>

thm lepoll_def

text \<open>@{verbatim "|A|"}（基数）是等势于 @{verbatim "A"} 的最小序数：\<close>

thm cardinal_def

text \<open>Schroeder-Bernstein 定理：若 @{verbatim "A \<lesssim> B"} 且
@{verbatim "B \<lesssim> A"} 则 @{verbatim "A \<approx> B"}。
证明核心是 Banach 分解定理（用 @{verbatim "lfp"} 构造）：\<close>

thm schroeder_bernstein

text \<open>等势是等价关系：\<close>

thm eqpoll_refl
thm eqpoll_sym
thm eqpoll_trans


subsection \<open>48.15 整数\<close>

text \<open>ZF 的整数 @{verbatim "int"} 构造为自然数对的等价类：
@{verbatim "\<langle>x,y\<rangle>"} 代表 @{verbatim "x - y"}。
等价关系 @{verbatim "intrel"}：@{verbatim "\<langle>x1,y1\<rangle> \<sim> \<langle>x2,y2\<rangle>"}
当且仅当 @{verbatim "x1 + y2 = x2 + y1"}：\<close>

thm intrel_def
thm int_def

text \<open>自然数到整数的嵌入 @{verbatim "$# m"}：\<close>

thm int_of_def

text \<open>加法 @{verbatim "$+"}、乘法 @{verbatim "$*"}、取负 @{verbatim "$-"}：\<close>

thm zadd_commute
thm zmult_commute
thm zadd_zmult_distrib

text \<open>整数上的线性序：\<close>

thm zless_linear

text \<open>整数的情形分解：\<close>

thm int_cases


subsection \<open>48.16 列表\<close>

text \<open>@{verbatim "list(A)"} 是 ZF 的列表数据类型
（通过 @{verbatim "Datatype"} 包的 @{verbatim "datatype"} 定义）：\<close>

text \<open>@{verbatim "datatype list(A) = Nil | Cons(a \<in> A, l \<in> list(A))"}\<close>

text \<open>基本操作 @{verbatim "map"}、@{verbatim "app"}（中缀 @{verbatim "@"}）、
@{verbatim "rev"} 满足以下定理：\<close>

thm map_ident
thm app_assoc
thm rev_rev_ident

text \<open>列表归纳有两种形式——普通归纳 @{verbatim "list.induct"}
和 @{verbatim "list_append_induct"}（对 @{verbatim "@"} 的右参数归纳，
证明 @{verbatim "app"} 相关性质更方便）：\<close>

thm list.induct
thm list_append_induct


subsection \<open>48.17 选择公理与 Zorn 引理\<close>

text \<open>@{verbatim "AC"} 公理在独立的 @{verbatim "AC"} 理论中
（不在 @{verbatim "ZF"} 主入口内）。其形式（Halmos 1960）：
若 @{verbatim "A"} 非空且每个 @{verbatim "B(x)"} 非空，
则 @{verbatim "Pi(A,B)"} 非空（依赖选择函数存在）。
@{verbatim "Zorn"} 理论用 @{verbatim "TFin"}（Tukey 函数的归纳定义）
推出 Zorn 引理：每个链都有上界的偏序集有极大元。\<close>

text \<open>@{verbatim "ZFC = ZF + InfDatatype"}，即 ZF 加上无穷分支数据类型支持。
@{verbatim "ZFC"} 理论本身只有一行 @{verbatim "imports ZF InfDatatype"}。\<close>


subsection \<open>48.18 迭代与超穷递归\<close>

text \<open>@{verbatim "ZF"} 理论（主入口）定义了函数迭代 @{verbatim "F^n(x)"}
和超穷递归 @{verbatim "transrec3"}（按零/后继/极限三种情况）：\<close>

lemma iterates_zero: "F^0 (x) = x"
  by simp

lemma iterates_succ: "F^(succ(n)) (x) = F(F^n (x))"
  by simp

text \<open>@{verbatim "\<omega>"} 次迭代：\<close>

thm iterates_omega_def

text \<open>@{verbatim "transrec3"} 的三种情况：\<close>

thm transrec3_0
thm transrec3_succ
thm transrec3_Limit


subsection \<open>48.19 与 HOL 的对照\<close>

text \<open>
  | 概念 | HOL | ZF |
  |---|---|---|
  | 集合 | @{verbatim "'a set"}（谓词语法糖）| 一等对象，仅 \<in> 关系 |
  | 函数 | 普通类型 @{verbatim "'a \<Rightarrow> 'b"} | 有序对的集合（@{verbatim "Pi"}) |
  | 应用 | @{verbatim "f x"}（空格）| @{verbatim "f`x"}（反引号）|
  | 类型检查 | 静态、编译期 | 无类型，全靠分离公理 |
  | 归纳 | 结构/规则归纳 | 超穷归纳 @{verbatim "trans_induct"} |
  | 自动化 | @{verbatim "auto"} / @{verbatim "metis"} | @{verbatim "blast"} / @{verbatim "auto"}（部分）|
  | 代码生成 | @{verbatim "export_code"} | 不可用（@{verbatim "value"} 也不可用）|
  | 库 | HOL-Library 等 | ZF-Constructible / ZF-IMP 等 |
\<close>


subsection \<open>48.20 坑位清单（实测）\<close>

text \<open>1. ZF **没有类型**：@{verbatim "x \<in> A"} 里没有类型变量；
   @{verbatim "::"} 类型标注不可用——HOL 肌肉记忆全废。
2. 谓词用函数式写法 @{verbatim "Ord(i)"}、@{verbatim "P(x)"}——
   @{verbatim "P x"} 空格应用在量词体里直接解析失败
  （实测 Inner syntax error，第 47 章同款雷）。
3. 函数应用 @{verbatim "f`a"} 用反引号，不是空格。
4. 自然数是冯诺依曼序数（@{verbatim "0 = \<emptyset>"}, @{verbatim "1 = {0}"}……），
   @{verbatim "2"} 既是数又是集合，化简行为和 HOL numeral 完全不同。
5. @{verbatim "value"} 不可用（代码生成器没配 ZF）。
6. @{verbatim "simp"} 可用但规则集是 ZF 的；@{verbatim "auto"} 部分可用
  （配 @{verbatim "blast"}）。
7. @{verbatim "blast"} 在 ZF 里好用——公理多带 @{verbatim "\<longleftrightarrow>"} /
   集合等式时先试它。
8. @{verbatim "metis"} 在 ZF 里不可用（那是 HOL 的）。
9. 定理名带撇号家族（@{verbatim "succ"}、@{verbatim "Ord_succ"}），
   与 HOL 的引理重名时靠会话前缀消歧。
10. @{verbatim "datatype"} 在 ZF 里可用（通过 Datatype 理论），
    但语法与 HOL 略有不同（类型约束写在构造子参数里）。\<close>

thm extension separation_demo ball_demo bex_demo bspec_demo
  pair_union no_self_mem lam_type_demo beta_demo the_equality_demo
  subsetI_demo equality_demo Ord_0_demo Ord_succ_demo nat_0_demo nat_succ_demo
  iterates_zero iterates_succ

ML \<open>writeln "==== 48 结束 ===="\<close>

end
