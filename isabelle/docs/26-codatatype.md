# 26 · 共归：`codatatype` 与 `primcorec`

对应示例：`../examples/T26_codatatype.thy`

## 26.1 从 datatype 到 codatatype

第 4 章的 `datatype` 声明的是**最小**不动点：类型里的每个元素都必须在**有限**步内由构造器搭出来。`codatatype` 反过来，声明**最大**不动点：允许存在**无限**深的构造。经典例子是流（stream）与无限树。

三条对称性要提前记住：

| datatype | codatatype |
|---|---|
| `primrec`（结构递归，必须终止） | `primcorec`（结构共归，逐层吐构造子） |
| `induct`（对结构做归纳） | `coinduct`（对关系做共归纳） |
| 注入性 / 互异性 | 判别式 `is_X` + 选择子 `sel` |

无限对象要**观察得够多步**才能区分；因此"相等"的正确说法是"永远观察不出区别"——**双相似（bisimilar）**，也就是 `coinduction` 要证的东西。

## 26.2 一个最小的纯流 codatatype

```isabelle
codatatype 'a stream = SCons (shead: 'a) (stail: "'a stream")

term SCons
term stail
```

```text
"SCons"
  :: "'a \<Rightarrow> 'a stream \<Rightarrow> 'a stream"

"stail"
  :: "'a stream \<Rightarrow> 'a stream"
```

`codatatype` 除了 `SCons` 与两个选择子之外，还会自动生成一堆 `typerep_stream`、`equal_stream`、`random_stream`、`term_of_stream`——`thm stream.collapse` 把它们统一展开成 `SCons (shead s) (stail s) = s`：

```text
SCons (shead ?stream) (stail ?stream) = ?stream
```

这条是共归证明里最常用的**结构展开引理**。

## 26.3 `primcorec`：逐层写构造子

`primcorec` 是 `primrec` 的对偶：每条方程描述**当前一层**的构造子长什么样，而不是"缩小到基本情况"。

```isabelle
primcorec repeat :: "'a \<Rightarrow> 'a stream" where
  "shead (repeat x) = x" |
  "stail (repeat x) = repeat x"
```

```text
consts
  repeat :: "'a \<Rightarrow> 'a stream"

  shead (repeat ?x) = ?x
  stail (repeat ?x) = repeat ?x
```

方程右边直接说 `shead = x`、`stail = repeat x`——`primcorec` 接受"结构上生产一层，递归只在 co-recursor 位置"的定义。

## 26.4 第二个例子：`upto`

```isabelle
primcorec upto :: "nat \<Rightarrow> nat stream" where
  "shead (upto n) = n" |
  "stail (upto n) = upto (Suc n)"
```

```text
  shead (T26_codatatype.upto ?n) = ?n
  stail (T26_codatatype.upto ?n) = T26_codatatype.upto (Suc ?n)
```

**注意**：`corec`（更宽松的共归，允许 `case`/`if` 分派）**不**在 `Main` 里——它来自 `HOL-Eisbach`/`HOL-Corec` 会话。只 `imports Main` 时 `primcorec` 是唯一选项；本教程的 ROOT 只依赖 `HOL`，所以刻意避开 `corec`。

## 26.5 一条平凡的共归方程

`primcorec` 已经把 `stail (repeat x) = repeat x` 写进 `repeat.simps`，直接 `simp` 就能证——这也是共归定义用起来最爽的一面：**方程就是构造子的选择子方程**。

```isabelle
lemma stail_repeat: "stail (repeat x) = (repeat x :: 'a stream)"
  by simp
```

```text
theorem stail_repeat: stail (repeat ?x) = repeat ?x
```

如果非要走 `coinduction`：`stream.coinduct` 生成的 case 名带类型前缀（`eq_stream` / `less_eq_stream`），得先 `thm stream.coinduct` 查出来才能写 `case eq_stream`。本教程的 ROOT 环境下不演示这条，是为了保持示例的**最短可跑路径**。

## 26.6 无限树：codatatype 里嵌 codatatype

```isabelle
codatatype 'a tree = Node (lab: 'a) (lch: "'a tree") (rch: "'a tree")

primcorec grow :: "nat \<Rightarrow> nat tree" where
  "lab (grow n) = n" |
  "lch (grow n) = grow (n + 1)" |
  "rch (grow n) = grow (n + 1)"
```

```text
  lab (grow ?n) = ?n
  lch (grow ?n) = grow (?n + 1)
  rch (grow ?n) = grow (?n + 1)
```

这里没有基本情况（"叶"）——一棵树就是一条无限路径上的观察。

## 26.7 与 `primrec` 的边界

常见坑：`primrec` 用在 `codatatype` 上。`primrec` 要求结构递归"变小"，`codatatype` 没有基本情况可言，一旦递归穿透 co-recursor 位置 `primrec` 就拒。但**只看一层**是允许的——例如 `lab` 选择子返回 `'a`，不是 `'a tree`。

```isabelle
definition root_lab :: "nat tree \<Rightarrow> nat" where
  "root_lab t = lab t"

lemma root_lab_grow [simp]: "root_lab (grow n) = n"
  unfolding root_lab_def by simp
```

## 26.8 坑位清单（实测）

1. **别 `value` 一条无限对象**：写 `value "root_lab (grow 5)"` 会挂——`value` 走代码生成路径，遇到 `codatatype` 会尝试构造整个无限对象。用 `lemma [simp]` + `by simp` 得同样的答案 `5`。
2. **`codatatype stream = SCons (shead: 'a) (stail: "stream")` 报 `Extra type variables on right-hand side`**：codatatype 也要写类型参数，`codatatype 'a stream = ... (stail: "'a stream")`。
3. **多构造子的 `codatatype` 上 `primcorec` 需要 `is_STerm` 判别式**：本教程用**单构造子**（纯流），去掉判别式方程负担；写两条构造子时得把 `is_X ...` 补齐。
4. **`corec` 命令**：`HOL-Corec`/`HOL-Eisbach` 才提供。`imports Main` 时只 `primcorec` 可用。
5. **`stream.coinduct` 的 case 名**：与 datatype 的 `induct` 命名规则不同，是 `eq_stream` / `less_eq_stream`，得先 `thm stream.coinduct` 查。
6. **`codatatype` 与 `datatype` 不共享 induction**：用错名字（`stream.induct`）报 `Undefined fact`；写 `stream.coinduct` 才对。
7. **`coinduction` 与 `induct` 一样需要 `arbitrary:`**：把泛化的变量绑进 bisimulation，否则找不到合适的关系。
8. **`primcorec` 的递归调用**只能出现在 co-recursor 位置（构造子的选择子参数槽）——一旦出现在其他位置就等价于普通 `fun`，需要 termination。
9. **`typerep_stream` 之类的自动常量**：`codatatype` 会送出一堆 code generation / Quickcheck / random 生成用的辅助常量，看着像噪声，其实都是给 `[code]` 属性用的；不要手动重定义。
10. **`thm stream.collapse`**：`SCons (shead s) (stail s) = s` 是共归证明里的"结构展开"引理，遇到 `simp` 拆不开流时先加它。

---

上一章：[25 · 类型类](25-classes.md) ｜ 下一章：[27 · Eisbach 方法 DSL](27-eisbach.md) ｜ 返回：[README](../README.md)
