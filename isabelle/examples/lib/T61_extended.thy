theory T61_extended
  imports "HOL-Library.Extended_Nonnegative_Real" "HOL-Library.Nonpos_Ints"
begin

section \<open>61.1 enat：nat 加一个无穷点\<close>

text \<open>@{theory "HOL-Library.Extended_Nat"} 把 @{typ "nat option"} 包装成
@{typ enat}：@{term "enat n"} 是有限值，@{term "\<infinity>"} 对应
@{const None}。两条线因此汇合——第 60 章的 @{verbatim Option_ord}
给了它序（@{term None} 垫底变最小？不——这里反过来了），
@{typ enat} 的序把 @{term "\<infinity>"} 放在**顶上**：@{term "n < \<infinity>"}
对一切有限 @{term n} 成立。后继 @{const eSuc} 在无穷处自吸收；
投影 @{const the_enat} 把有限值取回（@{term "\<infinity>"} 上未定义，
谨慎使用）。\<close>

ML \<open>writeln "==== 61 开始 ===="\<close>

value "\<infinity> + (1::enat)"
value "(0::enat) * \<infinity>"
value "\<infinity> * (2::enat)"
value "eSuc \<infinity>"
value "the_enat (5::enat)"

lemma "(3::enat) < \<infinity>"
  by simp

text \<open>加法是「逢无穷吸收」，乘法多一条测度论惯例 @{term "0 * \<infinity> = 0"}
（ @{thm times_enat_simps [no_vars]} 一族）。数字字面量直接可用——
@{verbatim enat} 有 coercion，@{term "5 :: enat"} 就是
@{term "enat 5"}。@{typ enat} 还是完备格：顶为 @{term "\<infinity>"}，
底为 0，任意集合的 @{const Sup} 有限取最大、无穷集合落到
@{term "\<infinity>"}：\<close>

lemma "Sup {0, 1, 2::enat} = 2"
  by (simp add: Sup_enat_def)

text \<open>@{thm [display] Sup_enat_def [no_vars]}
——「无穷集的 Sup 是无穷」正是它当「扩展自然数」的本钱：
无穷求和、无穷迭代次数都有了着落。\<close>

section \<open>61.2 ereal：带正负号的两个无穷\<close>

text \<open>@{theory "HOL-Library.Extended_Real"} 的 @{typ ereal} 是
datatype：@{verbatim "ereal real | PInfty | MInfty"}，即
@{term "\<infinity>"} 与 @{term "-\<infinity>"} 两个端点。与 enat 的本质差别是
**符号**：加法两边都是「同号吸收」，乘法是符号规则驱动
（正乘 @{term "\<infinity>"} 得 @{term "\<infinity>"}，负乘得 @{term "-\<infinity>"}，
0 乘任何无穷都得 0）：\<close>

value "\<infinity> + (-\<infinity>::ereal)"
value "(-\<infinity>::ereal) + \<infinity>"
value "(0::ereal) * \<infinity>"
value "ereal 2 * \<infinity>"
value "ereal (-2) * \<infinity>"
value "\<bar>(-\<infinity>::ereal)\<bar>"

lemma "ereal 2 < (\<infinity>::ereal)"
  by simp

text \<open>前两行同答 @{term "\<infinity>"}：@{term "\<infinity> + -\<infinity>"} 没有
「未定义」，定义按模式匹配硬性规定为 @{term "\<infinity>"}——这是库的
**设计决定**，不是定理。推论是 ereal 不成域：@{term "\<infinity>"} 没有
加法逆元，消去律要带非无穷前提
（@{thm ereal_add_cancel_left [no_vars]}：左端非 @{term "-\<infinity>"} 时
@{term "a + b = a + c"} 要么 @{term "a = \<infinity>"} 要么 @{term "b = c"}）。
写 ereal 证明的肌肉记忆就是 @{verbatim "cases rule: ereal2_cases"}
三分情形——库里的实例证明全是这么过的。\<close>

section \<open>61.3 ennreal：测度论的工作马\<close>

text \<open>@{theory "HOL-Library.Extended_Nonnegative_Real"} 用 typedef 把
@{typ ereal} 的非负半轴收进 @{typ ennreal}（第 28 章流水线）：
@{const enn2ereal} 投影出去，@{const e2ennreal} 进来（自动把负数
截到 0，并有 coercion）。它是测度与积分的值域（第 46 章）：
非负、含 @{term "\<infinity>"}（此时 @{term "\<infinity>"} 就是顶）、完备线序。
减法是**截断**的（{@{term "max 0 (a - b)"}} 的搬运）：\<close>

lemma "ennreal 5 - ennreal 8 = (0::ennreal)"
  by (simp del: ennreal_numeral add: ennreal_minus ennreal_eq_0_iff)

