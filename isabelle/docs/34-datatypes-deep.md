# 34 · 嵌套与互斥 datatype：BNF 视角

对应示例：`../examples/T34_datatypes_deep.thy`

## 34.1 一句话概括

直接递归只是 `datatype` 的入门形态。datatypes 手册的主体是两种进阶：
**嵌套**（递归穿过 `list`/`option`/`sum`/`prod` 等类型构造器）与
**互斥**（几个类型用 `and` 互相引用）。合法性由 **BNF**
（bounded natural functor）把关：map/set/rel 三件套自动穿过嵌套层，
size、case、primrec、归纳原理全部免费跟进去。

## 34.2 嵌套递归：玫瑰树

```isabelle
datatype 'a rose = Rose 'a "'a rose list"

primrec rsum :: "'a::monoid_add rose ⇒ 'a" where
  "rsum (Rose v cs) = v + sum_list (map rsum cs)"
```

右端穿过嵌套层要显式 `map rsum`——primrec 不知道"列表里装的是
递归调用"以外的东西。实测生成的 size/map（注意嵌套的形状）：

```text
thm rose.size
(* size (Rose ?x1 ?x2) = size_list size ?x2 + Suc 0 *)

thm rose.map
(* map_rose ?f (Rose ?x1 ?x2) = Rose (?f ?x1) (map (map_rose ?f) ?x2) *)
```

`size_list size` / `map (map_rose ?f)`——组合子自己嵌进去，
这就是 BNF 的"自动穿透"。终止性证据免费：第 5 章 `fun` 可以直接
`termination by (relation "measure size")`。

## 34.3 嵌套 case

case 表达式一路嵌进列表模式：

```isabelle
lemma rose_child: "rsum (Rose (a::nat) (c # cs)) = a + rsum c + sum_list (map rsum cs)"
  by (simp add: add.assoc)
```

`simp` 自动用 `list.map` + `sum_list.Cons` 展开嵌套层；`add.assoc`
负责把 `a + (rsum c + S)` 摆成右端形状。

## 34.4 互斥递归

```isabelle
datatype et = E0 | ES ot and ot = OS et

primrec e2n :: "et ⇒ nat" and o2n :: "ot ⇒ nat" where
  "e2n E0 = 0"
| "e2n (ES w) = Suc (Suc (o2n w))"
| "o2n (OS e) = Suc (e2n e)"
```

生成**组合**归纳规则 `et_ot.induct`。单类型目标用普通
`induct w` 就够——互斥类型每个成员都有自己的独立归纳规则：

```isabelle
lemma pos_o: "0 < o2n w"
  by (induct w) auto

lemma es_bigger: "e2n (ES w) > o2n w"
  by simp
```

"e2n 恒偶 / o2n 恒奇"这类互斥命题单类型归纳不够（ES 情形的 IH
落在另一类型上），要用 `et_ot.induct` 证合取目标——或只碰一个类型。

### 互斥归纳的两个坑

- **`.inducts` 不存在**（实测 Undefined fact）：只有 `.induct`，
  旧教程里的 `.inducts` 提法已过时；
- `induct e and w rule: et_ot.induct` 这种"两变量并排"写法实测报
  `Rule has fewer conclusions than arguments given`——组合规则的
  结论形状带两个谓词，`induct` 方法对不上。结论确实横跨两类型时，
  把命题合成单目标或分两个引理各自归纳（示例 34.5 的两段式）。

## 34.5 嵌套的叠层

`option list` 两层嵌套一起上：

```isabelle
datatype 'a shelf = Shelf 'a "'a shelf option list"

primrec shelf_depth :: "'a shelf ⇒ nat" where
  "shelf_depth (Shelf v cs) =
     Suc (fold max (map (λco. the (map_option shelf_depth co)) cs) 0)"

value "shelf_depth (Shelf (1::nat) [Some (Shelf 2 []), None])"
```

穿过 `option` 的递归调用写成 `the (map_option shelf_depth co)`——
实测 lambda 里手写 `case co of Some c ⇒ shelf_depth c | None ⇒ 0`
在会话构建里报 `Invalid map function`（探针堆能过、正式会话翻脸，
经典"堆上下文敏感"案例），map_option 形态两端都稳。
（`fold max` 而不是 `Max`：集合版不可执行，列表版稳。）

## 34.6 BNF 白名单与黑名单

| 嵌套位置 | 合法性 | 实测 |
|---|---|---|
| `list` / `option` / `sum` / `prod` / `set` | ✅ | 全部即用 |
| 上述的再嵌套（`option list` 等） | ✅ | 34.5 |
| 任意函数空间 `'a ⇒ 'a t` | ❌ | 报 `Cannot define empty datatype` |
| 自己嵌自己（`'a t t`） | ✅ | 合法但 size 语义微妙 |

函数空间出局的原因：`'a ⇒ 'b` 作为 BNF 需要 `set`（像域限制）
有界，任意定义域做不到。要"键值孩子"用 `('a × 'a t) list`（有限键）
或 Library 的现成结构。

## 34.7 坑位清单（实测）

1. **`o` 当变量名**：`ES o` 报 `Inner syntax error` 且位置误导——
   `o` 是函数复合的 ASCII 语法。互斥定义的高发坑。
2. **函数空间嵌套被拒**：错误文本 `Cannot define empty datatype`
   完全没提"函数"——看到先查递归位置的类型构造器。
3. **`.inducts` 不存在**：只有 `.induct`。
4. **`induct x and y rule:`** 对组合规则报
   `Rule has fewer conclusions than arguments given`——
   拆成单目标或分别归纳。
5. **嵌套 primrec 忘 `map`**：`sum_list (rsum cs)` 直接类型错误；
   必须写 `sum_list (map rsum cs)`。
6. **`Max`/集合版聚合不可执行**：value 报 code 方程缺失，
   换 `fold max`/列表版。
7. **互斥 primrec 的方程顺序**：两类型的方程**必须**在同一个
   `primrec ... and ...` 里给全；漏一条报 `missing equations`。
8. **`old_datatype` 是兼容遗物**：生成的事实名（` Exhaust`、
   `.exhaust`）与现代包不同，新代码别用。
9. **size 的嵌套形状**：`size (Rose a cs) = size_list size cs + Suc 0`
   ——子树 size 由 `size_list` 加总，自定义终止度量时直接
   `measure size` 即可，不用手推。
10. **选择子与判别式**：带名字的构造器参数（`Rose (val: 'a)`）
    额外生成选择子/判别式；不带名字就没有，事后要用只能 `case`。

## 34.8 与其他章的接口

- 第 4 章 datatype 基础：本章是其进阶续篇。
- 第 5 章 fun/终止性：嵌套 size 免费提供 `measure size` 证据。
- 第 26 章 codatatype：嵌套在余代数侧同样成立（BNF 双向通行）。
- 第 36 章 corec friends：本章的 rose/互斥是那边的基础设施。
