# 07 · 模式匹配

对应示例：`../examples/07_patterns.v`

### 7.1 match：按形状分支

第 5 章说过 if 是「两构造子 match 的糖」。现在看正版：

```coq
Definition is_zero (n : nat) : bool :=
  match n with
  | O => true
  | S _ => false      (* S 后面的分量用通配符 _ 忽略 *)
  end.
```

读法：拿 n 的**形状**和每个分支的模式比对，用第一个匹配的分支。`O` 是构造子模式（零）；`S _` 是「S 套着任何东西」——下划线是通配符，绑定但不使用。

match 是 Coq 数据处理的**唯一**分支原语（if、let 解构都是它的糖衣）。它同时做三件事：

1. **测试**：值是哪个构造子造的？
2. **拆解**：把构造子的参数绑定到模式变量；
3. **保证穷尽**：编译器检查所有构造子都有分支。

第 3 条是 Coq 相对 C/Java switch 的本质优势：**你新加一个构造子，所有漏掉它的 match 当场编译失败**——重构的安全网。

### 7.2 模式词汇表

```coq
Definition classify (n : nat) : nat :=
  match n with
  | 0 => 0             (* 字面量 0 —— 就是 O *)
  | 1 => 1             (* 字面量 1 —— 就是 S O *)
  | 2 => 2
  | S (S (S _)) => 3   (* 嵌套模式：≥ 3 *)
  end.
```

| 模式 | 写法 | 作用 |
|---|---|---|
| 构造子 | `O`、`S k`、`Some x` | 匹配该构造子并拆参数 |
| 变量 | `k`、`x` | 匹配任意值并绑定（可使用） |
| 通配符 | `_` | 匹配任意值、不绑定 |
| 字面量 | `0`、`1`、`2` | 构造子的数字记号（nat 专用糖） |
| 元组 | `(a, b)` | 拆积类型 |
| 嵌套 | `S (S (S _))`、`_ :: y :: _` | 一次拆多层 |
| 多 scrutinee | `match a, b with \| true, true => ...` | 同时匹配多个值 |

两个细节：

- **字面量模式能到多深？** `2` 可以（S (S O)），但只能用于「小数字」——它就是记号展开，写 `| 5 => ...` 完全合法，Coq 会展开成 `S (S (S (S (S O))))`；
- **or 模式（`| A \| B => ...`）在 Coq 核心语法里不存在**（OCaml/Haskell 有）。想合并分支只能重复写或用通配符放宽——这是从那两门语言过来的一个真实不便。

### 7.3 嵌套与多 scrutinee

列表的「第二个元素」用嵌套模式一步到位：

```coq
Definition second (xs : list nat) : option nat :=
  match xs with
  | _ :: y :: _ => Some y    (* 至少两个元素，取第二个 *)
  | _ => None
  end.
```

一次匹配两个值（bool 的「与」）：

```coq
Definition both (b1 b2 : bool) : bool :=
  match b1, b2 with
  | true, true => true
  | _, _ => false
  end.
```

元组解构在 match 里最自然：

```coq
Definition add3 (p : nat * (nat * nat)) : nat :=
  match p with
  | (a, (b, c)) => a + b + c
  end.
```

### 7.4 穷尽性：漏分支 = 编译错误（实测）

```coq
Fail Definition missing (b : bool) : nat :=
  match b with
  | true => 1
  end.
(* Non exhaustive pattern-matching: no clause found for pattern "false" *)
```

错误信息直接**点名缺哪个构造子**。反过来说：只要编译通过，就没有「忘了处理某种情况」这类 bug——这一保证贯穿全书，是 Coq 值得忍受「啰嗦」的头号回报。

### 7.5 冗余分支：也是编译错误（实测，8.20/9.1）

写多了同样不行：

```coq
Fail Definition redundant (b : bool) : nat :=
  match b with
  | true => 1
  | false => 2
  | _ => 3       (* 前两支已覆盖全部 —— 这支永不可达 *)
  end.
(* Pattern "_" is redundant in this clause. *)
```

死分支是错误不是警告。好处：读代码时**每个分支都可信**，不存在「其实永远走不到」的暗桩；代价：合并分支时得留心顺序（先具体后宽泛，通配符只能垫底）。

### 7.6 match 是表达式

match 有值、有类型，可以出现在任何表达式位置：

```coq
Compute (match 3 with 0 => 0 | S _ => 1 end).   (* = 1 *)
```

没有「语句版 match」，不存在 break/fallthrough（C 的 switch 两大事故源在类型层面根除）。所有分支必须返回**同一类型**——`| true => 1 | false => "x"` 会报类型不匹配，把「分支结果类型不一致」从运行时隐患变成编译期错误。

### 7.7 模式变量与遮蔽

分支里绑定的变量**遮蔽**（shadow）外层同名变量：

```coq
Definition f (n : nat) : nat :=
  match n with
  | S n => n      (* 这个 n 是 S 拆出来的分量，不是外层参数 *)
  | O => 0
  end.
```

合法但可读性差，本教程不这么写。命名习惯：模式变量用新名字（`k`、`tl`、`rest`），与外层区分。

### 7.8 本章坑位清单（实测）

1. **漏分支**：`Non exhaustive pattern-matching`——错误信息会指出缺的构造子，补上即可；
2. **冗余分支**：`Pattern "..." is redundant in this clause`——8.20/9.1 里是错误不是警告；分支从具体到宽泛排，`_` 垫底；
3. **没有 or 模式**：`| x | y => ...` 写不了，与 OCaml/Haskell 不同；
4. **模式变量遮蔽外层**：合法但易错，改用新名字；
5. **分支类型不一致**：所有分支必须同类型，混搭是编译错误（这通常是好事）。

---
上一章：[06 · 元组与记录](06-tuples-records.md) ｜ 下一章：[08 · 列表](08-lists.md) ｜ 返回：[README](../README.md)
