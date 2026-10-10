# 第 35 章 Zucker 对应：截消与正规化

> 对书：Christian Urban《Revisiting Zucker's Work on the Correspondence
> Between Cut-Elimination and Normalisation》（Prawitz 祝贺卷第 2 篇）。
> 机器件：`examples/35_zucker/ex35_zucker.v` 与 `ex35_zucker.lean`。

1974-75 年，J. Zucker 证明了一个直觉式的命题的精确版：在 {∧,→}（书
写为 (∧,→,⇒)）片段里，矢列演算的**截消**每走一步，自然演绎推导的
**正规化**就跟着走一步，反之亦然。可惜 Zucker 的证明背着「索引公
式」的沉重机器。Urban 本篇的贡献是把那套机器整个换成一个干净的
**项重写系统**：给两种演算各配一个项语言，把「截消↔正规化」变成
「两组重写规则在翻译下互镜像」。本章把这套双项语言原样做成可执行
程序，并让书里最有趣的发现——**对应在 ∨ 处断裂**——得到一次机器
抓拍。

## 35.1 双项语言：ND 项与矢列项

ND 侧用 Gallier 式项指派（`ex35_zucker.v` 第 1 节）：`pr/fst/snd`
配 ∧，`lam/app` 配 →，另带 ∨ 侧的 `inl/inr/case_`（断裂现场要用）：

```coq
Inductive tm : Type :=
| var (n : nat) | pr (a b : tm) | fst (a : tm) | snd (a : tm)
| inl (a : tm) | inr (a : tm)
| case_ (d : tm) (x y : nat) (a b : tm)   (* case d of x⇒a | y⇒b *)
| lam (x : nat) (a : tm) | app (a b : tm).
```

矢列侧是 Urban 的招牌设计——**名字（name）与余名（co-name）**：
左边公式挂名字 x:），右边挂余名（⟨a)。名字可以被「改名」但不能被
代换；圆括号 = 绑定名，尖括号 = 绑定余名。语境是 (名,公式) 的表，
**结构规则全部隐式**（Urban 强调 contexts-as-sets 的红利：Gentzen
LJ 里 360 种换位截情形被「证明代入」压成 24 条子句）：

```coq
Inductive st : Type :=
| SAx (x a : nat)
| SAndR (a b c : nat) (M N : st)      (* 右规则：⊢ a:A, ⊢ b:B ⊢ c:A∧B *)
| SAndiL (i : bool) (x z : nat) (M : st)  (* 左规则：吃 i 号分量 *)
| SImpR (x a c : nat) (M : st)
| SImpL (a x z : nat) (M N : st)
| SCut (A : form) (a : nat) (M : st) (x : nat) (N : st).
```

两个教学取舍要交代：其一，Urban 原版里 `Cut` 的截公式由推导读出，
我们把公式 `A` **显式写进项里**、由检查器核对两侢单化一致；其二，
检查器**自顶向下**（`stCheck G M C` 的后件公式作输入——闭样本端式
已知，这正是可判定的下界入口）：

```coq
| SCut A _ M x N =>
    andb (stCheck G M A) (stCheck ((x, A) :: remv x G) N C)
```

## 35.2 Prawitz 翻译 |·|：右规则上引入、左规则下消去

两种演算说同一批判断，靠的是 1965 年 Prawitz 给出的标准翻译：**右
规则映成根处的引入、左规则映成顶处的消去、Cut 映成 ND 代入**。代
码只有六行：

```coq
Fixpoint trans (M : st) : tm :=
  match M with
  | SAx x _ => var x
  | SAndR _ _ _ M N => pr (trans M) (trans N)
  | SAndiL i x z M =>
      subst x (if i then snd (var z) else fst (var z)) (trans M)
  | SImpR x _ _ M => lam x (trans M)
  | SImpL _ x z M N => subst x (app (var z) (trans M)) (trans N)
  | SCut _ _ M x N => subst x (trans M) (trans N)
  end.
```

读一遍就明白方向感：`SAndR` 变 `pr`（引入），`SAndiL` 变「把名 x
换成 `fst (var z)`」（消去），`SCut` 变代入。命题 2（「矢列项良型
则翻译良型」）的样本面由电零+电一承担：

