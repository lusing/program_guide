# 16 FOL 自然演绎：量词规则、等式规则与 Drinker 悖论

> 对书：H&R §2.3（ND 全套 / =i/=e / 量词等价）/ Ben-Ari 3e Ch8 / EFT IV / Mints ch13
> 通道：C/A/L/I/H4（三旗舰）+ C/L（等式规则深嵌入新单元 ex16_eq）

命题 ND 的全部手段（03 章）对 FOL 公式继续有效——连接词还是
那些连接词。FOL ND 的新行李是两组规则：**量词四规则**（∀i/∀e/
∃i/∃e，各带侧条件）与**等式两规则**（=i 自反公理、=e 等量代换）。
本章把 H&R §2.3 的规则全套讲透，机器化分两层：浅嵌入（直接用
内核的 ∀/∃，看规则的本体）与深嵌入（自建 nd 演算装等式规则，
看规则的骨架）。

## 量词四规则逐个讲

### ∀i（全称引入）

```text
  [x 任意]…φ
 ---------- ∀i（x 不在未消假设中自由出现）
  ∀x.φ
```

要证「所有 x 都 φ」，**任取**一个 x 推出 φ——「任取」的纪律是
侧条件：x 不得是任何活跃假设里的自由变元（否则你证明的是
「关于那个特定 x」，不是「关于一切 x」）。**反例**：假设
`P(x)`（x 自由），「证明」∀x.P(x)——如果允许，则从 P(0) 能证
∀x.P(x)，明显荒谬。侧条件就是防这一手。

### ∀e（全称消除）

```text
  ∀x.φ                    ∀x.φ
 -------- ∀e（t 是任意项） --------
  φ[t/x]                  φ[u/x]
```

「对所有成立」的东西对每个具体实例成立—— instantiation。
侧条件：t 对 x 在 φ 中可自由代入（14 章的捕获纪律）。

### ∃i（存在引入）

```text
  φ[t/x]
 -------- ∃i
  ∃x.φ
```

有见证就有存在——注意方向：**从具体到抽象**。∃ 的证明义务
就是交出一个见证（12 章 EP 的演算侧根据）。

### ∃e（存在消除）

```text
  ∃x.φ   [x 假设, φ 假设]…ψ（x 不在 ψ 或未消假设中自由出现）
 ---------------------------------------------------------------- ∃e
  ψ
```

「某物满足 φ」要被利用，就开一个**临时见证框**：假设 x 与
φ[x]，推出与 x 无关的结论 ψ——那 ψ 就是无条件事实。侧条件
「x 不在 ψ 中自由出现」保证结论真的与见证无关（否则你带走
了不该带走的临时代码）。这个「框」的结构与 ∨e 的双框同构——
分情况讨论的量词版。

## 等式两规则（H&R §2.3.1 与式 2.5/2.8）

**=i（自反公理）**：任何项 t，`t = t` 无前提成立——等式指
「计算结果相同」（非语法同一），自己等于自己免费。注意语言
只允许**项之间**的等式（不能写公式=公式——类型分层）。

**=e（等量代换）**：

```text
  t₁ = t₂    φ[t₁/x]
 ---------------------- =e（t₁ t₂ 对 x 在 φ 中可自由代入）
  φ[t₂/x]
```

「相等者可互换」：φ 对 t₁ 成立、t₁ 又等于 t₂，则 φ 对 t₂
成立。H&R 的算例（式 2.9 一带）：前提 `x+1 = 1+x` 与
`(x+1>1)∧(x+1>0)`，=e 一步得 `(1+x>1)∧(1+x>0)`——φ 取
`x'>1 ∧ x'>0`，t₁=x+1，t₂=1+x。侧条件即 14 章的代入纪律
（H&R 约定 2.10：写 φ[t/x] 即默认 t 对 x 自由）。

**=i+=e 的威力**：两条规则就能派生等式的全部「等式律」——
对称（式 2.6：t₁=t₂ ⊢ t₂=t₁，取 φ := `x = t₁`）、传递
（式 2.7：t₁=t₂、t₂=t₃ ⊢ t₁=t₃，取 φ := `t₁ = x`）、
以及谓词代换（P(t₁) 与 t₁=t₂ 推 P(t₂)）。语义侧的锚点在
15 章（§2.4.3：等式锁定为真相等）——规则与语义互相呼应。

## 量词等价族（H&R §2.3.2）

**定理 2.13** 的等价表是量词计算的常用工具箱：

```text
∀x.φ ∧ ψ  ⊣⊢  (∀x.φ) ∧ ψ        （x ∉ fv ψ）
∀x.φ ∨ ψ  ⊣⊢  (∀x.φ) ∨ ψ        （x ∉ fv ψ，直觉逻辑不成立！）
∃x.φ ∧ ψ  ⊣⊢  (∃x.φ) ∧ ψ        （x ∉ fv ψ）
¬∀x.φ     ⊣⊢  ∃x.¬φ             （经典）
¬∃x.φ     ⊣⊢  ∀x.¬φ             （直觉成立）
∀x.∀y.φ   ⊣⊢  ∀y.∀x.φ
∃x.∃y.φ   ⊣⊢  ∃y.∃x.φ
```

