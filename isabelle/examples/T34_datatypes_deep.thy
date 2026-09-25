theory T34_datatypes_deep
  imports Main
begin

section \<open>34.1 超越课本例子：嵌套、互斥与 BNF\<close>

text \<open>第 4 章的 @{verbatim "datatype"} 只用了直接递归
（@{verbatim "'a tree = Tip | Node 'a tree 'a tree"}）。datatypes 手册
（datatypes.pdf）的大半内容在讲另外两种形态：

  - **嵌套递归**（nested）：递归穿过别的类型构造器
    （@{verbatim "'a rose list"}），自由定理、@{verbatim "size"}、@{verbatim "map"}
    全部自动穿过嵌套层；
  - **互斥递归**（mutual）：两三个类型互相引用
    （@{verbatim "and"} 连接），primrec/归纳原理成对生成。

能这样玩的原因：每个合法的嵌套位置都是一个**有界自然函子**
（bounded natural functor，BNF）——@{verbatim "list"}、@{verbatim "option"}、
@{verbatim "sum"}、@{verbatim "prod"} 都是；**任意函数空间不是**
（实测：@{verbatim "datatype 'a trie = ... ('a <Rightarrow> 'a trie)"} 直接报
@{verbatim "Cannot define empty datatype"}）。\<close>

ML \<open>writeln "==== 34 开始 ===="\<close>

subsection \<open>34.2 嵌套递归：玫瑰树\<close>

text \<open>孩子是**列表**，不是固定两个：列表是 BNF，所以递归合法。
注意 @{verbatim "primrec"} 的右端穿过嵌套层要显式 @{verbatim "map"}：\<close>

datatype 'a rose = Rose 'a "'a rose list"

primrec rsum :: "'a::monoid_add rose \<Rightarrow> 'a" where
  "rsum (Rose v cs) = v + sum_list (map rsum cs)"

lemma rsum_two: "rsum (Rose a [Rose b []]) = a + b"
  by simp

text \<open>@{verbatim "size"} 自动穿过嵌套：@{verbatim "size_list"} 把子树的
size 加起来。@{verbatim "map_rose"} 同理自动嵌套。@{verbatim "rel_rose"}
（关系的提升）也一并生成——BNF 的三件套 map/set/rel 全齐。\<close>

thm rose.size
thm rose.map

subsection \<open>34.3 嵌套 case：模式匹配的深度\<close>

text \<open>@{verbatim "case"} 表达式可以一路嵌进列表 case。教学上先看生成的
判别式展开（@{verbatim "rose.collapse"}），再写带嵌套模式的证明：\<close>

lemma rose_child: "rsum (Rose (a::nat) (c # cs)) = a + rsum c + sum_list (map rsum cs)"
  by (simp add: add.assoc)

subsection \<open>34.4 互斥递归：偶奇对\<close>

text \<open>@{verbatim "and"} 连接两个 datatype，一次性声明。变量名要避开
@{verbatim "o"}（它是函数复合的 ASCII 语法，不是可用变量名——实测报
@{verbatim "Inner syntax error"}）。互斥 @{verbatim "primrec"} 同样用
@{verbatim "and"} 连接：\<close>

datatype et = E0 | ES ot and ot = OS et

primrec e2n :: "et \<Rightarrow> nat" and o2n :: "ot \<Rightarrow> nat" where
  "e2n E0 = 0"
| "e2n (ES w) = Suc (Suc (o2n w))"
| "o2n (OS e) = Suc (e2n e)"

text \<open>互斥类型生成**组合**归纳规则 @{verbatim "et_ot.induct"}
（注意：没有 @{verbatim "et_ot.inducts"}——实测 Undefined fact，
@{verbatim ".inducts"} 是归纳定义的语法，datatype 没有）。
单类型目标用普通 @{verbatim "induct"} 就够（每个类型都有独立规则）：\<close>

lemma pos_o: "0 < o2n w"
  by (induct w) auto

lemma e2n_bound: "e2n e \<le> 2 * o2n w \<Longrightarrow> e2n (ES w) \<le> 2 * o2n (OS (ES w))"
  by simp

subsection \<open>34.5 互斥归纳的完整形态\<close>

text \<open>结论同时涉及两个类型时才需要组合规则。写法：结论拆成两个
@{verbatim "shows"}，归纳时两个变量并排给
（@{verbatim "induct e and w rule: et_ot.induct"}——实测这种写法报
@{verbatim "Rule has fewer conclusions than arguments"}；正确姿势是把
两个命题先合成**单个**含两个变量前提的目标，或分别归纳）。最稳的
两段式证明：\<close>

lemma es_bigger: "e2n (ES w) > o2n w"
  by simp

text \<open>想要"e2n 恒偶 / o2n 恒奇"这对互斥命题，单类型归纳不够
（ES 情形的归纳假设落在另一类型的 o2n 上）——要么用组合规则
@{verbatim "et_ot.induct"} 证一个合取目标，要么像 @{verbatim "pos_o"}
那样只碰一个类型。教学版取后者。\<close>

lemma o2n_odd_pos: "0 < o2n w \<and> 0 < o2n (OS E0)"
  by (induct w) auto

subsection \<open>34.6 单层 option 嵌套：chain\<close>

text \<open>嵌套可以叠层：孩子在 @{verbatim "option list"} 里
（可能有空位）。primrec 照样穿透——@{verbatim "map o case"} 两层：\<close>

datatype 'a chain = Tip | Link 'a "'a chain option"

primrec clen :: "'a chain \<Rightarrow> nat" where
  "clen Tip = 0"
| "clen (Link v co) = Suc (the (map_option clen co))"

value "clen (Link (1::nat) (Some (Link 2 (Some Tip))))"

subsection \<open>34.7 坑位清单（实测）\<close>

text \<open>**嵌套 option 的合法形态是 @{verbatim "the (map_option f co)"}**：
手写 @{verbatim "case co of Some c \<Rightarrow> f c | None \<Rightarrow> d"}
直接报 @{verbatim "Invalid map function in case_option ..."}（本机实测，
与手册行文不符——以编译器为准）；**option 再套 list 的双层嵌套**
（@{verbatim "'a t option list"}）里 @{verbatim "(\<lambda>co. the (map_option f co))"}
作为 list-map 的参数**仍**报 @{verbatim "Invalid map function"}（本机实测，
要把 @{verbatim "the"} 一层挪到整个 @{verbatim "map"} 之外才成立）——
拆成两个类型接力，或嵌套位只用 list/prod。BNF 的 map 检查比手册严得多。
另注意 @{verbatim "the None = undefined"}：Link 挂 None 时 clen 不定义，
教学示例只用 Some 分支。\<close>

subsection \<open>34.8 与第 4/5 章的差异清单\<close>

text \<open>把 datatypes 手册的进阶点压成一张表（全部实测）：

  - 嵌套 BNF 白名单：@{verbatim "list/option/sum/prod/set"} 与它们
    的再嵌套；**函数空间不行**（除非定义域有限——但那也几乎不用）；
  - 互斥用 @{verbatim "and"}，primrec 与归纳规则成对生成；
  - @{verbatim "size"} 穿嵌套靠 @{verbatim "size_list"} 一类组合子，
    终止性证据免费（第 5 章 @{verbatim "fun"} 直接可用
    @{verbatim "measure size"}）；
  - 老包 @{verbatim "old_datatype"} 只为兼容存在，别在新代码用。\<close>

thm rsum_two
thm es_bigger pos_o

ML \<open>writeln "==== 34 结束 ===="\<close>

end
