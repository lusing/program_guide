# 19 · 类型与类型缩写

> 对应示例：[`examples/19_types/19_types.sml`](../examples/19_types/19_types.sml)

HOL 的项是**先有类型再有含义**的：`1 + T` 连"错"都算不上，
它根本不是一个项。这一章看类型的读法、类型缩写、参数化数据类型，
以及 HOL 里一个很硬的约束：**类型变量不能被"定义"出来。**

## 19.1 类型怎么看

```text
``:num``        : :num
``:bool``       : :bool
``:num -> num`` : :num -> num
``:num # bool`` : :num # bool
``:num list``   : :num list
``:'a``         : :α
type_of ``1``           : :num
type_of ``\x. x``      : :α -> α
type_of ``MAP``         : :(α -> β) -> α list -> β list
type_of ``\x. x + 1``  : :num -> num
``1`` 不带标注时是 : :num
（数字默认 num，比较运算会把它钉成 num；真正的多态常量如 MAP 打印出 α β。）
```

```sml
fun ty t = type_to_string (type_of t)      (* 项的类型的字符串 *)
fun tyq q = type_to_string q               (* 类型引号的字符串 *)
val _ = out ("``:num list``   : " ^ tyq ``:num list``)
val _ = out ("type_of ``MAP``         : " ^ ty ``MAP``)
```

类型引号的写法是 `` `:类型` ``（反引号 + 冒号），注意跟项引号 `` `…` `` 区分：

| 引号 | 类型 | 例子 |
|---|---|---|
| ``` ``…`` ``` | `term` | ``` ``1 + 2`` ``` |
| ``` ``:…`` ``` | `hol_type` | ``` ``:num -> num`` ``` |

看类型的两个函数是 `type_of : term -> hol_type` 和 `type_to_string`。

打印时类型变量显示成希腊字母 `α` `β`（源码里写 `'a` `'b`）。
最后两行提醒了一件事：**数字字面量默认是 `num`**，
所以 `\x. x + 1` 的类型被 `+` 钉成了 `num -> num`，而 `\x. x` 是多态的 `α -> α`。

## 19.2 拆开一个类型

```text
dest_type ``:num list`` = list [:num]
dom_rng ``:num -> bool`` 的定义域 = :num
dom_rng ``:num -> bool`` 的值域 = :bool
is_vartype ``:'a``  = true
is_vartype ``:num`` = false
```

```sml
val _ = out ("dest_type ``:num list`` = " ^
  (let val (s, l) = dest_type ``:num list``
   in s ^ " [" ^ String.concatWith ", " (map type_to_string l) ^ "]" end))
val _ = out ("dom_rng ``:num -> bool`` 的定义域 = " ^
             type_to_string (#1 (dom_rng ``:num -> bool``)))
val _ = out ("is_vartype ``:'a``  = " ^ Bool.toString (is_vartype ``:'a``))
```

写元程序（自己构造项/证明的工具）时要拆类型，三个函数就够：

| 函数 | 类型 | 作用 |
|---|---|---|
| `dest_type` | `hol_type -> string * hol_type list` | 拆成"类型构造子名 + 参数列表" |
| `dom_rng` | `hol_type -> hol_type * hol_type` | 拆函数类型的定义域与值域 |
| `is_vartype` | `hol_type -> bool` | 是不是类型变量 |

`dest_type ``:num list``` 给出 `("list", [`:num`])`，也就是上面打印的 `list [:num]`。

## 19.3 类型不匹配

```text
拿 bool 当 num 用，mk_comb 直接拒绝：
  <
Exception raised at Term.mk_comb: incompatible types
>
注意措辞是 incompatible types —— 它连算一算都不肯，因为项根本没构造出来。
反过来，类型对了才能谈值：
  1 + 2 = 3
```

```sml
val _ = out ("  " ^ ((term_to_string (mk_comb (``$+ : num -> num -> num``, ``T``)))
                     handle e => "<" ^ exn_to_string e ^ ">"))
```

这一节演示 HOL 里最"硬"的一类错误：把 `bool` 当 `num` 用。
注意错误信息是 **incompatible types**，来自 `Term.mk_comb` ——
也就是**构造项的时候就拒绝了**，根本没走到"计算"或"证明"那一步。

