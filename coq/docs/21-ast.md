# 21 · 表达式求值器：AST 入门

对应示例：`../examples/21_ast.v`

### 21.1 用归纳类型定义一门小语言

本章把前 18 章的全部工具组装成一件真正的作品：一个算术表达式的**求值器**，配上一个**优化器**，再证优化器**不改变程序含义**。先定义语法——一个归纳类型，每个构造子是一种语法形态：

```coq
Inductive aexp : Type :=
  | AConst (n : nat)          (* 字面量 *)
  | AVar (x : string)         (* 变量 *)
  | APlus (a1 a2 : aexp)      (* a1 + a2 *)
  | AMinus (a1 a2 : aexp)     (* a1 - a2 *)
  | AMult (a1 a2 : aexp).     (* a1 * a2 *)
```

表达式 `2 + x * 3` 在 Coq 里就是这个**语法树**（AST，abstract syntax tree）：

```coq
APlus (AConst 2) (AMult (AVar "x") (AConst 3))
```

几个值得停下来体会的点：

- **语法即数据**：别的语言里「表达式」是编译器内部的黑盒，在 Coq 里它是个再普通不过的归纳类型——能 `Check`、能 `Compute`、能 match、能对它归纳证明；
- **没有语法糖**：AST 是抽象语法，括号、优先级这些具体写法的烦恼不存在（代价是手写 AST 略啰嗦，真做语言要配解析器——超出本书范围）；
- **构造子带参数标注**：`APlus (a1 a2 : aexp)` 是第 9 章 `node (l a r)` 的同款写法（参数直接写在构造子里），比老式「冒号在后面」紧凑。

### 21.2 状态与求值器

变量需要环境。最直接的表达：**状态 = 从变量名到值的函数**：

```coq
Definition state := string -> nat.
```

「函数当数据用」又一次出现——一个具体的状态就是一个具体的查表函数：

```coq
Definition st1 : state := fun x =>
  if String.eqb x "x" then 5 else 0.
```

求值器是对 AST 的结构递归——每种语法形态一个分支：

```coq
Fixpoint aeval (a : aexp) (st : state) : nat :=
  match a with
  | AConst n => n
  | AVar x => st x
  | APlus a1 a2 => aeval a1 st + aeval a2 st
  | AMinus a1 a2 => aeval a1 st - aeval a2 st
  | AMult a1 a2 => aeval a1 st * aeval a2 st
  end.

Example eval_ex1 : aeval (APlus (AVar "x") (AConst 1)) st1 = 6.
Proof. reflexivity. Qed.
```

`Fixpoint` 的终止性检查照常通过（递归都在子表达式上）。注意减法用的是 nat 的截断减（第 5 章的坑在这门小语言里复现——`x - y` 当 y > x 时得 0；做练习时留意）。

### 21.3 优化器：smart constructor 的设计

目标优化：`0 + e` 化简为 `e`。直接写会掉进一个坑——把判断塞进 `optimize` 的 APlus 分支：

```coq
(* 反面教材（伪码）：
Fixpoint optimize (a : aexp) :=
  match a with
  ...
  | APlus (AConst 0) e2 => optimize e2      (* 嵌套模式 *)
  | APlus e1 e2 => APlus (optimize e1) (optimize e2)
  ...
```

问题在证明：对 `a1` 归纳到 APlus 分支时，`optimize (APlus a1 a2)` 里 a1 是变量，嵌套模式 `AConst 0` 的 match 卡住化简不了，得再对 a1 穷举五种构造子——证明变成二十多行的模式体操。

工程解法是把「加法的构建」独立成 **smart constructor**：

```coq
Definition optimize_plus (e1 e2 : aexp) : aexp :=
  match e1 with
  | AConst 0 => e2
  | _ => APlus e1 e2
  end.

Fixpoint optimize (a : aexp) : aexp :=
  match a with
  | AConst n => AConst n
  | AVar x => AVar x
  | APlus e1 e2 => optimize_plus (optimize e1) (optimize e2)
  | AMinus e1 e2 => AMinus (optimize e1) (optimize e2)
  | AMult e1 e2 => AMult (optimize e1) (optimize e2)
  end.
```

效果（实测）：

