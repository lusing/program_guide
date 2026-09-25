theory T49_stlc
  imports Main
begin

section \<open>49.1 λ 演算与简单类型：Pure 的心脏\<close>

text \<open>Isabelle 的项语言来自**简单类型 λ 演算**（STLC）：类型、抽象、
应用。implementation 手册第 1 章的推理规则就是 STLC 上的自然演绎。
本章把 STLC 当数学对象完整形式化，并证**类型安全**两定理：

  - **进展（progress）**：良类型**闭**项不是值，就是能前进一步；
  - **保持（preservation）**：前进一步后类型不变。

配方（Wright--Felleisen）：第 4 章 @{verbatim "datatype"} 搭语法、
第 31 章 @{verbatim "inductive"} 搭类型与求值、再手证两条结构引理。
变量用 de Bruijn 指标，换名问题从根上消失。\<close>

ML \<open>writeln "==== 49 开始 ===="\<close>

subsection \<open>49.2 语法、类型环境、类型规则\<close>

datatype ty =
  TNat
| TFun ty ty  (infixr "\<rightarrow>" 60)

datatype tm =
  Var nat
| Lam ty tm
| App tm tm

text \<open>环境 @{verbatim "env :: ty list"} 是**内层在前**的类型表：
@{verbatim "Var i"} 的类型是 @{verbatim "nth env i"}（@{verbatim "Var 0"}
指向最内层抽象）。类型判断是推导规则系统：\<close>

inductive typing :: "ty list \<Rightarrow> tm \<Rightarrow> ty \<Rightarrow> bool" ("_ \<turnstile> _ : _" 50) where
  T_Var [intro!]: "i < length env \<Longrightarrow> nth env i = T \<Longrightarrow> env \<turnstile> Var i : T"
| T_Lam [intro!]: "T1 # env \<turnstile> t : T2 \<Longrightarrow> env \<turnstile> Lam T1 t : T1 \<rightarrow> T2"
| T_App [intro!]: "env \<turnstile> t1 : T1 \<rightarrow> T2 \<Longrightarrow> env \<turnstile> t2 : T1 \<Longrightarrow> env \<turnstile> App t1 t2 : T2"

subsection \<open>49.3 带 cutoff 的移位与带位置的代换\<close>

text \<open>de Bruijn 的两个机械操作。@{verbatim "liftn d k"}：跳过前
@{verbatim "d"} 个局部绑定，其余指标加 @{verbatim "k"}（weakening 的
实现体）；@{verbatim "substn d s"}：在位置 @{verbatim "d"} 代入
@{verbatim "s"}、更大指标降一（β-归约的实现体）。**先吃语法雷**：
@{verbatim "Var 0"} / @{verbatim "Var (Suc i)"} 这种**嵌套数字模式**
primrec 不收（实测 @{verbatim "Nonprimitive pattern"}），指标级分派
用 @{verbatim "case"} 折进去：\<close>

primrec liftn :: "nat \<Rightarrow> nat \<Rightarrow> tm \<Rightarrow> tm" where
  "liftn d k (Var i) = (if i < d then Var i else Var (i + k))"
| "liftn d k (Lam T t) = Lam T (liftn (Suc d) k t)"
| "liftn d k (App t1 t2) = App (liftn d k t1) (liftn d k t2)"

primrec substn :: "nat \<Rightarrow> tm \<Rightarrow> tm \<Rightarrow> tm" where
  "substn d s (Var i) =
     (if i < d then Var i else if i = d then s else Var (i - 1))"
| "substn d s (Lam T t) = Lam T (substn (Suc d) (liftn 0 1 s) t)"
| "substn d s (App t1 t2) = App (substn d s t1) (substn d s t2)"

subsection \<open>49.4 结构引理一：weakening\<close>

text \<open>在 @{verbatim "<Gamma>1 @ \<Gamma>2"}（内段 @\<Gamma>1、外段 @\<Gamma>2）之间插一个
@{verbatim "T0"}，项的指标从位置 @{verbatim "|<Gamma>1|"} 起整体加一，
类型不变。归纳要泛化 @{verbatim "<Gamma>1"}（Lam 情形会把内段加长）：\<close>

lemma lift_ok:
  assumes "env \<turnstile> t : T"
  shows "env = \<Gamma>1 @ \<Gamma>2 \<Longrightarrow> \<Gamma>1 @ T0 # \<Gamma>2 \<turnstile> liftn (length \<Gamma>1) 1 t : T"
  using assms
