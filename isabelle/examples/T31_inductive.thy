theory T31_inductive
  imports Main
begin

section \<open>31.1 闭包：fun 写不了的"函数"\<close>

text \<open>第 5 章的 @{verbatim "fun"} 能定义所有**计算**型递归（要求终止），
第 15 章把终止性放宽到任意良基关系。但很多数学对象根本不是函数，而是
**关系**：求值关系、可达关系、类型规则……它们的定义是"满足这些规则的
**最小**关系"，用 @{verbatim "inductive"} 声明。isar-ref 手册把它列为
结构化规格命令族的第二支柱（第一支柱是第 4 章的 @{verbatim "datatype"}）。

@{verbatim "inductive"} 的三件赠品（都在定义后立刻可用）：

  1. @{verbatim "R.intros"} —— 引入规则（"怎样构造出一个 R 事实"）；
  2. @{verbatim "R.cases"} —— 消去规则（"拿到一个 R 事实能推出什么"）；
  3. @{verbatim "R.induct"} —— 归纳原理（"要证 R 蕴含 P，对每条规则各证一步"）。

最小性是定义的一部分：只把**必然属于**的元素放进去，不多放。\<close>

ML \<open>writeln "==== 31 开始 ===="\<close>

subsection \<open>31.2 第一个归纳定义：偶数\<close>

text \<open>不用 @{verbatim "2 dvd n"}，直接把"偶数"定义成归纳谓词：
起点 0，一步加二。@{verbatim "ev"} 是谓词（返回 bool），不是函数。\<close>

inductive ev :: "nat \<Rightarrow> bool" where
  ev0 [intro!]: "ev 0"
| evSS [intro!]: "ev n \<Longrightarrow> ev (Suc (Suc n))"

thm ev.intros
thm ev.cases
thm ev.induct

text \<open>@{verbatim "[intro!]"} 把规则塞进 @{verbatim "auto"} 的引入武器库：
@{verbatim "auto"} 现在会主动用它们拼出 ev 事实。\<close>

lemma "ev (Suc (Suc (Suc (Suc 0))))"
  by auto

subsection \<open>31.3 规则归纳：inductive 的配套推理\<close>

text \<open>对"凡是 ev 的都……"型命题，用 @{verbatim "ev.induct"}。
目标写成 @{verbatim "ev n <Longrightarrow> P n"}，归纳时每条规则给一个归纳假设：\<close>

lemma ev_imp_dvd: "ev n \<Longrightarrow> 2 dvd n"
  by (induct rule: ev.induct) auto

text \<open>双 Suc 规则的归纳假设是关于 @{verbatim "n"} 的——但前提 @{verbatim "ev n"}
里没有别的变量，所以 @{verbatim "arbitrary:"} 在这里用不上。需要泛化的场景
在 31.5 的传递闭包。\<close>

corollary ev_double: "ev n \<Longrightarrow> ev (n + n)"
  by (induct rule: ev.induct) auto

subsection \<open>31.4 消去：cases 的用法与局限\<close>

text \<open>@{verbatim "ev.cases"} 只能告诉你"这个 ev 事实是两条规则之一造出来的"，
它**做完整 case 分析**：对 @{verbatim "ev (Suc 0)"} 直接给出矛盾分支。\<close>

lemma "ev (Suc 0) \<Longrightarrow> False"
  by (auto elim: ev.cases)

text \<open>注意区别：@{verbatim "cases"} 是无信息拆分（拿到事实拆两条路），
@{verbatim "induct"} 是有假设拆分（每条路送一个归纳假设）。证明策略里
"先 cases 探路，发现要递归假设再换 induct"是常见节奏。\<close>

subsection \<open>31.5 inductive_set 与传递闭包\<close>

text \<open>关系上的**自反传递闭包** @{verbatim "star"} 是教科书级例子：
从 @{verbatim "r"} 出发，允许走零步或任意多步。注意 @{verbatim "inductive_set"}
版本操作集合的 @{verbatim "(x, y) <in> S"}，谓词版本操作 @{verbatim "'a <Rightarrow> 'a \<Rightarrow> bool"}——
后者在证明里更顺手，这里用谓词版。\<close>

inductive star :: "('a \<Rightarrow> 'a \<Rightarrow> bool) \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> bool" for r where
  refl [intro!]: "star r x x"
| step [intro]: "star r x y \<Longrightarrow> r y z \<Longrightarrow> star r x z"

lemma star_trans: "star r y z \<Longrightarrow> star r x y \<Longrightarrow> star r x z"
  by (induct rule: star.induct) auto

text \<open>为什么前提要按"先给 y\<rightarrow>z 那条链"摆？归纳沿**第一条**匹配的
链式前提走（@{verbatim "star r y z"}），@{verbatim "x"} 是旁观者不动。
反过来沿 @{verbatim "star r x y"} 归纳的话，step 情形要用"目标本身"
去接递归——循环论证。这里还埋着本章最大的实测坑：@{verbatim "step"}
规则**不能挂 @{verbatim "[intro!]"}**——叹号表示"可无前提地反向使用"，
而证 @{verbatim "star r x z"} 时任何 @{verbatim "y"} 都能造一步
@{verbatim "step"}，目标向后**无限分叉**；实测定义阶段的化简规则
证明就挂死（构建日志停在 @{verbatim "Proving the simplification rules"}
超过 750 秒）。规则挂 @{verbatim "[intro]"}（条件引入），@{verbatim "auto"}
依然可用但只在需要时展开。另外 @{verbatim "star_append_one"} 就是
step 规则本身，不用重证：\<close>

lemma star_append_one: "star r x y \<Longrightarrow> r y z \<Longrightarrow> star r x z"
  by (rule star.step)

subsection \<open>31.6 组合已有谓词与单调性检查\<close>

text \<open>定义体里如果**调用**别的谓词（而不是纯构造），Isabelle 要先确认
被调用者**单调**，最小不动点才存在。好消息：@{verbatim "inductive"} 定义出的
谓词自动单调，直接组合不用额外声明；普通函数（比如 @{verbatim "Not"} 出现在
负位置）就不行——报错形如 @{verbatim "Monotonicity check failed"}，
解法是手工证明单调性引理后用 @{verbatim "mono"} 命令注册（本教程用不上，
知道这个门牌即可）。下面定义"ev 且非零"，体里直接调用 @{verbatim "ev"}：\<close>

inductive ev_pos :: "nat \<Rightarrow> bool" where
  [intro!]: "ev n \<Longrightarrow> n \<noteq> 0 \<Longrightarrow> ev_pos n"

lemma "ev_pos (Suc (Suc 0))"
  by auto

subsection \<open>31.7 与 datatype 的对称性\<close>

text \<open>把三条对称线记牢（第 26 章讲过 datatype/codatatype 的另一半）：

  - @{verbatim "datatype"} 最小不动点在**类型**上；
    @{verbatim "inductive"} 最小不动点在**谓词/集合**上；
  - @{verbatim "primrec"} 对 datatype 结构递归；
    @{verbatim "induct"}/规则归纳对 inductive 结构归纳；
  - 两者共享同一套不动点理论（第 51 章在 @{verbatim "complete_lattice"}
    上从零证明 Knaster--Tarski）。

内部实现（implementation 手册）里，@{verbatim "inductive"} 生成的引入规则
本质上就是不动点算子 @{verbatim "lfp"} 的逐层展开。\<close>

thm star.induct

ML \<open>writeln "==== 31 结束 ===="\<close>

end
