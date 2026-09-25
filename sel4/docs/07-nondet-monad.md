# 07 · 非确定性状态单子

对应示例：`../examples/S07_nondet_monad.thy`

## 7.1 读 l4v 的第一道门槛：非确定性状态单子

seL4 的内核代码不是普通函数，而是一个**非确定性状态单子**：
给定初始状态，返回**(结果集合, 失败标志)**。
结果是个集合，因为内核里有真正的非确定性（调度器选谁、从哪个队列取）；
失败标志独立于结果集合，因为"失败"和"返回空集"是两件事。

真实定义在 `l4v/lib/Monads/nondet/Nondet_Monad.thy:36`：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_Monad.thy:36-36 -->
```text
type_synonym ('s, 'a) nondet_monad = "'s \<Rightarrow> ('a \<times> 's) set \<times> bool"
```

（配套 `Nondet_VCG.thy`、`Nondet_No_Fail.thy`、`Nondet_Empty_Fail.thy`、
`Nondet_Monad_Equations.thy`——同一目录下还有十几个，别指望一次读完。）

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
('s,'a) nondet_monad = 's ⇒ ('a × 's) set × bool
                              │         │      └─ 失败标志
                              │         └─ 非确定性：结果是个集合
                              └─ 新状态
```

本章用一组 `k` 前缀的名字把组合子重新实现了一遍（`kreturn`/`kbind`/`kfail`/`kassert`/
`kassert_opt`/`kget`/`kput`/`kgets`/`kmodify`/`kselect`/`kwhen`），
再挂到 do 记号上。要挂上去，需要 `imports "HOL-Library.Monad_Syntax"` 加一行
`adhoc_overloading bind == kbind`（**是 `==` 不是 `=`**，见坑位 2）。

## 7.2 单子三定律

```text
theorem bind_return_left: kreturn ?x \<bind> ?f = ?f ?x
```

```text
theorem local.bind_assoc: ?m \<bind> ?f \<bind> ?g = ?m \<bind> (\<lambda>x. ?f x \<bind> ?g)
```

定理名里的 `local.` 前缀是 `adhoc_overloading` 留下的痕迹：
绑定符号被重载了，定理名因此带了限定。这是**正常现象**，不是错误。

## 7.3 结合律：这一条最啰嗦，也最值得证

结合律之所以值得单独证，是因为它保证了"把一串 `bind` 怎么加括号都一样"。
内核代码里大量的 `do { x <- m; f x }` 嵌套，靠它才能重排。

## 7.4 失败与"空结果"是两件事

```text
theorem fail_fails: \<not> no_fail kfail
```

```text
theorem select_empty_does_not_fail: no_fail (kselect {})
```

```text
theorem select_empty_has_no_results: \<not> nonempty (kselect {})
```

三条是关键：**失败的程序一定不满足 `no_fail`；但"结果集为空"的程序可以是 `no_fail` 的**。
`kselect {}` 就是一个既不失败、又没有任何结果的计算。

l4v 为此专门有两个文件：`Nondet_No_Fail.thy` 与 `Nondet_Empty_Fail.thy`。
把 `no_fail` 当成"结果非空"，是这一层最常见的误解。

## 7.5 状态操作的三条等式

`kget`/`kput`/`kmodify` 满足一组等式，其中"改两次等于复合"最容易写反方向（实测）：

```text
theorem modify_twice: kmodify ?f \<bind> (\<lambda>_. kmodify ?g) = kmodify (?g \<circ> ?f)
```

复合顺序是 `g ∘ f`：先写的 `f` 先作用。

## 7.6 非确定性是怎么进到内核里的

`kselect` 是唯一的非确定性来源——从一个集合里"任选一个"（实测）：

```text
theorem
  bind_select_collects:
    fst ((kselect ?A \<bind> (\<lambda>x. kreturn (x + 1))) ?s) = (\<lambda>x. x + 1) ` ?A \<times> {?s}
```

结果集合就是"每个可能的 x 都算一遍"的像。
真实内核里的非确定性来自调度（`choose_thread`，`l4v/spec/abstract/Schedule_A.thy:74`，
它从就绪队列里"任选一个"优先级匹配的线程）与 `select_ext`
（"任选一个满足条件的槽"，见第 06 章的 `cap_revoke`）。

## 7.7 这套单子库自己带一份说明书：四个概念，两个变体

7.1 说"失败标志和结果集是两件事"。这件事在 l4v 里不是本章的口头解释，
而是库自带的、写在源码旁边的正式口径。`l4v/lib/Monads/README.md` 的目录说明是：

