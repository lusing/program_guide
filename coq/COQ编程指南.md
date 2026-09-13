# Coq 编程指南（Windows）

本教程配套示例均在 [examples/](./examples/) 下，并可用 `coqc` 批量编译验证。

## 目录

1. [环境准备](#环境准备)
2. [基础语法与计算](#基础语法与计算)
3. [归纳定义与归纳证明](#归纳定义与归纳证明)
4. [列表与递归函数](#列表与递归函数)
5. [布尔与自然数](#布尔与自然数)
6. [Record 记录类型](#record-记录类型)
7. [Option 安全建模](#option-安全建模)
8. [高阶函数](#高阶函数)
9. [命题逻辑证明](#命题逻辑证明)
10. [模块化组织](#模块化组织)
11. [统一编译验证](#统一编译验证)

---

## 环境准备

- Coq 安装目录：`G:\scoop\apps\coq\current`
- 编译器：`G:\scoop\apps\coq\current\bin\coqc.exe`

检查版本：

```powershell
G:\scoop\apps\coq\current\bin\coqc.exe --version
```

---

## 基础语法与计算

源码：`examples/01_basics.v`

```coq
From Coq Require Import Arith.
From Coq Require Import Bool.

Definition square (n : nat) : nat := n * n.

Example plus_1_2 : 1 + 2 = 3.
Proof. reflexivity. Qed.

Example square_3 : square 3 = 9.
Proof. reflexivity. Qed.
```

要点：
- `Definition` 定义可计算对象
- `Example` + `Proof ... Qed` 表达可验证断言

---

## 归纳定义与归纳证明

源码：`examples/02_induction.v`

```coq
Fixpoint sum_to (n : nat) : nat :=
  match n with
  | 0 => 0
  | S k => n + sum_to k
  end.

Theorem plus_n_O : forall n, n + 0 = n.
Proof.
  induction n as [|n IH].
  - reflexivity.
  - simpl. rewrite IH. reflexivity.
Qed.
```

要点：
- `Fixpoint` 表达递归定义
- `induction` 是证明自然数性质的核心策略

---

## 列表与递归函数

源码：`examples/03_lists.v`

```coq
From Coq Require Import List.
Import ListNotations.

Fixpoint my_length {A : Type} (xs : list A) : nat :=
  match xs with
  | [] => 0
  | _ :: tl => S (my_length tl)
  end.
```

要点：
- `Import ListNotations` 启用 `[]`、`::`、`[a;b;c]` 语法
- 参数 `{A : Type}` 表示隐式类型参数

---

## 布尔与自然数

源码：`examples/04_bool_nat.v`

```coq
Definition is_zero (n : nat) : bool :=
  match n with
  | 0 => true
  | _ => false
  end.

Theorem is_zero_S : forall n, is_zero (S n) = false.
Proof.
  intros n.
  reflexivity.
Qed.
```

要点：
- `match` 是结构化分支
- `intros` 将前提引入上下文

---

## Record 记录类型

源码：`examples/05_records.v`

```coq
Record Point : Type := {
  px : nat;
  py : nat
}.
```

要点：
- `Record` 可用于数据建模
- 字段函数（如 `px`）可直接投影

---

## Option 安全建模

源码：`examples/06_option.v`

```coq
Definition head_nat (xs : list nat) : option nat :=
  match xs with
  | [] => None
  | h :: _ => Some h
  end.
```

要点：
- `option` 避免“空值异常”风格错误
- `None/Some` 明确表达是否有结果

---

## 高阶函数

源码：`examples/07_higher_order.v`

```coq
Definition inc_all (xs : list nat) : list nat :=
  map (fun n => S n) xs.

Definition sum_all (xs : list nat) : nat :=
  fold_right Nat.add 0 xs.
```

要点：
- `map` 做逐项变换
- `fold_right` 做归约聚合

---

## 命题逻辑证明

源码：`examples/08_logic.v`

```coq
Theorem and_comm : forall P Q : Prop, P /\ Q -> Q /\ P.
Proof.
  intros P Q H.
  destruct H as [HP HQ].
  split.
  - exact HQ.
  - exact HP.
Qed.
```

要点：
- `destruct` 拆分合取前提
- `split` 构造合取目标

---

## 模块化组织

源码：`examples/09_modules.v`

```coq
Module NatStack.
Definition stack := list nat.
Definition empty : stack := [].
Definition push (x : nat) (s : stack) : stack := x :: s.
End NatStack.
```

要点：
- `Module ... End` 管理命名空间
- 适合按主题组织定理与定义

---

## 统一编译验证

在 `G:\code\guide\coq` 下执行：

```powershell
.\build.ps1 -All
```

编译单文件：

```powershell
.\build.ps1 -File 09_modules.v
```

清理：

```powershell
.\build.ps1 -Clean
```