```coq
Example andcut_typed : stCheck Gand andCut fA = true.
Example trans_andcut :
  tmEq (trans andCut) (fst (pr (var 0) (var 1))) = true.
```

`andCut` 的结构值得对照着书读：左项 `SAndR ⟨0⟩(Ax 0 0) ⟨1⟩(Ax 1 1)`
证出 A∧B，右项 `SAndiL false 0 2 (Ax 0 4)` 消费它的左分量——翻译
后 `fst ⟨var 0, var 1⟩`，**一个 β 红ex在两个演算的接缝处显形**。

## 35.3 cut1：截消一步归约

`cut1` 实现顶截消去的三族（书 Fig. 5 的样本化）：

- **逻辑截**：主 premises 是右规则。∧ 的情形——`Cut⟨c⟩(AndR ⟨a⟩M
  ⟨b⟩N c) (x)(AndiL i (x')Q, x)` 收缩为 `Cut⟨aᵢ⟩Mᵢ (x')Q`（吃哪
  个分量由布尔 i 决定）；→ 的情形——书 p.60 (1) 的两种排法，我们取
  第一种：`Cut(⟨a⟩Cut(⟨a'⟩N,(x)M),(y)P)`；
- **名字截**：`Cut⟨a⟩(Ax x a) (y)P → P[a⇒y]`（`renConame` 全程改名）；
- **换位截**：截公式在左项里**不是主公式**时，把截下推进左项的前
  提（`AndiL`/`SImpL` 的前提、截套截的右臂）。

```coq
| SCut CA c (SAndiL i x z M) y P =>
    SAndiL i x z (SCut CA c M y P)      (* 换位：下推进前提 *)
```

于是定理 4 的两个半边都成了机器断言。**换位侧**（引理 3 的伴生事
实：换位截在翻译下是恒等）：

```coq
Example commuting_identity :
  tmEq (trans commCut) (trans (cut1 commCut)) = true.
```

**逻辑侧**（每个逻辑截步对应**零或多步** β）：ND 归约的可到达性用
BFS 成员判定实现——`stepsOf` 枚举一个项的全部一步 β/γ 像（逐位置
：红ex识别+上下文重构），`betaGammaStar target a` 在深度 7 的广度
闭包里找 target：

```coq
Example logical_cut_beta :
  betaGammaStar (trans (cut1 andCut)) (trans andCut) = true.
Example imp_cut_beta :
  andb (tmEq (trans impCut) (app (lam 1 (var 2)) (var 1)))
       (betaGammaStar (trans (cut1 impCut)) (trans impCut))
  = true.
```

→ 侧样本 `impCut` 的翻译恰是 `(λx.var 2) (var 1)`——教科书级的 β
红ex；截消一步后翻译变成 `var 2`，BFS 一步命中。反向（引理 5：每
步 ND β 对应一串截消步、余项 β*-对齐）的样本面：

```coq
Example lemma5_sample :
  andb (tmEq (trans andCut) (fst (pr (var 0) (var 1))))
       (tmEq (trans (cut1 andCut)) (var 0)) = true.
```

## 35.4 对应在哪里断裂：∨ 与显式代入

Zucker 对应的**边界**才是本篇的戏眼。书里给了两处断裂，我们机器化
了第一处（例 8 的教学重构）：

**收缩的代价**。矢列证明里一条 A∨B 经 ∨L 喂给 ∧R 的两个前提（收
缩：同一个公式用两次），截消后翻译到 ND 侧得到「**两个 case 共享
同一个主体**」的项：

```
t1 = ⟨case d of x⇒M | y⇒N ,  case d of z⇒S | w⇒T⟩
```

而 Zucker 式的 ND 正规形应当是**一个 case、两支各自配对**：

```
t2 = case d of x⇒⟨M, S⟩ | y⇒⟨N, T⟩
```

从 t1 到 t2 需要一条「∧I 与 ∨E 换位」的规则。它不在标准 β/γ 之列
——γ 家族（`gFst/gSnd/gApp/gCase`：case 与观察者位置换位）全部是
「case 往外提」，没有一条把**两个同主体 case 合并**。机器抓拍双联
：

```coq
Example break_witness_unreachable : betaGammaStar t2 t1 = false.
Example break_witness_strange_reaches : tmEq (strangeStep t1) t2 = true.
```

