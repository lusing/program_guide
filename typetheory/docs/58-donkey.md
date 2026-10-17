# 58 证明无关与驴句：计数问题的两面

> 对应读本：罗朝晖书 3.5（证明无关性及关于回指语义的说明）。
> 代码：`examples/58_donkey/ex58_donkey.v`（PI 公理与 Σ 计数、
> **三农夫有限模型上驴句双读法的机器判决——全称读法假/
> 存在读法真**、Most 的书式定义与三元素等价形、|·| 的
> 可计算注脚）。

驴句（donkey sentence）是形式语义学四十年的试金石：

> Every farmer who owns a donkey beats it.
> （每个有毛驴的农夫都会揍它。）

不定名词「一头毛驴」的语义通常是存在量词；但代词 it 引用
它时却在存在量词的**辖域之外**——罗素式的量化架构装不下
这种回指（anaphora）。动态语义学（DRT、DPL 等）为此重建
了整个逻辑基础。本章讲类型论的另一条路——它不需要换逻辑，
只需要**分清两种求和算子**；而这条路的路基石是**证明无关性**
（proof irrelevance）。

## 58.1 证明无关性：为什么必须（书 3.5.1）

命题即类型之下，「`black(b)` 真」意味着类型 black(b) 非空
——但**有几个元素**？直觉主义逻辑里一个真命题可以有多个
互不相等的证明。这对一般数学无妨，对 MTT 语义学是灾难，
因为「通名即类型」把**计数**也交给了类型。书例（3.114）：

> 院子里只有一只黑猫 ⟺ |Σx:C.black(x)| = 1

若 black(b) 有两个证明 p ≠ q，则 (b,p) 与 (b,q) 是 Σ 的
**两个**对象——一只黑猫被数成两只！「如何证明它是黑的」
与计数无关——所以必须保证**同一命题的证明都相等**：

> (PI)　P : Prop，p : P，q : P ⟹ p = q : P

书 82 页给出关键定位：**能否引入 PI 取决于能否区分逻辑
类型与其他类型**。UTT 里 Prop 是独立空间，PI 一条规则
直达（式 3.116：任一命题要么空要么单点）；MLTT 里命题与
类型不分家，PI 会把所有类型压成至多单点——荒谬。所以书
的脚注提出 MLTT_h = HoTT − (UA + HIT)：用 HoTT 的 h-逻辑
（命题截断，67 章）给 MLTT 补上证明无关的命题层。Coq 里
PI 现成：

```coq
Require Import ProofIrrelevance.
Check proof_irrelevance : forall (P : Prop) (p q : P), p = q.
```

## 58.2 计数问题：Σ 兼任存在量词的代价（书 3.5.2 上半）

莫尼奇与 Sundholm 在 80 年代就用 Σ 处理驴句：Σ 的投影
π₁ 能把存在证人「拿出来」用——回指有了着落。但 Σ 在
MLTT 里**身兼两职**：既表子集（黑猫 = Σx:Cat.black(x)），
又表存在量词（有驴 = Σy:Donkey.own(x,y)）。计数崩在这里
（式 3.122–3.124）：

> F_D = Σx:Farmer.Σy:Donkey.own(x,y)

「拥有毛驴的农夫」类型——设 10 个农夫都养驴、其中一人
养 10 头都揍、其余 9 人各养 1 处都不揍：|F_D| ≥ 19 ≠ 10
——「多数有毛驴的农夫都揍它」（Most 版驴句）本该**假**，
但 Σ 计数让 Most_S 判真。**语义错误**。机器件把这个崩塌
缩到三农夫（f1 养 d1、d2，f2 养 d3）：

```coq
Lemma FD_enum : forall z : FD,
  z = mkFD f1 d1 I \/ z = mkFD f1 d2 I \/ z = mkFD f2 d3 I.
```

F_D 有**三个**对象（f1,d1）、(f1,d2)、(f2,d3)——养驴的
农夫只有**两个**。多出来的一个是「f1 拥有 d2 的证明」——
证明混进了计数。

**UTT 的修复：分工**。子集归 Σ（强和，有投影）、存在量词
归 ∃（弱和，无投影、Prop 值）：

> F₁ = Σx:Farmer.**∃**y:Donkey.own(x,y)（式 3.126）

PI 保证 |∃y.own(x,y)| ≤ 1，「怎么证明拥有」不再计数。
机器件两行见证：

```coq
Lemma F1_pi : forall z z' : F1, farmer z = farmer z' -> z = z'.
Proof.
  intros z z' Heq. destruct z as [a Ha]. destruct z' as [b Hb].
  simpl in Heq. subst b. f_equal.
  apply proof_irrelevance.          (* 证明分量被 PI 抹平 *)
Qed.
```

|F₁| = 2 = 养驴农夫数——计数复原（式 3.117：
|Σx:A.Q(x)| = |A|）。注意 MLTT 并非无药可救——只是要引
入独立的弱和算子；UTT 恰好两个都有。

## 58.3 Most：过半的严格定义（定义 3.2 / 书 5.3.3）

驴句的 Most 需要严格定义。书式（有穷类型 A，|A| = n）：

> Most x:A.P(x) := ∃k:Nat. k > n/2 ∧ ∃f:Fin(k)→A. inj(f)
> ∧ ∀x:Fin(k). P(f(x))

「A 中多于半数的对象满足 P」——用**内射函数**从 Fin(k)
（57 章的 Fin 家族）嵌入 A 数出 k 个不同的满足者。机器件
直译（F3 三农夫模型，card := 3），并证出唯一需要的方向：

```coq
Lemma most_two : forall P : F3 -> Prop, Most P ->
  exists a b : F3, a <> b /\ P a /\ P b.
```

