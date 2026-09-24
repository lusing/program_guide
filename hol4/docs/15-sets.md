# 15 · 集合与谓词

> 对应示例：[`examples/15_sets/15_sets.sml`](../examples/15_sets/15_sets.sml)

HOL4 里"集合"不是一种独立的数据结构 —— `α set` 就是 `α -> bool` 的**缩写**。
这一条决定了集合论在 HOL4 里的全部画风：集合运算就是逻辑运算，
集合相等就是谓词等价（`EXTENSION`）。

## 15.1 集合就是谓词

```text
类型      : :num -> bool
谓词即集合：:num -> bool
缩写展开  ：{x | x < 3}
```

```sml
val _ = out ("类型      : " ^ (type_of ``{} : num set`` |> type_to_string))
val _ = out ("谓词即集合：" ^ (type_of ``\x : num. x < 3`` |> type_to_string))
val _ = out ("缩写展开  ：" ^ term_to_string ``({x | x < (3 : num)} : num set)``)
```

三行说的是同一件事：

- `num set` 打印出来就是 `num -> bool`；
- 一个谓词 `\x. x < 3` 的类型也是 `num -> bool`；
- `{x | x < 3}` 这个"集合概括"符号，本质就是那个 `λ`。

所以：

| 集合运算 | 逻辑对应 |
|---|---|
| `x ∈ s` | `s x`（谓词在 x 上为真） |
| `s ∩ t` | `λx. s x ∧ t x` |
| `s ∪ t` | `λx. s x ∨ t x` |
| `COMPL s` | `λx. ¬ s x` |
| `s ⊆ t` | `∀x. s x ⇒ t x` |
| `{}` / `UNIV` | `λx. F` / `λx. T` |

**"集合"只是给谓词换了一身符号。** 想不通一个集合等式时，把它翻译成逻辑试试。

## 15.2 语法

```text
⊢ 1 ∈ {1; 2; 3} ⇔ T
⊢ {4; 1; 2; 3} = {4; 1; 2; 3}
⊢ {1; 2; 3} DELETE 1 = {2; 3}
UNION  : {1; 2} ∪ {3}
INTER  : {1; 2} ∩ {2; 3}
DIFF   : {1; 2} DIFF {2}
IMAGE  : IMAGE (λx. x + 1) {1; 2}
⊢ {1; 2} ⊆ {1; 2; 3} ⇔ T
⊢ CARD {1; 2; 3} = 3
⊢ FINITE {1; 2; 3} ⇔ T
⊢ {1; 2} ⊂ {1; 2; 3} ⇔ T
```

```sml
fun ev t = thm_to_string (EVAL t)
val _ = out (ev ``(1 : num) IN {1; 2; 3}``)
val _ = out (ev ``(4 : num) INSERT {1; 2; 3}``)
val _ = out ("UNION  : " ^ (term_to_string ``({1; 2} : num set) UNION {3}``))
```

| 写法 | 含义 |
|---|---|
| `{1; 2; 3}` | 有限集字面量（`INSERT` 的语法糖） |
| `x INSERT s` | 插入 |
| `s DELETE x` | 删除 |
| `s UNION t` / `s INTER t` / `s DIFF t` | 并 / 交 / 差（打印成 `∪` `∩`） |
| `COMPL s` | 补集 |
| `IMAGE f s` | 像 |
| `s SUBSET t` / `s PSUBSET t` | 子集 / 真子集（打印成 `⊆` `⊂`） |
| `CARD s` | 基数（元素个数） |
| `FINITE s` | 是否有限 |

两处"打印 ≠ 源码"的老问题：源码写 `UNION` / `INTER` / `SUBSET` / `PSUBSET`，
打印出来分别是 `∪` / `∩` / `⊆` / `⊂`。**照着打印结果抄回源码会 parse 不了。**

注意 `UNION` / `INTER` / `DIFF` / `IMAGE` 这几行打印的是**项本身**而不是求值结果：
它们的定义里含 `λ`，`EVAL` 展不出更有信息量的形状，所以这几行直接用
`term_to_string` 看长相就够了。

## 15.3 外延性

```text
⊢ ∀s t. s = t ⇔ ∀x. x ∈ s ⇔ x ∈ t
⊢ ∀s t. s = t ⇔ ∀x. x ∈ s ⇔ x ∈ t
```

```sml
val _ = out (thm_to_string EXTENSION)
val _ = out (p ``!s t : num set. s = t <=> !x. x IN s <=> x IN t`` (metis_tac [EXTENSION]))
```

`EXTENSION` 是集合论里最常用的一条定理：**两个集合相等，当且仅当元素逐个等价。**
它把"集合相等"化归成"命题等价"，于是集合等式可以用命题逻辑的工具证。

第二行演示它可以被 `metis` 直接用（虽然结论和第一条一模一样 ——
这里只是为了说明 `EXTENSION` 是普通定理，不是什么内置机制）。

## 15.4 集合上的证明

```text
⊢ ∀s t u. s ∩ (t ∪ u) = s ∩ t ∪ s ∩ u
⊢ ∀s t. COMPL (s ∪ t) = COMPL s ∩ COMPL t
⊢ ∀f s t. IMAGE f (s ∪ t) = IMAGE f s ∪ IMAGE f t
```

