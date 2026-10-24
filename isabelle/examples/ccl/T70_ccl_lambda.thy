theory T70_ccl_lambda
  imports "IsaTutCCL.CCL" "IsaTutCCL.Term"
begin

section \<open>70.1 一个"无类型但可证"的函数语言\<close>

text \<open>第 69 章在 FOL 上造了集合论；@{verbatim CCL} 理论则往前一步：
造一个**无类型 λ 演算**，并给出它的指称语义。库开篇（源码
@{verbatim "src/CCL/CCL.thy"} 第 13–17 行）把动机说得很直白：

@{verbatim "Based on FOL extended with set collection, a primitive higher-order"}
@{verbatim "logic.  HOL is too strong - descriptions prevent a type of programs"}
@{verbatim "being defined which contains only executable terms."}

HOL 的 @{verbatim "@{term undefined}"} 之类描述算子太强：任何类型都能塞进
一个"不可执行"的项。CCL 的对策是**不要类型**——所有程序项只有一个类型
@{verbatim i}，函数也是项（@{verbatim "lam x. b(x) : i"}），
用 @{verbatim bot} 表示发散。代价是全部性质都要从公理出发；
收益是第 69 章的 lfp/gfp/余归纳机器可以直接用来证行为等价。\<close>

ML \<open>writeln "==== 70 开始 ===="\<close>


subsection \<open>70.2 类型类 prog：让"万物皆项"类型安全\<close>

text \<open>库源码第 13–25 行。第 13–17 行的 @{verbatim text} 块是库作者的自白；后八行搞定"无类型"：

@{verbatim "class prog = \"term\""}
@{verbatim "default_sort prog"}
@{verbatim "instance \"fun\" :: (prog, prog) prog .."}
@{verbatim "typedecl i"}
@{verbatim "instance i :: prog .."}

@{verbatim i} 是一个新类型（@{verbatim typedecl}，第 47 章同款），
归属于类型类 @{verbatim prog}；再宣布函数空间保持 @{verbatim prog}。
于是 @{verbatim "i\<Rightarrow>i"} 也是程序类型，@{verbatim "lambda ::(i\<Rightarrow>i)\<Rightarrow>i"}
就能把函数变成项——这是"无类型"的技术核心：
**不是没有类型，而是把所有东西压进同一个类型**。
@{verbatim "default_sort prog"} 让裸类型变量默认取 @{verbatim prog} 排序，
所以 @{verbatim fix} / @{verbatim SIM} 这些多态常量不用写排序注解。\<close>

text \<open>自应用 @{verbatim "lam x. x`x"}（Ω 的前半身）因此良型：\<close>

term "lam x. x ` x"

text \<open>打印确认它就是一个普通的 @{verbatim i} 项。注意 @{verbatim "`"}
是应用的中缀写法（源码第 41 行，@{verbatim "infixl"} 优先级 56），
**必须写括号**的旧应用语法在 FOL 里同样有效，两者混用即可。\<close>


subsection \<open>70.3 Eval：操作语义的九条公理\<close>

text \<open>求值判断 @{verbatim "t \<longlongrightarrow> c"} 在 @{verbatim consts} 块里声明（源码第 28–45 行，
@{verbatim Eval} 中缀在第 30 行），九条公理在第 50–59 行整个**公理化**：
五个构造子各自求值成自身，@{verbatim case} 按构造子分派，

@{verbatim "axiomatization where"}
@{verbatim "  trueV:       \"true \<longlongrightarrow> true\" and"}
@{verbatim "  falseV:      \"false \<longlongrightarrow> false\" and"}
@{verbatim "  pairV:       \"<a,b> \<longlongrightarrow> <a,b>\" and"}
@{verbatim "  lamV:        \"\<And>b. lam x. b(x) \<longlongrightarrow> lam x. b(x)\" and"}
@{verbatim "  caseVtrue:   \"\<lbrakk>t \<longlongrightarrow> true; d \<longlongrightarrow> c\<rbrakk> \<Longrightarrow> case(t,d,e,f,g) \<longlongrightarrow> c\" and"}
@{verbatim "  caseVfalse:  \"\<lbrakk>t \<longlongrightarrow> false; e \<longlongrightarrow> c\<rbrakk> \<Longrightarrow> case(t,d,e,f,g) \<longlongrightarrow> c\" and"}
@{verbatim "  caseVpair:   \"\<lbrakk>t \<longlongrightarrow> <a,b>; f(a,b) \<longlongrightarrow> c\<rbrakk> \<Longrightarrow> case(t,d,e,f,g) \<longlongrightarrow> c\" and"}
@{verbatim "  caseVlam:    \"\<And>b. \<lbrakk>t \<longlongrightarrow> lam x. b(x); g(b) \<longlongrightarrow> c\<rbrakk> \<Longrightarrow> case(t,d,e,f,g) \<longlongrightarrow> c\""}

