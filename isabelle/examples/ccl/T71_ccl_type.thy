theory T71_ccl_type
  imports "IsaTutCCL.Type" "IsaTutCCL.Hered" "IsaTutCCL.Wfd" "IsaTutCCL.Fix"
begin

section \<open>71.1 类型即项集：Type 理论的核心点子\<close>

text \<open>第 70 章的 CCL 只有一个类型 @{verbatim i}，"类型"从何而来？
@{verbatim Type} 理论的回答优雅得离谱：**类型就是 @{verbatim i} 的
子集**。库源码 @{verbatim "src/CCL/Type.thy"} 第 12–35 行，六个定义：

@{verbatim "definition Unit :: \"i set\""}
@{verbatim "  where \"Unit == {x. x=one}\""}
@{verbatim "definition Bool :: \"i set\""}
@{verbatim "  where \"Bool == {x. x=true | x=false}\""}
@{verbatim "definition Plus :: \"[i set, i set] \<Rightarrow> i set\"  (infixr \"+\" 55)"}
@{verbatim "  where \"A+B == {x. (EX a:A. x=inl(a)) | (EX b:B. x=inr(b))}\""}
@{verbatim "definition Pi :: \"[i set, i \<Rightarrow> i set] \<Rightarrow> i set\""}
@{verbatim "  where \"Pi(A,B) == {x. EX b. x=lam x. b(x) \<and> (ALL x:A. b(x):B(x))}\""}
@{verbatim "definition Sigma :: \"[i set, i \<Rightarrow> i set] \<Rightarrow> i set\""}
@{verbatim "  where \"Sigma(A,B) == {x. EX a:A. EX b:B(a).x=<a,b>}\""}

@{verbatim Unit} 是单元素集，@{verbatim Bool} 是两个常量，
@{verbatim "A+B"} 是和类型（@{verbatim "inl/inr"} 标签），
@{verbatim "Pi(A,B)"} 是依赖函数空间（**装的是 λ 抽象**），
@{verbatim "Sigma(A,B)"} 是依赖序对。第 37–55 行再给它们配上
熟悉的记号：@{verbatim "PROD x:A. B"}、@{verbatim "A -> B"}、
@{verbatim "SUM x:A. B"}、@{verbatim "A * B"}；@{verbatim "{x:A. P}"} 的糖在第 15–20 行。
于是"类型检查"就是普通的成员关系证明，
类型规则就是集合成员关系的引入 / 消去规则——第 69 章那套
I/D/E 命名法原样复用。\<close>

ML \<open>writeln "==== 71 开始 ===="\<close>

thm Unit_def Bool_def Plus_def Pi_def Sigma_def Subtype_def


subsection \<open>71.2 递归类型：lfp 造有限、gfp 造无穷\<close>

text \<open>库源码第 57–67 行，四个递归类型两行一个：

@{verbatim "definition Nat :: \"i set\""}
@{verbatim "  where \"Nat == lfp(\<lambda>X. Unit + X)\""}
@{verbatim "definition List :: \"i set \<Rightarrow> i set\""}
@{verbatim "  where \"List(A) == lfp(\<lambda>X. Unit + A*X)\""}
@{verbatim "definition Lists :: \"i set \<Rightarrow> i set\""}
@{verbatim "  where \"Lists(A) == gfp(\<lambda>X. Unit + A*X)\""}
@{verbatim "definition ILists :: \"i set \<Rightarrow> i set\""}
@{verbatim "  where \"ILists(A) == gfp(\<lambda>X.{} + A*X)\""}

读法：@{verbatim Nat} 是方程 @{verbatim "X = Unit + X"} 的**最小**解
（只含有限多个 @{verbatim succ}）；@{verbatim "Lists(A)"} 是同一方程的
**最大**解（有限列表和无限流都在里面）；@{verbatim "ILists(A)"}
把空列表一支砍掉，只剩无穷流。第 69 章的 lfp/gfp 在这里第一次
派上实际用场。配套的还有 lifted 类型 @{verbatim "[A] == A Un {bot}"}
（允许发散，源第 76–77 行）、按序对切分的 @{verbatim SPLIT}
（源第 79–80 行）和两个量化构造 @{verbatim TALL} / @{verbatim TEX}
（源第 70–74 行）。\<close>

