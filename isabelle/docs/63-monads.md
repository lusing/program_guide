# 63 · 单子两件套、函数逐点代数与无序对

对应示例：`../examples/lib/T63_monads.thy`（IsaTutLib 会话，依赖
`HOL-Library.State_Monad`、`Open_State_Syntax`、`Function_Algebras`、
`Uprod`）

HOL 没有构造子类（typeclass of kinds），写不出 Haskell 那种
「任意单子」的签名。HOL-Library 的答案是两条互补路线：语法层用
**特设重载**模拟（Monad_Syntax），语义层给两个具体状态单子
（封装的 State_Monad 与开放的 Open_State_Syntax）。本章另带两个
小而美的代数设施：函数的逐点代数（Function_Algebras）与无序对
（Uprod）。

## 63.1 Monad_Syntax：Haskell 式 do 记法

`Monad_Syntax` 只有一页纸，却给了全套 do 记法：一个待重载的
`Monad_Syntax.bind` 中缀（符号命令 `\<bind>`，ASCII `>>>=`），外加
`do { x <- m; ... }` 块语法（支持 `let x = t` 行——它翻译成
`Let`，不进 bind）。`bind` 是多态占位符，`adhoc_overloading`
按类型落到 Set/Predicate/Option/List 各自的 bind 上——「单子
接口」在 HOL 里就是这样用语法+重载模拟的。

列表单子（非确定性遍历）：

```isabelle
value "do { x ← [1::nat, 2]; y ← [10, 20]; [x + y] }"
  (* "[11, 21, 12, 22]" — 外层 x 先固定，内层 y 扫完再换 x *)
```

列表 bind 就是 concat ∘ map。option 单子（短路失败）：

```isabelle
value "do { x ← Some (1::nat); y ← Some 2; Some (x + y) }"   (* Some 3 *)
value "do { x ← Some (1::nat); y ← None; Some (x + y) }"     (* None *)
```

任何一步 `None` 整体 `None`——异常传播的免费实现。

## 63.2 State_Monad：显式状态线程

`State_Monad` 是教科书状态单子：

```isabelle
datatype ('s, 'a) state = State (run_state: "'s ⇒ 'a × 's")
```

组合子是 qualified 名：`State_Monad.return`、`State_Monad.bind`
（已注册进 do 语法）、`State_Monad.get`（取状态为值）、
`State_Monad.set`（覆盖）、`State_Monad.update`（函数式改写）。
三条单子律已注册 simp：`bind_left_identity`、`bind_right_identity`、
`bind_assoc`——写证明时单子链会被化简器自动右结合规范化。

一个计数器：

```isabelle
definition tick :: "(nat, nat) state" where
  "tick = do {
     n ← State_Monad.get;
     State_Monad.set (n + 1);
     State_Monad.return n
   }"

value "run_state tick 5"   (* (5, 6)：返回旧值 5，状态变 6 *)
value "run_state (do { a ← tick; b ← tick; State_Monad.return (a + b) }) 0"
  (* (1, 2)：两次依次得 0、1（和为 1），状态走两步到 2 *)
```

批量遍历用 `traverse_list`（单子版 map，保序、逐元素穿状态）。
做一个「前缀和」遍历：

```isabelle
value "run_state (State_Monad.traverse_list
  (λn. do { s ← State_Monad.get; State_Monad.set (s + n); State_Monad.return (s + n) })
  [1, 2, 3]) (0::nat)"
  (* "([1, 3, 6], 6)" — 返回值是累计和列表，末态是总和 *)
```

注意初态的 `(0::nat)` 标注不可省：整条链的类型由它钉住，否则
多态数字报 term_of/free dictionaries 错（59–62 章同款）。

`update` 一族还配了 `mono_state`（状态单调性）引理组，验证
「状态只增不减」类性质时直接可用：

```isabelle
lemma "run_state (State_Monad.update (λn::nat. n + 2)) 3 = ((), 5)"
  by (simp add: State_Monad.update_def)
```

（`update` 是 qualified 定义，它的定义引理名是
`State_Monad.update_def`——不在默认 simpset 里，要显式 add。）

## 63.3 Open_State_Syntax：不包装的「开」状态单子

`Open_State_Syntax` 回答一个设计问题：状态单子真的需要
`('s,'a) state` 这个包装类型吗？不需要——状态变换可以直接是
函数 `'s ⇒ 'a × 's`。这就是「开」单子：没有类型构造子封住
状态，组合子直接是 Main 的 `scomp`（`f ∘→ g`，串联带产出的
变换）与 `fcomp`（`f ∘> g`，正向复合，纯变换）。记法是
`exec { ... }` 块，与 do 平行但底层是 scomp/fcomp：

```isabelle
definition bump :: "nat ⇒ nat × nat" where
  "bump s = (s, s + 1)"

value "(exec { n ← bump; Pair (n * 10) }) 5"        (* (50, 6) *)
value "(exec { n ← bump; m ← bump; Pair (n + m) }) 0"  (* (1, 2) *)
```

注意两点：exec 块里**没有** `return` 缩写（那是封装版的组合子），
收尾用 `Pair`；`∘→`/`∘>` 记号默认关闭，要用得
`unbundle state_combinator_syntax`（本理论就这么做的）。

