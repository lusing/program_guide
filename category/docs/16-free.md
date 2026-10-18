# 16 自由与遗忘

> 对书：Simmons 5.5 / 贺伟 3.1 / 高级 5.2。代码：`examples/16_free/`。

自由构造的样板：**freeCat ⊣ 遗忘函子 U : Cat → Graph**。机器内容（Coq）：
GraphMap（顶点映射 + 每边一态射——端点方程按类型免费）+ 单位（边 ↦ 单边路）+ 延拓 extendPath（对 Path 归纳）+ 延拓保复合 extend_comp（零公理）。

「自由」的机器含义：任何 GraphMap 唯一延拓成函子 freeCat G → C——泛性质的组装版。
04 章的 freeCat 基础设施在此全部复用。

## 16.4 旗舰二号：自由幺半群 List ⊣ U（Simmons 5.5）

freeCat ⊣ U 讲的是「图 → 范畴」；更经典的自造样本是
「集合 → 幺半群」：`(List X, ++, [])`。三件事全部按表归纳、
零公理（Coq 版完整机器化）：

```coq
(* 单位 η(x) = [x]；f 沿 ++ 的扩张 = 折叠 *)
Definition mfold {X A} (f : X -> mcar A) : list X -> mcar A :=
  fix go l := match l with
             | nil => mun A
             | x :: rest => mop A (f x) (go rest) end.

Lemma mfold_op : forall l m,          (* 同态性：++)
  mfold f (l ++ m) = mop A (mfold f l) (mfold f m).   (* 归纳 + 结合律 *)

Lemma mfold_unique : forall (h : MonHom (listMon X) A)
  (Hext : forall x, hfun h [x] = f x),                (* 唯一性 *)
  forall l, hfun h l = mfold f l.                     (* 表归纳 *)
```

`mfold_unique` 的归纳步是全书微缩景观：`h(x::l)` 经同态律
变成 `h[x] · h(l)`，`h[x]` 被「延拓 η」钉死成 `f x`，尾巴
交给归纳假设——**同态 + 延拓单位 = 全部信息**。这就是
「自由」的算法含义：泛性质唯一性 ⟹ **折叠即求值**。

**一般定理**（5.5.2，文档级）：任何 F-cofree 数据（每个 S 配
`ε_S : FG(S) → S` 泛箭头）自动长出右伴随 G 与整个伴随——
G(l) := `(l ∘ ε)♭`、ε 的自然性与双射性全部由唯一性挤出。
25 章的 Π（余自由 R-集）就是这个定理的实例：`ΠX = (R → X)`
配求值 ε。**「造左/右伴随 = 造一族泛箭头」**是伴随论的
第一工程学原则。

## 坑位速记
1. 目标是图时保端点方程是命题（04 章 GraphHom）；目标是范畴时依赖类型让运输消失（GraphMap）——同一定义的两种宇宙待遇。
2. 索引族递归定义走 induction 式 + Defined；as-模式第四个名字是「函数应用的递归假设」。

---

上一章：[15 伴随的三副面孔](15-adjunctions.md) · 下一章：[17 伴随与极限](17-adjlimits.md)
