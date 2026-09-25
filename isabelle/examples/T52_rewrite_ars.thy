theory T52_rewrite_ars
  imports Main
begin

section \<open>52.1 抽象重写系统：simp 与终止性的数学\<close>

text \<open>第 7 章的化简器按方程重写；第 5/16 章的终止性检查在防什么？
答案是**抽象重写系统**（ARS）的经典三问：

  - 终止（无无穷归约链）——@{verbatim "fun"} 的 termination；
  - 局部合流（一步分岔终能汇合）——方程组的"无歧义"；
  - 合流（任意两条归约路径终能汇合）——@{verbatim "simp"} 结果
    唯一性的根基。

**Newman 引理**：终止 + 局部合流 ⟹ 合流。本章完整证明它。
骨架之美：对"归约深度"做**强归纳**（过一步关系的传递闭包），
山顶的一步分岔用局部合流缝合，山腰的汇合点再吃一次归纳假设
——第 15 章 @{verbatim "measure"}/良基的手感在这里变成定理。\<close>

ML \<open>writeln "==== 52 开始 ===="\<close>

subsection \<open>52.2 舞台：单步、多步、可合流、在下\<close>

locale ARS =
  fixes R :: "'a \<Rightarrow> 'a \<Rightarrow> bool" (infixl "\<rightarrow>" 50)
begin

definition S :: "('a \<times> 'a) set" where
  "S = {(v, u). u \<rightarrow> v}"

inductive steps (infixl "\<rightarrow>\<^sup>*" 50) where
  refl [intro!]: "x \<rightarrow>\<^sup>* x"
| step [intro]: "x \<rightarrow> y \<Longrightarrow> y \<rightarrow>\<^sup>* z \<Longrightarrow> x \<rightarrow>\<^sup>* z"

inductive joinable (infixl "\<down>" 50) where
  [intro]: "x \<rightarrow>\<^sup>* z \<Longrightarrow> y \<rightarrow>\<^sup>* z \<Longrightarrow> x \<down> y"

text \<open>"在下"关系 @{verbatim "x \<prec> y"}：x 走**至少一步**可达 y，
强归纳的深度用它度量。配套定义 @{verbatim "S"}：把"在下"翻成
集合语言就是 @{verbatim "S\<^sup>+"}（一步关系的传递闭包）——先给
**命名常量**再进证明是本章的工程教训：集合补全式的显示形态
（@{verbatim "{a. case a of ...}"}）与书写形态不合同，blast/meson
对不上号（实测多次）；一律用常量 @{verbatim "S"} 就此免疫：\<close>

inductive below (infixl "\<prec>" 50) where
  one [intro]: "x \<rightarrow> y \<Longrightarrow> x \<prec> y"
| more [intro]: "x \<rightarrow> y \<Longrightarrow> y \<prec> z \<Longrightarrow> x \<prec> z"

definition terminating :: bool where
  "terminating \<longleftrightarrow> wf S"

definition locally_confluent :: bool where
  "locally_confluent \<longleftrightarrow> (\<forall>x y z. x \<rightarrow> y \<longrightarrow> x \<rightarrow> z \<longrightarrow> y \<down> z)"

definition confluent :: bool where
  "confluent \<longleftrightarrow> (\<forall>x y z. x \<rightarrow>\<^sup>* y \<longrightarrow> x \<rightarrow>\<^sup>* z \<longrightarrow> y \<down> z)"

lemma steps_trans: "x \<rightarrow>\<^sup>* y \<Longrightarrow> y \<rightarrow>\<^sup>* z \<Longrightarrow> x \<rightarrow>\<^sup>* z"
  by (induct rule: steps.induct) auto

inductive_cases stepsE [elim!]: "x \<rightarrow>\<^sup>* y"

lemma steps_below: "u \<rightarrow>\<^sup>* w \<Longrightarrow> u = w \<or> u \<prec> w"
proof (induction rule: steps.induct)
  case refl
  then show ?case by simp
next
  case (step u y w)
  then show ?case
  proof (cases "y = w")
    case True
    then show ?thesis using \<open>u \<rightarrow> y\<close> by blast
  next
    case False
    then show ?thesis using step by (metis below.more)
  qed
qed

lemma below_in_trancl: "u \<prec> w \<Longrightarrow> (w, u) \<in> S\<^sup>+"
proof (induction rule: below.induct)
  case (one x y)
  then show ?case by (auto simp: S_def intro: r_into_trancl)
next
  case (more x y z)
  from \<open>x \<rightarrow> y\<close> have "(y, x) \<in> S" by (auto simp: S_def)
  then have yx: "(y, x) \<in> S\<^sup>+" by (rule r_into_trancl)
  from more.IH yx show ?case by (rule trancl_trans)
qed

lemma steps_unfold:
  "x \<rightarrow>\<^sup>* y \<Longrightarrow> x = y \<or> (\<exists>u. x \<rightarrow> u \<and> u \<rightarrow>\<^sup>* y)"
proof (induction rule: steps.induct)
  case refl
  then show ?case by simp
