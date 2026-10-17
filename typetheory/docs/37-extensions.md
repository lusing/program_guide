# 37 简单扩展：从单位类型到列表的目录学

> 对应读本：TAPL 书第 11 章（简单扩展）。代码：
> `examples/37_extensions/`——Prolog 件 `ex37_extensions.pl`
> （fullsimple 的浓缩版：Unit/序列/归属/let/序对/记录/变式
> /case/fix 的类型机 + 按值调用求值机 + 导出形式见证）、
> Coq 件 `ex37_extensions.v`（导出形式的方法学：seq 的化简
> 与外部规则的推导；fix 的发散；变式/数据类型的元语言化身）。

λ→ 本体小得可怜——真实的语言有积、和、记录、变式、递归、
列表。本章是 TAPL 的「目录学」：**十二种语言特征如何一个个
装进简单类型系统，且每装一个，安全性定理就要重新验一遍**。
更重要的是书里反复使用的方法学——**导出形式**（derived
form）：很多「新特征」根本不用动内核，它们是既有构造子的
缩写。这条路线后来成为标准 ML 定义与 Scheme RnRS 的正式方法。

## 37.1 基本类型与单位类型（书 11.1–11.2）

**基本类型**（Bool/Nat/String/Float，乃至无解释的原子类型 A）
只是往类型语法里加叶子。真正有内容的是 **Unit**：只有一个
元素 `unit` 的类型。它看似最无聊，实际是**副作用语言的通用
返回类型**（赋值表达式的类型）——C/Java 的 `void` 语义上是
Unit 而不是空类型（书 11.2 的辨析：名字像 Bot，用法像 Unit）。

```prolog
typeof(unit, _, unitt).                         % T-Unit
```

## 37.2 导出形式：序列与通配符（书 11.3）

**序列** `t1; t2`（求值 t1、扔掉结果、继续 t2）有两种形式化：

- **成熟构造子**：加语法 `t1;t2` + 规则 E-Seq/E-SeqNext/T-Seq；
- **导出形式**：定义为 `(λx:Unit. t2) t1`（x 新鲜）。

定理 11.3.1 说两者在类型与求值上严格对应——**表面语法扩了、
内部语言没动、安全性定理不用重证**。这就是「导出形式」的价值
（Landin 的旧名「语法装饰」；反向展开叫「化简」）。Algol 60
报告与 SML 定义都用这招。机器件双向立据：

```prolog
desugar(seq(M, N), ap(lm(unitt, N), M)).        % 化简器
typeof(seq(M, N), G, T2) :-                     % 外部规则 T-Seq
    typeof(M, G, unitt), typeof(N, G, T2).
step(seq(unit, N), N).                          % E-SeqNext
```

Prolog 侧外部规则与化简式**并排装载**，检定两者给同一类型、
同一值。Coq 侧则把「外部规则是内部规则的定理」走到底：

```coq
Definition seqc (t1 t2 : tm) : tm := app (abs TUnit t2) t1.

Lemma E_Seq_derived : forall t1 t1' t2,
  step t1 t1' -> step (seqc t1 t2) (seqc t1' t2).
Proof. intros. unfold seqc. apply E_App2; [constructor | assumption]. Qed.
```

E-Seq 是 E-App2 的直译。E-SeqNext（`v; t2 → t2`）是
E-AppAbs 的特例——但 de Bruijn 下有个诚实的技术点：named
演算里 `[x↦v]t2 = t2` 只要 x 不自由；de Bruijn 的 β-代换
还会给高位变量**减位**，字面等式只在 t2 无自由变量时成立
（Coq 件以闭项样本立据，一般引理需要「全部自由变量低于绑定
位」的新鲜性——69 章元理论的属地）。**通配符** `λ_:S.t` 是
另一个导出形式：哑绑定的缩写。

## 37.3 归属与 let（书 11.4–11.5）

**归属** `t as T`：文档化地声明类型，求值时丢掉。类型规则
T-Ascribe 就是「验证 T 确实是 t 的类型」；用途从可读性到
控制类型打印。**let 绑定** `let x = t1 in t2` 是本章的转折点：
求值行为可导出（`(λx:T1.t2) t1`），但**类型行为不能**——
化简式需要 `λx:T1` 的注释 T1，而它来自**类型检查器对 t1 的
计算**。书里的结论值得整段记住：let 不是「项的导出形式」，
而是「**推导的导出形式**」（把含 T-Let 的推导翻译成含
T-Abs/T-App 的推导）。第 42 章（类型重构）将给出第二个理由：
HM 语言的 let 有**值多态**，λ-抽象给不了。

