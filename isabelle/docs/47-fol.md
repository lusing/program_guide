# 47 · FOL：一阶逻辑对象逻辑

对应示例：`../examples/fol/T47_fol.thy`（IsaFOL 会话，父堆 FOL）

> 参考：[Isabelle/FOL 库索引](https://dist.isabelle.cit.tum.de/dist/library/FOL/FOL/index.html)

## 47.1 一句话概括

Isabelle 是**逻辑框架**（第 56 章）：HOL 只是它最常用的一种对象逻辑。FOL 家族展示了 Isabelle 的核心设计哲学——**同一套推理内核，可以搭载不同的对象逻辑**。

FOL 会话包含两个理论：

- **`IFOL`**：直觉主义一阶逻辑（构造性，无排中律）
- **`FOL`**：IFOL + 经典公理（排中律、双非消去）

对 HOL 用户的价值：

1. 看清哪些定理依赖经典逻辑（`P ∨ ¬P` 在 HOL 里白给，在 IFOL 里**不存在**证明）
2. 手动做一遍自然演绎，理解 `auto` 在 HOL 里到底包办了哪些事
3. 体会 FOL 的语法与 HOL 的微妙差异（谓词类型、函数式应用、可用工具）

## 47.2 FOL 的类型系统

FOL 没有 HOL 的丰富类型系统。只有两种类型：

- **`o`**：命题类型（真值）
- **`'a ⇒ o`**：谓词类型（从个体到真值的函数）

个体变量用类型变量 `'a` 表示（多态），没有 `i` 类型（老教程里的 `i` 在 Isabelle2026 里已经不存在，实测报 `Undefined type name`）。

声明谓词变量的正确写法：

```isabelle
fixes P Q :: "'a ⇒ o"
```

这意味着 `P` 和 `Q` 是从任意类型 `'a` 到命题 `o` 的函数。写 `P(x)` 时 `x` 的类型自动推断为 `'a`。

## 47.3 合取（conjunction）

合取 `P ∧ Q` 有三条核心规则：

- **`conjI`**：引入——从 `P` 和 `Q` 得到 `P ∧ Q`
- **`conjunct1`**：消去左——从 `P ∧ Q` 得到 `P`
- **`conjunct2`**：消去右——从 `P ∧ Q` 得到 `Q`

```isabelle
lemma conj_intro_demo:
  assumes "P" and "Q"
  shows "P ∧ Q"
  using assms by blast

lemma conj_elim_left_demo:
  assumes "P ∧ Q"
  shows "P"
  using assms by (rule conjunct1)

lemma conj_elim_right_demo:
  assumes "P ∧ Q"
  shows "Q"
  using assms by (rule conjunct2)
```

`conjI` 是最基础的引入规则：两个独立的命题合在一起。`conjunct1` 和 `conjunct2` 是投影——从合取中提取左/右分量。

合取的消除规则 `conjE` 允许同时解构两个分量：

```isabelle
lemma conjE_demo:
  assumes "P ∧ Q" and "P ⟹ Q ⟹ R"
  shows "R"
  using assms by (rule conjE)
```

`conjE` 把 `P ∧ Q` 拆成两个独立的假设 `P` 和 `Q`，然后在一个同时拥有这两个假设的子目标里继续证明。

**合取交换律**——用 Isar 手动证一遍：

```isabelle
lemma conj_comm: "P ∧ Q ⟷ Q ∧ P"
proof
  assume "P ∧ Q"
  then have "P" by (rule conjunct1)
  moreover from ‹P ∧ Q› have "Q" by (rule conjunct2)
  ultimately show "Q ∧ P" by blast
next
  assume "Q ∧ P"
  then have "Q" by (rule conjunct1)
  moreover from ‹Q ∧ P› have "P" by (rule conjunct2)
  ultimately show "P ∧ Q" by blast
qed
```

`proof` 开始一个 Isar 证明。`⟷` 的引入需要证两个方向（`proof` 默认用 `iffI`），所以有两个子目标。第一个子目标：假设 `P ∧ Q`，用 `conjunct1` 和 `conjunct2` 提取分量，再用 `blast` 组合成 `Q ∧ P`。第二个子目标对称。

当然，`blast` 一步就能完成：

```isabelle
lemma conj_comm_auto: "P ∧ Q ⟷ Q ∧ P"
  by blast
```

## 47.4 析取（disjunction）

析取 `P ∨ Q` 有引入和消除规则：

- **`disjI1`**：从左引入——`P ⟹ P ∨ Q`
- **`disjI2`**：从右引入——`Q ⟹ P ∨ Q`
- **`disjE`**：消除——从 `P ∨ Q`、`P ⟹ R`、`Q ⟹ R` 得到 `R`

```isabelle
lemma disj_intro_left: "P ⟹ P ∨ Q"
  by (rule disjI1)

lemma disj_intro_right: "Q ⟹ P ∨ Q"
  by (rule disjI2)

lemma disj_elim_demo:
  assumes "P ∨ Q" and "P ⟹ R" and "Q ⟹ R"
  shows "R"
  using assms by (rule disjE)
```

`disjI1` 和 `disjI2` 反映了析取的非对称性：从左引入和从右引入是不同的规则。`disjE` 是分类讨论：如果 `P ∨ Q` 成立，且两种情况都能推出 `R`，则 `R` 成立。

**经典析取引入** `disjCI`：若 `¬Q ⟹ P` 则 `P ∨ Q`。

```isabelle
thm disjCI
```

输出：`(¬Q ⟹ P) ⟹ P ∨ Q`

这条规则依赖经典逻辑——在 IFOL 里不可用。直觉主义逻辑不接受这种"反证式"的析取引入。

## 47.5 蕴含（implication）

蕴含 `P ⟶ Q` 的核心规则：

- **`impI`**：引入——假设 `P` 证 `Q`，则得到 `P ⟶ Q`
- **`mp`**（Modus Ponens）：消去——从 `P ⟶ Q` 和 `P` 得到 `Q`

```isabelle
lemma imp_reflexive: "P ⟶ P"
  by (rule impI)

lemma mp_demo:
  assumes "P ⟶ Q" and "P"
  shows "Q"
  using assms by (rule mp)
```

`impI` 是蕴含的引入规则：要证 `P ⟶ Q`，就假设 `P` 然后证 `Q`。这是自然演绎的核心模式——把"如果…那么…"转化为"假设…证…"。

`mp` 是最基本的推理规则：从 `P ⟶ Q` 和 `P` 推出 `Q`。

**反向 Modus Ponens** `rev_mp`：前提顺序相反：

```isabelle
lemma rev_mp_demo:
  assumes "P" and "P ⟶ Q"
  shows "Q"
  using assms by (rule rev_mp)
```

`rev_mp` 和 `mp` 的区别只是前提顺序。`mp` 先给蕴含式再给前件，`rev_mp` 先给前件再给蕴含式。

**蕴含的消除规则** `impE` 允许在证明中展开：

```isabelle
lemma impE_demo:
  assumes "P ⟶ Q" and "P" and "Q ⟹ R"
  shows "R"
  using assms by (rule impE)
```

`impE` 把 `P ⟶ Q` 和 `P` 组合得到 `Q`，然后在 `Q ⟹ R` 的假设下完成证明。

**蕴含的自反性和传递性**：

```isabelle
thm imp_refl
```

输出：`P ⟶ P`

```isabelle
lemma imp_trans:
  assumes "P ⟶ Q" and "Q ⟶ R"
  shows "P ⟶ R"
  using assms by blast
```

## 47.6 否定（negation）

FOL 里 `¬P` 定义为 `P ⟶ False`（`not_def`）。这意味着否定规则本质上就是蕴含规则。

核心规则：

- **`notI`**：引入——假设 `P` 推出 `False`，则 `¬P`
- **`notE`**：消除——从 `¬P` 和 `P` 得到任意结论

```isabelle
lemma not_intro_demo:
  assumes "P ⟹ False"
  shows "¬P"
  using assms by (rule notI)

lemma not_elim_demo:
  assumes "¬P" and "P"
  shows "R"
  using assms by (rule notE)
```

`notI` 是反证法的直觉主义版本：如果假设 `P` 导致矛盾（`False`），则 `¬P` 成立。这在直觉主义和经典逻辑里都可用。

`notE` 是爆炸原理的变体：从 `¬P`（即 `P ⟶ False`）和 `P`，用 `mp` 得到 `False`，然后从 `False` 推出任意 `R`（`FalseE`）。

**从 `False` 可以推出任意命题**（爆炸原理）：

```isabelle
lemma false_elim: "False ⟹ P"
  by (rule FalseE)
```

`FalseE` 是 `False` 的消除规则——从矛盾可以推出任何东西。

**经典反证法** `ccontr`：若 `¬P ⟹ False` 则 `P`。

```isabelle
lemma ccontr_demo:
  assumes "¬P ⟹ False"
  shows "P"
  using assms by (rule ccontr)
```

`ccontr`（contradiction）是经典逻辑的标志性规则：如果假设 `¬P` 导致矛盾，则 `P` 成立。注意这与 `notI` 不同——`notI` 从 `P ⟹ False` 得到 `¬P`，`ccontr` 从 `¬P ⟹ False` 得到 `P`。后者依赖排中律，在直觉主义逻辑里不可用。

**经典双非消去** `notnotD`：`¬¬P ⟹ P`：

```isabelle
lemma notnotD_demo: "¬¬P ⟹ P"
  by (rule notnotD)
```

在直觉主义逻辑里，`P ⟹ ¬¬P` 可证（双非引入），但反向 `¬¬P ⟹ P` 不可证。经典逻辑接受双向。

## 47.7 双条件（biconditional）

`P ⟷ Q` 定义为 `(P ⟶ Q) ∧ (Q ⟶ P)`（`iff_def`）。

核心规则：

- **`iffI`**：引入——从 `P ⟹ Q` 和 `Q ⟹ P` 得到 `P ⟷ Q`
- **`iffD1`**：从左到右——从 `P ⟷ Q` 和 `P` 得到 `Q`
- **`iffD2`**：从右到左——从 `P ⟷ Q` 和 `Q` 得到 `P`

```isabelle
lemma iff_intro_demo:
  assumes "P ⟹ Q" and "Q ⟹ P"
  shows "P ⟷ Q"
  using assms by (rule iffI)

lemma iff_elim_lr_demo:
  assumes "P ⟷ Q" and "P"
  shows "Q"
  using assms by (rule iffD1)

lemma iff_elim_rl_demo:
  assumes "P ⟷ Q" and "Q"
  shows "P"
  using assms by (rule iffD2)
```

`iffI` 把双条件拆成两个方向的蕴含。`iffD1` 和 `iffD2` 分别从左到右和从右到左使用双条件。

**双条件的自反性、对称性、传递性**：

```isabelle
thm iff_refl
thm iff_sym
thm iff_trans
```

## 47.8 经典 vs 直觉主义：排中律

排中律 `P ∨ ¬P` 是经典逻辑的标志性定理。

```isabelle
lemma excluded_middle: "P ∨ ¬P"
  by blast
```

库中已有 `excluded_middle` 定理：

```isabelle
thm excluded_middle
```

输出：`¬P ∨ P`

**情形分解** `case_split`：若 `P ⟹ Q` 且 `¬P ⟹ Q` 则 `Q`：

```isabelle
lemma case_split_demo:
  assumes "P ⟹ Q" and "¬P ⟹ Q"
  shows "Q"
  using assms by (rule case_split)
```

`case_split` 是排中律的推理形式：不管 `P` 是否成立，`Q` 都成立，所以 `Q` 成立。

在 IFOL（直觉主义）里，排中律**不可证**——不是"难"，是逻辑上不存在证明。直觉主义语义要求构造性证据，而 `P ∨ ¬P` 没有统一的构造方法——你不能对任意命题 `P` 给出一个算法来决定它是真是假。

`iprover` 是直觉主义证明器，能证直觉主义有效式；`blast` 是经典表推演机，能证经典有效式。

**双非排中律** `¬¬(P ∨ ¬P)` 在直觉主义里可证：

```isabelle
lemma dn_dn_lem: "¬¬(P ∨ ¬P)"
  by iprover
```

虽然 `P ∨ ¬P` 本身在直觉主义里不可证，但"它不可证"这件事本身也不可证——即 `¬¬(P ∨ ¬P)` 成立。

## 47.9 全称量词

全称量词 `∀x. P(x)` 的核心规则：

- **`allI`**：引入——证 `P(x)` 对任意 `x` 成立
- **`spec`**：消去（实例化）——从 `∀x. P(x)` 得到 `P(t)`

```isabelle
lemma all_intro_demo:
  fixes P :: "'a ⇒ o"
  assumes "⋀x. P(x)"
  shows "∀x. P(x)"
  using assms by (rule allI)

lemma spec_demo:
  fixes P :: "'a ⇒ o"
  assumes "∀x. P(x)"
  shows "P(a)"
  using assms by (rule spec)
```

`allI` 用 Isabelle 的元量词 `⋀`（"对任意"）：如果对类型 `'a` 的每个元素 `x`，`P(x)` 都成立，则 `∀x. P(x)` 成立。注意 `fixes P :: "'a ⇒ o"` 声明了 `P` 是谓词。

`spec`（specialization）是全称消去：从 `∀x. P(x)` 可以实例化到任意项 `a`，得到 `P(a)`。

**更强大的全称消去** `allE`：

```isabelle
lemma allE_demo:
  fixes P :: "'a ⇒ o"
  assumes "∀x. P(x)" and "P(a) ⟹ Q"
  shows "Q"
  using assms by (rule allE)
```

`allE` 把 `∀x. P(x)` 实例化为 `P(a)`，然后在 `P(a) ⟹ Q` 的假设下完成证明。

**手动完成一个量词推理**：

```isabelle
lemma all_implies:
  fixes P Q :: "'a ⇒ o"
  assumes A: "∀x. P(x) ⟶ Q(x)" and B: "∀x. P(x)"
  shows "∀x. Q(x)"
proof (rule allI)
  fix x
  from A have "P(x) ⟶ Q(x)" by (rule spec)
  moreover from B have "P(x)" by (rule spec)
  ultimately show "Q(x)" by (rule mp)
qed
```

这是 HOL 里 `auto` 自动完成的推理，这里手动做一遍：

1. `proof (rule allI)`：用 `allI` 引入全称量词，子目标变成"对任意 `x`，`Q(x)`"
2. `fix x`：固定一个任意的 `x`
3. 从 `A` 用 `spec` 得到 `P(x) ⟶ Q(x)`
4. 从 `B` 用 `spec` 得到 `P(x)`
5. 用 `mp` 组合得到 `Q(x)`

**全称量词的分配律**：

```isabelle
lemma all_conj_distrib: "(∀x. P(x) ∧ Q(x)) ⟷ (∀x. P(x)) ∧ (∀x. Q(x))"
  by blast
```

## 47.10 存在量词

存在量词 `∃x. P(x)` 的核心规则：

- **`exI`**：引入——从 `P(t)` 得到 `∃x. P(x)`
- **`exE`**：消除——从 `∃x. P(x)` 和 `P(x) ⟹ Q`（`x` 不在 `Q` 中自由出现）得到 `Q`

```isabelle
lemma ex_intro_demo:
  fixes P :: "'a ⇒ o"
  assumes "P(a)"
  shows "∃x. P(x)"
  using assms by (rule exI)

lemma ex_elim_demo:
  fixes P :: "'a ⇒ o"
  assumes "∃x. P(x)" and "⋀x. P(x) ⟹ Q"
  shows "Q"
  using assms by (rule exE)
```

`exI` 是见证引入：找到一个具体的 `a` 满足 `P`，就证明存在性。

`exE` 是存在消去：已知存在某个 `x` 满足 `P`，且对任意这样的 `x` 都能推出 `Q`（`x` 不在 `Q` 中自由出现），则 `Q` 成立。

**存在量词的重命名**：

```isabelle
lemma ex_renaming:
  fixes P :: "'a ⇒ o"
  assumes "∃x. P(x)"
  shows "∃y. P(y)"
  using assms by blast
```

**经典存在引入** `exCI`：

```isabelle
thm exCI
```

输出：`(∀x. ¬P(x) ⟹ P(a)) ⟹ ∃x. P(x)`

若假设没有任何元素满足 `P` 能推出 `P(a)`，则存在元素满足 `P`。这依赖经典逻辑。

**存在量词的分配律**：

```isabelle
lemma ex_disj_distrib: "(∃x. P(x) ∨ Q(x)) ⟷ (∃x. P(x)) ∨ (∃x. Q(x))"
  by blast
```

## 47.11 唯一存在

唯一存在 `∃!x. P(x)` 定义为 `∃x. P(x) ∧ (∀y. P(y) ⟶ y = x)`（`ex1_def`）——存在一个满足 `P` 的元素，且任何满足 `P` 的元素都等于它。

**引入规则** `ex1I`：

```isabelle
lemma ex1_intro_demo:
  fixes P :: "'a ⇒ o"
  assumes "P(a)" and "⋀x. P(x) ⟹ x = a"
  shows "∃!x. P(x)"
  using assms by (rule ex1I)
```

若 `P(a)` 成立且任何满足 `P` 的 `x` 都等于 `a`，则唯一存在。

**另一个引入规则** `ex_ex1I`：

```isabelle
lemma ex_ex1I_demo:
  fixes P :: "'a ⇒ o"
  assumes "∃x. P(x)" and "⋀x y. P(x) ⟹ P(y) ⟹ x = y"
  shows "∃!x. P(x)"
  using assms by (rule ex_ex1I)
```

若已知存在且任意两个满足者相等，则唯一存在。

**消除规则** `ex1E`：

```isabelle
thm ex1E
```

**唯一存在的功能性**：

```isabelle
thm ex1_functional
```

输出：`⟦∃!z. P(a,z); P(a,b); P(a,c)⟧ ⟹ b = c`

若 `P(a,·)` 有唯一满足者，且 `P(a,b)` 和 `P(a,c)` 都成立，则 `b = c`。

## 47.12 等词

FOL 的等词 `=` 有三条基本规则：

- **`refl`**：自反性 `a = a`
- **`sym`**：对称性 `a = b ⟹ b = a`
- **`trans`**：传递性 `a = b ⟹ b = c ⟹ a = c`

```isabelle
lemma refl_demo: "a = a"
  by (rule refl)

lemma sym_demo: "a = b ⟹ b = a"
  by (rule sym)

lemma trans_demo: "a = b ⟹ b = c ⟹ a = c"
  by (rule trans)
```

**替换规则** `subst`：若 `a = b` 则 `P(a) ⟹ P(b)`：

```isabelle
lemma subst_demo:
  assumes "a = b" and "P(a)"
  shows "P(b)"
  using assms by (rule subst)
```

`subst` 是等词最强大的规则——允许在任何谓词里做等量替换。

**对称替换** `ssubst`：

```isabelle
lemma ssubst_demo:
  assumes "b = a" and "P(a)"
  shows "P(b)"
  using assms by (rule ssubst)
```

`ssubst` 和 `subst` 的区别是等式方向：`subst` 用 `a = b` 把 `P(a)` 替换为 `P(b)`，`ssubst` 用 `b = a` 做同样的事。

**等词的交换律**：

```isabelle
thm eq_commute
```

输出：`a = b ⟷ b = a`

## 47.13 定义：True、not、iff、Let

**`True`** 定义为 `False ⟶ False`：

```isabelle
lemma TrueI_demo: "True"
  by (rule TrueI)
```

`TrueI` 是 `True` 的引入规则。因为 `True` 定义为 `False ⟶ False`，而 `False ⟶ False` 可以用 `impI` 证明（假设 `False`，从 `False` 推出 `False`），所以 `True` 总是可证的。

**`¬P`** 定义为 `P ⟶ False`（`not_def`）：

```isabelle
thm not_def
```

这意味着否定规则本质上就是蕴含规则。`notI` 就是 `impI` 的特例，`notE` 就是 `mp` + `FalseE` 的组合。

**`P ⟷ Q`** 定义为 `(P ⟶ Q) ∧ (Q ⟶ P)`（`iff_def`）：

```isabelle
thm iff_def
```

**`Let(s, f)`** 定义为 `f(s)`——就是简单的代入：

```isabelle
lemma Let_demo: "Let(s, f) = f(s)"
  by (unfold Let_def, rule refl)
```

`Let` 不是真正的绑定操作——它只是语法糖，展开后就是直接应用。

**`Uniq(P)`** 定义为 `∀x y. P(x) ⟶ P(y) ⟶ y = x`：

```isabelle
thm Uniq_def
```

谓词 `P` 最多被一个元素满足。

## 47.14 自动化：simp、blast、iprover

FOL 提供三种自动化工具：

- **`simp`**：化简器，使用 `IFOL_ss`（直觉主义）或 `FOL_ss`（经典）化简集
- **`blast`**：经典表推演机，完备的一阶逻辑证明器
- **`iprover`**：直觉主义证明器，只证构造性有效的公式

HOL 的 `metis` 和 `smt` 在 FOL 里**不可用**。

化简器能自动处理命题逻辑的恒等式：

```isabelle
lemma conj_comm_simp: "P ∧ Q ⟷ Q ∧ P"
  by blast

lemma disj_comm_simp: "P ∨ Q ⟷ Q ∨ P"
  by blast

lemma imp_conj_distrib_simp: "(P ⟶ Q ∧ R) ⟷ (P ⟶ Q) ∧ (P ⟶ R)"
  by blast
```

`blast` 能自动处理带量词的公式：

```isabelle
lemma blast_quantifier:
  fixes P Q :: "'a ⇒ o"
  shows "(∀x. P(x) ⟶ Q(x)) ⟶ (∀x. P(x)) ⟶ (∀x. Q(x))"
  by blast
```

`iprover` 能证直觉主义有效式：

```isabelle
lemma iprover_demo: "¬¬(P ∨ ¬P)"
  by iprover
```

但 `iprover` 证不了经典有效式——`lemma lem: "P ∨ ¬P" by iprover` 会失败。

## 47.15 De Morgan 律与分配律

FOL 库提供了完整的 De Morgan 律：

```isabelle
thm de_Morgan_disj
thm de_Morgan_conj
thm not_imp
thm not_all
thm not_ex
```

- `de_Morgan_disj`：`¬(P ∨ Q) ⟷ ¬P ∧ ¬Q`
- `de_Morgan_conj`：`¬(P ∧ Q) ⟷ ¬P ∨ ¬Q`
- `not_imp`：`¬(P ⟶ Q) ⟷ P ∧ ¬Q`
- `not_all`：`¬(∀x. P(x)) ⟷ ∃x. ¬P(x)`
- `not_ex`：`¬(∃x. P(x)) ⟷ ∀x. ¬P(x)`

**分配律**：

```isabelle
lemma conj_disj_distribL: "P ∧ (Q ∨ R) ⟷ (P ∧ Q) ∨ (P ∧ R)"
  by blast

lemma disj_conj_distribL: "P ∨ (Q ∧ R) ⟷ (P ∨ Q) ∧ (P ∨ R)"
  by blast
```

**量词与联结词的交互**：

```isabelle
lemma imp_ex: "((∃x. P(x)) ⟶ Q) ⟷ (∀x. P(x) ⟶ Q)"
  by blast

lemma all_conj_distrib_full: "(∀x. P(x) ∧ Q(x)) ⟷ (∀x. P(x)) ∧ (∀x. Q(x))"
  by blast

lemma ex_disj_distrib_full: "(∃x. P(x) ∨ Q(x)) ⟷ (∃x. P(x)) ∨ (∃x. Q(x))"
  by blast
```

## 47.16 等词推理与 calculational 规则

FOL 支持等式的链式推理（calculational reasoning）。`trans` 规则标记为 `[trans]`，可以用于 `also` / `finally` 计算块：

```isabelle
lemma chain_demo:
  assumes "a = b" and "b = c" and "c = d"
  shows "a = d"
proof -
  from assms(1) have "a = b" .
  also from assms(2) have "b = c" .
  also from assms(3) have "c = d" .
  finally show "a = d" .
qed
```

`also` 把当前等式与前面的等式链通过 `trans` 组合，`finally` 结束计算块。`.`（`by fact`）表示用已有事实完成证明。

替换规则 `forw_subst` 和 `back_subst` 也标记为 `[trans]`：

```isabelle
thm forw_subst
thm back_subst
```

## 47.17 经典推理的额外规则

FOL（经典）比 IFOL（直觉主义）多出以下规则：

- **`classical`**：`(¬P ⟹ P) ⟹ P`——经典公理本身
- **`ccontr`**：`(¬P ⟹ False) ⟹ P`——反证法
- **`notnotD`**：`¬¬P ⟹ P`——双非消去
- **`excluded_middle`**：`¬P ∨ P`——排中律
- **`case_split`**：`⟦P ⟹ Q; ¬P ⟹ Q⟧ ⟹ Q`——情形分解
- **`disjCI`**：`(¬Q ⟹ P) ⟹ P ∨ Q`——经典析取引入
- **`exCI`**：`(∀x. ¬P(x) ⟹ P(a)) ⟹ ∃x. P(x)`——经典存在引入
- **`impCE`**：`⟦P ⟶ Q; ¬P ⟹ R; Q ⟹ R⟧ ⟹ R`——经典蕴含消去

这些规则在 IFOL 里都不可用。

## 47.18 同余规则（congruence）

FOL 提供了各联结词的同余规则——若子公式等价则整体等价：

```isabelle
thm conj_cong
thm disj_cong
thm imp_cong
thm iff_cong
thm not_cong
thm all_cong
thm ex_cong
thm ex1_cong
```

这些规则主要用于化简器的上下文敏感重写。例如 `conj_cong` 说：如果 `P ⟷ P'` 且 `P' ⟹ Q ⟷ Q'`，则 `P ∧ Q ⟷ P' ∧ Q'`。

## 47.19 与 HOL 的对照表

同一个命题在 HOL 和 FOL 里的证法对比（实测）：

| 命题 | HOL | FOL |
|---|---|---|
| `P ⟶ P` | `by (rule impI)` | 同左（最小逻辑层）|
| `P ∧ Q ⟷ Q ∧ P` | `by blast` | `by blast` |
| `P ∨ ¬P` | `by simp` | `by blast`（经典公理）|
| `(∀x. P(x)) ⟶ P(a)` | `by auto` | 手动 `allI`/`spec` |
| `∃x. P(x) ⟶ ∀x. P(x)` | `by blast` | `by blast` |
| `¬¬P ⟶ P` | `by simp` | `by (rule notnotD)` |

工程代价：

- HOL-Library / Eisbach 全不可用
- `datatype` / `primrec` / `fun` 等包也没有（那些是 HOL 的）
- `metis` / `smt` 不可用（那是 HOL 的引理工具）
- `blast` / `iprover` / `simp` 可用

## 47.20 坑位清单（实测）

1. **`i` 类型不存在**——个体用默认 sort 的类型变量 `'a`，谓词 `'a ⇒ o`。老教程里的 `:: i` 写法在 Isabelle2026 里直接报错。
2. **`P x` 空格应用解析失败**——用 `P(x)`（ZF 同款，第 48 章）。`P x` 在量词体里触发 Inner syntax error，报错位置从 `x` 开始——极具误导性。
3. IFOL 里证经典命题**不会报错，只会永远证不出**——谨慎用 `sorry` 之外的手段排查。
4. `metis` / `smt` 不可用；`blast` / `iprover` 可用。
5. 多方法串联 `by m1 m2` 之后**另起一行的括号**是 outer syntax 错误（keyword ( expected）——用 apply 脚本分行。
6. `fixes P :: "'a ⇒ o"` 是声明谓词变量的唯一正解——不能写 `fixes P :: "i ⇒ o"`（`i` 不存在）。
7. `spec` 是全称消去到**任意项**（不是特定变量），`erule allE` 时记得指定实例。
8. FOL 的 `⟷` 写作 `⟷`（与 HOL 相同），但内部定义不同（`iff_def` vs HOL 的 `iff_def`）。
9. `value` 不可用（代码生成器没配 FOL）。
10. `True` 在 FOL 里是定义（`False ⟶ False`），不是原始常量——`TrueI` 是它的引入规则。

## 47.21 与其他章的接口

- 第 50 章自然演绎：IFOL 是它最纯的舞台
- 第 48 章 ZF：FOL 之上的公理集合论
- 第 31 章 inductive：FOL 里也有（谓词变元版本）

上一章：[46 · HOL-Analysis 入门](46-analysis-intro.md) ｜ 下一章：[48 · ZF：公理集合论的形式化](48-zf.md) ｜ 返回：[README](../README.md)