lemma "ennreal 8 - ennreal 5 = ennreal 3"
  by (simp del: ennreal_numeral add: ennreal_minus)

lemma "(\<infinity>::ennreal) - \<infinity> = \<infinity>"
  by transfer' simp

text \<open>第三行再次提醒「扩展数系处处是设计决定」：ennreal 的
@{term "\<infinity> - \<infinity>"} 落在 @{term "\<infinity>"}（ereal 层 @{term "\<infinity> + -\<infinity> = \<infinity>"}
再截断）。库选择牺牲消去律换「处处有定义」，好处是完备格运算
畅通无阻。\<close>

section \<open>61.4 Nonpos_Ints：非正整数集\<close>

text \<open>@{theory "HOL-Library.Nonpos_Ints"} 是小品：任意环上
（经 @{const of_int} 嵌入）的非正整数集 @{term "\<int>\<^sub>\<le>\<^sub>0"}，
与 Main 的 @{term "\<nat>"}/@{term "\<int>"} 平行。它的标准用途是
@{term "\<Gamma>"} 函数的极点集（非正整数恰好是 @{term "\<Gamma>"} 的极点）。
成员判定全是现成 simp/intro 规则：\<close>

lemma "(-2 :: real) \<in> \<int>\<^sub>\<le>\<^sub>0"
  by simp

lemma "(1 :: real) \<notin> \<int>\<^sub>\<le>\<^sub>0"
  by simp

lemma x_nonpos: "x \<in> \<int>\<^sub>\<le>\<^sub>0 \<Longrightarrow> x \<le> (0 :: 'a :: linordered_idom)"
  by (rule nonpos_Ints_nonpos)

section \<open>61.5 坑位清单（实测）\<close>

text \<open>
1. @{typ enat} 的 @{term "\<infinity>"} 在**顶上**（序的最大元），与
   60 章 @{verbatim Option_ord} 里 @{term None} 垫底相反——
   两者底层都是 @{typ "nat option"}，序的解释不同。
2. @{term "0 * \<infinity> = 0"} 是测度论惯例的硬编码；期望「未定」
   语义的读者注意这不是 bug。
3. 三个类型的 @{term "\<infinity>"} 不是同一个常量，是 @{class infinity}
   类的多态常量；类型标注不清时 @{term "\<infinity>"} 会停在多态，
   求值报 free dictionaries（同 59/60 章数字坑）。另外符号名只有
   @{verbatim "\<infinity>"}——@{verbatim "\<infty>"} 不存在（词法层直接拒）。
4. @{const the_enat} 在 @{term "\<infinity>"} 上未定义（落在
   默认 0），证明里别拿它当安全的逆。
5. ereal 不是域：@{term "\<infinity>"} 无加法逆，消去律一律带前提
   （@{thm ereal_add_cancel_left [no_vars]} 的形态），
   乘法还有 0 陷阱。
6. ennreal 减法截断到 0（@{verbatim "max 0 (a - b)"}），
   @{term "\<infinity> - \<infinity> = \<infinity>"}；写差方程前先想清楚是否合法。
   证明通道实测一串坑：ennreal **不可执行**（无 equal 实例，
   @{verbatim eval} 直接拒）；Complex_Main 在场时 transfer 对
   ennreal 数值目标静默不动；@{verbatim ennreal_numeral} 这条
   simp 规则会抢先吃掉 @{verbatim ennreal} 包装让
   @{verbatim ennreal_minus} 匹配不上——数值减法要等式化简时
   必须 @{verbatim "simp del: ennreal_numeral"} 再用
   @{verbatim ennreal_minus}/@{verbatim ennreal_eq_0_iff} 一族。
7. enat 上 @{const Sup} 对无穷集给 @{term "\<infinity>"}——想证
   @{term "Sup A = \<infinity>"} 的标准路径是先证 @{term "infinite A"}
   再展开 @{thm Sup_enat_def [no_vars]}。
8. @{term "\<int>\<^sub>\<le>\<^sub>0"} 是**集合**不是类型：成员命题直接用，
   想造类型请自己 typedef（第 28 章）。
9. coercion 链：@{verbatim "nat → enat"}、@{verbatim "real → ereal"}、
   @{verbatim "ereal → ennreal"}（截断）；打印出来看不到 coercion
   箭头，读定理时心里补上。
10. 这三个理论在 @{verbatim "HOL-Library"} 会话，分析库
    （HOL-Analysis，第 46 章）里的测度/积分直接复用
    @{typ ennreal}——学它是为了读懂测度论定理的签名。
\<close>

ML \<open>writeln "==== 61 结束 ===="\<close>

end