注意侧条件的分布：ψ 不含 x 时它「穿越」量词；两条否定等价里
**只有 ¬∃→∀¬ 是直觉主义的**（机器件 `all_to_not_ex_not`/
`ex_not_to_not_all` 双方向零公理正面对应）——¬∀↔∃¬ 的
右半边要经典公理入账（`not_ex_to_not_not_all` 的 classic 账单）。
这张表是 18 章前束范式的规则库。

## 浅嵌入现场：三旗舰

在类型论系里，量词规则的「本体」由内核直接承担：
**∀I = λ、∀E = 应用、∃I = 构造子、∃E = match/obtain**。
侧条件纪律（广义变元不自由出现于未消假设）由类型系统**静态强制**
（Coq 的 intro 拒绝引入已用变元、Lean 的 binder 作用域）。

**(1) 量词 de Morgan 的构造方向（零公理）**

```
all_to_not_ex_not   (∀x.Px) → ¬∃x.¬Px
ex_not_to_not_all   (∃x.¬Px) → ¬∀x.Px
```

**(2) Drinker 悖论（经典）**

```
drinker : ∃x.(Px → ∀y.Py)
```

「任何酒吧里都有一个人：如果他喝，人人都喝」。两分支：

- **人人都喝**路：任取 x=0，前提真 + 结论即假设；
- **有人不喝**路：取那个不喝的人，**前提假使蕴含空真**。

**(3) drinker_nn 的最短证明（Coq 版一处经典）**

```
H : ¬∃x.(Px→∀y.Py) ⊢ False
  先立 Hall : ∀x.Px（一处 classic：若某 x 不喝，则该 x 是
  Drinker——前提假——与 H 矛盾）
  再喂 x=0：蕴含前提 P0 真（Hall）且结论就是 Hall 本身
  → H 自爆
```

比朴素版（三分支、两处经典）短一半——「自指喂食」在量词层的
复用。Drinker 也是 11 章 Glivenko 边界线的现场：drinker_nn
零公理（经典量词定理挂 ¬¬ 构造可证），而 FOL 层 Glivenko 干净
等式失效（¬¬∃x 与 ∃x¬¬ 要 Gödel–Gentzen 翻译区分）。

## 深嵌入现场：等式规则的机器演算（ex16_eq，C/L 新单元）

浅嵌入里 =i/=e 就是内核的 eq_refl/eq_subst——复述内核没有
教学价值。新单元（`examples/16_folnd/ex16_eq.v` 与
`.lean`）自建**深嵌入演算**：沿 14 章 form 加等式原子，
nd 归纳谓词装七条规则：

```coq
Inductive nd : list form -> form -> Prop :=
| ndHyp : forall G f, In f G -> nd G f
| ndImpI : forall G f g, nd (f :: G) g -> nd G (fimp f g)
| ndImpE : forall G f g, nd G (fimp f g) -> nd G f -> nd G g
| ndAllI : forall G x a,
    ~ In x (fvCtx G) ->
    (forall v, nd G (subst a x (tvar v))) -> nd G (fall x a)
| ndAllE : forall G x a t, nd G (fall x a) -> nd G (subst a x t)
| ndEqI : forall G t, nd G (feq t t)
| ndEqE : forall G t1 t2 x f,
    closedT t1 -> closedT t2 ->
    nd G (feq t1 t2) -> nd G (subst f x t1) -> nd G (subst f x t2).
```

读设计要点：

- **feq 是独立构造子**（不是谓词表里的原子）——语义条款
  `eform … (feq t1 t2) := eterm t1 = eterm t2` 把「锁定为
  真相等」（15 章 §2.4.3）写成定义，一眼可查；
- **ndAllI 的侧条件**「x ∉ FV(G)」直接进构造子——H&R 的
  纪律被类型化，违反侧条件的「证明」根本无法构造；
- **ndEqE 的侧条件**取「闭项」形态（t₁、t₂ 无自由变元）——
  H&R 的「t free for x」的**充分强化**：闭项使 15 章
  subst_all_eval 无条件成立（代入交换不失效），教学版回避
  一般化侧条件的携带负担，一般化留文档（此边界如实登记）。

派生件三枚把 H&R 的式 2.6/2.7 与谓词代换全部机器化：

```coq
Theorem eq_sym_nd : forall G t1 t2,
  nd G (feq t1 t2) -> closedT t1 -> closedT t2 ->
  nd G (feq t2 t1).
Theorem eq_trans_nd : forall G t1 t2 t3, ...
Theorem eq_cong_atom : forall G p t1 t2,
  nd G (atom p t1) -> nd G (feq t1 t2) -> ... -> nd G (atom p t2).
```

