# 18 · 速查表

一页查全：语法、算子、标准库、cfg 关键字、命令。详细讲解见对应章节。

## 模块骨架

```tla
---------------------------- MODULE Name ----------------------------
\* 模块名 = 文件名（Name.tla），且必须是合法标识符：不能数字开头、不含连字符
EXTENDS Integers, Sequences, FiniteSets, TLC
CONSTANT K                  \* 模型常量，值在 .cfg 里给
VARIABLES x, y
vars == <<x, y>>
Init == ...                 \* 未加撇变量的谓词
Action == ...               \* 含加撇变量的谓词
Next == Action1 \/ Action2
Spec == Init /\ [][Next]_vars
Inv == ...                  \* 不变式（状态谓词）
=============================================================================
```

## 值与运算符

| 写法 | 含义 |
|---|---|
| `Op(x) == e` | 定义算子（函数） |
| `LET d == e IN body` | 局部定义 |
| `IF c THEN a ELSE b` | 条件表达式 |
| `CASE c1->e1 [] c2->e2 [] OTHER->e3` | 多分支 |
| `RECURSIVE F(_)` + `F(n) == ...F(n-1)` | 递归算子 |
| `CHOOSE x \in S : P` | 选一个满足 P 的元素 |
| `f[x]`、`r.field` | 函数应用 / 记录取字段 |
| `[f EXCEPT ![a]=v]`、`[r EXCEPT !.k=v]` | 改一个点，得新值 |

## 算术（实测语义）

| 写法 | 含义 | 坑 |
|---|---|---|
| `+ - *` | 加减乘 | |
| `a \div b` | 整数除 | **向零截断**：`-3 \div 2 = -1` |
| `a % b` | 取余 | **b 必须为正**，结果在 `0..(b-1)`：`-3 % 2 = 1` |
| `a..b` | 整数集合 `{a,...,b}` | |
| `Nat` / `Int` | 自然数 / 整数集合 | `Int` 无限 |

## 集合 / 序列 / 函数 / 记录

| 写法 | 含义 |
|---|---|
| `{1,2,3}`、`{}` | 集合（无序无重复）/ 空集 |
| `x \in S`、`x \notin S` | 属于 / 不属于 |
| `S \cup T`、`S \intersect T`、`S \ T` | 并 / 交 / 差 |
| `S \subseteq T` | 子集 |
| `{x \in S : P}` | 筛选（filter） |
| `{f(x) : x \in S}` | 映射（map） |
| `{f(x,y) : x \in S, y \in T}` | 笛卡尔积构造 |
| `SUBSET S`、`UNION S` | 幂集 / 摊平 |
| `Cardinality(S)`、`IsFiniteSet(S)` | 基数 / 是否有限（FiniteSets） |
| `<<1,2,3>>`、`<<>>` | 序列 / 空序列 |
| `Len`、`Head`、`Tail`、`Append`、`\o`、`SubSeq` | 序列操作（Sequences） |
| `Seq(S)` | S 上所有有限序列的集合 |
| `[x \in S |-> e]` | 构造函数 |
| `[S -> T]` | 所有 S→T 函数的集合 |
| `DOMAIN f` | 定义域 |
| `[a|->1, b|->2]` | 记录 |

## 逻辑与量词

| 写法 | ASCII | 含义 |
|---|---|---|
| `/\` | `\land` | 与 |
| `\/` | `\lor` | 或 |
| `~` | `\lnot` | 非 |
| `=>` | | 蕴含 |
| `<=>` | | 等价 |
| `\A x \in S : P` | | 全称（空集恒真） |
| `\E x \in S : P` | | 存在（空集恒假） |
| `=`、`#`/`/=` | | 等于 / 不等于 |
| `TRUE`、`FALSE`、`BOOLEAN` | | 布尔值 / `{TRUE,FALSE}` |

## 时序算子

| 写法 | 含义 |
|---|---|
| `[]P` | always（每个状态都成立）——安全性 |
| `<>P` | eventually（某刻成立）——活性 |
| `[]<>P` | infinitely often（无限次） |
| `<>[]P` | eventually always（终归一直） |
| `[A]_v` | `A \/ (v'=v)`（走 A 或空转） |
| `<<A>>_v` | `A /\ (v'#v)`（走 A 且改变 v） |
| `ENABLED A` | 动作 A 在当前状态使能 |
| `WF_v(A)` / `SF_v(A)` | 弱 / 强公平性 |
| `v'` | 下一步的 v（prime） |
| `UNCHANGED v` | `v' = v` |

## .cfg 关键字

| 关键字 | 用途 |
|---|---|
| `INIT Init` | 指定初始谓词（查安全性常用） |
| `NEXT Next` | 指定后继动作（配合 INIT） |
| `SPECIFICATION Spec` | 指定完整时序公式（查活性/时序性质时用） |
| `INVARIANT I` | 检查状态不变式 I |
| `PROPERTY P` | 检查一般时序公式 P |
| `CONSTANT K = v` | 给模型常量赋值（`K = {1,2}`、`K <- ModelValue`） |
| `CONSTRAINT C` | 状态约束，剪枝（截断无限状态空间） |
| `ASSUMPTION A` | 假设（前提，不验证） |
| `SYMMETRY S` | 对称集，加速 |

> `INIT`/`NEXT` 与 `SPECIFICATION` 二选一，不要同时给。

## PlusCal（C 语法）

```tla
(* --fair algorithm Name {
  variables g = 0;                 \* 全局变量
  process (P \in {1,2})            \* 多进程
  variable loc = "a";              \* per-process 变量：写在 process 与 { 之间！
  {
    L1: while (x > 0) {            \* 标签 L1 划定原子步
          await (cond);            \* 阻塞等待
          x := x - 1;              \* 赋值 :=
          if (c) { ... } else { ... }
          either { A } or { B }    \* 非确定选择
        }
    L2: skip;                      \* 空语句也要占一个标签
  }
} *)
```

| 元素 | 说明 |
|---|---|
| `:=` | 赋值（翻译成 `x' = ...`） |
| `await P` / `wait P` | 阻塞至 P 为真 |
| 标签 `L:` | 原子步边界 |
| `self` | 当前进程 id |
| `either {...} or {...}` | 非确定分支 |
| `with (v = e) {...}` | 临时局部变量 |
| `print e;` | 翻译成 `PrintT` |
| `--fair` | 生成带公平性的 Spec |

## 命令

```bash
JAR="/Applications/TLA+ Toolbox 2.app/Contents/Eclipse/tla2tools.jar"

# 模型检查
java -XX:+UseParallelGC -cp "$JAR" tlc2.TLC Spec.tla
# 常用 TLC 选项
#   -workers auto   多核并行
#   -cleanup        跑完删中间状态文件
#   -deadlock       关闭死锁检查（不推荐，除非确知会终止）
#   -config X.cfg   指定配置文件
#   -dump           只解析不检查

# PlusCal 翻译（就地改写 .tla）
java -cp "$JAR" pcal.trans Spec.tla

# 一键回归
./run-all.sh           # 全部
./run-all.sh -v 13     # 单个 + 详细输出
```

---
上一章：[17 · 竞态条件](17-race-condition.md) ｜ 下一章：[19 · 坑清单与常见错误](19-pitfalls.md) ｜ 返回：[README](../README.md)
