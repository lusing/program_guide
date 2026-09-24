# 02 · 项、类型与引号

> 对应示例：[`examples/02_terms/02_terms.sml`](../examples/02_terms/02_terms.sml)

HOL4 的一切都写在 SML 的字符串化**引号**里：引号内是逻辑层（项 / 类型），
引号外是元语言层（SML）。本章把这条边界讲清楚 —— 它是新手前三天
最容易绊倒的地方。

## 02.1 两种引号

两撇反引号 ` ``…`` ` 得到**项**；一撇反引号 `` `…` `` 得到
**quotation**（一个 `term frag list`）：语法层还没解析成项。

```text
`p /\ q` 是 term frag list，长度 = 1
其中唯一的片段是 QUOTE " (*#loc 25 27*)p /\ q"
``p /\ q`` 是项，类型是 :bool
TAUT 直接吃 quotation：⊢ p ∨ ¬p
```

```sml
val q : term frag list = `p /\ q`
val _ = out ("`p /\\ q` 是 term frag list，长度 = " ^ Int.toString (length q))
val _ = out ("其中唯一的片段是 " ^
             (case hd q of QUOTE s => "QUOTE \"" ^ s ^ "\"" | ANTIQUOTE _ => "<antiq>"))
val _ = out ("``p /\\ q`` 是项，类型是 " ^ (type_of ``p /\ q`` |> type_to_string))
val _ = out ("TAUT 直接吃 quotation：" ^ thm_to_string (tautLib.TAUT `p \/ ~p`))
```

注意 quotation 里的片段带了源码位置 `(*#loc 25 27*)` —— 这是 quotation
和"纯字符串"的关键区别，位置信息让 HOL4 的报错能指到具体行。

> 绝大多数时候用 ` ``…`` `（项）。需要 quotation 的典型场合是那些
> "自己会解析参数"的老式接口（如 `tautLib.TAUT`、`Hol_datatype`）。

## 02.2 类型引号

类型也写在引号里，前面加冒号：

```text
:num      = :num
:bool     = :bool
:num list = :num list
:num # bool = :num # bool
```

```sml
val _ = out (":num      = " ^ type_to_string ``:num``)
```

`#` 是 HOL4 的**配对类型**，不是 SML 里的"取字段"。`:num # bool` 就是
"一个数和一个布尔的二元组"。

## 02.3 Unicode 打印开关

HOL4 默认用 Unicode 打印（`∀ ∃ ∧ ∨ ⇒ ⇔ ≠ ∈`）。关掉开关会退化成 ASCII：

```text
avoid_unicode=1: !x. x IN s ==> x <> 0
avoid_unicode=0: ∀x. x ∈ s ⇒ x ≠ 0
```

```sml
val _ = set_trace "PP.avoid_unicode" 1
val _ = out ("avoid_unicode=1: " ^ term_to_string ``!x. x IN s ==> ~(x = 0:num)``)
val _ = set_trace "PP.avoid_unicode" 0
```

> 写脚本时**不要**为了"好看"去改这个开关：验证脚本要的是逐字节可比，
> 而 Unicode 在所有 UTF-8 环境下都是稳定的 —— 保持默认即可。
> 这里演示它，只是让你在看到两种打印时不至于以为换了语言。

## 02.4 HOL 与 ML 的写法差异

同一对概念，在 HOL 项里和在 ML 里写法不同：

```text
HOL 列表用分号：  [1; 2; 3]
HOL 元组用 #：    :num # bool
中缀转前缀加 $：  3 + 4
MAP 一个加法函数： MAP ($+ 1) [1; 2; 3]
它的值：          MAP ($+ 1) [1; 2; 3] = [2; 3; 4]
```

```sml
val _ = out ("HOL 列表用分号：  " ^ term_to_string ``[1; 2; 3]``)
val _ = out ("中缀转前缀加 $：  " ^ term_to_string ``($+) 3 4``)
val _ = out ("MAP 一个加法函数： " ^ term_to_string ``MAP ($+ 1) [1; 2; 3]``)
```

