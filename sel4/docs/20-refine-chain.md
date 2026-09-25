# 20 · 精化链与信任基

对应示例：`../examples/S20_refine_chain.thy`

## 20.1 一条链，四个层次

第 18 章证的是"两个 monadic 函数对应"，第 19 章证的是"一段 C 对应一个设计层函数"。
把它们接起来，并且让最上面那层的定理真的适用于最下面那个二进制，
靠的是一套通用的**精化代数**。这套代数在本树里只有一个文件：
`l4v/lib/Simulation.thy`，只 `imports Main`，全文 321 行。
`l4v/README.md` 第 82--91 行把"哪一层归哪个目录证明"列得很清楚：

<!-- 源码块：l4v/README.md:82-89 -->
```text
 * [`proof`](proof/): the seL4 proofs
    * [`invariant-abstract`](proof/invariant-abstract/): invariants of the seL4 abstract specification
    * [`refine`](proof/refine/): refinement between abstract and design specifications
    * [`crefine`](proof/crefine/): refinement between design specification and C semantics
    * [`access-control`](proof/access-control/): integrity and authority confinement proofs
    * [`infoflow`](proof/infoflow/): confidentiality and intransitive non-interference proofs
    * [`asmrefine`](proof/asmrefine/): Isabelle/HOL part of the seL4 binary verification
    * [`drefine`](proof/drefine/): refinement between capDL and abstract specification
```

注意最后两行：`drefine`、`sep-capDL`（同一清单第 90--91 行）说明
**链条不是一条线，而是一棵树**——capDL 规范另有一条到抽象规范的精化路。

规范侧同理，`l4v/README.md` 第 58--66 行：

<!-- 源码块：l4v/README.md:58-65 -->
```text
 * [`spec`](spec/): a number of different formal specifications of seL4
    * [`abstract`](spec/abstract/): the functional abstract specification of seL4
    * [`sep-abstract`](spec/sep-abstract/): an abstract specification for a reduced
      version of seL4 that is configured as a separation kernel
    * [`haskell`](spec/haskell/): Haskell model of the seL4 kernel, kept in sync
      with the C code
    * [`machine`](spec/machine/): the machine interface of these two specifications
    * [`cspec`](spec/cspec/): the entry point for automatically translating the seL4 C code
```

第 75--80 行还补了一句要紧的：**`design` 与 `cspec/c` 两个目录不在版本库里**，
前者由 Haskell 模型生成，后者由 `seL4` 仓库的 C 源码预处理生成。
`l4v/spec/design/README.md` 第 12--16 行则交代了 H 层的性质：

<!-- 源码块：l4v/spec/design/README.md:12-15 -->
```text
This directory contains the Isabelle sources of the executable design
specification for seL4.

Most theory files in this directory are tool-generated, do not edit!
```

（同一份 README 接着推荐"直接读 Haskell 那份更好读"——
它写的是另一个仓库布局里的路径，本树里对应 `l4v/spec/haskell/`。）

<!-- 示意块：链条示意，非构建产物 -->
```text
抽象规范 A ── 设计规范 H（可执行，Haskell 生成）── C 规范 cspec ── 二进制
   ADT_A              ADT_H                       ADT_C        asmrefine/SydTV-GL
      └────────── proof/refine ──────────┘└── proof/crefine ──┘└─ proof/asmrefine ─┘
```

每层在 Isabelle 里都写成一个 **`data_type`**（历史名字，跟"抽象数据类型"无关）。
设计层的 `ADT_H` 一节开篇（`l4v/proof/refine/ADT_H.thy` 第 16--21 行）就是这么说的：

<!-- 源码块：l4v/proof/refine/ADT_H.thy:16-21 -->
```text
text \<open>
  The general refinement calculus (see theory Simulation) requires
  the definition of a so-called ``abstract datatype'' for each refinement layer.
  This theory defines this datatype for the executable specification.
  It is based on the abstract specification because we chose
  to base the refinement's observable state on the abstract state.\<close>
```

最后一行是个真实的设计决定：**可观察状态取自抽象层**，
所以 H 层的 `Fin` 要把具体状态"抽象化"后才输出。

## 20.2 "层"到底是什么

<!-- 源码块：l4v/lib/Simulation.thy 第 39--42 行 -->
```text
record ('a,'b,'j) data_type =
  Init :: "'b \<Rightarrow> 'a set"
  Fin :: "'a \<Rightarrow> 'b"
  Step :: "'j \<Rightarrow> ('a \<times> 'a) set"
```

三个分量各自的意思：`Init` 拿一个"每次运行的参数"（架构、初始线程之类）
返回起始状态集合；`Step` 是**一族关系**，索引是"这一步做什么"；
`Fin` 把一个内部状态折成可观察输出。

行为定义为关系的逐步像（`l4v/lib/Simulation.thy` 第 48--50 行）：

<!-- 源码块：l4v/lib/Simulation.thy 第 48--50 行 -->
```text
definition
  steps :: "('j \<Rightarrow> ('a \<times> 'a) set) \<Rightarrow> 'a set \<Rightarrow> 'j list \<Rightarrow> 'a set" where
  "steps \<delta> \<equiv> foldl (\<lambda>S j. \<delta> j `` S)"
```

再套上初始集与 `Fin` 就是执行集（第 58--60 行）：

<!-- 源码块：l4v/lib/Simulation.thy 第 58--60 行 -->
```text
definition
   execution :: "('a,'b,'j) data_type \<Rightarrow> 'b \<Rightarrow> 'j list \<Rightarrow> 'b set" where
  "execution A s js \<equiv> Fin A ` steps (Step A) (Init A s) js"
