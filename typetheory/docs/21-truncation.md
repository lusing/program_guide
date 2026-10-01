# 21 截断层级：命题、集合、群胚

> 对应读本：HoTT 书第 3 章；《现代类型论的发展与应用》3.5
>（证明无关性）。代码：`examples/21_truncation/ex21_truncation.v`
>（公理：funext 一条，账目 Print Assumptions 公示）。

## 21.1 层级：-2, -1, 0, …

| 层级 | 定义 | 直觉 | 例 |
|---|---|---|---|
| -2 可缩 Contr | 有中心 + 一切等于中心 | 一点空间 | 单点、Σ(x:A). x==a |
| -1 命题 IsHProp | 任两点相等 | 真值 | ⊥、⊤、(a == b) 的「负截断」 |
| 0 集合 IsHSet | 任两条路径相等 | 离散空间 | ℕ、Bool（要 noconf） |
| 1 群胚 | …路径的路径的… | 基本群胚 | 宇宙（泛等下）、群 |
| n | IsTrunc n 递归 | —— | —— |

Coq 文件用 Record 给出前三层（IsTrunc n 的完整递归版见
coq-hott 教程 09 章）。两个零公理成果：

```coq
Definition singleton_contr {A : Type} (a : A) : Contr { x : A & x == a }.
(* 单点域可缩：J 直推——「一切路径空间可缩」的种子形式 *)

Definition empty_hprop : IsHProp empty.   (* 假是命题 *)
Definition unit_contr : Contr unit2.      (* 真可缩 *)
```

## 21.2 noconf 一瞥：true ≠ false 的路径版

```coq
Definition tf_empty (p : true2 == false2) : empty :=
  match p in paths _ b
    return (match b with true2 => unit2 | false2 => empty end) with
  | idpath => tt2
  end.
```

motive 在端点上「分流」：idpath 只能落在 true2 侧（交出
unit2 的居留项），而拿到的是 false2 侧（要 empty）——矛盾。
这是构造子判别性在 Type 层等式上的化身（11 章Prop 版的姊妹）。

## 21.3 funext 与「命题对 Π 封闭」

层级理论离不开**函数外延性**。本章以公理记账引入：

```coq
Axiom funext : forall (A : Type) (P : A -> Type) (f g : forall x, P x),
  (forall x, f x == g x) -> f == g.

Definition pi_hprop (A : Type) (P : A -> Type)
  (H : forall x, IsHProp (P x)) : IsHProp (forall x, P x).
```

「每点是命题 ⇒ 函数空间是命题」——直觉主义逻辑里 Π 对命题
封闭的机器面（逻辑性，impredicativity 的直谓版本）。22 章
会看到 funext 能从区间 HIT **推出来**（公理降级为定理）。

## 21.4 与三家 Prop 的对照

| | 命题层 | 无关性 |
|---|---|---|
| Coq | `Prop`（+`SProp`） | `proof_irrelevance`（公理，Consistent） |
| Lean | `Prop` | **内核定义性**无关——`rfl` 直接证 `p = q` |
| Agda | 无专门层 | 命题=恰一个居留点的 Set（纪律） |

Coq 的 `proof_irrelevance : forall (P : Prop) (p q : P), p = q`
正是「Prop = -1 层」的内部表述。Lean 更激进——证明在 defeq
层面就无差别（18 章擦除的理论根基）。截断视角统一了这三家：
**命题 = 恰好「压平」到 -1 层的类型**。

> **坑位速记**
> ① Coq record 投影带参：`hprop_all (P x) (H x) (f x) (g x)`
> 全显式（`apply` 版本因首个显式参是 A 而踩坑）；
> ② 空类型的 match 放在依赖动机里会报「unknown empty
> inductive」——先用非依赖辅助函数 `empty_any` 打底；
> ③ 对自造 paths 证 loop-UIP（`idpath == q`）：destruct 的
> anchor 元变量地狱（实测三种写法全败）——正路是 noconf 或
> 投靠 stdlib eq（其 UIP_refl 可证，因为 Prop 压平）；
> ④ `Axiom funext` 的路径版本与 stdlib functional_extensionality
> 平行——mini 库内自洽即可。
