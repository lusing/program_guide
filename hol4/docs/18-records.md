# 18 · 记录类型

> 对应示例：[`examples/18_records/18_records.sml`](../examples/18_records/18_records.sml)

多字段的构造器用起来像元组，但**字段有名字**：取值、更新、相等判定都按名字走。
这一章看 `Datatype` 为记录生成了哪些定理，以及"字段更新"在 HOL 里到底是什么
（提示：不是赋值）。

## 18.1 声明

```text
<<HOL message: Defined type: "pt">>
生成的定理里有这些名字：
pt_updates_eq_literal pt_nchotomy pt_literal_nchotomy pt_literal_11 pt_induction pt_fupdselfid pt_fupdfupds_comp pt_fupdfupds pt_fupdcanon_comp pt_fupdcanon pt_fn_updates pt_component_equality pt_case_eq pt_case_cong pt_Axiom pt_accfupds pt_accessors pt_11 FORALL_pt EXISTS_pt
```

```sml
val _ = Datatype `pt = <| x : num ; y : num |>`
```

记录类型用 `<| … |>` 声明，字段写成 `名字 : 类型`，用 `;` 分隔。
`Datatype` 会为它生成二十来条定理，名字都带 `<类型名>_` 前缀，
外加两条不带前缀但带类型名的：`FORALL_pt` / `EXISTS_pt`。

这一章重点看其中 8 条。其余的（`pt_case_cong`、`pt_Axiom`、`pt_11` 等）
在需要时查 `DB.theorems` 即可（22 章）。

## 18.2 字面量 / 取值 / 更新

```text
字面量        : <|x := 1; y := 2|>
带类型标注    : <|x := 1; y := 2|>
取值 p.x      : p.x
单字段更新    : p with y := 3
函数式更新    : p with x updated_by f
整块覆盖      : p with <|x := 5; y := 6|>
求值 取值     : <|x := 1; y := 2|>.x = 1
求值 更新     : <|y := 9; x := 1; y := 2|> = <|x := 1; y := 9|>
求值 链式更新 : <|y := 4; x := 3; x := 1; y := 2|> = <|x := 3; y := 4|>
求值 整块覆盖 : <|x := 5; y := 6; x := 1; y := 2|> = <|x := 5; y := 6|>
求值 updated_by : <|x updated_by (λn. n + 10); x := 1; y := 2|> = <|x := 11; y := 2|>
```

```sml
val _ = out ("取值 p.x      : " ^ term_to_string ``(p : pt).x``)
val _ = out ("单字段更新    : " ^ term_to_string ``(p : pt) with y := 3``)
val _ = out ("函数式更新    : " ^ term_to_string ``(p : pt) with x updated_by f``)
val _ = out ("求值 updated_by : "
             ^ ev ``(<| x := 1 ; y := 2 |> : pt) with x updated_by (\n. n + 10)``)
```

三种"改"的写法：

| 写法 | 含义 |
|---|---|
| `p with x := v` | 把字段 `x` 设成 `v` |
| `p with x updated_by f` | 把字段 `x` 换成 `f p.x`（函数式更新） |
| `p with <|x := …; y := …|>` | 整块覆盖 |

**`with` 是后缀且左结合**，而且 `:=` 右边会"尽量多吃"。所以链式更新必须加括号：

```sml
((p : pt) with x := 3) with y := 4     (* 对 *)
p with x := 3 with y := 4              (* 错：解析成 p with x := (3 with y := 4) *)
```

`updated_by` 那行最能说明问题：`<|x := 1; y := 2|> with x updated_by (λn. n + 10)`
求值得 `<|x := 11; y := 2|>` —— **原来的 `p` 没变**，得到的是一个新记录。

## 18.3 生成的定理