| 场合 | ML | HOL 项 |
|---|---|---|
| 列表元素分隔 | 逗号 `[1, 2]` | 分号 `[1; 2]` |
| 元组类型 | `num * bool` | `:num # bool` |
| 中缀转前缀 | 无（`op +`） | `$+` |

`MAP ($+ 1) [1; 2; 3]` 里的 `$+ 1` 是"加一"函数：`$+` 把中缀转成前缀，
再偏应用一个参数。

## 02.5 解析与打印

`Parse.Term` 吃 quotation，吐项；`term_to_string` 反过来。两者可以来回：

```text
parse： 1 + 2
回环：  SUC (SUC 0)
再解析： SUC (SUC 0)
```

```sml
val _ = out ("parse： " ^ (Parse.Term [QUOTE "1 + 2"] |> term_to_string))
val _ = out ("回环：  " ^ (term_to_string ``SUC (SUC 0)``))
val _ = out ("再解析： " ^ (Parse.Term [QUOTE (term_to_string ``SUC (SUC 0)``)]
                            |> term_to_string))
```

注意"回环"和"再解析"给出**同样的字符串** —— `SUC (SUC 0)` 打印出来
不再折叠回 `2`，因为 `2` 只是字面量的书写形式，项本身是 `SUC (SUC 0)`。

## 02.6 保留词要加 $

集合运算的几个名字跟 SML 关键字/内置名冲突，写成项时必须加 `$` 前缀：

```text
$UNION  = :(α -> bool) -> (α -> bool) -> α -> bool
$INSERT = :α -> (α -> bool) -> α -> bool
$SUBSET = :(α -> bool) -> (α -> bool) -> bool
```

```sml
val _ = out ("$UNION  = " ^ (type_of ``$UNION`` |> type_to_string))
```

不加前缀报的是 `No rule for [UNION]` —— 这条消息很误导人，它其实在说
"解析器不认识这个名字"。

## 02.7 多态与类型实例化

`LENGTH` 的类型带类型变量 `α`。用 `inst` 可以把它钉到具体类型：

```text
LENGTH  : :α list -> num
LENGTH@num : :num list -> num
HD      : :α list -> α
```

```sml
val _ = out ("LENGTH@num : " ^ (inst [alpha |-> ``:num``] ``LENGTH``
                                 |> type_of |> type_to_string))
```

`alpha` 是 `HolKernel` 提供的那个"标准"类型变量；`|->` 是类型替换的写法。

## 02.8 坑位清单

1. **一撇 vs 两撇反引号搞混** → ``` `p` ``` 是 quotation（未解析），`` ``p`` `` 才是项；类型不匹配时报"expected term, got term frag list"。
2. **`UNION` / `INSERT` / `SUBSET` / `IN` 之外的保留词也要加 `$`** → 裸写报 `No rule for [X]`，消息里没有"保留词"三个字。
3. **单反引号不能拿去 `type_of`** → `type_of \`p /\ q\`` 类型错；要先 `Parse.Term` 或改用双反引号。
4. **`$` 本身是中缀** → 想当函数用要写 `(fn x => x + 1) $ 40 + 1`，不能裸写 `$ f x`。
5. **HOL 列表用分号** → `[1, 2]` 在项里是解析错误，要 `[1; 2]`。
6. **`#` 是元组类型不是取字段** → `:num # bool` 是类型；取元组成分用 `FST`/`SND`（记录用 `.字段名`，见 18 章）。
7. **`2` 打印出来是 `SUC (SUC 0)`** → 字面量只是书写形式；比对输出时按项的实际形态期待。
8. **改 `PP.avoid_unicode` 会让输出整体变样** → 验证脚本里保持默认，不要为了 ASCII 兼容性去改。
9. **类型引号里的 `#` 是右结合的** → `:num # bool # num` 是 `num # (bool # num)`；要左结合得加括号。
10. **quotation 里带源码位置 `(*#loc …*)`** → 手工构造 `QUOTE "..."` 时没有这个，某些接口的报错位置会退化。

---

上一章：[01 · 开场：心智模型与环境自检](01-overview.md) ·
下一章：[03 · 元语言 Standard ML](03-ml.md)
