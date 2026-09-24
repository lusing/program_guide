# 22 · 诊断：把目标看清楚，把报错读明白

对应示例：`../examples/T22_diagnosis.thy`

## 22.1 卡住时第一件事：把目标显示全

证明卡住，第一反应往往是"换一个更贵的方法"。这通常是错的——**先看清目标长什么样**，八成问题自己就现形了。

Isabelle 有一组打印选项（`[[ ]]` 双括号语法）：

| 选项 | 作用 |
|---|---|
| `show_types` | 打印每个项的类型 |
| `show_sorts` | 打印类型变量的类约束 |
| `show_brackets` | 打印全部括号，看优先级怎么落的 |
| `long_names` | 打印全限定名而不是短名 |
| `goals_limit` | 打印多少个目标（默认 10） |
| `eta_contract` | 是否把 `\<lambda>x. f x` 折叠成 `f` |

**`show_types` 是最有用的一个**：绝大多数"两个东西看起来一样就是证不出来"，其实是类型不同。

实测对比。关掉时：

```text
theorem diag_demo: length (?xs @ ?ys) = length ?xs + length ?ys
```

打开 `show_types` 之后：

```text
length ((?xs::?'a list) @ (?ys::?'a list)) = length ?xs + length ?ys
```

多出来的 `::?'a list` 标在每个列表上。这条定理本身不麻烦，但**遇到 `Type unification failed` 时，打开 `show_types` 再读一遍目标，通常一眼就能看出哪个类型变量被钉到了错误的类型上**。

## 22.2 find_theorems：按形状找定理

```isabelle
find_theorems "_ @ [] = _"
find_theorems "_ = rev (rev _)"
find_theorems name: "length" "length (_ @ _) = _"
```

实测三条的输出：

```text
find_theorems
  "_ @ [] = _"

found 2 theorem(s):
  List.append.right_neutral: ?a @ [] = ?a
  List.append_Nil2: ?xs @ [] = ?xs
```

```text
find_theorems
  "_ = rev (rev _)"

found nothing
```

```text
find_theorems
  name: "length"
  "length (_ @ _) = _"

found 2 theorem(s):
  List.length_append: length (?xs @ ?ys) = length ?xs + length ?ys
  BNF_Greatest_Fixpoint.length_append_singleton:
    length (?xs @ [?x]) = Suc (length ?xs)
```

三条都值得学：

1. **第一条命中 2 条，而且它们是同一条定理的两个名字**（`right_neutral` 是类型类层面的，`append_Nil2` 是列表特有的）。库里重复定理很常见，不必纠结用哪个。
2. **第二条 `found nothing`** —— 但 `rev (rev xs) = xs` 明明存在（叫 `rev_rev_ident`）！原因是 `find_theorems` 匹配的是**项的形状**，`_ = rev (rev _)` 要求右边是 `rev (rev ?)`，而库里那条是 `rev (rev ?xs) = ?xs`，**方向相反**。所以：**搜不到不代表不存在，换个方向再搜一次**。
3. 第三条演示了**限定词叠加**：`name: "length"` 筛名字子串，后面那个模式筛形状。可以叠加使用。

`_` 匹配任意**项**（不是一个"任意参数个数"的通配）。配合 `(intro)` `(elim)` `(simp)` `(dest)` 可以按属性筛。

## 22.3 穷举：try0 与 solve_direct

| 命令 | 做什么 | 代价 |
|---|---|---|
| `try0` | 用一串标准方法轮着试一遍，告诉你哪个成了 | 快 |
| `try` | 此外还叫 `sledgehammer`（拉起外部 ATP） | 慢得多 |
| `solve_direct` | 检查目标是不是已经有一条现成定理 | 快 |

`solve_direct` 是最便宜的一步：**如果目标就是某条库定理，直接 `by (rule …)`，别自己证**。

这些命令的输出里有时间信息。本教程把它们放在标记区间之外——不是因为不重要，而是因为"跑得快不快"不该进逐字节比对。

## 22.4 反例、溢出与退化目标

三类常见问题各有各的味道：

