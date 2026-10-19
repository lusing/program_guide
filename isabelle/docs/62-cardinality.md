# 62 · 可数与基数：Nat_Bijection、Equipollence、Countable、Cardinality、Infinite_Set

对应示例：`../examples/lib/T62_cardinality.thy`（IsaTutLib 会话，
依赖 `HOL-Library.Equipollence`、`Cardinality`、`Nat_Bijection`、
`Infinite_Set`、`Countable`）

「两个集合一样大吗」在 Isabelle 里有四套互相咬合的语言：编码
（可执行的双射）、等势关系（`≈`/`≲`/`≺`）、可数性（类型类与
集合谓词）、类型基数算术（`CARD('a)`）。本章一次讲清，外加
「无穷多次」的一阶写法。

## 62.1 Nat_Bijection：nat 与 nat×nat 互相编码

「nat 与 nat × nat 等势」的可执行证据是 Cantor 配对函数。
`prod_encode` 用三角数 `triangle n = n * Suc n div 2` 做锯齿
编号——公式是 `(m, n) ↦ triangle (m+n) + m`（注意：加的是
**第一**分量 m，所以编码不对称）；`prod_decode` 逆向解码。
互逆是 simp 规则：

```isabelle
value "prod_encode (2, 3)"    (* 17：triangle 5 = 15，加 m = 2 *)
value "prod_decode 17"        (* (2, 3) *)

lemma "prod_decode (prod_encode (m, n)) = (m, n)"
  by simp
```

同一条流水线还有集合编码：`set_encode A = sum ((^) 2) A` 把
**有限** nat 集编成二进制位串（无穷集约定返回 0——静默约定，
用前先证 `finite`）：

```isabelle
lemma "set_encode {0::nat, 2} = 5"   (* 2^0 + 2^2 *)
  by (simp add: set_encode_def)
```

这些编码是「可枚举类型」传统的始祖：编码存在，可数性就有依据。

## 62.2 Equipollence：等势、不弱于、严格小于

`Equipollence` 给出基数的**关系**形式，三个记号一次到位：

- `A ≈ B`（`eqpoll`）：存在双射 `bij_betw f A B`；
- `A ≲ B`（`lepoll`）：存在 A 到 B 的单射；
- `A ≺ B`（`lesspoll`）：可单射但不同势。

有限集上等势就是基数相等——`eqpoll_iff_card` 的两个 `finite`
前提化简器能自动担当（`simp add:` 即可，条件规则的侧前提由
simp 递归解决）：

```isabelle
lemma "{2, 4, 6::nat} ≈ {1, 3, 5::nat}"
  by (simp add: eqpoll_iff_card)

lemma "({0..<5}::nat set) ≲ {0..<7::nat}"
  by (auto intro: subset_imp_lepoll)
```

两条重量级定理直接可用。**Schröder–Bernstein**（互相单射即
等势）在这里是 `lepoll_antisym`，一行 rule 调用：

```isabelle
lemma Schroeder_Bernstein_use: "A ≲ B ⟹ B ≲ A ⟹ A ≈ B"
  by (rule lepoll_antisym)
```

**Cantor**（任何集合严格小于其幂集）在 Main 里是
`Cantors_theorem: ∄f. f ` A = Pow A`（「没有满射」形态）。
「nat 的幂集不可数」一条结构化证明——等势给出双射，双射的
像覆盖幂集，矛盾：

```isabelle
lemma cantor_nat: "¬ (UNIV :: nat set) ≈ Pow (UNIV :: nat set)"
proof
  assume "(UNIV :: nat set) ≈ Pow (UNIV :: nat set)"
  then obtain f where f: "bij_betw f (UNIV :: nat set) (Pow (UNIV :: nat set))"
    unfolding eqpoll_def by blast
  then have "f ` UNIV = Pow (UNIV :: nat set)"
    by (simp add: bij_betw_def)
  with Cantors_theorem show False by blast