```text
pt_accessors（取值就是投影）：
  ⊢ (∀n n0. (pt n n0).x = n) ∧ ∀n n0. (pt n n0).y = n0
pt_accfupds（更新只动一个字段）：
  ⊢ (∀p f. (p with y updated_by f).x = p.x) ∧
  (∀p f. (p with x updated_by f).y = p.y) ∧
  (∀p f. (p with x updated_by f).x = f p.x) ∧
  ∀p f. (p with y updated_by f).y = f p.y
pt_component_equality（两个记录相等 ⇔ 逐字段相等）：
  ⊢ ∀p1 p2. p1 = p2 ⇔ p1.x = p2.x ∧ p1.y = p2.y
pt_literal_11（字面量相等 ⇔ 逐字段相等）：
  ⊢ ∀n01 n1 n02 n2.
    <|x := n01; y := n1|> = <|x := n02; y := n2|> ⇔ n01 = n02 ∧ n1 = n2
pt_literal_nchotomy（任何记录都能写成字面量）：
  ⊢ ∀p. ∃n0 n. p = <|x := n0; y := n|>
pt_induction：
  ⊢ ∀P. (∀n n0. P (pt n n0)) ⇒ ∀p. P p
FORALL_pt（把 ∀p 拆成 ∀各字段）：
  ⊢ ∀P. (∀p. P p) ⇔ ∀n0 n. P <|x := n0; y := n|>
```

```sml
fun tb n = DB.fetch "Tut18" n          (* 取定理本身（thm） *)
fun th n = thm_to_string (tb n)        (* 取定理的字符串 *)
val _ = out ("pt_component_equality（两个记录相等 ⇔ 逐字段相等）：")
val _ = out ("  " ^ th "pt_component_equality")
```

> **这里有个容易写错的地方**：`DB.fetch` 返回的是**定理**，`thm_to_string` 返回**字符串**。
> 想当重写规则用（`rw [tb "pt_component_equality"]`）必须用前者。
> 本教程里因此专门定义了两个函数：`tb` 取定理、`th` 取字符串。

七条定理的用途：

| 定理 | 用途 |
|---|---|
| `pt_accessors` | 取值 = 取构造子的第 n 个参数 |
| `pt_accfupds` | 更新只动一个字段，其余不变 |
| `pt_component_equality` | **记录相等 ⟺ 逐字段相等**（最常用） |
| `pt_literal_11` | 两个字面量相等 ⟺ 逐字段相等 |
| `pt_literal_nchotomy` | 任何记录都能写成字面量（用来消去 `p`） |
| `pt_induction` | 结构归纳：只需证 `P (pt n n0)` |
| `FORALL_pt` | 把 `∀p. P p` 拆成 `∀n0 n. P <\|…\|>` |

`pt_component_equality` 是记录证明的主力。它把"两个记录相等"化归成
"各字段分别相等" —— 跟集合的外延性（`EXTENSION`，15.3 节）是一个套路。

## 18.4 `with` 不是赋值

```text
pt_fupdfupds（同一字段连着更新两次 = 复合）：
  ⊢ (∀p g f.
     p with <|x updated_by f; x updated_by g|> = p with x updated_by f ∘ g) ∧
  ∀p g f.
    p with <|y updated_by f; y updated_by g|> = p with y updated_by f ∘ g
pt_fupdcanon（不同字段的更新可以换序）：
  ⊢ ∀p g f.
    p with <|y updated_by f; x updated_by g|> =
    p with <|x updated_by g; y updated_by f|>
pt_fupdselfid（用原值更新 = 不动）：
  ⊢ (∀p. p with x := p.x = p) ∧ ∀p. p with y := p.y = p
用原值更新一次，记录不变：⊢ ∀p. p with x := p.x = p
两个字段各更新一次，结果与顺序无关：⊢ ∀p. p with <|y := 2; x := 1|> = p with <|x := 1; y := 2|>
```

```sml
val _ = out ("用原值更新一次，记录不变："
             ^ p ``!p : pt. p with x := p.x = p`` (rw [tb "pt_component_equality"]))
val _ = out ("两个字段各更新一次，结果与顺序无关："
             ^ p ``!p : pt. (p with x := 1) with y := 2
                          = (p with y := 2) with x := 1``
                 (rw [tb "pt_component_equality"]))
```

这一节回答"`with` 到底是什么"：**它是函数，不是赋值。**

