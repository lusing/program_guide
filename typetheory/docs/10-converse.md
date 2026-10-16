# 10 逆主类型与凝结分离

> 对应读本：Hindley《Basic Simple Type Theory》第 7 章全部（7A 逆
> PT 定理、7B 识别、7C Meyer 算法、7D 凝结分离）。
> 代码：`examples/10_converse/`——**Prolog 主场**（cd 原语、D-定理
> 搜索、与书末主类型表对表）；**Lean 对照**（7C1 的 I_σ 构造、
> 7A2.1 双胞胎定理、双机互证）。

05 章问了「给定项，求最一般的类型」。本章反过来：**给定类型 τ，
有没有封闭项把 τ 当主类型？** Hindley 第 7 章的两段答案：语构侧
的逆 PT 定理（答案：是，且有算法），和逻辑侧的凝结分离规则 D
——一条 1954 年发明、比 PT 算法早上机二十年的「合一即推理」。

## 10.1 逆 PT 定理（7A）

先命名。**λK-PT** 是某个封闭 λK-项的主类型；同理 λI-PT、BCKλ-PT、
BCIλ-PT（7A1；由 9F，它们分别等于 BCKW/BCIW/BCK/BCI-组合的主
类型）。

> **逆 PT 定理（λK 版，7A2）**：
> (i) 封闭 λK-项的每个类型本身就是某 λK-项的主类型；
> (ii) 有算法从（M, T）造出封闭项 M* 使 PT(M*) = T；
> (iii) 而且 M* →β M。
>
> **λI 版（7A3）**：同款三条，但 (iii) 弱化为 M* →βη M
> （λI 里推不出纯 β 版——7A3.1 留了一个 open question）。

**(i) 有个漂亮的推论（7A2.1）**：

> 存在两个封闭项 P、P′，**P =β P′ 但类型集完全不相交**。

构造在 10.4 机器化。「类型集合」与「β-等价类」是两根几乎正交
的轴——06 章已见 β-收缩会增类型，这里直接见**零交**。

## 10.2 识别与骨架（7B）

逆构造的核心视角：把 τ 看成「简单形状 + 一串**识别**」。

> **识别**（identification）in T：代换 [b/a]，a、b 都在 T 中出现
> ——把两个变量「认成同一个」。
> **骨架类型**（skeletal，1-property）：每个变量恰出现一次。

两条结构引理：变量-对-变量代换 = 改名后跟一串识别（7B1.2）；
**每个类型都能从某个骨架识别而来**（7B3——把重复出现换回新变量
即得骨架）。例（7B1.1）：S 的主类型里 [b/a] 识别一次，得到
`(b→b→c)→(b→b)→b→c`。

于是逆 PT 的战线是两步：**先给骨架类型造见证项**（10.3），
**再证识别保持「是某 λI-项的主类型」**（识别引理 7C5，
用单/双重替换引理 7C3/7C4 搭桥——那里要把出现分成**正/负极性**
（9D3：箭头左手为负、右手为正），按极性方向摆放 `(a→b)*` 或
`(b→a)*`）。整套机器证明的细节在书里占了五页，本章机器面取其
构造性核心。

## 10.3 Meyer 的 I_σ 构造（7C1）

骨架 σ 的见证项 I_σ 只需两行递归：

```text
I_a       = I                                （a 是原子）
I_{ρ→σ}   = λx y. I_σ (x (I_ρ y))
```

两条不变量（7C1）：**PT(I_σ) = σ→σ**，且 **I_σ →βη* I**
（后者因体内只有 x、y 与 I_家族的传递——每层都 βη-坍缩）。
Lean 版本就是这一行的直译：

```lean
def iS : Ty → Term
  | .tvar _ => I
  | .arrow ρ σ => lam (lam (app (iS σ) (app (var 1) (app (iS ρ) (var 0)))))
```

机器断言（全部 `by rfl`，字面按发号器口径）：

```lean
example : principal (iS a2)        -- a2 = t0→t1
        = some ((t4→t6) → (t4→t6)) := by rfl
example : nfBetaEta 50 (iS a2) = I := by rfl      -- βη-坍缩到恒等
example : isLI (iS a2) = true := by rfl           -- 全程 λI
```

## 10.4 双胞胎定理的机器面（7A2.1）

取两个**无公共实例**的类型（3C2.2：`a→a` 与 `a→a→a`——公共实例
会被 occurs check 拒绝），构造

```lean
def P1 : Term := iS (a→a)          -- PT = (a→a)→(a→a)
def P2 : Term := iS (a→a→a)        -- PT = (a→a→a)→(a→a→a)
```

三组断言：

```lean
-- βη-相等：都坍缩到 I
example : nfBetaEta 50 P1 = I ∧ nfBetaEta 50 P2 = I := ⟨by rfl, by rfl⟩
-- 类型集不相交：两方向的单侧匹配都撞 occurs check
example : matchInst 20 (PT P2 的字面) (PT P1 的字面) = none := by rfl
example : matchInst 20 (PT P1 的字面) (PT P2 的字面) = none := by rfl
```

这是 occurs check 在本指南的**第三次显灵**：05 章 ω 死于它
（项层自应用）、09 章伪证明死于它（类型层循环项）、这里它划出
两条永不相交的类型集。同一块石头，三处闭门。

## 10.5 凝结分离（7D）

现在换到公理侧。A-逻辑（09 章 6D）的两条规则 (→E)+(Sub) 可以
**凝成一条**：

