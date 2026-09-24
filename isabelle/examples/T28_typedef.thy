theory T28_typedef
  imports Main
begin

section \<open>28.1 @{verbatim "typedef"} 解决什么问题\<close>

text \<open>第 4 章的 @{verbatim "datatype"} 造**和类型**（构造器拼出来的）；
第 25 章的 @{verbatim "class"} 让已有类型加接口。还有一类常见需求：
"**我要一个只在某个 @{verbatim "set"} 里取值的类型**"。@{verbatim "typedef"}
就是这条通道：给一个 @{verbatim "set"} @{verbatim "S"}（非空即可），
生成一个和 @{verbatim "S"} 双射的**新类型** @{verbatim "T"}，
并附上 @{verbatim "Abs_T"} 与 @{verbatim "Rep_T"} 一对互逆映射。\<close>

ML \<open>writeln "==== 28 开始 ===="\<close>

subsection \<open>28.2 最小例子：@{verbatim "seven"}\<close>

text \<open>先造一个"0 到 6"的类型。@{verbatim "typedef seven = {n::nat. n < 7}"}
的**证明义务**只有一条：这个集合非空。@{verbatim "exI[of _ 0]"}
给见证 @{verbatim "0"}，@{verbatim "auto"} 关掉。\<close>

typedef seven = "{n::nat. n < 7}"
  by (auto intro!: exI[of _ 0])

term Abs_seven
term Rep_seven

subsection \<open>28.3 @{verbatim "typedef"} 送出的四件套\<close>

text \<open>新类型 @{verbatim "seven"} 只带了 @{verbatim "Abs_seven"} 与
@{verbatim "Rep_seven"} 两个函数，什么运算都没有。@{verbatim "typedef"}
自动给出的引理按@{verbatim "T"} 命名：@{verbatim "Rep_T_inverse"}
（回环）、@{verbatim "Abs_T_inverse"}（带条件的回环）、
@{verbatim "Rep_T_inject"}（抽象值相等的下沉判据）、
@{verbatim "Abs_T_inject"}（代表元在集合内时抽象相等等价于代表元相等）。
另有一条结构描述 @{verbatim "type_definition_T"}，是
@{verbatim "setup_lifting"} 需要的输入。\<close>

thm Rep_seven_inverse
thm Abs_seven_inverse
thm Rep_seven_inject
thm Abs_seven_inject
thm type_definition_seven

subsection \<open>28.4 @{verbatim "setup_lifting"}：为抽象类型装上 Transfer 桥\<close>

text \<open>@{verbatim "setup_lifting type_definition_seven"}
把 @{verbatim "Quotient"} / @{verbatim "lift_definition"} 需要的元数据登记进去。
这条是**新类型可用之前**的固定动作；不登记，下一节的
@{verbatim "lift_definition"} 会拒绝工作。\<close>

setup_lifting type_definition_seven

subsection \<open>28.5 @{verbatim "lift_definition"}：在抽象类型上定义运算\<close>

text \<open>@{verbatim "lift_definition plus_seven :: seven \<Rightarrow> seven \<Rightarrow> seven is f"}
把"底层 @{verbatim "nat"} 上的 @{verbatim "f"}"提升到 @{verbatim "seven"}
上。**关键**：@{verbatim "f"} 必须把 @{verbatim "S"} 中的元素映回
@{verbatim "S"}。这里 @{verbatim "(x + y) mod 7"} 显然满足，
但 Isabelle 要 @{verbatim "mod_less"} 才能闭合证明义务。\<close>

lift_definition plus_seven :: "seven \<Rightarrow> seven \<Rightarrow> seven" is
  "\<lambda>x y. (x + y) mod 7"
  by (simp add: mod_less)

lift_definition zero_seven :: "seven" is "0::nat" by simp

text \<open>提升之后的运算，等式证明要么用 @{verbatim "transfer"}（把 @{verbatim "seven"}
层的目标下沉到 @{verbatim "nat"}），要么用 @{verbatim "Rep_seven_inject"} 手动
下沉。@{verbatim "typedef"} 出来的抽象类型默认**没有代码方程**，
@{verbatim "value"} 不能直接算：\<close>

