theory T60a_comparator
  imports "HOL-Library.Sorting_Algorithms" "HOL-Library.Product_Lexorder"
    "HOL-Library.Option_ord" "HOL-Library.Fun_Lexorder" "HOL-Library.List_Lexorder"
begin

unbundle lattice_syntax

ML \<open>writeln "==== 60a 开始 ===="\<close>

section \<open>60.1 Comparator：三态比较器\<close>

text \<open>@{theory "HOL-Library.Comparator"} 把「比较」从序类里拆出来，
做成一个显式值：三态类型 @{verbatim "comp = Less | Equiv | Greater"}
加一条 locale @{locale comparator}（自反、Equiv 传递、Less 传递、
Greater 与反向 Less 互推）。typedef 把满足 locale 的函数收进
@{typ "'a comparator"}，投影 @{const compare} 是使用方法。
注意 @{verbatim Equiv} 只承诺「等价」不承诺「相等」——这正是
比较器比 @{class linorder} 强的地方：可以按某个投影排序而保留
同键元素的先后（稳定性，见 60.3）。\<close>

text \<open>@{class linorder} 类型自带默认比较器 @{term default}，常用类型的
代码化别名是 @{const comparator_nat}/@{const comparator_bool}：\<close>

value "compare comparator_nat (2::nat) 3"
value "compare comparator_nat (3::nat) 3"
value "compare comparator_nat (4::nat) 3"
value "compare comparator_bool False True"

text \<open>三个组合子覆盖最常见的改造：@{const reversed} 反转、
@{const key} 按投影比较、@{const prod_lex} 字典序拼合。
它们都有 @{verbatim "[simp]"} 应用规则，等式命题一行化简：\<close>

lemma "compare (reversed comparator_nat) (2::nat) 3 = Greater"
  by simp

lemma "compare (key length comparator_nat) [1::nat, 2] [5] = Greater"
  by simp

lemma "compare (prod_lex comparator_nat comparator_bool) (1::nat, True) (1, False) = Greater"
  by (simp add: compare_prod_lex_apply)

text \<open>第二行按长度比较：@{term "[1,2]"} 长度为 2 大于 @{term "[5]"}
的长度 1——比较器眼里这两个列表「等价类」是长度，元素内容无关。
第三行先比第一分量（打平），再比第二分量（@{term "False < True"}）。\<close>

section \<open>60.2 Sorting_Algorithms：一次验证，三种算法\<close>

text \<open>@{theory "HOL-Library.Sorting_Algorithms"} 的架构很有意思：
**规范层**只有插入排序 @{const Sorting_Algorithms.sort}（定义即
@{verbatim "foldr (insort cmp) xs []"}），正确性三件套一次证好——
多重集不变（@{thm Sorting_Algorithms.mset_sort [no_vars]}）、结果有序
（@{thm Sorting_Algorithms.sorted_sort [no_vars]}）、以及**稳定性**
@{thm Sorting_Algorithms.stable_sort [no_vars]}：排序前后，与
@{term x} 等价的元素段（@{verbatim stable_segment}）原封不动。
然后 @{const Sorting_Algorithms.quicksort} 与
@{const Sorting_Algorithms.mergesort} 都**定义成** sort 的别名，
再各自配一条可执行代码等式（@{thm Sorting_Algorithms.quicksort_code [no_vars]}
取中点 pivot 三路划分；@{thm Sorting_Algorithms.mergesort_code [no_vars]}
对半切分再 @{verbatim merge}）。数学上三者 syntactically 相等，
代码生成器走各自的快路径——「证明一次，跑三种实现」。\<close>

value "Sorting_Algorithms.sort comparator_nat [3::nat, 1, 2, 5, 4]"
value "Sorting_Algorithms.quicksort comparator_nat [3::nat, 1, 2, 5, 4]"
value "Sorting_Algorithms.mergesort comparator_nat [3::nat, 1, 2, 5, 4]"

lemma "mset (Sorting_Algorithms.sort comparator_nat [3::nat, 1, 2]) = {#3, 1, 2#}"
  by simp

text \<open>稳定性的可观察效果：按第一分量排序时，同键元素保持原相对顺序
（@{verbatim "(1,''b'')"} 始终排在 @{verbatim "(1,''c'')"} 前）：\<close>

value "Sorting_Algorithms.sort (key fst comparator_nat)
  [(1::nat, ''b''), (0, ''a''), (1, ''c'')]"

text \<open>排序谓词是 @{const Sorting_Algorithms.sorted}（注意与 Main 的
@{const List.sorted} 同名不同义，引用带前缀）：\<close>

value "Sorting_Algorithms.sorted comparator_nat [1::nat, 2, 3]"
value "Sorting_Algorithms.sorted comparator_nat [1::nat, 3, 2]"

text \<open>本章收尾有一条很漂亮的定理：先按第二分量稳定排序、再按第一
分量稳定排序，等价于一次字典序积排序——这正是「基数排序」的正确性
原理：\<close>

text \<open>@{thm [display] Sorting_Algorithms.sort_comp_fst_snd_eq_sort_prod_lex [no_vars]}\<close>

section \<open>60.3 列表字典序：List_Lexorder\<close>