Most ⟹ 至少两个不同满足者（k ≥ 2 时取 Fin 的前两位、
inj 保证它们不同）。反向（构造 Fin 见证）在依赖等式的
消解处需要 Fin 1 唯一性辅助引理——机器件用三元素等价形
Most3（至少两个）承接，桥接由 most_two 单向给出：

```coq
Definition Most3 (P : F3 -> Prop) : Prop :=
  exists a b : F3, a <> b /\ P a /\ P b.
Lemma Most_Most3 : forall P, Most P -> Most3 P.
```

## 58.4 驴句双读法：一台戏两个结局（式 3.125 vs 3.129）

「Most farmers who own a donkey beat it」的 it 有两读：

> **全称读法**（3.127）：揍**每一头**自己养的驴
> P_u(z) := ∀y′:D_owned(π₁z). beat(π₁z, π₁y′)
> **存在读法**（3.128）：揍**某头**自己养的驴
> P_e(z) := ∃y′:D_owned(π₁z). beat(π₁z, π₁y′)

回指由 **D_owned = Σy:Donkey.own(x,y) 的投影 π₁** 承载
——Sundholm 的原始洞见保留至今；变的只是外层量词。三农夫
模型（f1 养 d1 d2 只揍 d1；f2 养 d3 揍 d3）上两读分道：

```coq
Theorem universal_Most_false :
  ~ Most (fun x => exists z : F1, farmer z = x /\ P_u z).
Theorem existential_Most3_true : Most3 (fun x =>
  exists z : F1, farmer z = x /\ P_e z).
```

**同一句话，全称假、存在真**——语言学文献争的「驴句歧义」
在类型论里是两个不同命题的机器事实。全称侧的证明走
most_two：若 Most 成立则有两个不同农夫全称地揍驴，其中
必有 f1——而 f1 养 d2 不揍 d2，矛盾：

```coq
pose proof (Hua (mkDo f1 d2 I)) as Hc. cbv in Hc. exact Hc.
```

存在侧构造见证：f1 以 d1、f2 以 d3 各自完成回指。信用卡
句（式 3.130/3.131：每人有信用卡买了电视机都用**它**付账）
只取存在读法——结构同 P_e，书 3.5.2 末的 E-类回指也走
同一条 Σ+∃ 组合路。

## 58.5 一页总结（本章的三个公式）

> PI：同一命题的证明相等——|P| ≤ 1。UTT 有 Prop 独立
> 空间所以能引；MLTT 得靠 HoTT 的 h-逻辑（MLTT_h）补。
> 计数问题：Σ 兼任存在量词则证明混进计数（|F_D| ≠ 农夫数）
> ——UTT 以 Σ(子集) + ∃(弱和) 分工修复。
> 驴句 = 回指走 Σ 投影 π₁ + 量词按读法选择：全称/存在
> 两读在有限模型上真值相反——机器判决。

> **坑位速记**
> ① Record 构造子的 destruct 模式要**平铺全字段**：
>   mkFD 三字段用 `[x y Hp]`，写成 `[x [y Hp]]` 报
>   「disjunctive pattern with 3 branches」（把内层模式
>   当成三构造子析取）；
> ② exists∧exists∧… 的 intro 模式每层合取都**要自己的
>   括号**：`[k [Hk [f [Hinj Hall]]]]`——漏一层括号
>   Coq 把下一个名字当析取模式拆；
> ③ `lia` 不算 Nat.div（`k > 3/2` 关不过）——先 `cbn`
>   把常量除法算掉再 lia；
> ④ 依赖等式的 destruct 有「抽象不良类型」暗礁：目标含
>   单态函数（f : Fin 2 → F3）时 destruct x 抛异常且
>   **try 不捕获**——Most 反向的 Fin 见证证明因此改道
>   Most3（诚实记录在案）；
> ⑤ `apply (lemma _)` 留 evar 时别指望 exact 消——直接
>   把假设应到具体对象（Hua (mkDo f1 d2 I)）一锤定音；
> ⑥ Fixpoint 的结构递归参数必须是归纳类型——`F3 → bool`
>   作递归变元报错，计数函数用 Definition；
> ⑦ 罗素陷阱复刻：`destruct z'` 前若 Heq 含投影项
>   （farmer z = farmer z′），先 `simpl in Heq` 再 subst。

## 58.6 与本书其他线的接口

- 57 章相交形容词的 PI 伏笔——此处兑现；
- 41 章提取（书 3.5 的证明无关性已被引用过一次）——
  Coq 的 Prop 抽取正建立在「证明可以扔」的无关性直觉上；
- 67 章截断（Contr/Prop/Set、Hedberg）——HoTT 的命题截断
  是 PI 的同族：merely-prop 的证明全等；书脚注 MLTT_h 的
  逻辑正是这条线；
- 21 章 λC 的 ∃ 编码（弱和的直系）vs 30 章 Σ（强和）——
  「两种求和」在逻辑编码时代就已分岔；
- 48 章 HM 的隐式 ∀——回指的「话语级」量化与类型重构的
  隐式量化是不同层面的省略机制，对读防混。

## 58.7 章末地图（书 3.5 要点选）

- **书 3.5.1 定义 3.1**（势与同构）——|·| 的形式定义；
  本章 countF 是其可计算注脚；
- **书 3.5.2 动态语义学段**（DRT/文件变换语义/DPL）——
  类型论路线的「对手」介绍：换逻辑 vs 补算子；
- **Sundholm 的 Most_S 与强和/弱和之辨**（脚注）——
  直觉主义「存在证人可提取」的哲学在语义学的投影；
- **E-类回指**（3.5.2 末）——Evans 线的回指理论，Σ+∃
  组合同样覆盖。

---

上一章：[57 形容词修饰](57-adjectives.md) · 下一章：[59 标记与点类型](59-signatures.md)
