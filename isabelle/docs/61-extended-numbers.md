# 61 · 扩展数系：enat、ereal、ennreal 与非正整数集

对应示例：`../examples/lib/T61_extended.thy`（IsaTutLib 会话，依赖
`HOL-Library.Extended_Nonnegative_Real`——它 transitively 带出
`Extended_Real` 与 `Extended_Nat`——和 `HOL-Library.Nonpos_Ints`）

分析学里「无穷大」不是修辞，是值。HOL-Library 提供三种扩展数系，
各自把无穷塞进类型的方式、算术约定都不一样。本章把三个类型的
构造、算术规则和「设计决定」逐一对照，外加一个小品
`Nonpos_Ints`。

## 61.1 enat：nat 加一个无穷点

`Extended_Nat` 把 `nat option` 包装成 `enat`：`enat n` 是有限值，
`∞` 对应 `None`。序的安置和第 60 章的 `Option_ord` **相反**：
那里 `None` 垫底，这里 `∞` 是顶——一切有限值都小于它。
后继 `eSuc` 在无穷处自吸收，投影 `the_enat` 取回有限值：

```isabelle
value "∞ + (1::enat)"     (* ∞   — 加法逢无穷吸收 *)
value "(0::enat) * ∞"     (* 0   — 测度论惯例硬编码 *)
value "∞ * (2::enat)"     (* ∞ *)
value "eSuc ∞"            (* ∞ *)
value "the_enat (5::enat)"  (* 5 :: nat *)

lemma "(3::enat) < ∞"  by simp
```

数字字面量直接可用：`enat` 注册了 coercion，`5 :: enat` 就是
`enat 5`（`numeral_eq_enat` 一族处理）。

`enat` 还是完备格（底 0、顶 ∞），`Sup` 的定义把「无穷」用足：

```text
Sup_enat_def: Sup A = (if A = {} then 0 else if finite A then Max A else ∞)
```

空集给 0、有限集给最大元、**无穷集直接给 ∞**——这正是扩展自然数
存在的理由：无穷求和、无穷迭代次数都有值可读。有限情形一行 simp：

```isabelle
lemma "Sup {0, 1, 2::enat} = 2"
  by (simp add: Sup_enat_def)
```

## 61.2 ereal：带正负号的两个无穷

`Extended_Real` 的 `ereal` 是 datatype，三个构造子：
`ereal real | PInfty | MInfty`，即实数加 `∞` 与 `-∞` 两个端点。
与 enat 的本质差别是**符号**。加法是同号吸收，乘法是符号规则
驱动（正乘 ∞ 得 ∞，负乘得 -∞，0 乘任何无穷得 0）：

```isabelle
value "∞ + (-∞::ereal)"      (* ∞  *)
value "(-∞::ereal) + ∞"      (* ∞  — 两个方向同答 *)
value "(0::ereal) * ∞"       (* ereal 0 *)
value "ereal 2 * ∞"          (* ∞  *)
value "ereal (-2) * ∞"       (* -∞ *)
value "|(-∞::ereal)|"        (* ∞  *)

lemma "ereal 2 < (∞::ereal)"  by simp
```

前两行是本章最重要的提醒：`∞ + -∞` **不是未定义**，定义按模式
匹配硬性规定为 `∞`——这是库的设计决定，不是定理。代价是
ereal 不成域：∞ 没有加法逆元，消去律要带前提：

```text
ereal_add_cancel_left: a ≠ -∞ ⟹ (a + b = a + c) ⟷ (a = ∞ ∨ b = c)
```

写 ereal 证明的肌肉记忆是三分情形
`cases rule: ereal2_cases`（`ereal r` / `∞` / `-∞`），库里的实例
证明全部这么过；对应的量词拆分规则是 `ereal_all_split` 与
`ereal_ex_split`。

## 61.3 ennreal：测度论的工作马

`Extended_Nonnegative_Real` 用 typedef 把 ereal 的非负半轴收进
`ennreal`：`enn2ereal` 投影出去，`e2ennreal` 进来（负数截到 0，
且注册了 coercion）。它是测度与积分的值域（第 46 章的
HOL-Analysis 全线用它）：非负、含 ∞（此处 ∞ 就是顶）、完备线序。

减法是截断的——底层就是 `max 0 (a - b)`：

