# 第 37 章 标号演绎与相等：缺失的实体

> 对书：Ruy J. G. B. de Queiroz & Anjolina G. de Oliveira《Natural
> Deduction for Equality: The Missing Entity》（Prawitz 祝贺卷第 4 篇）。
> 机器件：`examples/37_lndequality/ex37_lndequality.v` 与 `.lean`。

「a = b : D」这个判断有什么毛病？de Queiroz 与 de Oliveira 的回答
出人意料：它**忘了为什么**。两个项相等的原因——走了哪条改写路径
——在判断里无处安放。要恢复这份「上下文信息」，就得给等式的证明
配上一个**标签演算**：等式写成 a =ₛ b : D，其中 s 是「改写理由」
（a composition of rewrites）。这就是标号自然演绎（LND）的等式片段。
而「缺失的实体」书名所指有二：一是等式证明里缺席的理由域，二是
Herbrand/Skolem 传统里早就该获得公民权的**函数符号**——证明论要
研究证明本身，就不能只让 Gentzen 的公式与 Herbrand 的词项各霸一
侧。

## 36.1 定义相等 vs 命题相等：λβη 的公理组

书中先把「相等」劈成两半。**定义相等**是 λ 演算式的：λβη 理论的
公理组（α）（β）（η）（ξ）（μ）（ν）（ρ）（σ）（τ）——抽象换名、
应用收缩、外延、同余（λ 与应用两侧）、自反、对称、传递。它们是
**演算的胶水**，从不当定理证明。**命题相等**才是逻辑联结词：有引
入规则（自反）与消去规则（等量代换），需要**证据**支撑。

把这两半装进同一套机器的办法，是把公理组逐条映射到「理由复合子」
上（`ex37_lndequality.v` 尾注的对位表）：ρ↔`rRefl`、σ↔`rSym`、
τ↔`rTrans`、μ/ν↔`rCongArg`（函数同余），而 (β)(η) 这类原子改写
↔带证书的 `rStep`。

## 36.2 理由 AST：原子步带证书

机器件的地基是一个定向重写系统——群论三条公理的定向版（0=左单位
e·x→x；1=左逆 x⁻¹·x→e；2=结合 (x·y)·z→x·(y·z)），`step1 rid t`
执行**最左最外恰一步**。理由 AST 就架在它上面：

```coq
Inductive reason : Type :=
| rStep (rid : nat) (src dst : gt)   (* 原子步：带两端证书 *)
| rRefl                             (* ρ *)
| rSym (s : reason)                 (* σ *)
| rTrans (s t : reason)             (* τ *)
| rCongArg (i : nat) (s : reason).  (* μ/ν：在第 i 个参数里做 s *)
```

关键设计：原子步 `rStep rid src dst` **自带两端项**，合法性
`validStep` 单独查——`step1 rid src` 必须恰好给出 dst。证书让「等
式证明=改写链」从修辞变成可核对的数据：

```coq
Definition validStep (r : reason) : bool :=
  match r with
  | rStep rid src dst =>
      match step1 rid src with
      | Some u => gtEq u dst
      | None => false end
  | _ => false end.
```

`reasonOK` 递归检查全树每片叶子都持证——一条复合理由成立，当且仅
当它分解出的每个原子步都是重写系统的真实一步。

## 36.3 重放引擎：把理由跑成中间项序列

`replayOpt fwd t r` 是本章的心脏：从项 t 出发，沿理由结构**重放**，
每个原子步核对证书、σ 翻转方向、合同下钻，最终交出终点（或失败）
。两个容易想错的细节都在 τ 上：

```coq
| rTrans s u =>
    (* 正向：先 s 后 u；逆向（σ 翻转后）必须**倒序**：先逆 u 再逆 s *)
    if fwd
    then match replayOpt true t s with
         | Some m => replayOpt true m u
         | None => None end
    else match replayOpt false t u with
         | Some m => replayOpt false m s
         | None => None end
```

逆向重放若不倒序，σσ 的对消在样本上当场翻车（本章实测坑位之一）
。`replayOK a b r` 把「证明 a=b 的理由 r」判为真，当且仅当重放
确实从 a 走到 b 且全叶持证。电一跑通书里那种群论等式：

```coq
Definition a1 : gt := gmul (ginv x) (gmul ge x).   (* x⁻¹·(e·x) *)
Definition chain1 : reason :=
  rTrans (rCongArg 1 (rStep 0 (gmul ge x) x))      (* 右参走左单位 *)
         (rStep 1 (gmul (ginv x) x) ge).           (* 顶走左逆 *)

Example chain1_ok : replayOK a1 ge chain1 = true.
```

电二把 σ/τ 验证成**导出规则**：对称 = 重放反向跑（
`symchain := rSym chain1` 从 e 走回 a1），传递 = 顺次重放。

## 36.4 标签正规化：冗余消除的 TRS

LND 的正规化定理在书里是「对标签的项重写系统」证明的——冗余的理
由（空转的 ρ、对消的 σσ、白做的合同）应当被剪掉。`nrm` 实现五条
法则：ρ∘s→s、s∘ρ→s、σσ→ρ、合同ρ→ρ、σs∘s→ρ：

```coq
| rSym (rSym s) => rRefl
| rTrans rRefl t => nrm t
| rTrans (rSym s) t =>
    if reasonEqb s t then rRefl else rTrans (rSym (nrm s)) (nrm t)
```

