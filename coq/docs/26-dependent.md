# 26 · 依赖类型与强规范

对应示例：`../examples/26_dependent.v`

### 26.1 让「类型」说出值的性质

到第 25 章为止，类型只回答「**是什么**」（nat、list bool、option A），性质住在命题里——类型和性质是两个世界。依赖类型（dependent type）把它们焊在一起：**类型的表达式可以依赖值**。这一步打通后能做两件事：

- **编译期检查数据性质**：长度写进类型的向量，拼错长度直接编译失败；
- **强规范（strong specification）**：函数的输出类型直接携带「输出满足性质」的证据。

### 26.2 依赖数据类型：vect

```coq
Inductive vect (A : Type) : nat -> Type :=
| vnil  : vect A 0
| vcons : forall {n}, A -> vect A n -> vect A (S n).
```

`vect A n` 是「长度为 n 的 A 向量」。三个直接后果（示例 26.1 全部实测）：

1. **长度算术在类型里过关**：`vappend` 的返回类型是 `vect A (n + m)`，两个分支的类型（`0 + m` 与 `S n' + m`）靠**可转换性**自动对上——类型检查器本身就是个小型计算器；
2. **长度错误编译期拒绝**：`Fail Check (vcons 1 vnil : vect nat 5).`——不是警告，是类型错误；
3. **依赖匹配会剪枝**：`vhead` 处理 `vect A (S n)` 时，vnil 分支**不可能**、可以整个省略——普通 list 的 head 只能返回 option（第 17 章），依赖类型把「非空」的运行期检查变成了编译期事实。

### 26.3 弱规范 vs 强规范

同一个函数的两种住法（书第 9 章的核心对照）：

| | 弱规范 + 伴随引理 | 强规范 |
|---|---|---|
| 函数类型 | `A -> B` | `forall a : A, {v : B \| R a v}` |
| 性质住哪 | 单独的定理 `forall a, R a (f a)` | 类型里，与值打包 |
| 取值 | 直接 `f a` | `proj1_sig (f a)` |
| 造假可能 | 忘证伴随引理 | 类型不过，编译失败 |

第 24 章的排序、21 章的优化器都是弱规范路线；本章给强规范路线配齐零件。

### 26.4 零件一：子集类型 {x : A | P x}

```coq
Definition pos (n : nat) : {p : nat | n < p}.
Proof. exists (S n). lia. Defined.

Compute (proj1_sig (pos 41)).   (* = 42 *)
```

`{x : A | P x}`（归纳类型 `sig`）装着**值 + 值满足 P 的证据**。构造它的唯一方法是给出真的证明——`pos 41` 里那个「42 > 41」的证据是 lia 现场造的。`proj1_sig` 取计算部分，证明部分对计算不可见。

它与 `ex`（存在量词）长得一模一样，关键差别在大类：sig 在 **Set**（可计算、可抽取），ex 在 **Prop**（证明无关）。所以能写 `sig -> A` 的取值函数，写不了 `ex -> A`——「存在」只许用来证命题，不许用来造程序。

### 26.5 零件二：有认证的不相交和 {A} + {B}

```coq
Definition zero_dec : forall n : nat, {n = 0} + {n <> 0}.
```

`sumbool` 是 bool 的强规范版：true/false 各自带「为什么」。标准库的判定函数都以 `_dec` 收尾（`Nat.eq_dec : forall n m, {n = m} + {n <> m}`），而且 sumbool 可以直接放进 `if`——这正是 if 语法的真身（第 5 章的伏笔在此兑现）。

### 26.6 强规范函数三连：pred 的三种写法

前驱函数最能暴露三种风格的差别（示例 26.5）：

```coq
(* 版本一：强规范输出——要么给前驱加证据，要么证明 n = 0 *)
Definition pred_strong : forall n : nat, {p : nat | n = S p} + {n = 0}.

(* 版本二：偏函数 + 前置条件——调用方负责证明 n <> 0 *)
Definition pred_partial : forall n : nat, n <> 0 -> nat.

(* 版本三：前置条件 + 子集类型收尾 *)
Definition pred_witness : forall n : nat, n <> 0 -> {p : nat | n = S p}.
```

注意版本二的 `refine` 写法——计算骨架（match 的形状）自己写，证明留 `_` 交给策略补。**计算内容不被自动策略污染**，这是书 9.2.7 力荐的分工：人管算法，策略管证据。

### 26.7 Defined 与 Qed：能算的证明收尾方式不同

```coq
Definition pred_opaque : forall n : nat, {p : nat | n = S p} + {n = 0}.
Proof. ... Qed.

Compute (pred_opaque 5).
(* = pred_opaque 5 —— 卡住！ *)
```

`Qed` 把证明封成**黑盒**（opaque），Compute 展不开；`Defined` 保持透明，计算畅通。示例 26.6 并排放了两个版本，Compute 的输出一目了然。铁律：**证定理用 Qed，造函数用 Defined**。

### 26.8 本章坑位清单（实测）

1. **造函数误用 Qed**：类型含 sig/sumbool 的定义用 Qed 收尾，Compute 直接卡住——输出停在函数名上不动（26.7 的对照实验）；
2. **sig 当子类型用**：`{x : A | P x}` 的元素**不是** A 的元素——要过 `proj1_sig` 这道门，老的 `exist` 记法别和 ex 的混；
3. **依赖匹配的省略分支**：依赖类型让不可能分支可省（vhead），但省略的依据是「构造子索引 unify 不上」——不满足时（比如 `vect A n` 的 n 是变量）还是得写全；
4. **前置条件的证明传染**：偏函数连用两次（pred ∘ pred）时，第二个前置条件的证明要引用第一个调用的**结果**——书 9.2.4 的经典难题（二阶合一），强规范版本（pred_witness）能显著缓解：取出的值自带证据，不再依赖前置条件的形状；
5. **自动策略污染计算内容**：构造强规范函数时滥用 auto/eauto，生成的项计算结构混乱——用 refine 手写骨架（书 9.2.2 的警告）。

---
上一章：[25 · 测试与断言风格](25-testing.md) ｜ 下一章：[27 · 互归纳：树与森林](27-mutual.md) ｜ 返回：[README](../README.md)