```sml
val _ = out (p ``!(s : num set) t u. s INTER (t UNION u) =
                  (s INTER t) UNION (s INTER u)``
               (rw [EXTENSION] >> metis_tac []))
val _ = out (p ``!f : num -> num. !s t. IMAGE f (s UNION t) = IMAGE f s UNION IMAGE f t``
               (rw [EXTENSION] >> metis_tac []))
```

三个证明**一模一样**：`rw [EXTENSION] >> metis_tac []`。这是集合证明的通用套路：

1. `rw [EXTENSION]` —— 把集合相等展开成"任取元素 x，两边同时为真"，
   再把 `∈` 上的 `∩` `∪` `∁` `IMAGE` 全化掉，剩下一个纯命题；
2. `metis_tac []` —— 把这个纯命题证掉。

第二条（德摩根律）里出现了 `∃`：`x ∈ IMAGE f s` 展开成 `∃y. y ∈ s ∧ f y = x`。
`rw` 会把 `∃` 留在那儿，`metis_tac` 能自己处理它 —— 这是
"`rw` 先展开、`metis` 再收尾"这个组合最好用的一类场景。

## 15.5 有限集与基数

```text
⊢ ∀s. FINITE s ⇒
      ∀x. CARD (x INSERT s) = if x ∈ s then CARD s else SUC (CARD s)
⊢ ∀s. FINITE s ⇒ CARD (0 INSERT s) ≤ CARD s + 1
列表转集合的项：set_of_list [1; 2; 3]
求值（注意结果）：
  set_of_list [1; 2; 3] = {1; 2; 3} ⇔
set_of_list [1; 2; 3] ⊆ {1; 2; 3} ∧ 1 ∈ set_of_list [1; 2; 3] ∧
2 ∈ set_of_list [1; 2; 3] ∧ 3 ∈ set_of_list [1; 2; 3]
```

```sml
val _ = out (thm_to_string CARD_INSERT)
val _ = out (p ``!s : num set. FINITE s ==> CARD ((0 : num) INSERT s) <= CARD s + 1``
               (rw [CARD_INSERT]))
val _ = out ("  " ^ eval1 ``set_of_list [1; 2; 3] = ({1; 2; 3} : num set)``)
```

`CARD_INSERT` 是基数的核心定理，注意它的 `if`：**插一个已有的元素，基数不变。**
它带 `FINITE s` 前提 —— 无限集的基数在 `pred_setTheory` 里就是 0，加元素没意义。

第二个证明 `rw [CARD_INSERT]` 一步过，因为 `rw` 会分 `0 ∈ s` 的情况，
两种情况都落到 `≤` 的算术上。

最后这块输出值得好好看一眼。**`EVAL` 证不出两个集合相等。**
它把 `set_of_list [1;2;3] = {1;2;3}` 化成了右边那一串逐点条件
（"互相包含"加"三个元素都在里面"），然后就停住了 ——
因为这些条件里还有 `set_of_list` 的递归结构没被消掉。

这正是"集合 = 谓词"的直接后果：**集合相等是外延的、不可计算的。**
想证集合相等，走 15.4 那条路（`rw [EXTENSION]`），别指望 `EVAL`。

## 15.6 化简器认识集合

```text
⊢ ∀x. x ∈ ∅ ⇔ F
⊢ ∀s. s ⊆ s
⊢ ∀x s. x ∈ s ⇒ x ∈ s ∪ {x}
```

```sml
val _ = out (p ``!x : num. x IN ({} : num set) <=> F`` (rw []))
val _ = out (p ``!s : num set. s SUBSET s`` (rw []))
val _ = out (p ``!x : num. !s. x IN s ==> x IN (s UNION {x})`` (rw []))
```

`rw []` 里**已经装着** `∈` 在 `∅` `INSERT` `UNION` `INTER` `COMPL` `IMAGE` 上的
那批化简定理，所以上面三条都不用额外列定理。

反过来，涉及 `CARD` / `FINITE` / `DELETE` / `DIFF` 的定理**不在**默认 simpset 里，
要手动 `rw [CARD_INSERT]` 这样喂进去。这是集合证明里最常见的"为什么 `rw` 不动"的原因。

## 15.7 坑位清单

1. **`α set` 就是 `α -> bool`** → 集合运算全是逻辑运算，集合相等是外延的。
2. **源码写 `UNION`/`INTER`/`SUBSET`/`PSUBSET`** → 打印成 `∪`/`∩`/`⊆`/`⊂`，别照抄回去。
3. **`EVAL` 证不出集合相等** → 它只会展开成逐点条件；用 `rw [EXTENSION]`。
4. **`CARD_INSERT` 带 `FINITE` 前提** → 无限集的 `CARD` 是 0，定理不适用。
5. **`CARD (x INSERT s)` 有个 `if x ∈ s`** → 插已有元素基数不变。
6. **`CARD`/`FINITE`/`DELETE`/`DIFF` 的定理不在默认 simpset 里** → 要手动列。
7. **`IMAGE` 展开会引入 `∃`** → 交给 `metis_tac` 处理（`rw` 会把它留在原地）。
8. **`{x | P x}` 就是 `\x. P x`** → 集合概括没有额外的机制。
9. **`∅` 的类型常常推不出来** → 空集要写类型标注 `({} : num set)`。
10. **`COMPL` 是相对 `UNIV` 的补** → 没有"全集之外的东西"。

---

上一章：[14 · 量词与一阶自动化](14-quantifiers.md) ·
下一章：[16 · 关系与闭包](16-relations.md)