next
  case (step x u y)
  then show ?case
  proof (cases "u = y")
    case True
    then show ?thesis using \<open>x \<rightarrow> u\<close> by blast
  next
    case False
    then show ?thesis using step by (metis steps.step)
  qed
qed

lemma below_wf: "terminating \<Longrightarrow> wf (S\<^sup>+)"
proof -
  assume "terminating"
  then have "wf S" by (simp add: terminating_def)
  then show ?thesis by (rule wf_trancl)
qed

subsection \<open>52.3 Newman 引理\<close>

text \<open>对 @{verbatim "S\<^sup>+"} 的良基性做**强归纳**。山顶一步分岔
（@{verbatim "x \<rightarrow> u"} / @{verbatim "x \<rightarrow> v"}）用局部合流缝合出汇合点
@{verbatim "w"}；归纳假设吃直系后代 u、v 得到 y↓w、w↓z；**汇合点
w 深两步**——@{verbatim "below.more"} 把 @{verbatim "x \<rightarrow> u \<rightarrow>\<^sup>* w"}
折成 @{verbatim "x \<prec> w"}，强归纳在此显威力：\<close>

theorem Newman:
  assumes T: "terminating" and LC: "locally_confluent"
  shows "confluent"
proof -
  from below_wf [OF T] have wf: "wf (S\<^sup>+)" .
  show ?thesis
    unfolding confluent_def
  proof (intro allI impI)
    fix x y z
    assume xy: "x \<rightarrow>\<^sup>* y" and xz: "x \<rightarrow>\<^sup>* z"
    from wf LC xy xz show "y \<down> z"
    proof (induct x arbitrary: y z rule: wf_induct_rule)
      case (less x)
      note IH = less.hyps [rule_format]
      note prems = less.prems
      show ?case
      proof (cases "x = y")
        case True
        then show ?thesis using prems by (metis steps.refl joinable.intros)
      next
        case False
        with prems(2) steps_unfold [of x y] obtain u where xu: "x \<rightarrow> u" and uy: "u \<rightarrow>\<^sup>* y"
          by metis
        show ?thesis
        proof (cases "x = z")
          case True
          show ?thesis
          proof (rule joinable.intros [where z = y])
            show "y \<rightarrow>\<^sup>* y" by (rule steps.refl)
            from \<open>x = z\<close> xu uy show "z \<rightarrow>\<^sup>* y" by (metis steps.step)
          qed
        next
          case False
          with prems(3) steps_unfold [of x z] obtain v where xv: "x \<rightarrow> v" and vz: "v \<rightarrow>\<^sup>* z"
            by metis
          from prems(1) xu xv have uv: "u \<down> v"
            by (simp add: locally_confluent_def)
          then obtain w where uw: "u \<rightarrow>\<^sup>* w" and vw: "v \<rightarrow>\<^sup>* w"
            by (metis joinable.cases)
          from IH [of u] below_in_trancl [OF below.one [OF xu]] prems(1) uy uw have "y \<down> w"
            by metis
          then obtain c where yc: "y \<rightarrow>\<^sup>* c" and wc: "w \<rightarrow>\<^sup>* c"
            by (metis joinable.cases)
          from IH [of v] below_in_trancl [OF below.one [OF xv]] prems(1) vw vz have "w \<down> z"
            by metis
          then obtain d where wd: "w \<rightarrow>\<^sup>* d" and zd: "z \<rightarrow>\<^sup>* d"
            by (metis joinable.cases)
          from xu uw have xw: "x \<prec> w" by (metis below.more below.one steps_below)
          from IH [of w] below_in_trancl [OF xw] prems(1) wc wd have "c \<down> d" by metis
          then obtain e where ce: "c \<rightarrow>\<^sup>* e" and de: "d \<rightarrow>\<^sup>* e"
            by (metis joinable.cases)
          have "y \<rightarrow>\<^sup>* e" using yc ce by (rule steps_trans)
          moreover have "z \<rightarrow>\<^sup>* e" using zd de by (rule steps_trans)
          ultimately show ?thesis by (rule joinable.intros)
        qed
      qed
    qed
  qed
qed

end

subsection \<open>52.4 坑位清单（实测）\<close>

text \<open>1. **强归纳必须过传递闭包**：只对直接后代归纳的话，
   汇合点 @{verbatim "w"}（深两步）吃不到归纳假设——Newman 证明
   的第一道坎。
2. @{verbatim "steps"} 做成"一步+多步"：若做成"多步+一步"，
   两条路径的对称性会差一档，山顶分析对不齐。
3. 局部合流只管**一步**分岔；直接用它证合流（不加终止性）
   是错的——反例是经典作业题，Nitpick 在小模型上能找到。
4. 终止性的集合形态 @{verbatim "wf {(y,x). x <rightarrow> y}"}：
   配对方向是 (后代, 祖先)，写反 @{verbatim "wf"} 直接不成立。
5. 传递闭包 @{verbatim "(?S\<^sup>+)"} 与多步的换算要一条
   引理垫背（@{verbatim "steps_beneath"}）——它在数学里是
   "显然"，在证明助手里是活。\<close>

thm ARS.Newman

ML \<open>writeln "==== 52 结束 ===="\<close>

end