thm Nat_def List_def Lists_def ILists_def Lift_def SPLIT_def TAll_def TEx_def


subsection \<open>71.3 穷举规则 XHs：定义即五路析取\<close>

text \<open>库源码第 95–102 行把每个类型定义翻成"元素长什么样"的
充要条件，命名后缀 @{verbatim XH}（exhaustion）：

@{verbatim "lemma UnitXH: \"\<And>a. a : Unit          \<longleftrightarrow> a=one\""}
@{verbatim "  and BoolXH: \"\<And>a. a : Bool          \<longleftrightarrow> a=true | a=false\""}
@{verbatim "  and PlusXH: \"\<And>a A B. a : A+B           \<longleftrightarrow> (EX x:A. a=inl(x)) | (EX x:B. a=inr(x))\""}
@{verbatim "  and PiXH: \"\<And>a A B. a : PROD x:A. B(x) \<longleftrightarrow> (EX b. a=lam x. b(x) \<and> (ALL x:A. b(x):B(x)))\""}
@{verbatim "  and SgXH: \"\<And>a A B. a : SUM x:A. B(x)  \<longleftrightarrow> (EX x:A. EX y:B(x).a=<x,y>)\""}
@{verbatim "  unfolding simp_type_defs by blast+"}

@{verbatim ML} 那行（源第 111 行）把七条 iff 统一转成消去规则
@{verbatim case_rls}；递归类型的四条（源第 258–262 行）则要从
不动点方程出发，多绕一步。\<close>

thm EmptyXH SubtypeXH UnitXH BoolXH PlusXH PiXH SgXH
thm LiftXH TallXH TexXH
thm NatXH ListXH ListsXH IListsXH


subsection \<open>71.4 类型规则：构造子与非构造子两条流水线\<close>

text \<open>库源码第 116–123 行。**构造子**（@{verbatim "one/true/false/pair/lam/inl/inr"}）的类型规则七条，全部 @{verbatim "blast intro: XHs"}：

@{verbatim "lemma lamT: \"\<And>b B. (\<And>x. x:A \<Longrightarrow> b(x):B(x)) \<Longrightarrow> lam x. b(x) : Pi(A,B)\""}
@{verbatim "  and pairT: \"\<And>b B. \<lbrakk>a:A; b:B(a)\<rbrakk> \<Longrightarrow> <a,b>:Sigma(A,B)\""}
@{verbatim "  and inlT: \"a:A \<Longrightarrow> inl(a) : A+B\""}

**非构造子**（@{verbatim "if/apply/split/when"}）的类型规则要靠
@{verbatim ncanT} 战术（源第 145–146 行）——它先把目标用
@{verbatim case_rls} 拆开，再对每个分支套前提。注意这些规则的
形状与第 70 章的 β 规则一一对应，只是把 @{verbatim "="} 换成
@{verbatim ":"}。\<close>

thm oneT trueT falseT lamT pairT inlT inrT
thm ifT applyT splitT whenT

text \<open>下面给一个完整的"类型检查一个真程序"的例子：
函数 @{verbatim "lam n. ncase(n, true, \<lambda>x. false)"}（零映射真、
后继映射假）的类型是 @{verbatim "Nat -> Bool"}。构造子一支用
@{verbatim lamT}，主体用 @{verbatim ncaseT}，两条前提各归
@{verbatim trueT} / @{verbatim falseT}：\<close>

