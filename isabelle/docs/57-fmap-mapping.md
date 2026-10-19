# 57 · 有限映射（上）：fmap 与 Mapping

对应示例：`../examples/lib/T57_fmap_mapping.thy`（IsaTutLib 会话，
依赖 `HOL-Library.Finite_Map` 与 `HOL-Library.AList_Mapping`）

## 57.1 偏函数很好，但它不能「跑」

第 14 章我们把字典建模成偏函数 `'a ⇀ 'b`，也就是 `'a ⇒ 'b option`：
查不到的键返回 `None`。这个表示在纸面推理上近乎完美——字典就是函数，
函数外延性（逐点相等则相等）、函数复合都是现成的，第 40 章的
`THE`、`dom`、`ran` 全部建立在它上面。

但把它放进代码生成器（第 19/37 章的世界）时，两个短板立刻暴露：

1. **定义域可能无穷。** 一个 `nat ⇀ nat` 函数原则上可以在无穷多个
   键上有定义，而任何真实程序的数据结构都只能存有限条目。
2. **函数对生成器不透明。** 生成器不知道一个函数值「里面存了什么」，
   无法把它实现成哈希表或关联表；对函数类型的求值只能靠有限枚举，
   于是只对 `enum` 类型族工作。

`HOL-Library` 给出两套互补的解法，本章各讲一个：

- **`('a,'b) fmap`**（`Finite_Map`）：用第 28 章的 typedef + Lifting
  流水线，把「定义域有限的偏函数」包装成一个携带等式理论和可执行
  实现的新类型。它适合**形式化推理**。
- **`('a,'b) mapping`**（`Mapping` + 后端理论 `AList_Mapping`）：
  同样基于有限偏函数，但**刻意藏起表示**，使后端能在关联表与红黑树
  （第 59 章）之间替换而客户端一行不改。它适合**组织可执行库**。

## 57.2 fmap 的定义：子类型 + Lifting

库里的定义只有一行 typedef：

```isabelle
typedef ('a, 'b) fmap = "{m. finite (dom m)} :: ('a ⇀ 'b) set"
```

新类型 `('a,'b) fmap` 的元素恰好是所有定义域有限的偏函数。
typedef 自动生成两个方向的映射：从 fmap 取出底层偏函数的投影被命名为
`fmlookup`，反方向是内部使用的 `Abs_fmap`。于是**「查键」就是函数
应用**：

```isabelle
fmlookup m k    (* m 中键 k 的值；None 表示缺键 *)
```

子类型包装最值钱的产物是外延性定理：

```isabelle
fmap_ext : fmlookup m = fmlookup n ⟹ m = n
```

两张映射相等，当且仅当对每个键的查找结果都相同。它对应普通函数的
`fun_eq_iff`，是 fmap 世界一切等式推理的总开关。

先用最朴素的三个原语造一张表：

```isabelle
definition ages :: "(string, nat) fmap" where
  "ages = fmupd ''Ann'' 23 (fmupd ''Bob'' 19 fmempty)"

value "fmlookup ages ''Ann''"            (* ⟹ "Some 23" :: "nat option" *)
value "fmlookup ages ''X''"              (* ⟹ "None" *)
value "fmlookup (fmempty :: (string, nat) fmap) ''Ann''"   (* ⟹ "None" *)
```

`fmempty` 是处处返回 `None` 的空表；`fmupd k v m` 在键 `k` 处写入
`v`（已存在则覆盖）。重复写同一个键是幂等的，不同键的更新彼此交换：

```isabelle
fmupd_idem      : fmupd a b (fmupd a b' m) = fmupd a b m
fmupd_reorder_neq : a ≠ b ⟹ fmupd a x (fmupd b y m) = fmupd b y (fmupd a x m)
```

我们用一条引理演示幂等性的实际用法——注意证明手法：**不要把
`ages_def` 展开成一串具体更新**（那样化简器会在具体字符串的嵌套
if-then-else 里打转），而是直接用外延性把目标变成逐点相等，再交给
化简器对符号形态的 `fmupd` 做改写：

```isabelle
lemma fmupd_demo:
  "fmupd ''Ann'' 24 ages = fmupd ''Ann'' 24 (fmupd ''Ann'' 25 ages)"
  by (rule fmap_ext; simp)
```

## 57.3 从关联表造表：fmap_of_list

