theory T26_codatatype
  imports Main
begin

section \<open>26.1 从 datatype 到 codatatype\<close>

text \<open>第 4 章的 @{verbatim "datatype"} 声明的是**最小**不动点：类型里的每个元素
都必须在**有限**步内由构造器搭出来。@{verbatim "codatatype"} 反过来，声明
**最大**不动点：允许存在**无限**深的构造。经典例子是流（stream）与无限树。

三条对称性要提前记住：

  1. @{verbatim "primrec"}（结构递归，必须终止） ↔ @{verbatim "primcorec"}
     （结构共归，逐层吐出构造子）；
  2. @{verbatim "induct"}（对结构做归纳） ↔ @{verbatim "coinduct"}
     （对关系做共归纳）；
  3. datatype 的注入性/互异性 ↔ codatatype 的判别式 @{verbatim "is_X"}
     + 选择子 @{verbatim "sel"}。

无限对象要**观察得够多步**才能区分；因此"相等"的正确说法是"永远观察不出
区别"，也就是**双相似（bisimilar）**——这正是 @{verbatim "coinduction"} 要
证的东西。\<close>

ML \<open>writeln "==== 26 开始 ===="\<close>

subsection \<open>26.2 一个最小的流 codatatype\<close>

text \<open>下面手写一个纯流类型：@{verbatim "SCons"} 携带表头 @{verbatim "shead"}
与尾流 @{verbatim "stail"}。@{verbatim "codatatype"} 会送出一堆东西：
选择子 @{verbatim "shead"} 与 @{verbatim "stail"}、共归纳规则
@{verbatim "stream.coinduct"}、构造子映射 @{verbatim "map_stream"}。\<close>

codatatype 'a stream = SCons (shead: 'a) (stail: "'a stream")

term SCons
term stail
thm stream.collapse

subsection \<open>26.3 @{verbatim "primcorec"}：逐层写构造子\<close>

text \<open>@{verbatim "primcorec"} 是 @{verbatim "primrec"} 的对偶：每条方程描述
**当前一层**的构造子长什么样，而不是"缩小到基本情况"。下面 @{verbatim "repeat"}
给一个 @{verbatim "x"}，产出无穷流 @{verbatim "SCons x (SCons x ...)"}。
方程右边直接说 @{verbatim "shead = x"}、@{verbatim "stail = repeat x"}
——@{verbatim "primcorec"} 接受这种"结构上生产一层，递归只在 co-recursor
位置"的定义。\<close>

primcorec repeat :: "'a \<Rightarrow> 'a stream" where
  "shead (repeat x) = x" |
  "stail (repeat x) = repeat x"

thm repeat.simps

subsection \<open>26.4 @{verbatim "primcorec"} 的第二个例子：@{verbatim "upto"}\<close>

text \<open>@{verbatim "primcorec"} 已经足够表达"每一层直接吐构造子，递归只在
@{verbatim "stail"} 位置"的常见流。这里造一个"从 @{verbatim "n"} 开始逐次
加 1"的流：\<close>

primcorec upto :: "nat \<Rightarrow> nat stream" where
  "shead (upto n) = n" |
  "stail (upto n) = upto (Suc n)"

thm upto.simps

subsection \<open>26.5 @{verbatim "stail_repeat"}：一条平凡方程\<close>

text \<open>@{verbatim "primcorec"} 已经把 @{verbatim "stail (repeat x) = repeat x"}
写进 @{verbatim "repeat.simps"}，直接 simp 就能证——这也是共归定义用起来
最爽的一面：**方程就是构造子的选择子方程**。\<close>

lemma stail_repeat: "stail (repeat x) = (repeat x :: 'a stream)"
  by simp

subsection \<open>26.6 无限树：codatatype 里嵌 codatatype\<close>

text \<open>无限二叉树：每个节点带标签，左右子树可以再无限深。这里没有基本情况
（"叶"）——一棵树就是一条无限路径上的观察。\<close>

codatatype 'a tree = Node (lab: 'a) (lch: "'a tree") (rch: "'a tree")

primcorec grow :: "nat \<Rightarrow> nat tree" where
  "lab (grow n) = n" |
  "lch (grow n) = grow (n + 1)" |
  "rch (grow n) = grow (n + 1)"

thm grow.simps

subsection \<open>26.7 与 @{verbatim "primrec"} 的边界\<close>

text \<open>常见的坑：@{verbatim "primrec"} 用在 @{verbatim "codatatype"} 上。
@{verbatim "primrec"} 要求结构递归"变小"，@{verbatim "codatatype"} 没有
基本情况可言，一旦递归穿透 co-recursor 位置 @{verbatim "primrec"} 就拒。
但**只看一层**是允许的——例如 @{verbatim "lab"} 选择子返回 @{verbatim "'a"}，
不是 @{verbatim "tree"}，所以 @{verbatim "primrec"} 不需要展开子树。\<close>

definition root_lab :: "nat tree \<Rightarrow> nat" where
  "root_lab t = lab t"

lemma root_lab_grow [simp]: "root_lab (grow n) = n"
  unfolding root_lab_def by simp

text \<open>这里刻意**不** @{verbatim "value"} 那条 @{verbatim "root_lab (grow 5)"}——
@{verbatim "value"} 走代码生成路径，遇到 @{verbatim "codatatype"} 会尝试构造
整个无限对象。求值只在 @{verbatim "datatype"}（有限的）上安全。上面改用
一条 simp 引理，得到同样的答案 @{verbatim "5"}。\<close>

subsection \<open>26.8 坑位清单（实测）\<close>

text \<open>1. @{verbatim "primcorec"} 必须**同时**给出所有判别式与选择子的方程
   （少一条选择子方程就报"方程不齐"）。
   2. @{verbatim "corec"}（更宽松的共归）在 @{verbatim "HOL-Library.Stream"}
   之类的父会话里才可用；只 imports Main 时 @{verbatim "primcorec"} 是唯一选项。
   分支里的递归调用必须出现在 co-recursor 位置——否则等价于普通
   @{verbatim "fun"}，需要 termination。
   3. @{verbatim "coinduction"} 与 @{verbatim "induct"} 一样，需要泛化的
   变量必须 @{verbatim "arbitrary:"}；否则 bisimulation 关系被固定。
   4. @{verbatim "codatatype"} 与 @{verbatim "datatype"} **不共享** induction
   规则；用错名字（@{verbatim "stream.induct"}）报的是 "Undefined fact"。\<close>

ML \<open>writeln "==== 26 结束 ===="\<close>

end
