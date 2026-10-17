# 64 等价论：从拟逆到合同纤维

> 对应读本：HoTT 书第 4 章全部 + §2.4（同伦与等价、自然性引理）。
> 代码：`examples/64_equivalence/`——**cubical Agda 主力**（mini-cubical
> 前奏：J 两行、群律七条、同伦自然性；等价四定义与网络；ua 从
> Glue 手造；funext 一行）+ **Coq mini-HoTT 对照组**（同一套推导的
> 公理化世界版；contrFib→biinv 数据版；相干 τ 由网络合成白送）。

上一章把类型当作空间、路径当作相等。本章回答一个严格的问题：
**什么时候两个类型「一样」？** 直觉答案是「有同构」——但类型论
的同构带证明（拟逆），而带证明的「一样」在高维会**分叉**：同一
个函数可以有多个互不相等的「拟逆证据」。本章的重头戏是把「是
等价」修成一个**命题**（至多一个证据）——四套方案殊途同归。

## 64.1 拟逆的病（书 4.1）

拟逆是教科书式的定义：

> **qinv(f) := Σ(g:B→A). (f∘g ∼ id_B) × (g∘f ∼ id_A)**

问题：它不是 mere proposition（66 章），而且病得可以量化。
书引理 4.1.1 给出精确测量（在泛等下）：

> qinv(f) ≃ Π(x:A). (x = x)

——拟逆的类型等价于「全员的自环」！推导（cubical 侧
`qinv-id→loops` 给出方向一）：从拟逆 (g,α,β) 造自环
`sym(β x) ∙ α x`——**两个同伦的错位差**就是一枚自环；反向
`loops→qinv-id` 把环 r 变成 α:=r、β:=refl。当 A 是纯集合时
全员自环只有 refl，病不发作；但当 A 有非平凡自环（69 章的
圆：loop ≠ refl）时，qinv(id_A) 至少有两个元素
（(id,refl,refl) 与 (id,loop,refl)）——「f 是等价」这句话
开始有多重含义。直觉图像：Π(x:A).(x=x) 是恒等函子的自然
变换——单对象群胚时正是群的**中心**；K(G,1) 的中心非平凡，
等价证据就分叉。

## 64.2 半伴随等价：加一条相干（书 4.2）

修法一（书的正式选择）：在拟逆三份数据上补一条 **2-维相干**：

> **ishae(f) := Σ(g). Σ(η: g∘f ∼ id). Σ(ε: f∘g ∼ id).
>   Π(x:A). f(η x) = ε(f x)**   —— τ 说两条化同伦的路彼此一致

微妙处在定理 4.2.3（qinv → ishae）：g 和 η 可以照抄，但 ε
**不能照抄**——必须重构为

```agda
ε′(y) := sym (α (f (g y))) ∙ (cong f (β (g y)) ∙ α y)
```

预制得能被 τ 拆回 f(η x)。τ 的推导是一条三步链（两个机器
世界里**同一条链**，逐段对齐）：

1. **系 2.4.4**（hdistr）：到恒等的同伦满足 H(h x) ≡ cong h (H x)
   ——由取消律八段链拼出（`sym rUnit ∙ … ∙ rUnit`）；
2. **引理 2.4.3**（natH）：同伦的自然性 H x ∙ cong g p ≡
   cong f p ∙ H y——对 p 归纳一步（cubical 里是 transport 的
   一击）；
3. 组装：`fb == (!α₂·α₂)·fb == !α₂·(α₂·fb) == !α₂·(ap_{f∘g∘f} βx · α₁)
   == !α₂·(ap f βg · α₁)`——每一步是群律或上述引理的一次
   cong 提升（**2-维的 ap**：把「路径的路径」喂给 ap，这在
   cubical 里原生、在 Coq 里是 ap 作用于 paths 类型）。

cubical 文件里这条链以 `chain` 展开、Coq 文件里以四段 `assert`
呈现——同一推导、两副面孔，这是本章机器面的核心对读件。

## 64.3 双可逆与合同纤维（书 4.3–4.4）

修法二（**biinv**）：不升高维数，改拆口袋——左逆与右逆各自独立：

> **biinv(f) := linv(f) × rinv(f)**
> linv(f) := Σ(g). g∘f ∼ id    rinv(f) := Σ(g). f∘g ∼ id

书 4.2.9 的关键观察：f 有拟逆时 linv、rinv 各自**合同**（书
4.2.8+4.2.6 的纤维合同性推论）——两个合同口袋的乘积还是合同。
biinv↔qinv 的桥是缝合同伦 γ（书 2.4.10 方向二）：

