# 05 · 递归与终止性

对应示例：`../examples/T05_recursion.thy`

## 5.1 递归的多种写法与终止性

`fun` 必须让机器相信"递归总会终止"。**结构递归**（参数在构造上变小）自动通过；非结构递归要给出度量函数。HOL 是**全函数**逻辑——不允许不终止的函数存在，否则 `half x = half x + 1` 就能推出 `0 = 1`。

四种写法按严格程度排：

| 写法 | 接受什么 | 需要终止性证明吗 |
|---|---|---|
| `primrec` | 只接受结构递归 | 从不 |
| `fun` | 结构递归，以及机器能找到度量的 | 自动尝试 |
| `function` + `termination` | 任意 | 必须手写 |
| `partial_function` | 任意（语义上允许不终止） | 不需要（但结论弱化） |

## 5.2 primrec：最原始的结构递归

```isabelle
primrec sum_to :: "nat \<Rightarrow> nat" where
  "sum_to 0 = 0"
| "sum_to (Suc n) = Suc n + sum_to n"
```

```text
consts
  sum_to :: "nat \<Rightarrow> nat"
```

```text
"55"
  :: "nat"
```

`primrec` 只接受结构递归，否则**定义阶段**直接报错（不是证明阶段）。它比 `fun` 严格，也因此从不需要终止性证明。想快速定义一个明显结构递归的函数时，`primrec` 的报错更好读。

## 5.3 fun：结构递归的默认选择

```isabelle
fun app3 :: "'a list \<Rightarrow> 'a list \<Rightarrow> 'a list \<Rightarrow> 'a list" where
  "app3 [] ys zs = ys @ zs"
| "app3 (x # xs) ys zs = x # app3 xs ys zs"
```

```text
Found termination order: "(\<lambda>p. length (fst p)) <*mlex*> {}"
```

```text
"[1, 2, 3, 4]"
  :: "nat list"
```

多参数时度量是对**参数元组**的函数：`\<lambda>p. length (fst p)`，即"看第一个参数的长度"。`<*mlex*>` 是 mlex（多参数字典序）组合子。

## 5.4 非结构递归：half 与度量函数

```isabelle
fun half :: "nat \<Rightarrow> nat" where
  "half 0 = 0"
| "half (Suc 0) = 0"
| "half (Suc (Suc n)) = Suc (half n)"
```

```text
Found termination order: "size <*mlex*> {}"
```

`half` 每次递归少 2，**不是结构递归**（`Suc (Suc n)` 与 `Suc n` 不是构造器的直接子项）。但 Isabelle 自动找到了 `size`（在 `nat` 上就是恒等）作度量——`size n < size (Suc (Suc n))` 显然成立。

再看 `gcd2`：

```isabelle
fun gcd2 :: "nat \<Rightarrow> nat \<Rightarrow> nat" where
  "gcd2 m 0 = m"
| "gcd2 m (Suc n) = gcd2 (Suc n) (m mod Suc n)"
```

```text
Found termination order: "(\<lambda>p. size (snd p)) <*mlex*> {}"
```

度量是"第二个参数在变小"，靠的是 `mod` 的性质。（实测 `gcd2 1071 462` = `"21" :: "nat"`。）

机器找不到度量时会退回交互模式：先由 `function` 给出**带前提**的方程，再用 `termination` 补证——第 16 章展开全套流程。

## 5.5 观察 fun 送给你的化简规则

（实测，来自 `@{thms half.simps}` 的第一条与第三条）：

```text
"half 0 = 0"
```

```text
"half (Suc (Suc ?n)) = Suc (half ?n)"
```

上面两条是 `half.simps` 的**第 1 条与第 3 条**（用 `hd` 与 `hd (tl (tl ...))` 取出）。想看全貌就 `thm half.simps`——**不要假设 `simps` 的方程条数等于你写的条数**，模式编译会重排和合并。

一条一行就过的定理：

```isabelle
lemma half_twice: "half (n + n) = n"
  by (induction n) simp_all
```

```text
theorem half_twice: half (?n + ?n) = ?n
```

能一行过，是因为 `half.simps` 在化简器里，`n + n` 归纳展开后恰好撞进 `half` 的方程。化简器的工作方式第 7 章拆开讲。

## 5.6 再练一遍：嵌套递归 datatype 的翻转对合

```isabelle
datatype 'a my_tree = Leaf | Node "'a my_tree" 'a "'a my_tree"

fun my_mirror :: "'a my_tree \<Rightarrow> 'a my_tree" where
  "my_mirror Leaf = Leaf"
| "my_mirror (Node l x r) = Node (my_mirror r) x (my_mirror l)"
```

```text
"Node (Node Leaf 2 Leaf) 1 Leaf"
  :: "nat my_tree"
```

```text
theorem my_mirror_twice: my_mirror (my_mirror ?t) = ?t
```

`by (induction t) auto`。这里 `auto` 能用，因为 `my_mirror` 的两个方程都在 `simps` 里，归纳假设又恰好对上。

---

## 本章坑位清单（实测）

1. **`primrec` 里写非结构递归**：定义阶段就报错，报错信息会指出哪一层不是"直接子项"。
2. **以为 `fun` 的方程条数 = `simps` 条数**：模式编译会合并/重排，`thm f.simps` 才是真相。
3. **`Found termination order` 没出现不代表出错**：`primrec` 从不打印它。
4. **多参数的度量看不出来**：`\<lambda>p. length (fst p)` 这种写法说明机器在对元组做度量，读不懂时先想"哪个参数在变小"。
5. **度量找不到就硬改算法**：多数非结构递归可以改写成累加器版本（第 6 章的 `itrev`）变成结构递归，比手证终止性省事。
6. **`function` 不给 `termination` 就走不下去**：方程会带前提 `f_dom`，用起来处处要证。
7. **`partial_function` 的结论是"如果返回 Some，则…"**：它把不终止编码成 `None`，定理陈述会多一层 `option`，别当普通函数用。
8. **递归调用写在构造器参数里但参数没变小**：`f (Suc n) = f (Suc n)` 之类必然失败，报 `Could not find termination order`。
9. **`size` 在自定义 datatype 上也可用作度量**：`datatype` 免费送 `size`，所以 `Found termination order: "size <*mlex*> {}"` 很常见。
10. **以为全函数逻辑只是"限制"**：正因为全函数，`simp` 才能无条件用 `f.simps` 重写而不引入前提——这是自动化能跑起来的地基。

---

上一章：[04 · 数据类型](04-datatype.md) ｜ 下一章：[06 · 归纳](06-induction.md) ｜ 返回：[README](../README.md)
