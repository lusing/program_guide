# 36 操作语义：NB 语言、推导归纳与安全性三幕

> 对应读本：皮尔斯《类型和程序设计语言》（TAPL）第 3 章
> （无类型算术表达式）、第 4 章（ML 实现）、第 8 章（类型算术
> 表达式）。代码：`examples/36_opsem/`——Coq 件 `ex36_opsem.v`
> （NB 的完整元理论：小步 9 规则、确定性、stepf 实现机与反射、
> 终止性、类型 8 规则、典型形式、progress + preservation =
> safety）、Prolog 件 `ex36_opsem.pl`（三台机器：小步/大步/
> 类型，加五层内全枚举的穷举见证）。

类型论的工程一侧从这里开始：一个语言先有**语法**（哪些字符串
是程序）、再有**语义**（程序如何运转）、最后有**类型**（哪些
程序被放行）。TAPL 用一个只有布尔和自然数的小语言 NB 把这三步
走到头——它平凡到每条规则都能一眼看穿，却完整承载了类型安全
证明的全部机器。本章按书走这三幕，全部定义在两个机器件里兑现。

## 36.1 语法：同一个集合的四种说法（书 3.2）

NB 的项：

```text
t ::= true | false | if t then t else t | 0 | succ t | pred t | iszero t
```

书 3.2 的教学重心是：**归纳定义不是一种，是三种等价说法**——
(3.2.1) 最小集合式、(3.2.2) 推导规则式、(3.2.3) 逐层构造式
（S₀ = ∅，Sᵢ₊₁ = 常量 + 一层算子/条件）。命题 3.2.6 证明三
者同集。Coq 件里这三种说法**天然塌缩成一种**：

```coq
Inductive tm : Type :=
| ttrue  : tm | tfalse : tm
| tif    : tm -> tm -> tm -> tm
| tzero  : tm | tsucc : tm -> tm
| tpred  : tm -> tm | tiszero : tm -> tm.
```

`Inductive` 一次给出全部三件事：构造子（Sᵢ 式的「一层」）、
消去原理（推导规则式的「最小性」）、以及结构归纳原理——书里
要手证 T = S 的那页纸，在 Coq 里是类型系统的白送品。

## 36.2 对项的归纳（书 3.3）

定理 3.3.4 给出三个可互推的归纳原理：对**深度**、对**长度**、
**结构**归纳。本章的元定理全部用结构归纳（Coq 的 `induction`
原生就是它）。第一个练手的引理（3.3.3：项的不同常量数 ≤ 长度）
是纯热身；真正反复出场的是它的两个后代：

- **值不求值**（3.5.7 的方向一）：`value_no_step`——值是范式；
- **数值同理**：`nv_no_step`——`nv` 归纳一层，`succ` 头上的
  步进被 `E_Succ` 的前提逼死。

这两个小引理是后面一切「矛盾分支」的弹药（见 36.9 的坑位②）。

## 36.3 小步语义：九条规则（书 3.5）

求值关系 `t → t′` 由图 3.1（布尔）+ 图 3.2（算术）的九条
规则定义。Prolog 件是它的**逐条对译**——九个事实/规则，一行
一条：

```prolog
step(if(true,  T2, _), T2).                     % E-IfTrue
step(if(false, _, T3), T3).                     % E-IfFalse
step(if(T1, T2, T3), if(T1p, T2, T3)) :- step(T1, T1p).
step(succ(T), succ(Tp))    :- step(T, Tp).      % E-Succ
step(pred(zero), zero).                         % E-PredZero
step(pred(succ(V)), V)     :- nv(V).            % E-PredSucc
...
```

规则分两类（书 3.5 的命名）：**计算规则**（E-IfTrue/IfFalse、
E-PredZero/PredSucc、E-IsZeroZero/Succ——真正干活）与**同余
规则**（E-If、E-Succ、E-Pred、E-IsZero——只决定「在哪里干」）。
注意 `nv` 这个语法范畴的精妙：E-PredSucc 的左端是
`pred (succ nv)` 而**不是** `pred (succ t)`——`pred (succ
(pred 0))` 不能一步跳到 `pred 0`（`pred 0` 不是数值），它必须
先走里面的 `pred 0 → 0`。Coq 件里 `nv` 与 `value` 是两个
**归纳谓词**（`Prop`），与项的语法分层——这正是书里「语法
范畴」的正式化。

多步 `→*`（3.5.9）是自反传递闭包；**受阻**（3.5.15）是
「范式但不是值」：

```coq
Definition stuck (t : tm) : Prop := normal_form t /\ ~ value t.
```