- **`quickcheck` 找不到反例不代表命题成立**，它只是没找到（随机采样）。真正安全的是 `nitpick`（穷尽有限模型），但它需要独立的外部求解器，本教程不涉及。
- **`Wellsortedness error`**：类型约束推不出来，通常是一串数字字面量没有足够信息定类型（第 3 章的坑）。
- **`Vacuous truth` / `Illegal schematic variable`**：目标里有别的量化变量溜进来了，往往是 `induction` 没写 `arbitrary:`，或者漏了 `\<And>` 前缀。

真要查"目标在脚本某一行长什么样"，用 `print_state`。要看 `simp` 每一步用了哪条规则：

```isabelle
declare [[simp_trace = true]]
declare [[simp_trace_depth_limit = 4]]
```

（`apply_trace` 同理适用于 `rule`。）这些追踪开关的输出极长且含时间信息，本教程把它们放在**比对区间之外**。

## 22.5 常见错误消息速查

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
Inner lexical error / Malformed command syntax
```
源里出现了不认的字符或符号写法。最常见原因是直接写了字面 Unicode 符号（`∀`、`‹›`）而不是 ASCII 转义（第 1 章有实测边界表）。

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
Bad arguments for document antiquotation
```
`@{verbatim xxx}` 的参数忘了加 ASCII 引号，要写 `@{verbatim "xxx"}`。

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
Undefined constant / Bad type name
```
拼错，或者要用 `Complex_Main` 里的东西却只导入了 `Main`（`real` 最典型）。

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
Not a logical constant
```
对一个其实不是常量的东西用了常量 antiquotation——`length` 只是 `size` 的缩写，用 `@{term "length"}` 而不是 `@{const length}`。

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
Type unification failed
```
两个类型对不上，多半是把列表写成元组、或者 `::` 标错了位置。

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
No type arity
```
某个类型不属于某个类型类，比如拿函数类型当 `enum` 用（第 14 章的集合求值）。

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
Failed to apply initial proof method
```
`proof (method)` 的开局方法没接住目标，通常是**归纳对象选错了**（第 18 章的 `hoare_While` 就是这样卡住的）。

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
No subgoals!
```
目标已经被前面的 `apply (auto …)` 解决了，又多写了一步。**`auto` 对全部目标生效**。

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
Failed to parse prop
```
语法层面失败，但位置常常指向 RHS 而不是真凶。真凶在多数例子里是**名字本身**——第 18 章的 `SUM` 事件：词法层把整词 `SUM` 替换成了求和号。

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
At command "<malformed>"
```
上一处文本块的起止标记没配对：多写一个 `\<close>` 会让后面的命令全部失认，而**报错地点远在几十行之后**。

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
Draft FAILED / Unfinished session(s)
```
会话没建成。先看有没有理论漏 `end`，再看第一处报错在哪。

---

## 本章坑位清单（实测）

1. **不看目标就换方法**：先 `declare [[show_types = true]]` 再看一遍，八成问题自己现形。
2. **`find_theorems` 搜不到就以为不存在**：它匹配的是**形状**，方向反了就搜不到。换个写法再试。
3. **`_` 当成"任意参数个数"**：它匹配任意**项**，不跨元数。
4. **不先跑 `solve_direct`**：目标常常就是某条库定理。
5. **`try` 当常规手段**：它会拉起外部 ATP，很慢。先用 `try0`。
6. **把 `quickcheck` 的"没找到反例"当证明**：它只是随机采样没撞上。
7. **把 `simp_trace` 的输出留进比对区间**：含时间信息和步骤数，每次都不同。
8. **把追踪开关忘了关**：之后所有证明都会刷屏。用完 `declare [[simp_trace = false]]`。
9. **遇到 `At command "<malformed>"` 只看报错那行**：真凶在几十行之前的未配对 `\<close>`。
10. **以为 `Failed to parse prop` 的 RHS 有问题**：`SUM` 事件说明真凶常常是 LHS 的名字本身。

---

上一章：[21 · 会话与工程组织](21-sessions.md) ｜ 下一章：[23 · 工程实践与证明风格](23-engineering.md) ｜ 返回：[README](../README.md)
