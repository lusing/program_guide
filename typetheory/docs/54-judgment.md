# 54 判断语义与事件语义：命题化与依赖事件

> 对应读本：罗朝晖书 4.3（判断语义的命题形式）、4.4（依赖
> 类型在事件语义学中的应用）；5.3.4（Coq 实现）。代码：
> `examples/54_judgment/ex54_judgment.v`（自造 JMeq + NOT
> 定义 + 定律 A1/A2 机器证明、生成过剩警示、依赖事件类型
> 强制菱形与合谐条件、EQP 错误语义 Fail 见证、带论域事件
> 类型、War and Peace 事件强迫完整版）。

本章两个收官课题，各带一个「悖论式」的难题：**判断**不是
命题却要参与命题组合（「张三**不是**张桌子」怎么说？）；
**事件**解决了副词修饰却让量词辖域失控（「没有人讲话」的
错误读法居然是合法公式）。两个难题的解法殊途同归——都是
给类型论**加结构**而不是换逻辑。

## 54.1 判断语义：不能否定的东西（书 4.3.1）

MTT 语义学里句子可以解释为**判断**：「张三是个人」=
`zhang : Human`（50 章）。判断语义的好处（类型检测可判、
无意义=不可导出）之前都见过；现在它的账单来了——

> 判断**不是命题**：不能否定（`¬(zhang:Table)` 不是合法
> 表达式，式 4.42 ✗）、不能与命题合取（式 4.37 ✗）、
> 也不能在元理论里否定完事（式 4.43 只是元语言句子）。

但「张三不是张桌子」（式 4.40）是句正经话！药方分两路：

- **正确判断** a:A 的命题形式：常真谓词 `P_A(a)`（式 4.38）
  ——其合法性**预设** a:A 可导出（PA 是预售票，检票在元层）；
- **错误判断/类型不配**的命题形式：IS/DO 算子（下节）。

## 54.2 NOT/IS/DO 与异类等式 JMeq（书 4.3.2）

三算子由一个 NOT 定义（式 4.53–4.56）：

```coq
Definition NOT (A : Type) (p : A -> Prop) (B : Type) (b : B) : Prop :=
  forall x : A, JMeq x b -> ~ p x.
Definition is (A B : Type) (b : B) : Prop := NOT A (fun _ => True) B b.
Definition do (A B : Type) (p : A -> Prop) (b : B) : Prop := NOT A p B b.
```

`NOT(A,p,B,b)` 读「b 不做 p」；特例 p=P_A 时 is(A,b) 读
「b 是 A」。do 让「桌子不会讲话」（talk 论域 Human、t 论域
Table，式 4.48 非法）命题化：

```coq
Definition tables_dont_talk : Prop :=
  forall t : Table54, ~ do Human54 Table54 talk54 t.
```

关键角色是 **JMeq**（McBride 异类等式）——`JMeq x b` 说
**不同类型**的对象 x:A 与 b:B 相等。普通 eq:A→A→Prop 装不下
跨类型等式；JMeq 把它做成命题（Coq 8.20 预加载库里没有，
自造三行）：

```coq
Inductive JMeq {A : Type} (a : A) : forall {B : Type}, B -> Prop :=
| JMeq_refl : JMeq a a.
```

NOT 用它说「对任何 x:A，若 x 异类等于 b，则 x 不满足 p」
——把「b（类型不对）不做 p」化成全称。**定理 4.2**（NOT
由 JMeq 引入是相容的）的机器选段——定律 A1/A2：

```coq
Lemma law_A1 : forall (A : Type) (p : A -> Prop) (x : A),
  p x -> ~ NOT A p A x.
Proof. intros A p x Hpx HN. apply (HN x).
  - exact (JMeq_refl x).  - exact Hpx.  Qed.

Lemma law_A2 : forall (A B : Type) (p q : A -> Prop),
  (forall x : A, p x -> q x) ->
  forall b : B, do A B q b -> do A B p b.
Proof.
  intros A B p q Himp b Hq x Hjm Hpx.
  apply (Hq x Hjm). apply Himp. exact Hpx.  Qed.
```

A1：「做 p 则不 NOT p」（同一型内的对偶）；A2：「p⊆q ⟹
不会 q ⟹ 不会 p」——「桌子不会讲话 ⟹ 不会大声讲话」（书
例 (2)）。相容性的证明策略（书 4.3.2 末）值得记：不去硬证
元定理，而是**在相容扩张 T+JMeq 里定义 NOT 再证定律**——
「间接证明」的类型论版（与 17 章相对一致性证明同一家法）。