```

模型里两条递归展开（实测）：

```text
theorem steps_Nil: steps ?\<delta> ?S [] = ?S
```

```text
theorem steps_Cons: steps ?\<delta> ?S (?j # ?js) = steps ?\<delta> (?\<delta> ?j `` ?S) ?js
```

**关键类型事实：`Step` 是 `'j ⇒ ('a × 'a) set`，不是 `'j ⇒ 'a ⇒ 'a set`。**
非确定性直接写成一对一对的关系。模型里想用
`'j ⇒ 'a ⇒ 'a set` 的形状喂进 `Step`，Isabelle 会当场报类型冲突——
所以三层实例的步都定义成 Collect 形式，例如（实测）：

```text
consts
  a_step :: "nat \<Rightarrow> (nat \<times> nat) set"
```

有了 `execution`，"精化"就只是一句包含关系
（`l4v/lib/Simulation.thy` 第 77--80 行）：

<!-- 源码块：l4v/lib/Simulation.thy 第 77--80 行 -->
```text
definition
  refines :: "('c,'b,'j) data_type \<Rightarrow> ('a,'b,'j) data_type \<Rightarrow> bool" (infix "\<sqsubseteq>" 60)
where
  "C \<sqsubseteq> A \<equiv> \<forall>js s. execution C s js \<subseteq> execution A s js"
```

模型里的两条代数事实（实测）：

```text
theorem refinement_refl: ?A \<sqsubseteq> ?A
```

```text
theorem refinement_trans: \<lbrakk>?C \<sqsubseteq> ?B; ?B \<sqsubseteq> ?A\<rbrakk> \<Longrightarrow> ?C \<sqsubseteq> ?A
```

真实文件里它们挂在第 274--280 行，属性分别是 `[simp]` 与 `[trans]`——
`seL4_refinement` 那条 `blast` 之所以能一行搞定，靠的就是 `[trans]`。
同一套记号里还有两条带属性的：`invariant_T [iff]`（第 166 行）、
`fw_simulates_refl [simp]`（第 307 行）。

## 20.3 精化为什么等价于"性质搬得过去"

`⊑` 看起来只是"执行集包含"，离"定理能搬"还有一步。
这一步在 `l4v/lib/Simulation.thy` 第 86--88 行，一个 `blast` 就完了：

<!-- 源码块：l4v/lib/Simulation.thy 第 86--88 行 -->
```text
lemma hoare_triple_refinement:
  "C \<sqsubseteq> A = (\<forall>P Q js. hoare_triple A P js Q \<longrightarrow> hoare_triple C P js Q)"
  by (simp add: refines_def hoare_triple_def) blast
```

模型里的同一条（实测）：

```text
theorem
  hoare_triple_refinement:
    ?C \<sqsubseteq> ?A = (\<forall>P Q js. hoare_triple ?A P js Q \<longrightarrow> hoare_triple ?C P js Q)
```

三点要读出来：

1. 结论是 **`=`，不是 `⟹`**。所以"精化"和"所有 Hoare 三元组都搬得动"
   是同一件事的两种写法——包含关系不是近似，而是完全刻画了性质搬运能力。
2. `hoare_triple` 的量化方式是 `∀s ∈ P. execution A s js ⊆ Q`
   （同一文件第 67--70 行）：前置条件是**状态集合**，
   索引 `js` 是"这一串操作"，不是"任意调度"。
3. 一条 `blast` 就够，说明这套定义是被**设计**成这样的：
   抽象层证性质，具体层自动继承，代价全在链子本身。

## 20.4 逐条证明太贵：前向模拟

`⊑` 是量在"所有执行"上的，逐条证不可行。工程做法是**逐状态**证交换图。
先给关系复合一个记号（`l4v/lib/Simulation.thy` 第 92--95 行）：

<!-- 源码块：l4v/lib/Simulation.thy 第 92--95 行 -->
```text
definition
  rel_semi :: "('a \<times> 'b) set \<Rightarrow> ('b \<times> 'c) set \<Rightarrow> ('a \<times> 'c) set" (infixl ";;;" 65)
where
  "A ;;; B \<equiv> A O B"
```

`;;;` 只是 HOL 的 `O`（`relcomp`）换了个优先级和写法。前向模拟三条
（同一文件第 102--107 行）：

<!-- 源码块：l4v/lib/Simulation.thy 第 102--107 行 -->
```text
definition
  fw_sim :: "('a \<times> 'c) set \<Rightarrow> ('c,'b,'j) data_type \<Rightarrow> ('a,'b,'j) data_type \<Rightarrow> bool"
where
  "fw_sim R C A \<equiv> (\<forall>s. Init C s \<subseteq> R `` Init A s) \<and>
                  (\<forall>j. R ;;; Step C j \<subseteq> Step A j ;;; R) \<and>
                  (\<forall>s s'. (s,s') \<in> R \<longrightarrow> Fin C s' = Fin A s)"
```

外加一层存在量词就是模拟精化（第 109--112 行）：

<!-- 源码块：l4v/lib/Simulation.thy 第 109--112 行 -->
```text
definition
  fw_simulates :: "('c,'b,'j) data_type \<Rightarrow> ('a,'b,'j) data_type \<Rightarrow> bool" (infixl "\<sqsubseteq>\<^sub>F" 50)
where
  "C \<sqsubseteq>\<^sub>F A \<equiv> \<exists>R. fw_sim R C A"
```

中间那条 `R ;;; Step C j ⊆ Step A j ;;; R` 就是"交换图"：
从抽象状态走一步、再落到具体状态，等于先落到具体状态、再走一步。
两条记号在模型里的实测形状：

```text
consts
  rel_semi :: "('a \<times> 'b) set \<Rightarrow> ('b \<times> 'c) set \<Rightarrow> ('a \<times> 'c) set"
```

```text
consts
  fw_simulates :: "('c, 'b, 'j) data_type \<Rightarrow> ('a, 'b, 'j) data_type \<Rightarrow> bool"
```

`fw_sim` 到 `⊑` 的桥是两条引理。第一条说交换图可以叠成任意长的执行
（`l4v/lib/Simulation.thy` 第 114--117 行）：

<!-- 源码块：l4v/lib/Simulation.thy 第 114--117 行 -->
```text
lemma fw_sim_steps:
  assumes steps: "t' \<in> steps (Step C) S' js" "S' \<subseteq> R `` S"
  assumes sim: "fw_sim R C A"
  shows "\<exists>t \<in> steps (Step A) S js. (t,t') \<in> R" using steps
```

证明是对 `js` 归纳（第 118 行起），模型里连归纳步骤一起抄了，实测中间产物：

```text
have R ;;; Step C j \<subseteq> Step A j ;;; R
```

```text
have Step C j `` S' \<subseteq> R `` Step A j `` S
```

第二条把模拟直接变成精化（`l4v/lib/Simulation.thy` 第 140--152 行，
13 行 tactic 脚本，比第 86--88 行那条费劲得多）：

<!-- 源码块：l4v/lib/Simulation.thy 第 140--146 行 -->
```text
lemma sim_imp_refines:
  "C \<sqsubseteq>\<^sub>F A \<Longrightarrow> C \<sqsubseteq> A"
  apply (clarsimp simp: refines_def execution_def fw_simulates_def)
  apply (rename_tac t)
  apply (drule fw_sim_steps)
    prefer 2
    apply assumption
```

模型里两条的实测结论：

```text
theorem fw_sim_steps:
 \<lbrakk>?t' \<in> steps (Step ?C) ?S' ?js; ?S' \<subseteq> ?R `` ?S; fw_sim ?R ?C ?A\<rbrakk>
 \<Longrightarrow> \<exists>t\<in>steps (Step ?A) ?S ?js. (t, ?t') \<in> ?R
```

```text
theorem sim_imp_refines: ?C \<sqsubseteq>\<^sub>F ?A \<Longrightarrow> ?C \<sqsubseteq> ?A
```

`sim_imp_refines` 是**单向**的：模拟足够，但不是必要。
真实主链每一环都在证 `⊑⇩F`，从不直接碰 `⊑`。

## 20.5 不变式：交换图走不通的时候

先记号化"这个集合是不变式"（`l4v/lib/Simulation.thy` 第 161--164 行）：

<!-- 源码块：l4v/lib/Simulation.thy 第 161--164 行 -->
```text
definition
  invariant_holds :: "('a,'b,'j) data_type \<Rightarrow> 'a set \<Rightarrow> bool" (infix "\<Turnstile>" 60)
where
  "D \<Turnstile> I \<equiv> (\<forall>s. Init D s \<subseteq> I) \<and> (\<forall>j. Step D j `` I \<subseteq> I)"
```

模型里的引入规则（实测，同文件第 169--171 行）：

```text
theorem
  invariantI: \<lbrakk>\<forall>s. Init ?D s \<subseteq> ?I; \<forall>j. Step ?D j `` ?I \<subseteq> ?I\<rbrakk> \<Longrightarrow> ?D \<Turnstile> ?I
```

然后把 `fw_sim` 改成"只在不变式内成立的交换图"，就是 `LI`
（`l4v/lib/Simulation.thy` 第 200--205 行）：

<!-- 源码块：l4v/lib/Simulation.thy 第 200--205 行 -->
```text
definition
  LI :: "('a,'b,'j) data_type \<Rightarrow> ('c,'b,'j) data_type \<Rightarrow> ('a \<times> 'c) set \<Rightarrow> ('a \<times> 'c) set \<Rightarrow> bool"
where
  "LI A C R I \<equiv> (\<forall>s. Init C s \<subseteq> R `` Init A s) \<and>
                (\<forall>j. (R \<inter> I) ;;; Step C j \<subseteq> Step A j ;;; R) \<and>
                (\<forall>s s'. (s,s') \<in> R \<inter> I \<longrightarrow> Fin C s' = Fin A s)"
```

读三遍：

* 参数顺序是 `LI A C R I`——**抽象层在前**，跟 `fw_sim R C A` 相反；
* 只在第二条（步）和第三条（`Fin`）上切了 `I`，第一条（`Init`）没切；
* 切的是**乘积**不变式 `I⇩a × I⇩c`，也就是"两边都留在各自的不变式里"。

`LI` 换回 `fw_sim` 靠 `LI_fw_sim`（`l4v/lib/Simulation.thy` 第 208--210 行）：

<!-- 源码块：l4v/lib/Simulation.thy 第 208--210 行 -->
```text
lemma LI_fw_sim:
  assumes  ia: "A \<Turnstile> I\<^sub>a" and ic: "C \<Turnstile> I\<^sub>c" and li: "LI A C r (I\<^sub>a \<times> I\<^sub>c)"
  shows "fw_sim (r \<inter> I\<^sub>a \<times> I\<^sub>c) C A"
```

结论里的关系**换了**：从 `r` 变成 `r ∩ I⇩a × I⇩c`。
它的证明中段（第 226--228 行）做了一件很巧的事——把交集写成两侧自关系的复合：

<!-- 源码块：l4v/lib/Simulation.thy 第 226--227 行 -->
```text
    have "r \<inter> (I\<^sub>a \<times> I\<^sub>c) = ((UNIV \<times> I\<^sub>a) \<inter> Id) ;;; r ;;; ((I\<^sub>c \<times> UNIV) \<inter> Id)"
      (is "_ = ?I\<^sub>a ;;; r ;;; ?I\<^sub>c")
```

有了这个形状，就能把"不变式在步下封闭"从左右两边各塞进去一次。
模型里把整段 41 行的证明照抄了一份，实测它的中间结论：

```text
have r \<inter> I\<^sub>a \<times> I\<^sub>c ;;; Step C j \<subseteq> Step A j ;;; r \<inter> I\<^sub>a \<times> I\<^sub>c
```

```text
show fw_sim (r \<inter> I\<^sub>a \<times> I\<^sub>c) C A
```

外层再包一条就是工程入口（`l4v/lib/Simulation.thy` 第 267--272 行）：

<!-- 源码块：l4v/lib/Simulation.thy 第 267--272 行 -->
```text
lemma L_invariantI:
  assumes  "A \<Turnstile> I\<^sub>a" and "C \<Turnstile> I\<^sub>c" and "LI A C r (I\<^sub>a \<times> I\<^sub>c)"
  shows "C \<sqsubseteq>\<^sub>F A"
  using assms
  by (simp add: fw_simulates_def, rule_tac x="r \<inter> I\<^sub>a \<times> I\<^sub>c" in exI,
      simp add: LI_fw_sim)
```

配套的还有两条"关系强弱"的（实测）：

```text
theorem fw_sim_eq_LI: fw_sim ?r ?C ?A = LI ?A ?C ?r UNIV
```

```text
theorem weaken_LI:
 \<lbrakk>LI ?A ?C ?R ?I'; ?I \<subseteq> ?I'\<rbrakk> \<Longrightarrow> LI ?A ?C ?R ?I
```

`fw_sim_eq_LI`（第 260--261 行）说明**前向模拟就是"不变式取 UNIV 的 LI"**：
所以"证不出 `fw_sim`"和"`LI … UNIV` 不成立"是同一句话。
`weaken_LI`（第 251--258 行）说明条件越大越容易证——
这也是为什么真证明里总想把不变式切小一点再切小一点。

## 20.6 三层链：跑一遍

模型用三个 `data_type` 复现链的形状：抽象层只有一个数，
设计层多一个"备用字段"但保证它为 0，
C 层允许这个字段有垃圾值、还多一条"垃圾非 0 就整个清零"的分支。

<!-- 示意块：三层状态形状，非构建产物 -->
```text
ADT_A: 状态 nat                     一步: n ↦ n + k
ADT_M: 状态 (nat × nat)，snd 恒 0    一步: (a,b) ↦ (a+k, b)
ADT_C: 状态 (nat × nat)，snd 有垃圾   一步: (a,b) ↦ (a+k,b)，或 b≠0 时 ↦ (0,0)
```

三个实例的实测签名：

```text
consts
  ADT_A :: "(nat, nat, nat) data_type"
```

```text
consts
  ADT_M :: "(nat \<times> nat, nat, nat) data_type"
```

```text
consts
  ADT_C :: "(nat \<times> nat, nat, nat) data_type"
```

分量引理（实测，注意 `Step` 全部写成"属于一条关系"）：

```text
theorem A_Step: ((?p, ?p') \<in> Step ADT_A ?k) = (?p' = ?p + ?k)
```

```text
theorem M_Step: ((?p, ?p') \<in> Step ADT_M ?k) = (?p' = (fst ?p + ?k, snd ?p))
```

```text
theorem
  C_Step:
    ((?p, ?p') \<in> Step ADT_C ?k) =
    (?p' = (fst ?p + ?k, snd ?p) \<or> 0 < snd ?p \<and> ?p' = (0, 0))
```

```text
theorem C_Fin: Fin ADT_C ?p = fst ?p + snd ?p
```

`Fin ADT_C` 把两个分量**加起来**，这一笔是整节能成立的关键：
垃圾值不影响可观察输出。`C_Step` 里那个 `0 < snd ?p` 分支
就是内核里"这段代码到不了"那类分支的抽象。

第一环不需要不变式。关系只看第一个分量（实测）：

```text
theorem R_MA_iff: ((?v, ?p) \<in> R_MA) = (?v = fst ?p)
```

```text
theorem fw_sim_MA: fw_sim R_MA ADT_M ADT_A
```

```text
theorem refinement_H: ADT_M \<sqsubseteq>\<^sub>F ADT_A
```

第二环不行，得先立不变式（实测）：

```text
theorem invariant_M: ADT_M \<Turnstile> inv_M
```

```text
theorem invariant_C: ADT_C \<Turnstile> inv_C
```

```text
theorem R_CM_iff: ((?p, ?p') \<in> R_CM) = (fst ?p = fst ?p' + snd ?p')
```

`R_CM` 说的是"抽象那边的和 = 具体这边两个分量之和"。
三条前提凑齐就能用 `L_invariantI`：

```text
theorem LI_CM: LI ADT_M ADT_C R_CM (inv_M \<times> inv_C)
```

```text
theorem refinement_C: ADT_C \<sqsubseteq>\<^sub>F ADT_M
```

模型里 `refinement_C` 的证明体和 seL4 主定理一字不差。
真实那一条叫 `refinement`（`l4v/proof/refine/Refine.thy` 第 842--849 行）：

<!-- 源码块：l4v/proof/refine/Refine.thy 第 842--849 行 -->
```text
theorem refinement:
  "ADT_H uop \<sqsubseteq> ADT_A uop"
  apply (rule sim_imp_refines)
  apply (rule L_invariantI)
    apply (rule akernel_invariant)
   apply (rule ckernel_invariant)
  apply (rule fw_sim_A_H)
  done
```

它的第三条前提是 `fw_sim_A_H`（同一文件第 769--773 行）——
一条带着两个不变式乘积的 `LI`：

<!-- 源码块：l4v/proof/refine/Refine.thy 第 769--773 行 -->
```text
lemma fw_sim_A_H:
  "LI (ADT_A uop)
      (ADT_H uop)
      (lift_state_relation state_relation)
      (full_invs \<times> full_invs')"
```

两层的 `data_type` 本身长这样——抽象层
（`l4v/proof/invariant-abstract/ADT_AI.thy` 第 281--286 行）：

<!-- 源码块：l4v/proof/invariant-abstract/ADT_AI.thy 第 281--286 行 -->
```text
definition
  ADT_A :: "user_transition \<Rightarrow> (('a::state_ext state) global_state, 'a observable, unit) data_type"
where
 "ADT_A uop \<equiv>
  \<lparr> Init = \<lambda>s. Init_A, Fin = \<lambda>((tc,s),m,e). ((tc, abs_state s),m,e),
    Step = (\<lambda>u. global_automaton check_active_irq_A (do_user_op_A uop) kernel_call_A) \<rparr>"
```

设计层（`l4v/proof/refine/ADT_H.thy` 第 1167--1173 行）逐项对得上，
`Fin` 里换成了 `absKState`：

<!-- 源码块：l4v/proof/refine/ADT_H.thy 第 1167--1173 行 -->
```text
definition ADT_H ::
  "user_transition \<Rightarrow> (kernel_state global_state, det_ext observable, unit) data_type"
  where
  "ADT_H uop \<equiv>
     \<lparr>Init = \<lambda>s. Init_H,
      Fin = \<lambda>((tc,s),m,e). ((tc, absKState s),m,e),
      Step = (\<lambda>u. global_automaton check_active_irq_H (do_user_op_H uop) kernel_call_H)\<rparr>"
```

`Step` 的索引类型是 `unit`——**"这一步做什么"由 nondet 关系自己带**，
`uop` 已经固化在定义里。两层的 `Step` 都套了同一个
`global_automaton`，差异全在参数（`check_active_irq_A` 对 `check_active_irq_H`）。

C 到设计那一环是 `refinement2`，顶上那条 `seL4_refinement` 只用一条
`refinement_trans` 就把两环接成一条。下面的原文从 `refinement2` 开始：

<!-- 源码块：l4v/proof/crefine/ARM/Refine_C.thy 第 993--1005 行 -->
```text
theorem refinement2:
  "ADT_C uop \<sqsubseteq> ADT_H uop"
  unfolding ADT_C_def
  by (rule refinement2_both)

theorem fp_refinement:
  "ADT_FP_C uop \<sqsubseteq> ADT_H uop"
  unfolding ADT_FP_C_def
  by (rule refinement2_both)

theorem seL4_refinement:
  "ADT_C uop \<sqsubseteq> ADT_A uop"
  by (blast intro: refinement refinement2 refinement_trans)
```

模型里的对应三条（实测）：

```text
theorem refinement_C_M: ADT_C \<sqsubseteq> ADT_M
```

```text
theorem refinement_H_A: ADT_M \<sqsubseteq> ADT_A
```

```text
theorem chain: ADT_C \<sqsubseteq> ADT_A
```

## 20.7 链条怎么接上：模拟关系可以复合

`⊑` 可传（`[trans]`）已经见过。`⊑⇩F` 也可传，靠的是模拟关系本身可复合
（`l4v/lib/Simulation.thy` 第 312--319 行）：

<!-- 源码块：l4v/lib/Simulation.thy 第 312--319 行 -->
```text
lemma fw_sim_trans:
  "\<lbrakk>fw_sim Q C B; fw_sim R B A\<rbrakk> \<Longrightarrow> fw_sim (R O Q) C A"
  by (auto simp: fw_sim_def rel_semi_def; blast)

lemma fw_simulates_trans:
  "\<lbrakk>C \<sqsubseteq>\<^sub>F B; B \<sqsubseteq>\<^sub>F A\<rbrakk> \<Longrightarrow> C \<sqsubseteq>\<^sub>F A"
  apply (auto simp: fw_simulates_def dest: fw_sim_trans)
  done
```

结论里的复合是 `R O Q` 而不是 `Q O R`——**谁在后面对应哪一层**：
`fw_sim Q C B` 的 `Q` 是"中间层↔具体层"，写在里面。
模型里的实测：

```text
theorem
  fw_sim_trans: \<lbrakk>fw_sim ?Q ?C ?B; fw_sim ?R ?B ?A\<rbrakk> \<Longrightarrow> fw_sim (?R O ?Q) ?C ?A
```

真实主链不用它（每环直接复合 `⊑`），但在这里可以把中间关系算出来看看。
先把 C 环换成带切片的 `fw_sim`（`LI_fw_sim` 的直接实例）：

```text
theorem fw_sim_CM_sliced: fw_sim (R_CM \<inter> inv_M \<times> inv_C) ADT_C ADT_M
```

```text
theorem fw_sim_CA: fw_sim (R_MA O (R_CM \<inter> inv_M \<times> inv_C)) ADT_C ADT_A
```

```text
theorem chain_F: ADT_C \<sqsubseteq>\<^sub>F ADT_A
```

复合关系化简后（实测）：

```text
theorem
  R_CA_simp:
    ((?v, ?p) \<in> R_MA O (R_CM \<inter> inv_M \<times> inv_C)) = (?v = fst ?p \<and> snd ?p = 0)
```

中间层的备用字段在复合时被消掉了：`R_CM` 要求
`fst p' = fst p + snd p'`，切片又把 `snd p'` 钉成 0，于是只剩 `v = fst p`。
**这就是"链条接通后中间层消失"的机器可查形式。**

沿链搬运的不只是精化关系，还有不变式本身
（`l4v/lib/Simulation.thy` 第 283--284 行）：

<!-- 源码块：l4v/lib/Simulation.thy 第 283--284 行 -->
```text
lemma fw_inv_transport:
  "\<lbrakk> A \<Turnstile> I\<^sub>a; C \<Turnstile> I\<^sub>c; LI A C R (I\<^sub>a \<times> I\<^sub>c) \<rbrakk> \<Longrightarrow> C \<Turnstile> {s'. \<exists>s. (s,s') \<in> R \<and> s \<in> I\<^sub>a \<and> s' \<in> I\<^sub>c}"
```

真实证明里那个 `full_invs × full_invs'`（上面 `fw_sim_A_H` 的第 773 行）
走的就是这条路。

## 20.8 不变式不是装饰：一个反例

上一节口头上说"没有不变式证不出来"。这里把它证出来：

```text
theorem not_fw_sim_CM: \<not> fw_sim R_CM ADT_C ADT_M
```

反例只有一个可达性之外的状态。模型里那段证明的中间结论（实测）：

```text
have rc: ((1, 0), 0, 1) \<in> R_CM
```

```text
have st: ((0, 1), 0, 0) \<in> Step ADT_C 0
```

```text
have in_right: ((1, 0), 0, 0) \<in> Step ADT_M 0 ;;; R_CM
```

```text
have notin: ((1, 0), 0, 0) \<notin> Step ADT_M 0 ;;; R_CM
```

`((1,0), 0, 1)` 是 `R_CM` 里的一对：抽象值 1 对应具体状态 `(0,1)`——
但 `(0,1)` 不满足 `inv_M`，**根本不在任何执行里**。
`ADT_C` 在 `(0,1)` 上走一步到 `(0,0)`（那条垃圾分支），
`ADT_M` 只能走 `0 + 1`，两边对不上。

于是 `fw_sim R_CM` 假；按 `fw_sim_eq_LI`，这条也假（实测）：

```text
theorem not_LI_CM_univ: \<not> LI ADT_M ADT_C R_CM UNIV
```

好消息是坏行为进不了任何执行。把不变式作为前提提出去（实测）：

```text
theorem
  step_on_inv:
    \<lbrakk>snd ?p = 0; (?p, ?p') \<in> Step ADT_C ?k\<rbrakk> \<Longrightarrow> ?p' = (fst ?p + ?k, 0)
```

于是三层的行为集合可以被算成同一个式子（实测）：

```text
theorem steps_C: steps (Step ADT_C) {(?s, 0)} ?js = {(?s + sum_list ?js, 0)}
```

```text
theorem execution_A: execution ADT_A ?s ?js = {?s + sum_list ?js}
```

```text
theorem execution_C: execution ADT_C ?s ?js = {?s + sum_list ?js}
```

`steps_C` 是对 `js` 归纳、且归纳假设要 `arbitrary: s` 才能用；
这类归纳里 Cons 情形可用的事实叫 `Cons.hyps`（写 `Cons.IH` 会报
`Undefined fact`），因为 `s` 被 arbitrary 掉了，一个 case 里只有一个假设。

## 20.9 性质的搬运：证一次，三层都成立

抽象层证一条 Hoare 三元组（实测）：

```text
theorem
  hoare_A_result: hoare_triple ADT_A {?s} ?js {t. t = ?s + sum_list ?js}
```

然后一次都不再证明，直接换层（实测）：

```text
theorem
  hoare_C_result: hoare_triple ADT_C {?s} ?js {t. t = ?s + sum_list ?js}
```

它的证明体就是 `using chain hoare_triple_refinement hoare_A_result by blast`。
注意前置条件写成 `{?s}` 而不是 `UNIV`：`hoare_triple` 量的是
"从 P 里的**每个**起始状态出发的执行"，而结论 `{t. t = s + sum_list js}`
里那个 `s` 是固定的——用 `UNIV` 会得到一条假命题
（模型第一次就死在这里：`goal: ∀sa. sa = s`）。
**"抽象层证明的安全定理适用于 C 代码"这句话，形式上就是这两条定理之间的那一步。**

## 20.10 假设清单：读证明之前先看它

模型最后把"哪些东西没被验证"写成一个数据类型，两条事实加一条不相交
（实测）：

```text
theorem decompiler_is_external: Decompiler \<in> unverified_assumptions
```

```text
theorem config_is_checked: ConfigSet \<in> verified_assumptions
```

```text
theorem
  assumptions_partition: verified_assumptions \<inter> unverified_assumptions = {}
```

这一节**只有模型是这里的**：本树（`l4v` + `seL4`）里没有
`verified_assumptions`/`unverified_assumptions` 这套常量——
那是另一份代码库里的记号。权威的清单是 `seL4/CAVEATS.md`。

功能正确性覆盖什么、不覆盖什么，第 64--67 行的原话：

<!-- 源码块：seL4/CAVEATS.md 第 64--67 行 -->
```text
This proof covers the functional behaviour of the C code of the kernel. It does
not cover machine code, compiler, linker, boot code, cache or TLB management.
The compiler and linker can be removed from this list by additionally running the
binary verification tool chain for seL4 for AArch32 or RISC-V.
```

顺带白送的性质，第 69--71 行：

<!-- 源码块：seL4/CAVEATS.md 第 69--71 行 -->
```text
Overall, the functional correctness proof shows that the seL4 C code implements
the formal [abstract API specification][ASpec] of seL4 and is free from standard
C implementation defects such as buffer overruns or NULL pointer dereferences.
```

安全性质只在部分配置上有，第 73--80 行：

<!-- 源码块：seL4/CAVEATS.md 第 73--80 行 -->
```text
For AArch32 without hypervisor extensions and without FPU, and for RISC-V, there
are additional proofs that this specification satisfies the following high-level
security properties:

- integrity (no write without authority),
- confidentiality (no read without authority), and
- intransitive non-interference (isolation, modulo timing channels, between
  adequately configured user-level components).
```

同一份文件第 11--13 行还划了一遍功能正确性覆盖的平台范围
（"当前发布版的全部 64 位平台 + 全部 32 位 Arm 平台"），
而 C 层证明是**按平台跑**的：换架构要重跑一整条链。

最后一环（二进制）比很多人以为的要"外部"：
`l4v/proof/asmrefine/README.md` 第 10--17 行说得很直白：

<!-- 源码块：l4v/proof/asmrefine/README.md:10-17 -->
```text
This proof contributes to a larger proof that seL4's compiled binary correctly
implements the [semantics](../../spec/cspec) of its C code. This component of
the proof generates (exports) an external version of the C semantics into the
SydTV-GL language, and proves that the exported version refines the starting C
semantics. A SydTV-GL representation of the binary is created (with proof) by
a decompilation tool based on [HOL4](https://github.com/HOL-Theorem-Prover/HOL),
and the two representations are compared by the [SydTV tool](
https://github.com/seL4proj/graph-refine).
```

也就是说：Isabelle 这边证的是"**导出**的 C 语义精化原来的 C 语义"，
二进制的 SydTV-GL 表示由一个 HOL4 反编译器**带证明**产出，
最后**两份图由外部工具 SydTV 比对**。
同文件第 31--35 行点名了两个理论：
`SEL4SimplExport`（执行导出）与 `SEL4GraphRefine`（证明导出是精化）。
通用装置在 `l4v/tools/asmrefine/`，seL4 专属的在 `l4v/proof/asmrefine/`。

这就是链条的真实形状：链上每一环都在 Isabelle 里，
但**环与环之间最关键的翻译（C 解析、编译、反编译、图比对）在 Isabelle 之外**。

## 20.11 链条的仓库形状：会话、架构、以及链条尽头验了什么

20.1 到 20.10 讲的是"链为什么能接起来"。这一节讲三件一读仓库就会撞上的事：
理论与会话的命名规矩、一条链要按架构跑几遍、以及官方声明"验到哪儿为止"。

### 1. 后缀就是会话名，不是装饰

`l4v` 里一个理论名后面的 `_A`、`_R`、`_C` 不是风格，是**必需品**，
官方约定页把理由写得很清楚：

<!-- 源码块：l4v/docs/conventions.md:65-79 -->
```text
* **postfix:** theory names in `l4v` usually carry a short postfix that indicate
  to which session they belong. This is necessary because the session name in
  current Isabelle is not part of the theory name, and Isabelle will reject
  `Session_A.T` and `Session_B.T` as duplicate theory `T`.

  Examples of postfixes:

  * `T_A` for theories in the abstract specification
  * `T_H` for theories in the design (Haskell) specification
  * `T_AI` for theories in abstract invariants
  * `T_R` for theories in the Refine session
  * `T_C` for theories in the CRefine session

* **prefix**: architecture dependent theories are prefixed with `Arch`.
  **Example:** `ArchDetype_AI` in `proof/invariant-abstract/ARM`
```

理由那一段值得用白话再说一遍：Isabelle 的理论名里不含会话名，
两个会话里各有一条叫 `T` 的理论就直接报重复，所以只能把会话名塞进理论名。
对本章的直接好处是：**看到后缀就知道该去哪个会话找它**。
20.6 那三个 `data_type` 实例在真实树里叫 `ADT_A`、`ADT_H`、`ADT_C`
（19.5 结尾那三条定理用的正是这三个名字），而它们不在三个"ADT"理论里：
`ADT_A` 定义在 `l4v/proof/invariant-abstract/ADT_AI.thy` 第 282 行，
`ADT_H` 在 `l4v/proof/refine/ADT_H.thy` 第 1167 行，
`ADT_C` 在 `l4v/proof/crefine/ARM/ADT_C.thy` 第 1533 行。
一条链上的三层，各自住在以后缀命名的理论里。

会话之间的父子关系写在两份 ROOT 文件里，一条不漏：

| 会话 | 建在 | 声明处 |
|---|---|---|
| `ASpec` | `Word_Lib` | `l4v/spec/ROOT` 第 30 行 |
| `AInvs` | `ASpec` | `l4v/proof/ROOT` 第 63 行 |
| `BaseRefine` | `AInvs` | `l4v/proof/ROOT` 第 55 行 |
| `Refine` | `BaseRefine` | `l4v/proof/ROOT` 第 29 行 |
| `CKernel` | `CParser` | `l4v/spec/ROOT` 第 94 行 |
| `CSpec` | `CKernel` | `l4v/spec/ROOT` 第 82 行 |
| `CBaseRefine` | `CSpec` | `l4v/proof/ROOT` 第 94 行 |
| `CRefine` | `CBaseRefine` | `l4v/proof/ROOT` 第 85 行 |
| `Access` | `AInvs` | `l4v/proof/ROOT` 第 135 行 |
| `InfoFlow` | `Access` | `l4v/proof/ROOT` 第 142 行 |

三点值得注意：`AInvs` 与 `Refine` 之间还夹了一个 `BaseRefine`
（它声明的 sessions 只有 `Lib` 与 `CorresK`，不碰规范侧）；
`CRefine` 那一支的根是 `CSpec`，与抽象侧的 `ASpec` 是**两条独立入口**，
链是在 `CRefine` 内部用 `refinement_trans` 接起来的
（19.5 最后那条 `seL4_refinement` 就是接点）；`Access`/`InfoFlow`
都挂在 `AInvs` 上，不经过 `Refine`——所以第 21、22 章的性质只依赖抽象层不变式。

### 2. 一条链要按架构跑几遍

20.1 那张图上每层都写着"每架构一份"，机制官方写在 `l4v/docs/arch-split.md`：
环境变量 `L4V_ARCH` 决定用哪份内核配置、镜像存哪、以及编译哪些架构目录。
命名规矩是同一段话里定的：

<!-- 源码块：l4v/docs/arch-split.md:55-60 -->
```text
Theories often come in pairs of a generic theory and an associated
architecture-specific theory. Since theory base names must be unique, regardless
of their fully qualified names, we adopt the convention that
architecture-specific theory names are prefixed with "Arch". We don't prefix
with `ARM` or `X64`, because generic theories must be able to import
architecture-specific theories without naming a particular architecture.
```

它下面紧接着给了那个 namespace 的载体——一条没有参数、没有假设的 locale：

<!-- 源码块：l4v/spec/machine/Setup_Locale.thy:12-24 -->
```text
(*
   We use a locale for namespacing architecture-specific definitions.

   The global_naming command changes the underlying naming of the locale. The intention is that
   we liberally put everything into the "ARM" namespace, and then carefully unqualify (put into global namespace)
   or requalify (change qualifier to "Arch" instead of "ARM") in order to refer to entities in
   generic proofs.

*)

locale Arch

end
```

`locale Arch` 下面什么都不写是对的：它只当命名空间用。真正干活的是
`global_naming` 与 `lib/Requalify.thy` 里那几个自定义命令——把 `ARM`
这个限定符换成 `Arch`，泛型证明才能不提具体架构地引用它。
抽象规范侧每个理论开头都在用这套命令，例如
`l4v/spec/abstract/CSpace_A.thy` 的开头：

<!-- 源码块：l4v/spec/abstract/CSpace_A.thy:13-21 -->
```text
theory CSpace_A
imports
  ArchVSpace_A
  IpcCancel_A
  ArchCSpace_A
  "Monads.Nondet_Lemmas"
  "HOL-Library.Prefix_Order"
begin

```

**这里有一处文档与代码对不上，值得单独记。** 同一篇文档举这个例子时说
`CSpace_A.thy` 用 `"./$L4V_ARCH/ArchVSpace_A"` 这种参数化 import，
而今天这份文件里三条 import 都没有 `$L4V_ARCH`：架构目录是挂在会话的
`directories` 里的（`l4v/proof/ROOT` 第 65 行那种 `"$L4V_ARCH"`），
理论名反而要求全局唯一，于是靠 `Arch` 前缀区分。
参数化路径这个写法本身没死，只是不再出现在理论 import 里——
它活下来的地方是一条指向生成物的路径，在
`l4v/spec/cspec/ARM/Kernel_C.thy` 第 15 行。

同一篇文档"Workaround for non-split theories"一节举的 `Retype_R` 也过期了：
那里展示的是 `context begin interpretation Arch . (*FIXME: arch-split*)`
那种临时包法（连 import 都还写着 `VSpace_R`），
而今天的 `l4v/proof/refine/Retype_R.thy` 开头只有 `imports ArchVSpace_R`
加第 15 行一句 `arch_requalify_consts`。
不过这个 workaround 并没有消失——仓库里还有 142 个 `.thy` 文件带着
`FIXME: arch-split` 这条注释。读任何一份证明之前，先确认它落在哪一类：
架构无关、已 split（在 `Arch` locale 里），还是包在临时 context 里。

### 3. 不是所有会话都能直接 `isabelle build`

本章整条链的根上有三个会话依赖**构建时生成**的规范，README 写得很明白：

<!-- 源码块：l4v/README.md:149-153 -->
```text
Not all of the proof sessions can be built directly with the `isabelle build`
command. The seL4 proofs depend on Isabelle specifications that are generated
from the C source code and Haskell model. Therefore, it is recommended to always
build using the `run_tests` command or the supplied Makefiles, which will ensure
that these generated specs are up to date.
```

它后面还补了一句名单：

<!-- 源码块：l4v/README.md:163-165 -->
```text
The sessions that directly depend on generated sources are `ASpec`, `ExecSpec`,
and `CKernel`. These, and all sessions that depend on them, need to be run using
`run_tests` or `make`.
```

也就是说 `ASpec`、`ExecSpec`、`CKernel` 及其一切下游（包括本章整条链）
都要走 `run_tests` 或 `make <session>`，只有不依赖生成物的会话
才能直接 `isabelle build -d . -b <name>`。本教程第 1 章那套只用
`spec/abstract` 与 `proof/invariant-abstract` 的示例会话属于后者，
所以能一条命令跑完；这不是普遍情况，别拿这个经验去猜 `CRefine`。

资源要求也钉在这里，同文件的原话：

<!-- 源码块：l4v/README.md:127-132 -->
```text
Almost all proofs in this repository should work within 4GB of RAM. Proofs
involving the C refinement, will usually need the 64bit mode of polyml and
about 16GB of RAM.

The proofs distribute reasonably well over multiple cores, up to about 8
cores are useful.
```

同一份 README 第 144--147 行还有一句容易漏掉的：`ARM` 的证明最全，
其余架构通常只支持 `ARM` 那套会话的一个子集。

### 4. 链条尽头验的是哪些"性质"

20.9 说"证一次，三层都成立"，那到底证到了什么？官方按配置列在
`docs/projects/sel4/verified-configurations.md`。以 `ARM`（AArch32）为例：

<!-- 源码块：docs/projects/sel4/verified-configurations.md:100-104 -->
```text
- C-level functional correctness, including fast path
- integrity and availability (access control)
- confidentiality (information flow)
- binary correctness, covering C functions that have C-level verification
- model-level functional correctness of the capDL user-level system initialiser/root task
```

同一份文件里其他配置就短得多，而且**不是所有配置都带 fast path**：

| 配置 | 官方列出的已验性质 | 出处 |
|---|---|---|
| `ARM` | 功能正确性（含 fast path）、完整性与可用性、保密性、二进制层正确性、capDL 初始化器 | 第 100--104 行 |
| `ARM_HYP` | 只有"功能正确性（含 fast path）" | 第 132 行 |
| `AARCH64` | 功能正确性（含 fast path）、完整性与可用性、保密性 | 第 161--163 行 |
| `RISCV64` | 功能正确性（**不含 fast path**）、完整性与可用性、保密性 | 第 194--196 行 |
| `X64` | 只有"功能正确性（不含 fast path）" | 第 223 行 |

这张表和本章的关系是具体的：第 21 章那套 `Access` 会话、第 22 章那套
`InfoFlow` 会话，对应的是"完整性/保密性"那两行；`ARM_HYP` 与 `X64`
都没有列这两行，所以拿这两个配置的构建去说"它有信息流安全性"是不成立的。
同一份文件开头还有一句常被略过的话：

<!-- 源码块：docs/projects/sel4/verified-configurations.md:77-79 -->
```text
At present, none of our verified configurations take into account
address translation for devices (System MMU or IOMMU), debug/profiling/printing
interfaces, or the kernel startup at boot.
```

---

## 官方教程对照

| 官方文档 | 覆盖本章哪一段 | 本教程的处理 |
|---|---|---|
| `l4v/docs/conventions.md` | 理论名后缀、`Arch` 前缀 | 20.11 第 1 条 |
| `l4v/docs/arch-split.md` | `L4V_ARCH`、`Arch` locale、临时包法 | 20.11 第 2 条 |
| `l4v/README.md` | 会话依赖生成物、内存与架构覆盖 | 20.11 第 3 条 |
| `docs/projects/sel4/verified-configurations.md` | 每个配置验到哪些性质、哪些东西不验 | 20.11 第 4 条 |
| `l4v/proof/ROOT`、`l4v/spec/ROOT` | 会话父子链 | 20.11 第 1 条的表 |

**1. 这一层的官方"教程"就是这两份 ROOT 加三篇文档。** 镜像里
`docs/Tutorials/` 下没有精化链教程；会话链、生成物依赖、架构覆盖这三件事
的权威口径全在 `l4v/README.md` 与两份 ROOT 文件里。

**2. `arch-split.md` 的三个例子今天都对不上。** `CSpace_A.thy` 那份 import
已无 `$L4V_ARCH`；`Setup_Locale.thy` 的 import 文档里写的是
`"../../lib/Qualify" "../../lib/Requalify" "../../lib/Extend_Locale"`，
实际文件里是 `"Lib.Qualify" "Lib.Requalify"`（第三条已经不 import 了）；
`Retype_R` 那段临时 `context` 包法已被替换。
照抄这篇文档的代码片段之前，先去真实文件里核一遍。

**3. 本教程抄录时发现的三处上游笔误，都照原样引、另加说明**：
`verified-configurations.md` 第 88 行把 AArch32 写成"AArch23"，
同页第 27 行说配置在 configs 这个文件夹、第 62 行的 cmake 示例却写 `config/`；
`l4v/README.md` 里"Proofs involving the C refinement,"多一个逗号。
镜像里 `docs/Tutorials/` 下这几章相关页面全是占位文件，所以本节引用
全部落在 `l4v/docs/`、`l4v/README.md` 与 `docs/projects/sel4/`。

---

## 本章坑位清单（实测）

1. **以为验证的是 C 代码**：验证的是 `l4v/spec/cspec/` 那份 C 规范，
   而它是未验证的 C 解析器（`l4v/tools/c-parser/`）翻译出来的。
2. **把链当一条线**：`l4v/README.md` 第 82--91 行列了 `drefine`、`sep-capDL`
   等分支，capDL 规范到抽象规范是另一条路。
3. **不知道 `data_type` 的三个分量**：`Init :: 'b ⇒ 'a set`（带每运行参数）、
   `Fin :: 'a ⇒ 'b`、`Step :: 'j ⇒ ('a × 'a) set`。
4. **把 `Step` 当函数**：它是**关系族** `'j ⇒ ('a × 'a) set`，
   写成 `'j ⇒ 'a ⇒ 'a set` 直接类型冲突（实测踩过）。
5. **以为 `⊑` 只是"行为包含"**：`hoare_triple_refinement` 给的是
   `=`，即"精化"与"所有 Hoare 三元组可搬运"完全等价。
6. **把 `;;;` 当新运算**：它就是 HOL 的 `O`（`relcomp`），只换了优先级。
7. **以为 `fw_sim` 与 `LI` 是两套东西**：`fw_sim_eq_LI` 说
   `fw_sim r C A = LI A C r UNIV`；注意 `LI` 的参数顺序是抽象层在前。
8. **忘切不变式**：`C_Step` 那条垃圾分支让 `fw_sim` 直接证不出
   （`not_fw_sim_CM`）；必须先 `LI` + 两条 `invariant`，走 `L_invariantI`。
9. **复合方向搞反**：`fw_sim_trans` 的结论是 `R O Q`，不是 `Q O R`。
10. **`hoare_triple` 前置条件随手写 `UNIV`**：结论里若含固定起始值，
    `UNIV` 会得到假命题；写 `{s}`（实测报错 `∀sa. sa = s`）。
11. **归纳里写 `Cons.IH`**：`arbitrary:` 之后 Cons 情形只有一个事实
    `Cons.hyps`，写 `Cons.IH` 报 `Undefined fact`。
12. **`¬P` 的证明起手 `proof -` 再 `assume`**：目标不会被改写，
    最后 `show False` 报 "Failed to refine any pending goal"；
    用 `proof (rule notI)`。
13. **`auto` 想造存在量词证人**：`goal` 里的 `∃y` 它不会自己给，
    改用 `unfolding rel_semi_def by (rule relcompI [OF rc st])`。
14. **反手把 `relcomp_def` 加进 simp 集**：`relcomp_iff` 本来就是 `[simp]`，
    加了反而更差（实测 `auto simp: rel_semi_def` 一步就够）。
15. **以为"验证 = 什么都不用信"**：`seL4/CAVEATS.md` 第 64--67 行列明
    机器码、编译器、链接器、启动码、cache/TLB 都不在范围内；
    二进制那一环还依赖 HOL4 反编译器和外部 SydTV 工具。
16. **在 `l4v` 里找 `unverified_assumptions`**：本树没有这套常量，
    假设清单的权威版本是 `seL4/CAVEATS.md`。
17. **拿 `ADT_A`、`ADT_H`、`ADT_C` 去找同名理论**：三个常量分别定义在
    `ADT_AI.thy`、`ADT_H.thy`、`ADT_C.thy` 里，后缀标的是**会话**不是常量名。
18. **照着 `arch-split.md` 抄参数化 import**：文档举的那三份片段今天都对不上，
    架构目录是靠会话 `directories` 里的 `"$L4V_ARCH"` 挑的。
19. **以为每个配置都验了完整性和保密性**：官方那张性质表里只有 `ARM`、
    `AARCH64`、`RISCV64` 三列有这两项，`ARM_HYP` 与 `X64` 都没有。
20. **以为改了内核配置还能沿用证明**：功能正确性是**按平台**跑的
    （见 `seL4/CAVEATS.md` 那份清单），换配置或换架构要重跑链。

---

上一章：[19 · C 规范与堆](19-cspec.md) ｜ 下一章：[21 · 完整性](21-integrity.md) ｜ 返回：[README](../README.md)