thm plus_seven.abs_eq
thm plus_seven.rep_eq
thm zero_seven.abs_eq

subsection \<open>28.6 @{verbatim "transfer"}：把抽象层目标下沉到底层\<close>

text \<open>@{verbatim "transfer"} 依赖 @{verbatim "setup_lifting"} 登记的
@{verbatim "Quotient"} 结构。下面这条 @{verbatim "plus_seven_zero"}
在抽象层看起来要绕一圈，@{verbatim "transfer"} 一步就把目标换成
@{verbatim "nat"} 上的 @{verbatim "(0 + x) mod 7 = x"}：\<close>

lemma plus_seven_zero [simp]: "plus_seven zero_seven x = x"
  apply transfer
  by (simp add: mod_less)

subsection \<open>28.7 @{verbatim "typedef"} 与 @{verbatim "datatype"} 的分工\<close>

text \<open>选 @{verbatim "datatype"} 还是 @{verbatim "typedef"}，看的是**"是不是子集"**：

  - 需要**多个构造器**（@{verbatim "Left"}、@{verbatim "Right"}）：@{verbatim "datatype"}；
  - 需要**递归结构**（列表、树）：@{verbatim "datatype"}；
  - **就是一个子集**（@{verbatim "seven"}、@{verbatim "invertible matrix"}）：
    @{verbatim "typedef"}；
  - 需要**按等价类**（下一教程 @{verbatim "quotient_type"}）：那是
    @{verbatim "typedef"} 的对偶——把"哪些代表元等价"作为参数。

@{verbatim "typedef"} 的新类型默认**没有代码生成**支持，@{verbatim "value"}
不能直接算；要跑数得手动补 @{verbatim "code_datatype"} 或走 @{verbatim "transfer"}。\<close>

subsection \<open>28.8 常见坑：@{verbatim "typedef"} 证明义务\<close>

text \<open>@{verbatim "typedef"} 唯一义务是"非空"。下面这个 @{verbatim "empty_set"}
就构造不出来：\<close>

lemma "\<not> (\<exists>x. x \<in> ({} :: nat set))" by simp

text \<open>如果 @{verbatim "typedef"} 的 @{verbatim "set"} 复杂，@{verbatim "auto"}
不够，得手工 @{verbatim "exI[of _ w]"} 给见证、再证属性。\<close>

subsection \<open>28.9 用 @{verbatim "typedef"} 造的新类型参与类型类\<close>

text \<open>@{verbatim "typedef"} 生成的类型可以立刻给 @{verbatim "instantiation"}
（第 25 章）当参数：下面把 @{verbatim "seven"} 装进 @{verbatim "plus0"}
这个自足的最小类。@{verbatim "plus0"} 自带常量 @{verbatim "zero0"}，
不去依赖 HOL 的 @{verbatim "zero"} 类，这样 @{verbatim "seven"} 不需要预先
建立数值结构。\<close>

class plus0 =
  fixes add0 :: "'a \<Rightarrow> 'a \<Rightarrow> 'a"  (infixl "\<oplus>\<^sub>0" 65)
  fixes zero0 :: 'a
  assumes add0_zero0 [simp]: "add0 zero0 x = x"

instantiation seven :: plus0
begin

definition add0_seven :: "seven \<Rightarrow> seven \<Rightarrow> seven" where
  "add0_seven = plus_seven"

definition zero0_seven :: "seven" where
  "zero0_seven = zero_seven"

instance proof
  fix x :: seven
  show "add0 zero0 x = x"
    unfolding add0_seven_def zero0_seven_def
    by (simp add: plus_seven_zero)
qed

end

text \<open>实例化完成后，@{verbatim "\<oplus>\<^sub>0"} 与 @{verbatim "zero0"}
在 @{verbatim "seven"} 上就用我们上面提升的定义。用抽象等式验证一下：\<close>

lemma "zero0 \<oplus>\<^sub>0 (Abs_seven 5) = (Abs_seven 5 :: seven)"
  unfolding add0_seven_def zero0_seven_def
  by (simp add: plus_seven_zero)

ML \<open>writeln "==== 28 结束 ===="\<close>

end