实际数据很少靠一层层 `fmupd` 堆叠，更常见的入口是关联表：

```isabelle
value "fmap_of_list [(''Ann'', 23), (''Bob'', 19), (''Ann'', 99)]
        :: (string, nat) fmap"
(* ⟹ "fmap_of_list [(''Ann'', 23), (''Bob'', 19), (''Ann'', 99)]" *)

value "fmlookup (fmap_of_list [(''Ann'', 23), (''Ann'', 99)]
        :: (string, nat) fmap) ''Ann''"
(* ⟹ "Some 23" *)
```

两个观察结果都很重要：

1. **表首优先**：同一个键出现多次时，最前面的条目胜出，后面的被覆盖
   （与 Main 的 `map_of` 语义一致）。所以 `''Ann''` 查到的是 23。
2. **值就是以 `fmap_of_list` 打印的**——注意连重复条目都原样保留，
   求值并不替你压缩列表，查找时按表首优先自然忽略后面的同键条目。
   fmap 在代码生成时唯一注册的构造子正是 `fmap_of_list`（库里写明
   `code_datatype fmap_of_list`）：内部不管存成什么，导出到
   SML/Haskell/Scala 时一律落地为关联表。

于是 `ages` 也能换一种等价构造，证明用 `transfer` 把 fmap 层搬回
普通偏函数层（第 29 章 transfer 的标准用法）：

```isabelle
lemma ages_via_list: "ages = fmap_of_list [(''Ann'', 23), (''Bob'', 19)]"
  unfolding ages_def by transfer simp
```

## 57.4 定义域与值域：先和 fset 打个照面

下面三个取值操作的返回类型值得专门记住：

```isabelle
fmdom  :: "('a, 'b) fmap ⇒ 'a fset"   (* 键的有限集 *)
fmdom' :: "('a, 'b) fmap ⇒ 'a set"   (* 普通集合版 *)
fmran  :: "('a, 'b) fmap ⇒ 'b fset"   (* 值的有限集 *)
```

`fmdom` 和 `fmran` 返回的是 **`fset`**——第 58 章的主角「有限集类型」，
它是普通 `set` 的有限子类型，字面量写作 `{| … |}`（双竖线，空集是
`{||}`）；属于关系写作 `x |∈| S`。如果你需要和 Main 的集合库对接，
用带撇的 `fmdom'`：

```isabelle
value "fmdom ages"        (* ⟹ "Abs_fset {''Bob'', ''Ann''}" :: "char list fset" *)
value "fmdom' ages"       (* ⟹ "{''Bob'', ''Ann''}" :: "char list set" *)
value "fmran ages"        (* ⟹ "Abs_fset {19, 23}" :: "nat fset" *)
value "''Ann'' |∈| fmdom ages"   (* ⟹ "True" *)
```

注意 fset 的求值结果打印成 `Abs_fset {…}`——这是 typedef 的内部
构造子，在告诉你「它是普通集合的一层包装」。想要整齐的显示，
第 58 章会用 `sorted_list_of_fset`。

「在定义域里」与「查得到」是同一件事，定理两边互推：

```isabelle
fmlookup_dom_iff : fmlookup m a = Some b ⟷ a |∈| fmdom m
```

两条具体结论分别由求值与化简完成：

```isabelle
lemma "''X'' |∉| fmdom ages"     by (simp add: ages_def)
lemma "fmdom (fmempty :: (string, nat) fmap) = {||}"  by simp
```

## 57.5 并、复合、删除、限制

### 右优先的逐键并 `++⇘f`

`m ++⇘f n`（常量名 `fmadd`）把两张表逐键合并，**右表覆盖左表的同键
值**。这与 Main 的 `map_add` 方向一致（Isabelle 的并运算传统是
「后来者居上」），但与不少编程语言的直觉相反，三行实测把方向钉死：

```isabelle
value "fmlookup (ages ++⇘f fmupd ''Cy'' 30 fmempty) ''Cy''"   (* "Some 30"：新键并入 *)
value "fmlookup (ages ++⇘f fmupd ''Ann'' 99 fmempty) ''Ann''" (* "Some 99"：右表覆盖 *)
value "fmlookup (fmupd ''Ann'' 99 fmempty ++⇘f ages) ''Ann''" (* "Some 23"：ages 在右，仍它赢 *)

lemma fmadd_unit: "ages ++⇘f fmempty = ages"
  by (rule fmadd_empty)
```

