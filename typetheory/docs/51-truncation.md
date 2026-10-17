# 51 截断与 n-类型：层级塔与 Hedberg

> 对应读本：HoTT 书第 7 章全部（n-类型层级、UIP 与 Hedberg、
> 截断、连通性、模态素描）+ 第 3 章回顾；《现代类型论的发展与
> 应用》3.5（证明无关性）。代码：`examples/51_truncation/
> ex51_truncation.v`——**Hedberg 定理完整机器版**（7.2.2 第一
> 证明的 K 路线 + 7.2.4 + 7.2.5 + Bool/ℕ 是 set 的两个样本；
> 公理仅 funext 一条，账目 Print Assumptions 公示）。

## 51.1 层级：-2, -1, 0, …

| 层级 | 定义 | 直觉 | 例 |
|---|---|---|---|
| -2 可缩 Contr | 有中心 + 一切等于中心 | 一点空间 | 单点、Σ(x:A). x==a |
| -1 命题 IsHProp | 任两点相等 | 真值 | ⊥、⊤、(a == b) 的「负截断」 |
| 0 集合 IsHSet | 任两条路径相等 | 离散空间 | ℕ、Bool（要 noconf） |
| 1 群胚 | …路径的路径的… | 基本群胚 | 宇宙（泛等下）、群 |
| n | IsTrunc n 递归 | —— | —— |

层级的**封闭律**（书 7.1 的表格化）：n-type 对 Π 封闭（值域
逐点 n-type 即可——50 章 isProp-Π 的逐层推广）、对 Σ 封闭
（两分量 n-type ⇒ Σ n-type——用 47 章 ΣPath 分量式归纳）、
对可缩因子的伸缩封闭。宇宙 U_n 本身恰是 (n+1)-type 而**不是**
n-type（7.1.10——层级严格）：每层宇宙都在自己的上一级打工，
这是 Russell 悖论的类型论化身——30 章宇宙塔的同伦版。

塔的**递归刻画**（7.2.7）：is-(n+1)-type(X) ⟺ 对一切 x:X，
自环空间 Ω(X,x) := (x ≡ x) 是 n-type——基座 −2 是合同。于是
「第几层」问的是**自环塔的高度**：集合的自环全坍（K），群胚的
自环是集合，宇宙的自环是群胚（泛等的直接后果——60 章）。

Coq 文件用 Record 给出前三层（IsTrunc n 的完整递归版见
coq-hott 教程 15 章）。两个零公理成果：

```coq
Definition singleton_contr {A : Type} (a : A) : Contr { x : A & x == a }.
(* 单点域可缩：J 直推——「一切路径空间可缩」的种子形式 *)

Definition empty_hprop : IsHProp empty.   (* 假是命题 *)
Definition unit_contr : Contr unit2.      (* 真可缩 *)
```

## 51.2 noconf 一瞥：true ≠ false 的路径版

```coq
Definition tf_empty (p : true2 == false2) : empty :=
  match p in paths _ b
    return (match b with true2 => unit2 | false2 => empty end) with
  | idpath => tt2
  end.
```

motive 在端点上「分流」：idpath 只能落在 true2 侧（交出
unit2 的居留项），而拿到的是 false2 侧（要 empty）——矛盾。
这是构造子判别性在 Type 层等式上的化身（28 章Prop 版的姊妹）。

## 51.3 funext 与「命题对 Π 封闭」

层级理论离不开**函数外延性**。本章以公理记账引入：

```coq
Axiom funext : forall (A : Type) (P : A -> Type) (f g : forall x, P x),
  (forall x, f x == g x) -> f == g.

Definition pi_hprop (A : Type) (P : A -> Type)
  (H : forall x, IsHProp (P x)) : IsHProp (forall x, P x).
```

「每点是命题 ⇒ 函数空间是命题」——直觉主义逻辑里 Π 对命题
封闭的机器面（逻辑性，impredicativity 的直谓版本）。53 章
会看到 funext 能从区间 HIT **推出来**（公理降级为定理）。

## 51.4 与三家 Prop 的对照