```isabelle
lemma "ennreal 5 - ennreal 8 = (0::ennreal)"
  by (simp del: ennreal_numeral add: ennreal_minus ennreal_eq_0_iff)

lemma "ennreal 8 - ennreal 5 = ennreal 3"
  by (simp del: ennreal_numeral add: ennreal_minus)

lemma "(∞::ennreal) - ∞ = ∞"
  by transfer' simp
```

三条引理的证明形态本身就是教学点（详见坑位清单 6）：ennreal
不可执行、等式不 transfer、数值减法被 `ennreal_numeral` 抢先
改写，必须 `simp del:` 掉它再放行 `ennreal_minus`。

第三行再次看到「扩展数系处处是设计决定」：ennreal 的
`∞ - ∞ = ∞`（ereal 层 `∞ + -∞ = ∞` 再截断）。牺牲消去律换
「处处有定义」，换来完备格运算畅通——测度论里你不会想在每个
测度差上挂有限性前提。

## 61.4 Nonpos_Ints：非正整数集

小品一个：任意环上（经 `of_int` 嵌入）的非正整数集 `ℤ≤0`，
与 Main 的 `ℕ`/`ℤ` 平行。标准用途是 Γ 函数的极点集——非正整数
恰好是 Γ 的极点。成员判定全是现成 simp/intro 规则：

```isabelle
lemma "(-2 :: real) ∈ ℤ≤0"   by simp
lemma "(1 :: real) ∉ ℤ≤0"    by simp

lemma x_nonpos: "x ∈ ℤ≤0 ⟹ x ≤ (0 :: 'a :: linordered_idom)"
  by (rule nonpos_Ints_nonpos)
```

注意 `ℤ≤0` 是**集合**不是类型——成员命题直接用，不需要 typedef。

## 61.5 坑位清单（实测）

1. **∞ 的位置看类型。** enat 的 ∞ 在顶上（序最大元），与 60 章
   `Option_ord` 里 `None` 垫底相反——两者底层都是
   `nat option`，序的解释不同。
2. **`0 * ∞ = 0` 是测度论惯例的硬编码**；期待「未定」语义的
   读者注意这不是 bug。enat 与 ereal/ennreal 都是这个约定。
3. **三个 ∞ 不是同一个常量**，是 `infinity` 类的多态常量；
   类型标注不清会停在多态、求值报 free dictionaries。符号名
   只有 `\<infinity>`——`\<infty>` 不存在（词法层直接拒）。
4. **`the_enat` 在 ∞ 上未定义**（落默认 0），证明里别拿它当
   安全的逆。
5. **ereal 不是域**：∞ 无加法逆，消去律一律带前提，乘法还有
   0 陷阱（`0 * ∞ = 0` 与符号规则并存）。
6. **ennreal 数值等式的证明通道是一串实测坑**：
   - ennreal 无 `equal` 实例，`by eval` 直接拒
     （not of sort equal）；
   - Complex_Main 在场时 `transfer`/`transfer'` 对 ennreal
     数值目标**静默不动**（目标原样返回，不等式也一样）；
   - `ennreal_numeral` 是 simp 规则，会抢先吃掉 `ennreal`
     包装使 `ennreal_minus` 匹配不上——所以数值减法要
     `simp del: ennreal_numeral add: ennreal_minus` 这套
     固定动作；∞ 参与的等式走 `transfer' simp`。
7. **`Sup` 对无穷 enat 集给 ∞。** 证 `Sup A = ∞` 的标准路径：
   先证 `infinite A` 再展开 `Sup_enat_def`。
8. **`ℤ≤0` 是集合不是类型**；想要类型自己 typedef（第 28 章）。
9. **coercion 链不可见**：`nat → enat`、`real → ereal`、
   `ereal → ennreal`（截断式）都注册了 coercion，打印看不到
   箭头，读定理签名时心里补上。
10. 三个理论都在 HOL-Library 会话；学它们的最终目的多半是
    读懂 HOL-Analysis（第 46 章）里测度/积分定理的签名——
    那里 ennreal 是默认值域。

## 61.6 与其他章的接口

- 第 28/29 章 typedef 与 Lifting：ennreal 是「typedef 非满射
  abs（e2ennreal 钳制）」的样本——这正是它等式不 transfer 的
  根源。
- 第 46 章 HOL-Analysis：ennreal 是测度论值域；本章的
  `∞ - ∞ = ∞` 等约定在积分定理里反复出现。
- 第 60 章 Option_ord：同一个 `nat option` 底座，两种序解释的
  对照样本。
- 第 62 章可数与基数：enat 的 `countable` 实例、
  「无穷集 Sup = ∞」与无限集判定互相呼应。