外加两条"元"性质：@{verbatim canonical}（源第 63–68 行）说
@{verbatim "t \<longlongrightarrow> c"} 里的 @{verbatim c} 必是构造子形态；
@{verbatim substitute}（源第 71–72 行，库注释自嘲
@{verbatim "Should be derivable - but probably a bitch!"}）说等量可代换。
这些公理只用来**读**语义，后面的推理一条也不用——库的全部引理
都从 @{verbatim caseB} 那组 β 规则出发。\<close>

thm trueV falseV pairV lamV
thm caseVtrue caseVfalse caseVpair caseVlam
thm canonical substitute


subsection \<open>70.4 bot 与 apply：Ω 组合子与"应用即 case"\<close>

text \<open>库源码第 78–83 行。@{verbatim bot} 就是 λ 演算里最著名的发散项：

@{verbatim "axiomatization where"}
@{verbatim "  bot_def:         \"bot == (lam x. x`x)`(lam x. x`x)\" and"}
@{verbatim "  apply_def:     \"f ` t == case(f, bot, bot, \<lambda>x y. bot, \<lambda>u. u(t))\""}

@{verbatim bot} 定义为 @{verbatim "(lam x. x`x)`(lam x. x`x)"}（Ω）；
而**应用不是原始构造子，是用 @{verbatim case} 定义出来的**：
@{verbatim "f ` t"} 对 @{verbatim f} 分类讨论——是函数就套上去
（@{verbatim "\<lambda>u. u(t)"}），是 @{verbatim bot} 就还是 @{verbatim bot}
（严格性）。这一手让"应用"继承了 @{verbatim case} 的全部规则，
整部理论的公理数量骤减。@{verbatim fix} 则循例定义（源第 82–83 行）：\<close>

thm bot_def apply_def fix_def

text \<open>行为随之而来：函数作用于参数是 β（@{verbatim applyB}），
发散项吞掉一切（@{verbatim applyBbot}），而 @{verbatim fix} 展开成
一步自调用（@{verbatim fixB}，库源码 @{verbatim "src/CCL/Term.thy"}
第 191–194 行）。\<close>

thm applyB applyBbot fixB

text \<open>K 组合子 @{verbatim "lam x. lam y. x"} 先吃 @{verbatim a} 再吃
@{verbatim b}，两次 β 之后返回第一个参数——"函数真的在算"：\<close>

lemma beta_demo: "((lam x. lam y. x) ` a) ` b = a"
  by simp

text \<open>注意 @{verbatim "by simp"} 一步过：@{verbatim applyB} 已在
@{verbatim termBs} 里挂成 simp 规则（Term 理论第 272–276 行）。
@{verbatim fixB} **故意**没挂——它的右端还含 @{verbatim fix}，
挂上去 simp 会无限展开。要用它就地展开、配 @{verbatim arg_cong}：\<close>

lemma fix_unfold_demo: "f(fix(f)) = f(f(fix(f)))"
  by (rule arg_cong [OF fixB])

text \<open>另一个方向：@{verbatim "bot ` a = bot"}（严格性）也是一步：\<close>

lemma apply_bot_demo: "bot ` a = bot"
  by simp


subsection \<open>70.5 构造子的内射性与相异性\<close>

text \<open>库源码第 218–225 行用一段 ML（@{verbatim inj_rl_tac}）从
@{verbatim caseB} 规则**生成**内射律：

@{verbatim "lemma ccl_injs:"}
@{verbatim "  \"<a,b> = <a',b'> \<longleftrightarrow> (a=a' \<and> b=b')\""}
@{verbatim "  \"\<And>b b'. (lam x. b(x) = lam x. b'(x)) \<longleftrightarrow> ((ALL z. b(z)=b'(z)))\""}
@{verbatim "  by (inj_rl caseBs)"}

