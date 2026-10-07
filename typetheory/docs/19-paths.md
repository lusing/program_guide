# 19 恒等类型再审视：路径与同伦

> 对应读本：HoTT 书第 1–2 章；coq-hott 教程 04–06 章的
> 自包含重演。代码：`examples/19_paths/`——Coq（**零公理**
> mini-HoTT 路径库）、Agda（群律镜像）、Lean（群律镜像 +
> Prop 层天花板实测）。

## 19.1 三个问题，打开新世界

把 12 章的相等类型放回显微镜下，问三个 12 章没问的问题：

1. `p : a = b` 的 **p 自己**有没有内部结构？（12 章：没有——
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
**∞-群胚**。12 章的 J 只是这个世界的「沿 refl 生成的一切」。

## 19.2 住在哪层：三家的一览

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

## 19.3 路径代数：群律全部免费

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

## 19.4 J 的计算行为：只在 idpath 上

一个容易被忽略的语义细节（后面 HIT 章的伏笔）：

```coq
Eval compute in (concat_pV (idpath : 2 == 2)).   (* 直接给出 idpath *)
```

`transport P idpath u` **定义性**等于 u——J 消去只在 refl 构造子
上计算。但 `p · idpath` 不折叠（19 章 Coq 文件里 `ap_pp` 归纳
变量的选择就是被它逼的：`idpath · q` 折叠、`p · idpath` 不折）。
这正是 22 章 HIT 要打破的天花板：**区间/圆的构造子没有计算
规则**，必须显式补充公理——到时对照。

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

上一章：[18 提取与运行](18-extraction.md) · 下一章：[20 泛等](20-univalence.md)
