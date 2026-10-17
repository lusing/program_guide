# 65 泛等公理：等价即相等

> 对应读本：HoTT 书 §2.10（泛等公理）+ §4.8（对象分类器）+
> §4.9（泛等蕴含函数外延）——本章为第五部分深化版。
> 代码：`examples/65_univalence/`——Coq（等价四份数据 + UA 公理 +
> β 计算公理，账目两条）、Agda stdlib（postulate 版同账目）、
> Lean（账目摆出 + 为什么 Lean 加不了）、**cubical Agda 深化件
> `ex65_uacalc.agda`**（ua 从 Glue 手造、funext 一行、uaβ 计算
> 律——两条「公理」的程序化身）。

## 65.0 泛等的三种读法

同一个公理，三种强度递增的读法——本章机器面逐一兑现：

1. **外延读法**：「同构的类型应当相等」。UA 说 idtoequiv 是
   等价——即 (A ≡ B) ≃ (A ≃ B)：类型层的相等**恰好**是等价，
   不多（无 UIP 的平）不少（无更高的球）。
2. **计算读法**（cubical 组兑现）：等价可以**变成**路径、路径
   可以**算出**搬运——ua 与它的 β 律都是程序。
3. **范畴读法**（65.4 对象分类器兑现）：宇宙 U 是万有 fibration
   的基——每个类型族都是拉回。泛等是「U 的局部平凡性」。

三读法在后续章各取所需：66 章用读法 1 造 mere prop 的同构
不变量；42/70 章用读法 2 让 HIT 的构造子参与计算；72 章用
读法 3 给范畴论定基调。

## 65.1 从「同构搬运」到公理

数学里人人都知道：「同构的类型应当看作一样」。集合论里这只是
口语；类型论里它是精确命题：

```text
idtoequiv : (A == B) → (A ≃ B)      ——J 直接构造（零公理）
泛等公理： idtoequiv 是等价
推论：     ua : (A ≃ B) → (A == B)   ——等价造出路径
```

`A ≃ B` 的四份数据（Coq 文件）：函数 `f : A → B`、逆 `inv`、
以及两个收缩证据 `retr`/`sec`。**等价 = 双射 + 相干性**——
比同构多一点（那点在高维）。

```coq
Axiom univalence : forall A B : Type, isequiv (@idtoequiv A B).
Definition ua {A B : Type} (e : equiv A B) : A == B :=
  @inv (A == B) (equiv A B) (@idtoequiv A B) (univalence A B) e.
```

## 65.2 实测：Bool 的非平凡自等价

```coq
Definition negb_equiv : equiv bool2 bool2 := ...
Definition neg_path := ua negb_equiv.        (* Bool == Bool 的新路 *)
Axiom transport_ua : ... transport X (ua e) u == equiv_fun e u.
```

取反 `negb` 不是恒等，但它是等价——于是泛等给出**第二条**
`Bool == Bool` 的路径。沿它搬运元素 = 逐点取反（β 公理
`transport_ua`）。Agda 版同构镜像（`not-path : Bool ≡ Bool`）。

**宇宙不是集合**：`Bool == Bool` 若只有 `idpath` 一条路，
类型宇宙就是 0 层；泛等制造新路 → 宇宙至少是 1 层（群胚）。
（证「两条路不同」要 70 章的 encode-decode。）

## 65.2b 沿 ua 的三段式搬运（机器面导读）

泛等启用后的日常写作模式是「三段式」：**造等价 → ua 成路 →
transport 搬运**。以「等价的类型有相同的元素数」为例（书
2.10 的精神）：

```text
f : A ≃ B            （第一段：构造等价——75 章的装备）
p := ua f : A ≡ B    （第二段：泛等换路）
transport P p : P A → P B   （第三段：沿路搬性质 P）
```

性质 P 可以是任何谓词（isSet、可数、群结构……）。Coq 组的
`transport_ua`（β 公理）保证第三段能化简回第一段的函数——
这是「搬运可计算」的公理承诺；cubical 组的 uaβ 是它的定理
版。**泛等的全部工程价值浓缩在这个三段式里**：同构不再需要
「手动搬运每个定理」——ua 一次性搬走整个谓词层。

