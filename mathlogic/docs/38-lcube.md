# 第 38 章 λ-立方与定理证明器

> 对书：Jonathan P. Seldin《Type Theories from Barendregt's Cube for
> Theorem Provers》（Prawitz 祝贺卷第 7 篇）。机器件：
> `examples/38_lcube/ex38_lcube.v` 与 `.lean`。

为什么一个证明助手的内核可以小到「可信任」？Seldin 的答案分三层：
(1) 逻辑内核选 λ-立方里的某个系统——它们都是**纯类型系统**（PTS），
差别只有一行规则；(2) 一致性由强正规化定理保证（无居元的 ⊥）；
(3) 用户的数学不是靠改内核得到的——**未证假设**以新常元 c:A 的形式
加入语境，而「哪些假设组合安全」有自己的理论。本章把这三层全部
装进一个三开关的类型检查器。

## 38.1 八个系统，一行差异

PTS 的语法六件套（`ex38_lcube.v`）：

```coq
Inductive tm : Type :=
| var (n : nat) | srt (b : bool)   (* false=Prop(∗) true=Type(□) *)
| app (a b : tm) | lam (x : nat) (A b : tm) | pi (x : nat) (A B : tm).
```

通用规则四条：公理 Prop : Type；(start) 语境里的变量取自己的类型
（我们的语境是 (名,类型) 表，start 隐含）；(weakening) 隐含于
lookup；(conversion) 类型按 β-转换等价（`convF` 燃料版：whnf 到头
+ 结构比较 + α-改名）。**全部系统差异浓缩在 (ss′rule)**——
Πx:A.B : s′ 需要配对 (s,s′)：

```coq
Definition ruleOK (fl : flags) (s1 s2 : bool) : bool :=
  match s1, s2 with
  | false, false => true          (* (∗,∗) 恒有：λ→ 的全部 *)
  | true, false => fPoly fl       (* (□,∗)：多态——λ2 *)
  | false, true => fDep fl        (* (∗,□)：依值——λP *)
  | true, true => fTops fl        (* (□,□)：类型算子——λω *)
  end.
```

三开关 (poly, dep, tops) 拼出八系统：λ→(000)、λ2(100)、λP(010)、
λP2(110)、λω̄(001)、λω=**Fω**(101，Seldin 原文「若 s 是 Prop 则 s′
也是」恰是 (□,∗)+(□,□) 两组)、λPω(011)、λC(111，构造演算)。

## 38.2 检查器的两个暗礁

`inferF` 是燃料版推断（`lam` 分支要**再查一次「体类型的类型」**
——非结构递归，Coq/Lean 都要显式燃料）。先讲两个本章实测踩实的
暗礁：

**暗礁一：λ 与 Π 的排序判定不对称**。Πx:A.B : s′ 需要 B 本身是类
型（B 的类型是排序）：`asSort TB` 直接查 TB。λx:A.b : Πx:A.(typeof
b) 需要的是 **typeof b : s′**——即先推出 b 的类型 TB，再查 TB 的
类型是不是排序。两个分支若用同一个判定，eqRefl 那类样本在 λP 里
会静默被拒。

**暗礁二：conversion 是双向的**。检查 `inferOK fl G a T` 时拿推断
出的 U 与声明 T 做 `conv`（β-同余），不是语法相等——`conversion_
beta` 电用 `(λ9:Prop.9) ⊥` 与 `⊥` 的对齐钉死这一点。

## 38.3 谁收谁不收：三开关的门槛样本

电池的核心是四个「门槛样本」，每个样本在立方上切出一道面：

**id 要多态**。`λA:Prop. λx:A. x : ∀A:Prop. A→A`——外层 ΠA:Prop
的配对是 (Type,Prop)。λ→ 拒收，λ2 与 λC 收：

```coq
Example id_needs_poly :
  andb (negb (inferOK lARROW [] idTerm idType))
       (andb (inferOK lPOLY [] idTerm idType)
             (inferOK lCOC [] idTerm idType)) = true.
```

**Leibniz 相等要依值+多态**（本章实测最有趣的一课）。样本语境
[A:Prop, a:A]，自反性的类型与证据：

```coq
Definition eqTy : tm :=
  pi 2 arrT (pi 4 (app (var 2) (var 5)) (app (var 2) (var 5))).
   (* ΠP:A→Prop. Πh:P a. P a *)
Definition eqRefl : tm :=
  lam 2 arrT (lam 4 (app (var 2) (var 5)) (var 4)).   (* λP. λh. h *)
```

这道题**同时**踩两个开关：谓词类型 A→Prop 需要 (Prop,Type)（依值
——λP 的招牌），而对谓词变量 P 的量化需要 (Type,Prop)（多态——λ2
的招牌）。初稿以为「Leibniz = LF 的依值」只开 dep 就够——机器说
不：**纯 λP 与纯 λ2 都拒收，λP2 与 λC 才收**。λP2（λ2+λP）在立方
里恰是这两个方向汇合的角点，Leibniz 式定义正是它的地盘。

**⊥ 是 λ2 的合法命题**。Seldin 定义 2 的二阶编码 ⊥ := ∀x:Prop.x、
∧AB := ∀w:Prop.(A⊃B⊃w)⊃w 等都以 (□,∗) 为门槛——λ→ 连「把 Prop
当作可量化的论域」都不允许：