```prolog
step(letin(V, B), R) :- isvalue(V), subst(B, 0, V, R).   % E-LetV
typeof(letin(M, B), G, T2) :-
    typeof(M, G, T1), typeof(B, [T1|G], T2).              % T-Let
```

## 37.4 序对、元组、记录（书 11.6–11.8）

乘积类型 T₁×T₂ 的引入/消去对（T-Pair/T-Proj₁₂、
E-PairBeta₁₂）是第一个「数据」构造。**元组**推广到 n 元，
**记录**再把数字下标换成标签：

```prolog
typeof(rcd(Fs), G, rcdt(Ts)) :-
    maplist([L=E, L=T]>>typeof(E, G, T), Fs, Ts).
typeof(prj(E, L), G, T) :-
    typeof(E, G, rcdt(Ts)), member(L=T, Ts).     % T-Proj 查表
```

两个纪律性细节：(1) **求值次序由元变量编码**——规则里
`{v₁, t₂} → {v₁, t₂′}` 的 v₁/t₂ 位置写法强制「从左到右、
按值调用」（Prolog 件的 E-Pair1/E-Pair2 与 E-Rcd 的
`step_first_field` 就是这条纪律的程序形态）；(2) **标签次序
本章有意义**（{a:Nat,b:Bool} ≠ {b:Bool,a:Nat}）——39 章子
类型将放开它（宽度/置换子类型），那时「无序记录」的取舍会
再次出场（书 11.8 末的预告）。

## 37.5 和与变式（书 11.9–11.10）

**和类型** T₁+T₂ 的元素带左右标记（inl/inr），case 消去。
标记的**类型不唯一**（`inl 5 : Nat+Nat` 与 `inl 5 : Nat+Bool`
都成立）打破了类型的惟一性——书给出三条出路：猜（42 章类型
重构）、放宽（39 章子类型）、**注释**（`inl t as T`——本章
采取的方案，注释「背」在其他语法上可以做到近乎隐形）。
**变式** `<lᵢ:Tᵢ>` 是带标签的和（乘积→记录的同一个推广）：

```prolog
typeof(tga(L, E, Ts), G, vart(Ts)) :-           % 带注释变式
    member(L=T, Ts), typeof(E, G, T).
step(case(tga(L, V, _), X, B1, _, _), R) :-
    isvalue(V), L = X, subst(B1, 0, V, R).      % E-CaseVariant
```

变式的三个习惯用法（书 11.10 的精品段落）：**选项**
（`<none:Unit, some:Nat>`——C/Java 的 null 是「伪装的选项」：
引用类型的真身是 `Ref(Option T)`）、**枚举**（全 Unit 字段
的变式）、**单字段变式**（币种例：Dollar/Euro 各自包装 Float，
双重转换在类型层写不出——Coq 件用 `Fail Check` 给出「编译
错误」的机器见证）。

书 11.10 的对照表「变式 vs OCaml datatype」是本章的哲学高点：
datatype = 变式 + **递归** + **参数化**——后两样在本指南的
类型论主线里早已是原生品：递归即归纳类型（30 章），参数化
即类型算子（45 章）。Coq 件的丙段正面演示这个重逢：

```coq
Inductive natlist : Type :=
| nnil  : natlist | ncons : nat -> natlist -> natlist.
```

——书里用变式编码写的 `type NatList = nil | cons of Nat * NatList`，
在 Coq/Agda/Lean 里就是一行 `Inductive`。

## 37.6 一般递归（书 11.11）

λ→ 是强规范化的（07 章）——**fix 在里面定义不出来**，只能
作为新原语加入（图 11.12）：

```coq
| E_FixBeta : forall A b,
    step (fixp (abs A b)) (subst b 0 (fixp (abs A b)))
| T_Fix : forall G f A, has_ty G f (TArr A A) -> has_ty G (fixp f) A
```

T-Fix 的类型不限于函数类型——任何 T 都可取 `T→T` 的不动点，
这允许**互递归函数的记录**（iseven/isodd 打包成记录再整体取
不动点——书 11.11 的优雅例）。代价立即到账：**每个类型都有
无定义元素**——`diverger = λ_:Unit. fix (λx:T.x)`：