qed
```

注意 `obtain` 一行里两侧类型都标了 `nat`：等势允许不同类型
（`'a set ⇒ 'b set`），不钉死的话 `Pow UNIV` 的元素类型停在
多态，后面 `Cantors_theorem` 就接不上。

还有一个常用判据：`infinite_le_lepoll`——集合无穷当且仅当
nat 能单射进去（`UNIV::nat set ≲ A`），「无穷」与「可数无穷
最小」的形式化。

## 62.3 Countable：可数的类型与集合

两个层次别混：`Countable` 是**类型类** `countable`（存在到
nat 的单射；`to_nat`/`from_nat` 由此定义）；`Countable_Set`
是**集合谓词** `countable`。类实例把可数性一路传给构造器：
nat、int、rat、积、和、option、list 全部可数（函数类型在
定义域 `finite`、值域可数时可数）。桥接写法是对 UNIV 用
集合谓词：

```isabelle
lemma "countable (UNIV :: (nat × nat) set)"   by simp
lemma "countable (UNIV :: nat list set)"      by simp
```

`to_nat` 是选择算子挑出来的单射（`SOME f. inj f`），所以它的
具体值**不可计算**——能用的只有 `inj_to_nat` 与
`surj_from_nat` 两条抽象性质，不要指望 `value`。

## 62.4 Cardinality：类型的基数算术

`Cardinality` 把「类型的大小」写成 `CARD('a)`（即
`card UNIV`，无穷类型约定为 0），并给出构造器上的算术：

```text
CARD('a × 'b)     = CARD('a) * CARD('b)        （card_prod）
CARD('a + 'b)     = CARD('a) + CARD('b)        （card_sum）
CARD('a option)   = CARD('a) + 1               （card_option）
CARD('a set)      = 2 ^ CARD('a)               （card_set）
CARD('a ⇒ 'b)     = CARD('b) ^ CARD('a)        （card_fun）
```

```isabelle
lemma "CARD(bool) = 2"          by simp
lemma "CARD(bool × bool) = 4"   by simp
lemma "CARD(bool option) = 3"   by simp
lemma "CARD(nat) = 0"           by simp
```

「0 = 无穷」的约定（`card_nat`）让 `card_fun` 这类公式对所有
类型统一成立、不用分情形——但读定理时注意 0 的双重含义。
另有 `card2` 类（至少两个元素）支撑 `one_less_card` 一类
「非平凡」前提。

## 62.5 Infinite_Set：「无穷多次」的一阶写法

`Infinite_Set` 提供两个 binder（ Main 的 Filter 里定义，本理论
汇集引理）：`∃⇩∞x. P x`（`Inf_many`，满足 P 的 x 组成无穷集）
与 `∀⇩∞x. P x`（`Alm_all`，例外只有有限个）。它们是渐近推理的
日常词汇——64 章 ω 词的 limit 集（「出现无穷多次的字母」）就
建立在 `∃⇩∞` 上：

```isabelle
lemma "∃⇩∞n::nat. True"
  by (simp add: Inf_many_def)

lemma "∀⇩∞n::nat. n > 100"
proof -
  have "{n::nat. ¬ n > 100} = {..100}" by auto
  then show ?thesis by (simp add: Alm_all_def Inf_many_def)
qed
```

证明模式：`∃⇩∞` 展开成 `infinite` 后交给无穷 simp 规则；
`∀⇩∞` 展开成「补集有限」，先把例外集算成显式区间再化简。
ASCII 写法是 `INFM` / `MOST`（老代码里还能见到 `Inf_many`/
`Alm_all` 名字）。

## 62.6 坑位清单（实测）

1. **「可数」有两层**：类型类 `countable`（Countable.thy）与
   集合谓词 `countable`（Countable_Set.thy）；`countable UNIV`
   是桥。
2. **`to_nat`/`from_nat` 不可计算**（`SOME` 挑的）；只有
   `inj_to_nat`/`surj_from_nat` 可用。
3. **`CARD('a)` 对无穷类型是 0**，不是「无定义」——算术公式
   因此无分支，但 0 有双重含义。
4. `≈`/`≲`/`≺` 是 infixl 50，与普通 `≤` 不冲突但视觉易混，
   读别人的理论先确认 imports 了 Equipollence。
5. **`≈` 的两侧类型独立**（`'a set ⇒ 'b set`）：集合写法
   `{1, 3, 5}` 里的数字要逐个或整体标注，否则停在多态 `'a`，
   `card` 算不动（本章实测两连撞）。
6. 等势证明入口：有限用 `eqpoll_iff_card` 化归基数；无穷造
   双射（`eqpoll_def`）或 Schröder–Bernstein 两边单射。
7. Cantor 在 Main 里是 `Cantors_theorem`（「没有满射」形态）；
   与等势语言的转换经 `bij_betw_def` 的像等式。
8. **`set_encode` 对无穷集静默返回 0**（约定），用前先
   `finite`。
9. `prod_encode (m, n) = triangle (m+n) + m`——加的是**第一**
   分量，编码不对称，`prod_encode (m, n) ≠ prod_encode (n, m)`
   一般成立，别凭印象交换。
10. 文档反引号纪律（本章三连撞）：裸 binder `∃⇩∞`、`SOME`
    这类**关键字**不能进 `@{term}`（不是完整项）；写
    `@{const Inf_many}`/`@{verbatim SOME}`。另外
    `@{verbatim}` 字符串里放不下 `\<...>` 转义，需要符号的
    地方退到 ASCII 或改写句子。

## 62.7 与其他章的接口

- 第 25 章类型类：`countable` 类实例链是它的标准应用；
  `card2` 同理。
- 第 14 章集合：`eqpoll`/`lepoll` 的展开终点是
  `bij_betw`/`inj_on` 的集合语言。
- 第 61 章扩展数系：`enat` 有 `countable` 实例；
  「Sup 无穷集 = ∞」与 `infinite` 谓词互译。
- 第 63 章单子：`Countable` 的 `list` 实例与单子 bind 共同构成
  「有限枚举」生态。
- 第 64 章 ω 词：`limit` 集定义在 `∃⇩∞` 上。
