theory T63_monads
  imports "HOL-Library.State_Monad" "HOL-Library.Open_State_Syntax"
    "HOL-Library.Function_Algebras" "HOL-Library.Uprod"
begin

unbundle state_combinator_syntax

section \<open>63.1 Monad_Syntax：Haskell 式 do 记法\<close>

text \<open>@{theory "HOL-Library.Monad_Syntax"} 只有一页纸，却给了全套
do 记法：一个待重载的 @{const Monad_Syntax.bind} 中缀
（@{verbatim "\<bind>"}，ASCII @{verbatim ">>>="}），外加
@{verbatim "do { x <- m; ... }"} 块语法（@{verbatim "do"}/
@{verbatim "let"}、分号串联）。@{const Monad_Syntax.bind} 本身是
多态占位符，由 @{verbatim "adhoc_overloading"} 按类型落到
Set/Predicate/Option/List 的各自 bind 上——HOL 没有构造子类，
「单子接口」就是这样用语法+特设重载模拟的。

列表单子（非确定性遍历）：\<close>

ML \<open>writeln "==== 63 开始 ===="\<close>

value "do { x \<leftarrow> [1::nat, 2]; y \<leftarrow> [10, 20]; [x + y] }"

text \<open>输出 @{verbatim "[11, 21, 12, 22]"}：外层 x 先固定，内层 y 扫完
再换 x——列表 bind 就是 concat ∘ map。option 单子（短路失败）：\<close>

value "do { x \<leftarrow> Some (1::nat); y \<leftarrow> Some 2; Some (x + y) }"
value "do { x \<leftarrow> Some (1::nat); y \<leftarrow> None; Some (x + y) }"

text \<open>分别得 @{verbatim "Some 3"} 与 @{verbatim "None"}——任何一步
@{const None} 整体 @{const None}。@{verbatim "let x = t"} 行在 do 块里
是纯语法糖（翻译成 @{const Let}，不进 bind）。\<close>

section \<open>63.2 State_Monad：显式状态线程\<close>

text \<open>@{theory "HOL-Library.State_Monad"} 是教科书状态单子：
@{verbatim "datatype ('s, 'a) state = State (run_state: 's \<Rightarrow> 'a \<times> 's')"}。
组合子都是 qualified 名：@{const State_Monad.return}、
@{const State_Monad.bind}（已 adhoc_overloading 进 do 语法）、
@{const State_Monad.get}（取状态为值）、@{const State_Monad.set}
（覆盖状态）、@{const State_Monad.update}（函数式改写）。
三条单子律已注册 simp：@{thm State_Monad.bind_left_identity [no_vars]}、
@{thm State_Monad.bind_right_identity [no_vars]}、
@{thm State_Monad.bind_assoc [no_vars]}。一个计数器：\<close>

definition tick :: "(nat, nat) state" where
  "tick = do {
     n \<leftarrow> State_Monad.get;
     State_Monad.set (n + 1);
     State_Monad.return n
   }"

value "run_state tick 5"
value "run_state (do { a \<leftarrow> tick; b \<leftarrow> tick; State_Monad.return (a + b) }) 0"

text \<open>第一行 @{verbatim "(5, 6)"}：取出旧值 5 作返回值，状态变 6。
第二行 @{verbatim "(1, 2)"}：两次 tick 依次得 0、1（和为 1），
状态走两步到 2——状态线程的顺序性一目了然。

批量遍历用 @{const State_Monad.traverse_list}（单子版 map，
保持顺序、逐元素穿状态）。做一个「前缀和」遍历：\<close>

value "run_state (State_Monad.traverse_list
  (%n. do { s \<leftarrow> State_Monad.get; State_Monad.set (s + n); State_Monad.return (s + n) })
  [1, 2, 3]) (0::nat)"

text \<open>输出 @{verbatim "([1, 3, 6], 6)"}：返回值是累计和列表，末态是
总和。@{const State_Monad.update} 一族还有 @{verbatim "mono_state"}
（状态单调性）引理族，验证「状态只增不减」类性质时直接可用。\<close>

lemma "run_state (State_Monad.update (%n::nat. n + 2)) 3 = ((), 5)"
  by (simp add: State_Monad.update_def)

section \<open>63.3 Open_State_Syntax：不包装的「开」状态单子\<close>

text \<open>@{theory "HOL-Library.Open_State_Syntax"} 回答一个设计问题：
状态单子真的需要 @{typ "('s, 'a) state"} 这个包装类型吗？不需要——
状态变换可以直接是函数 @{typ "'s \<Rightarrow> 'a \<times> 's"}。这就是「开」单子：
没有类型构造子封住状态，组合子直接是 Main 的 @{const scomp}
（@{term "(f \<circ>\<rightarrow> g) s = (let (x, s') = f s in g x s')"}，串联
「带产出的变换」）与 @{const fcomp}（@{term "f \<circ>> g"}，正向
复合，纯变换）。记法是 @{verbatim "exec { ... }"} 块（与 do 平行，
但底层是 scomp/fcomp）：\<close>

definition bump :: "nat \<Rightarrow> nat \<times> nat" where
  "bump s = (s, s + 1)"

value "(exec { n \<leftarrow> bump; Pair (n * 10) }) 5"
value "(exec { n \<leftarrow> bump; m \<leftarrow> bump; Pair (n + m) }) 0"