```agda
γ y := sym (ηl (gr y)) ∙ cong gl (εr y)   -- gr y ≡ gl y
β′ x := γ (f x) ∙ ηl x                     -- gr(f x) ≡ x
```

修法三（**contrFib**）：干脆忘掉逆，只看纤维——

> **ContrFib(f) := Π(y:B). isContr(fib f y)**，fib f y := Σ(x:A). f x = y

这正是 **cubical 世界的主教**：builtin 的 `isEquiv` 记录的
`equiv-proof` 字段就是它（§64.4 详述）。方向 contrFib→ishae
（书 4.4.3）在 Coq 侧走的是数据版两跳——η 从纤维合同性取出：

```coq
g   y := projT1 (center (fib f y))          -- 中心的第一分量
η   x := ap projT1 (contraction … (x, idpath))
contrfib_to_ishae := qinv_to_ishae (biinv_to_qinv (contrfib_to_biinv cf))
```

**τ 不用单独造——等价网络两跳白送**。这是本章的方法论亮点：
相干性可以由网络传导，不必手拼。四定义的等价网络：

```text
        qinv ──4.2.3 ε′-重构──▶ ishae
         ▲ │忘却 τ               │
   2.4.10γ│ │                    │ishae→contrFib（4.2.6，66 章回填）
         │ ▼                    ▼
        biinv ◀──数据移动──── contrFib
   （右端两箭头在 Coq 侧合成出 contrFib→ishae 的完整通路）
```

## 64.4 定义即工程决策（书 4.5）

书 4.5 的立场：三套定义满足同样的三条（吸收拟逆、被拟逆吸收、
是命题），所以**随选其一**，此后只说「等价」。书选 ishae（数据
最直接），cubical 库选 contrFib（与 Glue/uniform 原语接口最顺），
工业世界三家对照：

| 选择 | 谁在用 | 理由 |
|---|---|---|
| ishae | HoTT 书、Coq-HoTT 库 | 证明时拟逆好找、τ 可后补 |
| biinv | 若干玩具/教学库 | 无 2-维路径、两半独立 |
| contrFib | cubical Agda builtin、Lean `IsEquiv` 血统 | transport 计算的接口 |

选型不影响数学（三者等价），影响的是**下游每一条引理的形状**——
这是 25 章「表示论」（形式化是设计）在等价论上的重演。

## 64.5 嵌入与满射的正确形状（书 4.6）

集合论说「双射 = 单射 + 满射」。类型论的对应物要小心：

> **embedding**：∀ x y. **isequiv(ap f)**——ap 在路径上是等价
> （不是「f x = f y → x = y」——那个形态对非集合类型病态）；
> **surjection**：∀ b. **∥fib f b∥**——纤维**截断后** inhabited；
> **split surjection**：∀ b. fib f b（不截断）——能选原像。

定理 4.6.3：等价 ⟺ embedding × surjection。机器面本章只做
陈述级（∥∥ 是 67 章截断的道具），split 版的两条引理在 67 章
的 truncation 机制就位后回填。注意对照 25 章（TTAFP 线）：
那里「映射 = 泛关系 + ∃¹」是集合层的故事，这里的 embedding/
surjection 是它在高维的正确化——两章连读恰见「同一数学概念
随类型层级的升高而分裂」。

## 64.6 封闭性质（书 4.7）

等价的三条常用封闭律（机器面在 cubical 文件的样本段与 Coq 的
网络合成中各得一半，完整机械版散见后续章）：

- **2-out-of-3**：f、g、g∘f 三者知其二得其三（拟逆的复合格式
  证明）；
- **retract 封闭**：等价的收缩还是等价（纤维是收缩的收缩）；
- **逐点 ⇔ 全空间**（4.7.6/4.7.7）：fiberwise 变换 f 是逐点等价
  ⟺ total(f) 全空间等价——**fibration 视角的发动机**：把「族的
  等价」搬运到「Σ 的等价」，70 章编码-解码的每一层都靠它。

## 64.7 对象分类器（书 4.8）

泛等视角下宇宙 U 是「所有空间的分类空间」：每个函数 f 都等价
于一个 fibration。两个关键引理（fib_pr1 的纤维恰好是族的值）：

> fib_{pr1}(a) ≃ B(a)      （Σ 投影的纤维 = 族在 a 的值）
> A ≃ Σ(b:B). fib f b      （任何函数都「是」fibration）

合起来：交换方块 A → Σ(b:B) fib f b ≃ B ×_U U• 是拉回——
「空间的分类空间」这句范畴论的话在类型论里有了精确坐标。
机器面：fib_pr1 ≃ B(a) 的显式等价在 66 章（Σ 路径刻画）后
回填；本章把 fib 定义与样本立在 cubical 文件里。

