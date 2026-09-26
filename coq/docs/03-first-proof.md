# 03 · 第一个证明

对应示例：`../examples/03_first_proof.v`

### 3.1 三种句子：命令、策略与项

打开一个 `.v` 文件，你会看到三种成分。分清它们，Coq 的报错才有读法：

| 成分 | 例子 | 什么时候起作用 |
|---|---|---|
| **vernacular（命令）** | `Definition` `Example` `Print` `Check` `Require` `Qed` | 管理环境：声明、查询、加载 |
| **tactic（策略）** | `reflexivity` `intros` `simpl` `rewrite` `destruct` | 只在证明模式里，改造证明状态 |
| **term（项）** | `3` `S O` `fun n => n` `Nat.add 2 3` | 数据与证明的本体，类型检查的对象 |

一个文件就是一串命令；命令里嵌着项；`Proof.` 到 `Qed.` 之间是策略的地盘。第 11 章会精确解释策略如何工作，本章只需要「证明 = 用策略造项」这个直觉。

### 3.2 Definition：定义一个可计算对象

```coq
Definition square (n : nat) : nat := n * n.
```

读法：`Definition 名字 (参数 : 类型) : 返回类型 := 体.`。它是纯函数式的「let」——给 `fun n => n * n` 这个项起了个名字。三件套问询都能作用于它（实测输出）：

```coq
Check (square 3).   (* square 3 : nat *)
Compute (square 3). (* = 9 : nat *)
Print square.       (* square = fun n : nat => n * n
                        : nat -> nat *)
```

注意 `Print` 显示的是「编译器眼中的定义」——参数、类型、函数体，原样展开。定义没有魔法，`square 3` 就是 `3 * 3`，`Compute` 老老实实把它算出来。

### 3.3 Example / Proof / reflexivity / Qed 逐行解剖

现在进入正题。四行一个完整的证明：

```coq
Example square_3 : square 3 = 9.
Proof. reflexivity. Qed.
```

逐行拆解：

**第一行 `Example square_3 : square 3 = 9.`**
声明一个对象 `square_3`，其类型是命题 `square 3 = 9`。此刻它还没有「值」（证明）——就像你宣布「我要定义一个返回 bool 的函数」但还没写函数体。屏幕上（交互模式下）出现的证明状态是：

```text
1 subgoal

  ============================
  square 3 = 9
```

横线下面是**目标**（goal）：需要构造出 `square 3 = 9` 这个类型的一个居民。

**第二行 `Proof.`**
正式进入证明模式。它本身不做事，是个仪式性开关（默认开启，写出来是为了可读性）。

**第三行 `reflexivity.`**
策略登场。它检查：等式两边能否**化简到同一个值**？`square 3` 化简得 `9`，右边本来就是 `9`——两边相同，于是它构造出证明项 `eq_refl`（「自反性」的见证：`x = x` 型等式的通用证明）。目标消失，证明状态归零。

**第四行 `Qed.`**
封印。把从 `Proof.` 以来的策略脚本编译成一个证明项，交**内核**重新独立做一次类型检查（策略层即使有 bug 也骗不过这一步），通过后把 `square_3 : square 3 = 9` 存入环境。从此 `square_3` 是一个可引用的定理。

这套「陈述 → 开目标 → 打策略 → 封印」的节奏贯穿全书。初学时把四行**分开写、逐行执行**（CoqIDE 里按 F10），亲眼看目标怎么出现、怎么消失——这是建立证明直觉最快的方式。

### 3.4 证明是一个项：Print 它

Curry–Howard 不是口号，可以验证：

```coq
Print square_3.
```

```text
square_3 = eq_refl : square 3 = 9
```

`square_3` 的「值」是 `eq_refl`——一个由 `=` 类型的唯一构造子构成的项。就像 `list` 的值由 `nil`/`cons` 构成，**等式的值由 `eq_refl` 构成**。以后学到 `rewrite` 会看到：使用定理就是把它的证明项当作数据去变换。

### 3.5 失败长什么样：Fail 与 Abort

证明失败是日常。把断言写错：

```coq
Example broken : 2 + 2 = 5.
Proof.
  Fail reflexivity.
  (* The command has indeed failed with message:
     Unable to unify "5" with "4". *)
Abort.
```

两个新命令：

- **`Fail`**：断言「下一个命令应当失败」。失败了，`Fail` 成功；没失败，`Fail` 反而报错 `The command has not failed!`。它是**把错误变成可编译文档**的机制——本教程大量用它把坑写进示例。注意（实测）：失败提示语只在 coqtop / CoqIDE 里显示，coqc 批处理下静默；
- **`Abort.`**：放弃当前证明，环境回到陈述之前。证明做不下去时用它脱身，别把烂尾的 `Theorem` 留在文件里。

类型错误同样可以被 `Fail` 预言（示例 03 里就有）：

```coq
Fail Check (0 : bool).
(* The term "0" has type "nat" while it is expected to have
   type "bool". *)
```

Coq 的报错信息值得逐字读：**谁**（the term "0"）、**是什么**（has type "nat"）、**哪里不匹配**（expected "bool"）。它几乎总在说真话——第 33 章的坑清单里，一半条目的排查方法就是「把错误信息完整读完」。

### 3.6 Theorem 家族与命名习惯

以下关键字**语法地位完全相同**，都是「声明一个命题类型的对象」：

| 关键字 | 语义习惯 |
|---|---|
| `Theorem` | 比较重要的结果 |
| `Lemma` | 服务于主定理的中间结果 |
| `Corollary` | 由主定理直接派生 |
| `Proposition` | 中等重要性的陈述 |
| `Fact` / `Remark` | 顺手记下的小结论 |
| `Example` | 通常是算一算就能验证的具体断言 |

新手纠结「该用哪个」纯属浪费感情——随便挑，团队一致即可。本教程的习惯：具体计算断言用 `Example`，一般性结论用 `Theorem`。

### 3.7 Admitted：技术债开关

有一个危险的逃生门必须现在讲清楚：

```coq
Theorem i_promise : forall n : nat, n + 0 = n.
Proof. Admitted.   (* 假装证完了！ *)
```

`Admitted.` 把定理**作为公理**收下——之后所有依赖它的证明都建立在空中楼阁上。它是开发过程中「先跳过这段，后面再补」的合法手段，但**任何提交/发布的代码里都不该有它**。检查工具（第 25 章）：`Print Assumptions 定理名.` 会列出该定理依赖的全部公理——输出 `Closed under the global context` 才是干净证明。

### 3.8 本章坑位清单（实测）

1. **句子忘句点 / 多句点**：`Proof. reflexivity. Qed.` 一行三句，句点属于「句子」不属于「行」；
2. **`Fail` 在 coqc 下不打印失败原因**（见 3.5）；
3. **`Qed` 时才发现没证完**：还剩目标就 `Qed.`，报错 `Attempt to save an incomplete proof`——错误行号在 `Qed` 处，但真正的问题在前面；养成 `Show.` 的习惯；
4. **陈述里函数名拼错**：`square3` vs `square_3`，报的是 `The reference square3 was not found`，查拼写；
5. **`Admitted` 留进正式代码**：`Print Assumptions` 一查便知，CI 里应当禁；
6. **想当然写 `8 / 2`**：不加 `Require Import Arith` 就是记号未定义错误（第 2 章坑 3，本章示例文件头也注明了）。

---
上一章：[02 · 工具链与运行方式](02-toolchain.md) ｜ 下一章：[04 · 类型系统](04-types.md) ｜ 返回：[README](../README.md)
