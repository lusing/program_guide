# 25 · 测试与断言风格

对应示例：`../examples/25_testing.v`

### 25.1 Example 即测试

Coq 里不需要测试框架——`Example` + `reflexivity` 就是断言，`coqc` 就是测试运行器：

```coq
Definition inc (n : nat) : nat := S n.

Example test_inc_1 : inc 0 = 1.
Proof. reflexivity. Qed.

Example test_inc_41 : inc 41 = 42.
Proof. reflexivity. Qed.
```

改坏 `inc` 的任何一行，`build.ps1 -All` 当场全红。回归测试的全部要素（断言、运行、失败定位）都在，只是「跑测试」变成了「编译检查」。本教程每个示例文件从第 1 章起就在用这套——你已经在 TDD 了。

### 25.2 负向断言

「不该发生的」也要钉住：

```coq
Example test_inc_neg : inc 0 <> 2.
Proof. discriminate. Qed.

Fail Check (inc true).     (* 类型误用，如期失败 *)
```

`<>`（不等于）配 `discriminate`（第 13 章）锁具体值；`Fail`（第 3 章）锁「这行不该编译过」。两类负向断言把 API 的边界写成可执行文档。

### 25.3 从测试升级为定理

测试思维与证明思维的分界线是 **forall**。工作流（示例 25 的完整示范）：

```coq
(* 第一步：具体样例找感觉 *)
Example test_all_even_1 : all_even [2; 4; 6] = true.
Proof. reflexivity. Qed.

(* 第二步：把想要的性质一般化 *)
Theorem all_even_app : forall l1 l2 : list nat,
  all_even l1 = true -> all_even l2 = true
  -> all_even (l1 ++ l2) = true.
Proof.
  intros l1. induction l1 as [| x tl IH]; intros l2 H1 H2.
  - exact H2.
  - simpl in H1.
    apply andb_true_iff in H1.   (* && = true 拆两个 = true *)
    destruct H1 as [Ex Et].
    simpl. rewrite Ex. simpl.
    apply IH; assumption.
Qed.
```

具体值是测试（跑有限个），量化命题是证明（覆盖无穷个），Example 是通往 Theorem 的脚手架。`apply IH; assumption.` 的分号用法（第 18 章）在这里顺手续掉两个前提。`andb_true_iff` 是 bool 世界的拆桥工具——第 14 章 `destruct` 拆 `/\` 的 bool 版。

### 25.4 公理审查：Print Assumptions

测试证明「行为对」，`Print Assumptions` 审查「出身清白」（第 3 章埋的线）：

```coq
Theorem honest : 2 + 2 = 4.
Proof. reflexivity. Qed.
Print Assumptions honest.
(* Closed under the global context —— 干净 *)

Axiom bogus : forall n : nat, n = 0.
Theorem poisoned : 3 = 0.
Proof. apply bogus. Qed.
Print Assumptions poisoned.
(* Axioms:
   bogus : forall n : nat, n = 0 —— 出身有问题！ *)
```

一条 `Admitted`、一个手滑的 `Axiom`，都会在这里现形（实测输出如上）。**工程化纪律**：CI 里对每个公开定理跑 `Print Assumptions`，只许 `Closed under the global context`——「无公理依赖」是可验证代码的最低出厂标准。

### 25.5 什么时候测试、什么时候证明

| 场景 | 手段 |
|---|---|
| 具体行为快照（回归锚点） | Example + reflexivity |
| API 误用应被拒绝 | Fail Check / Fail Definition |
| 不变式对一切输入成立 | Theorem + induction |
| 纯算术性质 | lia（第 24 章） |
| 发布检查 | Print Assumptions 全绿 |

成本直觉：Example 十秒写完零维护；Theorem 十分钟起步但永久免疫。**原型期堆 Example，接口稳定后把关键性质升格为 Theorem**——两层的配比就是工程判断。

### 25.6 本章坑位清单（实测）

1. **`Fail Example 名 : 假命题. Proof. reflexivity. Qed.`**：Fail 只包一句——陈述句本身合法（成功），下一个 reflexivity 才失败且不在 Fail 保护内，文件直接编译失败。负向断言的正确写法是 `Example 名 : x <> y. Proof. discriminate. Qed.`（实测对照）；
2. **`<>` 目标忘了它是否定**：`x <> y` 即 `x = y -> False`——`discriminate`/`intros H` 后引爆即可，别试图「直接证」；
3. **Print Assumptions 输出 Axioms 却继续提交**：审查输出要进 CI，人工看一眼的日子久了会疲劳；
4. **测试 bool 函数忘了负例**：只测 `= true` 的样例测不出「永远返回 true」的假实现——`all_even [2;3] = false` 这类负例与正例同等重要。

---
上一章：[24 · 数值专题：nat、N 与 Z](24-numbers.md) ｜ 下一章：[26 · 依赖类型与强规范](26-dependent.md) ｜ 返回：[README](../README.md)
