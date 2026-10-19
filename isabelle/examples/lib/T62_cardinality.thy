theory T62_cardinality
  imports "HOL-Library.Equipollence" "HOL-Library.Cardinality"
    "HOL-Library.Nat_Bijection" "HOL-Library.Infinite_Set" "HOL-Library.Countable"
begin

section \<open>62.1 Nat_Bijection：nat 与 nat×nat 互相编码\<close>

text \<open>「nat 与 nat × nat 等势」的可执行证据在
@{theory "HOL-Library.Nat_Bijection"}：Cantor 配对函数。
@{const prod_encode} 用三角数 @{const triangle}
（@{term "triangle (Suc n) = triangle n + Suc n"}）做
@{verbatim "(m, n) -> triangle (m + n) + m"} 的锯齿编号，
@{const prod_decode} 逆向解码。两者互逆是 simp 规则
（@{thm prod_decode_inverse [no_vars]} 与
@{thm prod_encode_inverse [no_vars]}）：\<close>

ML \<open>writeln "==== 62 开始 ===="\<close>

value "prod_encode (2, 3)"
value "prod_decode 18"

lemma "prod_decode (prod_encode (m, n)) = (m, n)"
  by simp

text \<open>同一条流水线还有集合编码：@{const set_encode} 把**有限**
nat 集编码成二进制位串之和 @{term "sum ((^) 2) A"}（无穷集约定
为 0），@{const set_decode} 反向。这些编码是第 25 章
「可枚举类型」传统的始祖——编码存在，可数性就有依据。\<close>

lemma "set_encode {0::nat, 2} = 5"
  by (simp add: set_encode_def)

section \<open>62.2 Equipollence：等势、不弱于、严格小于\<close>

text \<open>@{theory "HOL-Library.Equipollence"} 给出基数的**关系**形式，
三个记号一次到位：@{term "A \<approx> B"}（@{const eqpoll}，存在双射）、
@{term "A \<lesssim> B"}（@{const lepoll}，存在 A 到 B 的单射）、
@{term "A \<prec> B"}（@{const lesspoll}，可单射但不同势）。

有限集上等势就是基数相等（@{thm eqpoll_iff_card [no_vars]}，
化简器能自动担当有限性前提）：\<close>

lemma "{2, 4, 6::nat} \<approx> {1, 3, 5::nat}"
  by (simp add: eqpoll_iff_card)

lemma "({0..<5}::nat set) \<lesssim> {0..<7::nat}"
  by (auto intro: subset_imp_lepoll)

text \<open>两条重量级定理直接可用。Schröder–Bernstein（互相单射即等势，
库里是 @{thm lepoll_antisym [no_vars]}，经 Main 的
@{verbatim Schroeder_Bernstein} 落地）：\<close>

lemma Schroeder_Bernstein_use: "A \<lesssim> B \<Longrightarrow> B \<lesssim> A \<Longrightarrow> A \<approx> B"
  by (rule lepoll_antisym)

text \<open>Cantor（任何集合严格小于其幂集）。@{const UNIV} 形态的
「nat 的幂集不可数」一条结构化证明——等势给出双射，双射的像
覆盖幂集，与 @{thm Cantors_theorem [no_vars]}（没有任何函数
能把自己的值域铺满幂集）矛盾：\<close>

lemma cantor_nat: "\<not> (UNIV :: nat set) \<approx> Pow (UNIV :: nat set)"
proof
  assume "(UNIV :: nat set) \<approx> Pow (UNIV :: nat set)"
  then obtain f where f: "bij_betw f (UNIV :: nat set) (Pow (UNIV :: nat set))"
    unfolding eqpoll_def by blast
  then have "f ` UNIV = Pow (UNIV :: nat set)"
    by (simp add: bij_betw_def)
  with Cantors_theorem show False by blast
qed

text \<open>一个常用的「无穷」判据也在这里：@{thm infinite_le_lepoll [no_vars]}
——集合无穷当且仅当 nat 能单射进去。\<close>

section \<open>62.3 Countable：可数的类型与集合\<close>

text \<open>两个层次别混：@{theory "HOL-Library.Countable"} 是**类型类**
@{class countable}（存在到 nat 的单射， @{const to_nat}/
@{const from_nat} 由此定义）；@{verbatim Countable_Set}（Main 侧
已有雏形）是**集合**谓词 @{const countable}。类实例把可数性一路
传给构造器：nat、int、rat、积、和、option、list 全部可数
（函数类型 @{typ "'a \<Rightarrow> 'b"} 在定义域 @{class finite}、值域
可数时可数）。集合谓词与类的桥梁是 @{verbatim countable} 对
@{verbatim UNIV} 的实例：\<close>

lemma "countable (UNIV :: (nat \<times> nat) set)"
  by simp

lemma "countable (UNIV :: nat list set)"
  by simp