lemma lam_type_demo: "lam n. ncase(n, true, \<lambda>x. false) : Nat -> Bool"
proof (rule lamT)
  fix n assume hn: "n:Nat"
  show "ncase(n, true, \<lambda>x. false) : Bool"
  proof (rule ncaseT[OF hn])
    show "true : Bool" by (rule trueT)
    fix x assume "x:Nat" and "n = succ(x)"
    show "false : Bool" by (rule falseT)
  qed
qed

lemma pair_type_demo: "<zero, true> : Nat * Bool"
  by (rule pairT[OF zeroT trueT])

text \<open>两个小练习性质的演示：@{verbatim zeroT} 直接给出
@{verbatim "zero : Nat"}；@{verbatim succT} 可以串着用，
说明"Nat 对 succ 封闭"：\<close>

lemma zero_nat: "zero : Nat"
  by (rule zeroT)

lemma succ_succ_nat: "n:Nat \<Longrightarrow> succ(succ(n)) : Nat"
proof -
  assume "n:Nat"
  then have "succ(n):Nat" by (rule succT)
  then show "succ(succ(n)):Nat" by (rule succT)
qed


subsection \<open>71.5 从展开方程到归纳规则\<close>

text \<open>库源码第 219–253 行。先用第 69 章的 @{verbatim def_lfp_Tarski}
把 @{verbatim lfp} 定义翻成**展开方程**——前提是单调性，
而单调性由 @{verbatim PlusM} / @{verbatim SgM} / @{verbatim constM} /
@{verbatim idM} 四条组合出来（源第 182–215 行）：

@{verbatim "lemma NatM: \"mono(\<lambda>X. Unit+X)\""}
@{verbatim "  apply (rule PlusM constM idM)+"}
@{verbatim "  done"}
@{verbatim "lemma def_NatB: \"Nat = Unit + Nat\""}
@{verbatim "  apply (rule def_lfp_Tarski [OF Nat_def])"}
@{verbatim "  apply (rule NatM)"}
@{verbatim "  done"}

拿到 @{verbatim "Nat = Unit + Nat"} 和 @{verbatim PlusXH} 一凑，
@{verbatim NatXH}（源第 258–262 行）就出来了：@{verbatim Nat}
的元素要么是 @{verbatim zero}、要么是某个 Nat 的 @{verbatim succ}。
再往上一步就是**归纳规则**——它来自第 69 章 @{verbatim Lfp}
理论的通用 @{verbatim def_induct}（源第 55–60 行），
Nat 实例化后正是熟悉的形状：

@{verbatim "lemma Nat_ind: \"\<lbrakk>n:Nat; P(zero); \<And>x. \<lbrakk>x:Nat; P(x)\<rbrakk> \<Longrightarrow> P(succ(x))\<rbrakk> \<Longrightarrow> P(n)\""}

注意归纳假设里**带 @{verbatim "x:Nat"} 守卫**——因为
@{verbatim Nat} 不是"全部项"， Nat 外的项不在讨论范围。
@{verbatim nrecT} / @{verbatim lrecT}（源第 317–325 行）则由
归纳直接给出：原始递归保持类型。\<close>

thm NatM ListM def_NatB def_ListB def_ListsB def_IListsB
thm Nat_ind List_ind nrecT lrecT


subsection \<open>71.6 gfpI：共归纳装下无穷数据\<close>

text \<open>库源码第 351–372 行。无穷数据的引入规则长这样：

@{verbatim "lemma gfpI:"}
@{verbatim "  assumes \"a:A\""}
@{verbatim "    and \"\<And>x X. \<lbrakk>x:A; ALL y:A. t(y):X\<rbrakk> \<Longrightarrow> t(x) : B(X)\""}
@{verbatim "  shows \"t(a) : gfp(B)\""}
@{verbatim "  apply (rule coinduct)"}

读作：只要 @{verbatim t} 把 @{verbatim A} 里每个点都推进
@{verbatim B} 一层，@{verbatim "t(a)"} 就在最大不动点里——
这正是第 69 章 @{verbatim coinduct} 的成员关系版本。
库用它证了一个漂亮例子（源第 365–371 行）：**用 letrec 定义的
常流** @{verbatim "letrec g x be zero$g(x) in g(bot)"} 是
@{verbatim "Lists(Nat)"} 的元素——虽然它一步都不会终止。
@{verbatim def_gfpI} 是它的定义形态。\<close>

