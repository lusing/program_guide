# 71 · CCL（三）：Type、Hered、Wfd、Fix——类型即项集

对应示例：`../examples/ccl/T71_ccl_type.thy`（IsaTutCCLex 会话，父堆
`IsaTutCCL`）

> 参考：[Isabelle/CCL 库索引](https://dist.isabelle.cit.tum.de/dist/library/FOL/CCL/index.html?token=Isabelle)

## 71.1 类型即项集：Type 理论的核心点子

第 70 章的 CCL 只有一个类型 `i`，"类型"从何而来？`Type` 理论的回答
优雅得离谱：**类型就是 `i` 的子集**。库源码 `src/CCL/Type.thy`
第 12–35 行，六个定义：

```isabelle
definition Subtype :: "['a set, 'a \<Rightarrow> o] \<Rightarrow> 'a set"
  where "Subtype(A, P) == {x. x:A \<and> P(x)}"

syntax
  "_Subtype" :: "[idt, 'a set, o] \<Rightarrow> 'a set"  (\<open>(\<open>indent=1 notation=\<open>mixfix Subtype\<close>\<close>{_: _ ./ _})\<close>)
syntax_consts
  "_Subtype" == Subtype
translations
  "{x: A. B}" == "CONST Subtype(A, \<lambda>x. B)"

definition Unit :: "i set"
  where "Unit == {x. x=one}"

definition Bool :: "i set"
  where "Bool == {x. x=true | x=false}"

definition Plus :: "[i set, i set] \<Rightarrow> i set"  (infixr \<open>+\<close> 55)
  where "A+B == {x. (EX a:A. x=inl(a)) | (EX b:B. x=inr(b))}"

definition Pi :: "[i set, i \<Rightarrow> i set] \<Rightarrow> i set"
  where "Pi(A,B) == {x. EX b. x=lam x. b(x) \<and> (ALL x:A. b(x):B(x))}"

definition Sigma :: "[i set, i \<Rightarrow> i set] \<Rightarrow> i set"
  where "Sigma(A,B) == {x. EX a:A. EX b:B(a).x=<a,b>}"
```

`Unit` 是单元素集，`Bool` 是两个常量，`A+B` 是和类型（`inl/inr`
标签），`Pi(A,B)` 是依赖函数空间（**装的是 λ 抽象**），
`Sigma(A,B)` 是依赖序对。第 37–55 行再给它们配上熟悉的记号：
`PROD x:A. B`、`A -> B`、`SUM x:A. B`、`A * B`；而 `{x:A. P}`
的糖就在上面第 15–20 行（`syntax` + `translations` 两段）。于是
"类型检查"就是普通的成员关系证明，类型规则就是集合成员关系的
引入 / 消去规则——第 69 章那套 I/D/E 命名法原样复用。

六条定义实测（`examples/ccl/T71_ccl_type.thy` 第 34 行）：

```text

  Unit \<equiv> {x. x = one}
  Bool \<equiv> {x. x = true \<or> x = false}
  ?A + ?B \<equiv> {x. (EX a:?A. x = inl(a)) \<or> (EX b:?B. x = inr(b))}
  Pi(?A, ?B) \<equiv> {x. \<exists>b. x = lam x. b(x) \<and> (ALL x:?A. b(x) : ?B(x))}
  Sigma(?A, ?B) \<equiv> {x. EX a:?A. EX b:?B(a). x = <a,b>}
  Subtype(?A, ?P) \<equiv> {x. x : ?A \<and> ?P(x)}
```

这是 Martin-Löf 类型论"命题即类型"的镜像操作：**类型即集合**。
好处是全部类型论设施（依赖和、依赖积、子类型）不需要新的语言
机制，第 69 章的集合运算直接够用。

## 71.2 递归类型：lfp 造有限、gfp 造无穷

库源码第 57–67 行，四个递归类型两行一个：

```isabelle
definition Nat :: "i set"
  where "Nat == lfp(\<lambda>X. Unit + X)"

definition List :: "i set \<Rightarrow> i set"
  where "List(A) == lfp(\<lambda>X. Unit + A*X)"

definition Lists :: "i set \<Rightarrow> i set"
  where "Lists(A) == gfp(\<lambda>X. Unit + A*X)"

definition ILists :: "i set \<Rightarrow> i set"
  where "ILists(A) == gfp(\<lambda>X.{} + A*X)"
```

读法：`Nat` 是方程 `X = Unit + X` 的**最小**解（只含有限多个
`succ`）；`Lists(A)` 是同一方程的**最大**解（有限列表和无限流都在
里面）；`ILists(A)` 把空列表一支砍掉，只剩无穷流。第 69 章的
lfp/gfp 在这里第一次派上实际用场。

八条定义实测（第 59 行）——后三条是配套的 lifted 类型、
按序对切分的 `SPLIT`、两个量化构造：

```text

  Nat \<equiv> lfp((+)(Unit))
  List(?A) \<equiv> lfp(\<lambda>X. Unit + ?A * X)
  Lists(?A) \<equiv> gfp(\<lambda>X. Unit + ?A * X)
  ILists(?A) \<equiv> gfp(\<lambda>X. {} + ?A * X)
  [?A] \<equiv> ?A Un {bot}
  SPLIT(?p, ?B) \<equiv> Union({A. \<exists>x y. ?p = <x,y> \<and> A = ?B(x, y)})
  TALL X. ?B(X) \<equiv> Inter({X. \<exists>Y. X = ?B(Y)})
  TEX X. ?B(X) \<equiv> Union({X. \<exists>Y. X = ?B(Y)})
```

`[A] == A Un {bot}` 是"lifted 类型"——允许发散。这个记号在
第 72 章的类型化程序里到处出现：一个 `[Nat]` 类型的函数可以对
`bot` 返回 `bot`。

三条刻画（第 79 行）说明 `TALL`/`TEX` 就是全称 / 存在：

```text

  ?a : [?A] \<longleftrightarrow> ?a = bot \<or> ?a : ?A
  ?a : TALL X. ?B(X) \<longleftrightarrow> (\<forall>X. ?a : ?B(X))
  ?a : TEX X. ?B(X) \<longleftrightarrow> (\<exists>X. ?a : ?B(X))
```

## 71.3 穷举规则 XHs：定义即五路析取

库源码第 95–102 行把每个类型定义翻成"元素长什么样"的充要条件，
命名后缀 `XH`（exhaustion）：

```isabelle
lemma EmptyXH: "\<And>a. a : {} \<longleftrightarrow> False"
  and SubtypeXH: "\<And>a A P. a : {x:A. P(x)} \<longleftrightarrow> (a:A \<and> P(a))"
  and UnitXH: "\<And>a. a : Unit          \<longleftrightarrow> a=one"
  and BoolXH: "\<And>a. a : Bool          \<longleftrightarrow> a=true | a=false"
  and PlusXH: "\<And>a A B. a : A+B           \<longleftrightarrow> (EX x:A. a=inl(x)) | (EX x:B. a=inr(x))"
  and PiXH: "\<And>a A B. a : PROD x:A. B(x) \<longleftrightarrow> (EX b. a=lam x. b(x) \<and> (ALL x:A. b(x):B(x)))"
  and SgXH: "\<And>a A B. a : SUM x:A. B(x)  \<longleftrightarrow> (EX x:A. EX y:B(x).a=<x,y>)"
  unfolding simp_type_defs by blast+
```

`ML` 那行（源第 111 行）把七条 iff 统一转成消去规则 `case_rls`；
递归类型的四条（`NatXH`/`ListXH`/`ListsXH`/`IListsXH`，源第
258–262 行）则要从不动点方程出发，多绕一步。

非递归类型的 XHs 实测（第 78 行）——七条一字排开，全是"a 在类型里
当且仅当它长什么样"：

```text

  ?a : {} \<longleftrightarrow> False
  ?a : Subtype(?A, ?P) \<longleftrightarrow> ?a : ?A \<and> ?P(?a)
  ?a : Unit \<longleftrightarrow> ?a = one
  ?a : Bool \<longleftrightarrow> ?a = true \<or> ?a = false
  ?a : ?A + ?B \<longleftrightarrow> (EX x:?A. ?a = inl(x)) \<or> (EX x:?B. ?a = inr(x))
  ?a : PROD x:?A. ?B(x) \<longleftrightarrow> (\<exists>b. ?a = lam x. b(x) \<and> (ALL x:?A. b(x) : ?B(x)))
  ?a : SUM x:?A. ?B(x) \<longleftrightarrow> (EX x:?A. EX y:?B(x). ?a = <x,y>)
```

递归类型的四条（第 80 行）——这才是归纳证明的工作母机：

```text

  ?a : Nat \<longleftrightarrow> ?a = zero \<or> (EX x:Nat. ?a = succ(x))
  ?a : List(?A) \<longleftrightarrow> ?a = [] \<or> (EX x:?A. EX xs:List(?A). ?a = x $ xs)
  ?a : Lists(?A) \<longleftrightarrow> ?a = [] \<or> (EX x:?A. EX xs:Lists(?A). ?a = x $ xs)
  ?a : ILists(?A) \<longleftrightarrow> (EX x:?A. EX xs:ILists(?A). ?a = x $ xs)
```

`List` 与 `Lists` 的 XH 文本几乎相同——差的那个 `l`/`s` 决定了
有限与无穷，是本章最大的陷阱（见坑位 3）。

## 71.4 类型规则：构造子与非构造子两条流水线

库源码第 116–123 行。**构造子**（`one/true/false/pair/lam/inl/inr`）
的类型规则七条，全部 `blast intro: XHs`：

```isabelle
lemma oneT: "one : Unit"
  and trueT: "true : Bool"
  and falseT: "false : Bool"
  and lamT: "\<And>b B. (\<And>x. x:A \<Longrightarrow> b(x):B(x)) \<Longrightarrow> lam x. b(x) : Pi(A,B)"
  and pairT: "\<And>b B. \<lbrakk>a:A; b:B(a)\<rbrakk> \<Longrightarrow> <a,b>:Sigma(A,B)"
  and inlT: "a:A \<Longrightarrow> inl(a) : A+B"
  and inrT: "b:B \<Longrightarrow> inr(b) : A+B"
  by (blast intro: XHs [THEN iffD2])+
```

**非构造子**（`if/apply/split/when`）的类型规则要靠 `ncanT` 战术
（源第 145–146 行）——它先把目标用 `case_rls` 拆开，再对每个分支
套前提。注意这些规则的形状与第 70 章的 β 规则一一对应，只是把
`=` 换成 `:`。

构造子七条实测（第 97 行）：

```text

  one : Unit
  true : Bool
  false : Bool
  (\<And>x. x : ?A \<Longrightarrow> ?b(x) : ?B(x)) \<Longrightarrow> lam x. ?b(x) : Pi(?A, ?B)
  \<lbrakk>?a : ?A; ?b : ?B(?a)\<rbrakk> \<Longrightarrow> <?a,?b> : Sigma(?A, ?B)
  ?a : ?A \<Longrightarrow> inl(?a) : ?A + ?B
  ?b : ?B \<Longrightarrow> inr(?b) : ?A + ?B
```

非构造子四条（第 98 行）——每条都是"按输入的类型分派，输出类型
跟着输入走"：

```text

  \<lbrakk>?b : Bool; ?b = true \<Longrightarrow> ?t : ?A(true); ?b = false \<Longrightarrow> ?u : ?A(false)\<rbrakk>
  \<Longrightarrow> if ?b then ?t else ?u : ?A(?b)
  \<lbrakk>?f : Pi(?A, ?B); ?a : ?A\<rbrakk> \<Longrightarrow> ?f ` ?a : ?B(?a)
  \<lbrakk>?p : Sigma(?A, ?B);
   \<And>x y. \<lbrakk>x : ?A; y : ?B(x); ?p = <x,y>\<rbrakk> \<Longrightarrow> ?c(x, y) : ?C(<x,y>)\<rbrakk>
  \<Longrightarrow> split(?p, ?c) : ?C(?p)
  \<lbrakk>?p : ?A + ?B; \<And>x. \<lbrakk>x : ?A; ?p = inl(x)\<rbrakk> \<Longrightarrow> ?a(x) : ?C(inl(x));
   \<And>y. \<lbrakk>y : ?B; ?p = inr(y)\<rbrakk> \<Longrightarrow> ?b(y) : ?C(inr(y))\<rbrakk>
  \<Longrightarrow> when(?p, ?a, ?b) : ?C(?p)
```

注意 `applyT` 的形状：`f : Pi(A,B)` 配 `a : A` 给出
`f ` a : B(a)`——**依赖函数空间真的在依赖**。

下面给一个完整的"类型检查一个真程序"的例子（第 106–115 行）：
函数 `lam n. ncase(n, true, λx. false)`（零映射真、后继映射假）
的类型是 `Nat -> Bool`。构造子一支用 `lamT`，主体用 `ncaseT`，
两条前提各归 `trueT` / `falseT`：

```isabelle
lemma lam_type_demo: "lam n. ncase(n, true, \<lambda>x. false) : Nat -> Bool"
proof (rule lamT)
  fix n assume hn: "n:Nat"
  show "ncase(n, true, \<lambda>x. false) : Bool"
  proof (rule ncaseT[OF hn])
    show "true : Bool" by (rule trueT)
    fix x assume "x:Nat" and "n = succ(x)"
    show "false : Bool" by (rule falseT)
  qed
qed
```

```text
theorem lam_type_demo: lam n. ncase(n, true, \<lambda>x. false) : Nat -> Bool

show true : Bool

show ncase(n, true, \<lambda>x. false) : Bool

show false : Bool
```

三个 Isar 细节都踩过坑，逐一说明：

1. **`rule lamT` 之后必须 `fix n`**：`lamT` 的前提是
   `⋀x. x:A ⟹ b(x):B(x)`，不 `fix` 直接 `show` 会报未绑定变量。
2. **`ncaseT[OF hn]`**：`ncaseT` 的第一条前提是 `?n : Nat`，
   用 `OF hn` 显式关掉。不关的话 `qed` 会残留 `n : Nat` 作子目标
   （第 70 章 `Nat_ind` 同款）。
3. **`show ... by (rule falseT)` 前面不能加 `then`**：`then` 引入的
   链式事实会被 `show` 当额外前提，目标实际变成
   `x:Nat ⟹ n = succ(x) ⟹ false : Bool`，而 `falseT` 的结论是
   `false : Bool`，`rule` 关不掉蕴含式——报
   `Failed to apply initial proof method`。去掉 `then` 即可
   （`fix x assume ...` 之后 `show` 是干净的）。

`pairT` 配上两条前提即用（`examples/ccl/T71_ccl_type.thy`
第 117–118 行）：

```isabelle
lemma pair_type_demo: "<zero, true> : Nat * Bool"
  by (rule pairT[OF zeroT trueT])
```

配套的两个小演示（同文件第 123–131 行）：`zeroT` 直接给出
`zero : Nat`；`succT` 可以串着用，说明"Nat 对 succ 封闭"：

```isabelle
lemma zero_nat: "zero : Nat"
  by (rule zeroT)

lemma succ_succ_nat: "n:Nat \<Longrightarrow> succ(succ(n)) : Nat"
proof -
  assume "n:Nat"
  then have "succ(n):Nat" by (rule succT)
  then show "succ(succ(n)):Nat" by (rule succT)
qed
```

```text
theorem pair_type_demo: <zero,true> : Nat * Bool

theorem zero_nat: zero : Nat

theorem succ_succ_nat: ?n : Nat \<Longrightarrow> succ(succ(?n)) : Nat

have succ(n) : Nat

show succ(succ(n)) : Nat
```

`succ_succ_nat` 里 `then have` / `then show` 都能用——因为这里
`rule succT` 只需要一条前提，链式事实刚好匹配。**判断能否用
`then` 的经验法则：数一下 `rule` 需要几条前提，链里有几条事实。**

## 71.5 从展开方程到归纳规则

库源码第 219–253 行。先用第 69 章的 `def_lfp_Tarski` 把 `lfp`
定义翻成**展开方程**——前提是单调性，而单调性由 `PlusM` /
`SgM` / `constM` / `idM` 四条组合出来（源第 182–215 行）。
`NatM` 与 `def_NatB` 的原文（源第 221–227 行）：

```isabelle
lemma NatM: "mono(\<lambda>X. Unit+X)"
  apply (rule PlusM constM idM)+
  done

lemma def_NatB: "Nat = Unit + Nat"
  apply (rule def_lfp_Tarski [OF Nat_def])
  apply (rule NatM)
  done
```

拿到 `Nat = Unit + Nat` 和 `PlusXH` 一凑，`NatXH`（源第 258–263 行）
就出来了：`Nat` 的元素要么是 `zero`、要么是某个 Nat 的 `succ`。
再往上一步就是**归纳规则**——它来自第 69 章 `Lfp` 理论的通用
`def_induct`（源第 55–60 行），Nat 实例化后正是熟悉的形状：

```isabelle
lemma Nat_ind: "\<lbrakk>n:Nat; P(zero); \<And>x. \<lbrakk>x:Nat; P(x)\<rbrakk> \<Longrightarrow> P(succ(x))\<rbrakk> \<Longrightarrow> P(n)"
```

注意归纳假设里**带 `x:Nat` 守卫**——因为 `Nat` 不是"全部项"，
Nat 外的项不在讨论范围。`nrecT` / `lrecT`（源第 317–325 行）则由
归纳直接给出：原始递归保持类型。

单调性与展开方程实测（第 164 行）——四条方程是全部后续规则的
发动机：

```text

  mono((+)(Unit))
  mono(\<lambda>X. Unit + ?A * X)
  Nat = Unit + Nat
  List(?A) = Unit + ?A * List(?A)
  Lists(?A) = Unit + ?A * Lists(?A)
  ILists(?A) = {} + ?A * ILists(?A)
```

四条归纳 / 递归规则（第 165 行）：

```text

  \<lbrakk>?n : Nat; ?P(zero); \<And>x. \<lbrakk>x : Nat; ?P(x)\<rbrakk> \<Longrightarrow> ?P(succ(x))\<rbrakk> \<Longrightarrow> ?P(?n)
  \<lbrakk>?l : List(?A); ?P([]);
   \<And>x xs. \<lbrakk>x : ?A; xs : List(?A); ?P(xs)\<rbrakk> \<Longrightarrow> ?P(x $ xs)\<rbrakk>
  \<Longrightarrow> ?P(?l)
  \<lbrakk>?n : Nat; ?b : ?C(zero);
   \<And>x g. \<lbrakk>x : Nat; g : ?C(x)\<rbrakk> \<Longrightarrow> ?c(x, g) : ?C(succ(x))\<rbrakk>
  \<Longrightarrow> nrec(?n, ?b, ?c) : ?C(?n)
  \<lbrakk>?l : List(?A); ?b : ?C([]);
   \<And>x xs g.
      \<lbrakk>x : ?A; xs : List(?A); g : ?C(xs)\<rbrakk> \<Longrightarrow> ?c(x, xs, g) : ?C(x $ xs)\<rbrakk>
  \<Longrightarrow> lrec(?l, ?b, ?c) : ?C(?l)
```

`nrecT` 读作：若基例有类型 `C(zero)`，且"归纳假设 `g : C(x)`
能造出 `C(succ(x))`"，则 `nrec(n,b,c) : C(n)`。**这就是"原始递归
保持类型"**——第 70 章那个只会算的 `nrec` 在这里有了类型保证。

## 71.6 gfpI：共归纳装下无穷数据

库源码第 351–372 行。无穷数据的引入规则长这样：

```isabelle
lemma gfpI:
  assumes "a:A"
    and "\<And>x X. \<lbrakk>x:A; ALL y:A. t(y):X\<rbrakk> \<Longrightarrow> t(x) : B(X)"
  shows "t(a) : gfp(B)"
  apply (rule coinduct)
```

读作：只要 `t` 把 `A` 里每个点都推进 `B` 一层，`t(a)` 就在最大
不动点里——这正是第 69 章 `coinduct` 的成员关系版本。库用它证了
一个漂亮例子（源第 365–371 行）：**用 letrec 定义的常流**
`letrec g x be zero$g(x) in g(bot)` 是 `Lists(Nat)` 的元素——
虽然它一步都不会终止。`def_gfpI` 是它的定义形态。

三条规则实测（第 186 行）：

```text

  \<lbrakk>?a : ?A; \<And>x X. \<lbrakk>x : ?A; ALL y:?A. ?t(y) : X\<rbrakk> \<Longrightarrow> ?t(x) : ?B(X)\<rbrakk>
  \<Longrightarrow> ?t(?a) : gfp(?B)
  \<lbrakk>?C \<equiv> gfp(?B); ?a : ?A;
   \<And>x X. \<lbrakk>x : ?A; ALL y:?A. ?t(y) : X\<rbrakk> \<Longrightarrow> ?t(x) : ?B(X)\<rbrakk>
  \<Longrightarrow> ?t(?a) : ?C
  mono(?f) \<Longrightarrow> lfp(?f) <= gfp(?f)
```

第三条 `lfp_subset_gfp` 第 69 章已证过，这里作为库内引用。

配套的 `ci3_RI` / `ci3_AgenI` / `ci3_AI`（源第 396–405 行）是
第 70 章 `eq_coinduct3` 在类型层的三块砖，第 72 章的流等式证明
会直接踩上去。下面演示 `Lists` 对 cons 封闭（第 195–203 行）——
有限列表的规则 `consT` 只管 `List`，这里必须走穷举规则：

```isabelle
lemma lists_cons_demo: "\<lbrakk>h:A; t:Lists(A)\<rbrakk> \<Longrightarrow> h$t : Lists(A)"
  apply (rule ListsXH [THEN iffD2])
  apply (rule disjI2)
  apply (rule_tac x = h in bexI)
   apply (rule_tac x = t in bexI)
    apply (rule refl)
   apply assumption
  apply assumption
  done
```

```text

theorem lists_cons_demo: \<lbrakk>?h : ?A; ?t : Lists(?A)\<rbrakk> \<Longrightarrow> ?h $ ?t : Lists(?A)
```

一条 `ListsXH [THEN iffD2]` 直奔 cons 支：目标 `h$t : Lists(A)`
展开成"`h$t = []` 或存在 `x$xs`"，取 `disjI2` 后两个**有界**
存在量词分别用 `bexI` 给出证人 `x := h`、`xs := t`——每条
`bexI` 留下"谓词成立"与"证人在集合里"两个义务，前者 `refl`
关、后者正好是两条前提。原库用 `blast` 一把过；这里故意展开
成显式规则链，是为了看清 `EX x:A.` 是 **Bex 不是裸 ex**——
`rule exI` 会报 `Failed to apply`（坑位 4 的又一实例）。

## 71.7 Wfd：项上的良基关系

库源码 `src/CCL/Wfd.thy` 第 12–22 行把 HOL 的良基关系整套搬到
项上：

```isabelle
definition Wfd :: "[i set] \<Rightarrow> o"
  where "Wfd(R) == ALL P.(ALL x.(ALL y.<y,x> : R \<longrightarrow> y:P) \<longrightarrow> x:P) \<longrightarrow> (ALL a. a:P)"

definition wf :: "[i set] \<Rightarrow> i set"
  where "wf(R) == {x. x:R \<and> Wfd(R)}"

definition wmap :: "[i\<Rightarrow>i,i set] \<Rightarrow> i set"
  where "wmap(f,R) == {p. EX x y. p=<x,y> \<and> <f(x),f(y)> : R}"

definition lex :: "[i set,i set] => i set"      (infixl \<open>**\<close> 70)
  where "ra**rb == {p. EX a a' b b'. p = <<a,b>,<a',b'>> \<and> (<a,a'> : ra | (a=a' \<and> <b,b'> : rb))}"
```

`Wfd` 直接用 `ALL P` 写出"每个可及子集都全"的定义；`wf(R)` 是
"在 R 里且 R 良基"的项集；`wmap(f,R)` 是把 `R` 经 `f` 搬过来的
关系；`**` 是字典序。两个 ground 关系是主角（源第 24–28 行）：

```isabelle
definition NatPR :: "i set"
  where "NatPR == {p. EX x:Nat. p=<x,succ(x)>}"

definition ListPR :: "i set \<Rightarrow> i set"
  where "ListPR(A) == {p. EX h:A. EX t:List(A). p=<t,h$t>}"
```

即"前驱关系"和"去头关系"。

六条定义实测（第 227 行）：

```text

  Wfd(?R) \<equiv> \<forall>P. (\<forall>x. (\<forall>y. <y,x> : ?R \<longrightarrow> y : P) \<longrightarrow> x : P) \<longrightarrow> (\<forall>a. a : P)
  wf(?R) \<equiv> {x. x : ?R \<and> Wfd(?R)}
  wmap(?f, ?R) \<equiv> {p. \<exists>x y. p = <x,y> \<and> <?f(x),?f(y)> : ?R}
  ?ra ** ?rb \<equiv>
  {p. \<exists>a a' b b'.
         p = <<a,b>,<a',b'>> \<and> (<a,a'> : ?ra \<or> a = a' \<and> <b,b'> : ?rb)}
  NatPR \<equiv> {p. EX x:Nat. p = <x,succ(x)>}
  ListPR(?A) \<equiv> {p. EX h:?A. EX t:List(?A). p = <t,h $ t>}
```

`Wfd(R)` 的定义值得逐字读：**若"一切 R-前驱都在 P 里"能推出
"x 在 P 里"，且这对所有 x 成立，则所有 a 都在 P 里**。这就是
集合论版本的良基归纳——比 HOL 的 `wfP`（用 `∈` 关系）更笨拙，
但换来的是不需要类型层基础设施。

四条核心规则（第 228 行）：

```text

  \<lbrakk>Wfd(?R); \<And>x. \<forall>y. <y,x> : ?R \<longrightarrow> ?P(y) \<Longrightarrow> ?P(x)\<rbrakk> \<Longrightarrow> ?P(?a)
  \<lbrakk>\<And>x y. <x,y> : ?R \<Longrightarrow> ?Q(x); \<forall>x. (\<forall>y. <y,x> : ?R \<longrightarrow> y : ?P) \<longrightarrow> x : ?P;
   \<And>x. ?Q(x) \<Longrightarrow> x : ?P\<rbrakk>
  \<Longrightarrow> ?a : ?P
  \<lbrakk>Wfd(?r); <?a,?x> : ?r; <?x,?a> : ?r\<rbrakk> \<Longrightarrow> ?P
  \<lbrakk>Wfd(?r); <?a,?a> : ?r\<rbrakk> \<Longrightarrow> ?P
```

第一条 `wfd_induct` 是标准形状的强归纳；第二条
`wfd_strengthen_lemma` 是"同时证 Q 和 P"的技巧（HOL 的
`wf_induct` 同款）；后两条说良基关系必然无循环、无自环。

字典序一族（第 229 行）——`lexXH` 是刻画，`lexI1`/`lexI2` 是
两条引入，`lexE` 是消去，`lex_pair` 把序对形态的成员关系拆开，
`lex_wf` 是"字典序保良基"：

```text

  ?p : ?ra ** ?rb \<longleftrightarrow>
  (\<exists>a a' b b'.
      ?p = <<a,b>,<a',b'>> \<and> (<a,a'> : ?ra \<or> a = a' \<and> <b,b'> : ?rb))
  <?a,?a'> : ?ra \<Longrightarrow> <<?a,?b>,<?a',?b'>> : ?ra ** ?rb
  <?b,?b'> : ?rb \<Longrightarrow> <<?a,?b>,<?a,?b'>> : ?ra ** ?rb
  \<lbrakk>?p : ?ra ** ?rb; \<And>a a' b b'. \<lbrakk><a,a'> : ?ra; ?p = <<a,b>,<a',b'>>\<rbrakk> \<Longrightarrow> ?R;
   \<And>a b b'. \<lbrakk><b,b'> : ?rb; ?p = <<a,b>,<a,b'>>\<rbrakk> \<Longrightarrow> ?R\<rbrakk>
  \<Longrightarrow> ?R
  \<lbrakk>?p : ?r ** ?s; \<And>a a' b b'. ?p = <<a,b>,<a',b'>> \<Longrightarrow> ?P\<rbrakk> \<Longrightarrow> ?P
  \<lbrakk>Wfd(?R); Wfd(?S)\<rbrakk> \<Longrightarrow> Wfd(?R ** ?S)
```

映射一族（第 230 行）——`wmap_wf` 说经函数映射保良基，
`wfstI`/`wsndI`/`wthdI` 是三条预置的映射（分别投影序对的第一、
第二、第三分量），用来把 `<<a,b>,<a',b'>>` 上的关系化归到
`<a,a'>` 上：

```text

  ?p : wmap(?f, ?r) \<longleftrightarrow> (\<exists>x y. ?p = <x,y> \<and> <?f(x),?f(y)> : ?r)
  <?f(?a),?f(?b)> : ?r \<Longrightarrow> <?a,?b> : wmap(?f, ?r)
  \<lbrakk>?p : wmap(?f, ?r); \<And>a b. \<lbrakk><?f(a),?f(b)> : ?r; ?p = <a,b>\<rbrakk> \<Longrightarrow> ?R\<rbrakk> \<Longrightarrow> ?R
  Wfd(?r) \<Longrightarrow> Wfd(wmap(?f, ?r))
  <?xa,?ya> : ?r \<Longrightarrow> <<?xa,?xb>,<?ya,?yb>> : wmap(fst, ?r)
  <?xb,?yb> : ?r \<Longrightarrow> <<?xa,?xb>,<?ya,?yb>> : wmap(snd, ?r)
  <?xc,?yc> : ?r \<Longrightarrow> <<?xa,<?xb,?xc>>,<?ya,<?yb,?yc>>> : wmap(thd, ?r)
```

`wf` 集合的四条定律（第 231 行）——`wf_wf`（良基关系的域自身
良基）与 `trancl_wf`（传递闭包保良基）是两个有点意外的结论：

```text

  \<lbrakk>Wfd(?r); ?a : ?r\<rbrakk> \<Longrightarrow> ?a : wf(?r)
  Wfd({})
  Wfd(wf(?R))
  Wfd(?R) \<Longrightarrow> Wfd(?R^+)
```

最后是 Nat/List 前驱关系（第 232 行）——`Wfd(NatPR)` 与
`Wfd(ListPR(A))` 就是第 72 章 `sub`/`div`/`ackermann` 终止证明的
全部弹药：

```text

  ?p : NatPR \<longleftrightarrow> (EX x:Nat. ?p = <x,succ(x)>)
  ?p : ListPR(?A) \<longleftrightarrow> (EX h:?A. EX t:List(?A). ?p = <t,h $ t>)
  ?x : Nat \<Longrightarrow> <?x,succ(?x)> : NatPR
  \<lbrakk>?t : List(?A); ?h : ?A\<rbrakk> \<Longrightarrow> <?t,?h $ ?t> : ListPR(?A)
  Wfd(NatPR)
  Wfd(ListPR(?A))
```

## 71.8 Hered：遗传终止性

库源码 `src/CCL/Hered.thy` 第 18–24 行。前几章的"类型"只管形状，
不管终止；`HTT`（hereditarily terminating terms，遗传终止项）补上
这一维，思路照抄 Martin Löf：

```isabelle
definition HTTgen :: "i set \<Rightarrow> i set" where
  "HTTgen(R) ==
    {t. t=true | t=false | (EX a b. t= <a, b> \<and> a : R \<and> b : R) |
      (EX f. t = lam x. f(x) \<and> (ALL x. f(x) : R))}"

definition HTT :: "i set"
  where "HTT == gfp(HTTgen)"
```

`bot` 被**排除**在外——这就是"终止"的含义。注意库自己的免责
声明（源第 12–16 行）：`lam x. b(x)` 属于 HTT 当且仅当**所有**
`x` 都让 `b(x)` 终止，所以对函数不太有用；真正好用的是 `Nat` /
`List` 这些**数据**类型，它们的形成规则（`NatF` / `ListF` /
`ListsF` / `IListsF`，源第 133–166 行）用余归纳证成，说明"数据
构造子保终止"。

定义与刻画实测（第 257 行）：

```text

  HTTgen(?R) \<equiv>
  {t. t = true \<or>
      t = false \<or>
      (\<exists>a b. t = <a,b> \<and> a : ?R \<and> b : ?R) \<or>
      (\<exists>f. t = lam x. f(x) \<and> (\<forall>x. f(x) : ?R))}
  HTT \<equiv> gfp(HTTgen)
  mono(HTTgen)
  ?t : HTTgen(?A) \<longleftrightarrow>
  ?t = true \<or>
  ?t = false \<or>
  (\<exists>a b. ?t = <a,b> \<and> a : ?A \<and> b : ?A) \<or>
  (\<exists>f. ?t = lam x. f(x) \<and> (\<forall>x. f(x) : ?A))
  ?t : HTT \<longleftrightarrow>
  ?t = true \<or>
  ?t = false \<or>
  (\<exists>a b. ?t = <a,b> \<and> a : HTT \<and> b : HTT) \<or>
  (\<exists>f. ?t = lam x. f(x) \<and> (\<forall>x. f(x) : HTT))
```

`HTTXH` 是 `HTTgenXH` 把 `?A` 换成 `HTT` 的实例——又一次
"gfp 方程 + 生成子刻画"。simp 规则组 `HTT_rews`（第 258 行，
注意输出里它被打印了两遍，一次来自 `thm HTT_bot ... HTT_rews`，
一次来自紧随的 `HTT_rews` 本身——内容相同）：

```text

  \<not> bot : HTT
  true : HTT
  false : HTT
  <?a,?b> : HTT \<longleftrightarrow> ?a : HTT \<and> ?b : HTT
  lam x. ?f(x) : HTT \<longleftrightarrow> (\<forall>x. ?f(x) : HTT)
  \<not> bot : HTT
  true : HTT
  false : HTT
  <?a,?b> : HTT \<longleftrightarrow> ?a : HTT \<and> ?b : HTT
  lam x. ?f(x) : HTT \<longleftrightarrow> (\<forall>x. ?f(x) : HTT)
  one : HTT
  inl(?a) : HTT \<longleftrightarrow> ?a : HTT
  inr(?b) : HTT \<longleftrightarrow> ?b : HTT
  zero : HTT
  succ(?n) : HTT \<longleftrightarrow> ?n : HTT
  [] : HTT
  ?x $ ?xs : HTT \<longleftrightarrow> ?x : HTT \<and> ?xs : HTT
```

余归纳规则（第 259 行）——`HTT_coinduct` 是第 69 章 `coinduct`
的直接实例，`HTT_coinduct3` 是 `eq_coinduct3` 的同款强化版，
`HTTgenIs` 是生成子的引入规则族：

```text

  \<lbrakk>?t : ?R; ?R <= HTTgen(?R)\<rbrakk> \<Longrightarrow> ?t : HTT
  \<lbrakk>?t : ?R; ?R <= HTTgen(lfp(\<lambda>x. HTTgen(x) Un ?R Un HTT))\<rbrakk> \<Longrightarrow> ?t : HTT
  true : HTTgen(?R)
  false : HTTgen(?R)
  \<lbrakk>?a : ?R; ?b : ?R\<rbrakk> \<Longrightarrow> <?a,?b> : HTTgen(?R)
  (\<And>x. ?b(x) : ?R) \<Longrightarrow> lam x. ?b(x) : HTTgen(?R)
  one : HTTgen(?R)
  ?a : lfp(\<lambda>x. HTTgen(x) Un ?R Un HTT) \<Longrightarrow>
  inl(?a) : HTTgen(lfp(\<lambda>x. HTTgen(x) Un ?R Un HTT))
  ?b : lfp(\<lambda>x. HTTgen(x) Un ?R Un HTT) \<Longrightarrow>
  inr(?b) : HTTgen(lfp(\<lambda>x. HTTgen(x) Un ?R Un HTT))
  zero : HTTgen(lfp(\<lambda>x. HTTgen(x) Un ?R Un HTT))
  ?n : lfp(\<lambda>x. HTTgen(x) Un ?R Un HTT) \<Longrightarrow>
  succ(?n) : HTTgen(lfp(\<lambda>x. HTTgen(x) Un ?R Un HTT))
  [] : HTTgen(lfp(\<lambda>x. HTTgen(x) Un ?R Un HTT))
  \<lbrakk>?h : lfp(\<lambda>x. HTTgen(x) Un ?R Un HTT);
   ?t : lfp(\<lambda>x. HTTgen(x) Un ?R Un HTT)\<rbrakk>
  \<Longrightarrow> ?h $ ?t : HTTgen(lfp(\<lambda>x. HTTgen(x) Un ?R Un HTT))
```

后八条形状很怪——它们是给 `HTT_coinduct3` 用的：余归纳关系要
装进 `lfp(...)`，所以生成子的引入规则也得跟着实例化到这个
`lfp` 上。

七个数据类型的"保终止"定律（第 260 行）：

```text

  Unit <= HTT
  Bool <= HTT
  \<lbrakk>?A <= HTT; ?B <= HTT\<rbrakk> \<Longrightarrow> ?A + ?B <= HTT
  \<lbrakk>?A <= HTT; \<And>x. x : ?A \<Longrightarrow> ?B(x) <= HTT\<rbrakk> \<Longrightarrow> SUM x:?A. ?B(x) <= HTT
  Nat <= HTT
  ?A <= HTT \<Longrightarrow> List(?A) <= HTT
  ?A <= HTT \<Longrightarrow> Lists(?A) <= HTT
  ?A <= HTT \<Longrightarrow> ILists(?A) <= HTT
```

库的 `HTT_rews` 把 HTT 的判定挂成 simp：
`succ(n) : HTT ⟷ n : HTT`、`x$xs : HTT ⟷ x : HTT ∧ xs : HTT`……
于是一个具体项三行收敛到 `zero` / `[]`（第 274–275 行）：

```isabelle
lemma htt_demo: "succ(zero) : HTT"
  by (simp add: HTT_rews)

lemma htt_pair_demo: "<zero, true> : HTT"
  by (simp add: HTT_rews)
```

```text

theorem htt_demo: succ(zero) : HTT

theorem htt_pair_demo: <zero,true> : HTT
```

`htt_pair_demo` 的 simp 路径：`HTT_pair` 把目标拆成两条
`zero : HTT` 与 `true : HTT`，前者经 `succ_HTT` 归约到
`zero : HTT`（`HTT_rews` 里的 `zero : HTT` 直接命中），后者
经 `true : HTT` 命中。

## 71.9 Fix：不动点归纳与「可达性」

库源码 `src/CCL/Fix.thy`，标题自带苦笑：
`Tentative attempt at including fixed point induction; justified by Smith`。
思路是造一个**包含性谓词** `INCL`：

```isabelle
axiomatization INCL :: "[i\<Rightarrow>o]\<Rightarrow>o" where
  INCL_def: "INCL(\<lambda>x. P(x)) == (ALL f.(ALL n:Nat. P(f^n`bot)) \<longrightarrow> P(fix(f)))" and
  po_INCL: "INCL(\<lambda>x. a(x) [= b(x))" and
  INCL_subst: "INCL(P) \<Longrightarrow> INCL(\<lambda>x. P((g::i\<Rightarrow>i)(x)))"