以 eq_sym_nd 为例走一遍 =e 的用法：要证 `t₂ = t₁`，取
φ := `x = t₁`（x 为 0 号变元充当新鲜名）——φ[t₁/x] 是
`t₁ = t₁`（=i 白拿），=e 换出 φ[t₂/x] = `t₂ = t₁` 收工。
**=e 的全部机智在 φ 的选择**：想要什么形状的结论，就倒推
「哪个 φ 的两次实例化分别给出前提与目标」。eq_trans 同构
（φ := `t₁ = x`）；谓词代换取 φ := `P(x)`。机器证明里
apply 统一不展开 subst，需要 `subst_closed_id`（闭项代入
恒等——侧条件的引擎）与显式换形（坑位速记有实录）。

**边界（诚实清单）**：等式规则相对 eform 的可靠性大定理
（nd G f → 全满足 G 则满足 f）需要一致性+代入交换全套组装
（15 章两旗舰的串接），本章不展开——语义侧只立 FEq 条款与
sanity 现场。

## 五家分工

| 通道 | 内容 |
|---|---|
| Coq/Rocq | 三旗舰全件 + de Morgan 完整版（classic 入账公示）+ **ex16_eq 深嵌入等式演算** |
| Lean | 同构 + `not_forall.mp` 标准件 + rintro 匿名 ∃E + **ex16_eq 同构**（Nat.beq 直连） |
| Agda | 构造面：条件 Drinker 两方向（`when-all`/`when-ex¬`）；完整版如实登记「写不出来」 |
| Isabelle | blast 一行版 + `obtains` 的 witness 语法 |
| HOL4 | PROVE_TAC 直收（与 15 章理论定理同款待遇） |

## 侧条件纪律的现场

- **Coq/Rocq**：`intros x` 后 x 是「任意」的——若 x 已在假设中
  出现，intros 无法引入新广义变元（静态强制）；
- **∃E witness**：`destruct … as [x Hx]` 的 x 是临时见证——
  只能在当前分支使用，跨分支需重新获取；
- **Isabelle**：`obtains x where …` 的 x 只在当前块有效；
- **深嵌入**：侧条件长在构造子参数上（ndAllI 的 fvCtx、
  ndEqE 的 closedT）——比纸面规则多一层「编译期检查」。

## 本章小结

- 量词四规则各带侧条件：∀i 的「任意」、∃e 的「临时见证」、
  两个 instantiation 的「可自由代入」——纪律防的全是同一类
  事故（把特定当普遍、把临时当永久、捕获变元）。
- =i 自反+ =e 代换两条规则派生全部等式律；=e 的机智在 φ 的
  倒推选择。
- 量词等价族里只有 ¬∃→∀¬ 是直觉主义的——18 章前束的规则库。
- 浅嵌入看本体（内核即规则），深嵌入看骨架（nd 装等式）；
  深嵌入的侧条件「类型化」是纸面纪律的强化。
- Drinker：经典证明的量词招牌；其 ¬¬ 版是 Glivenko FOL 边界
  的现场。

## 坑位速记（本章实测）

- **Coq/Rocq**（浅嵌入）：`not_all_ex_not` 是 `Classical_Prop`
  的（签名 `forall U P, ¬∀→∃¬`——**U 要显式传 nat**）；经典
  定理的 `Print Assumptions` 账单：`classic : forall P, P \/ ~P`。
- **Coq/Rocq**（ex16_eq 新增）：
  - match 分支箭头写错（`->` 当 `=>`）报「Invalid notation
    for pattern」——位置在语义定义的 fimp 行；
  - `apply (ndEqE …)` 的统一**不展开 subst**——结论形状对不上
    时先 `assert (Hs : subst … = 目标形状)` + `rewrite <- Hs`
    显式换形（subst_closed_id 是引擎）；
  - 未使用的量化参数（`forall t1 t2` 里 t2 不出现）报
    「Cannot infer the type」——删参或用 `forall _`；
  - `Nat.eqb x x` 对变量 x 不归约——`rewrite !Nat.eqb_refl`
    （多处出现用 `!`）。
- **Lean**（ex16_eq 新增）：
  - 10 章教训复用生效：substTerm 用 `Nat.beq` 直连（`==` 的
    BEq 实例挡 rfl），`beq_refl` 自证（induction + ih 直收，
    succ 情形靠 whnf 一层 beq 子句）；
  - `if_pos (by rfl)` 对 `Nat.beq 0 0` 直收（ground），
    对 `Nat.beq y x` 变量情形先 rewrite 再 destruct；
  - 构造子的隐式参数在 exact 位用具名实例化
    （`Nd.ndEqE (t1 := …) (x := 0) (f := …)`）——元变量
    无法从目标反解 f/x；
  - `absurd hc (by simp)` 处理 fvTerm (tvar n) = [] 的不可能
    假设（`[n] = []` 的 simp 反证）。
- **Lean**（浅嵌入）：`h ⟨x, …⟩ : False` 之后要 `.elim` 展开
  （False 消除到任意目标）。
- **Agda**：构造边界如实登记——「条件 Drinker」两方向是构造
  逻辑的全部；无条件 Drinker 需要量词排中。

---

上一章：[15 FOL 语义：模型、一致性引理与代入交换](docs/15-folsem.md) · 下一章：[17 FOL Hilbert 系统：Gen 侧条件的演绎定理](docs/17-folhilbert.md)