thm gfpI def_gfpI lfp_subset_gfp

text \<open>配套的 @{verbatim ci3_RI} / @{verbatim ci3_AgenI} /
@{verbatim ci3_AI}（源第 396–405 行）是第 70 章
@{verbatim eq_coinduct3} 在类型层的三块砖，第 72 章的流等式证明
会直接踩上去。下面演示 @{verbatim Lists} 对 cons 封闭
（有限列表的规则 @{verbatim consT} 只管 @{verbatim List}，
这里必须走穷举规则）：\<close>

lemma lists_cons_demo: "\<lbrakk>h:A; t:Lists(A)\<rbrakk> \<Longrightarrow> h$t : Lists(A)"
  apply (rule ListsXH [THEN iffD2])
  apply (rule disjI2)
  apply (rule_tac x = h in bexI)
   apply (rule_tac x = t in bexI)
    apply (rule refl)
   apply assumption
  apply assumption
  done


subsection \<open>71.7 Wfd：项上的良基关系\<close>

text \<open>库源码 @{verbatim "src/CCL/Wfd.thy"} 第 12–22 行把 HOL 的
良基关系整套搬到项上：

@{verbatim "definition Wfd :: \"[i set] \<Rightarrow> o\""}
@{verbatim "  where \"Wfd(R) == ALL P.(ALL x.(ALL y.<y,x> : R \<longrightarrow> y:P) \<longrightarrow> x:P) \<longrightarrow> (ALL a. a:P)\""}
@{verbatim "definition wf :: \"[i set] \<Rightarrow> i set\""}
@{verbatim "  where \"wf(R) == {x. x:R \<and> Wfd(R)}\""}
@{verbatim "definition lex :: \"[i set,i set] => i set\"      (infixl \"**\" 70)"}
@{verbatim "  where \"ra**rb == {p. EX a a' b b'. p = <<a,b>,<a',b'>> \<and> (<a,a'> : ra | (a=a' \<and> <b,b'> : rb))}\""}

@{verbatim Wfd} 直接用 @{verbatim "ALL P"} 写出"每个可及子集都全"的
定义；@{verbatim "wf(R)"} 是"在 R 里且 R 良基"的项集；
@{verbatim "**"} 是字典序。两个 ground 关系是主角（源第 24–28 行）：

@{verbatim "definition NatPR :: \"i set\""}
@{verbatim "  where \"NatPR == {p. EX x:Nat. p=<x,succ(x)>}\""}
@{verbatim "definition ListPR :: \"i set \<Rightarrow> i set\""}
@{verbatim "  where \"ListPR(A) == {p. EX h:A. EX t:List(A). p=<t,h$t>}\""}

即"前驱关系"和"去头关系"。@{verbatim wfd_induct}（源第 31–37 行）
是标准形状的强归纳；@{verbatim wfI} 把 @{verbatim Wfd} 判据
兑现成集合包含；@{verbatim lex_wf} 说字典序保良基；
@{verbatim wmap_wf} 说经函数映射保良基——这三条正是证明
递归函数终止（第 72 章 @{verbatim sub} / @{verbatim div} /
@{verbatim ackermann}）的全部弹药。\<close>

thm Wfd_def wf_def wmap_def lex_def NatPR_def ListPR_def
thm wfd_induct wfd_strengthen_lemma wf_anti_sym wf_anti_refl
thm lexXH lexI1 lexI2 lexE lex_pair lex_wf
thm wmapXH wmapI wmapE wmap_wf wfstI wsndI wthdI
thm wfI Empty_wf wf_wf trancl_wf
thm NatPRXH ListPRXH NatPRI ListPRI NatPR_wf ListPR_wf