```

读作：`P` 包含，若"对所有 n 有 `P(f^n`bot)` 就能推出
`P(fix(f))`"——即 P 对**有限逼近的极限**封闭。配上基例与步进就
得到不动点归纳：

```isabelle
lemma fix_ind:
  assumes base: "P(bot)"
    and step: "\<And>x. P(x) \<Longrightarrow> P(f(x))"
    and incl: "INCL(P)"
  shows "P(fix(f))"
```

步进 `P(x) ⟹ P(f(x))` 配基例 `P(bot)` 给出
`∀n. P(f^n`bot)`（对 `n` 归纳），`incl` 再把它推到极限。库还给出
四条 INCL 的代数（`conj_INCL` / `all_INCL` / `ball_INCL`）和一条
与行为等价的接口 `eq_INCL`。

定义与规则实测（第 313–315 行）：

```text

  idgen(?f) \<equiv>
  lam t. case(t, true, false, \<lambda>x y. <?f ` x,?f ` y>, \<lambda>u. lam x. ?f ` u(x))
  INCL(?P) \<equiv> \<forall>f. (ALL n:Nat. ?P(f ^ n ` bot)) \<longrightarrow> ?P(fix(f))
  INCL(\<lambda>x. ?a(x) [= ?b(x))
  INCL(?P) \<Longrightarrow> INCL(\<lambda>x. ?P(?g(x)))
  \<lbrakk>?P(bot); \<And>x. ?P(x) \<Longrightarrow> ?P(?f(x)); INCL(?P)\<rbrakk> \<Longrightarrow> ?P(fix(?f))
```

```text

  INCL(?P) \<longleftrightarrow> (\<forall>f. (ALL n:Nat. ?P(f ^ n ` bot)) \<longrightarrow> ?P(fix(f)))
  (\<And>f. ALL n:Nat. ?P(f ^ n ` bot) \<Longrightarrow> ?P(fix(f))) \<Longrightarrow> INCL(?P)
  \<lbrakk>INCL(?P); \<And>n. n : Nat \<Longrightarrow> ?P(?f ^ n ` bot)\<rbrakk> \<Longrightarrow> ?P(fix(?f))
  \<lbrakk>INCL(?P); (ALL n:Nat. ?P(?f ^ n ` bot)) \<longrightarrow> ?P(fix(?f)) \<Longrightarrow> ?R\<rbrakk> \<Longrightarrow> ?R
```

```text

  INCL(\<lambda>x. \<not> ?a(x) [= ?t)
  \<lbrakk>INCL(?P); INCL(?Q)\<rbrakk> \<Longrightarrow> INCL(\<lambda>x. ?P(x) \<and> ?Q(x))
  (\<And>a. INCL(?P(a))) \<Longrightarrow> INCL(\<lambda>x. \<forall>a. ?P(a, x))
  (\<And>a. a : ?A \<Longrightarrow> INCL(?P(a))) \<Longrightarrow> INCL(\<lambda>x. ALL a:?A. ?P(a, x))
  INCL(\<lambda>x. ?a(x) = ?b(x))
```

`eq_INCL`（最后一条）用起来最顺手：**点等则不动点处也等**。
下面演示一次完整使用（`examples/ccl/T71_ccl_type.thy` 第 316–332
行）——归纳证明 `∀n` 那支正是 `Nat_ind` 的用武之地：

```isabelle
lemma fix_cong_demo:
  fixes a b :: "i \<Rightarrow> i"
  assumes h: "\<And>x. a(x) = b(x)"
  shows "a(fix(f)) = b(fix(f))"
proof (rule inclD)
  show "INCL(\<lambda>x. a(x) = b(x))" by (rule eq_INCL)
  show "\<And>n. n:Nat \<Longrightarrow> a(f^n`bot) = b(f^n`bot)"
  proof -
    fix n assume hn: "n:Nat"
    show "a(f^n`bot) = b(f^n`bot)"
    proof (rule Nat_ind[OF hn])
      show "a(f^zero`bot) = b(f^zero`bot)" by (simp add: napplyBzero h)
      fix x assume "x:Nat" and ih: "a(f^x`bot) = b(f^x`bot)"
      show "a(f^succ(x)`bot) = b(f^succ(x)`bot)" by (simp add: napplyBsucc h)
    qed
  qed
qed
```

```text
theorem fix_cong_demo:
 (\<And>x. ?a(x) = ?b(x)) \<Longrightarrow> ?a(fix(?f)) = ?b(fix(?f))

show INCL(\<lambda>x. a(x) = b(x))
```

这个证明把本章三个机制串成一条线：

1. **`inclD`**：`INCL(P)` + `∀n. P(f^n`bot)` ⟹ `P(fix(f))`——
   把目标拆成"包含性"与"有限逼近全中"两条；
2. **`eq_INCL`** 一条关掉包含性义务（这正是它的用途）；
3. **`Nat_ind[OF hn]`** 证"有限逼近全中"——注意 `OF hn` 不能省，
   否则 `Nat_ind` 会留下 `n:Nat` 作第一个子目标（同 71.4 的
   `ncaseT`）。

**两个必须写对的细节**（都踩过）：

- **`fixes a b :: "i \<Rightarrow> i"` 不能省**：不写的话 `a`/`b` 的
  类型推断不落位，`eq_INCL`（`INCL(λx. a(x) = (b(x)::'a::prog))`）
  与目标无法合一，`by (rule eq_INCL)` 报失败。
- **`proof (rule Nat_ind)` 不能省 `OF hn`**：`Nat_ind` 的第一条
  前提是 `?n : Nat`，用 `proof (rule Nat_ind)` 会把它留成第一个
  子目标，随后的 `show "a(f^zero`bot) = ..."` 报
  `Failed to refine any pending goal`。要么 `OF hn`，要么
  `proof -` + `fix n assume hn` + `Nat_ind[OF hn]`。

库的终极目标是**项的结构归纳**。`idgen` 是"恒等函数的泛函"
（源第 12–13 行），库证明它的所有不动点都是 λ（`idgenfp_lam`），
且 `fix(idgen)` 与 `lam x. x` 互为最小不动点——两条 `[=` 一夹
就是 `reachability`：

```isabelle
lemma reachability: "fix(idgen) = lam x. x"
```

有了它，任何项都能写成 `fix(idgen) ` t`，再对 `t` 用 `fix_ind`，
就得到无类型世界的结构归纳原理 `term_ind`（源第 178–196 行）——
五路基例加一个 `INCL` 义务，与第 70 章的 `term_case` 正好一对
（消去 / 归纳）。

最后一组实测（第 389 行前后 `thm`）覆盖这条链条的每一环。

## 71.10 坑位清单（实测）

1. **`:` 是成员关系不是 HOL 的类型标注**：`a : Nat` 是一条
   **命题**，可以被 simp、blast、余归纳规则操作；HOL 里
   `a :: nat` 是类型约束，两者语义完全不同，别混写。
2. **`Nat` / `List` / `Bool` / `Unit` 是 CCL 的集合常量**，与 HOL
   同名类型（`nat` / `'a list` / `bool`）毫无关系；本章一律小写
   字母打头的 `i set`。
3. **`List(A)` 与 `Lists(A)` 只差一个字母**：前者 lfp（有限），
   后者 gfp（含无穷）。规则也分成两套：`consT` 属于 `List`，
   `Lists` 只能用 `ListsXH` 或 `gfpI`。
4. **递归类型的归纳规则带守卫**：`Nat_ind` 的归纳假设是
   `⟦x:Nat; P(x)⟧`，对 Nat 外的项一无所知；照抄 HOL 数归的形状
   会少一条前提，blast 到一半报 `Failed to refine`。另外
   `EX x:A.` 是 **Bex 不是裸 ex**：给证人要用 `bexI`（谓词成立、
   证人在集合里两个义务），`rule exI` 直接报 `Failed to apply`；
   且 `auto simp add: ListsXH` 在 process_theories 下会**无限
   发散**（iff 里嵌 EX，classical tableau 展开不封顶），改成
   `ListsXH [THEN iffD2]` + `bexI` 显式规则链一秒收敛。
5. **`rule lamT` 之后要对绑定变量 `fix`**：`lamT` 的前提是
   `⋀x. x:A ⟹ b(x):B(x)`，不 `fix` 直接 `show` 会报未绑定。
6. **`ncanT` / `incanT` / `typechk` / `gen_ccs` / `clean_ccs`
   都是库的 `method_setup`**，只在加载过 Type/Wfd 理论后可见；
   Draft 会话 `-l IsaTutCCL` 已带，换父堆要重新确认。
7. **`HTT_rews` 是 simp 规则**，所以 `succ(zero) : HTT` 一步过；
   但它**不**知道 `letrec` 定义的函数，对函数项基本无能为力
   （库源码第 12–16 行自认）。
8. **`INCL` 是公理不是定理**：`INCL_def` 把"包含"定义成一条
   全称命题，`inclI` 是唯一入口；想证 `INCL(P)` 必须对**任意**
   `f` 证明那个蕴含式，大多数直观上"包含"的谓词其实证不出。
9. **`eq_INCL` 的 `a` / `b` 是函数变量**：
   `INCL(λx. a(x) = b(x))` 里 `a` `b` 要被合一成具体的项函数，
   写成 `a(t) = b(t)`（单个点）形式会被 `inclD` 用不上。
10. **`reachability` 的证明用了 `fix_idgenfp` 与 `id_idgenfp`
    两条自反**，读库源码时注意 `idgen` 的 case 五支（源第
    12–13 行）与 `term_case` 的五支一一对应，这是整条证明的骨架。
## 71.11 与其他章的接口

- 第 70 章：`ncase`/`nrec` 在这里升级为 `ncaseT`/`nrecT`；
  `eq_coinduct3` 在类型层有三块砖 `ci3_RI`/`ci3_AgenI`/`ci3_AI`。
- 第 69 章：`lfp`/`gfp`/`coinduct`/`def_induct` 是本章全部
  定义与规则的来源。
- 第 72 章：`NatPR`/`ListPR` 的良基性直接用于 `sub`/`div`/
  `ackermann` 的终止证明；`HTT_rews` 用于类型检查。


上一章：[70 · CCL（二）：无类型 λ 演算与行为等价](70-ccl-lambda.md) ｜ 下一章：[72 · CCL（四）：四个可执行例子](72-ccl-programs.md) ｜ 返回：[README](../README.md)