相异性（源第 233–299 行）更凶：@{verbatim mk_dstnct_thms} 把
@{verbatim "bot/true/false/pair/lambda"} 两两不等**全部机器生成**出来，
挂进 @{verbatim "[simp]"}。于是"不同构造子永不相等"在simp 里免费：\<close>

thm ccl_injs pair_inject

lemma pair_inj_demo: "<a,b> = <a',b'> \<Longrightarrow> a = a' \<and> b = b'"
  by (simp add: ccl_injs)

lemma lam_inj_demo: "lam x. b(x) = lam x. b'(x) \<Longrightarrow> ALL z. b(z) = b'(z)"
  by (simp add: ccl_injs)

lemma dstnct_demo: "<a,b> \<noteq> lam x. f(x)"
  by simp

text \<open>配合 @{verbatim exhaustion}（源第 488–491 行）与
@{verbatim term_case}（源第 493–495 行），任何关于"项长什么样"的命题
都能五路穷举——@{verbatim term_case} 就是无类型世界的
@{verbatim "full_nat_case"}：\<close>

thm exhaustion term_case

lemma term_case_demo:
  assumes "P(bot)" and "P(true)" and "P(false)"
    and "\<And>x y. P(<x,y>)" and "\<And>b. P(lam x. b(x))"
  shows "P(t)"
  using assms by (rule term_case)


subsection \<open>70.6 行为等价是最大不动点：SIM / POgen / EQgen\<close>

text \<open>库源码第 89–105 行是全章的理论核心。先定义"两个项在一个关系
@{verbatim R} 下同构"（@{verbatim SIM}）：

@{verbatim "definition SIM :: \"[i,i,i set]\<Rightarrow>o\""}
@{verbatim "  where"}
@{verbatim "  \"SIM(t,t',R) ==  (t=true \<and> t'=true) | (t=false \<and> t'=false) |"}
@{verbatim "                  (\<exists>a a' b b'. t=<a,b> \<and> t'=<a',b'> \<and> <a,a'> : R \<and> <b,b'> : R) |"}
@{verbatim "                  (\<exists>f f'. t=lam x. f(x) \<and> t'=lam x. f'(x) \<and> (ALL x.<f(x),f'(x)> : R))\""}

再由它长出两个"生成子"：@{verbatim POgen}（预序）容忍左边是
@{verbatim bot}——@{verbatim "bot [= 任何东西"}；@{verbatim EQgen}
（等价）则要求两边同时 @{verbatim bot}：

@{verbatim "definition POgen :: \"i set \<Rightarrow> i set\""}
@{verbatim "  where \"POgen(R) == {p. \<exists>t t'. p=<t,t'> \<and> (t = bot | SIM(t,t',R))}\""}
@{verbatim "definition EQgen :: \"i set \<Rightarrow> i set\""}
@{verbatim "  where \"EQgen(R) == {p. \<exists>t t'. p=<t,t'> \<and> (t = bot \<and> t' = bot | SIM(t,t',R))}\""}

@{verbatim PO} 与 @{verbatim EQ} 就是这两个生成子的**最大**不动点
（第 69 章的 @{verbatim gfp}）：

@{verbatim "definition PO :: \"i set\""}
@{verbatim "  where \"PO == gfp(POgen)\""}
@{verbatim "definition EQ :: \"i set\""}
@{verbatim "  where \"EQ == gfp(EQgen)\""}

最后用两条公理把 @{verbatim "[="} / @{verbatim "="} 接回不动点
（源第 128–130 行）：@{verbatim "t [= t' \<longleftrightarrow> <t,t'> : PO"}、
@{verbatim "t = t' \<longleftrightarrow> <t,t'> : EQ"}。也就是说
**行为等价被*定义*成最大不动点里的成员关系**，余归纳因此天然可用。\<close>

thm SIM_def POgen_def EQgen_def PO_def EQ_def
thm PO_iff EQ_iff eq_iff


subsection \<open>70.7 poXH / eqXH：把不动点方程展开成结构规则\<close>

text \<open>库源码第 323–339 行与第 441–463 行干的是同一件事：
借第 69 章的 @{verbatim def_gfp_Tarski}（@{verbatim "mono(f) \<Longrightarrow> gfp(f) = f(gfp(f))"}）
把定义展开成可直接读的刻画。先证单调性，再让 Tarski 方程穿过
@{verbatim XHlemma1}：\<close>

thm POgen_mono EQgen_mono
thm POgenXH EQgenXH
thm poXH eqXH

