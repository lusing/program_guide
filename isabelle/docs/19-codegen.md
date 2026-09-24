# 19 · 代码生成：从定义到可执行程序

对应示例：`../examples/T19_codegen.thy`

## 19.1 定义既是逻辑对象，也是程序

Isabelle 里的 `fun` / `primrec` / `definition` 有双重身份：

- **逻辑对象**：带生成定理（`f.simps`、`f.induct`），可以被 `simp` 用、可以归纳；
- **可执行程序**：代码生成器把它们翻译成 ML / OCaml / Haskell / Scala。

第二重身份是 `value` 能算出结果、`by eval` 能当证明方法的原因。本章讲三件事：三种求值引擎、代码方程怎么选、怎么导出真源码。

## 19.2 三种求值引擎

拿一个经典的非尾递归定义当样本：

```isabelle
fun fib :: "nat \<Rightarrow> nat" where
  "fib 0 = 0"
| "fib (Suc 0) = 1"
| "fib (Suc (Suc n)) = fib n + fib (Suc n)"

value "fib 10"
```

```text
consts
  fib :: "nat \<Rightarrow> nat"

Found termination order: "size <*mlex*> {}"

"55"
  :: "nat"
```

默认引擎是 `code`：把 `fib` 编译进 Poly/ML 再跑。最快，但需要 ML 运行时。

第二种是 `nbe`（**求值即归一化**，normalisation by evaluation）：

```isabelle
value [nbe] "fib 10"
```

```text
"55"
  :: "nat"
```

`nbe` 不生成 ML，而是在内核里把项重写到范式。**它能算部分实例化的项**（比如 `fib n` 在 `n` 未知时也能做一部分化简），这是 ML 引擎做不到的。

第三种 `code_simp` 只是把代码方程当 `simp` 规则用，纯符号化。

三者都能当**证明方法**：

| 写法 | 机制 |
|---|---|
| `by eval` | 编译执行后比对 |
| `by normalization` | 归一化为同一范式 |
| `by code_simp` | 用代码方程做符号化简 |

实测三条都过了同一条等式：

```text
theorem fib 10 = 55

theorem fib 10 = 55

theorem fib 10 = 55
```

（三条都没命名，所以打印出来不带名字前缀。）

## 19.3 尾递归与辅助引理

```isabelle
fun trev :: "'a list \<Rightarrow> 'a list \<Rightarrow> 'a list" where
  "trev [] ys = ys"
| "trev (x # xs) ys = trev xs (x # ys)"

lemma trev_eq: "trev xs ys = rev xs @ ys"
  by (induction xs arbitrary: ys) auto
```

```text
consts
  trev :: "'a list \<Rightarrow> 'a list \<Rightarrow> 'a list"

Found termination order: "(\<lambda>p. length (fst p)) <*mlex*> {}"

theorem trev_eq: trev ?xs ?ys = rev ?xs @ ?ys

"[4, 3, 2, 1]"
  :: "nat list"

theorem trev [1, 2, 3, 4] [] = [4, 3, 2, 1]
```

`trev_eq` 是第 6 章那个 `itrev` 套路的复现：累加器版本必须配 `arbitrary: ys`，否则归纳假设太弱。这再次说明——**能求值不等于能证明**。`value` 过得去的东西，性质还是要自己证。

## 19.4 代码方程与 `[code]` 属性

代码生成器的输入不是源定义本身，而是**一组代码方程**。

```isabelle
definition my_len :: "'a list \<Rightarrow> nat" where
  "my_len xs = foldr (\<lambda>_ n. Suc n) xs 0"

value "my_len [1::nat, 2, 3, 4, 5]"
```

```text
consts
  my_len :: "'a list \<Rightarrow> nat"

"5"
  :: "nat"
```

`definition` 会把定义式**整条**搬进代码方程。所以用 `foldr` 写的 `my_len`，导出后在目标语言里仍然是一个折叠，不会被自动改写成递归函数。

想换掉默认实现，给一组标了 `[code]` 的定理：

```isabelle
lemma [code]: "my_len [] = 0"
  by (simp add: my_len_def)

lemma [code]: "my_len (x # xs) = Suc (my_len xs)"
  by (simp add: my_len_def)

value "my_len [1::nat, 2, 3, 4, 5]"
```

```text
theorem my_len [] = 0

theorem my_len (?x # ?xs) = Suc (my_len ?xs)

"5"
  :: "nat"
```

**顺序很重要**：先出口条件、再递归步，代码生成器按声明顺序从上往下匹配。

一条容易忽略的性质：`[code]` 定理**首先是一条普通定理**——你必须证明它。代码生成器不管它从哪来，只管它是一条等式。所以**写错方向会让导出代码与原定义不等价，而 Isabelle 不会替你检查**——因为它是你自己证明过的等式。

这是"证明即认证"的另一面：机器保证你证的东西为真，但不保证你想证的东西是你想要的。

## 19.5 导出到目标语言

```isabelle
definition my_max :: "nat \<Rightarrow> nat \<Rightarrow> nat" where
  "my_max a b = (if a \<le> b then b else a)"

fun ins :: "nat \<Rightarrow> nat list \<Rightarrow> nat list" where
  "ins x [] = [x]"
| "ins x (y # ys) = (if x \<le> y then x # y # ys else y # ins x ys)"

fun isort :: "nat list \<Rightarrow> nat list" where
  "isort [] = []"
| "isort (x # xs) = ins x (isort xs)"

value "isort [3::nat, 1, 4, 1, 5]"
```

