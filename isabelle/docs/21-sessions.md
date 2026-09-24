# 21 · 会话、名字空间与工程组织

对应示例：`../examples/T21_sessions.thy`

## 21.1 会话是 Isabelle 的工程单位

单个 `.thy` 文件叫**理论**（theory）；一批理论加上构建配置叫**会话**（session）。会话用 `ROOT` 文件描述，本教程 `examples/ROOT` 的核心内容就是这三行：

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
session IsaTut = HOL +

options [document = false]

theories T01_overview ... T24_capstone
```

- 第一行声明**父会话**：`HOL` 决定这份工程从哪个 heap 镜像起步，也就是 `imports Main` 背后那套东西从哪来。
- 第二行是构建选项：`document = false` 关掉 LaTeX 照排（要出 PDF 就写 `document = true` 并配 `root.tex`）。
- 第三行是理论清单：列表**有序**，但**依赖仍然由文件里的 `imports` 决定**，清单只控制加载与错误处理顺序。

构建入口：

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
isabelle build -D examples
```

它先检查依赖，再按需重新处理理论，最后把会话的 heap 镜像写进用户 heaps 目录。**第二次构建几乎瞬时**——前提是没有改过任何被依赖的理论。这就是 heap 机制的价值：改一个文件不会导致整个库重编。

会话还能被子会话继承（`session Sub = IsaTut + …`），这就是 `HOL-Library` 这类"父 + 库"套娃的来源。

## 21.2 名字空间：全名、隐藏与开放

```isabelle
definition helper :: "nat \<Rightarrow> nat" where
  "helper n = n + 1"

lemma helper_pos: "0 < helper n"
  by (simp add: helper_def)

hide_const (open) helper
```

```text
consts
  helper :: "nat \<Rightarrow> nat"

theorem helper_pos: 0 < helper ?n

theorem helper_pos2: 0 < T21_sessions.helper ?n
```

每个理论里的声明都有带理论名前缀的**完整名字**：`helper` 的全名是 `T21_sessions.helper`。平时能用短名，是因为名字空间把同名条目"开放"了出来。

`hide_const (open) helper` 把短名收回去，只留全名。从这一行往下必须写：

```isabelle
lemma helper_pos2: "0 < T21_sessions.helper n"
  by (simp add: T21_sessions.helper_def)
```

实测输出印证了：第一条定理打印成 `helper ?n`，第二条是 `T21_sessions.helper ?n`——**虽然它们是同一个常量**。

`hide_const` 在"我的定义和库里的撞名"时很有用：与其给自己的东西起一个别扭的名字，不如起个正常的然后隐藏短名。

## 21.3 bundle：可开关的语法与规则包

```isabelle
definition myop :: "nat \<Rightarrow> nat \<Rightarrow> nat" where
  "myop a b = a + b + 1"

bundle myop_syntax
begin
notation myop  (infixl "\<oplus>" 65)
declare myop_def [simp]
end

context includes myop_syntax
begin
lemma myop_sample: "1 \<oplus> 2 = 4"
  by simp
end
```

```text
consts
  myop :: "nat \<Rightarrow> nat \<Rightarrow> nat"

bundle myop_syntax

theorem myop_sample: 1 \<oplus> 2 = 4
```

bundle 把一批 `declare` / `notation` 打包，**只在 `context includes B` 里生效**。典型用途："这段证明既要符号、又要特化 simp 规则，但别污染全局"。

出了 `context`，`\<oplus>` 消失了，`myop` 也不再自动展开——**同一份定义在不同地方可以有不同"便利度"**。

注意 `1 \<oplus> 2 = 4` 是真的：`myop a b = a + b + 1`，所以 `1 ⊕ 2 = 4`。

## 21.4 named_theorems：自己开一个规则集合

```isabelle
named_theorems my_rules

lemma myop_comm [my_rules]: "myop a b = myop b a"
  by (simp add: myop_def add.commute)

lemma myop_comm_use: "myop x y = myop y x"
  by (simp add: my_rules)
```