<!-- 源码块：l4v/lib/Monads/README.md:27-30 -->
```text
- for the nondeterministic state monad, additional concepts such as
  wellformedness with respect to failure (`empty_fail`), absence of failure
  (`no_fail`), absence of exceptions (`no_throw`). See its [README][nondet] and
  the respective theories for more details.
```

同一目录下的 `Nondet_README.thy` 用 Isabelle 的注释把这四个概念的差别列全了：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_README.thy:123-132 -->
```text
text \<open>
There are additional properties of nondeterministic monadic functions that are often
useful. These include:
  @{const no_fail} - a monad does not fail when starting in a state that satisfies a
    given precondition.
  @{const empty_fail} - if a monad returns an empty set of results then it must also have
    the failure flag set.
  @{const no_throw} - an exception monad does not throw an exception when starting in a
    state that satisfies a given precondition.
  @{const det} - a monad is deterministic and returns exactly one non-failing state.\<close>
```

读这一段要抓住三件事。第一，`no_fail` 和 `no_throw` 都**带前置条件**，
不是单参数的谓词——本章模型里那个 `no_fail m` 是简化写法，
真实定义是（`l4v/lib/Monads/nondet/Nondet_No_Fail.thy`）：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_No_Fail.thy:19-25 -->
```text
text \<open>
  With the failure flag, we can formulate non-failure separately from validity.
  A monad @{text m} does not fail under precondition @{text P}, if for no start
  state that satisfies the precondition it sets the failure flag.
\<close>
definition no_fail :: "('s \<Rightarrow> bool) \<Rightarrow> ('s,'a) nondet_monad \<Rightarrow> bool" where
  "no_fail P m \<equiv> \<forall>s. P s \<longrightarrow> \<not>snd (m s)"
```

第二，`empty_fail` 的方向是"**结果为空 ⟹ 失败标志置起**"，
不是反过来（这条方向的另一种写法在第 18 章 18.8 专门纠过一次）。
第三，四个概念里只有 `det` 不带前置条件
（`l4v/lib/Monads/nondet/Nondet_Det.thy` 第 17 行那条定义是
`('a,'s) nondet_monad ⇒ bool`），它说的是"恰好一个结果且不失败"。
另外别把这个名字和抽象规范里的 `det_state` 混起来——
后者是 `Deterministic_A.thy` 给确定性状态起 synonym，
和这里的谓词是两码事。

下面两条变体也常被撞到：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_README.thy:134-140 -->
```text
text \<open>
Variants of the basic validity definition are sometimes useful when working with the
nondeterministic monad.
  @{const validNF} - a total correctness extension combining @{const valid} and
    @{const no_fail}.
  @{const exs_valid} - a dual to @{const valid} showing that after a monad executes there
    exists at least one state that satisfies a given condition.\<close>
```

`validNF` = `valid` + `no_fail`，即"部分正确性再加一趟不许失败"，
这就是第 17 章 `wp` 推出来的那种目标；`exs_valid` 是"存在一个结局"，
方向与 `valid` 相反，`wp` 推它时规则集完全不同。
**注意：这份 `.thy` 形式的说明书没有列进 `l4v/lib/Monads/ROOT` 的 `theories`，
`isabelle build` 默认不编它**——要读得自己在 jEdit 里打开那个文件。

## 7.8 `bind` 那一行里，失败位是怎么传下去的

7.1 的类型定义只是骨架，两条基本组合子的定义才说清了失败位的语义。
`return`（`l4v/lib/Monads/nondet/Nondet_Monad.thy`）：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_Monad.thy:61-63 -->
```text
definition return :: "'a \<Rightarrow> ('s,'a) nondet_monad" where
  "return a \<equiv> \<lambda>s. ({(a,s)},False)"

```

`bind`：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_Monad.thy:73-77 -->
```text
definition bind ::
  "('s, 'a) nondet_monad \<Rightarrow> ('a \<Rightarrow> ('s, 'b) nondet_monad) \<Rightarrow> ('s, 'b) nondet_monad" (infixl ">>=" 60)
  where
  "bind f g \<equiv> \<lambda>s. (\<Union>(fst ` case_prod g ` fst (f s)),
                   True \<in> snd ` case_prod g ` fst (f s) \<or> snd (f s))"
```

