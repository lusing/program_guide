# 19 · Ltac：自定义策略

对应示例：`../examples/19_ltac.v`

### 19.1 为什么需要一种「策略语言」

写到第 18 章，你已经见过这样的剧本重复出现：`intros; simpl; rewrite 某定理; reflexivity`。第三章的套路抄到第四章还好，抄到第三十章呢？Ltac 是 Coq 内置的**策略定义语言**——把重复的证明步骤做成一个名字，之后一个词调用。它不是宏展开：Ltac 的策略是带参数、可递归、能对目标做模式匹配的**程序**，运行在证明搜索引擎里。

本章路线：参数 → 递归 → `match goal` → 深度匹配与回溯 → 计算与打包，最后是 Hint 数据库与 eauto。

### 19.2 带参数的策略：试探-回滚习语

```coq
Ltac auto_clear h := try (clear h; auto; fail).
```

这行浓缩了 Ltac 控制流的三件套：

- `tac1; tac2` 顺序组合——**所有**当前目标都要过 tac2；
- `fail` 制造失败——但注意 `auto; fail` 的妙处：auto 若收掉全部目标，fail 没有目标可作用，整串**空成功**；auto 没收掉则 fail 触发；
- `try (...)` 捕获失败并**回滚**——连 `clear h` 一起撤销，h 原样回到上下文。

合起来：「先移走 h 试试能不能 auto 收工；不行就把 h 放回来当无事发生」。示例 19.1 里 `auto_clear_rollback` 验证了回滚后 `lia` 仍然能用 H。

参数还可以是**另一个策略**——调用时用 `ltac:(...)` 括起来，把策略与普通 Gallina 项区分开：

```coq
Ltac auto_after tac := try (tac; auto; fail).
auto_after ltac:(clear Hm).
```

### 19.3 递归策略

```coq
Ltac le_S_star := apply le_n || (apply le_S; le_S_star).
```

`||` 是「左边失败才试右边」。`le_S_star` 证明 `5 <= 25`：先试 `le_n`（收尾），不行就剥一层 `le_S` 再递归。策略递归没有结构递归约束——它跑在搜索里，但**不保证终止**，设计时要确保有收尾分支。

### 19.4 match goal：按目标形状分派

```coq
Ltac dispatch :=
  match goal with
  | [ |- _ = _ ] => reflexivity
  | [ |- _ <= _ ] => lia
  | [ |- _ < _ ]  => lia
  end.
```

模式 `[ 假设们 |- 目标 ]` 里：`|-` 左边写假设的模式（可只写需要的），右边是目标模式，`?x` 是元变量。匹配成功执行右支；**右支失败会回溯到下一个匹配**——所以 dispatch 遇到 `0 + n = n` 走 reflexivity 分支，若 reflexivity 失败（比如 `n + 0 = n`），Ltac 会自动尝试后续子句，全都不匹配才报 `No matching clauses`。

也能对**假设**做匹配。contrapose 把 `~A` 目标配 `~B` 假设换成新假设 B 与目标 A（逆否变换）：

```coq
Ltac contrapose H :=
  match goal with
  | [ H0 : ~ _ |- ~ _ ] => intro H; apply H0
  end.
```

### 19.5 深度匹配：context 与 fail n

目标里任意深处的子项，用 `context[...]` 挖出来：

```coq
Ltac S_to_plus_simpl :=
  match goal with
  | [ |- context [S ?x] ] =>
      match x with
      | O => fail 1
      | ?y => rewrite (S_plus_one y); S_to_plus_simpl
      end
  | [ |- _ ] => idtac
  end.
```

这个经典例子（书 7.6.2.4）要把所有 `S x` 改写成 `x + 1` 再交给 ring。为什么不直接 `repeat rewrite S_plus_one`？——`1` 本身就是 `S 0`，改写产物 `0 + 1` 里又长出新的 `S 0`，**无限循环**。解法是挖出参数 x：x 是 0 时用 `fail 1` 跳出。

`fail 1` 的数字是「跳出几层选择点」。`fail 0` 只废掉当前分支，Ltac 会试同一模式的下一个实例；`fail 1` 连内层 match 一起废掉，回到外层找 `S` 的下一个出现——这正是我们要的语义。

> 版本注记（实测）：书里这个技巧的动机是「ring 不认识 S」——在 8.x 属实；**9.1 的 ring 已经能直接吃下 `S n`**，本例的价值转为展示 context 匹配与 fail 层级本身。

### 19.6 在策略里做计算：eval ... in

```coq
Ltac simpl_on e :=
  let v := eval simpl in e in
  match goal with
  | [ |- context [e] ] => replace e with v; [ idtac | auto ]
  end.
```

`eval simpl in e` 在策略层面把 e 化简出一个值 v，再 `replace` 目标里的所有 e——「只化简指定子项」的定向 simpl。`let ... := ... in` 绑定的就是普通策略值。

### 19.7 工程打包：inv 与 number_goal

最常用的三连打包成一句话：

```coq
Ltac inv H := inversion H; subst; clear H.
```

「一击必杀」型组合用 `first`：

```coq
Ltac number_goal := first [ reflexivity | lia | ring | congruence ].
```

### 19.8 Hint 数据库与 eauto

`Hint Resolve 定理 : 库名.` 把定理注册进指定数据库，`eauto with 库名` 搜索时当积木用。eauto 与 auto 的差别在 **e**（existential）：auto 不会为 `le_trans` 这类定理猜测中间值，eauto 用存在变量替它猜——代价是搜索树更大、更慢。

`Hint Rewrite 定理 : 库名.` 注册「永远从左往右」的重写规则，配合 `autorewrite with 库名` 一键展开。示例 19.7 的组合逻辑例子：S、K 两条重写规则注册后，`S K K` 被自动化简成恒等组合子——`autorewrite` 做完了所有该做的事。注意别注册会**互相点燃**的规则组，否则 autorewrite 不终止。

### 19.9 本章坑位清单（实测）

1. **matched 子句失败 ≠ 整个 match 失败**：右支失败回溯尝试后续子句，全不中才报 No matching clauses——报错位置经常出乎意料；
2. **`repeat rewrite` 会循环**：改写产物里长出新的匹配项（S 0 → 0 + 1 → …）时无限循环，coqc 直接卡死——用 context 挖参数 + fail n 精确控制（19.5）；
3. **fail 的数字是相对层级**：fail 0/fail 1/fail 2 行为完全不同，调不通时先数清楚自己嵌在几层 match 里；
4. **Ltac 无穷递归没有守卫检查**：策略递归不像 Fixpoint 有结构约束，死循环编译期不报、运行时挂；
5. **eauto 很慢**：搜索树指数膨胀，大开发里先把能 hint 的都 hint 上，再用深度限制（`eauto 3`）；
6. **Hint Rewrite 别注册循环规则**：两条互相改写的等式会让 autorewrite 停不下来。

---
上一章：[18 · 策略武器库与模块](18-tactics-modules.md) ｜ 下一章：[20 · 决策过程](20-decision.md) ｜ 返回：[README](../README.md)