```coq
Definition diverger := abs TUnit (fixp (abs TUnit (var 0))).
Definition diverging := app diverger tt.

Lemma diverge_seq_steps : forall k,
  step (diverge_seq k) (diverge_seq (S k)).
```

求值序列 `diverging → loop → loop → …` 每步都是 E-FixBeta 的
原地展开——Coq 件用显式无限序列见证非终止（07 章 SN 讨论的
对照面：**加了 fix，SN 死了，progress/preservation 幸存**——
安全性不承诺终止）。**letrec** 是 fix 的导出形式（书 11.11
末）。带 Nat 与 fix 的 λ→ 有专名 **PCF**（Plotkin 1977）——
程序语言语义学的实验小白鼠。

## 37.7 列表（书 11.12）

`List T` 的五件套（nil/cons/head/tail/isnil）与 ML 相同，
注意 head/tail **只在非空列表上有定义**——良类型但受阻的
`head [T] nil` 是安全性框架允许的「受控部分性」（预演 38 章
引用与异常的主题：错误处理的类型论谱系从「装没看见」到
「类型里记账」）。练习 11.12.1 要求全证进展/保持——38 章的
Coq 件把整套机械在带状态的语言里重演，此处不重复。

## 37.8 一页总结（本章的三个公式）

> 导出形式 = 表面语法扩容、内核不动：t1;t2 ≡ (λx:Unit.t2) t1。
> let = 推导的导出形式：类型注释来自检查器，HM 多态另有内情（42 章）。
> fix = 买终止换表达力：diverger 见证每类型有无定义元素，
> progress/preservation 不受影响。

> **坑位速记**
> ① Prolog 注释/记录字段表统一用 `L=T` 的 **等号对**——写成
>   `(L, T)` 逗号对与 `member(L=T, …)` 不同构（37 章实测）；
> ② `between(1, N-3, K)` 的第二参**不求值**——先 `K0 is N - 3`；
> ③ 外部语言（seq/wildcard 直接规则）与内部语言（desugar 后）
>   双轨并载时，`typeof` 两套子句都要写，检定两轨一致——
>   这就是定理 11.3.1 的机器形态；
> ④ Coq `Fail Check` 是「编译错误」的合法机器见证（断言某项
>   **不可** elaboration）；
> ⑤ de Bruijn 的 β-代换带减位：named 演算的 `[x↦v]t = t`
>   （x 新鲜）在 de Bruijn 只对**闭项**字面成立——导出形式
>   引理要么加「自由变量全低于绑定位」条件（69 章属地），
>   要么像本件以闭项样本立据；
> ⑥ Coq `>?` 记号不存在（只有 `<?` `<=?` `=?`）——`k > j`
>   写成 `j <? k`；
> ⑦ Coq `/* */` 不是注释（C 惯性手滑）——一律 `(* *)`。

## 37.9 与本书其他线的接口

- 36 章的安全性机械在本章每加一个特征都「免费继承」——前提
  是导出形式路线；成熟构造子路线每步要重证（书的方法学即
  此取舍）；
- 04 章三路线的检查器、05 章的 Curry 指派与 42 章（类型重构）
  共享 let 的多态难题——05 章的已知边界「无 let-多态」在
  42 章正面解决；
- 30 章（归纳族）与本章 37.5 的重逢：变式+递归+参数化 =
  归纳类型——程序语言视角与类型论视角在同一物上会师；
- 07 章（规范化）与 37.6 的对照：fix 一入、SN 即死——
  「表达力 vs 终止」的第一笔账，45 章 Fω 的强规范化是第二笔。

## 37.10 章末地图（书 ch.11 习题选）

- **练习 11.3.1**（序列的导出形式定理）：正文定理的完整
  「当且仅当」双向——Prolog 件的双轨检定是其机器版；
- **练习 11.8.2**（记录模式匹配）：match 函数与嵌套模式——
  ML 系语言的日常、类型规则的好练习（机器件未收录，Prolog
  侧可仿 case 装配）；
- **练习 11.11.1**（用 fix 定义 equal/plus/times/factorial）：
  Church 编码（02/18 章）与原语递归的对照练习；
- **练习 11.12.1**（布尔+列表的进展/保持）：36 章 Coq 件的
  模板直接套用——T-List 五规则 + E-List 七规则的机械重演。

---

上一章：[36 操作语义](36-opsem.md) · 下一章：[38 引用与异常](38-refs.md)