第二个分量那句 `True ∈ snd ` case_prod g ` fst (f s) ∨ snd (f s)` 值得逐字读：
**整体失败的充要条件是"`f` 失败"或者"`g` 在 `f` 的某个结果上失败"**。
非确定性在这里的表现是那个 `∪` 和那个"某个结果"——
一条分支失败，整个 `bind` 就失败，哪怕别的分支给出了结果。
这正是第 18 章 `corres` 要 `nf' = True` 的那条义务的来源。

## 7.9 为什么你的目标长得和定义不一样：一条 AST 翻译

模型里 `kbind` 展开后你会看到 `⟨UNION, case_prod⟩` 那一坨；
真实树里同样的目标却显示成 `('s,'a) nondet_monad`。
这不是记忆偏差，是库里装了一个**打印翻译**：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_Monad.thy:39-43 -->
```text
text \<open>
  Print the type @{typ "('s,'a) nondet_monad"} instead of its unwieldy expansion.
  Needs an AST translation in code, because it needs to check that the state variable
  @{typ 's} occurs twice. This comparison is not guaranteed to always work as expected
  (AST instances might have different decoration), but it does seem to work here.\<close>
```

它自己也承认这套匹配"不保证总是按预期工作"。
实用结论有两条：化简器看到的仍是展开后的形式，
所以 `[simp]` 规则、`split` 声明都得写在真实符号上；
而人眼看到的形式不能拿来推断"证明器已经知道这是单子"。

## 7.10 单子等式有一条专用方法：`monad_eq`

坑位 9 说"用 `auto` 直接证单子等式通常卡在集合相等"。
在 l4v 里这不是一条民间技巧，而是有名字、有方法、有例子：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_MonadEq.thy:53-55 -->
```text
method_setup monad_eq = \<open>
    Method.sections Clasimp.clasimp_modifiers >> (K (SIMPLE_METHOD o monad_eq_tac))\<close>
  "prove equality on monads"
```

说明书里那两条例子（`l4v/lib/Monads/nondet/Nondet_README.thy`）：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_README.thy:94-111 -->
```text
text \<open>
Lemmas directly about the monad primitives can be found in @{theory Monads.Nondet_Lemmas}
and @{theory Monads.Nondet_Monad_Equations}. Many of these lemmas use @{method monad_eq},
which is a tactic for solving monadic equalities.\<close>

lemma
  "(do x \<leftarrow> gets f;
       xa \<leftarrow> gets f;
       m xa x
    od) =
   (do xa \<leftarrow> gets f;
       m xa xa
    od)"
  by monad_eq

lemma
  "snd (gets_the X s) = (X s = None)"
  by (monad_eq simp: gets_the_def gets_def get_def)
```

第一条是"两次 `gets` 可以合并成一次"这种在 `do` 块里天天遇到的化简；
第二条直接把 `gets_the` 的失败位算出来（`snd (gets_the X s) = (X s = None)`）——
本章模型里那条 `kassert_opt` 的失败条件，真实版本就是这么一条等式。
注意它的证明里带 `simp: gets_the_def gets_def get_def`：
`monad_eq` 管的是**形状**，定义还得自己给。

## 7.11 官方口径：用最弱的单子，用最具体的访问器

这一层的选择不是风格问题，官方那份规划文档把它写成了一条明确准则
（`l4v/docs/plans/the-matrix.md`）：

<!-- 源码块：l4v/docs/plans/the-matrix.md:112-117 -->
```text
  - More consistent structure in the abstract spec, to improve accessibility to automation, e.g.:
    - Use the least powerful monad that gets the job done.
    - Use the most specific accessor.
    - Break large functions into smaller ones (to make it easier to state lemmas about the parts).
    - Pass more parameters to functions, if information available in the caller might be useful
      for stating properties about the called function.
```

四条里前两条直接管本章：类型上"能表达失败"和"必须表达失败"是两回事，
`7.7` 那四个谓词能不能白送，取决于你选的单子有多强；
访问器选得越具体（`cte_wp_at` 而不是 `pspace`），`wp` 要证的框架条件越少。
命名侧的配套规矩在约定页里：

<!-- 源码块：l4v/docs/conventions.md:135-141 -->
```text
* function variables are called `f`, `g`, or `m` (for "monad")

* property variables are called `P`, `Q`, `R`, `P'`, `Q'`. This means, in Hoare
  triples, `P` tends to be a precondition, `Q` a postcondition. If there is only
  one property variable, it should be called `P` so it is easy to guess the name
  for instantiations. Example: `return_wp: ⦃P v⦄ return v ⦃P⦄` (even though P is
  a postcondition here).
```