text \<open>@{verbatim poXH} 说的是：@{verbatim "t [= t'"} 成立，当且仅当
@{verbatim "t = bot"}，或两者同为 @{verbatim true} / @{verbatim false}，
或同为序对且分量同在 @{verbatim "[="} 中，或同为 λ 且逐点同在。
@{verbatim eqXH} 同构，只把 @{verbatim bot} 一支改成两边皆
@{verbatim bot}。注意 @{verbatim "t = bot"} 在 @{verbatim poXH} 里
**不要求 @{verbatim "t' = bot"}**——这正是"发散模拟一切"的相异性所在。\<close>

thm po_bot bot_poleast po_pair po_lam

text \<open>三条读出的小结论：@{verbatim po_bot}（bot 是预序底元）、
@{verbatim bot_poleast}（只有 bot 能 @{verbatim "[= bot"}，
即"不比底元更小"）、@{verbatim po_pair} / @{verbatim po_lam}
（序对与 λ 的规则可当双向 iff 用）。@{verbatim "="} 一侧对应
@{verbatim eq_iff}：相等就是互相 @{verbatim "[="}。\<close>

thm eq_iff
thm Trm_iff Dvg_iff


subsection \<open>70.8 余归纳实战一：po_coinduct 与 bot [= t\<close>

text \<open>库源码第 427–430 行给出预序的余归纳规则——它正是第 69 章
@{verbatim coinduct} 的实例：

@{verbatim "lemma po_coinduct: \"\<lbrakk><t,u> : R; R <= POgen(R)\<rbrakk> \<Longrightarrow> t [= u\""}
@{verbatim "  apply (rule PO_def [THEN def_coinduct, THEN PO_iff [THEN iffD2]])"}
@{verbatim "   apply assumption+"}
@{verbatim "  done"}

用法与 HOL 的 @{verbatim "coinduct"} 一式一样：找一个把
@{verbatim "<t,u>"} 装进去的关系 @{verbatim R}，再证 @{verbatim R}
在 @{verbatim POgen} 下封闭。下面证 @{verbatim "bot [= t"}：
取 @{verbatim "R = {<bot,t>}"}，第一件事显然；第二件事里
@{verbatim POgen} 的 @{verbatim "t = bot"} 析取支正好兜住：\<close>

lemma po_bot_demo: "bot [= t"
proof (rule po_coinduct[of _ _ "{<bot,t>}"])
  show "<bot,t> : {<bot,t>}" by simp
  show "{<bot,t>} <= POgen({<bot,t>})"
  proof (rule subsetI)
    fix p assume hp: "p : {<bot,t>}"
    then have pz: "p = <bot,t>" by simp
    then show "p : POgen({<bot,t>})" by (simp add: POgenXH)
  qed
qed

text \<open>顺带说明：@{verbatim POgen} 比 @{verbatim EQgen} 弱的根源就在
@{verbatim "t = bot"} 这一支——它让 @{verbatim bot} 单方面模拟任何项，
所以 @{verbatim "[="} 只是预序；@{verbatim "="} 要两边同时发散，
才是真正的等价关系。\<close>


subsection \<open>70.9 余归纳实战二：eq_coinduct3 证"点等则 lam 等"\<close>

text \<open>库源码第 465–480 行。弱的 @{verbatim eq_coinduct} 要求
@{verbatim "R <= EQgen(R)"}，可 R 通常装不下"展开一层"才出现的对；
Martin Coen 的强化版把 @{verbatim R} 自己和 @{verbatim EQ}
一起塞进生成子，再取**最小**不动点：

@{verbatim "lemma eq_coinduct3:"}
@{verbatim "  \"\<lbrakk><t,u> : R;  R <= EQgen(lfp(\<lambda>x. EQgen(x) Un R Un EQ))\<rbrakk> \<Longrightarrow> t = u\""}
@{verbatim "  apply (rule EQ_def [THEN def_coinduct3, THEN EQ_iff [THEN iffD2]])"}
@{verbatim "  apply (rule EQgen_mono | assumption)+"}
@{verbatim "  done"}

库还把它包成方法（源第 476–480 行），
@{verbatim "eq_coinduct3 \"{p. ...}\""} 一把梭。下面不用方法，
把两条义务拆开写清楚。要证的命题：**两个函数逐点相等，则两个
λ 相等**。余归纳关系必须比目标大一圈——既要装下两个 λ 本身，
也要装下它们展开后出现的每一对 @{verbatim "<f(z),f'(z)>"}：\<close>

lemma lam_eq_demo:
  assumes h: "\<And>x. f(x) = f'(x)"
  shows "lam x. f(x) = lam x. f'(x)"
proof (eq_coinduct3 "{p. EX z. p = <f(z), f'(z)>} Un {p. p = <lam x. f(x), lam x. f'(x)>}")
  show "<lam x. f(x), lam x. f'(x)> : {p. EX z. p = <f(z), f'(z)>} Un {p. p = <lam x. f(x), lam x. f'(x)>}"
    by simp
next
  let ?R = "{p. EX z. p = <f(z), f'(z)>} Un {p. p = <lam x. f(x), lam x. f'(x)>}"
  let ?L = "lfp(\<lambda>x. EQgen(x) Un ?R Un EQ)"
  have R_le_L: "?R <= ?L"
    by (rule lfp_greatest) blast
  have hL: "\<And>x. <f(x),f'(x)> : ?L"
    using R_le_L by (blast intro: UnI1 CollectI)
  have EQ_le_L: "EQ <= ?L"
    by (rule lfp_greatest) blast
  have refl_L: "\<And>a. <a,a> : ?L"
    using EQ_le_L by (blast dest: subsetD intro: EQ_iff [THEN iffD1])
  have TT: "\<And>t. <t,t> : EQgen(?L)"
  proof -
    fix t show "<t,t> : EQgen(?L)"
    proof (rule term_case[where P = "\<lambda>t. <t,t> : EQgen(?L)"])
      show "<bot,bot> : EQgen(?L)" by (simp add: EQgenXH)
      show "<true,true> : EQgen(?L)" by (simp add: EQgenXH)
      show "<false,false> : EQgen(?L)" by (simp add: EQgenXH)
      fix x y show "<<x,y>,<x,y>> : EQgen(?L)"
        by (simp add: EQgenXH refl_L)
      fix b show "<lam x. b(x), lam x. b(x)> : EQgen(?L)"
        by (auto simp add: EQgenXH intro: refl_L)
    qed
  qed
  show "?R <= EQgen(?L)"
  proof (rule Un_least)
    show "{p. EX z. p = <f(z), f'(z)>} <= EQgen(?L)"
    proof (rule subsetI)
      fix p assume hp: "p : {p. EX z. p = <f(z), f'(z)>}"
      then obtain z where pz: "p = <f(z), f'(z)>" by blast
      with h have "p = <f(z), f(z)>" by simp
      then show "p : EQgen(?L)" by (simp add: TT)
    qed
    show "{p. p = <lam x. f(x), lam x. f'(x)>} <= EQgen(?L)"
    proof (rule subsetI)
      fix p assume hp: "p : {p. p = <lam x. f(x), lam x. f'(x)>}"
      then have pz: "p = <lam x. f(x), lam x. f'(x)>" by blast
      have e: "EX f'' f'''. lam x. f(x) = lam x. f''(x)
            \<and> lam x. f'(x) = lam x. f'''(x) \<and> (ALL x. <f''(x),f'''(x)> : ?L)"
      proof (rule exI[of _ f], rule exI[of _ f'])
        show "lam x. f(x) = lam x. f(x) \<and> lam x. f'(x) = lam x. f'(x)
            \<and> (ALL x. <f(x),f'(x)> : ?L)"
          by (simp add: hL)
      qed
      have key: "<lam x. f(x), lam x. f'(x)> : EQgen(?L)"
      proof (rule EQgenXH [THEN iffD2])
        show "lam x. f(x) = bot \<and> lam x. f'(x) = bot
            | lam x. f(x) = true \<and> lam x. f'(x) = true
            | lam x. f(x) = false \<and> lam x. f'(x) = false
            | (EX a a' b b'. lam x. f(x) = <a,b> \<and> lam x. f'(x) = <a',b'>
                \<and> <a,a'> : ?L \<and> <b,b'> : ?L)
            | (EX f'' f'''. lam x. f(x) = lam x. f''(x) \<and> lam x. f'(x) = lam x. f'''(x)
                \<and> (ALL x. <f''(x),f'''(x)> : ?L))"
          by (rule disjI2 [OF disjI2 [OF disjI2 [OF disjI2 [OF e]]]])
      qed
      from pz key show "p : EQgen(?L)" by simp
    qed
  qed
qed

text \<open>拆开看第二义务做了什么：@{verbatim R_le_L} 与 @{verbatim EQ_le_L}
都是 @{verbatim lfp_greatest} 的一行推论——"任何前不动点都装得下
@{verbatim R} 与 @{verbatim EQ}"，于是最小不动点 @{verbatim ?L} 也装得下。
有了 @{verbatim refl_L}（"任何项与自己相关"）和 @{verbatim hL}
（"点对相关"），@{verbatim "R <= EQgen(?L)"} 就只是逐构造子核对：
序对分支用 @{verbatim refl_L}，λ 分支用 @{verbatim hL}。
@{verbatim disjI2} 四连发是把五路析取里的前四路（bot/true/false/序对）
留给 @{verbatim simp} 已经证伪的相异性规则，只留 λ 这一路。
这就是第 72 章证无限列表等式的主力武器的完整机械结构。\<close>


subsection \<open>70.10 Term 理论：把常用程序构造搬进 CCL\<close>

text \<open>库源码 @{verbatim "src/CCL/Term.thy"} 在第 12–152 行用
@{verbatim case} 定义了一整套"标准库"：布尔 @{verbatim "if"}、
和类型 @{verbatim "inl/inr"}、序对投影 @{verbatim "split/fst/snd/thd"}、
自然数 @{verbatim "zero/succ/ncase/nrec"}、列表 @{verbatim "nil/cons/lcase/lrec"}、
迭代 @{verbatim napply}，以及 @{verbatim let1} / @{verbatim letrec}
（递归！）。定义一律一行，规则一律成组：\<close>

thm if_def inl_def inr_def split_def when_def fst_def snd_def thd_def
thm zero_def succ_def ncase_def let_def letrec_def nil_def cons_def
thm lcase_def lrec_def napply_def

text \<open>第 166–276 行给出全套 β 规则（@{verbatim termBs}），
命名规律与第 69 章的 I/D/E 一致：@{verbatim "splitB"} 是 β，
@{verbatim "splitBbot"} 是严格性（@{verbatim bot} 穿到底）：

@{verbatim "lemma splitB: \"split(<a,b>,h) = h(a,b)\""}
@{verbatim "  and splitBbot: \"split(bot,h) = bot\""}
@{verbatim "  unfolding data_defs by beta_rl+"}

@{verbatim beta_rl} 是库自带的战术（源第 203–211 行）：
在 @{verbatim rawBs} 上跑 simp，再把 @{verbatim letrecB}
（源第 196–199 行）当**循环规则**喂进去——递归定义一步展开一层，
不会死循环。@{verbatim fixB} / @{verbatim letrecB} 的证明本身就三行，
靠的全是 @{verbatim ssubst} 和 @{verbatim applyB}。\<close>

thm splitB splitBbot fstB sndB thdB
thm ifBtrue ifBfalse ifBbot whenBinl whenBinr whenBbot
thm ncaseBzero ncaseBsucc ncaseBbot
thm nrecBzero nrecBsucc nrecBbot
thm lcaseBnil lcaseBcons lcaseBbot
thm lrecBnil lrecBcons lrecBbot
thm napplyBzero napplyBsucc
thm letB applyB applyBbot fixB letrecB

text \<open>这些规则挂成 simp 之后，"执行"就是重写。下面三条演示
三个层次：构造子分派、原始递归**真的在算**、迭代计数。\<close>

lemma fst_demo: "fst(<a,b>) = a"
  by simp

lemma if_demo: "if true then t else u = t"
  by simp

text \<open>@{verbatim "nrec(succ(succ(zero)), one, \<lambda>x g. succ(g))"}
读作"以 @{verbatim one} 为基例、每步套一层 @{verbatim succ}的
两层递归"——算出来正是 @{verbatim "succ(succ(one))"}，
即 CCL 世界里的 @{verbatim 2}。这就是"计算逻辑"的字面意思：\<close>

lemma nrec_eval_demo: "nrec(succ(succ(zero)), one, \<lambda>x g. succ(g)) = succ(succ(one))"
  by simp

lemma napply_demo: "(\<lambda>x. succ(x)) ^ succ(succ(zero)) ` zero = succ(succ(zero))"
  by simp

text \<open>@{verbatim term_injs}（源第 281–286 行）与 @{verbatim ccl_injs}
同款，把 @{verbatim "inl/inr/succ/cons"} 的内射性也机器生成出来；
@{verbatim term_porews}（源第 300–305 行）则把数据构造子的
@{verbatim "[="} 规则配齐，供第 72 章的流等式证明使用。\<close>

thm term_injs term_porews


subsection \<open>70.11 坑位清单（实测）\<close>

text \<open>1. **CCL 不是 HOL**：没有 @{verbatim value}、没有
   @{verbatim "fun"} 高阶数据类型、没有 @{verbatim QuickCheck}。
   所有项只有一个类型 @{verbatim i}，"多态"靠类型类 @{verbatim prog}
   的排序约束表达，写 @{verbatim "'a::prog"} 才显式。
2. **@{verbatim "`"} 应用必须写括号**：@{verbatim "f ` t"} 不是
   @{verbatim "f t"}；@{verbatim "lam x. b(x)"} 的 @{verbatim "b(x)"}
   同理（FOL 旧应用语法，第 47/69 章同款坑）。
3. **@{verbatim fixB} / @{verbatim letrecB} 不能进 simp 集**：
   右端仍含 @{verbatim fix} / @{verbatim letrec}，挂上去无限展开。
   库的解法是 @{verbatim beta_rl} 把 @{verbatim letrecB}
   注册成 simp 的**循环规则**（@{verbatim set_loop}）。
4. **@{verbatim "rule term_case"} 会把高阶变量 @{verbatim P}
   绑错**：目标 @{verbatim "<t,t> : ..."} 与结论 @{verbatim "P(?t)"}
   合一有两种解，默认那一种是对**序对** @{verbatim "<t,t>"}
   做案例分析。必须 @{verbatim "where P = \"\<lambda>t. ...\""}
   显式给出（本章 @{verbatim TT} 的证法）。
5. **@{verbatim "eq_coinduct3 \"{p. ...}\""} 与
   @{verbatim "rule eq_coinduct3[of ...]"} 是两回事**：前者是
   @{verbatim method_setup} 注册的方法，直接吃关系项；后者是引理，
   @{verbatim of} 按变量出现顺序填（第一个是 @{verbatim t} 不是
   @{verbatim R}），填错报类型冲突。@{verbatim po_coinduct}
   没有方法版，只能 @{verbatim "rule po_coinduct[of _ _ R]"}。
6. **@{verbatim EQgenXH} 的析取支是关于 @{verbatim t} 与
   @{verbatim t'} 两个分量**，不是关于序对 @{verbatim "<t,t'>"}：
   写成 @{verbatim "<lam...,lam...> = bot"} 会被 simp 的相异性
   规则直接判假，报 @{verbatim "Failed to finish: False"}。
7. **FOL 没有 @{verbatim disjI3} 以上的析取引入规则**，
   五路析取只能 @{verbatim "disjI2 [OF disjI2 [OF ...]]"} 叠，
   或者先 @{verbatim simp} 把前几路证伪再收尾。
8. **@{verbatim EQ_refl} 在 @{verbatim Type} 理论里**，不在
   @{verbatim CCL}；在 @{verbatim CCL} 里要
   @{verbatim "EQ_iff [THEN iffD1]"} 配 @{verbatim refl} 用。
9. **@{verbatim ccl_dstncts} 是机器生成的 simp 规则**，
   所以 @{verbatim "<a,b> = lam x. f(x)"} 这类目标 simp 一步证伪；
   但**生成它们的 ML 在理论加载时跑**，改库源码要连 ML 一起重放。
10. **@{verbatim "class prog"} 与 @{verbatim "default_sort prog"}
    在 Isabelle2025-2 仍然有效**，但这是 1993 年的类型类用法：
    排序推断失败时报的是 @{verbatim "prog"} 而非具体类型，
    读报错要先想"哪个类型变量该有 @{verbatim prog} 排序"。\<close>

subsection \<open>70.12 与其他章的接口\<close>

text \<open>第 69 章的 @{verbatim gfp} + @{verbatim coinduct3} 是本章
行为等价的全部机器，@{verbatim lfp} 在 @{verbatim eq_coinduct3} 里
反转为辅助角色；第 71 章把 @{verbatim Nat} / @{verbatim List} 从
"编码"升级为"类型即项集"；第 72 章的四个例子理论用本章全部机制
写真正的程序，并用 @{verbatim eq_coinduct3} 证流等式。\<close>

ML \<open>writeln "==== 70 结束 ===="\<close>

end
