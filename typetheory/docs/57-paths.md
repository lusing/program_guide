# 57 路径与同伦：类型即空间

> 对应读本：HoTT 书第 1–2 章全部（本章为第五部分深化版：
> 前三轮的路径代数 + 本轮补齐 §2.3 纤维化、§2.5–2.7 型构子
> 的高维群结构、§2.14 结构相等、§2.15 泛性质）。
> 代码：`examples/57_paths/`——Coq（**零公理** mini-HoTT 路径库）、
> Agda stdlib（群律镜像）、Lean（群律镜像 + Prop 层天花板实测）、
> **cubical Agda 深化件 `ex57_fib.agda`**（族 transport/× 路径/
> Σ 路径分量式/结构相等小样本/泛性质即等价）。

## 57.1 三个问题，打开新世界

把 29 章的相等类型放回显微镜下，问三个 29 章没问的问题：

1. `p : a = b` 的 **p 自己**有没有内部结构？（29 章：没有——
   refl 唯一构造子。HoTT：凭什么没有？）
2. 两个证明 `p q : a = b` 能不能**不相等**？
3. `a = b` 这个类型的**空间**长什么样？

Martin-Löf 的内涵类型论没有回答 2、3——它只保证 J 规则。
Hofmann–Streicher（1996，groupoid model）与 Voevodsky（2006）
发现：**J 的一切模型里，等式类型的「行为」像空间里的道路**。
这就是同伦类型论的起点：

> **类型 = 空间，项 = 点，`p : a = b` = 从 a 到 b 的道路。**

道路可以首尾相接（`p · q`）、可以掉头（`! p`）、可以并排
比较（`α : p = q`——二维道路/同伦）、二维之上还有三维……
**∞-群胚**。29 章的 J 只是这个世界的「沿 refl 生成的一切」。

## 57.2 住在哪层：三家的一览

路径要有高维结构，它的**类型就不能是 Prop**（Prop 层一切
抹平）。三家现状：

| | 相等类型 | 层 | 后果 |
|---|---|---|---|
| Coq | `eq` | Prop | 高维要**自造** paths（本章 .v 的做法） |
| Lean | `Eq` | Prop | **UIP 可证**（本章实测 `uip` 定理）——泛等不可加 |
| Agda | `_≡_` | Set | Type 层 ✓，`--without-K` 可关 J 的唯一性 |

Coq 文件开头一句 `Unset Automatic Proposition Inductives`
就是把自造的 `paths` 按住不让它落 Prop——这是用 Coq 做 HoTT
的第一句咒语。

## 57.3 路径代数：群律全部免费

自造库的四个算子（Coq 版零公理，`Print Assumptions` 见证）：

```coq
Definition concat  (p : x == y) (q : y == z) : x == z   (* p · q *)
Definition inverse (p : x == y) : y == x                 (* ! p *)
Definition ap      (f : A -> B) (p : x == y) : f x == f y
Definition transport (P : A -> Type) (p : x == y) : P x -> P y
```

群律一条条看它们**免费**到手（对 idpath 匹配即 J 一步）：

```coq
Definition concat_pV (p : x == y) : (p · ! p) == idpath :=
  match p as p0 in paths _ y' return (p0 · ! p0) == (@idpath A x) with
  | idpath => idpath
  end.
```

`p · !p = 1`、`!p · p = 1`、`!!p = p`、ap 的函子律、transport 的
组合律——Agda/Lean 镜像版全部同构（每条一两行）。**注意这
不是群**（没有 `p · q = q · p`）——是**群胚**：合成按路径定向。

## 57.4 J 的计算行为：只在 idpath 上

一个容易被忽略的语义细节（后面 HIT 章的伏笔）：

```coq
Eval compute in (concat_pV (idpath : 2 == 2)).   (* 直接给出 idpath *)
```

`transport P idpath u` **定义性**等于 u——J 消去只在 refl 构造子
上计算。但 `p · idpath` 不折叠（57 章 Coq 文件里 `ap_pp` 归纳
变量的选择就是被它逼的：`idpath · q` 折叠、`p · idpath` 不折）。
这正是 63 章 HIT 要打破的天花板：**区间/圆的构造子没有计算
规则**，必须显式补充公理——到时对照。

## 57.5 类型族即 fibration（书 2.3）

把 19 章的「依赖类型 = 类型族」放回空间意象，它获得新名字：
**fibration**。族 P : A → Set 是「基空间 A 上的纤维丛」，全空间
Σ(x:A). P x 投影到基，纤维 P x 是「点 x 上的纤维」。而 transport
就是**平行移动**：基里一条路 p : x ≡ y 把纤维 P x 的数据搬到
P y——cubical 侧的包装是一行：

```agda
transportF : (P : A → Set) → x ≡ y → P x → P y
transportF P p u = transp (λ i → P (p i)) i0 u
```

纤维化的第一个计算样本（书 2.3.10 的实例，cubical 文件
`transport-path-fam`）：沿 p 搬运「λz. z ≡ c」族有显式公式
`transp ≡ sym p ∙ q`——路径族里的搬运就是「先消 p 对齐端点」。
ap 与 transport 是同一枚硬币的两面：**cong 把基里的路推到全
空间，transport 把纤维里的数据沿基里的路移动**。搬运合成律
`transport_{p∙q} = transport_q ∘ transport_p`（2.3.11）完整
机械版需要双端点归纳——64 章编码-解码时作为 decode 的装配
件回填（彼处它从引理升级为主角）。

## 57.6 型构子的高维群结构（书 2.5–2.7）