也就是说 `m` 代表 monad、`P` 代表前置条件不是巧合，
而是"看名字就知道该往哪个参数位上代项"的接口。
7.2 那条 `local.bind_assoc` 之所以要写限定名，根子也在这里：
`bind` 这个名字被 `adhoc_overloading` 改过，
而库里 `return`/`bind` 这些名字本身就是 `Nondet_Monad.thy` 的顶层常量
（第 7.8 节那两条定义），不是本教程模型里那种 `k` 前缀的私货。

---

## 官方教程对照

| 官方文档 / 文件 | 覆盖本章哪一段 | 本教程的处理 |
|---|---|---|
| `l4v/lib/Monads/README.md` | 三个单子 + `empty_fail`/`no_fail`/`no_throw` 三个概念 | 7.7 |
| `l4v/lib/Monads/nondet/Nondet_README.thy` | 四概念清单、`validNF`/`exs_valid`、`monad_eq` 例子 | 7.7、7.10 |
| `l4v/docs/plans/the-matrix.md` | "最弱的单子/最具体的访问器" | 7.11 |
| `l4v/docs/conventions.md` | `f`/`g`/`m`、`P`/`Q` 命名约定 | 7.11 |
| `l4v/lib/Monads/wp/WP_README.thy` | `wp` 方法的规则集怎么装配 | 第 17 章 |

**1. 官方对这一层的"教程"就是两份 README。** 一份是 Markdown
（`lib/Monads/README.md`，讲有哪些单子、各管什么），
一份是 `.thy`（`Nondet_README.thy`、`wp/WP_README.thy`，讲怎么用）。
`.thy` 那份没进 ROOT 的 `theories` 列表，`isabelle build` 不编它，
所以它的示例**没有经过构建检查**——抄之前自己开一遍。

**2. 本地文档镜像 `docs/Tutorials/` 里没有单子教程**，
seL4 项目主页讲的是怎么用 API，不讲 HOL 侧的类型。
本章引用全部落在 `l4v/lib/Monads/` 与 `l4v/docs/`。

**3. 一处术语别混**：`the-matrix.md` 里说的 "monad" 指**规范内部用哪种类型**
（`s_monad`/`se_monad`/`f_monad`，见第 08 章），
而 `lib/Monads/` 那个会话说的是**底层实现**（nondet/trace/reader-option 三种）。
两者不是一回事。

---

## 本章坑位清单（实测）

1. **ROOT 父会话写 `HOL` 就 import 不了 `Monad_Syntax`**：报 `Bad import … need to include sessions "HOL-Library" in ROOT`。父会话要写 `"HOL-Library"`（带引号）。
2. **`adhoc_overloading` 写 `=`**：必须是 `bind == kbind`，写 `=` 报错且位置不指向这一行。
3. **定理名带 `local.` 前缀以为出错**：重载绑定符号后属正常。
4. **把 `no_fail` 当"结果非空"**：两者独立，`kselect {}` 是反例。
5. **把失败标志当返回值的一部分**：它是二元组右边的 `bool`，与结果集合并列。
6. **`modify_twice` 的复合顺序写反**：是 `g ∘ f`。
7. **结果类型是集合导致等式难证**：拆成 `fst` 与 `snd` 两个分量分别证（用 `prod_eqI`）。
8. **裸写 `bind_assoc`**：重载后要写 `local.bind_assoc`。
9. **用 `auto` 直接证单子等式**：通常卡在集合相等上，先用 `ext` 或 `prod_eqI` 拆开；真实库里这条有专用方法，见 7.10。
10. **把 `kassert` 当普通布尔**：`kassert False = kfail`（实测），它是"不成立就失败"。
11. **把 `no_fail` 当单参数谓词**：真实定义是 `no_fail P m`，`no_throw` 同理；四个概念里只有 `det` 不带前置条件（7.7）。
12. **看到目标显示成 `('s,'a) nondet_monad` 就以为证明器认识它**：那是一条 `print_ast_translation`，化简器看到的仍是展开形式（7.9）。
13. **把库里的 `.thy` 说明书当构建产物**：`Nondet_README.thy` 没列进 `lib/Monads/ROOT`，它的示例没经过 `isabelle build`。

---

上一章：[06 · 回收与删除](06-revoke-delete.md) ｜ 下一章：[08 · 错误单子与解码](08-error-monad.md) ｜ 返回：[README](../README.md)