空表是双边单位元，运算满足结合律（`fmadd_assoc`），所以多张表连并
不用操心括号，只操心顺序。

### Kleisli 复合 `∘⇘f`

`g ∘⇘f f`（常量名 `fmcomp`）是选项型偏函数的复合：先用 `f` 查，
命中后拿结果再去 `g` 里查；任一键在 `f` 处缺失，整体即缺失。

```isabelle
definition moms :: "(string, string) fmap" where
  "moms = fmap_of_list [(''Amy'', ''Ann''), (''Leo'', ''Ann'')]"

value "fmlookup (ages ∘⇘f moms) ''Amy''"  (* "Some 23"：Amy→Ann→23 *)
value "fmlookup (ages ∘⇘f moms) ''Leo''"  (* "Some 23" *)
value "fmlookup (ages ∘⇘f moms) ''Ann''"  (* "None"：moms 里没有 Ann 这个键 *)
```

复合方向的口诀是「**右边先查**」：`moms` 在右，先把孩子名映到母亲名。

### 删除、限制与按键筛选

```isabelle
value "fmlookup (fmdrop ''Ann'' ages) ''Ann''"        (* "None" *)
value "fmrestrict_fset {|''Ann''|} ages"
(* ⟹ "fmap_of_list [(''Ann'', 23)]"：只保留这一族键 *)
value "fmfilter (λk. k = ''Bob'') ages"
(* ⟹ "fmap_of_list [(''Bob'', 19)]" *)
```

一个容易踩的类型细节：`fmfilter` 的谓词类型是 `'a ⇒ bool`——
**只能按键筛**，不能直接按值筛。按值表达条件用 57.6 节的 `fmpred`，
或自行与查找组合。删除不存在的键是空操作：

```isabelle
fmdrop_idle : a |∉| fmdom m ⟹ fmdrop a m = m

lemma fmdrop_missing: "fmdrop ''X'' ages = ages"
  by (simp add: ages_def fmdrop_idle)
```

同族还有 `fmdrop_fset`（删一族键）、`fmrestrict_fset`（保留一族键），
以及接普通集合的 `fmdrop_set` / `fmrestrict_set`。

## 57.6 取像、枚举与「能不能 value」的边界

`fmimage m S` 取键集 `S` 对应的值（成 fset），`fset_of_fmap m` 把
整张表摊成键值对的 fset：

```isabelle
lemma "fmimage ages {|''Ann''|} = {|23|}"
  by (auto simp add: fset_eq_iff ages_def fmlookup_image_iff)

lemma "fset_of_fmap ages = {|(''Ann'', 23), (''Bob'', 19)|}"
  by (auto simp add: fset_eq_iff ages_def)
```

这两条写成引理而不是 `value`，是为了逼出一个关于 fmap/fset 代码层的
**重要事实**。fset 在代码生成时通过 `code_unfold` 展开回普通集合，
而 `fmimage`、`fset_of_fmap`、`fmpred`、`size` 这些操作展开后形如
「在整个类型上收集满足条件的元素」。代码求值器要处理这样的集合，
就得能够枚举整个元素类型——即元素满足 `enum` 类（有限且可枚举）。
`nat`、`string` 都是无穷类型，于是直接 `value` 会报：

```text
Wellsortedness error: Type nat not of sort {enum, equal}
```

换成有限类型 `bool`，同样的操作立刻可以求值：

```isabelle
value "fmimage (fmap_of_list [(True, 1::nat), (False, 2)]) {|True|}"
(* ⟹ "Abs_fset {1}" :: "nat fset" *)
value "fset_of_fmap (fmap_of_list [(True, False), (False, True)])"
(* ⟹ "Abs_fset {(False, True), (True, False)}" *)
```

无穷类型上需要「跑出来看」时，正解是把结果换成可执行的列表枚举。
当键类型带 `linorder` 时，`sorted_list_of_fmap` 给出按键排序、
无重复的关联表：

```isabelle
value "sorted_list_of_fmap
        (fmap_of_list [(3::nat, ''c''), (1, ''a''), (2, ''b'')])"
(* ⟹ "[(1, ''a''), (2, ''b''), (3, ''c'')]" *)

value "length (sorted_list_of_fmap
        (fmap_of_list [(1::nat, ''a''), (2, ''b''), (1, ''z'')]))"
(* ⟹ "2"：同键覆盖后只剩两个 *)
```