第一条：BFS 把 t1 的全部标准一步像枚举干净——**一步都没有**（t1
本身已 γ-正规），t2 不可达。第二条：补上书 p.48 的「怪规则」
`strangeStep`（⟨case P λx.M λy.N, case P λz.S λw.T⟩ → case P
λx.⟨M,S[z/x]⟩ λy.⟨N,T[w/y]⟩）后一步命中。Urban 的评语值得抄进教
程：这条规则从项重写的观点「非常奇怪」——**先破坏 λ 演算的合流，
其次需要先测试两个子项相等才能适用**；但从语义的观点它说得通（它
是范畴语义里某种等价——第 39 章 de Paiva 篇的伏笔）。第二处断裂
（例 7：显式代入演算 λx 里只有一种截归约排法能被匹配）属文献线，
文档不再展开。

**为什么 ∨ 特殊**？∧ 与 → 的左规则消费公式后**不再复制**任何东西
；∨L（和 ∃L）的两个副前提让同一语境被用两次——「收缩」在截消里
的位置与 ND 的「复用」错位，正规化跟不上。这也解释了为什么 von
Plato 的广义消去规则（第 34 章 →ESL）能恢复对应：它把左规则的信息
搬到 ND 的消去规则形状里，两种演算的步子重新对齐——Urban 在本篇
开头正是这么引用的。

## 35.5 本章机器件清单

| 件 | 位置 | 说明 |
|---|---|---|
| ND 项 + β/γ 逐位置枚举 | `tm/subst/betaCtx/gammaCtx` | γ 四型：case 与 fst/snd/app/case 换位 |
| 矢列项 + 自顶向下检查器 | `st/stCheck` | 名字/余名；截公式显式携带 |
| Prawitz 翻译 | `trans` | 六行；Cut↦代入 |
| 截消一步 | `cut1` | 逻辑截（∧/→）+名字截+换位截 |
| BFS 成员判定 | `betaGammaStar` | 定理 4 的「β→*」侧 |
| 断裂现场 | `t1/t2/strangeStep` | 例 8 重构：不可达+怪规则可达 |

## 坑位速记（本章实测）

- **检查器方向**：矢列项检查必须**自顶向下**（后件公式作输入）——
  自底向上时 `SImpR` 的前件类型无从而来（初稿自底向上版整段推倒）。
- **AndiL 要记分量**：`i : bool` 记吃左/右分量；否则逻辑截的重写方
  向（保哪个 AndR 前提）无法决定。
- **case_ 的主体是项不是名**：`case_ (d : tm) (x y : nat) ...`——
  初稿把 d 写成 nat，`subst` 当场类型爆。
- **Coq option 构造子大写**：`Some/None`（Rocq 9.1 Stdlib 命名）。
- **cut1 的分支穷尽性**：左项=SCut 的换位情形漏写会 Non exhaustive；
  左项=SAndR 的换位与逻辑截两个分支**重叠**（Coq 报 redundant）——
  保逻辑截、其余下推。
- **Lean 双洞 lambda**：`(·.pr · v)` 是两参函数（两个 `·` 各吃一
  参），`.map` 里要用单洞 `(.pr · v)`；`n + 1` 递归必须命名 n。
- **BFS 从 t1 立即断气**：t1 无任何标准一步像——「不可达」断言因此
  秒判；这不是偷懒而是现象本身（正规 ND 推导卡死，缺的正是怪规则）。
- **重排侧事故（本轮实测）**：build.ps1 的会话名曾用
  `Substring(0,2)` 截章号——三位章号 105 被截成 ML10，Isabelle 报
  Undefined session；改 `-replace '_.*$',''` 修复。

## 小结

Zucker 对应说：在 {∧,→} 里，截消与正规化是同一件事的两种记法。
Urban 用名字/余名项语言把两边都变成重写系统，对应定理坍缩成「翻译
与归约可交换」的逐语句核对。断裂点同样精确：∨（与 ∃）的左规则携
带收缩，ND 侧没有标准的合并规则，对应在「两个同主体 case」处卡
死——而补出来的规则要付出破坏合流的代价。本章把这整条叙事装进了
七百行可执行代码：翻译、归约、断裂，全部可复算。

---
上一章：[34 广义消去规则与高层次规则](docs/34-ge.md) · 下一章：[36 标号演绎与相等](docs/36-lndequality.md)