- `pt_fupdfupds` —— 同一字段连着更新两次等于把两个函数复合；
- `pt_fupdcanon` —— 不同字段的更新**可以换序**（这正是"函数式"的体现）；
- `pt_fupdselfid` —— 用原值更新等于不动。

三个证明用的都是 `rw [pt_component_equality]`：
先把记录相等化归成逐字段相等，剩下的就是 `pt_accfupds` 那类化简
（`rw` 已经装着它们）。

最后一行注意**打印**效果：`(p with x := 1) with y := 2` 被折叠打印成
`p with <|y := 2; x := 1|>`。源码里写哪种都行，
但**连续 `with` 要加括号**（18.2 节）。

## 18.5 记录和元组比

```text
同一个东西写成元组：
  :num # num
取值要用 FST/SND：FST (1,2) = 1
记录按名字取：<|x := 1; y := 2|>.y = 2
三个以上字段时，元组的第 4 个分量没有内置投影函数，记录的字段名是自带的。
```

```sml
val _ = out ("取值要用 FST/SND：" ^ ev ``FST (1, 2)``)
val _ = out ("记录按名字取：" ^ ev ``(<| x := 1 ; y := 2 |> : pt).y``)
```

两个字段时元组和记录差不多。但：

- 元组只有 `FST` / `SND` 两个内置投影，**第三个及以上要自己写**；
- 元组的字段没名字，`(num # bool # num)` 和 `(num # num # bool)` 全靠位置记；
- 记录自动生成 `component_equality`、`accessors`、`induction` 等定理。

**经验法则**：两个字段的临时组合用元组；会出现在类型签名里、
或者有三个以上字段的，用记录。

## 18.6 多态记录

```text
<<HOL message: Defined type: "pair">>
类型：:(num, bool, num) pair
取值：<|fst := 1; snd := T; tag := 7|>.fst = 1
生成的 component_equality：
  ⊢ ∀p1 p2. p1 = p2 ⇔ p1.fst = p2.fst ∧ p1.snd = p2.snd ∧ p1.tag = p2.tag
（字段名跟内置函数 FST/SND 同名也没关系：它们在不同的命名空间。）
```

```sml
val _ = Datatype `pair = <| fst : 'a ; snd : 'b ; tag : 'c |>`
val _ = out ("类型：" ^ type_to_string ``: (num, bool, num) pair``)
```

记录类型可以是**带参数（多态）**的。声明时左边只写类型名 `pair`
（**不写参数**），右边用类型变量 `'a` `'b` `'c`；
用的时候参数写在前面：`(num, bool, num) pair`。

注意参数顺序按类型变量**首次出现的顺序**排 —— 也就是字段的书写顺序。

字段名可以叫 `fst` / `snd`，跟内置的 `FST` / `SND` 撞名也没关系：
字段访问是 `p.fst` 这种后缀语法，跟函数名在不同的命名空间里。

## 18.7 坑位清单

1. **`with` 是后缀且左结合** → 链式更新必须写 `(p with x := 3) with y := 4`。
2. **`with` 不是赋值** → 原记录不变，返回新记录。
3. **`DB.fetch` 返回定理、`thm_to_string` 返回字符串** → 喂给 `rw` 要用前者。
4. **`pt_component_equality` 是记录证明的主力** → 把记录相等化归成逐字段相等。
5. **多态记录声明时左边不写参数** → `Datatype \`pair = <| fst : 'a |>\``，不是 `('a,'b) pair`。
6. **类型参数顺序按字段出现顺序** → `(num, bool, num) pair` 对应 `fst`/`snd`/`tag`。
7. **元组只有 `FST`/`SND`** → 三个以上字段用记录。
8. **`Datatype` 不产生 ML 绑定** → 记录类型也一样，定理要用 `DB.fetch` 取。
9. **连续 `with` 会被打印折叠成 `p with <|…|>`** → 看输出时别以为源码写错了。
10. **`updated_by` 接的是函数** → `p with x updated_by f` 等价于 `p with x := f p.x`。

---

上一章：[17 · 归纳定义](17-inddef.md) ·
下一章：[19 · 类型与类型缩写](19-types.md)