这个函数也是 fmap 与第 59 章红黑树后端对接的接口。`size` 在代码层
被定义成「键值对 fset 的基数」，所以同样只能在 `enum` 类型上直接
求值（注意同键覆盖后只计一次）：

```isabelle
value "size (fmap_of_list [(True, False), (False, True), (True, True)])"
(* ⟹ "2" *)
```

最后是两个判定：`m ⊆⇘f n`（`fmsubset`）表示键集包含且共有键上的值
一致；`fmpred P m` 表示每个键值对都满足二元谓词 `P`：

```isabelle
value "fmap_of_list [(''Ann'', 23::nat)] ⊆⇘f ages"   (* "True" *)
value "fmpred (λb n. n > 0) (fmap_of_list [(True, 1::nat)])"  (* "True" *)

lemma "fmpred (λ_ n. n > 18) ages"
  by (simp add: ages_def fmpred_iff)
```

## 57.7 Mapping：把表示藏起来的抽象字典

`Mapping.thy` 同样用 typedef 从有限偏函数构造出 `('a,'b) mapping`，
但它的工程意图和 fmap 正好形成镜像：**核心理论不提供任何构造子的
代码等式**。你在理论层面可以对 mapping 做推理（它有完整的 lookup
定律），可一旦要 `value` 或导出代码，就必须再导入一个**后端理论**
来「安装表示」。

后端一：关联表。导入 `HOL-Library.AList_Mapping` 后，构造子
`Mapping`（大写，与类型同名）以一张关联表为表示，查找直接解释成
Main 的 `map_of`，即无序列表上的线性查找：

```isabelle
value "Mapping.lookup (Mapping.empty :: (nat, string) mapping) 1"  (* "None" *)
value "Mapping.lookup (Mapping.update (1::nat) ''a'' Mapping.empty) 1"  (* "Some ''a''" *)
value "Mapping.lookup (Mapping [(1::nat, ''a''), (2, ''b'')]) 2"        (* "Some ''b''" *)
```

日常只读 API 与 fmap 对应，但结果回到普通集合与选项：

```isabelle
value "Mapping.keys    (Mapping [(1::nat, ''a''), (2, ''b''), (1, ''z'')])"
(* ⟹ "{1, 2}"：重复键去掉 *)
value "Mapping.entries (Mapping [(1::nat, ''a''), (2, ''b''), (1, ''z'')])"
(* ⟹ "{(1, ''a''), (2, ''b'')}" *)
value "Mapping.is_empty Mapping.empty"   (* "True" *)
value "Mapping.size    (Mapping [(1::nat, ''a''), (2, ''b''), (1, ''z'')])"
(* ⟹ "2" *)
```

三个批量构造子在实践中很好用：

- `Mapping.tabulate ks f`：按键表 `ks` 和取值函数 `f` 造表；
- `Mapping.bulkload xs`：造一张 `nat ⇀ 'b` 表，第 `n` 个条目以 `n`
  为键——这就是把数组当字典用；
- `Mapping.map_values g m`：只改值不改键。

```isabelle
value "Mapping.lookup (Mapping.tabulate [1::nat, 2, 3] (λn. n * n)) 3"  (* "Some 9" *)
value "Mapping.lookup (Mapping.bulkload [''a'', ''b'', ''c'']) 2"       (* "Some ''c''" *)
value "Mapping.lookup (Mapping.map_values (λ_ v. v @ ''!'')
        (Mapping [(1::nat, ''a'')])) 1"                                  (* "Some ''a!''" *)
```

改写与合并用 `map_entry`、`combine`、`lookup_default`：

```isabelle
(* map_entry 只在键已存在时改值，不会插入新键 *)
value "Mapping.lookup (Mapping.map_entry (1::nat) (apsnd (λ_::bool. True))
        (Mapping [(1, (''a'', False))])) 1"
(* ⟹ "Some (''a'', True)" *)

(* combine f：同键值对用 f 合并；1 同时在两边，2+3=5 *)
value "Mapping.lookup (Mapping.combine (λv w. v + w)
        (Mapping [(1::nat, 2::nat)]) (Mapping [(1, 3), (2, 4)])) 1"
(* ⟹ "Some 5" *)

(* 缺键时落回默认值，而不是返回 None *)
value "Mapping.lookup_default (0::nat) (Mapping [(1::nat, 2::nat)]) 9"  (* "0" *)
```