每个类型构子都自带「路径级」的规则——这是同伦意象最实用的
一层。cubical 深化件把它们做成了两行一个的样板：

**× 的路径**（引理 2.6.2）：

```agda
×Path-→ : (u,v : A × B 的路径) → (u₁ ≡ v₁) × (u₂ ≡ v₂)   -- 投影
×Path-← : (u₁ ≡ v₁) × (u₂ ≡ v₂) → (u,v 的路径)            -- 配对
```

**Σ 的路径**（定理 2.7.2）：

```agda
ΣPath-→ : (Σ A P 的路径) → Σ(p : x ≡ y). PathP (λ i → P (p i)) u v
ΣPath-← : Σ(p : x ≡ y). PathP (λ i → P (p i)) u v → (Σ A P 的路径)
```

后者是 60 章 `isContr-pathFrom`（单端点路径空间合同）两行证明
的火力来源，也是 42/64 章 HIT 消去子的标配弹药。**注意两世
界的深刻差异**：书 2.7 的定理是「Σ 的路径**等价于** Σ 路径」
——需要拆解引理+双向构造+合同性三件套；cubical 里 ΣPath-←
是 `λ i → (p i , q i)`——**路径就是分量式**，原生定义级。这不是
省事，是**计算内容的增加**：公理化世界里 ΣPath 只能「用一次
折一次」，cubical 里它参与任何位置的计算。

Π 的路径（2.9）则相反——它是**公理级**的：funext（同伦即
相等）在书里是公理 2.9.3，cubical 里是 λ i j → h j i（58 章）。

## 57.7 结构相等（书 2.14）

「带结构的类型」＝ Σ(B : Set). 结构(B)。结构相等的刻画是
ΣPath 的直接应用（深化件 `StructurePath-→` 以「带一个二元
运算」为样本）：

> Σ 的路径 = 底层的类型路径 p + 结构沿 p 的 PathP 搬运

在泛等之下它将升级为「**结构相等 ⟺ 结构等价**」——即 SIP
（structure identity principle，66 章 9.8 的正题）。本章埋的
这块砖在 59 章立即被 ua 点燃，在 66 章长成大树。

## 57.8 泛性质即等价（书 2.15）

集合论里的泛性质（universal property）说「满足 UP 的对象在同
构下唯一」。HoTT 把它精确化为**等价**——以 × 的 UP 为样本
（深化件 `curry-qinv`）：

```agda
curry : ((A × B) → C) → (A → B → C)
curry-qinv : QInv curry      -- uncurry 是拟逆；两个方向的
                              -- 同伦都是 refl（eta 定义相等）
```

UP 不再是集合级的「唯一性」（那在证明相关世界里是错误的
形状——满足者可以有多个不同的满足方式），而是空间级的
**合同性/等价**。curry-qinv 的两个 refl 是最平的样本：同构
的证据在此退化成定义相等——「最平凡的等价」正是「泛性质
用等价表述」这一改写的直接回报。64 章的 S¹（圆的 UP）与
63 章（商的 UP）将把这一模式推广到 HIT。

## 57.9 三世界的 J：同一公理的三副面孔

本章四个实现文件放在一起看，J 的形态是一张浓缩的类型论进化
史表：

| 世界 | J 的形态 | 计算行为 |
|---|---|---|
| Coq（mini-HoTT） | `match p in paths _ y' return …` | 只在 idpath 上 iota 折叠 |
| Agda stdlib | 归纳族 `_≡_` 的 elim | 同上（J 是数据的消去子） |
| cubical Agda | `J P d p = transport (λ i → P (p i) (λ j → p (i∧j))) d` | **J 是两个原语的复合程序**——对任意 p 计算展开 |
| Lean | `Eq.rec`（内核） | 只在 rfl 上折叠；Prop 层 + UIP 免费 |

第三行值得驻足：cubical 里 J 不再是「初始性宣言」（归纳类型
的消去规则），而是一个**可执行定义**——transport 是原语、
λ j → p (i∧j) 是「p 的自拘束方形」（把任意路径的「前半」当
refl 用）。J 的全部群律（57.3）于是从「逐条对 idpath 匹配」
变成「逐条对 transport 的计算律」——69 章的群律证明正是这么
写的（基座只剩 transportRefl 一个）。**公理变程序，证明变
计算**——这是 cubical 革命在本章最直观的落点，也是 42/64 章
HIT 计算规则的预演。

> **坑位速记**
> ① Coq 记号优先级：`·`(60) 比 `!`(65) **更紧**，
> `! p · p` 解析成 `! (p · p)`——复合逆转要括号 `(! p) · p`；
> ② 依赖匹配的 motive 里裸 `idpath` 要显式端点
> （`@idpath A y'`），否则消歧到错误的端点；
> ③ `match q ... in paths _ z'` 的 motive 里引用外层 `q` 必须
> retype——把 q 做成 match 的参数（`return forall q0, ...`）；
> ④ Coq 自造相等类型要 `Unset Automatic Proposition Inductives`
> （否则落 Prop、失去 Type 层消去）；
> ⑤ Lean 方程式 def 的隐式参数要放冒号前（`: {x y : α} →`
> 的写法会让 pattern 槽位错位）；
> ⑥ Agda 的 lambda-型家庭在 `_ : subst (λ m → ...) refl refl
> ≡ refl` 里 m 无从确定——要么 named 定理带 ∀ n，要么
> `{x = n}` 钉住。

---

上一章：[56 LF 与元理论](56-lf.md) · 下一章：[58 等价论](58-equivalence.md)
