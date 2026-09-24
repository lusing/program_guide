theory T20_locales
  imports Main
begin

section \<open>20.1 locale 要解决的问题\<close>

text \<open>写"任给一个满足某某性质的结构，则……"这类数学时，最笨的写法是
把一串 @{verbatim "assumes"} 塞进每个 @{verbatim "lemma"}。一旦写了十几个引理，
假设列表就变成难以维护的复制粘贴。

locale 把"一组固定的参数 + 一组关于它们的假设"打包成一个可复用的上下文：
在里面证明的定理带上"局部性"，离开时自动泛化成带@{verbatim "\<lbrakk>\<rbrakk>"}的定理，
并可以被具体结构实例化。\<close>

ML \<open>writeln "==== 20 开始 ===="\<close>

subsection \<open>20.2 定义第一个 locale\<close>

text \<open>@{verbatim "fixes"} 声明参数（可以有具体语法），@{verbatim "assumes"} 声明
性质。 @{verbatim "assumes"} 里出现的自由变量一律被自动全称量化，
所以 @{verbatim "assoc"} 看起来是"关于三个变量的乘法结合律"。\<close>

locale semigroup =
  fixes mult :: "'a \<Rightarrow> 'a \<Rightarrow> 'a"   (infixl "\<cdot>" 70)
  assumes assoc: "(x \<cdot> y) \<cdot> z = x \<cdot> (y \<cdot> z)"

print_locale semigroup

subsection \<open>20.3 进到 locale 里：@{verbatim "context"}\<close>

text \<open>进了 @{verbatim "context semigroup begin ... end"}，
@{verbatim "mult"} 和 @{verbatim "assoc"} 就在作用域里，写 @{verbatim "abcd"} 不用
再声明类型，也不用重复假设。\<close>

context semigroup
begin

lemma assoc4: "((a \<cdot> b) \<cdot> c) \<cdot> d = a \<cdot> (b \<cdot> (c \<cdot> d))"
  by (simp add: assoc)

end

text \<open>离开 context 之后，@{verbatim "assoc"} 不再自动可见，要写限定名
@{verbatim "semigroup.assoc"}。上面那条 @{verbatim "assoc4"} 的完整形态是
@{verbatim "semigroup mult \<Longrightarrow> ((a \<cdot> b) \<cdot> c) \<cdot> d = a \<cdot> (b \<cdot> (c \<cdot> d))"}：
locale 名同时也是一个谓词，用来把假设重新收回来。\<close>

subsection \<open>20.4 用 @{verbatim "+"} 叠加结构\<close>

text \<open>新 locale 可以在旧的基础上加东西。 @{verbatim "monoid = semigroup + ..."}
表示：monoid 继承 semigroup 的参数与假设，再补上 @{verbatim "one"} 和两个
单位元律。同名假设被并入同一套 todo 列表，@{verbatim "print_locale"} 会
把合并之后的结果完整列出——这是排查"到底要证几条"的最快手段。\<close>

locale monoid = semigroup +
  fixes one :: "'a"  ("\<one>")
  assumes left_neutral: "\<one> \<cdot> x = x"
      and right_neutral: "x \<cdot> \<one> = x"

print_locale monoid

context monoid
begin

lemma neutral_idem: "\<one> \<cdot> \<one> = \<one>"
  by (simp add: left_neutral)

end

subsection \<open>20.5 interpretation：把抽象结构装到具体类型上\<close>

text \<open>@{verbatim "interpretation"} 给一组具体参数建立实例。
@{verbatim "unfold_locales"} 把 locale 的全部假设摊成子目标，
接上 @{verbatim "simp_all"} 一次性证明。注意 lambda 上的类型标注
@{verbatim ":: 'a list"}：缺了它， @{verbatim "xs @ ys"} 的 list
元素类型会被推断成一个全新的未知类型参数，实例就不是多态的了。\<close>

interpretation list_monoid: monoid "(\<lambda>xs ys :: 'a list. xs @ ys)" "[]"
  by unfold_locales simp_all

text \<open>实例建立之后，它的定理可以按实例名引用，类型是特化过的：\<close>

thm list_monoid.right_neutral

text \<open>locale 名作谓词用时，同样可以用 @{verbatim "unfold_locales"} 证明。
这里刻意避开 @{verbatim "op +"} 那种写法：@{verbatim "op"} 前缀形式在近年的
Isabelle 里已经不再推荐，直接写一个带类型标注的 lambda 更稳，
也更容易看出实例化到底选中了哪个加法。\<close>

lemma nat_add_monoid: "monoid (\<lambda>a b :: nat. a + b) 0"
  by unfold_locales (simp_all add: add.assoc)

subsection \<open>20.6 sublocale：永久注册的结构推导\<close>

text \<open>如果说 @{verbatim "interpretation"} 是"这一处要用这个实例"，
@{verbatim "sublocale"} 就是"从今往后，只要说 semigroup 就自动也有一份 dual"。
它注册的是一条**永久**规则，源 locale 的任何上下文里都能用。

下面把"反过来的乘法"注册成 semigroup 的实例。\<close>

sublocale semigroup \<subseteq> dual: semigroup "(\<lambda>x y. y \<cdot> x)"
  by unfold_locales (simp add: assoc)

context semigroup
begin

text \<open>这里的 @{verbatim "dual.assoc"} 说的是：把乘法反过来，
依然满足结合律——展开就是 @{verbatim "z \<cdot> (y \<cdot> x) = (z \<cdot> y) \<cdot> x"}，
即原结合律的镜像。\<close>

thm dual.assoc

end

subsection \<open>20.7 交换律：一个不带等式的例子\<close>

locale comm_monoid = monoid +
  assumes comm: "x \<cdot> y = y \<cdot> x"

context comm_monoid
begin

text \<open>@{verbatim "comm"} 不能当 @{verbatim "simp"} 规则：它是自对称的，
simp 会拒绝或者原地打转。这种"重排"用 @{verbatim "metis"} 最稳。\<close>

lemma left_comm: "x \<cdot> (y \<cdot> z) = y \<cdot> (x \<cdot> z)"
  by (metis assoc comm)

end

subsection \<open>20.8 locale 与类型类的分工\<close>

text \<open>最后提醒一条方向性事实：locale 里的假设是**假设**，不是事实。
如果某个结构其实满足更多性质（比如某个 monoid 恰好可交换），
那要靠 @{verbatim "sublocale"} 或者 @{verbatim "interpretation"} 补一张
新的证明义务，而不是直接改原来的 locale。\<close>

ML \<open>writeln "==== 20 结束 ===="\<close>

end