对比一下：在动态语言里 `1 + True` 好歹是个能跑的表达式（结果可能很怪）；
在 HOL 里它连项都不是。**类型检查发生在项构造阶段**，这是"先有类型再有含义"的字面意思。

## 19.4 类型缩写 type_abbrev

```text
缩写只是个名字，打印时会被展开：
  :num # num
所以 ``:pnum`` 和 ``:num # num`` 是同一个类型：
  true
用到缩写上的函数照常工作：
  ⊢ ∀pp. swap pp = (SND pp,FST pp)
  swap (1,2) = (2,1)
```

```sml
val _ = type_abbrev ("pnum", ``:num # num``)
val _ = out ("  " ^ tyq ``: pnum``)
val _ = out ("  " ^ Bool.toString (``: pnum`` = ``: num # num``))
```

`type_abbrev ("pnum", ``:num # num``)` 给一个已有类型起别名。
**它只是个名字，不是新类型**：

- 打印时会被展开回 `:num # num`；
- `` `:pnum` = `:num # num` `` 求值为 `true`；
- 用它写函数、求值、证明，全都照常。

> 缩写的好处只在**源码可读性**：`pnum` 比 `num # num` 更能说明意图。
> 它**不提供**任何额外的类型安全 —— 想让 `pnum` 和 `num # num` 不能混用，
> 要用单构造子的数据类型（`Datatype \`pnum = Pnum num num\``）。

## 19.5 参数化数据类型

```text
<<HOL message: Defined type: "tree">>
类型：:α tree
构造子 Nd 的类型：:α tree -> α -> α tree -> α tree
tree_induction：
  ⊢ ∀P. P Lf ∧ (∀t t0. P t ∧ P t0 ⇒ ∀a. P (Nd t a t0)) ⇒ ∀t. P t
tree_nchotomy：
  ⊢ ∀tt. tt = Lf ∨ ∃t a t0. tt = Nd t a t0
tree_11（注入性）：
  ⊢ ∀a0 a1 a2 a0' a1' a2'.
    Nd a0 a1 a2 = Nd a0' a1' a2' ⇔ a0 = a0' ∧ a1 = a1' ∧ a2 = a2'
tree_Axiom（原始递归原理）：
  ⊢ ∀f0 f1. ∃fn.
    fn Lf = f0 ∧ ∀a0 a1 a2. fn (Nd a0 a1 a2) = f1 a1 a0 a2 (fn a0) (fn a2)
```

