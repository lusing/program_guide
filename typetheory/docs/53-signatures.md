# 53 标记与点类型：语境与同谓

> 对应读本：罗朝晖书 4.1（标记：类型论的语境描述机制）、
> 4.2（同谓现象及其点类型语义）。代码：
> `examples/53_signatures/ex53_signatures.v`（Section 局部强制
> =标记子类型条目、单点类型与定义性条目、点类型双投影
> 强制的**合谐正实验**、集胚/子集胚、数字量词「三」）。

两个语言现象把 MTT 语义学推向类型论的进一步扩充：**语境**
（「这个情景里有哪些人和物」——上下文装不下，因为它装的是
变量）与**同谓**（「午餐既可口又费时」——可口要 Food、费时要
Process，两个不相交的论域却要同一顿午餐同时进）。本章两件
武器：**标记（signature）**与**点类型（dot type）**。

## 53.1 标记：常量的描述机制（书 4.1.1–4.1.2）

语境 ≠ 上下文。上下文 `Meng : Cat` 假设 Meng 是**任意**一只
猫——可以被量化抽象成 `∀Meng:Cat.P(Meng)`；但「萌萌」是一只
**具体**的猫，抽象它荒谬。类型论需要描述**常量**的机制——
标记（源于 Edinburgh LF）：

> 标记 Δ ::= c₁:A₁, …, cₙ:Aₙ（属于条目）
> 　　｜ A ≤k B（子类型条目）｜ c~a:A（定义性条目）

判断形式升级为 `Γ ⊢_Δ J`（在标记 Δ 与上下文 Γ 下）。Coq 里
`Parameter` 就是常量语义（不可抽象）。

**子类型条目是局部化的强制**（书 4.1.3）——招牌例子是餐馆
服务员说的：

> 「那个三明治还没付账就走了。」（式 4.4）

「三明治」指称变迁（reference transfer）到「买三明治的顾客」
——`Sandwich ≤k Human` **只在餐馆情景内**成立。机器件用
Coq 的 **Section 作用域**承载局部性：

```coq
Section Restaurant.
  Parameter k53 : Sandwich53 -> Human53.
  Coercion k53 : Sandwich53 >-> Human53.
  Definition sem_4_6 : Prop := ~ pay53 s53 /\ leave53 s53.
End Restaurant.
```

Section 关闭后强制失效——「三明治是人」出了餐馆不再成立。
这是标记类型论 TS[C]（书 6.3.3，局部强制 vs 48 章的全局
T[C]）在 Coq 里的最近亲。

**定义性条目** c~a:A：「c 处处代表 a」。书的技术实现是参数化
单点类型 `1(A,a)`（以 a 为唯一对象），c:1(A,a) 不过是
c~a:A 的另一种写法：

```coq
Definition Singleton1 (A : Type) (a : A) : Type := { x : A | x = a }.
Lemma rep_ok : forall (A B : Type) (a : A) (f : A -> B)
                         (c : Singleton1 A a),
  f (proj1_sig c) = f a.
```

任何函数作用在 c 上都等于作用在 a 上——「代表」的机器含义。
书的 Beatles 例（4.1/4.2）：用属于条目逐个列六位成员（Δ₁），
或用定义性条目一行装下整个情景（Δ 用 D~{John,…}:Type₀、
q_B~q₆:D→Prop）——后者更简洁，且可推广到无穷概念。

## 53.2 同谓现象与点类型（书 4.2.1–4.2.2）

> 午餐挺可口，但花了很长时间。（式 4.9）
> delicious : Food→Prop　take_long : Process→Prop

Food 与 Process 互不相交——「同一顿午餐」却要同时进两个
论域。普斯特约夫斯基的**固有多义性**（inherent polysemy）：
点对象能在「类型说明互相矛盾的选择性语境中出现」。书的
形式化（图 4.3）：点类型 A•B 的规则四组（形成/引入/消去/
计算），形如积类型——**但形成规则多两个前提**：

> A、B 均为封闭类型且 **C(A)∩C(B)=∅**（不共享组成部分，
> 定义 4.1：按范式形状归纳——Σ 形取左支、点形取两支之并）

于是 PHY•PHY、PHY•(PHY•INFO) 都**不**是点类型（共享 PHY）。
这个限制直通**合谐性定理**（定理 4.1）：

> p1 : A•B ≤ A 与 p2 : A•B ≤ B **同时是强制转换且合谐**。

对比 48 章的合谐性反例（π1/π2 同作积类型强制 → Coq 报
ambiguous-paths）——点类型为什么没事？机器件的回答漂亮：
**p1 与 p2 的目标类型不同**（Food vs Process），两条强制
根本不竞争同一配对——Coq **零警告**：

```coq
Record FoodProcess := mkFP
  { fp_food :> Food53 ; fp_proc :> Process53 }.
Axiom lunch_dot : Lunch53 -> FoodProcess.
Coercion lunch_dot : Lunch53 >-> FoodProcess.
Definition sem_4_11 : Prop := delicious l53 /\ take_long l53.
Check sem_4_11 : Prop.      (* 一句双目标，零歧义 *)
```

