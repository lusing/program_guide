theory T18_hoare
  imports Main
begin

section \<open>18.1 给一门小语言写证明器\<close>

text \<open>本章是全书的大案例：定义一门命令式小语言 IMP，
给出大步操作语义，再定义 Hoare 三元组的"有效性"，
最后证明几条 Hoare 规则。整个流程就是把第 4、5、6、14 章
串起来。\<close>

ML \<open>writeln "==== 18 开始 ===="\<close>

subsection \<open>18.2 语法：算术表达式与布尔表达式\<close>

type_synonym vname = string
type_synonym val = int
type_synonym state = "vname \<Rightarrow> val"

datatype aexp = N int | V vname | Plus aexp aexp

fun aval :: "aexp \<Rightarrow> state \<Rightarrow> val" where
  "aval (N n) s = n"
| "aval (V x) s = s x"
| "aval (Plus a1 a2) s = aval a1 s + aval a2 s"

datatype bexp = Bc bool | Not bexp | And bexp bexp | Less aexp aexp

fun bval :: "bexp \<Rightarrow> state \<Rightarrow> bool" where
  "bval (Bc v) s = v"
| "bval (Not b) s = (\<not> bval b s)"
| "bval (And b1 b2) s = (bval b1 s \<and> bval b2 s)"
| "bval (Less a1 a2) s = (aval a1 s < aval a2 s)"

value "aval (Plus (V ''x'') (N 5)) (\<lambda>x. (0::int))"
value "bval (Less (V ''x'') (N 5)) (\<lambda>x. (0::int))"

subsection \<open>18.3 命令与具体语法\<close>

datatype com =
  SKIP
| Assign vname aexp       ("_ ::= _" [1000, 61] 61)
| Seq com com             ("_;;/ _"  [60, 61] 60)
| If bexp com com         ("(IF _/ THEN _/ ELSE _)"  [0, 0, 61] 61)
| While bexp com          ("(WHILE _/ DO _)"  [0, 61] 61)

subsection \<open>18.4 大步语义：归纳定义的执行关系\<close>

inductive big_step :: "com \<times> state \<Rightarrow> state \<Rightarrow> bool"  (infix "\<Down>" 55)
where
  SkipS: "(SKIP, s) \<Down> s"
| AssignS: "(x ::= a, s) \<Down> s(x := aval a s)"
| SeqS: "\<lbrakk> (c\<^sub>1, s\<^sub>1) \<Down> s\<^sub>2; (c\<^sub>2, s\<^sub>2) \<Down> s\<^sub>3 \<rbrakk> \<Longrightarrow> (c\<^sub>1;; c\<^sub>2, s\<^sub>1) \<Down> s\<^sub>3"
| IfTrueS: "\<lbrakk> bval b s; (c\<^sub>1, s) \<Down> t \<rbrakk> \<Longrightarrow> (IF b THEN c\<^sub>1 ELSE c\<^sub>2, s) \<Down> t"
| IfFalseS: "\<lbrakk> \<not> bval b s; (c\<^sub>2, s) \<Down> t \<rbrakk> \<Longrightarrow> (IF b THEN c\<^sub>1 ELSE c\<^sub>2, s) \<Down> t"
| WhileFalseS: "\<not> bval b s \<Longrightarrow> (WHILE b DO c, s) \<Down> s"
| WhileTrueS: "\<lbrakk> bval b s; (c, s) \<Down> t; (WHILE b DO c, t) \<Down> u \<rbrakk>
              \<Longrightarrow> (WHILE b DO c, s) \<Down> u"

text \<open>注意上面这些规则的名字：它们被刻意命名为
@{verbatim "SkipS"} @{verbatim "AssignS"} @{verbatim "SeqS"} 而不是
@{verbatim "Skip"} @{verbatim "Assign"} @{verbatim "Seq"}——
后三个名字会和 @{verbatim "com"} 的构造器撞车，之后再想写
@{verbatim "Seq c1 c2"} 就会出现"解析失败"的怪错。
给归纳规则起名字时，一律加前缀。

一个反复出现的定理：SKIP 的执行没有副作用。
它的证明靠 @{verbatim "big_step.cases"} 做反演——
"能推出这个结果的规则只有那一条"。\<close>

lemma skip_deterministic: "(SKIP, s) \<Down> t \<Longrightarrow> t = s"
  by (erule big_step.cases) simp_all

subsection \<open>18.5 Hoare 三元组的有效性\<close>

type_synonym assn = "state \<Rightarrow> bool"

