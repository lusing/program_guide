# 32 · 综合实战：表达式解释器与优化器

对应示例：`../examples/32_project.v`

### 32.1 项目目标

收官项目把全书的工具连成一条完整的生产线：

1. **定义语言**：带变量的算术表达式（第 21 章的 aexp）；
2. **解释器**：状态下的求值（结构递归）；
3. **两个优化 pass**：吃掉 `0 + e`、常量折叠；
4. **组合证明**：流水线整体保语义——两个 pass 的正确性**免费合成**；
5. **抽取**：验证过的优化器导出成 OCaml，在真实世界运行。

这条线就是「验证编译器」的微缩景观：CompCert 的每个优化 pass 都配一条「语义保持」定理，pass 之间的组合因为各自正确而自动正确。你要写的全部代码不到 150 行。

### 32.2 语言与解释器

与第 21 章相同，直接复用：

```coq
Inductive aexp : Type :=
  | AConst (n : nat) | AVar (x : string)
  | APlus (a1 a2 : aexp) | AMinus (a1 a2 : aexp) | AMult (a1 a2 : aexp).

Definition state := string -> nat.

Fixpoint aeval (a : aexp) (st : state) : nat :=
  match a with
  | AConst n => n
  | AVar x => st x
  | APlus a1 a2 => aeval a1 st + aeval a2 st
  | AMinus a1 a2 => aeval a1 st - aeval a2 st
  | AMult a1 a2 => aeval a1 st * aeval a2 st
  end.

Example run1 : aeval (APlus (AVar "x") (AMult (AConst 2) (AConst 3)))
                    (fun _ => 10) = 16.
Proof. reflexivity. Qed.
```

### 32.3 pass 1：吃掉 0 + e

第 21 章的 `optimize0` 原样搬来（smart constructor 设计、正确性两步证法——忘了的话翻回去，这里是复用不是新知识）：

```coq
Theorem optimize0_correct : forall (a : aexp) (st : state),
  aeval (optimize0 a) st = aeval a st.
```

### 32.4 pass 2：常量折叠

新 pass：两个操作数都折成常量时，直接算掉：

```coq
Fixpoint const_fold (a : aexp) : aexp :=
  match a with
  | APlus e1 e2 =>
      match const_fold e1, const_fold e2 with
      | AConst n1, AConst n2 => AConst (n1 + n2)
      | e1', e2' => APlus e1' e2'
      end
  | AMinus e1 e2 =>
      match const_fold e1, const_fold e2 with
      | AConst n1, AConst n2 => AConst (n1 - n2)
      | e1', e2' => AMinus e1' e2'
      end
  | AMult e1 e2 =>
      match const_fold e1, const_fold e2 with
      | AConst n1, AConst n2 => AConst (n1 * n2)
      | e1', e2' => AMult e1' e2'
      end
  | AConst n => AConst n
  | AVar x => AVar x
  end.

Compute (const_fold (APlus (AConst 2) (AMult (AConst 3) (AConst 4)))).
(* = AConst 14 —— 整棵子树折成一个数 *)
```

双 scrutinee 的嵌套 match（第 7 章）在这里正合适。正确性证明有一个新看点——**rewrite 的方向反过来用 IH**：

```coq
Theorem const_fold_correct : forall (a : aexp) (st : state),
  aeval (const_fold a) st = aeval a st.
Proof.
  intros a st. induction a; simpl.
  - reflexivity.
  - reflexivity.
  - rewrite <- IHa1. rewrite <- IHa2.
    destruct (const_fold a1) eqn:E1; destruct (const_fold a2) eqn:E2;
      reflexivity.
  - (* AMinus：同款 *) ...
  - (* AMult：同款 *) ...
Qed.
```

APlus 分支的目标里，`const_fold a1` 藏在 match 的 scrutinee 位置——`rewrite IHa1`（正向）找不到 `aeval (const_fold a1) st` 这个模式；**先 `rewrite <- IHa1`** 把右边的 `aeval a1 st` 替换成 `aeval (const_fold a1) st`，两边就都谈 `const_fold` 的结果了。随后 `destruct (const_fold a1) eqn:E1; destruct (const_fold a2) eqn:E2` 十二种组合全部 `reflexivity`（分号把 reflexivity 批量发给每个目标）。「IH 用反向」是嵌套 match 场景的标准解法，与第 13 章的方向学完全自洽。

### 32.5 流水线：正确性免费合成

```coq
Definition pipeline (a : aexp) : aexp := const_fold (optimize0 a).

Theorem pipeline_correct : forall (a : aexp) (st : state),
  aeval (pipeline a) st = aeval a st.
Proof.
  intros a st.
  unfold pipeline.
  rewrite const_fold_correct.
  rewrite optimize0_correct.
  reflexivity.
Qed.
```

读一遍：`unfold` 展开 pipeline 定义（第 21 章的 unfold），两个 pass 的正确性定理接力 rewrite，三行收工。**这就是组合的正确性**——每个环节单独验证，串联后的保证自动成立，不需要对整条流水线重新归纳。CompCert 由几十个 pass 组成而依然可维护，靠的正是这个性质。

```coq
Example pipeline_demo :
  pipeline (APlus (AConst 0) (AMult (AConst 3) (AConst 4))) = AConst 12.
Proof. reflexivity. Qed.
```

`0` 被吃、常量被折，一次到位——且 `pipeline_correct` 担保**任何**表达式经过流水线语义不变。

### 32.6 抽取：从证明世界到运行世界

最后一步，把验证过的优化器变成可执行代码：

```coq
From Stdlib Require Import Extraction.

Recursive Extraction pipeline.
```

`Recursive Extraction` 把 pipeline（及其依赖的 aeval、aexp……）翻译成 OCaml 源码打印出来——类型、函数、递归全部直译（nat 仍是 `O | S of nat`，要高效可在 Z 上重做计算核心或让抽取走 `Extract Inductive nat => int` 一类的映射，超出本书范围）。工作流闭环：

```text
Coq：定义 + 定理                    OCaml：编译运行
     |        \                        ^
     |         \—— Recursive Extraction ——+
     +—— 证明正确性（留在 Coq，不需要运行时携带）
```

证明是开发期的脚手架，运行期零开销——**「经过验证的程序」不需要随身带着证明**。这个模型叫「验证后抽取」，是 Coq 走向工业界的主干道（CompCert 的 C 编译器本体、Fiat Crypto 的密码算法，都以这种方式交付）。

> 坑（实测）：`Recursive Extraction` 裸写报 `illegal begin of vernac`——必须先 `From Stdlib Require Import Extraction.`。

### 32.7 本章坑位清单（实测）

1. **`Recursive Extraction` 需要 Require**：先 `From Stdlib Require Import Extraction`，否则报非法命令（32.6 的坑）；
2. **const_fold 证明里 IH 用正向**：`rewrite IHa1` 在嵌套 match 场景找不到模式——`rewrite <- IHa1` 先把两边对齐（32.4 的完整分析）；
3. **流水线证明忘了 unfold**：`pipeline a` 不展开，rewrite 的模式藏在定义后面够不着；
4. **抽取产物里 nat 仍是一元**：性能敏感的抽取目标要规划数系（Z 核心 + 映射），别默认抽取完就是快的；
5. **想给语言加 if/while**：语法加个构造子容易，求值器加分支也容易——但 while 需要**终止性度量**或改用燃料（第 10 章 10.4），这是 Software Foundations《PLF》卷的入口，本书到此为止。

---
上一章：[31 · 自反证明](31-reflection.md) ｜ 下一章：[33 · 坑清单与最佳实践](33-pitfalls.md) ｜ 返回：[README](../README.md)