**SIP 预告**（72 章 9.8 的伏笔）：把三段式用在「结构化类型」
上（63.7 的 Σ(B:Set). 结构 B），泛等给出「结构等价 ⇒ 结构
相等」——数学各分支的「同一结构」从此有了统一的形式判据。
65 章只摆出机制，72 章给出定理。

## 65.3 泛等的代价与收益

| | 收益 | 代价 |
|---|---|---|
| 结构搬运 | 同构的类型自动传递一切性质 | 证明常要「沿 ua 搬」 |
| 逻辑 | ¬UIP（等式类型有高维结构） | 不能再「压平」证明 |
| 工程 | Cubical 系统让 ua 可计算 | 普通内核只能公理化（本章做法） |

**Lean 为什么加不了**（文件实测）：`Eq` 在 Prop、UIP 是定理
（63 章 `uip`）——泛等与其矛盾。要泛等得换 Type 层等式 +
可计算立方内核（cubical Agda / Lean-HoTT 分支）。

> **坑位速记**
> ① Coq record 构造子要 `@MkX A B ...` 全显式——隐式推断在
> seed 位置经常把函数塞进 Type 槽；
> ①b（cubical 组）ua 的 primGlue 三参形态：靶类型、两端
> partial 的类型系统、两端 partial 的等价——(i=i0) 端放源
> 等价 e、(i=i1) 端放恒等 idEquiv；漏掉 i1 端会让 φ 面不全；
> ② `ua e` 的类型标注可能引发宇宙不一致（Set vs Type@{u}）——
> 用 `Definition x := ua e.` 让推断做主；
> ③ Agda postulate 块里不能写 `where`——import 提前；
> ④ `transport (fun _ => X) p u == u`（常值族搬运）是 J-定理
> 不是定义——mini 库里要立引理再用（70 章正文展开）。

## 65.4 对象分类器（书 4.8）

泛等把宇宙 U 变成「所有空间的分类空间」。两块基石（书引理
4.8.1/4.8.2）：

> **fib_{pr1}(a) ≃ B(a)**——Σ 投影的纤维恰好是族的值；
> **A ≃ Σ(b:B). fib f b**——任何函数都「是」一个 fibration。

证明是两串等价链（Σ 路径刻画 2.7 + 泛等搬运）。合起来得到
拉回方块：A → U•（带点类型全空间）over U，χ_f : B → U 把每个
b 送到它的纤维——**每个函数都是 fibration，U 是万有纤维丛**。
范畴论的「对象分类器」意象（72 章 Yoneda 的同伴）在类型论里
有了精确坐标。机器面：fib 的定义已在 64 章；fib_{pr1}(a) ≃
B(a) 的显式等价需要 Σ 合同性机械——陈述级呈现（诚实清单），
完整版随 67 章 Hedberg 后回填。

## 65.5 泛等蕴含函数外延（书 4.9 详证）

公理化世界里这是 Voevodsky 的优雅定理，两步走：

**第一步（4.9.4）：UA ⇒ 弱函数外延**（合同族的 Π 合同）。
给定 P : A → U 每点合同，证 Π(x:A). P x 合同。关键构造：投影
pr1 : Σ(x:A). P x → A 是等价（纤维 fib_{pr1}(a) ≃ P(a) 合同）。
UA 下「复合等价」给预复合 α : (A→Σ P) ≃ (A→A)（书引理
4.9.2）；于是 **Π P 是 fib_α(id_A) 的收缩**：

```text
φ : Π P → fib_α(id) := λ f. (λx. (x, f x), refl)
ψ : fib_α(id) → Π P := λ (g, p) x. transport p (snd (g x))
ψ ∘ φ = id（逐点 refl——transport refl 即恒等）
```

收缩保合同（收缩的像落进合同空间）⇒ Π P 合同。UA 的出场
只有一处：让 pr1 的纤维合同性变成「pr1 是等价」，从而预复合
α 存在——**UA 把「逐点合同」兑换成「复合可逆」**。