definition hoare_valid :: "assn \<Rightarrow> com \<Rightarrow> assn \<Rightarrow> bool" where
  "hoare_valid P c Q = (\<forall>s t. P s \<longrightarrow> (c, s) \<Down> t \<longrightarrow> Q t)"

lemma hoare_Skip: "hoare_valid P SKIP P"
  by (auto simp: hoare_valid_def elim: big_step.cases)

lemma hoare_Assign: "hoare_valid (\<lambda>s. P (s(x := aval a s))) (x ::= a) P"
  by (auto simp: hoare_valid_def elim: big_step.cases)

subsection \<open>18.6 顺序、条件与循环\<close>

lemma hoare_Seq: "hoare_valid P c\<^sub>1 Q \<Longrightarrow> hoare_valid Q c\<^sub>2 R \<Longrightarrow>
                  hoare_valid P (c\<^sub>1;; c\<^sub>2) R"
  apply (simp add: hoare_valid_def)
  apply (intro allI impI)
  apply (erule big_step.cases)
    apply simp_all
  by blast

text \<open>条件规则的关键是 @{verbatim "erule big_step.cases"}：它拿前提里的
@{verbatim "(IF b THEN c\<^sub>1 ELSE c\<^sub>2, s) \<Down> t"} 去和 7 条规则的结论做
合一，只有 @{verbatim "IfTrueS"} 与 @{verbatim "IfFalseS"} 两条的形状
对得上，其余 5 条在合一阶段就被丢掉了——所以这里不会冒出
"SKIP 分支怎么办"这种目标。这也是 @{verbatim "erule R.cases"} 与
@{verbatim "induction rule: R.induct"} 最大的区别：前者只看能匹配上
的那几条，后者 7 条全都要证。\<close>

lemma hoare_If: "hoare_valid (\<lambda>s. P s \<and> bval b s) c\<^sub>1 Q \<Longrightarrow>
                 hoare_valid (\<lambda>s. P s \<and> \<not> bval b s) c\<^sub>2 Q \<Longrightarrow>
                 hoare_valid P (IF b THEN c\<^sub>1 ELSE c\<^sub>2) Q"
  apply (simp add: hoare_valid_def)
  apply (intro allI impI)
  apply (erule big_step.cases)
      apply simp_all
  done

subsection \<open>18.7 循环：唯一真正难的一条\<close>

text \<open>循环规则是本章唯一真正难的一条。@{verbatim "big_step"} 有 7 条规则，
如果直接对 @{verbatim "(WHILE b DO c, s) \<Down> t"} 做归纳，归纳谓词
@{verbatim "?P"} 会被 WHILE 那个形状钉死，于是 @{verbatim "SkipS"}、
@{verbatim "SeqS"} 这些分支的目标会变成"任意 SKIP 也满足循环不变式"
这种假命题，谁也证不出来。

正确写法是：把结论放宽成"任意一条推导 @{verbatim "cs \<Down> u"}，
如果它的起点 @{verbatim "cs"} 恰好形如某个 WHILE，那么只要循环体
保持 @{verbatim "P"}，就有 @{verbatim "P u \<and> \<not> bval b u"}。
这样 @{verbatim "?P"} 是"对任意命令"的谓词，7 条规则全都进得来，
不相干的 5 条靠构造器的区分性（SKIP 永远不等于 WHILE）被
@{verbatim "simp"} 直接消掉。\<close>

lemma while_aux:
  "cs \<Down> u \<Longrightarrow>
   (\<forall>b c s\<^sub>0. cs = (WHILE b DO c, s\<^sub>0) \<longrightarrow>
      (\<forall>s t. P s \<and> bval b s \<longrightarrow> (c, s) \<Down> t \<longrightarrow> P t) \<longrightarrow>
      P s\<^sub>0 \<longrightarrow> P u \<and> \<not> bval b u)"
proof (induction rule: big_step.induct)
  case SkipS
  then show ?case by simp
next
  case AssignS
  then show ?case by simp
next
  case SeqS
  then show ?case by simp
next
  case IfTrueS
  then show ?case by simp
next
  case IfFalseS
  then show ?case by simp
next
  case WhileFalseS
  then show ?case by simp
next
  case (WhileTrueS b c s t u)
  then show ?case by auto
qed

lemma hoare_While: "hoare_valid (\<lambda>s. P s \<and> bval b s) c P \<Longrightarrow>
                    hoare_valid P (WHILE b DO c) (\<lambda>s. P s \<and> \<not> bval b s)"