**生成过剩的防线**（书 4.3.3）：IS/DO 不能无限用——
「张三是一张桌子」不能给 is(Table, zhang)。机器件给出诚实
的警示：

```coq
Definition over_gen : Prop := is Table54 Human54 zhang54.
(* 形式上**合法**！is 的 A、B 是独立参数 *)
```

防线不在类型检查而在**语境纪律**：类型不相交（必要条件）
+ 否定性语境（定义 4.7：IS/DO 表达式经 ∧∨∀∃ 传播后仍须
待在否定/条件的管制下）。「女人不是男人」（式 4.63）合法、
裸的「张三是桌子」（式 4.57）不合法——语义学的自我约束
条款。

## 54.3 事件语义：Davidson 的账（书 4.4.1）

副词修饰的难题：「约翰在厨房里用餐刀给烤面包片抹黄油」
（式 4.68）应**蕴涵**「约翰给烤面包片抹黄油」（式 4.67）。
蒙太古里副词是谓词变形 `(e→t)→(e→t)`，蕴涵要靠意义公设
（with_knife(p,x)⇒p(x) 等）——又是无奈之举。Davidson 1967
的方案：行为动词**附带存在量化的事件变量**，副词全改成
事件谓词：

> ∃v:Event. butter(v) ∧ agent(v)=j ∧ patient(v)=toast
> ∧ with_knife(v) ∧ in_kitchen(v)　（式 4.72）

蕴涵变成合取删项——意义公设退场（新戴维森式：agent/
patient 题元角色函数，Event→e）。

但新问题立刻到账——**事件量化问题 EQP**：「没有人讲话」
（式 4.73）的正确语义（4.74）之外，量词搬家的版本（4.75）
也是**合法公式**——形式上无法排除：

> (4.75 ✗) ∃v:Event. ¬∃x:e. human(x) ∧ talk(v) ∧ agent(v)=x

## 54.4 依赖事件类型：辖域焊死（书 4.4.2–4.4.3）

书与 Soloviev 的方案：把事件类型**按题元角色参数化**——

> Evt_A(a)：施事为 a 的事件；Evt_P(p)：受事为 p 的事件；
> Evt_AP(a,p)：施事 a 受事 p 的事件
> 子类型菱形（图 4.4）：Evt_AP(a,p) ≤ Evt_A(a) ≤ Event 等

机器件直译（图 4.5 的强制版）：

```coq
Axiom c1 : forall a p, Evt_AP a p -> Evt_A a.
Axiom c3 : forall a, Evt_A a -> Event54.
Coercion c1 : Evt_AP >-> Evt_A.
Coercion c3 : Evt_A >-> Event54.
Axiom diamond_coherent : forall a p (v : Evt_AP a p),
  c3 a (c1 a p v) = c4 p (c2 a p v).
```

注意**合谐条件**（书 121 页）：菱形两条路到 Event 必须
相等——c3∘c1 = c4∘c2，否则同一事件经两条路得到两个不同
的 Event 映像（48 章合谐性的依赖版）。

**EQP 的解决**干净利落：正确语义用 `∃v:Evt_A(x).talk(v)`
（x 绑定在内）；错误语义想搬 ∃v 出去——但 `Evt_A(x)` 的
**类型本身含 x**，x 出辖域类型就没了着落：

```coq
Definition intended_sem : Prop :=
  ~ exists (x : Human54) (v : Evt_A x), talk_ev v.   (* 合法 *)
Fail Definition incorrect_sem : Prop :=
  exists v : Evt_A x, ~ exists x : Human54, talk_ev v.
(*                        ^ x 未绑定——非法！ *)
```

**依赖类型把量词辖域焊死在类型里**——搬家即非法，无需
任何非形式规定。这是「表达式非法性」第二次当语义学的
法官（第一次是 50 章选择限制）。书还证了保守扩张（定理
4.3/4.4：Cₑ 与 Tₑ[E] 都是原理论的保守扩张）——图 4.4 的
子类型按 48 章强制式落地，元理论无损。

## 54.5 选择限制的回归与带论域事件类型（书 4.4.3 末）

引入事件后一个意外回归：「桌子会讲话」的事件版（Table≤Agent
时，式 4.93）**居然合法**——∀t:Table.∃v:Evt_A(t).talk(v)
过了类型检查（50 章辛苦建立的防线被事件绕后门攻破）。
解药：**带论域的依赖事件类型** Evt_A[D](d)——参数 d 的类型
限在 D ≤ Agent：