```coq
Example bot_needs_poly :
  andb (isPropIn lPOLY [] botT) (negb (isPropIn lARROW [] botT)) = true.
```

**基系统无 ⊥ 居元；坏假设立即有**。一致性是强正规化定理的推论，
机器只能给「候选居元全被拒」的样本面（恒等实例、裸变量）。但对
称的一面完全可机器：**用户私货可以一击致命**——

```coq
Definition badCtx : Ctx :=
  [ (0, srt false); (1, var 0); (2, negT (var 0)) ].
   (* c1:Prop, c2:c1, c3:¬c1 *)
Example bad_assumptions_explode :
  inferOK lCOC badCtx (app (var 2) (var 1)) botT = true.
```

c₃ c₂ : ⊥——Seldin 的原话值得抄录：这「不否定强正规化定理保证
的一致性；但在任何实际应用中必须避免这类假设」。他的正题由此展
开：**强一致环境**（定义极弱——不能含 ¬、=、∧、∨、∃ 型公式的
类型）保证安全；含「不同正规形之间等式的否定」的环境加上经典公
理 cl : ∀u:Prop.¬¬u⊃u 也安全（双否定翻译的变体）——文档线，本
章不再机器化。

## 38.4 数字与「异常居元」（文献线）

Seldin 用递归子 R 定义 N（每型配一条常元 + 两条 β 式归约），然后
指出一个惊人事实：**λA:Prop.λx:A.x 也是 N 的居元**，但它不 β-转换
到任何数字项——Leibniz 等式（在那里=转换）抓不住它，数学归纳因此
不能照搬。Pfenning–Paulin-Mohring 给出更彻底的反例。这件事的教训
是「未证假设 + 定义扩展」比「加新规则」安全：定义错了最多证不出
东西，规则加错了会产假。本章把这条线留作文档——它需要带常元归约
公理的扩展检查器，机器账在教程的边界外（有兴趣的读者：把
`badCtx` 的技巧推广到「常元 + 归约方程」即可自建）。

## 38.5 与本教程其余章节的关系

- 第 14 章（Curry–Howard）给了 λ→ 的证明语义；本章把 λ→ 放回它
  的家族——三开关的每格都是一个「证明助手的候选内核」。
- 第 35 章的项语言是 ND 的证明项；PTS 的 λ/Π 是同一思想的「类型
  层」版本——(conversion) 规则就是那里的 β-归约在类型检查中的
  位置。
- Coq/Lean/Agda 本身分别是 λC/λPω⁺/λPω⁺ 血统的后代——本章的
  三开关是「这些工具差在哪一行」的最简模型。

## 机器件清单

| 件 | 位置 | 说明 |
|---|---|---|
| 项+替换+相等 | `tm/subst/tmEq` | named-样本守 Barendregt 约定 |
| β 三件 | `whnfF/convF/nfF` | 全燃料版（subst 打破结构递归） |
| 三开关 | `flags/ruleOK` | (□,∗)/(∗,□)/(□,□) |
| 推断 | `inferF` | 燃料；λ 分支双查「体类型的类型」 |
| 八系统 | `lARROW…lCOC` | λ→ 到 λC |
| 门槛样本 | 五电 | id/Leibniz/⊥/一致性/坏假设 |

## 坑位速记（本章实测）

- **λ/Π 排序判定不对称**：Π 查「B 的类型是排序」（asSort TB）；
  λ 查「TB 的类型是排序」（再推断一次 TB）——写一样的话 eqRefl
  在 λP 里静默失败。
- **Leibniz 要双开关**：「依值=LF 所以 λP 够」是想当然；谓词变
  量量化的 (□,∗) 不可少——先跑机器再写结论（又一例）。
- **「⊥ 是命题」≠「⊥ 有居元」**：isPropIn（botT : Prop）在 λ2
  就是 true；一致性断言要查的是 infer 候选**项**对类型 ⊥——初稿
  把两件事塞进一个 or，断言反着挂。
- **非结构递归三连**：whnf/conv/nf 里 subst 出现处全是雷——全燃
  料化；Lean 的 `_ + 1` 模式必须命名燃料（老坑四现）。
- **Lean 冗余分支**：`match nfF n u with | .lam… | u' => …` 之后
  再补 `| _ =>` 是 redundant alternative（u' 已全兜）——warning
  即 error 的通道纪律。

## 小结

λ-立方把「证明助手的类型论」压缩成一行可拨动的开关：多态、依值
、类型算子。三开关的八格各有门槛样本——id 切多态、Leibniz 切双开
关、⊥ 切二阶编码、坏假设切一致性的边界。Seldin 的工程教训在六十年
后依然成立：**信任来自小内核+强正规化，扩展走「假设与定义」而非
「新规则」**。本章的检查器不到三百行，却能对每个角落的系统给出
收/拒的判定——这正是 PTS 抽象的红利。

---
上一章：[37 「一般」逻辑与滤子](docs/37-generally.md) · 下一章：[39 线性逻辑的自然演绎与范畴语义](docs/39-linear.md)
