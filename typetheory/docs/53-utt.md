# 53 UTT 与类型空间：Prop 与 Type 的统一

> 对应读本：罗朝晖《现代类型论的发展与应用》第 1 章（概论）、
> 2.4（类型空间）、2.5.3 节 1（子类型类型空间）；6.3.1（UTT 的
> 形式化）在 62 章展开。代码：
> `examples/53_utt/ex53_utt.v`（Prop 非直谓见证、莱布尼茨等式
> 与逻辑算子的 ∀ 编码、宇宙塔、佩亚诺第四公理、CN 宇宙与
> Π-多态副词、子类型空间 U(H) 的依赖对编码）。

从本章起进入**罗朝晖专轮**。前四部分走过的谱系——Hindley/
Farmer 的简单类型论（02–17）、TTAFP 的 λ 立方体（18–26）、
Nordström 的 Martin-Löf 类型论（27–33）、TAPL 的程序语言
类型论（42–52）——在本章合流为一个统一的现代类型论
（modern type theory）：**统一类型论 UTT（Unifying Theory of
dependent Types）**，以及它身后的整个「现代类型论」家族
（含 Coq 的 pCIC、本书的构造演算后裔）。本章处理三件事：
直谓与非直谓的分野、**类型空间（宇宙）**的两种读法、以及
「通名的宇宙 CN」——它是 56–64 章整块 MTT 语义学的地基。

## 53.1 直谓还是非直谓：现代类型论的分家（书 1.1）

罗素把悖论归咎于「恶性循环」，分支类型论用归约公理修补；
拉姆塞指出逻辑悖论与语义悖论应当分开，简单类型论由此
「简化」而出（02 章的历史线）。真正的分家发生在 1971 年：
Martin-Löf 最初的类型论含一个「所有类型的类型」
`Type : Type`——**Girard 证明它不相容**（Girard 悖论）。
书 1.1 脚注给出漂亮的病理分析：`Type : Type` 来自两条基本
思想的合流——

1. 所有命题组成一个非直谓类型（简单类型论的非直谓原则）；
2. 命题与类型是**同一概念**（Curry–Howard 的强读法：不仅
   所有命题都是类型，所有类型也都是命题！）。

把（1）里的「命题」换成「类型」就得到 `Type : Type`。
现代类型论各家按取舍分三支：

| 取舍 | 系统 | 结果 |
|---|---|---|
| 弃（1）保（2） | Martin-Löf 类型论、HoTT（27–33、63–74 章） | **直谓**：宇宙塔 U₀ ∈ U₁ ∈ … |
| 保（1）弃（2） | 构造演算 CoC、**UTT** | **非直谓**：Prop 一个非直谓空间 + 直谓数据塔 |
| 全保 | Type:Type 系统 | **不相容**（Girard 悖论） |

Coq（pCIC）正是 UTT 谱系的实现后裔——本章机器件里
`Prop` 的行为就是 UTT 的 `Prop`。

## 53.2 Prop：非直谓的命题空间（书 2.4.1）

UTT 的双层结构（书图 1.1）：**数据类型**（Nat、Π、Σ…）
住在直谓塔 `Type₀, Type₁, …` 里；**逻辑命题**（∀…）住在
非直谓空间 `Prop` 里。全称命题的形成规则只有一条：

> (V)　A type，P(x) : Prop ⟹ ∀x:A.P(x) : Prop

关键在 A **可以是任意类型**——包括 `Prop` 自己或
`Prop → Prop` 这样的高阶类型。机器件直接见证非直谓性：

```coq
Definition imp_id : Prop := forall X : Prop, X -> X.
Definition hh : Prop := forall F : Prop -> Prop,
  forall X : Prop, F X -> F X.
```

`imp_id` 量化域是 Prop 本身——「对所有命题 X」。这在
直谓类型论（MLTT）里写不出：那里的宇宙塔禁止对「全部
命题」一次量化。

**逻辑算子全部由 ∀ 定义**（书式 2.16–2.18）——二阶编码，
21 章 λC 逻辑编码的直达：

```coq
Definition leib (A : Type) (a b : A) : Prop :=
  forall P : A -> Prop, P a -> P b.     (* 莱布尼茨等式 *)
Definition and' (P Q : Prop) : Prop :=
  forall X : Prop, (P -> Q -> X) -> X.  (* 合取 *)
Definition ex' (A : Type) (P : A -> Prop) : Prop :=
  forall X : Prop, (forall x : A, P x -> X) -> X.  (* 存在 *)
```

机器件里 `and'_comm`（交换律）不需要排中——纯构造可证。
莱布尼茨等式的对称性要一个小技巧（把谓词 `Q y := P y → P a`
喂给等式证明），这是 25 章 Leibniz 等式的 Coq 复刻：

```coq
Lemma leib_sym : forall (A : Type) (a b : A),
  leib A a b -> leib A b a.
Proof.
  intros A a b H P pb.
  exact (H (fun y => P y -> P a) (fun pa => pa) pb).
Qed.
```