```coq
Definition Evt_H (h : Human54) : Type := Evt_A h.
Fail Definition illegal_sem2 : Prop :=
  forall t : Table54, exists v : Evt_H t, talk_ev v.
(*                              ^ t:Table 喂不进 Human 位 *)
```

论域参数 Human 来自动词的**原始语义**（talk 引入事件前是
Human→Prop）——「事件的类型记得动词的论域」，防线重修。

**War and Peace 全景**（书 5.3.4 I，50 章 enjoy 的完整版）：

> Julie just started War and Peace, which Tolstoy finished
> after many years…（式 3.56）

read/write 的强制 c(h,b) 按「h 是否为 b 的作者**选边**」
（依赖性强制！）：j 不是 W&P 作者 → c(j,b)=read(j,b)。
机器件：`Coercion cj : Book54 >-> Evt_A`（cj := read54 j54），
start/finish/last 论域 Evt_A(h)——一句 start j WP 里 W&P
被强制成 read(j,WP)（Set Printing Coercions 可见展开，
式 3.60）。事件强迫+依赖事件类型+强制子类型三合一——
MTT 语义学的火力顶点。

## 54.6 一页总结（本章的三个公式）

> 判断不是命题——NOT/IS/DO 由异类等式 JMeq 定义命题化
> （定律 A1/A2 机器可证；相容性走「T+JMeq 里定义」的
> 间接证明）。
> 依赖事件类型：Evt_A(x) 把量词辖域焊进类型——EQP 的错误
> 语义因 x 出辖域而**非法**；强制菱形须合谐（c3∘c1=c4∘c2）。
> 事件绕后门攻破选择限制 → 带论域事件类型 Evt_A[D](d)
> 重修防线——「事件的类型记得动词的论域」。

> **坑位速记**
> ① JMeq 在 Coq 8.20 预加载库**不存在**——自造三行
>   （Inductive JMeq {A} (a:A) : forall {B}, B -> Prop）；
>   隐式参数 A/B 别写成显式，否则 NOT 里 JMeq x b 对不上；
> ② 自造件必须**声明在使用前**——Definition NOT 引用
>   JMeq 时它还没出生（本批实测：引用先于声明静默失败
>   到第二次编译才暴露）；
> ③ `Fail Definition` 要求失败**真的发生**——is 的 A/B 是
>   独立参数，is(Table, zhang) 类型上**合法**（生成过剩
>   是语义学纪律问题不是类型问题）——别拿 Fail 见证
>   不存在的失败（The command has not failed!）；
> ④ 双参数强制的 Coercion 注册（c2 : Evt_AP a p → Evt_P p
>   目标依赖参数）Coq 支持有限——以 Axiom 承载、合谐条件
>   单独 Axiom 化是书的 5.3.4 原代码同款处理；
> ⑤ Python 批量替换的 replace 无匹配时**静默跳过**——
>   移动代码块后必须 grep 验证落位（本批 JMeq 块「插入
>   成功」假象）。

## 54.7 与本书其他线的接口

- 17 章相对一致性——NOT 相容性的「间接证明」家法；
- 48 章合谐性——依赖版（菱形对角相等）在此；
- 50 章选择限制、事件强迫 enjoy——本章是其完整依赖版；
- 29 章相等与 J——JMeq 是 J 的「跨类型表亲」，57 章路径
  的 hetero 版将再见；
- 55 章（下一章）范畴语法——语法-语义接口的第三条战线；
- 69 章元理论——保守扩张定理 4.3/4.4 的证明技术在 56 章
  LF 形式化里补全。

## 54.8 章末地图（书 4.3–4.4 要点选）

- **定义 4.7（否定性语境）**——五条归纳定义，IS/DO 的
  使用执照；
- **McBride 的 JMeq 原文**（[159][160]）——异类等式的
  构造性威力（54 章 Coq 版只是它的一面）；
- **Davidson 1967 / Parsons 1990**——事件语义学两代文献；
  Landman 的辖域论域原则与 Champollion 的事件集合是 EQP
  的另两派解；
- **书 4.6 后记**——「事件的概念至今带有神秘色彩」——
  依赖事件类型是探索而非定论。

---

上一章：[53 标记与点类型](53-signatures.md) · 下一章：[55 范畴语法](55-categorial.md)