subsection \<open>71.8 Hered：遗传终止性\<close>

text \<open>库源码 @{verbatim "src/CCL/Hered.thy"}。前几章的"类型"只管
形状，不管终止；@{verbatim HTT}（hereditarily terminating terms，
遗传终止项）补上这一维，思路照抄 Martin Löf：

@{verbatim "definition HTTgen :: \"i set \<Rightarrow> i set\" where"}
@{verbatim "  \"HTTgen(R) =="}
@{verbatim "    {t. t=true | t=false | (EX a b. t= <a, b> \<and> a : R \<and> b : R) |"}
@{verbatim "      (EX f. t = lam x. f(x) \<and> (ALL x. f(x) : R))}\""}
@{verbatim "definition HTT :: \"i set\""}
@{verbatim "  where \"HTT == gfp(HTTgen)\""}

@{verbatim bot} 被**排除**在外——这就是"终止"的含义。
注意库自己的免责声明（源第 12–16 行）：@{verbatim "lam x. b(x)"}
属于 HTT 当且仅当**所有** @{verbatim x} 都让 @{verbatim "b(x)"}
终止，所以对函数不太有用；真正好用的是 @{verbatim Nat} /
@{verbatim List} 这些**数据**类型，它们的形成规则
（@{verbatim NatF} / @{verbatim ListF} / @{verbatim ListsF} /
@{verbatim IListsF}，源第 133–166 行）用余归纳证成，
说明"数据构造子保终止"。\<close>

thm HTTgen_def HTT_def HTTgen_mono HTTgenXH HTTXH
thm HTT_bot HTT_true HTT_false HTT_pair HTT_lam HTT_rews
thm HTT_coinduct HTT_coinduct3 HTTgenIs
thm UnitF BoolF PlusF SigmaF NatF ListF ListsF IListsF

text \<open>库的 @{verbatim HTT_rews} 把 HTT 的判定挂成 simp：
@{verbatim "succ(n) : HTT \<longleftrightarrow> n : HTT"}、
@{verbatim "x$xs : HTT \<longleftrightarrow> x : HTT \<and> xs : HTT"}……
于是一个具体项三行收敛到 @{verbatim zero} / @{verbatim "[]"}：\<close>

lemma htt_demo: "succ(zero) : HTT"
  by (simp add: HTT_rews)

lemma htt_pair_demo: "<zero, true> : HTT"
  by (simp add: HTT_rews)


subsection \<open>71.9 Fix：不动点归纳与"可达性"\<close>

text \<open>库源码 @{verbatim "src/CCL/Fix.thy"}，标题自带苦笑：
@{verbatim "Tentative attempt at including fixed point induction; justified by Smith"}。
思路是造一个**包含性谓词** @{verbatim INCL}：

@{verbatim "axiomatization INCL :: \"[i\<Rightarrow>o]\<Rightarrow>o\" where"}
@{verbatim "  INCL_def: \"INCL(\<lambda>x. P(x)) == (ALL f.(ALL n:Nat. P(f^n`bot)) \<longrightarrow> P(fix(f)))\" and"}
@{verbatim "  po_INCL: \"INCL(\<lambda>x. a(x) [= b(x))\" and"}
@{verbatim "  INCL_subst: \"INCL(P) \<Longrightarrow> INCL(\<lambda>x. P((g::i\<Rightarrow>i)(x)))\""}

读作：@{verbatim P} 包含，若"对所有 n 有 @{verbatim "P(f^n`bot)"}
就能推出 @{verbatim "P(fix(f))"}"——即 P 对**有限逼近的极限**封闭。
配上基例与步进就得到不动点归纳：

@{verbatim "lemma fix_ind:"}
@{verbatim "  assumes base: \"P(bot)\""}
@{verbatim "    and step: \"\<And>x. P(x) \<Longrightarrow> P(f(x))\""}
@{verbatim "    and incl: \"INCL(P)\""}
@{verbatim "  shows \"P(fix(f))\""}

步进 @{verbatim "P(x) \<Longrightarrow> P(f(x))"} 配基例 @{verbatim "P(bot)"}
给出 @{verbatim "\<forall>n. P(f^n`bot)"}（对 @{verbatim n} 归纳），
@{verbatim incl} 再把它推到极限。库还给出四条 INCL 的代数
（@{verbatim conj_INCL} / @{verbatim all_INCL} / @{verbatim ball_INCL}）
和一条与行为等价的接口 @{verbatim eq_INCL}。