歧义只在两强制**同目标**时发生（48 章 PairNN 双 nat 字段）
——C(A)∩C(B)=∅ 恰好杜绝了同目标的可能。同法「书」：
Book ≤ PHY•INFO，take（论域 PHY）与 read（论域 INFO）同时
作用于同一本 b（式 4.12–4.14）。

## 53.3 集胚与子集胚：等同标准入列（书 4.2.3）

同谓遇上数词就触到 50 章的伏笔——**等同标准**：

> 张三拿了三本（不同的）书来读。（式 4.15）
> 这三本书都很重，也都很无趣。（式 4.16）

「不同」按什么标准？书「既是物体又含信息」的书要**同时**
按 PHY 和 INFO 两个标准两两不同。通名的语义在最一般情况
下是**集胚（setoid）**：

```coq
Record Setoid := mkSetoid
  { carrier : Type ; equiv : carrier -> carrier -> Prop
  ; equiv_refl  : forall x, equiv x x
  ; equiv_sym   : forall x y, equiv x y -> equiv y x
  ; equiv_trans : forall x y z, equiv x y -> equiv y z -> equiv x z }.
```

**子集胚（subsetoid）**（定义 4.3）：A ⊑ B 当存在强制
c:A→B **且** A 的等同标准是 B 的限制（式 4.21：「两个男人
是同一个男人 ⟺ 同一个人」）——子通名**继承**母通名的等同
标准。多数情况继承成立（所以平时「通名即类型」够用）；
同谓+量词的复杂语境是例外——那时「通名即集胚」。数字量词
「三」（定义 4.4–4.5）在准集胚上定义，双标准的书要求两两
对象同时按两个标准不等：

```coq
Definition Three (A B : Type) (neq : B -> B -> Prop)
  (embed : A -> B) (P : A -> Prop) : Prop :=
  exists x y z : A,
    neq (embed x) (embed y) /\ neq (embed y) (embed z)
    /\ neq (embed x) (embed z)
    /\ P x /\ P y /\ P z.
```

书例 4.4：「三只不同的钢笔」单标准（≠phy）即可；「三本
不同的书」双标准（≠phy ∧ ≠info，定义 4.4 的合取不等）
——同一量词在两类通名上的两种行为。

## 53.4 一页总结（本章的三个公式）

> 标记 = 常量条目 + 子类型条目（局部强制——Section 是它的
> Coq 化身）+ 定义性条目（c:1(A,a) 单点类型技巧）。
> 点类型 A•B：C(A)∩C(B)=∅ ⟹ p1/p2 双投影强制**合谐**
> （目标类型不同不竞争——48 章同目标反例的解）。
> 通名即集胚（类型+等同标准）：子集胚继承标准；同谓×量词
> 的语境必须上集胚——「三本不同的书」按双标准两两不同。

> **坑位速记**
> ① Coq 8.20 预加载库里**没有** JMeq/`string` 等件——
>   参数类型先声明（Cat 都要 Parameters）；54 章同坑；
> ② Section 内的 Coercion 在 End 后失效——这正是「局部
>   强制」的机器化身，但要在 docs 讲明，别当成 bug；
> ③ 点类型的双 `:>` 字段**不触发** ambiguous-paths——
>   警告只认「同源同目标」的路径对；这是定理 4.1 的
>   机器证据（以沉默作证）；
> ④ 声明顺序：`Parameter l53 : Lunch53.` 在 `Parameters
>   Lunch53 : Type.` 之前会报未找到——类型先于对象（本批
>   实测）；
> ⑤ 子集胚的继承条件 (=A)=(=B)|A 形式化时，「限制」要写成
>   谓词组合——完整版比示意版啰嗦得多，教学件点到结构
>   即可（书的定义 4.3 是权威文本）。

## 53.5 与本书其他线的接口

- 48 章合谐性（ambiguous-paths 反例）——本章是其**正例**：
  目标类型不同则双强制并存无碍；
- 34 章 setoid 三文化——集胚在此从工程技巧升格为语义学
  本体（通名的一般形态）；
- 50 章等同标准伏笔（乘客/人计数）——此处正式化；
- 47 章子类型空间——子集胚 ⊑ 与 ≤ 的「带等同标准版」；
- 56 章标记类型论 TS[C] 元理论（定理 6.5 表示定理）——
  本章 Section 化身的正式后盾。

## 53.6 章末地图（书 4.1–4.2 要点选）

- **书例 4.1/4.2**（Beatles 情景的两种标记写法）——属于
  条目 vs 定义性条目的表达力对照；
- **Pustejovsky 1995《生成词库》**——同谓与点类型的源头；
  书的形式化是第一个「有引入/消去规则」的点类型；
- **定理 4.1**（点类型强制合谐性）——证明靠 C(A)∩C(B)=∅
  （去掉限制则 PHY•(PHY•INFO) 立刻给出两条 PHY 强制）；
- **定义 4.4/4.5**（准集胚点运算与 Three）——依赖性等式
  的语义学应用（54 章 JMeq 再遇异类话题）。

---

上一章：[52 证明无关与驴句](52-donkey.md) · 下一章：[54 判断与事件语义](54-judgment.md)