`succ true` 受阻：`true` 无处可走（E-Succ 走不动）、`succ true`
不是值。**受阻 = 运行时错误的数学化**——类型系统的整个目标
就是把它挡在求值之前。

## 36.4 确定性与终止性（书 3.5.4/3.5.12）

**确定性**（一步至多一个去处）：书 3.5.4 对推导做归纳，十个
情形逐个排查「两条规则同时匹配」的可能。Coq 件的打法更工程：
先造好**实现机**再反射（下节），确定性退化为一行 `congruence`。
Prolog 侧则用穷举：五层内全部 714 个项，每个的 `findall` 出的
去处数 ≤ 1。

**终止性**（3.5.12）：每步 `size` 严格下降，良基序阻止无限
链——这是本书第一次出现「终止度量函数」，第 12 章规范化证明
（07 章深化）是它的豪华版。Coq 件 `step_size` 对九条规则归纳
后全部 `lia` 收尾；终止定理用「size 界 + stepf」的构造性归纳
（避免排中）。

## 36.5 ch.4 的 ML 实现：stepf 求值机

书第 4 章把语义写成 OCaml 程序。我们的对应物是 `stepf`：

```coq
Fixpoint stepf (t : tm) : option tm := ...   (* 一步：Some t' 或 None *)
```

`option` 的 `None` 读作「无处可走」。**反射两半**把它与规则
关系焊死：

```coq
Lemma stepf_complete : forall t u, step t u -> stepf t = Some u.
Lemma stepf_sound   : forall t t', stepf t = Some t' -> step t t'.
```

完备半（规则→机器）对求值推导归纳，每条规则直算 `stepf`；
关键辅引理 `step_not_value`（会步进的项不是值）负责拆掉
`if is_value t1 then None else …` 的岔路。可靠半（机器→规则）
对项归纳，每种子项形状落到对应的 E-规则。有了这两半：

- 确定性：`step t a` 和 `step t b` 都被完备半映到
  `stepf t = Some a / Some b`——`a = b`；
- `stepf = None` 恰是范式；
- 终止性可以完全构造性地走 `stepf`。

**这是「实现 + 反射 = 元定理」的方法论**：与其在规则关系上
做十个情形的归纳，不如先实现、再证忠实——书 ch.3（理论）与
ch.4（实现）的分章在机器面合流成一体两面。

## 36.6 大步语义（练习 3.5.17）

同一语言还有第二种操作语义：**大步**（自然语义，Kahn 1987）
直接给 `t ⇓ v`：

```prolog
evalv(V, V) :- value(V).                        % B-Value
evalv(if(T1, T2, _), V) :- evalv(T1, true), evalv(T2, V).
...
```

练习 3.5.17 要求证小步与大步一致（`t →* v` 当且仅当 `t ⇓ v`，
v 是值）。Prolog 件把它做成**穷举见证**：五层内全部项上两个
方向都核过。三种语义风格（操作/指称/公理，书 3.4 的三段史话）
里 TAPL 只走操作语义——指称语义的域论与公理语义的 Hoare 逻辑
不在本书疆域（书 3.6 的注释与前言的取舍声明）。

## 36.7 类型登场（书 8.1–8.2）

两个类型、八条规则：

```coq
Inductive has_ty : tm -> ty -> Prop :=
| T_True   : has_ty ttrue TBool
| T_If     : forall t1 t2 t3 T, has_ty t1 TBool ->
    has_ty t2 T -> has_ty t3 T -> has_ty (tif t1 t2 t3) T
| T_Succ   : forall t, has_ty t TNat -> has_ty (tsucc t) TNat
...
```

NB 无变量，所以没有上下文——第 9 章的 λ→ 才引入 Γ（04 章
已走过）。类型检查是**保守的**（8.1 的关键句）：`if true
then 0 else false` 求值安全但不可类型化——静态信息不够时
宁可错杀。这一句的机器见证在 Prolog 件⑥：

```prolog
check("保守性：if true then 0 else false 可求值但无类型",
       ( steps(if(true, zero, false), zero),
         \+ typeof(if(true, zero, false), _) ))
```

## 36.8 安全性 = 进展 + 保持（书 8.3）

类型安全的正典两幕，Coq 件全证：

> **进展**（8.3.2）：良类型项要么是值，要么能走一步。
> **保持**（8.3.3）：良类型项走一步后仍良型（且同型）。