proof (induction arbitrary: \<Gamma>1 rule: typing.induct)
  case (T_Var i env T)
  then show ?case by (cases "i < length \<Gamma>1") (auto simp: nth_append)
next
  case (T_Lam T1 env t T2)
  then have "T1 # env = (T1 # \<Gamma>1) @ \<Gamma>2" by simp
  then show ?case using T_Lam.IH [of "T1 # \<Gamma>1"] by auto
next
  case (T_App env t1 T1 T2 t2)
  then show ?case by auto
qed

text \<open>代换引理的形状：把 @{verbatim "env = <Gamma>1 @ T0 # \<Gamma>2"} 里
@{verbatim "t"} 的"位置 @{verbatim "|<Gamma>1|"} 处变量"替换成
@{verbatim "<Gamma>1 @ \<Gamma>2"} 里良型的 @{verbatim "s"}，结果在
@{verbatim "<Gamma>1 @ \<Gamma>2"} 里良型。归纳同时泛化 @{verbatim "<Gamma>1"}
与 @{verbatim "s"}（Lam 情形里 @{verbatim "s"} 要 @{verbatim "liftn 0 1"}
抬一层，合法性恰好是上面的 weakening）：\<close>

lemma subst_ok:
  assumes "env \<turnstile> t : T"
  shows "env = \<Gamma>1 @ T0 # \<Gamma>2 \<Longrightarrow> \<Gamma>1 @ \<Gamma>2 \<turnstile> s : T0 \<Longrightarrow>
         \<Gamma>1 @ \<Gamma>2 \<turnstile> substn (length \<Gamma>1) s t : T"
  using assms
proof (induction arbitrary: \<Gamma>1 s rule: typing.induct)
  case (T_Var i env T)
  then show ?case
    by (cases "i < length \<Gamma>1"; cases "i = length \<Gamma>1") (auto simp: nth_append)
next
  case (T_Lam T1 env t T2)
  have split_prem: "T1 # env = (T1 # \<Gamma>1) @ T0 # \<Gamma>2"
    using T_Lam.prems(1) by simp
  have s_lift: "(T1 # \<Gamma>1) @ \<Gamma>2 \<turnstile> liftn 0 1 s : T0"
    using lift_ok [of "\<Gamma>1 @ \<Gamma>2" s T0 "[]" "\<Gamma>1 @ \<Gamma>2" T1] T_Lam.prems(2) by simp
  from T_Lam.IH [OF split_prem s_lift] have prem:
    "T1 # (\<Gamma>1 @ \<Gamma>2) \<turnstile> substn (Suc (length \<Gamma>1)) (liftn 0 1 s) t : T2"
    by simp
  from prem show ?case by (auto simp: substn.simps)
next
  case (T_App env t1 T1 T2 t2)
  then show ?case by auto
qed

subsection \<open>49.6 一步求值\<close>

primrec is_value :: "tm \<Rightarrow> bool" where
  "is_value (Var i) = False"
| "is_value (Lam T t) = True"
| "is_value (App t1 t2) = False"

inductive eval :: "tm \<Rightarrow> tm \<Rightarrow> bool" (infixl "\<longmapsto>" 50) where
  E_AppAbs [intro!]: "is_value v2 \<Longrightarrow> App (Lam T1 t12) v2 \<longmapsto> substn 0 v2 t12"
| E_App1 [intro!]: "t1 \<longmapsto> t1' \<Longrightarrow> App t1 t2 \<longmapsto> App t1' t2"
| E_App2 [intro!]: "is_value v1 \<Longrightarrow> t2 \<longmapsto> t2' \<Longrightarrow> App v1 t2 \<longmapsto> App v1 t2'"

subsection \<open>49.7 反演与规范形式\<close>

inductive_cases [elim!]:
  "[] \<turnstile> Var i : T"
  "\<Gamma> \<turnstile> Var i : T"
  "\<Gamma> \<turnstile> Lam T1 t : T"
  "\<Gamma> \<turnstile> App t1 t2 : T"

lemma canonical_forms:
  assumes "\<Gamma> \<turnstile> v : T1 \<rightarrow> T2" "is_value v"
  shows "\<exists>T' t'. v = Lam T' t'"
  using assms by (cases v) auto

subsection \<open>49.8 进展定理\<close>

theorem progress:
  assumes "[] \<turnstile> t : T"
  shows "is_value t \<or> (\<exists>t'. t \<longmapsto> t')"
  using assms
