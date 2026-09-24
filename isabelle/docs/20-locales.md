# 20 · Locale 与抽象代数结构

对应示例：`../examples/T20_locales.thy`

## 20.1 locale 解决什么问题

要写"任给一个满足某某性质的结构，则……"这类数学，最笨的写法是把一串 `assumes` 塞进每个 `lemma`。写了十几个引理之后，假设列表就变成难以维护的复制粘贴。

**locale 把"一组固定的参数 + 一组关于它们的假设"打包成一个可复用的上下文**：在里面证明的定理带上"局部性"，离开时自动泛化成带 `\<lbrakk>\<rbrakk>` 的定理，并可以被具体结构实例化。

## 20.2 定义第一个 locale

```isabelle
locale semigroup =
  fixes mult :: "'a \<Rightarrow> 'a \<Rightarrow> 'a"   (infixl "\<cdot>" 70)
  assumes assoc: "(x \<cdot> y) \<cdot> z = x \<cdot> (y \<cdot> z)"

print_locale semigroup
```

```text
locale T20_locales.semigroup
  fixes mult :: "'a \<Rightarrow> 'a \<Rightarrow> 'a"  (infixl \<open>\<cdot>\<close> 70)
  assumes "T20_locales.semigroup (\<cdot>)"
```

`fixes` 声明参数（可以带具体语法，这里给了中缀 `\<cdot>`），`assumes` 声明性质。**`assumes` 里出现的自由变量一律被自动全称量化**，所以 `assoc` 看起来是"关于三个变量的乘法结合律"。

`print_locale` 的输出值得细看：它把 locale 的完整内容列出来，包括**理论名前缀**（`T20_locales.semigroup`）。这是排查"到底要证几条假设"的最快手段。

（同一个 `print_locale semigroup` 在输出里出现了三次，是因为后面 `sublocale` 注册之后又有引用触发了打印。）

## 20.3 进到 locale 里

```isabelle
context semigroup
begin

lemma assoc4: "((a \<cdot> b) \<cdot> c) \<cdot> d = a \<cdot> (b \<cdot> (c \<cdot> d))"
  by (simp add: assoc)

end
```

```text
theorem assoc4: ?a \<cdot> ?b \<cdot> ?c \<cdot> ?d = ?a \<cdot> (?b \<cdot> (?c \<cdot> ?d))
```

进了 `context semigroup begin … end`，`mult` 和 `assoc` 就在作用域里，写 `a`、`b` 不用声明类型，也不用重复假设。

**离开 context 之后，`assoc` 不再自动可见**，要写限定名 `semigroup.assoc`。而且 `assoc4` 的完整形态是

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
semigroup mult ⟹ ((a ⋅ b) ⋅ c) ⋅ d = a ⋅ (b ⋅ (c ⋅ d))
```

也就是说：**locale 名同时也是一个谓词**，用来把假设重新收回来。这是 locale 的核心机制——"局部定理"在全局看就是"带 locale 谓词作前提的定理"。

## 20.4 继承与叠加

```isabelle
locale monoid = semigroup +
  fixes one :: "'a"  ("\<one>")
  assumes left_neutral: "\<one> \<cdot> x = x"
      and right_neutral: "x \<cdot> \<one> = x"

print_locale monoid

context monoid
begin
lemma neutral_idem: "\<one> \<cdot> \<one> = \<one>"
  by (simp add: left_neutral)
end
```

```text
locale T20_locales.monoid
  fixes mult :: "'a \<Rightarrow> 'a \<Rightarrow> 'a"  (infixl \<open>\<cdot>\<close> 70)
    and one :: "'a"  (\<open>\<one>\<close>)
  assumes "T20_locales.monoid (\<cdot>) \<one>"

theorem neutral_idem: \<one> \<cdot> \<one> = \<one>
```

`monoid = semigroup + …` 表示：继承 `semigroup` 的参数与假设，再补上 `one` 和两个单位元律。同名假设被并入同一套待证列表——`print_locale` 会把合并后的结果完整列出。

## 20.5 interpretation：装到具体类型上

```isabelle
interpretation list_monoid: monoid "(\<lambda>xs ys :: 'a list. xs @ ys)" "[]"
  by unfold_locales simp_all

thm list_monoid.right_neutral
```

```text
?x @ [] = ?x

theorem nat_add_monoid: T20_locales.monoid (+) 0
```

（`thm list_monoid.right_neutral` 打印成 `?x @ [] = ?x`——实例化的定理已经特化到列表上了。）

`unfold_locales` 把 locale 的全部假设摊成子目标，接上 `simp_all` 一次证完。

**注意 lambda 上的类型标注 `:: 'a list`**：缺了它，`xs @ ys` 的元素类型会被推断成一个全新的未知类型参数，实例就不是多态的了。这是本章最容易踩的一条。

locale 名作谓词用时同样可以 `unfold_locales`：