text \<open>@{const to_nat} 是选择算子挑出来的单射（@{term "SOME f. inj f"}），
所以它的具体值**不可计算**——能用的是 @{thm inj_to_nat [no_vars]}
和 @{thm surj_from_nat [no_vars]} 两条抽象性质，不要指望
@{verbatim value}。\<close>

section \<open>62.4 Cardinality：类型的基数算术\<close>

text \<open>@{theory "HOL-Library.Cardinality"} 把「类型的大小」写成
@{term "CARD('a)"}（即 @{term "card UNIV"}，无穷类型约定为 0），
并给出构造器上的算术：积是乘、和是加、option 加一、幂集是
2 的幂、函数空间是指数：\<close>

lemma "CARD(bool) = 2"
  by simp

lemma "CARD(bool \<times> bool) = 4"
  by simp

lemma "CARD(bool option) = 3"
  by simp

lemma "CARD(nat) = 0"
  by simp

text \<open>「0 = 无穷」的约定（@{thm card_nat [no_vars]}）让
@{thm card_fun [no_vars]} 这样的公式对所有类型统一成立，
不用分情形。@{verbatim card2} 类（至少两个元素）支撑
@{thm one_less_card [no_vars]} 一类「非平凡」前提。\<close>

section \<open>62.5 Infinite_Set：「无穷多次」的一阶写法\<close>

text \<open>@{theory "HOL-Library.Infinite_Set"} 提供两个 binder：
@{term "\<exists>\<^sub>\<infinity>x. P x"}（@{const Inf_many}，满足 P 的 x 组成无穷集）
与 @{term "\<forall>\<^sub>\<infinity>x. P x"}（@{const Alm_all}，例外只有有限个）。
它们是「极限/渐近」推理的日常词汇（第 64 章 @{verbatim "Omega_Words_Fun"} 的 limit、
滤子里的 @{const eventually} 的近亲）：\<close>

lemma "\<exists>\<^sub>\<infinity>n::nat. True"
  by (simp add: Inf_many_def)

lemma "\<forall>\<^sub>\<infinity>n::nat. n > 100"
proof -
  have "{n::nat. \<not> n > 100} = {..100}" by auto
  then show ?thesis by (simp add: Alm_all_def Inf_many_def)
qed

text \<open>证明模式：@{const Inf_many} 展开成 @{term infinite} 后交给
无穷的 simp 规则；@{const Alm_all} 展开成补集有限，先把例外集
算成显式区间再化简。\<close>

section \<open>62.6 坑位清单（实测）\<close>

text \<open>
1. 「可数」有两层：类型类 @{class countable}（Countable.thy）
   与集合谓词 @{const countable}（Countable_Set.thy）；
   写法 @{term "countable (UNIV :: 'a set)"} 是两者的桥。
2. @{const to_nat}/@{const from_nat} 是 @{verbatim SOME} 挑的，
   不可计算；只有 @{thm inj_to_nat [no_vars]}/
   @{thm surj_from_nat [no_vars]} 可用。
3. @{term "CARD('a)"} 对无穷类型是 0 不是「无定义」——
   基数算术公式（积/和/幂）因此无分支，但读定理时注意
   0 的双重含义。
4. @{const eqpoll} 的 @{verbatim "\<approx>"}、@{const lepoll} 的
   @{verbatim "\<lesssim>"}、@{const lesspoll} 的 @{verbatim "\<prec>"}
   是 infixl 50；与普通 @{verbatim "\<le>"} 不冲突，但视觉上
   易混，读别人的理论先确认 imports。
5. @{term "A \<approx> B"} 的证明入口：有限用 @{thm eqpoll_iff_card [no_vars]}
   化归基数相等；无穷用 @{thm eqpoll_def [no_vars]} 造双射或
   Schröder–Bernstein（@{thm lepoll_antisym [no_vars]}）两边单射。
6. Cantor 定理在 Main 里叫 @{thm Cantors_theorem [no_vars]}
   （@{verbatim "∄f. f ` A = Pow A"}，「没有满射」形态），
   与等势语言的转换经过 bij_betw 的像等式。
7. @{const Inf_many}/@{const Alm_all} 的 ASCII 写法是
   @{verbatim "INFM"}/@{verbatim "Alm_all"}（部分老代码里见
   @{verbatim "Inf_many"}），展开引理 @{thm Inf_many_def [no_vars]}/
   @{thm Alm_all_def [no_vars]}。
8. @{const set_encode} 对无穷集**静默返回 0**（约定），
   用前先用 @{term finite} 守住。
9. prod_encode 的参数序是 @{verbatim "(m, n) -> triangle (m+n) + m"}
   （加的是**第一**分量），不是对称的——@{term "prod_encode (m, n) \<noteq> prod_encode (n, m)"}
   一般成立，别凭印象交换。
10. 基数与等势是**集合**层面语言；@{term "infinite (UNIV :: 'a set)"}
    是「整个类型无穷」的写法，与 @{const lepoll} 经
    @{thm infinite_le_lepoll [no_vars]} 互译。
\<close>

ML \<open>writeln "==== 62 结束 ===="\<close>

end