电三验证两件事：`nrm chain1' = chain1`（带 τ∘ρ 包装的理由正规化
为裸链），以及**端点保持**——`replayOK a1 ge (nrm chain1')` 照样
成立。这正是「正规化定理=标签重写的可靠性」的样本面。

## 36.5 内延性现场：Iext 丢掉的轨迹

书 §1 对 Martin-Löf 外延相等类型 Iext 的批评可以一句话复述：
**引入规则里 a、b 不出现在轨迹中**——`Iext-introduction` 的标签只
有典范元 r，被等置的两端从证明里消失；消去规则里 c 的全部轨迹又被
扔掉。外延系统里「为什么相等」在类型层**无处存放**。

机器件把这笔批评量化成一次对照。同一等式 e·x = x 配两条理由：
裸原子步 `direct_id`，和带一层 τ∘ρ 包装的 `chainC`——

```coq
Definition direct_id : reason := rStep 0 (gmul ge x) x.
Definition chainC : reason := rTrans direct_id rRefl.

Example intensional_witness :
  andb (replayOK a2 x chainC)
       (andb (negb (reasonEqb chainC direct_id))   (* 理由层：可区分 *)
             (extEq (gmul ge x) x))                (* 外延层：塌缩 *)
  = true.
```

`reasonEqb` 在理由层分得开两条证明；而外延侧的 `extEq`（范式相
等：`gtEq (nf a) (nf b)`）只能回答「等/不等」——对它而言所有证明
都是同一个 `true`。**内延性 = 系统是否在乎证明的同一性**，这个定
义性的对照就是 Iext/Iint 之争的最小实验。书 §2 的其余部分——
Gabbay 的 LDS 纲领（标号=泛函演算、公式=逻辑演算的二维谐和）、
Herbrand 泛基与锐化 Hauptsatz 的中矢列血统（∃ 前束化、量词下推
的换位引理）、Frege 的值域算子 ε/∀ 与抽象/应用的雏形——属文献
线，教程点到为止。

## 36.6 与本教程其余章节的关系

- 第 34 章的推导 AST 把「规则形状」数据化；本章把「等式的理由」数
  据化——两章合起来是「证明作为可检查对象」这一 Prawitz 学派主
  题的两个切面。
- 第 35 章的 ND 代入/替换机器（`subst`）在本章的合同复合子里复用
  同一思想：操作的位置感（第 i 个参数）必须进数据。
- 第 118 章（同一性与结构主义）的 Leibniz 等词是命题相等的另一副
  面孔；本章的改写理由给出「等词证明的内部结构」这一第 118 章没
  有展开的维度。

## 机器件清单

| 件 | 位置 | 说明 |
|---|---|---|
| 群论项+定向重写 | `gt/step1/stepAny` | 最左最外恰一步；三条规则 |
| 理由 AST | `reason` | 原子步带两端证书 |
| 合法性检查 | `validStep/reasonOK` | 每片叶子都是真实改写步 |
| 双向重放 | `replayOpt` | σ 翻转、τ 逆向倒序、合同下钻 |
| 标签正规化 | `nrm` | 五条冗余法则+端点保持账 |
| 内延对照 | `chainC vs direct_id` | 理由层可区分/外延层塌缩 |
| 范式 | `oneStep/nfF/nf` | 外延侧的判定器（燃料版） |

## 坑位速记（本章实测）

- **τ 的逆向倒序**：`replayOpt` 的 `rTrans` 分支在 rev 方向必须先
  逆 u 再逆 s——按正向顺序逆放，σ 样本（`symchain`）当场失败，
  症状是 `None`（起点对不上原子证书）。
- **Coq 互递归的降参**：`replayOpt` 与非递归的 `stepGetArg/
  stepSetArg` 挂 `with` 会被「Cannot guess decreasing argument」
  拒收——非递归帮手拆成独立 Definition。
- **`nf` 非结构递归**：`step1` 的输出不是子项——燃料版 `nfF`
  60 步不动点；Lean 侧同理，且「先 match step1 再 match t」的
  `stepAny` 认不出降参，也改燃料下钻。
- **Lean 运算符优先级**：`a && b == 0 = true` 解析歧义——布尔复
  合断言一律加括号 `(a && (b == 0)) = true`。
- **Lean 中缀洞**：`validStep ·` 单参洞也要括号；命名模式
  `r@(.rStep rid src dst)` 里 r 未用则直接写构造子模式。
- **替换脚本的区间吞噬**：用 [start,end) 切片替换文件段落时，区
  间里夹着的 Definition 会一起被吃掉——`a2/direct_id` 曾被误删，
  症状是后续断言 Reference not found。改完必须 grep 引用。

## 小结

把「为什么相等」写进判断，等式逻辑就有了内延的骨架：理由是数据、
重放是语义、正规化是标签上的重写、外延性是「塌掉理由」的那一面。
「缺失的实体」补上之后，命题相等不再是定义相等的影子，而是一门
有自己证明论的同余理论——这正是标号演绎纲领给证明论的一般许诺：
元层的每一种「理由」，都值得在对象层有一个名字。

---
上一章：[36 归约分解：抽象归约系统](docs/36-ars.md) · 下一章：[38 「一般」逻辑与滤子](docs/38-generally.md)