proof (induction t arbitrary: T)
  case (Var i)
  then show ?case by (auto elim: typing.cases)
next
  case (Lam T0 t0)
  then show ?case by simp
next
  case (App t1 t2)
  from App.prems obtain T1 T2 where
    t1T: "[] \<turnstile> t1 : T1 \<rightarrow> T2" and t2T: "[] \<turnstile> t2 : T1"
    by (blast elim: typing.cases)
  from App.IH(1) [OF t1T] show ?case
  proof
    assume "is_value t1"
    then obtain T' tb where t1: "t1 = Lam T' tb"
      using canonical_forms t1T by blast
    from App.IH(2) [OF t2T] show ?thesis
    proof
      assume "is_value t2"
      from t1 have "is_value t1" by simp
      then show ?thesis using t1 \<open>is_value t2\<close> by blast
    next
      assume "\<exists>t2'. t2 \<longmapsto> t2'"
      then obtain t2' where "t2 \<longmapsto> t2'" ..
      from t1 have "is_value t1" by simp
      then show ?thesis using \<open>t2 \<longmapsto> t2'\<close> by blast
    qed
  next
    assume "\<exists>t1'. t1 \<longmapsto> t1'"
    then obtain t1' where "t1 \<longmapsto> t1'" ..
    then show ?thesis by blast
  qed
qed

subsection \<open>49.9 保持定理\<close>

theorem preservation:
  assumes "\<Gamma> \<turnstile> t : T" and "t \<longmapsto> t'"
  shows "\<Gamma> \<turnstile> t' : T"
  using assms(2,1)
proof (induction arbitrary: \<Gamma> T rule: eval.induct)
  case (E_AppAbs v2 T1 t12)
  then obtain T1' where lam: "\<Gamma> \<turnstile> Lam T1 t12 : T1' \<rightarrow> T"
    and v2: "\<Gamma> \<turnstile> v2 : T1'"
    by (blast elim: typing.cases)
  from lam have inner: "T1' # \<Gamma> \<turnstile> t12 : T" by (blast elim: typing.cases)
  from subst_ok [of "T1' # \<Gamma>" t12 T "[]" T1' \<Gamma> v2, OF inner] v2
  show ?case by simp
next
  case (E_App1 t1 t1' t2 \<Gamma>)
  from E_App1.prems obtain T1 where
    t1T: "\<Gamma> \<turnstile> t1 : T1 \<rightarrow> T" and t2T: "\<Gamma> \<turnstile> t2 : T1"
    by (blast elim: typing.cases)
  from E_App1.IH [OF t1T] t2T show ?case by blast
next
  case (E_App2 v1 t2 t2' \<Gamma>)
  from E_App2.prems obtain T1 where
    v1T: "\<Gamma> \<turnstile> v1 : T1 \<rightarrow> T" and t2T: "\<Gamma> \<turnstile> t2 : T1"
    by (blast elim: typing.cases)
  from E_App2.IH [OF t2T] v1T show ?case by blast
qed

subsection \<open>49.10 坑位清单（实测）\<close>

text \<open>1. de Bruijn 的方向：本教程 @{verbatim "Var 0"} = 最内层，
   环境**内层在前**；TAPL 的约定相反（外层在前），照抄会让
   nth/移位全反。
2. **嵌套数字模式 primrec 不收**（@{verbatim "Nonprimitive pattern"}）：
   @{verbatim "Var 0"} 这类分派用 case 表达式折进方程体。
3. **移位必须带 cutoff**：不带截止的"全体 +1"在进入抽象时会把
   绑定变量也抬走，weakening 引理的 Lam 情形对不上 IH。
4. 代换进壳要给 @{verbatim "s"} 抬层（@{verbatim "liftn 0 1 s"}），
   其合法性正是 weakening——两条结构引理互相咬合。
5. 进展定理的归纳里 **canonical forms 必不可少**：值 + 箭头类型
   才能拆出 @{verbatim "Lam"}。
6. 保持定理用 **eval 的归纳**（不是 typing 的）：对求值步归纳，
   typing 作为携带前提；β 情形靠反演拆 @{verbatim "Lam"}。
7. 空环境 @{verbatim "[]"} 的进展才成立；开项 @{verbatim "Var 0"}
   卡住但良型——进展的反例就在这。\<close>

thm progress preservation

ML \<open>writeln "==== 49 结束 ===="\<close>

end
