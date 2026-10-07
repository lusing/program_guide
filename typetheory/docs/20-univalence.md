# 20 泛等公理：等价即相等

> 对应读本：HoTT 书第 2 章（泛等）；coq-hott 教程 11 章。
> 代码：`examples/20_univalence/`——Coq（等价四份数据 + UA 公理 +
> β 计算公理，账目两条）、Agda（postulate 版同账目）、Lean
>（账目摆出 + 为什么 Lean 加不了）。

## 20.1 从「同构搬运」到公理

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

## 20.2 实测：Bool 的非平凡自等价

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
（证「两条路不同」要 23 章的 encode-decode。）

## 20.3 泛等的代价与收益

| | 收益 | 代价 |
|---|---|---|
| 结构搬运 | 同构的类型自动传递一切性质 | 证明常要「沿 ua 搬」 |
| 逻辑 | ¬UIP（等式类型有高维结构） | 不能再「压平」证明 |
| 工程 | Cubical 系统让 ua 可计算 | 普通内核只能公理化（本章做法） |

**Lean 为什么加不了**（文件实测）：`Eq` 在 Prop、UIP 是定理
（19 章 `uip`）——泛等与其矛盾。要泛等得换 Type 层等式 +
可计算立方内核（cubical Agda / Lean-HoTT 分支）。

> **坑位速记**
> ① Coq record 构造子要 `@MkX A B ...` 全显式——隐式推断在
> seed 位置经常把函数塞进 Type 槽；
> ② `ua e` 的类型标注可能引发宇宙不一致（Set vs Type@{u}）——
> 用 `Definition x := ua e.` 让推断做主；
> ③ Agda postulate 块里不能写 `where`——import 提前；
> ④ `transport (fun _ => X) p u == u`（常值族搬运）是 J-定理
> 不是定义——mini 库里要立引理再用（23 章正文展开）。

---

上一章：[19 路径与同伦](19-paths.md) · 下一章：[21 截断层级](21-truncation.md)
