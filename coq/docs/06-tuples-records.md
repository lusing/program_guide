# 06 · 元组与记录

对应示例：`../examples/06_tuples_records.v`

### 6.1 积类型 A * B：把两个值捆成一个

有了「或」（变体/构造子），还要有「且」——把两个类型的值**同时**放在一起。这就是积类型：

```coq
Check (3, true).              (* (3, true) : nat * bool *)
Definition p : nat * bool := (3, true).
```

`nat * bool` 读作「一个 nat **和**一个 bool」。它只有一个构造方式：写一对 `(a, b)`。拆开用两个投影函数：

```coq
Compute (fst p).              (* = 3 : nat —— 第一个分量 *)
Compute (snd p).              (* = true : bool —— 第二个分量 *)
```

两个提醒：

1. 这里的 `*` 是 **type_scope 里的积类型记号**，与乘法无关（`Locate "*"` 会列出所有解释）。数学上「A 和 B 的所有组合」正是笛卡尔积，记号由此得名；
2. `fst`/`snd` 只拆**最外层**。嵌套元组 `(nat * nat) * bool` 要连用：`fst (fst q)`。连续投影很快变得难读——这正是下一节 `let` 解构和 Record 存在的理由。

### 6.2 let 解构：给分量起名字

```coq
Compute (let (x, y) := p in if y then x else 0).   (* = 3 *)
```

`let (x, y) := p in ...` 把 p 拆成 x 和 y 再用——一次解构任意深度，比 `fst (fst ...)` 可读得多。嵌套照写：`let (a, (b, c)) := q in a + b + c`。

它和第 7 章的 match 一脉相承（`let (x, y) := e in body` 本质是 `match e with (x, y) => body end`），差别只是积类型**只有一个构造子**，无需多分支。

### 6.3 Record：带字段名的积类型

当元组超过两三元、或分量语义重要时，用 Record：

```coq
Record Point : Type := {
  px : nat;
  py : nat
}.
```

读法：定义类型 `Point`，它有 `px`、`py` 两个 **nat 类型的字段**。构造用 `{| 字段 := 值; ... |}`：

```coq
Definition origin : Point := {| px := 0; py := 0 |}.
Definition p1 : Point := {| px := 2; py := 5 |}.
```

字段名同时就是**投影函数**：

```coq
Compute (px p1).              (* = 2 *)
Compute (py p1).              (* = 5 *)
```

改「某个字段」没有原地修改（Coq 数据不可变）——造一个新值：

```coq
Definition move_x (p : Point) (dx : nat) : Point :=
  {| px := px p + dx; py := py p |}.

Example move_ex : move_x p1 3 = {| px := 5; py := 5 |}.
Proof. reflexivity. Qed.
```

### 6.4 Record 的真身：单构造子归纳类型

用 Print 揭底（实测）：

```coq
Print Point.
(* Inductive Point : Type := Build_Point : nat -> nat -> Point *)
```

Record 完全不是新机制——它就是一个**只有一个构造子**（自动命名 `Build_Point`）的 Inductive，字段名是给投影函数起的别名。所以第 9 章的一切（归纳原理、构造子纪律）对 Record 照样适用。反过来，理解了这一点，「参数化 Record」也不神秘：

```coq
Record Trio (A : Type) : Type := {
  first : A;
  second : A;
  third : A
}.

Definition t1 : Trio nat := {| first := 1; second := 2; third := 3 |}.
Definition t2 : Trio bool := {| first := true; second := false; third := true |}.
```

一个实测坑：参数化 Record 的投影自带**显式类型参数**——裸写 `first t1` 会报错说 `t1` 应当是 `Type`（Coq 想让你先给 A）。两种解法：

```coq
Compute (first _ t1).         (* 下划线：让推断补 *)
Arguments first {A}.          (* 或把 A 设为隐式，一劳永逸 *)
Compute (first t1).           (* = 1 *)
```

### 6.5 元组还是 Record？

| 场景 | 选择 |
|---|---|
| 匿名小组合、当场拆掉 | 元组：`(nat * bool)`、函数返回「(结果, 是否成功)」 |
| 多于 2–3 个分量 | Record（位置记忆负担太大） |
| 分量会增删、要可读 | Record（按名访问，增删字段不破坏使用点） |
| 中间层 AST 节点 | 常直接多参数构造子（第 19 章） |

### 6.6 本章坑位清单（实测）

1. **`fst`/`snd` 只拆最外层**：嵌套要 `fst (fst q)` 连用，改用 `let (a, (b, c)) := ...`；
2. **字段名全局唯一**：两个 Record 不能有同名字段，第二个直接报 `fx already exists`——字段是全局命名空间里的投影函数，命名要带前缀意识（`px`/`py` 而不是裸 `x`/`y`）；
3. **参数化 Record 投影带显式类型参数**：`first t1` 报错，要 `first _ t1` 或 `Arguments first {A}`；
4. **`A * B` 的 `*` 不是乘法**：作用域决定含义（第 5 章 5.1 节）。

---
上一章：[05 · 表达式与运算符](05-expressions.md) ｜ 下一章：[07 · 模式匹配](07-patterns.md) ｜ 返回：[README](../README.md)