**Prop 与 Type 的关系**（书 2.4.2 末）：`Prop : Type₀` 且
每个 `P : Prop` 也是 `Type₀` 的对象（`Prop ⊆ Type₀`）。
这不是装饰——没有它，`Σx:A.(x =_A x) : Type₀` 这类
「数据 + 命题性质」的 类型就写不出。机器件：

```coq
Definition ReflexiveType (A : Type) : Type :=
  { x : A | x = x }.        (* sig : Type，分量在 Prop *)
```

还有一层容易被忽略的澄清（书 2.4.2 第 3 节）：Type_i
**表面上**非直谓（可以对 Type₀ 量化得到 Prop 的对象），但
这些非直谓性全部**来自 Prop**——Type 自身的构造规则仍是
严格分层的，所以 Type_i 本质直谓。这是 UTT「两层各司其职」
的精义。

## 53.3 塔斯基式与罗素式：宇宙的两种读法（书 2.4.2）

Martin-Löf 提出直谓宇宙的两种描述。**罗素式（à la
Russell）**：`A : Uᵢ` 直接说「A 是 Uᵢ 的对象」，而 Uᵢ 的
对象本身就是类型——符号简洁，但**混淆了类型与对象**，会
让规范性（canonicity）等元理论性质失效。**塔斯基式（à la
Tarski）**：Uᵢ 的对象是**类型名称**（code），由解释函数
`Tᵢ` 还原成真类型：

> nat₀ : U₀ 且 T₀(nat₀) = Nat；名称提升 a : Uᵢ ⟹ tᵢ₊₁(a) : Uᵢ₊₁
> 且 Tᵢ₊₁(tᵢ₊₁(a)) = Tᵢ(a)

准确但啰嗦。罗朝晖的观察（书引文献 [137]）：**塔斯基式 +
强制性子类型 = 两全**——把提升算子 tᵢ₊₁ 注册成强制转换，
名称层自动融入类型层，准确性与便利兼得。这是 54 章
强制性子类型的第一个「实战应用」，也是 31 章宇宙塔的
UTT 读法。

机器件里宇宙塔的层级性由 Coq 的 `Type@{i}` 体现：

```coq
Check Set : Type.
Check Type : Type.       (* 层级塔：两个 Type 是不同层的宇宙 *)
```

`Type : Type` 能通过检查恰恰因为 Coq 默默新建了更高的
宇宙层 i < j——自指被层级隔断，Girard 悖论无门可入。

## 53.4 佩亚诺第四公理：宇宙的必要性（书例 2.7）

书里一个漂亮的「没有宇宙就证不出」的例子。第四公理
`∀x:Nat. 0 ≠ succ(x)`——在非直谓类型论里用莱布尼茨等式
证明时，必须定义谓词 `IsZero : Nat → Prop`：

```coq
Definition IsZero (n : nat) : Prop :=
  match n with O => True | S _ => False end.
```

它的**值域是命题**（true/false 本身是类型——命题即类型），
所以值域必须是类型空间 Prop。没有类型空间，IsZero 无法
定义，第四公理不可证（书引 [206]）。书原证：

```coq
Lemma peano4_leib : forall x : nat, ~ leib nat 0 (S x).
Proof.
  intros x h. exact (h IsZero I).   (* h : ∀P, P 0 → P (S x) *)
Qed.
```

把等式证明 `h` 作用到谓词 IsZero 上：`IsZero 0 = True`
有证明 I，搬过去得 `IsZero (S x) = False` 的证明——矛盾。
「宇宙 = 以类型为值的函数的值域」这个用途，是 CN 的前奏。

## 53.5 CN 宇宙：通名的类型空间（书例 2.8 + 5.3.1）

MTT 语义学（56–64 章）的核心建模：**通名（普通名词）的
语义是类型**——「人」是 Human、「猫」是 Cat、「黑猫」是
`Σx:Cat.black(x)`。所有通名的语义一起组成类型空间 **CN**。
CN 一出，副词与量词的语义类型立刻就位：

```coq
Definition CN := Set.        (* Coq 不许自定义类型空间，
                                书 5.3.1 以 Set 充当 CN *)
Parameter quickly : forall A : CN, (A -> Prop) -> A -> Prop.
Definition some (A : CN) (P : A -> Prop) : Prop :=
  exists x : A, P x.
```

`quickly : ΠA:CN.(A→Prop) → (A→Prop)`——「很快地」对
每个通名 A 实例化出一个谓词变形函数：`quickly(Human, run)`
是人跑得快、`quickly(Cat, walk)` 是猫走得快。**Π 在宇宙上
的量化 = 语义学的多态**。这与 50 章 F<: 的 `∀X<:T` 形成
对照：一边是「对满足界的类型量化」，一边是「对某宇宙的
对象量化」——都是 bounded quantification，但 UTT 的界是
**宇宙成员资格**而非子类型序。

