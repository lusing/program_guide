# 20 · 决策过程：ring、lia 与它的家族

对应示例：`../examples/20_decision.v`

### 20.1 决策过程是什么

「决策过程」（decision procedure）= 对一整类问题**保证给答案**的算法。前面章节里你已经零星用过 lia；本章把这一家族系统过一遍——它们是日常证明的主力武器，选对工具能省掉一半手工劳动。

| 策略 | 管什么 | 典型目标 |
|---|---|---|
| `ring` | 环/半环上的等式 | 多项式展开、配方 |
| `ring_simplify` | 同上，但输出范式 | 化简成标准形 |
| `lia` | 线性整数算术（nat/Z），挖上下文 | `x <= y -> x + 0 <= y` |
| `nia` | 非线性整数（启发式） | `0 <= x -> 0 <= x * x` |
| `field` | 域上的等式（实数除法） | `(x+y)/y = 1 + x/y` |
| `lra` | 实数线性算术 | 实数不等式推理 |
| `tauto` | 直觉主义命题重言式 | `P /\ ~P -> Q` |
| `intuition` | 拆命题结构 + 指定后续策略 | `intuition lia` |
| `congruence` | 等式同余与构造子冲突 | `x = y -> f x = f y` |

### 20.2 ring：多项式恒等式自动机

```coq
Theorem ring_z : forall x y : Z,
  ((x + y) * (x + y) = x * x + 2 * x * y + y * y)%Z.
Proof. intros x y. ring. Qed.
```

ring 用**自反证明**（第 31 章展开）实现：把两边规整成多项式范式再比对。nat（半环，没有减法和负数）与 Z 都行。

两条实测边界：

1. **ring 无视上下文**——假设 `H : x = 3` 摆在那它也不看。先把已知值 `rewrite` 进目标，ring 才能收（示例 20.1 的 `ring_no_hyp`）；
2. **ring 看不见定义**——自定义的 `dbl n := n + n` 对它是原子，`unfold dbl` 展开成多项式后它才认识（`ring_opaque`）。

版本注记（实测）：8.x 时代 ring 不认识 `S n`，老教材要用专门策略先改写成 `n + 1`；**9.1 的 ring 已能直接吃下**——`S n * m = m + n * m` 一击即中。

`ring_simplify` 把等式两边规整成范式但不负责收尾——目标是「化简」不是「证明」时用它，通常跟一刀 `ring` 或 `reflexivity` 收。

### 20.3 lia：线性整数算术的假设挖掘机

第 24 章介绍过 lia 的基本盘；这里补两个进阶认识。

**lia 挖上下文**：合取假设自动拆开用，连藏在里面的线性信息都捡走：

```coq
Theorem lia_mines_conj : forall x y z : Z,
  ((x <= y /\ y <= z -> x <= z))%Z.
Proof. intros x y z H. lia. Qed.
```

**非线性子项当黑盒**：`x * x` 整体记作原子 X，`0 <= X`、`3 * X <= 2 * y` 就成了关于 X 和 y 的线性约束——lia 依然能推（示例 `lia_blackbox`）。但黑盒只是「视而不见」不是「会推理」：真正需要乘积的代数推理（比如从 `0 <= x` 推 `0 <= x * x`）时 lia 无能为力，换 **nia**——它对非线性目标做启发式展开。实力划分记住一句话：**线性找 lia，乘积找 nia**。

### 20.4 field 与 lra：实数两件套

```coq
Example field_ex : forall x y : R,
  ((y <> 0 -> (x + y) / y = 1 + x / y))%R.
Proof.
  intros x y H. field. assumption.
Qed.
```

field 是带除法的 ring。化简除法会挖出「除数非零」**副目标**——这不是 bug 是特性：类型系统逼你交代清楚每个除法合法。实数不等式用 `lra`（老教材的 fourier 策略 8.9 起弃用，现名 lra）。

实测提醒：实数没有字面量作用域，`y <> 0`、`x - y > 1` 这类命题裸写在 `forall ... : R` 下会把 `0`、`1` 解析成 nat——给整个命题套 `%R`（示例 20.3 的写法）。

### 20.5 命题层：tauto / intuition / congruence

```coq
Theorem tauto_ex : forall P Q : Prop, P /\ ~ P -> Q.
Proof. intros P Q H. tauto. Qed.
```

auto 证不了这条（它不会拆假设里的合取），tauto 一击——它判定的是**直觉主义**命题逻辑的永真式。天花板也在这里：`~~P -> P` 不是直觉主义定理，tauto 证不动——要么走经典逻辑公理（`Classical` 的 `NNPP`，见 20.6 的公理审查），要么改述命题。

`intuition` 先把命题结构（合取/析取/蕴含）自动拆解，再用给定策略收拾残余目标——`intuition lia` 是「命题壳 + 算术芯」目标的标配：

```coq
Theorem intuition_ex : forall n p q : nat,
  n <= p \/ n <= q -> n <= p \/ n <= S q.
Proof. intros n p q H. intuition lia. Qed.
```

`congruence` 做等式同余推理：`x = y` 时 `f x = f y` 自动成立；构造子冲突（`S x = 0`）它也认。

### 20.6 公理审查：决策过程也可能带公理

```coq
Print Assumptions nnpp.
(* Axioms:
     classic : forall P : Prop, P \/ ~ P *)
```

经典逻辑的定理建立在排中律公理上——`Print Assumptions` 把账本摊开（第 25 章详述）。选决策过程时心里有这张表：lia/ring/tauto 是构造性的，`Classical` 系列引公理。

### 20.7 本章坑位清单（实测）

1. **ring 不读上下文**：假设里的等式要先 rewrite 进目标；
2. **ring 不展开定义**：自定义函数先 unfold；
3. **`ring_simplify` 不收尾**：目标变成范式后还开着，记得补 reflexivity/ring；
4. **lia 黑盒认形不认义**：`x * x` 和 `(x * x) * 1` 它看作两个不同原子；真正非线性换 nia；
5. **实数命题忘套 %R**：`0` `1` 被当 nat，报「has type nat while expected to have type R」；
6. **fourier 已弃用**：老书代码 `fourier.` 换 `lra.`；实数相关模块是 `Reals` + `Lra`（lra 不在 Lia 里，要单独 Require）；
7. **tauto ≠ 自动经典逻辑**：排中律、双否消去它证不了，需要 `Classical` 并接受公理依赖。

---
上一章：[19 · Ltac：自定义策略](19-ltac.md) ｜ 下一章：[21 · 表达式求值器：AST 入门](21-ast.md) ｜ 返回：[README](../README.md)