## 57.8 同一个抽象，两种后端

关键事实：57.7 节所有演示只调用了 `Mapping.lookup / Mapping.update`
一族**抽象**操作，没有任何一处依赖「里面是张表」。因此把导入从
`AList_Mapping` 换成 `HOL-Library.RBT_Mapping`（键类型需要
`linorder`），同一批命题一个字都不用改；运行时表示却从无序列表
变成平衡红黑树，查找由线性变对数。第 59 章会实际把红黑树后端跑起来。

这是典型的「**抽象类型 + 可换后端**」设计：核心理论定义操作并证明
定律，代码等式由后端理论单独安装（`code_datatype Mapping`）。
`AList_Mapping` 不要求键有序、结构简单，适合原型与小数据；
`RBT_Mapping` 要求键可线性排序，换来有保证的对数复杂度。

选型经验：

- **做形式化推理**（在更大的开发里证明关于有限字典的定理、用
  transfer 在抽象层与普通偏函数层之间搬运、构造商类型）选 **fmap**：
  它的常量直接出现在项里，`fmlookup` 是态射，围绕它的规则网
  （`fmupd_lookup`、`fmlookup_add`、`fmap_ext`……）最密。
- **组织要导出可执行代码的库接口**选 **mapping**：表示被刻意藏起，
  后端可以随数据规模替换，客户端证明与代码都不受影响。

## 57.9 坑位清单（实测）

1. `Finite_Map` / `AList_Mapping` 都属于 `HOL-Library` 会话，
   必须以 imports 形式引入（如 `"HOL-Library.Finite_Map"`）；
   裸名在 Main 会话报 undefined。
2. `fmdom` 与 `fmran` 返回 **fset**；返回普通 `set` 的是带撇的
   `fmdom'`（关系版本另有 `fmran'`）。fset 值打印成
   `Abs_fset {…}` 不是出错，是 typedef 构造子的正常显示。
3. fmap 没有字面量语法，构造一律走 `fmempty` / `fmupd` /
   `fmap_of_list`；不要凭印象写出 `{| k ↦ v |}` 这类记号（那是
   fset 的双竖线，而且 fset 里也没有键值对语法）。
4. fset 字面量是双竖线 `{| … |}`（空集 `{||}`），别和多重集的
   `{# … #}`（第 45 章）、普通集合的 `{ … }` 混。
5. `m ++⇘f n` 是**右表优先**（与 `map_add` 同向）；想让新值胜出，
   把更新写在右边。
6. 同一理论里不要同时导入 `AList_Mapping` 和 `RBT_Mapping`：两边都
   用 `code_datatype` 安装构造子 `Mapping`，代码等式会互相覆盖；
   一个理论只选一个后端。
7. `sorted_list_of_fmap` 与 RBT 后端都要求键类型是 `linorder`，
   只有 `order` 不够。
8. `fmfilter` 只按键筛（谓词类型 `'a ⇒ bool`）；按值筛用
   `fmpred` 表达。
9. 大写构造子 `Mapping` 只在后端理论里可用；只导入核心
   `Mapping` 理论时 `value` 会报「没有代码等式」。
10. `size`、`fset_of_fmap`、`fmimage`、`fmpred` 的代码等式展开为
    在整个类型上收集的普通集合，`value` 只接受 `enum`（有限可枚举）
    元素类型；无穷类型上要结果就写引理（`fset_eq_iff` + 成员关系
    iff 是标准抓手），或改用 `sorted_list_of_fmap`。另外，fmap
    每键至多一个值，没有「重数」概念——需要重数回第 45 章的
    multiset。

## 57.10 与其他章的接口

- 第 14 章集合、第 40 章 Main 库漫游：fmap 是那里 `'a ⇀ 'b` 的
  有限化、可执行化版本。
- 第 28 章 typedef、第 29 章 quotient/transfer：fmap 与 mapping 都是
  Lifting 流水线的成品，`transfer` 是回到普通偏函数层的回程票。
- 第 45 章 multiset：袋子（重数）与字典（单值）的分工。
- 第 58 章 FSet：`fmdom`/`fmran`/`fmimage` 的值域类型。
- 第 59 章红黑树：Mapping 的对数后端 `RBT_Mapping`。
