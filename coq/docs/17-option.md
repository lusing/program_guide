# 17 · Option：安全建模

对应示例：`../examples/17_option.v`

### 17.1 用类型消灭一类错误

「查无此值」是程序错误的经典来源：空列表取头、字典查不存在的键、除以零。主流语言的方案——返回 NULL（C）、抛异常（Java）、返回 undefined（JS）——共同问题：**调用方可以装作不会失败**，类型系统不设防。

Coq 的方案是把「可能没有」编码进类型：

```coq
Inductive option (A : Type) : Type :=
  | Some : A -> option A
  | None : option A.
```

`option nat` 的每个值要么是 `Some n`（有货），要么是 `None`（没货）——**想拿到里面的 nat，必须 match，必须处理 None 分支**（穷尽性检查强制）。错误从「运行时意外」变成「编译期必须回答的问题」。对比第 8 章的 `nth`（越界静默给默认值——错误被吞），option 版干净得多：

```coq
Fixpoint nth_option {A : Type} (n : nat) (xs : list A) : option A :=
  match n, xs with
  | O, x :: _ => Some x
  | S k, _ :: tl => nth_option k tl
  | _, _ => None
  end.

Compute (nth_option 5 [10; 20; 30]).   (* = None —— 越界明说 *)
```

这个 match 的 `,` 双 scrutinee 语法第 7 章见过；`_, _` 兜底组合「越界」与「列表太短」两种失败。

### 17.2 option 上的三个基本操作

拿到 option 后的三种典型处理，全部是普通函数：

```coq
Definition option_map {A B : Type} (f : A -> B) (o : option A) : option B :=
  match o with
  | Some x => Some (f x)
  | None => None
  end.

Definition default {A : Type} (d : A) (o : option A) : A :=
  match o with
  | Some x => x
  | None => d
  end.

Definition bind {A B : Type} (o : option A) (f : A -> option B) : option B :=
  match o with
  | Some x => f x
  | None => None
  end.
```

- **`option_map`**：对有货的做变换，没货的原样传播失败——「成功的路径上加工」；
- **`default`**：显式兜底——「我现在必须要一个值，取不到就用这个」，把第 8 章 `nth` 隐式做的事变成明说；
- **`bind`**：串联可能失败的计算——上一步有货就喂给下一步，没货整个链条直接 None（这就是 monad 的 `bind`，不用记名词，记住行为）。

### 17.3 链式：安全除法流水线

实战看效果——「取列表前两个元素相除」，任何一步失败整体就 None：

```coq
Definition safe_div (a b : nat) : option nat :=
  if Nat.eqb b 0 then None else Some (a / b).

Definition div_heads (xs : list nat) : option nat :=
  bind (nth_option 0 xs) (fun a =>
    bind (nth_option 1 xs) (fun b => safe_div a b)).

Compute (div_heads [10; 2]).    (* = Some 5 *)
Compute (div_heads [10]).       (* = None —— 第二个元素不存在 *)
Compute (div_heads [10; 0]).    (* = None —— 除零 *)
```

对照命令式写法（取头、判空、取次、判空、判除零……），bind 版把「失败传播」的样板全部收进一个组合子，业务逻辑一行陈述。这正是 Rust 的 `?`、Swift 的可选链、Haskell 的 Maybe monad 同款思想——**Coq 里它只是个普通函数**。

### 17.4 option 的定律

option 同样有可证的定律（示例 17）：

```coq
Theorem option_map_id : forall (A : Type) (o : option A),
  option_map (fun x => x) o = o.
Proof.
  intros A o. destruct o.
  - reflexivity.
  - reflexivity.
Qed.
```

对 o 分情况（Some/None）——**不需要归纳**（option 不是递归类型，没有「更小的 option」）。这提示一条选择法则：数据是一层还是多层，决定 destruct 还是 induction。

更有营养的是 `nth_option` 与 `map` 的交换律（对第 n 个取值，先后做 map 结果一样）：

```coq
Theorem nth_option_map : forall (A B : Type) (f : A -> B)
                                   (n : nat) (xs : list A),
  option_map f (nth_option n xs) = nth_option n (map f xs).
Proof.
  intros A B f n. induction n as [| n IH]; intros xs.
  - destruct xs as [| x tl].
    + reflexivity.
    + reflexivity.
  - destruct xs as [| x tl].
    + reflexivity.
    + simpl. apply IH.
Qed.
```

注意结构：**对 n 归纳、对 xs 分情况**——两个维度各司其职。以及一个重要的细节：`intros xs` 放在 `induction n` **之后**——归纳时 xs 留在目标里保持任意，于是 IH 是「对**所有** xs 成立」，步例里才能 `apply IH` 用在 tail 上。这正是第 12 章坑 2 的正面示范：**要归纳的变量先动，其余维度后收**。

### 17.5 什么时候用 option

| 场景 | 用法 |
|---|---|
| 查找类（head/nth/lookup） | 返回 option，失败显式 |
| 可能失败的计算（除法、解析） | option + bind 串联 |
| 调用方有合理默认值 | 在**调用处** `default`，不要在 API 里吞错 |
| 失败需要携带原因 | 变体类型 `Inductive result := Ok : A -> result \| Err : string -> result`（第 24 章用到类似手法） |

原则一句话：**让失败在类型里可见，在最近的地方处理**。

### 17.6 本章坑位清单（实测）

1. **`default` 放错层**：在库函数内部 default 会把「调用方该知道的失败」吞掉——兜底永远放在使用现场；
2. **忘记 bind 的短路语义**：链条里任何 None 都让整体 None——调试时从最前端的 None 查起；
3. **对 option 归纳**：option 无递归结构，`induction o` 没有意义（构造子的参数不是 option）——destruct 就够；
4. **`nth_option` 证明里 intros 顺序**：先 `intros xs` 再 `induction n` 会把 IH 锁死在具体 xs 上（第 12 章坑 2 的变体，17.4 有完整对照）。

---
上一章：[16 · 高阶函数及其证明](16-higher-order.md) ｜ 下一章：[18 · 策略武器库与模块](18-tactics-modules.md) ｜ 返回：[README](../README.md)