## 53.6 子类型空间 U(H) 与有界量化（书 2.5.3 节 1）

CN 的进一步精细化：对任意类型 H，**U(H) = H 的所有子类型
组成的类型空间**：

> (F) H type ⟹ U(H) type　　(T) A ≤ H ⟹ A : U(H)

它让有界量化 `∀X ≤ H. P(X)`（书式 2.32/2.33）成为类型论
的一等公民。书里这段有个重要的史论对话：Cardelli–Wegner
的 Fun 与 F<: 系统（50 章！）的有界量化**不可判定**
（Pierce [183]），一度让人以为有界量化本身有问题；书指出
F≤ 的不可判定性**源于 Top**（所有类型的顶类型——有界量化
∀X≤Top 等于对全部类型量化，「所有类型的类型」已近在眼前），
而 U(H) 的 H 是**具体类型**、无 Top，且可层次化映射到直谓
宇宙塔（U(H) ↦ Uᵢ₊₁…），保持逻辑一致性、可判定性与强
正规化。机器件用依赖对编码 U(H)——每个对象 = 类型 + 内射：

```coq
Definition U (H : Type) : Type := { A : Type & A -> H }.
Definition bounded_all (H : Type) (P : U H -> Prop) : Prop :=
  forall X : U H, P X.
```

`{A : Type & A -> H}` 读作「一个子类型包」：载体类型 A
加上把它嵌进 H 的（内射）函数。50 章的可判定性对照在此
闭环：**换掉 Top，有界量化从不可判定变为可判定**。

## 53.7 一页总结（本章的三个公式）

> 现代类型论分家：MLTT/HoTT 弃命题非直谓保命题=类型（直谓）；
> CoC/UTT 保命题非直谓弃命题=类型（Prop/Type 双层）；
> Type:Type 不相容（Girard）。
> 塔斯基宇宙 + 强制子类型（提升算子作强制）= 准确且好用。
> U(H) 子类型空间：H 具体则无 Top 之疾——有界量化可判定
> （50 章 F≤ 不可判定的解药）。

> **坑位速记**
> ① Coq 的 `Type : Type` 检查**能通过**——因为它默默新建
>   更高宇宙层（i<j）；想展示 Girard 悖论入口得靠注释讲
>   层级隔断，不能靠报错；
> ② `Check f x (fun X => …) : T` 的尾部 `: T` 会**就近**
>   粘到 lambda 上——`Check ((f x (fun _ => True)) : Prop)`
>   括号要全（本批实测：报「product expected Prop」）；
> ③ 带体 `Definition … := body.` 后接 `Proof.` 会报
>   「No proof-editing in progress」—— tactic 证明用
>   `Lemma`/无体 `Definition … : T.`；
> ④ `apply ex'_intro` 会留 evar（a 找不到实例）——显式
>   `exact (ex'_intro … 0 (eq_refl 0))`（TAPL 轮「eapply
>   卡死→显式项构造」纪律的又一现身）；
> ⑤ 莱布尼茨对称性不能 `apply H` 直推（方向反）——恒等
>   谓词技巧 `H (fun y => P y -> P a) id pb`。

## 53.8 与本书其他线的接口

- 20 章立方体的顶点 λC（构造演算 CoC）——UTT 是 CoC 的
  「加数据类型」版，62 章 LF 形式化里两线合流；
- 21 章 λC 逻辑编码（∧/∨/∃ 的 ∀ 定义）——本章是其
  非直谓版在 Coq 的复刻；
- 31 章宇宙塔（罗素式/塔斯基式、Cumulativity 三家立场）——
  UTT 读法 + 强制子类型解法在此续写；
- 50 章 F<: 不可判定（Top 之疾）——U(H) 是解药，一正一反
  恰成对读；
- 56–64 章 MTT 语义学——CN 宇宙与 Π-多态是全部语义构造
  的地基；
- 54 章（下一章）强制性子类型——提升算子作强制的完整
  理论。

## 53.9 章末地图（书 ch.1–2.4 要点选）

- **书 1.2.2「特点综述」**：类型论 vs 集合论（判断 vs 命题、
  可判定 vs 不可判定）、vs 简单类型论（丰富类型结构）、
  vs 多态类型系统（intrinsic vs extrinsic——Reynolds 术语）；
- **书 2.4.3 例 2.8**：CN 宇宙与副词多态——62 章主角登场；
- **书 2.4.2 脚注**：Prop 引入混淆类型/对象之别——与 Uᵢ
  罗素式同病，故正式描述走 LF（62 章表 6.1）；
- **Girard 悖论分析**（1.1 脚注）：两条基本思想的取舍表——
  现代类型论谱系的「家谱图」。

---

上一章：[52 纯函数对象](52-pureobjects.md) · 下一章：[54 强制性子类型](54-coercive.md)