@{verbatim eq_INCL} 用起来最顺手：**点等则不动点处也等**。
下面演示一次完整使用——归纳证明 @{verbatim "\<forall>n"} 那支
正是 @{verbatim Nat_ind} 的用武之地：\<close>

thm idgen_def INCL_def po_INCL INCL_subst fix_ind
thm inclXH inclI inclD inclE
thm npo_INCL conj_INCL all_INCL ball_INCL eq_INCL

lemma fix_cong_demo:
  fixes a b :: "i \<Rightarrow> i"
  assumes h: "\<And>x. a(x) = b(x)"
  shows "a(fix(f)) = b(fix(f))"
proof (rule inclD)
  show "INCL(\<lambda>x. a(x) = b(x))" by (rule eq_INCL)
  show "\<And>n. n:Nat \<Longrightarrow> a(f^n`bot) = b(f^n`bot)"
  proof -
    fix n assume hn: "n:Nat"
    show "a(f^n`bot) = b(f^n`bot)"
    proof (rule Nat_ind[OF hn])
      show "a(f^zero`bot) = b(f^zero`bot)" by (simp add: napplyBzero h)
      fix x assume "x:Nat" and ih: "a(f^x`bot) = b(f^x`bot)"
      show "a(f^succ(x)`bot) = b(f^succ(x)`bot)" by (simp add: napplyBsucc h)
    qed
  qed
qed

text \<open>库的终极目标是**项的结构归纳**。@{verbatim idgen} 是
"恒等函数的泛函"（源第 12–13 行），库证明它的所有不动点都是
λ（@{verbatim idgenfp_lam}），且 @{verbatim "fix(idgen)"} 与
@{verbatim "lam x. x"} 互为最小不动点——两条 @{verbatim "[="}
一夹就是 @{verbatim reachability}：

@{verbatim "lemma reachability: \"fix(idgen) = lam x. x\""}

有了它，任何项都能写成 @{verbatim "fix(idgen) ` t"}，
再对 @{verbatim t} 用 @{verbatim fix_ind}，就得到无类型世界的
结构归纳原理 @{verbatim term_ind}（源第 178–196 行）——
五路基例加一个 @{verbatim INCL} 义务，与第 70 章的
@{verbatim term_case} 正好一对（消去 / 归纳）。\<close>

thm fix_idgenfp id_idgenfp idgen_lemmas po_eta
thm fix_least_idgen id_least_idgen reachability id_apply term_ind


subsection \<open>71.10 坑位清单（实测）\<close>

text \<open>1. **@{verbatim ":"} 是成员关系不是 HOL 的类型标注**：
   @{verbatim "a : Nat"} 是一条**命题**，可以被 simp、blast、
   余归纳规则操作；HOL 里 @{verbatim "a :: nat"} 是类型约束，
   两者语义完全不同，别混写。
2. **@{verbatim Nat} / @{verbatim List} / @{verbatim Bool} /
   @{verbatim Unit} 是 CCL 的集合常量**，与 HOL 同名类型
   （@{verbatim nat} / @{verbatim "'a list"} / @{verbatim bool}）
   毫无关系；本章一律小写字母打头的 @{verbatim "i set"}。
3. **@{verbatim "List(A)"} 与 @{verbatim "Lists(A)"} 只差一个字母**：
   前者 lfp（有限），后者 gfp（含无穷）。规则也分成两套：
   @{verbatim consT} 属于 @{verbatim List}，
   @{verbatim Lists} 只能用 @{verbatim ListsXH} 或
   @{verbatim gfpI}。
