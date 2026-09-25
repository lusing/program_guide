theory T38_locales_deep
  imports Main
begin

section \<open>38.1 第 20 章之后：locale 的后半本书\<close>

text \<open>第 20 章会了 @{verbatim "locale"} + @{verbatim "interpretation"}
的最小闭环。locales 手册（locales.pdf）的重头在后半：
**locale 里的定义**（interpretation 时被翻译）、**继承与多继承合并**、
@{verbatim "sublocale"}（带证明义务的包含关系）、局部解释、
以及 locale 与类型类（第 25 章）的相互翻译。\<close>

ML \<open>writeln "==== 38 开始 ===="\<close>

subsection \<open>38.2 locale 里可以有定义\<close>

text \<open>在 locale 内 @{verbatim "definition"}，定义带 locale 参数；
interpretation 时它被**自动翻译**到具体载体上。半群的幂运算：\<close>

locale semigroup =
  fixes prod :: "'a \<Rightarrow> 'a \<Rightarrow> 'a" (infixl "\<otimes>" 70)
  assumes assoc: "(x \<otimes> y) \<otimes> z = x \<otimes> (y \<otimes> z)"

context semigroup
begin

primrec power_sg :: "'a \<Rightarrow> nat \<Rightarrow> 'a" where
  "power_sg x 0 = x"
| "power_sg x (Suc n) = x \<otimes> power_sg x n"

end

text \<open>注意 @{verbatim "primrec"} 也可以在 locale 里做（定义阶段
带 @{verbatim "<otimes>"}）。interpretation 之后名字换成
@{verbatim "semigroup.power_sg prod"} 的实例形态：\<close>

interpretation list_sg: semigroup append
  by standard (simp add: append_assoc)

thm list_sg.power_sg.simps

subsection \<open>38.3 继承与参数合并\<close>

text \<open>monoid 继承 semigroup 并加单位元。参数合并是自动的：
@{verbatim "prod"} 只声明一次。\<close>

locale monoid_l = semigroup +
  fixes one :: 'a ("\<one>")
  assumes left_neutral [simp]: "\<one> \<otimes> x = x"

interpretation list_mon: monoid_l append "[]"
  by standard auto

thm list_mon.left_neutral

subsection \<open>38.4 sublocale：带证明义务的包含\<close>

text \<open>@{verbatim "sublocale"} 断言"满足 A 的都满足 B"，义务由你证。
最常见的用法之一：给已有 locale 补性质。交换半群里，幂的逆序性
不依赖逆元，但"幂与顺序交换"需要交换律——把它作为 sublocale
从 comm_semigroup 挂到 semigroup 的一个变体上：\<close>

locale comm_semigroup = semigroup +
  assumes comm: "x \<otimes> y = y \<otimes> x"

context comm_semigroup
begin

lemma power_sg_swap: "power_sg x (Suc n) = x \<otimes> power_sg x n"
  by simp

end

text \<open>@{verbatim "sublocale"} 带**参数映射**与证明义务的真示范：
交换半群里，"对偶乘法" @{verbatim "<lambda>x y. y \<otimes> x"} 又是一个半群——
义务（对偶的结合律）由交换律+结合律推出：\<close>

sublocale comm_semigroup \<subseteq> dual_sg: semigroup "\<lambda>x y. y \<otimes> x"
  by standard (simp add: assoc)

subsection \<open>38.5 局部解释：context 块内换世界\<close>

text \<open>@{verbatim "interpretation"} 是全局的（写进理论）；
@{verbatim "interpret"} 只在当前证明里生效。给 nat 的加法
临时解释半群并引用其引理：\<close>

lemma nat_sg_local:
  fixes a b :: nat
  shows "(a + b) + b = a + (b + b)"
proof -
  interpret nsg: semigroup "(+) :: nat \<Rightarrow> nat \<Rightarrow> nat"
    by standard simp
  show ?thesis by (simp add: nsg.assoc)
qed

subsection \<open>38.6 检查工具：print_locale 与 print_interps\<close>

print_locale semigroup
print_locale comm_semigroup
print_interps semigroup

subsection \<open>38.7 坑位清单（实测）\<close>

text \<open>1. locale 内定义的名字前缀：@{verbatim "semigroup.power_sg"}，
   全局引用要写全（或先 interpretation 再用短前缀
   @{verbatim "list_sg.power_sg"}）。
2. @{verbatim "value"} 里用 locale 定义：@{verbatim "power_sg x 3"}
   直接报未绑定——必须 @{verbatim "semigroup.power_sg append [1] 3"}
   把参数喂全。
3. @{verbatim "sublocale"} 的参数映射语法
   @{verbatim "<lparr>prod := (\<otimes>)\<rparr>"} 别忘；空映射也要写对 locale 名。
4. @{verbatim "interpret"}（局部）与 @{verbatim "interpretation"}（全局）
   一字之差；证明里用了 interpretation 会把解释持久化进理论，
   通常不是你要的。
5. 多继承的参数合并冲突：两个父 locale 有同名参数且映射不同，
   合并阶段直接报 @{verbatim "Conflicting"}。
6. @{verbatim "print_interps"} 按第一个 locale 列出所有解释，
   忘了名字先查它。
7. locale 里的 @{verbatim "primrec"} 终止性照常检查（它就是普通
   primrec，只是右端可以带 locale 常量）。
8. @{verbatim "sublocale"} 的义务证不动 = 包含关系不成立或参数映射
   写错；硬 @{verbatim "sorry"} 构建必拒，回头改映射而不是硬顶。\<close>

thm list_mon.left_neutral nat_sg_local

ML \<open>writeln "==== 38 结束 ===="\<close>

end
