theory T25_classes
  imports Main
begin

section \<open>25.1 类型类解决什么问题\<close>

text \<open>@{verbatim "locale"} 是"打包假设"，一次一处；**类型类（@{verbatim "class"}）**
则是"按类型分派"——写 @{verbatim "x + y"} 时，@{verbatim "+"} 到底是 nat 的加、
int 的加还是 list 的 append，靠 @{verbatim "x"} 的类型自动选。它的两条基本
纪律：

  1. 一个类型对一个类**至多一个实例**（区别于 locale 的多实例）；
  2. 类里的常量在语法层是"重载"的，一旦 @{verbatim "instantiation"} 完成，
     普通记号（@{verbatim "x \<bullet> y"}）就直接用。

这带来便利，也带来坑：类型推不出来时报的错是"sort constraint"，
不是"没定义"。\<close>

ML \<open>writeln "==== 25 开始 ===="\<close>

subsection \<open>25.2 定义一个最小的半群类\<close>

text \<open>下面定义 @{verbatim "mg"}（mini-group）：只有一个二元运算 @{verbatim "inf2"}
（刻意与 HOL 内置 @{verbatim "inf"} 区分），要求结合律。@{verbatim "class"}
@{verbatim "fixes"} 部分把常量声明为**类参数**，@{verbatim "assumes"} 声明它必须满足的律。\<close>

class mg =
  fixes inf2 :: "'a \<Rightarrow> 'a \<Rightarrow> 'a"  (infixl "\<bullet>" 70)
  assumes inf2_assoc: "(x \<bullet> y) \<bullet> z = x \<bullet> (y \<bullet> z)"

text \<open>@{verbatim "class"} 命令自动生成三样东西：@{verbatim "mg"} 类型约束、
@{verbatim "inf2"} 投影函数、@{verbatim "mg.inf2_assoc"} 泛化引理。
下面直接把类公理与类参数常量打印出来，这是查"类到底要求几条律"的最快手段：\<close>

thm mg.inf2_assoc
term inf2

subsection \<open>25.3 把 nat 装进去：@{verbatim "instantiation"}\<close>

text \<open>实例化写起来像一个"临时理论"：@{verbatim "instantiation nat :: mg begin ... end"}
里给运算一个具体定义，再补一次证明义务（@{verbatim "instance"} 后面接
@{verbatim "proof"}/@{verbatim "qed"}）。这里的 @{verbatim "inf2_nat"} 用自然数加法；
证明里用 @{verbatim "add.assoc"} 一步搞定。\<close>

instantiation nat :: mg
begin

definition inf2_nat :: "nat \<Rightarrow> nat \<Rightarrow> nat" where
  "inf2_nat m n = m + n"

instance
  by intro_classes (simp add: inf2_nat_def add.assoc)

end

text \<open>实例建立后，@{verbatim "\<bullet>"} 记号在 nat 上就是 @{verbatim "inf2_nat"}：\<close>

value "(3 :: nat) \<bullet> 4"

subsection \<open>25.4 再来一个实例：list 的连接\<close>

text \<open>下面把 @{verbatim "\<bullet>"} 在 list 上实例化为 append。这里刻意演示**同一个类
在多个类型上的并存**：@{verbatim "3 \<bullet> 4"} 与 @{verbatim "[1,2] \<bullet> [3]"} 共享记号，
但底层常量完全不同。\<close>

instantiation list :: (type) mg
begin

definition inf2_list :: "'a list \<Rightarrow> 'a list \<Rightarrow> 'a list" where
  "inf2_list xs ys = xs @ ys"

instance
  by intro_classes (simp add: inf2_list_def append_assoc[symmetric])

end

value "([1,2] :: nat list) \<bullet> [3]"

subsection \<open>25.5 类里的引理：靠类型约束触发\<close>

text \<open>在 @{verbatim "context mg"} 里写引理，类型变量 @{verbatim "'a"} 自动带上
@{verbatim ":: mg"} 的约束。离开 @{verbatim "context"} 后，引理名字带
@{verbatim "mg."} 前缀，靠类型约束把假设自动装回去。\<close>

context mg
begin

lemma inf2_four: "((a \<bullet> b) \<bullet> c) \<bullet> d = a \<bullet> (b \<bullet> (c \<bullet> d))"
  by (simp add: inf2_assoc)

end

thm mg.inf2_four

text \<open>把这条引理**具体化**到 nat 上，得写成限定名。这里的 simp 会展开
@{verbatim "inf2_nat_def"} 到加法，再用 @{verbatim "mg.inf2_four"}（自动带上
@{verbatim "mg"} 类型约束的 nat 实例）证明两边一致。\<close>

lemma nat_four: "((1 :: nat) \<bullet> 2) \<bullet> 3 \<bullet> 4 = 1 \<bullet> (2 \<bullet> (3 \<bullet> (4 :: nat)))"
  unfolding mg.inf2_four [of "(1::nat)" 2 3 4] by (simp add: inf2_nat_def)

subsection \<open>25.6 子类：@{verbatim "class ... = father + ..."}\<close>

text \<open>类型类也可以继承。@{verbatim "mg_idem = mg + ..."} 表示"在 mg 之上再加一条
幂等律"。这里给 bool 用 @{verbatim "\<and>"} 建立实例并证明幂等，
nat 那个实例（用 @{verbatim "+"}）自动被排除——这就是"至多一实例"带来的筛选。\<close>

class mg_idem = mg +
  assumes inf2_idem: "x \<bullet> x = x"

instantiation bool :: mg
begin

definition inf2_bool :: "bool \<Rightarrow> bool \<Rightarrow> bool" where
  "inf2_bool p q = (p \<and> q)"

instance
  by intro_classes (simp add: inf2_bool_def)

end

instantiation bool :: mg_idem
begin

instance
  by intro_classes (simp add: inf2_bool_def)

end

value "(True :: bool) \<bullet> True"
thm inf2_bool_def

subsection \<open>25.7 与 locale 的分工（复述 + 一条对比）\<close>

text \<open>20 章给了分工表。从**类**的视角补一条容易混的点：
@{verbatim "class"} 的常量在语法层是**隐式限定**的，同一个短名 @{verbatim "x \<bullet> y"}
在 nat 上就是 @{verbatim "inf2_nat"}、在 bool 上就是 @{verbatim "inf2_bool"}；而
@{verbatim "locale"} 里 @{verbatim "mult"} 只有一份，不同实例要靠
@{verbatim "interpretation name: locale ..."} 起别名，再引用
@{verbatim "name.assoc"}。\<close>

subsection \<open>25.8 常见坑：sort constraint 未满足\<close>

text \<open>如果一个类型没被实例化，写 @{verbatim "x \<bullet> y"} 时报的是 sort 不匹配、
**不是**"未定义"。下面 @{verbatim "term"} 只打印项，把类型约束显式化：
@{verbatim "'a::mg"}。\<close>

term "(\<lambda>x y :: 'a :: mg. x \<bullet> y)"

text \<open>看到 @{verbatim "'a::mg"} 就说明 @{verbatim "mg"} 类型约束**必须**由使用点
提供实例；否则报的是 @{verbatim "Type 'a not of sort mg"}。\<close>

ML \<open>writeln "==== 25 结束 ===="\<close>

end