```isabelle
lemma nat_add_monoid: "monoid (\<lambda>a b :: nat. a + b) 0"
  by unfold_locales (simp_all add: add.assoc)
```

```text
theorem nat_add_monoid: T20_locales.monoid (+) 0
```

这里刻意写 `(\<lambda>a b :: nat. a + b)` 而不是 `(op +)`——**`op` 前缀形式在近年的 Isabelle 里已不再推荐**，带类型标注的 lambda 更稳，也更容易看出实例化到底选中了哪个加法。

## 20.6 sublocale：永久注册的结构推导

```isabelle
sublocale semigroup \<subseteq> dual: semigroup "(\<lambda>x y. y \<cdot> x)"
  by unfold_locales (simp add: assoc)

context semigroup
begin
thm dual.assoc
end
```

```text
?z \<cdot> (?y \<cdot> ?x) = ?z \<cdot> ?y \<cdot> ?x
```

区别在于：

| 命令 | 含义 |
|---|---|
| `interpretation` | "**这一处**要用这个实例" |
| `sublocale` | "**从今往后**，只要说 semigroup 就自动也有一份 dual" |

`sublocale` 注册的是一条永久规则，源 locale 的任何上下文里都能用。

`dual.assoc` 的内容是 `z ⋅ (y ⋅ x) = (z ⋅ y) ⋅ x`——把乘法反过来依然满足结合律，是原结合律的镜像。

## 20.7 交换律：不能当 simp 规则的例子

```isabelle
locale comm_monoid = monoid +
  assumes comm: "x \<cdot> y = y \<cdot> x"

context comm_monoid
begin
lemma left_comm: "x \<cdot> (y \<cdot> z) = y \<cdot> (x \<cdot> z)"
  by (metis assoc comm)
end
```

```text
theorem left_comm: ?x \<cdot> (?y \<cdot> ?z) = ?y \<cdot> (?x \<cdot> ?z)
```

**`comm` 不能当 `simp` 规则**：它是自对称的（`x ⋅ y = y ⋅ x` 反过来还是自己），`simp` 会拒绝或者原地打转。这种"重排"类的等式用 `metis` 最稳——第 17 章讲过，`metis` 擅长把等式拼起来，不受重写方向限制。

对比一下第 10 章的 `foldl_foldr`：那里用的是 `add.commute add.left_commute add.assoc` 三条喂给 `simp`。原因是 `+` 在 `nat` 上**有额外的化简规则**（`simp` 会按项的某种序排列），而这里的 `\<cdot>` 是抽象运算，没有任何序可用。

## 20.8 locale 与类型类的分工

| | locale | 类型类（`class`） |
|---|---|---|
| 参数个数 | 任意（`mult`、`one` 都是参数） | 恰好一个类型变量 |
| 实例化 | 显式 `interpretation` | 隐式，靠类型推断 |
| 多实例 | 同一类型可以有多个 | 同一类型只能有一个 |
| 典型用途 | 代数结构、语义框架 | `plus`、`zero`、`ord` 这类记号重载 |

判断标准：**需要同一类型的多个实例就用 locale**（比如 `nat` 上的 `+` 和 `*` 都是 monoid）；只需要一个、且希望记号自动可用就用类型类。

最后一条方向性事实：**locale 里的假设是假设，不是事实**。如果某个结构其实满足更多性质（比如某个 monoid 恰好可交换），要靠 `sublocale` 或 `interpretation` 补一张新的证明义务，而不是直接改原来的 locale。

---

## 本章坑位清单（实测）

1. **`fixes` 的 lambda 没写类型标注**：`(\<lambda>xs ys. xs @ ys)` 会推出全新类型参数，实例不是多态的。写 `(\<lambda>xs ys :: 'a list. …)`。
2. **用 `op +` 这种旧写法**：近年的 Isabelle 不再推荐。写带类型标注的 lambda。
3. **出了 context 直接用 `assoc`**：要写 `semigroup.assoc`。同理实例里的写 `list_monoid.right_neutral`。
4. **把 `comm` 加进 `simp`**：自对称等式会让 `simp` 打转。用 `metis` 显式拼。
5. **`interpretation` 忘了 `unfold_locales`**：假设不会自动证。
6. **该用 `sublocale` 时用了 `interpretation`**：后者只在当前位置生效，别处拿不到。
7. **以为能改 locale 的假设**：假设是固定的。要加性质就新建 locale 或 `sublocale`。
8. **`print_locale` 看到理论名前缀就以为出错**：`T20_locales.semigroup` 是完整限定名，正常。
9. **继承时用 `+` 却重复声明同名参数**：会报重复声明。继承的参数不用重写。
10. **以为 locale 实例能自动被 `simp` 用**：实例只是让定理可引用，不会自动进化简集。

---

上一章：[19 · 代码生成](19-codegen.md) ｜ 下一章：[21 · 会话与工程组织](21-sessions.md) ｜ 返回：[README](../README.md)
