# 18 · 策略武器库与模块

对应示例：`../examples/18_tactics_modules.v`

### 18.1 自动化第一档：auto

前 17 章的证明全靠手工。`auto` 是自动化的入口——一个带提示库的深度优先搜索：

```coq
Theorem auto_ex : forall P Q : Prop, P -> (P -> Q) -> Q.
Proof. auto. Qed.
```

`auto` 能拼出：上下文假设的组合、`reflexivity` 可关闭的等式、简单构造子应用（split/left/…）。它**不能**做归纳、不能重写库里你没用 `Hint` 注册的定理。使用心法：

- 目标「一眼显然」（假设的直接组合、定义展开即相等）→ 先 `auto` 试试；
- `auto` 失败不损失什么——马上回到手工；
- 想给 auto 加弹药：`Hint Resolve 定理名.` 把定理挂进提示库（本教程不展开，知道有这回事即可）。

更激进的 `eauto`（会自己造存在证人）、`firstorder`（一阶逻辑专用）是后续的自学方向——先把手工程序练熟，才知道自动化在替你做什么。

### 18.2 assert：证明的分段

证明超过半屏就该拆。`assert (H : 陈述)` 造一个「局部引理」：花括号里现场证明它，之后 H 当普通假设用：

```coq
Theorem plus_rearrange : forall n m p q : nat,
  (n + m) + (p + q) = (m + n) + (p + q).
Proof.
  intros n m p q.
  assert (H : n + m = m + n).
  { apply Nat.add_comm. }
  (* 注意（实测坑）：老教材里的 plus_comm 在 8.20 已不存在，
     现名 Nat.add_comm——抄旧书先 Check 名字 *)
  rewrite H. reflexivity.
Qed.
```

assert 是**证明的模块化**：大定理拆成「引理链」，每段独立可读。与「提前把引理证成 Theorem」相比，assert 的引理是局部的——只在这个证明里可见，不污染命名空间。经验法则：会被多处复用的上升为 Theorem，单点使用的 assert 就地解决。

### 18.3 控制流组合：分号、try、嵌套

三个组合子让策略脚本紧凑：

```coq
(* ;  分号：让一条策略作用于当前全部目标 *)
Example semi_ex : forall b : bool, orb b true = true.
Proof.
  intros b. destruct b; reflexivity.
Qed.
```

`destruct b; reflexivity.` 读作「分情况后，每个情况各自 reflexivity」——两种情况一行收。展开写要两个子弹七行，等价但啰嗦。

```coq
(* try：失败就当无事发生 *)
intros n. simpl. try reflexivity.
```

`try reflexivity` 在证不了的目标上静默跳过——常与 `;` 连用：`destruct b; try reflexivity.` 留下证不动的情况继续手工。这两个组合子是「批量处理 + 例外管理」的策略语言版。

### 18.4 模块：命名空间

第 2 章示例就开始用 `Module ... End` 包装，现在正式讲。模块把一组定义（类型、函数、定理）打包进独立命名空间：

```coq
Module Stack.
  Definition t := list nat.
  Definition empty : t := [].
  Definition push (x : nat) (s : t) : t := x :: s.
  Definition pop (s : t) : option (nat * t) :=
    match s with
    | [] => None
    | h :: tl => Some (h, tl)
    end.
  Theorem pop_push : forall (x : nat) (s : t),
    pop (push x s) = Some (x, s).
  Proof. intros x s. reflexivity. Qed.
End Stack.

Compute (Stack.pop (Stack.push 5 Stack.empty)).   (* Some (5, []) *)
```

外部以 `Stack.pop` 点名访问；模块内互相直呼其名。定义与「关于定义的定理」同居一室——**接口和它的正确性证明在同一个命名空间里交付**，这是 Coq 工程化与普通语言最不同的气质。

### 18.5 模块签名：接口与封装

`Module Type` 声明**签名**（signature）——一组名字与类型的规定，`Parameter` 表示「签名不关心你怎么实现」，`Axiom` 表示「实现必须交付这条正确性证明」：

```coq
Module Type STACK_SIG.
  Parameter t : Type.                    (* 只说「有个类型」 *)
  Parameter empty : t.
  Parameter push : nat -> t -> t.
  Parameter pop : t -> option (nat * t).
  Axiom pop_push : forall (x : nat) (s : t),
    pop (push x s) = Some (x, s).        (* 行为承诺 *)
End STACK_SIG.

Module SealedStack : STACK_SIG := Stack.
```

`Module SealedStack : STACK_SIG := Stack.` 用签名**封印**了实现。效果（实测）：

```coq
Print SealedStack.t.
(* SealedStack.t : Type —— 看不到 list nat 了 *)

Fail Check (SealedStack.push 5 [1; 2]).
(* 签名外不知道 t = list nat，裸列表偷渡不进来 *)
```

表示细节被彻底隐藏，外部只能走接口——这就是**抽象数据类型（ADT）**，而且是带正确性证明的：接口上的 `Axiom pop_push` 由 `Stack` 内的 `Theorem pop_push` 实现满足（封印时 Coq 检查过签名匹配）。换实现（比如改用函数表示的队列）只要仍满足签名，所有使用方无感——**签名是模块间的类型系统**。

### 18.6 本章坑位清单（实测）

1. **`plus_comm` 已不存在**：8.20 移除了旧别名，现名 `Nat.add_comm`；老教材（包括 Software Foundations 旧版）抄代码先 Check；
2. **`contradiction` 不认 `0 = 1`**：报 `No such contradiction`——它只找「上下文里的 False / 构造子直接冲突」，数字不同要 `discriminate`（实测）；
3. **auto 空转**：对需要归纳的目标 auto 无能为力（它不会 induction）——显然要归纳就别等 auto；
4. **`;` 把错误信息搞乱**：`destruct b; try rewrite H; try reflexivity.` 一长串组合，哪步失败难定位——调试时展开成分步，绿了再合并；
5. **封印后的模块看不到表示**：`SealedStack.t` 只是抽象 Type，想对实现做计算/证明得用未封印的原模块——封装与便利的取舍。

---
上一章：[17 · Option：安全建模](17-option.md) ｜ 下一章：[19 · Ltac：自定义策略](19-ltac.md) ｜ 返回：[README](../README.md)