| | 命题层 | 无关性 |
|---|---|---|
| Coq | `Prop`（+`SProp`） | `proof_irrelevance`（公理，Consistent） |
| Lean | `Prop` | **内核定义性**无关——`rfl` 直接证 `p = q` |
| Agda | 无专门层 | 命题=恰一个居留点的 Set（纪律） |

Coq 的 `proof_irrelevance : forall (P : Prop) (p q : P), p = q`
正是「Prop = -1 层」的内部表述。Lean 更激进——证明在 defeq
层面就无差别（35 章擦除的理论根基）。截断视角统一了这三家：
**命题 = 恰好「压平」到 -1 层的类型**。

> **坑位速记**
> ⓪（深化批新增）Coq Record 目标不能 `unfold IsHSet`——用
>   `apply MkHSet` 攻字段；IsHProp 的证据取字段要用
>   `hprop_all (R x x) (isPropR x x) _ _`（投影函数吃三个参）；
> ⓪b apd 型等式在 assert 里 induction p 会被「上下文中依赖 p
>   的先前假设」卡死——用**显式 match 版 J**（return 手写、
>   变端点 y' 显式标注；motive 里 f 的作用点随 y' 动：f x y'）；
> ⓪c 路径族 transport 的方向：λz. **x ≡ z**（正侧）搬运出
>   「右拼接」（q·p），λz. z ≡ x（反侧）出「左拼接」——书
>   7.2.2 的演算要选正侧族，apd 的展开形才与消去链对齐；
> ⓪d funext 的 Coq 公理五参**全显式**——`funext _ _ f g h`，
>   只给最后一个参会把 λ 塞进 A 槽（product expected sort）；
> ⓪e nat 判等的 0≠S/S 单射：paths 的 large elimination——
>   motive 按 y' 的构造子分流（O 给 unit/S 给 empty 等），
>   `noconf_step` 的 O 分支类型要与 S 分支同框（empty→empty
>   vs m==k 在 return 子句的 match 里统一）；
> ① Coq record 投影带参：`hprop_all (P x) (H x) (f x) (g x)`
> 全显式（`apply` 版本因首个显式参是 A 而踩坑）；
> ② 空类型的 match 放在依赖动机里会报「unknown empty
> inductive」——先用非依赖辅助函数 `empty_any` 打底；
> ③ 对自造 paths 证 loop-UIP（`idpath == q`）：destruct 的
> anchor 元变量地狱（实测三种写法全败）——正路是 noconf 或
> 投靠 stdlib eq（其 UIP_refl 可证，因为 Prop 压平）；
> ④ `Axiom funext` 的路径版本与 stdlib functional_extensionality
> 平行——mini 库内自洽即可。

## 51.4b 层级塔的 Coq 递归骨架

IsTrunc n 的完整递归版（coq-hott 教程 15 章的形态，本章给出
签名骨架）：

```coq
Fixpoint IsTrunc (n : nat) (A : Type) : Type :=
  match n with
  | O => IsHSet A
  | S n' => forall (a b : A), IsTrunc n' (a == b)
  end.
(* 注意：真实的 -2/-1 基座用单独的 Contr/IsHProp 定义索引
   （负数层的编码），此处展示的是 0 起步的骨架。 *)
```

递归的每一层「降维打击」：n-type 的判定被归结为「路径空间
是 (n−1)-type」——与 7.2.7 的定理互相锁定（递归定义与迭代
定理的同一性）。cubical 侧的同型（51 章未给 IsTrunc 递归，
50 章 isProp/isSet 的前两级+此骨架的映射）是回填清单件。

## 51.5 UIP、K 与 Hedberg（书 7.2）——本章的深化主菜

「集合」的重命名学：UIP（唯一性证明）= Axiom K（一切自环是
refl）= 是 set（**定理 7.2.1**，K 与 UIP 等价由对 q 归纳给出）。
注意 HoTT 的立场：**UIP/K 不是公理而是类型的属性**——宇宙不
满足它（泛等制造非平凡环），Bool/ℕ 满足它（要证！）。

证「是 set」的两大引擎，Coq 文件全部机器化：