```sml
val _ = Datatype `tree = Lf | Nd tree 'a tree`
val _ = out ("类型：" ^ tyq ``: 'a tree``)
val _ = out ("构造子 Nd 的类型：" ^ ty ``Nd``)
```

**类型参数不写在左边。** HOL4 从右边出现的类型变量推断出参数列表。
写成 `Datatype \`tree 'a = Lf | Nd …\`` 会被拒绝，错误信息是：

```
to_tyspecs: Omit arguments to new type
```

（意即"别给新类型写参数"。）

`Datatype` 照例生成四条主力定理：

| 定理 | 用途 |
|---|---|
| `tree_induction` | 结构归纳（子树上有两个归纳假设） |
| `tree_nchotomy` | 穷举：`Lf` 或 `Nd t a t0` |
| `tree_11` | 构造子注入性与区分性 |
| `tree_Axiom` | 原始递归原理（写递归函数用） |

注意 `tree_induction` 里 `∀a` 的位置：归纳假设只覆盖**两个子树**，
节点上的数据 `a` 是任意的、没有归纳假设 —— 因为它不是 `tree` 类型。

## 19.6 在多态类型上写函数

```text
⊢ tsize Lf = 0 ∧ ∀l a r. tsize (Nd l a r) = tsize l + tsize r + 1
tsize 的类型：:α tree -> num
求值：tsize (Nd Lf 9 (Nd Lf 8 Lf)) = 2
tsize Lf 归零：⊢ ∀t. tsize t = 0 ⇒ t = Lf
```

```sml
Definition tsize_def:
  (tsize Lf = 0) /\
  (tsize (Nd l a r) = tsize l + tsize r + 1)
End
val _ = out ("tsize 的类型：" ^ ty ``tsize``)
val _ = out ("tsize Lf 归零："
             ^ p ``!t : num tree. tsize t = 0 ==> t = Lf``
                 (Cases >> rw [tsize_def] >> DECIDE_TAC))
```

`tsize` 是多态的：`:α tree -> num`。定义里 `a` 这个字段完全没被用到 ——
正是这一点让它多态。

最后一个证明演示了 **`Cases` 不带参数**的用法：
它自动对目标里的变量做 case 分析（等价于 `Cases_on \`t\``），
然后 `rw [tsize_def]` 把 `tsize Lf = 0` 和 `tsize (Nd …) = tsize l + tsize r + 1`
分别化简掉，剩下的 `0 = 0` 和"正数 ≠ 0"交给 `DECIDE_TAC`。

第二个分支的关键在于：目标 `tsize (Nd l a r) = 0` 化简成
`tsize l + tsize r + 1 = 0`，这是个**线性算术矛盾**，`DECIDE_TAC` 能判出来。

## 19.7 内置的 option / sum

```text
``:num option`` = :num option
option_nchotomy : ⊢ ∀opt. opt = NONE ∨ ∃x. opt = SOME x
THE             : ⊢ ∀x. THE (SOME x) = x
OPTION_MAP      : ⊢ (∀f x. OPTION_MAP f (SOME x) = SOME (f x)) ∧ ∀f. OPTION_MAP f NONE = NONE
``:num + bool`` = :num + bool
sum_case        : ⊢ (∀x f f1. sum_CASE (INL x) f f1 = f x) ∧
  ∀y f f1. sum_CASE (INR y) f f1 = f1 y
（option/sum 的定理在 optionTheory / sumTheory，不在 listTheory。）
```

```sml
val _ = out ("option_nchotomy : " ^ th "option" "option_nchotomy")
val _ = out ("THE             : " ^ th "option" "THE_DEF")
val _ = out ("OPTION_MAP      : " ^ th "option" "OPTION_MAP_DEF")
val _ = out ("sum_case        : " ^ th "sum" "sum_case_def")
```

两个最常用的内置多态类型：

| 类型 | 构造子 | 用途 |
|---|---|---|
| `α option` | `NONE` / `SOME x` | 可能失败的计算（查找、解析） |
| `α + β` | `INL x` / `INR y` | 二选一（错误 vs 结果） |

配套的分情况函数是 `case … of`（对 `option`）和 `sum_CASE`（对 `sum`）。
打印出来是 `sum_CASE`，源码里通常写 `sum_case` 或者直接 `case s of INL … | INR …`。

> 定理的位置：`option` 的在 `optionTheory`，`sum` 的在 `sumTheory`。
> 它们**不在** `listTheory` 里 —— 找不到定理时先 `DB.find`（22 章）。

## 19.8 坑位清单

1. **类型引号是 `` `:T` ``，项引号是 `` `t` ``** → 差一个冒号，别混。
2. **参数化 `Datatype` 左边不写参数** → 写了报 `Omit arguments to new type`。
3. **类型参数顺序按类型变量首次出现顺序** → 跟 18.6 节的记录一样。
4. **`type_abbrev` 只是别名** → 它不提供额外的类型安全，需要时用单构造子 `Datatype`。
5. **类型错误发生在构造项时** → 报错来自 `Term.mk_comb`，不是证明阶段。
6. **数字字面量默认是 `num`** → 想写多态函数就别让它碰到算术算子。
7. **`tree_induction` 的归纳假设只覆盖子树** → 节点上的数据没有归纳假设。
8. **`Cases`（不带参数）自动挑变量分情况** → 但有歧义时要显式 `Cases_on`。
9. **`option` / `sum` 的定理在各自的理论里** → 不在 `listTheory`。
10. **打印时类型变量是 `α β`，源码要写 `'a 'b`** → 别照抄打印结果。

---

上一章：[18 · 记录类型](18-records.md) ·
下一章：[20 · 化简器与 simpset](20-simpset.md)