4. **递归类型的归纳规则带守卫**：@{verbatim Nat_ind} 的归纳假设
   是 @{verbatim "\<lbrakk>x:Nat; P(x)\<rbrakk>"}，对 Nat 外的项
   一无所知；照抄 HOL 数归的形状会少一条前提，blast 到一半
   报 @{verbatim "Failed to refine"}。另外 @{verbatim "EX x:A."}
   是 @{verbatim Bex} 不是裸 @{verbatim ex}：给证人要用
   @{verbatim bexI}（谓词成立、证人在集合里两个义务），
   @{verbatim "rule exI"} 直接报 @{verbatim "Failed to apply"}；
   且 @{verbatim "auto simp add: ListsXH"} 在 process_theories 下
   会**无限发散**（iff 里嵌 EX，classical tableau 展开不封顶），
   改成 @{verbatim "ListsXH [THEN iffD2]"} + @{verbatim bexI}
   显式规则链一秒收敛。
5. **@{verbatim "rule lamT"} 之后要对绑定变量 @{verbatim fix}**：
   @{verbatim lamT} 的前提是 @{verbatim "\<And>x. x:A \<Longrightarrow> b(x):B(x)"}，
   不 @{verbatim fix} 直接 @{verbatim show} 会报未绑定。
6. **@{verbatim ncanT} / @{verbatim incanT} / @{verbatim typechk} /
   @{verbatim gen_ccs} / @{verbatim clean_ccs} 都是库的
   @{verbatim method_setup}**，只在加载过 Type/Wfd 理论后可见；
   Draft 会话 @{verbatim "-l IsaTutCCL"} 已带，换父堆要重新确认。
7. **@{verbatim HTT_rews} 是 simp 规则**，所以
   @{verbatim "succ(zero) : HTT"} 一步过；但它**不**知道
   @{verbatim "letrec"} 定义的函数，对函数项基本无能为力
   （库源码第 12–16 行自认）。
8. **@{verbatim INCL} 是公理不是定理**：@{verbatim INCL_def}
   把"包含"定义成一条全称命题，@{verbatim inclI} 是唯一入口；
   想证 @{verbatim "INCL(P)"} 必须对**任意** @{verbatim f} 证明
   那个蕴含式，大多数直观上"包含"的谓词其实证不出。
9. **@{verbatim eq_INCL} 的 @{verbatim a} / @{verbatim b} 是
   函数变量**：@{verbatim "INCL(\<lambda>x. a(x) = b(x))"} 里
   @{verbatim a} @{verbatim b} 要被合一成具体的项函数，
   写成 @{verbatim "a(t) = b(t)"}（单个点）形式会被
   @{verbatim inclD} 用不上。
10. **@{verbatim reachability} 的证明用了 @{verbatim fix_idgenfp}
    与 @{verbatim id_idgenfp} 两条自反**，读库源码时注意
    @{verbatim idgen} 的 case 五支（源第 12–13 行）与
    @{verbatim term_case} 的五支一一对应，这是整条证明的骨架。\<close>

subsection \<open>71.11 与其他章的接口\<close>

text \<open>第 70 章的 @{verbatim ncase} / @{verbatim nrec} 在这里升级为
@{verbatim ncaseT} / @{verbatim nrecT}，@{verbatim eq_coinduct3} 在
类型层有三块砖 @{verbatim ci3_RI} / @{verbatim ci3_AgenI} /
@{verbatim ci3_AI}；第 69 章的 @{verbatim lfp} / @{verbatim gfp} /
@{verbatim coinduct} / @{verbatim def_induct} 是本章全部定义与
规则的来源；第 72 章直接用 @{verbatim NatPR} / @{verbatim ListPR}
证递归函数终止。\<close>

ML \<open>writeln "==== 71 结束 ===="\<close>

end