text \<open>@{theory "HOL-Library.List_Lexorder"} 把列表实例化进序类：
@{term "xs < ys"} 定义为 @{term "(xs, ys) \<in> lexord {(u, v). u < v}"}
（Main 的 @{const lexord} 关系），逐元素比较，第一处不同定胜负，
空表最小。它给出完整的类链：@{class linorder} 实例 +
@{class distrib_lattice}（min/max 即 ⊓/⊔）+ @{class order_bot}
（@{term "[]"} 是底）：\<close>

value "[1, 2] < ([1, 3] :: nat list)"
value "[1, 2] < ([0, 9] :: nat list)"
value "[5] < ([1, 2] :: nat list)"
value "[] < ([0] :: nat list)"

lemma "([1::nat, 2] < [1, 3])"
  by simp

text \<open>第三行是本节的对比锚点：@{term "[5]"} 与 @{term "[1, 2]"}
首元素 5 > 1，字典序判负——长度完全不看。60.7 的 lenlex 版本
结论相反。还要记住：字典序在无穷降链意义上**不是**良序
（@{verbatim "[1] > [0,1] > [0,0,1] > …"}），所以它没有
@{class wellorder} 实例。\<close>

section \<open>60.4 积与函数上的字典序：Product_Lexorder 与 Fun_Lexorder\<close>

text \<open>@{theory "HOL-Library.Product_Lexorder"} 给积类型装字典序
（先比 @{const fst}，平了再比 @{const snd}），同样一路实例到
@{class linorder}、@{class distrib_lattice}、@{class bot}/@{class top}
以至 @{class wellorder}（两边都良序则积良序）：\<close>

value "(1, 2) < ((1, 3) :: nat \<times> nat)"
value "((2, 0) :: nat \<times> nat) > (1, 9)"

lemma "((1, 2) :: nat \<times> nat) \<le> (1, 3)"
  by simp

text \<open>函数类型的字典序是另一回事。Main 已经给函数装了**逐点**序
（@{term "f \<le> g \<longleftrightarrow> (\<forall>x. f x \<le> g x)"}），所以
@{theory "HOL-Library.Fun_Lexorder"} 刻意**不**注册类实例，
只给出定义 @{const less_fun}：在「第一处不同」的参数上分胜负
（参数侧须是 @{class linorder}，作为「字典的字母顺序」）：\<close>

lemma "less_fun (%n::nat. n) (%n. if n = 2 then 100 else n)"
  by (auto simp: less_fun_def intro!: exI [of _ 2])

text \<open>两个函数在 0、1 处相同，在 2 处 2 < 100，故前者小于后者。
三分律 @{thm less_fun_trichotomy [no_vars]} 要求两函数的**差异集有限**；
这条函数字典序正是字典序在「无穷词」上的对应物，在序数算术、
项序（termination order）文献里反复出现。\<close>

section \<open>60.5 Option_ord：None 垫底\<close>

text \<open>@{theory "HOL-Library.Option_ord"} 给 @{typ "'a option"} 装
典范序：@{term None} 小于一切 @{term Some}，@{term Some} 之间
回到元素序。于是 @{term "\<bottom>"} 就是 @{term None}，
@{term "\<top>"} 是 @{term "Some \<top>"}（元素有顶才有顶），并一路实例到
@{class wellorder}：\<close>

value "None < Some (0::nat)"
value "Some (2::nat) \<le> Some 3"
value "None \<le> (Some 5 :: nat option)"

lemma "(\<bottom> :: nat option) = None"
  by (simp add: bot_option_def)

text \<open>偏函数的序因此有了着落：第 14 章的 @{typ "'a \<rightharpoonup> 'b"}
逐点比较时，缺键（@{term None}）自动是最小值。\<close>

section \<open>60.8 坑位清单（实测，60a 部分）\<close>

text \<open>
1. @{const Sorting_Algorithms.sorted}/@{const Sorting_Algorithms.sort}
   与 Main 的 @{const List.sorted}/@{const sort_key} 体系**同名
   不同签名**：比较器版多带一个 @{typ "'a comparator"} 参数。
   混用理论后引用一律写全称。
2. @{verbatim Equiv} 不是相等：按 @{const key} 投影排序时同键
   不同值的元素都判 @{verbatim Equiv}，稳定性保证它们不换序，
   但 @{verbatim "compare cmp x y = Equiv \<Longrightarrow> x = y"} 不成立。
3. 比较器组合子（@{const reversed}/@{const key}/@{const prod_lex}）
   的应用规则是 simp 引理；写等式证明直接 simp，不必 unfold
   typedef。
4. @{const Sorting_Algorithms.quicksort}/@{const Sorting_Algorithms.mergesort}
   在逻辑层就是 @{const Sorting_Algorithms.sort}（定义展开即得），
   快的是代码等式；证明性质时对着 @{verbatim sort} 证，
    @{verbatim quicksort_is_sort} 一族会自动衔接。
5. 顶底与格记号的开关：Isabelle2025-2 起 ⊥/⊤/⊓/⊔ 收在
   @{verbatim lattice_syntax} bundle 里，Main 默认**不激活**
   （源码末尾 @{verbatim "unbundle no lattice_syntax"}）。项里直接写
   @{verbatim "\<bottom>"} 会报 Inner lexical error；要么像本理论一样
   @{verbatim "unbundle lattice_syntax"}，要么写 @{const bot}/@{const top}。
\<close>

ML \<open>writeln "==== 60a 结束 ===="\<close>

end