```text
consts
  my_max :: "nat \<Rightarrow> nat \<Rightarrow> nat"

consts
  ins :: "nat \<Rightarrow> nat list \<Rightarrow> nat list"

Found termination order: "(\<lambda>p. size_list size (snd p)) <*mlex*> {}"

consts
  isort :: "nat list \<Rightarrow> nat list"

Found termination order: "size_list size <*mlex*> {}"

"[1, 1, 3, 4, 5]"
  :: "nat list"
```

导出：

```isabelle
export_code my_max in SML module_name T19_Code
export_code my_max ins isort in SML module_name T19_List
export_code my_max ins isort in OCaml module_name T19_List
export_code my_max ins isort in Haskell module_name T19_List
export_code my_max ins isort in Scala module_name T19_List
```

实测输出只有五行：

```text
See theory exports

See theory exports

See theory exports

See theory exports

See theory exports
```

**不带 `file` 参数时，产物进 Isabelle 自己的导出区**（jEdit 的 Export 面板里可见），不污染源码目录。这是推荐的写法——本教程的验证脚本会比对两次运行的字节，落文件到源码目录会引入噪声。

要列出**全部要导出的常量**；依赖（如 `isort` 用到的 `@`）会被自动带上。

导出不需要本机装对应编译器。**写代码是一回事，编译是另一回事**——真要编译验证是 shell 里 `mlton` / `ocamlfind` 的事，不在证明助手的职责范围内。

## 19.6 什么不能生成代码

遇到 `value` 或 `export_code` 报 `no code equation` 的，通常是这四类：

1. **用了选择算子 `SOME` / `THE` 的定义**——`Hilbert_Choice` 里的东西基本都不可执行；
2. **说明式定义**——比如用 `Least` 描述最小值，它是个描述而不是算法；
3. **`inductive` 定义的谓词**——可以额外部署 `code_pred` 让它们变成可枚举的生成器，那是另一套设施；
4. **类型层面没有对应表示的东西**——比如真函数类型 `'a ⇒ 'b`。

对应的办法通常是：先证明一个**可计算的**实现与说明式定义等价，再用 `[code]` 把实现装进去。19.4 的 `my_len` 就是这个套路的最小样本。

## 19.7 用 `code_datatype` 定制后端表示

`Set` 之类的抽象类型，代码生成器把它实现成 `List.coset`（补集表示）。
`code_datatype` 用来把某个类型映射到**指定**的构造器集合。最有代表性的
场景是自己定义了一个抽象类型，想用另一份具体的表示来导出代码。

```isabelle
datatype 'a wrapped = Wrap "'a list"

primrec unwrap :: "'a wrapped \<Rightarrow> 'a list" where
  "unwrap (Wrap xs) = xs"

code_datatype Wrap

value "unwrap (Wrap [1::nat, 2, 3])"
```

`code_datatype Wrap` 之后，导出时 `wrapped` 后端表示**直接**是 `Wrap` 构造器，
跟 `list` 的表示同构。不加这条也能跑，只是加之后后端表现更贴近 `list`。
HOL 里 `set` 类型的 `code_datatype List.coset` 就是同一个套路——因为
`Set` 是 `typedef`，不指明构造器代码生成器根本找不到表示。

## 19.8 `code_module` / 目标限定 / `code_identifier`

导出时对单个常量加 `(Haskell)` / `(SML)` 这样的**目标限定**，只影响指定后端；
`code_module` 把一堆常量绑成一个可复用模块；`code_module_attribute` 给生成
模块头加一段固定文本。这类"目标限定"的语法与 `export_code` 同族，具体形式
见 `codegen.pdf` §4；本教程只在 19.5 演示基础形式的 `export_code ... in SML/
OCaml/Haskell/Scala`，高级形式留给读者。

## 19.9 让导出保持稳定的两条纪律

- **`export_code` 不带 `file` 参数**：产物进 Isabelle 的 export 区、不进工作树，
  两遍输出比对不受影响。
- **绝对路径**：一旦 `file` 里出现 `/Users/…` 或 `/home/…`，macOS 与 Linux
  两端逐字节比对**直接崩**。要么用相对路径，要么不带 `file`。

---

## 本章坑位清单（实测）

1. **`export_code` 忘了列某个常量**：只列你提到的，依赖是自动带的；但同一层次的多个入口常量必须全列出来。
2. **`[code]` 定理顺序写反**：递归步写在出口条件之前会导致匹配顺序错。先出口、后递归。
3. **给 `[code]` 写了假等式**：Isabelle 不管语义，只要你证出来。写错方向会静默导出不等价代码。
4. **对 `Hilbert_Choice` 的东西 `value`**：报 `no code equation`。改用可计算实现 + 等价性定理。
5. **对 `inductive` 谓词 `value`**：谓词没有代码方程，要 `code_pred` 或改写成函数。
6. **以为 `value` 能证性质**：`value` 只算具体实例。`trev [1,2,3,4] []` 得出 `[4,3,2,1]` 不等于证明了 `trev_eq`。
7. **`by eval` 用在含变量的项上**：`eval` 要完全实例化。含变量用 `by normalization` 或 `by code_simp`。
8. **`export_code` 带 `file` 落进源码目录**：会污染比对区间。不带 `file` 是推荐写法。
9. **`definition` 期待被自动改写成递归**：不会。它把定义式整条搬进代码方程，想要别的实现就给 `[code]`。
10. **`nbe` 与 `code` 结果不同就以为有 bug**：两者机制不同（`nbe` 走内核归一化），结果应当一致但性能差很多。大计算用 `code`。

---

上一章：[18 · 案例：一个小语言的霍尔逻辑](18-hoare.md) ｜ 下一章：[20 · Locale 与类型类](20-locales.md) ｜ 返回：[README](../README.md)