**第二步（4.9.5）：弱 ⇒ 强**（不用 UA）。要证 happly : (f=g)
→ (f∼g) 是等价——同伦可以「积分」回相等。证法用「图像」：
对 f,g 构造 graph 纤维空间，f=g 的路径与 f∼g 的同伦都成了
它的元素，弱 funext 保证相关空间合同，双向映射于是互逆。

**cubical 的消解**（深化件 `ex65_uacalc.agda`）：这两页定理
在 cubical 里是**两条定义**——ua 是 Glue 的 8 行程序（64 章
手造），funext 是方形转置的一行（λ i j → h j i）。「UA ⇒
funext」的整条推导链被 Glue 的计算律整体替代：**公理化世界
在证明「是什么」，cubical 世界直接给出「怎么算」**。本章
Coq 组与 cubical 组并排读，是这场范式转移最完整的标本。

## 65.6 泛等的私人账本：能算与不能算

| 命题 | Coq mini-HoTT | cubical Agda |
|---|---|---|
| ua : (A ≃ B) → A = B | 公理 | **程序**（Glue 手造，64 章） |
| transport ∘ ua 的 β 律 | 第二条公理 | **定理**（uaβ，可证） |
| funext | 公理（67 章组） | **一行**（方形转置） |
| idtoequiv : (A = B) → (A ≃ B) | 程序（J 一击） | **程序**（builtin pathToEquiv） |
| ua 的 η 律（idtoequiv∘ua=id） | 可证（两公理下） | 陈述级（unglue 展开待 69 章） |
| ua (not-equiv) 的非平凡自路径 | 程序+公理立得 | 待 67 章（需要 Bool isSet） |

最后一行是诚实的注脚：**泛等的「计算」也有台阶**——要造
Bool 的非平凡自路径，得先有 not 的纤维合同性，而它依赖
Bool 是 set（Hedberg，67 章）。公理不分先后一律给；程序按
依赖序逐级点亮——两个世界的教学差异最微妙处在此。

## 65.7 机器面导读

四组文件按「公理化 → 计算」的光谱排开：

- **Coq（`ex65_univalence.v`）**：等价的四份数据 + UA 公理 +
  transport_ua（β）公理——两条公理的账目 `Print Assumptions`
  公示。它是「假设世界」的诚实样板：每一步「是什么」都明码
  标价，但「怎么算」到此为止。
- **Agda stdlib（`ex65_univalence.agda`）**：postulate 版，
  账目与 Coq 同构——证明两个公理化世界在结构上互通。
- **Lean（`ex65_univalence.lean`）**：只摆账本不给公理——
  `Eq` 在 Prop 层、UIP 是定理（63 章实测），泛等与之矛盾；
  文件的价值恰是**证明此路不通**的形式化记录。
- **cubical（`ex65_uacalc.agda`）**：ua 是 8 行 Glue 程序、
  funext 是 1 行转置、uaβ 是 transportRefl 的组合——「公理
  的程序化身」三部曲。与 64 章的 mini-cubical 前奏无缝衔接。

## 65.8 三段式的第一个实战：¬ 的两次搬运

「等价的类型有同构的性质」最直观的一次行使：¬ 与 ∥¬∥ 的对
话。设 e : A ≃ B，则（65.2b 的三段式）：

```text
not-A := A → ⊥          （66 章 ¬_）
沿 p := ua e 搬运 not- ：not-B := B → ⊥
```

搬运的具体形态是 transport 在「函数空间族」里的计算（63 章
fibration 群律的 §2.9 部分）——A → ⊥ 沿 ua e 搬到 B → ⊥ 的
函数是「先 e⁻¹ 再评估」的复合。这个小实例在 66 章（isProp-¬
的两世界对照）与 71 章（Whitehead 的连通性条件）里被反复
调用——泛等的工程语法一旦上手，剩下的是查表。

---

上一章：[64 等价论](64-equivalence.md) · 下一章：[66 集合与逻辑](66-setlogic.md)