```text
theorem myop_comm: myop ?a ?b = myop ?b ?a

theorem myop_comm_use: myop ?x ?y = myop ?y ?x
```

`named_theorems` 声明一个**动态规则集**：用属性 `[my_rules]` 往里塞定理，用 `simp add: my_rules` 一次性取出。

它比手抄 `lemmas` 列表强在：别人（以及下游理论）可以往里追加，不必改你的引理。这是写"可扩展框架"时的标准手段——比如一个自定义的 tactic 框架会开一个 `named_theorems` 让用户注册规则。

## 21.5 属性的加与减

```isabelle
lemmas myop_pair = myop_def myop_comm

declare myop_def [simp]
lemma "myop 1 2 = 4" by simp
declare myop_def [simp del]
```

```text
theorem myop_pair:
            myop ?a ?b = ?a + ?b + 1
            myop ?a ?b = myop ?b ?a

theorem myop 1 2 = 4
```

属性用 `declare` 增删：

| 属性 | 含义 |
|---|---|
| `[simp]` | 加入化简集 |
| `[simp del]` | 从化简集移除 |
| `[intro]` | 安全引入规则（`auto`/`blast` 可用） |
| `[dest]` | 安全消去规则 |
| `[iff]` | 同时当 `simp` 规则和 `intro`/`dest` |

`lemmas myop_pair = myop_def myop_comm` 把两条定理一次性命名——注意打印格式：多条定理共用一个名字时，Isabelle 会**缩进对齐地列出来**。

**全局 `declare foo [simp]` 会影响整条理论后续的所有证明。** 能写成局部 `simp add: foo` 就别写全局。这是可维护性的关键：全局属性是隐式依赖，读代码的人看不出来。

## 21.6 让理论输出可验证的结果

本教程的每个示例都用

```isabelle
ML \<open>writeln "==== 21 开始 ===="\<close>
```

打了起止标记，验证脚本抽标记之间的输出做逐字节比对。

这是件小事，但值得写进规范：**命令自身的输出（批注、`value`、`print_locale`）会随版本变化，只有"圈出来的区间"才是稳定可比的**。

配套的几条纪律（第 1 章讲过，这里从工程角度重申）：

1. 正常输出走 stdout，诊断走 stderr；
2. 标记要唯一，且能圈出全部实质输出；
3. 会漂移的东西（`quickcheck` 的随机种子、耗时数字）必须留在区间外。

---

## 本章坑位清单（实测）

1. **`ROOT` 里的清单当依赖用**：依赖由 `imports` 决定，清单只控制加载顺序。少了 `imports` 照样报错。
2. **`hide_const` 之后忘写全名**：短名立刻不可用，包括 `_def` 派生事实。
3. **`hide_const` 少了 `(open)`**：只隐藏当前层的名字，开放出来的别名还在。要彻底收就用 `(open)`。
4. **bundle 里的 `notation` 写到全局**：会永久污染语法。语法一律放 bundle。
5. **`context includes B` 写成 `context B`**：后者是进 locale，语法完全不同。
6. **全局 `declare [simp]` 泛滥**：隐式依赖，读代码看不出来。优先局部 `simp add:`。
7. **`named_theorems` 忘了 `simp add:` 取用**：声明了规则集但不用等于没有。
8. **以为 `lemmas` 能合并不同形状的定理**：可以，但打印出来是多行缩进，引用时下标要注意。
9. **改了底层理论却期待增量构建快**：改一个被所有理论依赖的文件，全量重编是必然的。
10. **把验证标记写在 `text` 里**：`text` 的输出走文档通道，不一定进 stdout。用 `ML \<open>writeln …\<close>`。

---

上一章：[20 · Locale 与类型类](20-locales.md) ｜ 下一章：[22 · 诊断：读报错与查状态](22-diagnosis.md) ｜ 返回：[README](../README.md)