> **规则 (D)（condensed detachment，Carew Meredith 1954）**：
> 从 `ρ→υ` 与 `τ` 推出 `D(ρ→υ)τ`：取 (ρ,τ) 的最一般公共实例
> `v = s₁(ρ) = s₂(τ)`，结论 = `s₁(υ)`；无公共实例则规则不适用。

(D) 是「先各自代换成最一般可用形状，再做一次 MP」——7D1.1 说它
恰好是 MP+Sub 能给出的**最一般结论**。与类型论的接缝只有一行
（7D2，D. Meredith 引理）：

> 若 PT(P) = ρ→υ、PT(Q) = τ，则 **PT(PQ) = D(ρ→υ)τ**（模变元
> 换名）。

——D 就是 PT 算法的应用情形。**历史注（7D3）值得整段照抄**：
D 规则由 Carew Meredith 发明（其堂弟 David Meredith 回忆 1954 年
学到），首次印刷在 Lemmon 等 1957；波兰线索更早——Łukasiewicz
1939 发表过一个特例，间接证据指向 **Tarski 在 1930 年前就可能
 formulate 了 D 概念**；David Meredith 1957 年把 D 算法写成程序、
 跑在 **UNIVAC 1** 上——按 7D2，**那本质上是第一个形式化并在
 机器上运行的主类型算法**（比 Curry/Hindley/Morris 早十一年，
 与 05 章 4.7 的优先权史闭环）。

**凝结逻辑与 D-完全性**：把 A-逻辑的两条规则换成单条 (D) 得到
condensed A-logic（7D4）。A 是 **D-完全**的若两套定理集相同。
主定理组：

> 7D6（Meredith 的 Curry–Howard）：凝结 A-逻辑的定理 = 组合子
> 集合的应用组合的主类型。
> 7D7：R_ 的 {B,C,I,W} D-完全；7D10：直觉主义的 {B,C,K,W} D-完全
> （经 7D9 D-扩张引理：D-完全 + a→a 可证 ⟹ 保守扩张仍 D-完全）。
> 反例也存在：BCI/BCK 的公理集**不** D-完全（7D11——书末索引
> 点名 D-incompleteness）。

## 10.6 Prolog 实验室：合一即推理

`ex10_cd.pl` 的三件套：公理模式（09 章同款）、**cd 原语**、
D-定理搜索：

```prolog
cd(Major, Minor, Conc) :-
    copy_term(Major, arr(P, Q)), copy_term(Minor, T),
    unify_with_occurs_check(P, T),   % m.g.c.i.：合一就是它
    Conc = Q.
```

四组检查（全部通过）：

| 检查 | 结果 | 出处 |
|---|---|---|
| `cd(B,B)` | `(x→y→z)→(x→(w→y)→(w→z))` | 与 Lean `principal (B B)` 双机互证 ✓ |
| `cd(S,K)` 再 `cd(·,K)` | 链终值 = `a→a` | SKK = I 的 D-版 |
| `cd(C,I)` | `a→(a→b)→b` | CI = λyz. z y（反向应用子） |
| `cd(I,K)` | K 自己的主类型 | I K =β K |
| D-定理：I from {B,C,K} | 深度 4 内可导 | 7D10 直觉主义 D-完全的核 |

**双机互证**是本章的验证设计：主类型表的 OCR 不可靠，就让两台
机器独立算同一件事——Prolog 走 D（逻辑侧），Lean 走 PT（项侧），
字面 α-一致即对表成功。同样的互证还捎带一个**PT 不是 β-不变量**
的活样本：

```lean
example : principal (app S Kc) = some ((t5→t4)→(t5→t5)) := by rfl
#eval principal (lam (lam (var 0)))   -- some (t0 → (t1 → t1))
```

`S K =β λy z. z`（`nfBetaEta 50 (app S Kc) = λλ.0` 机器可证），
但未缩项的主类型 `(a→b)→(a→a)` 是缩后项主类型 `a→b→b` 的**真
实例**——β-展开会收紧类型（06 章 Eq-规则的动机在这里有了最小
反例对）。

## 10.7 与自动推理的血缘

D-规则在定理证明器世界的身份：它是**单文字超归结**的命题版——
Otter/Prover9 的 `hyperresolution` + `paramodulation` 组合在纯
蕴涵片段上恰好实现 D。Carew Meredith 用 D 手算命题逻辑公理系统
的推导（Lemmon 1957 成册），David Meredith 1957 上机——这条线
经 Kalman 1983 的综述进入自动推理正史。**合一（Robinson 1965）
是连接两条线的桥**：PT 算法拿它当引擎（05 章），D 规则拿它当
语义（本章）——同一个数学物件，1965 年之前已被两条战线各自
预演。

> **坑位速记**
> ① Prolog 的 copy_term 隔断前提间实例化传播——D-搜索器要
> 「大前提先落地、小前提证同一个 P」，不能 cd 之后再证未绑定
> 的 minor（本批初版 bug）；
> ② 断言字面跟机器走：iS 构造的 PT 变元编号来自算法计数器
> （t4→t6 而非 t0→t1）——先 #eval 后回填，别按书抄；
> ③ Prolog 变量名别用小写原子（`m` 不是变量，是 atom——静默
> 变成「证出任意公理」的假阳性）；
> ④ matchInst 的 occurs check 是 7A2.1 双胞胎不相交的唯一
> 防线——去掉它，`(a→a→a)→(a→a→a)` 会「匹配上」`(a→a)→(a→a)`。

---

上一章：[09 弱逻辑与子结构 λ](09-sub.md) · 下一章：[11 居留项计数](11-counting.md)
