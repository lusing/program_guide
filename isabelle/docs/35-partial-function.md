# 35 · `partial_function` 深水区

对应示例：`../examples/T35_partial_function.thy`

## 35.1 一句话概括

`fun`/`function` 定义全函数，定义即承诺终止。部分函数
（"找不到就 None"）的落地三件套：`partial_function (option)`、
`(tailrec)`、手搓/库里的 while 组合子。核心心智模型：
**最小不动点 + 容许性（admissible）**——第 51 章 Knaster–Tarski
在 cpo 上的亲戚。

## 35.2 fun 拒绝不终止（实测报错全文）

```text
fun f where "f n = f n"
*** Unfinished subgoals:
*** Calls:
***   a) n ~> n
*** Measures:
*** Result matrix:
*** Could not find lexicographic termination order.
```

`Calls: a) n ~> n`——调用图上 n 映到 n 自己，任何度量都不降。
这是**定义时**被拒，不是运行时挂起；Isabelle 里没有"跑起来
才死"这回事。

## 35.3 第一个坑：只吃单条方程

`fun` 的多方程竖线在 `partial_function` 是**语法错误**
（实测 `command expected, but keyword |`）。一条方程 + `case` 折叠：

```isabelle
partial_function (option) findP where
  "findP p xs = (case xs of [] ⇒ None
     | x # xs' ⇒ if p x then Some x else findP p xs')"
```

定义后的事实清单 `find_theorems findP` 实测只有三条：

- `findP.simps`：单条展开方程（mono 后的）；
- `findP.raw_induct`：泛函形状归纳原理（对"候选函数"归纳）；
- `findP.fixp_induct`：不动点语义版，前提带 `option.admissible`。

**没有** `findP.pinduct`（实测 Undefined fact——手册旧版提法），
也没有 fun 式的多条 simps。

## 35.4 证明：结构归纳 + 逐步展开

`raw_induct` 的形状对 `induct rule:` 极不友好（实测：结论参差，
前提被错当结论，两种写法都配不上）。好消息：**尾递归**形状
（递归调用都在严格子结构上）用普通结构归纳 + `findP.simps` 就能证：

```isabelle
lemma findP_Some: "findP p xs = Some x ⟹ x ∈ set xs"
proof (induct xs)
  case Nil thus ?case by (simp add: findP.simps)
next
  case (Cons y ys) thus ?case
    by (auto simp: findP.simps split: if_splits)
qed
```

非尾递归（递归调用包在构造器里，如 `Some (f x + f y)`）才真需要
`raw_induct`/`fixp_induct`——那是 functions 手册第 3 章的深水区。

## 35.5 求值：code 方程要手动注册

第二个实测坑：直接 `value` 报 `No code equations for findP`。
partial_function 的方程默认不注册为代码方程：

```isabelle
declare findP.simps [code]

value "the (findP (λn. n > 2) [(1::nat), 2, 3, 4])"
(* "3" :: nat *)
```

## 35.6 tailrec 与手搓 while

`(tailrec)` 装的是尾递归单子，返回值直接是结果类型（不套 option），
不终止时值是 `undefined`。同样**单条方程**：

```isabelle
partial_function (tailrec) sum_acc :: "nat ⇒ nat list ⇒ nat" where
  "sum_acc acc xs = (case xs of [] ⇒ acc | x # xs' ⇒ sum_acc (acc + x) xs')"
```

while 组合子自己搓一个（Library 的 `while_option` 在
`HOL-Library.While_Combinator`，Main 里没有——见下坑）：

```isabelle
partial_function (option) mywhile :: "('a ⇒ bool) ⇒ ('a ⇒ 'a) ⇒ 'a ⇒ 'a option" where
  "mywhile b c s = (if b s then mywhile b c (c s) else Some s)"

declare mywhile.simps [code]

value "mywhile (λn. n ≠ (1::nat)) (λn. if even (n::nat) then n div 2 else 3 * n + 1) 6"
value "mywhile (λn. n > (0::nat)) (λn. n - 1) 3"
```

### 两个 lambda 都要标类型

只标外层 `nat` 的话，内层 `even n` 留下多态约束，`value` 报
`not of sort` 系列——第 3 章的老坑换了件衣服。

### 更阴的坑：未知常量被静默当自由变量

对 Library 的 `while_option`（不在 Main）跑 `value`，**不报错**：
被解析成自由变量，把你输入的项原样"求值"回来——输出是双引号
包着的原样项、类型挂着 `'b`。看到这个形状，先查常量在不在：

```text
"while_option (λu. u ≠ 1) (λu. ...) (1 + 1 + 1 + (1 + 1 + 1))"
  :: "'b"
```

## 35.7 重叠模式的 fun：一致就自动消歧

```isabelle
fun f where
  "f (Suc n) = n"
| "f n = 0"
```

两条方程重叠（第二条匹配一切），但重叠处取值一致——实测包自动
算出互斥化简方程（日志 `Found termination order: "{}"`，`f.simps`
是干净的两条：`f (Suc ?n) = ?n`、`f 0 = 0`）。重叠处**不一致**
（第二条改 `f n = n`）则定义被拒。

## 35.8 选型速查

| 场景 | 工具 | 章节 |
|---|---|---|
| 结构递归 | `primrec` | 5 |
| 自动终止性够用 | `fun` | 5 |
| 终止要手证 | `function` + `termination` | 15/16 |
| 可能"找不到" | `partial_function (option)` | 本章 |
| 尾循环语义 | `(tailrec)` / while | 本章/45 |
| 方程重叠但一致 | `fun` 自动消歧 | 35.7 |

## 35.9 坑位清单（实测）

1. **多方程竖线直接语法错误**：`partial_function` 只吃一条，
   `command expected, but keyword |`。
2. **`pinduct` 不存在**：归纳用 `raw_induct`（泛函形状）或对
   尾递归形式走结构归纳。
3. **code 方程不自动注册**：`declare foo.simps [code]` 补上才能
   `value`/`export_code`。
4. **未知常量静默变自由变量**：value 打印原样项 + 多态类型
   `'b`，是"常量不存在"的马脚（35.6）。
5. **lambda 少标一个类型**：内层约束留下多态，`not of sort` 报错。
6. **`raw_induct` 配 `induct rule:` 失败**：结论/前提形状对不上，
   两种流行写法都报错——别硬试，改结构归纳或 Isar 手摆。
7. **`(tailrec)` 的不终止值是 `undefined`**：不是 None！推理时
   `undefined` 参与的等式要靠 `option` 版避坑。
8. **重叠方程"一致"的判定是机器做的**：`f n = 0` 与 `f (Suc n) = n`
   在 0 处一致所以放行；人眼觉得"差不多"不行，机器逐点验证。
9. **partial_function 与 [simp]**：`foo.simps` 默认就是 simp 规则，
   但只在目标里出现 `foo` 应用时才展开——和 fun 的行为一致，
   以为"没展开"先看目标形状。
10. **option/tailrec 之外的 monad**：`(heap)` 等要 Library；
    干净的 Main 里就 option/tailrec 两个。

## 35.10 与其他章的接口

- 第 5/16 章 fun/function：全函数侧的正门。
- 第 51 章不动点：`partial_function` 的数学原型
  （`lfp`/容许性/Kleene 链）。
- 第 45 章 HOL-Library：`while_option`、`(heap)` monad 的家。
- 第 19 章代码生成：`[code]` 注册机制的总纲。