proof (unfold hoare_valid_def, intro allI impI)
  fix s t
  assume ih: "\<forall>s t. P s \<and> bval b s \<longrightarrow> (c, s) \<Down> t \<longrightarrow> P t"
  assume Ps: "P s"
  assume exec: "(WHILE b DO c, s) \<Down> t"
  from while_aux[OF exec] ih Ps show "P t \<and> \<not> bval b t" by blast
qed

text \<open>下面这个程序把 0..2 累加进 x。它被拆成两个片段再用
@{verbatim ";;"} 拼起来，纯粹为了可读：一长串"赋值接循环"写在一起，
出错时很难定位是哪一段。

更值得注意的是这段程序的名字为什么叫 @{verbatim "SUM_PROG"}。
Isabelle 的词法层认得一批全大写缩写，它们在源文件里被整词替换成
对应的符号：@{verbatim "ALL"} 变成全称量词，@{verbatim "EX"} 变成
存在量词，@{verbatim "SUM"} 变成求和号，@{verbatim "PROD"} 变成求积号，
@{verbatim "INT"} 与 @{verbatim "UN"} 变成交并，@{verbatim "INF"} 与
@{verbatim "SUP"} 变成上下确界。

于是给常量起名字时，@{verbatim "SUM"} 是不能用的：词法器会先把它读成
求和号（一个需要参数的 binder 语法常量），等号就成了多余的 token，
报的错是看不出所以然的 @{verbatim "Failed to parse prop"}，
位置指向 RHS 而不是那个名字。替换只认整词，所以
@{verbatim "SUM_PROG"}、@{verbatim "SUM2"} 都安全。\<close>

subsection \<open>18.8 常量名与词法缩写\<close>

definition INIT :: com where
  "INIT = ((''x'' ::= N 0);; (''y'' ::= N 0))"

definition LOOP :: com where
  "LOOP = (WHILE (Less (V ''y'') (N 3)) DO ((''x'' ::= Plus (V ''x'') (V ''y''));; (''y'' ::= Plus (V ''y'') (N 1))))"

definition SUM_PROG :: com where
  "SUM_PROG = (INIT;; LOOP)"

value "aval (Plus (V ''x'') (V ''y'')) ((\<lambda>x. (0::int))(''x'' := 1, ''y'' := 2))"

text \<open>用规则证程序时，顺序规则的中间断言 @{verbatim "Q"} 必须自己给：
直接 @{verbatim "apply (rule hoare_Seq)"} 会把它留成待定的元变量，
接下来 @{verbatim "auto"} 会替你"猜"一个，猜出来的东西通常不是你想要的，
最后卡在一个看起来莫名其妙的目标上。用 @{verbatim "where Q = ..."}
显式指定。

另一个容易踩的点：@{verbatim "apply (auto ...)"} 里的 @{verbatim "auto"}
是"作用于全部目标"的方法，它会一口气把剩下的子目标都收掉。所以
脚本里再写第二个 @{verbatim "apply (auto ...)"} 时，常见报错是
@{verbatim "goal: No subgoals!"}——不是证明错了，是目标已经被前面
那一步解决了。\<close>

subsection \<open>18.9 用规则证程序\<close>

lemma sum_example: "hoare_valid (\<lambda>s. True) ((''x'' ::= N 0);; (''y'' ::= N 0))
                    (\<lambda>s. s ''x'' = 0 \<and> s ''y'' = 0)"
  apply (rule hoare_Seq[where Q = "\<lambda>s. s ''x'' = 0"])
   apply (auto simp: hoare_valid_def elim: big_step.cases)
  done

text \<open>循环规则只能给出"不变式成立且条件为假"这个后条件，
想把它改成更好看的形式（比如 @{verbatim "s ''y'' \<ge> 3"}），
需要一条"加强前件／减弱后件"的结论规则。\<close>

lemma hoare_conseq: "hoare_valid P c Q \<Longrightarrow> (\<forall>s. P' s \<longrightarrow> P s) \<Longrightarrow>
                     (\<forall>s. Q s \<longrightarrow> Q' s) \<Longrightarrow> hoare_valid P' c Q'"
  by (auto simp: hoare_valid_def)

lemma loop_example: "hoare_valid (\<lambda>s. True)
                      (WHILE (Less (V ''y'') (N 3)) DO (''y'' ::= N 3))
                      (\<lambda>s. s ''y'' \<ge> 3)"
  apply (rule hoare_conseq)
    apply (rule hoare_While[where P = "\<lambda>s. True"])
    apply (auto simp: hoare_valid_def elim: big_step.cases)
  done

ML \<open>writeln "==== 18 结束 ===="\<close>

end
