# 22 高阶归纳类型：造空间的粘合剂

> 对应读本：HoTT 书第 6 章；coq-hott 教程 12–13、16 章。
> 代码：`examples/22_hit/ex22_hit.v`——区间、圆、商三件套，
> 全部**公理化**（构造子 + 消去子 + 计算规则，账目公开）。

## 22.1 HIT 是什么：构造子可以是「路径」

普通归纳类型的构造子造**点**；HIT 允许构造子造**路径**（乃至
更高维）：

```text
区间 I   构造子：zero, one : I；seg : zero == one
圆 S¹    构造子：base : S¹；loop : base == base
商 A/R   构造子：qg : A → A/R；qglue : qg x == qg y（xRy 时）
```

这补齐了类型论「造空间」的最后一块：拓扑粘合（把区间两端
粘起来得圆；把整段整段的点等同起来得商）。

## 22.2 消去子：签名里的「路径构造子条款」

HIT 的归纳原理在普通归纳原理之外多出**路径条款**：

```coq
Axiom interval_rec : forall (Q : interval -> Type)
  (u : Q zero) (v : Q one),
  transport Q seg u == v -> forall i, Q i.

Axiom circle_rec : forall (Q : circle -> Type)
  (b : Q base) (l : transport Q loop b == b),
  forall c, Q c.
```

读法：要沿区间定义函数，除了两端各给值，还得给**「两端值沿
seg 搬运后吻合」的证据**——正是 20 章 transport 的用武之地。

**计算规则的分界**（19 章伏笔兑现）：J 在 idpath 上定义性计算；
seg/loop 是公理化的路径（不透明），计算规则只能**公理补账**
（`interval_zero`/`interval_one`/`circle_base`）。Cubical Agda
等系统里这些规则可计算——那才是「原生 HIT」。

## 22.3 商类型：万有性质实测

公理化的商（nat 按 mod 2）：

```coq
Axiom quot_lift : forall (Q : Type) (F : nat -> Q),
  (forall n, F (S (S n)) == F n) -> quot -> Q.
Axiom quot_lift_qg : ... quot_lift Q F cond (qg n) == F n.
```

**尊重等价关系的函数唯一下沉**。实测：奇偶函数 `parityF`
用两步递归定义——条件 `F (S (S n)) == F n` 成为**定义相等**
（免证明！），于是

```coq
Example parity_5 : parity (qg 5) == false2 :=
  quot_lift_qg bool2 parityF (fun n => idpath) 5.
```

这是「定义方式选得好，公理负担就小」的典型现场——对照 07 章
的方向学（加法递归侧）一脉相承。

## 22.4 公理记账：本章的诚实清单

| 公理 | 作用 |
|---|---|
| interval/zero/one/seg + rec + 两条计算 | 区间全套 |
| circle/base/loop + rec + 计算 | 圆全套 |
| quot/qg/lift/qg 计算 | 商全套 |
| `Print Assumptions parity_5` | 逐条公示 |

Cubical 系统的意义就在这张表：**把公理变成可计算规则**
（ua 与 HIT 的计算全交给立方演算的 kan 操作）。

> **坑位速记**
> ① 公理化 HIT 的 `ap f loop`-型计算规则要用**依赖版 apD**
> 表述（类型随点变的路径作用），非依赖版类型对不上
> （实测 `ap double loop == loop · loop` 两端锚点不一致）；
> ② `transport (fun _ => X) q u == u`（常值族）是 **J-定理**
> 而非定义——q 不透明时 match 卡住，先立引理（19 章形态）；
> ③ 商的条件下沉选「递归结构使条件成为定义相等」的函数
> （两步递归的 parityF），公理用量立减；
> ④ `Definition f (q : Q) := lift ... q` 别忘应用到 q——
> 类型 `Q -> X` 交给 `X` 位的经典报错。