## 64.8 泛等蕴含函数外延（书 4.9）

书 4.9 是公理化世界的优雅定理：UA ⇒ 弱函数外延（合同族的 Π
合同）⇒ 函数外延，两步都不轻松（Voevodsky 的证明：Π 是
fib_α(id_A) 的收缩，收缩保合同）。

cubical 世界里这道题**被技术进步消解**——两个「公理」都成了
程序：

```agda
ua     : (A ≃ B) → A ≡ B          -- 从 Glue 原语手造（不是公理！）
uaβ    : transport (ua e) a ≡ e .fst a   -- 计算律可证
funext : f ∼ g → f ≡ g
funext h i j = h j i              -- 方形转置，一行
```

`ua` 的构造：沿区间 i 在 i0 端用 e 把 A 粘到 B、i1 端用恒等粘
B——`primGlue B T e` 一行；`uaβ` 由 transp-Glue 计算律 +
transportRefl（`transp A j a` 在 φ=i1 定义归约为 a）组合而成。
对照 Coq mini-HoTT（65 章）：那里 UA 是公理、transport_ua
（β 律）要**单独再立一条公理**——公理记账的差异就是两个世界
的教科书差异。Coq 侧的 4.9 证明链（UA⇒wfunext⇒funext）以
散文+账单形式在 65 章展开。

## 64.9 机器面导读

**cubical Agda（`ex64_equivalence.agda`，~330 行）**：六个段——
mini-cubical 前奏（interval renaming、J、transportRefl、群律
七条 J-归纳、natH/hdistr）；四定义（Record 版）；等价网络三
箭头（qinv→ishae 的 chain 与 Coq 版逐段对齐）；样本
（idIshaE/negbIshaE——取反的最小非平凡自等价，τ 全 refl）；ua
手造 + uaβ；funext 与 qinv-loops。**零外部依赖**：全部内容
来自 `Agda.Primitive.Cubical` + `Agda.Builtin.Cubical.*` 与
自写件——「自包含 mini-cubical」与 63 章的 mini-HoTT 同一
哲学，但 HIT/泛等**原生计算**。

**Coq（`ex64_equivalence.v`，~200 行）**：同一前奏的 Coq 版
（63 章库 + assoc/ap_pp/ap_id/ap_compose 本章自证）；natH/
hdistr 的 J 归纳版（基座靠定义性吃掉）；四定义 Record；τ 的
四段 assert（与 cubical chain 同构）；contrFib→biinv 的
@mkBiInv 全显式数据版；网络合成。`Print Assumptions
contrfib_to_ishae` 报 **Closed under the global context**——
整条网络零公理。

> **坑位速记**
> ① cubical Agda 的区间运算要 `open Agda.Primitive.Cubical
>   renaming (primINeg to ~_ …)`——`~` 不是默认语法；
> ② `primHComp`/`primTransp` 的**别名定义**会触发
>   CubicalPrimitiveNotFullyApplied/边界检查——直接在用点调用，
>   别名要 eta 展开（本章 ∙ 直接内联 primHComp）；
> ③ Agda 点-free 定义体内**隐式参数不在辖域**——`lUnit {x = x}`
>   得在子句模式里绑定；
> ④ 2-维路径的 cong 链是「路径代数的代数」——每段的 ap 函数
>   形状（k 在左/右/内层）必须与前后段的**结合树**严格对齐，
>   Agda 报 UnequalTerms 时先画树再改；
> ⑤ Coq `!`（65 级）比 `·`（60 级）**结合更紧**：`! p · q`
>   解析为 `! (p · q)`——逆元串联合成一律加括号 `(! p) · q`；
> ⑥ Coq Record 构造子的 {A B} 参数**默认不隐式**：跨
>   destruct 后用 `@mkBiInv _ _ _` 全显式；tactic `exists`
>   只服务 ∃/sig 目标，Record 用 `exact (@mk…)`；
> ⑦ Coq `forall y, c == y` 里 y 的域标注不可省（Record 字段
>   能推断、Definition 右侧不能）；路径记号 `==` 在 fun 域
>   标注位置有解析怪癖——需要类型时用小括号包裹或改 assert；
> ⑧ 巨型 term 的串联用 **assert 分段**再装配——直接嵌套时
>   Coq 的括号/优先级解析会先于类型检查失败（本章 τ 链四段
>   assert 的形态）。

---

上一章：[63 路径与同伦](63-paths.md) · 下一章：[65 泛等](65-univalence.md)