单子律在组合子层面：`Pair_scomp`（左单位）、`scomp_Pair`
（右单位）、`scomp_scomp`（结合）；`monad_simp`/
`monad_collapse` 两组引理集就是规范化单子表达式的标准 simp
配置。

取舍对照：封装版（state 类型）有类型安全、独立的选择子
（`run_state`）和谓词工具（`pred_state`）；开版零开销、状态类型
可在串联中改变，但「这是一个单子」只存在于语法约定里。

## 63.4 Function_Algebras：函数的逐点代数

`Function_Algebras` 只有一组实例：函数类型逐点继承值域的代数
结构——`f + g` 就是 `λx. f x + g x`，`0` 是常零函数，`*`、`1`
同理（`plus_fun_apply` 一族 simp 规则）：

```isabelle
value "((λn::nat. n) + (λn. 2 * n)) 3"        (* 9 *)
value "((1 :: nat ⇒ nat) + (λn. n * n)) 5"    (* 26 *)
```

这理论改变函数上 `+` 的**含义**：导入前 `f + g` 对函数类型不适
型，导入后默认识别为逐点加。全局实例，想清楚再导入（坑 5）。

## 63.5 Uprod：无序对与交换函数

`Uprod` 是商类型（第 29 章）的精致样本：`'a uprod` 是
`'a × 'a` 模去「交换相等」（`eq_upair`）的商——无序对。
构造子 `Upair`：

```isabelle
lemma "Upair 1 2 = Upair (2::nat) 1"
  by simp

value "proper_uprod (Upair (1::nat) 2)"   (* True  — 两分量相异 *)
value "proper_uprod (Upair (1::nat) 1)"   (* False *)
```

消去无序对需要「结果与顺序无关」的函数——配套类型
`('a,'b) commute`（typedef 收进满足 `∀x y. f x y = f y x` 的
二元函数），`case_uprod` 只接受 commute：

```isabelle
lift_definition addc :: "(nat, nat) commute" is "(+)" by auto

value "case_uprod addc (Upair 3 4)"   (* 7 *)

lemma "case_uprod addc (Upair 3 4) = case_uprod addc (Upair 4 3)"
  by (simp add: addc.rep_eq)
```

把非交换函数塞进 `case_uprod`，类型层直接拒绝（typedef 的承载
集挡住）——「对称性义务」被类型系统强制执行，这正是 Uprod
比 `'a × 'a` 加注释强的地方。图的边、双元素集合、对称关系
的载荷都是它的主场。

## 63.6 坑位清单（实测）

1. do 记法依赖 `adhoc_overloading` 按类型解析 bind；自己的
   单子类型要写自己的 bind 并照抄 State_Monad 的一行
   `adhoc_overloading Monad_Syntax.bind ⇌ …` 注册。
2. `State_Monad.return/get/set/update` 是 qualified 名，必须带
   前缀；`traverse_list` 不 qualified。`update` 的定义引理
   `State_Monad.update_def` 不在默认 simpset，要显式 add。
3. `exec {…}` 与 `do {…}` 是两套独立语法（scomp/fcomp vs
   bind）；exec 块里没有 `return`，收尾用 `Pair`；`∘→`/`∘>`
   记号要 `unbundle state_combinator_syntax` 才有。
4. 单子律三件套已是 simp——化简器会把 do 链自动右结合化，
   打印形态与书写不同，别慌，语义一致。
5. `Function_Algebras` 是全局实例：导入后函数类型的
   `+`/`*`/0/1 全变逐点运算，与既有「函数复合」语义撞车时
   别导入。
6. 状态单子的 `value` 要给**初态标类型**（`… (0::nat)`），
   否则多态数字卡在 term_of 推导。
7. `('a,'b) commute` 的成员义务是 `∀x y. f x y = f y x`；
   lift_definition 新 commute 时 side condition 就是这条，
   加法乘法 `by auto`，自定义运算先想对称性。
8. `Upair` 的相等规则 `Upair_inject` 是 simp，含「正序或逆序」
   析取——拿它证不等时两条支路都要堵。
9. do 块优先级低（61），混在大表达式里要加括号；`m ≫ n`
   （ASCII `>>`）是丢弃结果的 bind。
10. `proper_uprod`/`case_uprod` 有 code 等式可求值；`'a uprod`
    的相等比较要元素类型带 `equal`（商类型的日常）。

## 63.7 与其他章的接口

- 第 26 章共归：单子是 codatatype 流的「对偶」组织方式之一，
  64 章流的 sfilter/smap 与列表单子的 bind 结构同源。
- 第 28/29 章 typedef 与商类型：`('a,'b) commute` 与
  `'a uprod` 是两条流水线的教学样本（前者收对称函数、后者
  模交换）。
- 第 57 章 fmap/Mapping：Mapping 是「封装版」思路（藏表示），
  与本章 State_Monad 同源；Monad_Syntax 的 option/list bind
  在 fmap 的 `fmlookup` 链式查找里可直接用。
- 第 62 章：`countable` 的 list 实例与列表单子共同构成有限
  枚举生态。
