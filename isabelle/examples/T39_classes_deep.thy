theory T39_classes_deep
  imports Main
begin

section \<open>39.1 第 25 章之后：overloading、subclass 证明与实例工程\<close>

text \<open>第 25 章走通了 @{verbatim "class"} → @{verbatim "instantiation"}
→ @{verbatim "instance"} 的直线。classes 手册（classes.pdf）的后半
讲三件工程事：**overloading 块**（同名常量在多个类型上各自定义）、
@{verbatim "subclass"}（类包含关系的**证明**）、以及把 locale 的
假设批量搬进 class 的翻译通道。第 30 章在 @{verbatim "linorder"} 上
做过一次，这里补全另外两条。\<close>

ML \<open>writeln "==== 39 开始 ===="\<close>

subsection \<open>39.2 overloading：同名不同型的手工重载\<close>

text \<open>@{verbatim "overloading"} 块声明"这个常量名在定义处就要
按类型分身"。与 class 的区别：class 要求**所有**实例共享一条公理，
overloading 只共享**名字**。教科书用途：为 debug 输出、默认值等
"每个类型自己说了算"的常量：\<close>

consts shrink :: "'a \<Rightarrow> 'a list"    (* 只有名字，没有定义 *)

overloading
  shrink_nat \<equiv> "shrink :: nat \<Rightarrow> nat list"
  shrink_bool \<equiv> "shrink :: bool \<Rightarrow> bool list"
begin

definition shrink_nat :: "nat \<Rightarrow> nat list" where "shrink_nat n = [n div 2]"
definition shrink_bool :: "bool \<Rightarrow> bool list" where "shrink_bool b = [False]"

end

value "shrink_nat 7"
value "shrink_bool True"

text \<open>注意 @{verbatim "value \"shrink (7::nat)\""} 会报
@{verbatim "No code equations for shrink"}——重载常量的 code 方程
不跟着别名走（实测），求值用别名 @{verbatim "shrink_nat"} 直连。\<close>

text \<open>@{verbatim "consts"} 只登记名字；两个分身的定义各自带
@{verbatim "_def"}（@{verbatim "shrink_nat_def"}）。注意这不是类：
没有公理，也没有 @{verbatim "instance"} 义务。\<close>

thm shrink_nat_def

subsection \<open>39.3 一个带证明义务的完整实例\<close>

text \<open>第 25/30 章的 @{verbatim "instantiation"} 里义务用
@{verbatim "standard"}+自动化清空。这里补一个**非空义务**的完整版：
给 @{verbatim "typedef"} 出来的小类型装 @{verbatim "equal"} 类
（@{verbatim "HOL.equal"}，驱动 @{verbatim "= " }的 code 生成与
@{verbatim "deriving"} 设施）。义务是自反：\<close>

typedef two = "{0, 1::nat}" by auto

instantiation two :: equal
begin

definition eq_two: "HOL.equal a b \<longleftrightarrow> Rep_two a = Rep_two b"

instance
  by standard (simp add: eq_two Rep_two_inject)

end

lemma two_eq_refl: "HOL.equal (Abs_two 0) (Abs_two 0) = True"
  by (simp add: eq_two)

text \<open>同类强化用**继承**（locale 式 @{verbatim "="}）表达，
比 @{verbatim "subclass"} 直白；@{verbatim "subclass"} 的真正用途是
把**内置类层次**上的包含证出来（如证新类型落在
@{verbatim "ab_semigroup_add"} 下，白拿 @{verbatim "Groups"} 树的引理），
义务多时先证辅助引理或上 @{verbatim "lifting"}（第 28 章）。
写不成立的包含硬 @{verbatim "sorry"}——构建必拒，别试。\<close>

subsection \<open>39.4 实例的两种口味：instantiation 与 instance\<close>

text \<open>第 25 章的 @{verbatim "instantiation"} 块负责"定义+证明"
一条龙；@{verbatim "instance .."} 声明"义务为空/已被前提覆盖"。
清单：

  - @{verbatim "instantiation t :: (classes) class"} + @{verbatim "begin"}：
    定义分身、证公理、@{verbatim "instance"} 收尾；
  - @{verbatim "instance t :: class .."}：无定义、义务可空的声明；
  - @{verbatim "instance t :: class"} + 证明：义务非空的裸形态。

坑：@{verbatim "instantiation"} 块里忘了 @{verbatim "instance"}，
报 @{verbatim "Unfinished instantiation"}（实测高频）。\<close>

subsection \<open>39.5 sort 约束阅读法\<close>

text \<open>类型类最阴的报错来自 sort：
@{verbatim "'a itself <Rightarrow> ..."} 里突然冒出
@{verbatim "{equal,ord}"} 之类的约束（第 35 章 @{verbatim "value"}
的 not of sort 系列）。读法：sort 是**类型的集合**，
@{verbatim "'a::{plus,zero}"} = "'a 同时是 plus 和 zero 的实例"。
用 @{verbatim "typ 'a"}（带 @{verbatim "show_sorts"}）看约束从哪来。\<close>

declare [[show_sorts = false]]

subsection \<open>39.6 坑位清单（实测）\<close>

text \<open>1. @{verbatim "consts"} + @{verbatim "overloading"} 的定义名
   要手动起（@{verbatim "shrink_nat"}），不然重载块里没抓手。
2. @{verbatim "subclass"} 义务证不动时，先问"包含关系真的成立吗"——
   不成立的包含硬写必然 sorry。
3. @{verbatim "instantiation"} 块忘 @{verbatim "instance"} 收尾：
   @{verbatim "Unfinished instantiation"}。
4. @{verbatim "typedef"} 之后立刻 @{verbatim "instance"}：Rep/Abs 的
   性质没被 simp 拿到，要显式 @{verbatim "Abs_two_inverse"} /
   @{verbatim "Rep_two_inject"} 一族。
5. @{verbatim "sorry"} 在构建必死（@{verbatim "quick_and_dirty"}
   关着时直接报错）——写不下去的义务说明包含关系或定义本身有问题，
   回头改设计而不是硬 sorry。
6. sort 约束报错的根源在**约束最小的类型变量**：给数字字面量补
   类型标注（第 3 章老坑）解决大半。
7. @{verbatim "instantiation"} 的箭头语法（@{verbatim "t :: (c1, c2) c3"}）
   括号里是**类型构造器的参数约束**，不是该类型自己的约束——
   参数约束写错位置类型检查直接爆。\<close>

value "shrink_nat 7"
thm shrink_nat_def

ML \<open>writeln "==== 39 结束 ===="\<close>

end