text \<open>第一行 @{verbatim "(50, 6)"}（取出 5，乘 10，状态变 6）；
第二行 @{verbatim "(1, 2)"}。单子律在组合子层面：
@{verbatim "Pair_scomp"}（左单位）、@{verbatim "scomp_Pair"}
（右单位）、@{verbatim "scomp_scomp"}（结合）——
@{verbatim "monad_simp"}/@{verbatim "monad_collapse"} 两组引理集
就是规范化单子表达式的标准 simp 配置。与 63.2 的取舍：
包装版（state 类型）有类型安全与独立推理工具；开版零开销、
状态类型可在串联中改变，但没有「这是一个单子」的类型标记。\<close>

section \<open>63.4 Function_Algebras：函数的逐点代数\<close>

text \<open>@{theory "HOL-Library.Function_Algebras"} 只有一组实例：
函数类型逐点继承值域的代数结构——@{term "f + g"} 就是
@{term "%x. f x + g x"}，@{term "0"} 是常零函数，乘法、
@{term "1"} 同理（@{thm plus_fun_apply [no_vars]} 一族 simp）。\<close>

value "((%n::nat. n) + (%n. 2 * n)) 3"
value "((1 :: nat \<Rightarrow> nat) + (%n. n * n)) 5"

text \<open>输出 @{verbatim "9"} 与 @{verbatim "26"}。这理论改变了
函数上 @{verbatim "+"} 的**含义**——导入前 @{term "f + g"} 对函数
类型根本不适型，导入后默认识别为逐点加。这是全局实例（坑 5）。\<close>

section \<open>63.5 Uprod：无序对与交换函数\<close>

text \<open>@{theory "HOL-Library.Uprod"} 是商类型（第 29 章）的精致样本：
@{typ "'a uprod"} 是 @{typ "'a \<times> 'a"} 模去「交换相等」
（@{const eq_upair}）的商——无序对。构造子 @{const Upair}：
\<close>

lemma "Upair 1 2 = Upair (2::nat) 1"
  by simp

value "proper_uprod (Upair (1::nat) 2)"
value "proper_uprod (Upair (1::nat) 1)"

text \<open>@{const proper_uprod} 判定两分量相异。消去无序对需要
「结果与顺序无关」的函数——这就是配套类型
@{typ "('a, 'b) commute"}（typedef 收进满足
@{term "\<forall>x y. f x y = f y x"} 的二元函数），@{const case_uprod}
只接受 commute：\<close>

lift_definition addc :: "(nat, nat) commute" is "(+)" by auto

value "case_uprod addc (Upair 3 4)"

lemma "case_uprod addc (Upair 3 4) = case_uprod addc (Upair 4 3)"
  by (simp add: addc.rep_eq)

text \<open>如果把非交换函数塞进 case_uprod，类型层直接拒绝（typedef
的承载集挡住）——「对称性义务」被类型系统强制执行，这是
Uprod 比 @{typ "'a \<times> 'a"} 加注释强的地方。\<close>

section \<open>63.6 坑位清单（实测）\<close>

text \<open>
1. do 记法依赖 @{verbatim "adhoc_overloading"} 按类型解析 bind；
   自己的单子类型要写自己的 bind 并注册重载（照抄
   @{theory "HOL-Library.State_Monad"} 的一行
   @{verbatim "adhoc_overloading Monad_Syntax.bind"} 右接你的 bind 常量）。
2. @{const State_Monad.return}/@{const State_Monad.get}/
   @{const State_Monad.set}/@{const State_Monad.update} 是
   qualified 名，必须带前缀；@{const State_Monad.traverse_list}
   不 qualified，裸名可用。
3. @{verbatim "exec { ... }"} 与 @{verbatim "do { ... }"} 是两套
   独立语法（scomp/fcomp vs bind）；exec 块里没有
   @{verbatim "return"} 缩写，收尾用 @{const Pair}。
4. 单子律三件套已是 simp：证明里不用手工搬
   @{verbatim "bind_assoc"}；但反过来，化简器会把你的 do 链
   右结合化，打印形态与书写不同（别慌，语义一致）。
5. @{theory "HOL-Library.Function_Algebras"} 是全局实例：
   导入后函数类型的 @{verbatim "+"}/@{verbatim "*"}/0/1 全部
   变成逐点运算。若你的理论里函数上别有「加」（如逐点之外
   的复合），会撞车。
6. @{const State_Monad.bind} 的 run_state 等式是 simp
   （@{thm State_Monad.run_state_bind [no_vars]}），证明状态单子
   性质的标准开局是 @{verbatim "simp add: run_state_..."} 一族
   或干脆用各自的 @{verbatim "*_def"} 定义展开成函数等式。
7. @{typ "('a, 'b) commute"} 的成员义务是
   @{term "\<forall>x y. f x y = f y x"}；lift_definition 新 commute
   时 side condition 就是这条，加法乘法 @{verbatim "by auto"}，
   自定义运算先想好对称性。
8. @{const Upair} 的相等规则 @{thm Upair_inject [no_vars]} 是
   simp：两分支「正序或逆序相等」，写引理时别忘它有析取。
9. Monad_Syntax 的 @{verbatim "do"} 块优先级低（61），混在
   大表达式里要加括号；@{verbatim "m \<then> n"}（ASCII
   @{verbatim ">>"}）是「丢弃结果的 bind」。
10. @{const proper_uprod}/@{const case_uprod} 有 code 等式
    可求值；但 @{typ "'a uprod"} 的相等比较只在元素类型带
    @{class equal} 时可执行（商类型的日常）。
\<close>

ML \<open>writeln "==== 63 结束 ===="\<close>

end