进展的证明结构（对类型推导归纳）里藏着一个必背引理——
**典型形式**（8.3.1）：Bool 类型的值只能是 true/false、Nat
类型的值必是数值。没有它，「条件是值」推不出「条件可判」。
保持对求值推导归纳，每个 E-规则配 T-规则的逆。两幕合并：

```coq
Corollary safety : forall t T t',
  has_ty t T -> multi t t' -> ~ stuck t'.
```

——良类型项沿求值链**永远到不了受阻状态**。Prolog 侧的对应
是穷举：85 个良类型小项的全部求值中间态，逐个核「不受阻 +
类型不变」。注意 Coq 的 `safety` 用的是 `multi` 归纳版保持
（`multi_preservation`）——书 8.3.4 练习让读者重构证明方向，
这里选了「对多步归纳」的路线（对类型推导归纳的原始版本在同
文件的 `preservation` 里）。

## 36.9 机器面导读

Coq 件（约 550 行）六段：语法与值 → 九条小步规则 →
nv/value 不走步两引理 → 多步/受阻 → 确定性（显式十情形
归纳——沿用书 3.5.4 的原始证明路线）→ stepf 机与反射三引理
→ 终止性 → 类型与典型形式 → 进展/保持/安全性 → 边界两例。
Prolog 件（约 160 行）三台机器 + 六组见证。

> **坑位速记**
> ① Coq `induction H` 的 `as` 模式必须**列全构造子数**（step
>   十条规则十个分支——漏写一个就「Wrong bullet」错位连环爆）；
> ② `eapply nv_no_step; eauto` 这类「共享 evar 的双子目标」会
>   先提交错解再卡死——**显式钉住实例**（`eapply (nv_no_step
>   (tsucc x) (nv_succ x …))`）或直接构造完整证明项最稳；
> ③ `congruence` 不解含 evar 的目标；要 `exists` 出**具体
>   项**再 `apply`（`eexists` + `assumption` 是常见假动作）；
> ④ `destruct … eqn:E` 之后假设里的 `if is_value t` **不会自动
>   归约**——`rewrite E in H; simpl in H` 的两连招是纪律；
> ⑤ `simpl in H` 会把 `stepf（复合项）` 整个展开、把待 rewrite
>   的子项展开不见——**remember 先抽象、再 simpl**（36.5 的
>   反射证明全靠这条纪律）；
> ⑥ `discriminate` 遇到未归约的 `if true then None else …`
>   报「No primitive equality found」且 `try` 接不住——先
>   `simpl` 再判；
> ⑦ `constructor` 只装**一层**构造子：`value tzero` 要
>   `constructor; constructor`（v_nv + nv_zero 两层）；
> ⑧ `inversion` 自动生成的假设名（H2/H4）不稳定——用
>   `match goal with h : has_ty ttrue _ |- _ => inversion h end`
>   按形状抓；
> ⑨ Prolog `between(1, N-3, K)` 不做算术——先 `K0 is N - 3`
>   再 `between(1, K0, K)`；
> ⑩ Prolog 注释列表用 `[l=T|…]` 的 **= 对**（`[(l, T)]` 的
>   逗号对与 `member(L=T, …)` 的等号项不同构——37 章实测）。

## 36.10 与本书其他线的接口

- 04 章（λ→ 的 progress）是本章的安全性的函数版延伸——那里
  有了上下文 Γ 与代换，这里 NB 无变量、全部机械裸露；
- 07/12 章（规范化）接 3.5.12 的终止度量传统——NB 的 size
  度量是 Tait 方法的第零版；
- 48→69 章（元理论）的「语义即关系 vs 语义即函数」之辨在本章
  stepf 的反射两半里提前彩排；
- Prolog 通道在此后的 TAPL 线（37–46 章）承担「ML 实现章」
  的全部对应物——规则即程序，穷举即验证。

## 36.11 章末地图（书 ch.3/4/8 习题选）

- **练习 3.5.13**（E-Funny1/2）：往规则集里塞坏规则，哪些
  定理幸存——Prolog 侧改一行 `step` 即可实验（机器件未收录，
  留作读者改装位）；
- **练习 3.5.16**（wrong 项）：受阻版 vs wrong 版语义的等价
  形式化——「难点在陈述不在证明」的著名教学点；
- **练习 8.3.6**（主体扩张反例）：`t → t′` 且 `t′ : T` 推不出
  `t : T`——保守性的另一半；
- **练习 8.3.7/8.3.8**（大步版/wrong 版的安全性陈述）：
  安全性定义对语义形态的依赖——与 36.6 的一致性机器件互证。

---

上一章：[35 提取与运行](35-extraction.md) · 下一章：[37 简单扩展](37-extensions.md)