```coq
Compute (optimize (APlus (AConst 0) (AVar "y"))).
(* = AVar "y" —— 0 + y 被吃掉 *)

Compute (optimize (APlus (APlus (AConst 0) (AVar "x")) (AConst 0))).
(* = APlus (AVar "x") (AConst 0)
   里层的 0 + x 被吃；x + 0 保留——优化器只认 0 在左，
   「e + 0 → e」的折叠留给第 32 章实战 *)
```

### 21.4 正确性证明：两步走

**定理**（优化器不改变语义）：

```coq
Theorem optimize_correct : forall (a : aexp) (st : state),
  aeval (optimize a) st = aeval a st.
```

分两步证。**第一步**，smart constructor 自己的正确性——注意它对**任意** u v 成立，与 optimize 无关，所以证明是独立的：

```coq
Lemma optimize_plus_correct : forall (u v : aexp) (st : state),
  aeval (optimize_plus u v) st = aeval u st + aeval v st.
Proof.
  intros u v st.
  unfold optimize_plus.        (* 展开定义，露出 match u *)
  destruct u; simpl; try reflexivity.
  destruct n; reflexivity.     (* AConst n 的 n 还要分 0 / S *)
Qed.
```

`unfold`（把定义展开成定义体）是新面孔但不必紧张：它就是「把名字换成定义」的 rewrite。`destruct u` 五种构造子里四种直接 reflexivity（两边形状相同），唯独 `AConst n` 里 n 未知，再分 `0` / `S k` 两步收掉。

**第二步**，主定理对 a 归纳，APlus 分支引用小引理：

```coq
Theorem optimize_correct : forall (a : aexp) (st : state),
  aeval (optimize a) st = aeval a st.
Proof.
  intros a st. induction a; simpl.
  - reflexivity.
  - reflexivity.
  - rewrite optimize_plus_correct. rewrite IHa1, IHa2. reflexivity.
  - rewrite IHa1, IHa2. reflexivity.
  - rewrite IHa1, IHa2. reflexivity.
Qed.
```

读 APlus 分支：目标左边是 `aeval (optimize_plus (optimize a1) (optimize a2)) st`——`optimize_plus_correct` 把这一层剥成 `aeval (optimize a1) st + aeval (optimize a2) st`，两个归纳假设再各自把 `optimize` 剥掉，两边归一。**五个分支、三个 rewrite，一个「优化器正确」的定理到手。**

这个 40 行的闭环值得敬畏：它就是 CompCert（验证编译器）、Verified SCC（验证垃圾回收）这类工业成果的**最小完整样本**——定义语言、写变换、证保持语义。规模差万倍，结构完全同构。

### 21.5 设计即证明友好

回头看，本章最大的心得不在证明里，而在**设计**里：把嵌套模式拆成 smart constructor，让「何时优化」的判断集中在一个小函数，主函数保持纯结构递归——于是主定理保持「标准归纳剧本」，特殊情况的复杂度被隔离进一个独立小引理。**为可证性而设计**（design for verifiability）是 Coq 工程师的核心技能：当你发现证明难得离谱，多半是定义可以改得更「结构化」。

### 21.6 本章坑位清单（实测）

1. **嵌套模式直接进 Fixpoint 导致证明爆炸**：21.3 的反面教材——用 smart constructor 隔离判断；
2. **`AConst n` 分支忘分 n**：`optimize_plus` 的 match 对 n 卡住，`destruct n` 补刀才收；
3. **nat 截断减法混进语言语义**：`AMinus` 沿用 nat 减法，负中间结果是 0——想语义正确可换 `Z` 结果类型或加 precondition（进阶）；
4. **String.eqb 的状态函数**：`st1` 用 `String.eqb x "x"` 判断——别用 `=`（那是 Prop，if 需要 bool，第 4 章的老朋友）；
5. **`rewrite IHa1, IHa2` 逗号**：`rewrite A, B` 是 `rewrite A. rewrite B.` 的缩写——顺序执行，B 失败整个失败，分开排查更容易。

---
上一章：[20 · 决策过程](20-decision.md) ｜ 下一章：[22 · 列表定律证明实战](22-list-laws.md) ｜ 返回：[README](../README.md)