**定理 7.2.2（自反 mere 关系蕴含相等 ⇒ set）**——第一证明的
K 路线，四步演算链：

```coq
Theorem reflexive_mere_rel_set (R : X -> X -> Type)
  (isPropR : forall x y, IsHProp (R x y))   (* mere 关系 *)
  (rho : forall x, R x x) (f : forall x y, R x y -> x == y) :
  IsHSet X.
```

> ① p*(f x x ρx) = f x x (p*ρx)   [apd 自然性 2.9.6——Coq 里
>    显式 J 一步即溃]
> ② p*ρx = ρx                     [R(x,x) 是 prop]
> ③ 路径族（正侧）的搬运 = 右拼接  [对 p 归纳直读]
> ④ 消去四连：p ≡ 1·p ≡ (!w·w)·p ≡ !w·(w·p) ≡ !w·w ≡ 1

**定理 7.2.5（Hedberg，1993）**：可判定等式 ⇒ set——R 取
「双重否定」族（prop 性免费：空类型上无信息）、f 由 7.2.4
（dec ⇒ ¬¬ 可消除）给出。两个样本：`bool2_isSet`（谓词分离
判等）与 `nat_isSet`（0≠S 与 S 单射都由 paths 的**依赖消去**
取出——large elimination 的 motive 按构造子分流）。

```coq
Theorem hedberg (deceq : forall x y : X, (x == y) + ~ (x == y))
  : IsHSet X.
```

工程视角：**Hedberg 是判等函数的「纵火许可证」**——任何语言
里能写 dec eq 的类型，在 HoTT 里自动是 set（等式无高维结构）。
Lean/Coq 的一切 stdlib 判等类型因此天然安全；风险只在判不出
的类型（S¹、宇宙——54 章的战场）。

与 50 章的连接：50 章机器化了 `isProp-sum¬`（A prop ⇒
A+¬A prop）与 nn-sum¬；本章的 R = 双重否定族把这两块拼进
Hedberg 的火力线。与 53 章的连接：截断 ∥_∥ₙ 作为 HIT 是
「带层次的 squash」——squash 一层的 50 章经验将原样上楼。

## 51.6 截断层级与连通性（书 7.1/7.3/7.5）

**n-类型的递归塔**（定理 7.2.7/7.2.9 的骨架）：

> is-n-type(X) ⟺ 对一切 x，Ω(X,x)（x 的自环空间）是
> (n−1)-type；归纳基座 −2 = isContr。

塔上的全景：−2 合同 ⊂ −1 命题 ⊂ 0 集合 ⊂ 1 群胚 ⊂ 2
2-群胚 ⊂ …。**截断**（7.3）把任意类型压到第 n 层——50 章的
∥·∥ 是 n=−1 的特例，一般 ∥_∥ₙ 是 HIT（53 章）：加 n-维
squash。书 7.3 的三组消去/计算律与 ∥·∥ 同构，只多一层维度。

**连通性**（7.5）：is-n-connected(f) := ∥fib f∥ₙ 高度截断后
合同——「纤维在 n 层以下无内容」。is-0-connected = 非空+连通
（任何两点 merely 有路）；is-(−1)-connected = merely 非空。
它把拓扑的连通搬进类型论，是 55 章（Freudenthal：n-连通映射
的纤维截断下移）的准备件。**正交分解**（7.6：n-连通 ×
n-截断 的因子分解）与**模态**（7.7：截断算子的模态论素描），
本章以地图形式呈现——完整开发属于「反思类型论」的专著领地。

## 51.7 机器面导读

`ex51_truncation.v` 三段：原层级件（Contr/IsHProp/IsHSet、
singleton_contr、empty/unit、noconf 样本、funext 公理与
Π-封闭）+ **深化批**（transport/apd/群律补件 → 7.2.2 的
四步演算 → 7.2.4 → 7.2.5 → Bool/ℕ 样本）。`Print Assumptions
nat_isSet` → 仅 funext（双重否定 prop 性的代价；cubical 侧
50 章 isProp-¬ 免费——两个世界的账本又一页）。

---

上一章：[49 泛等](49-univalence.md) · 下一章：[53 HIT](53-hit.md)
