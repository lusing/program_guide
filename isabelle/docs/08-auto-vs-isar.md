# 08 · 自动化方法的分工与两种证明风格

对应示例：`../examples/T08_auto_vs_isar.thy`

## 8.1 自动化方法的分工

Isabelle 有一整柜自动化方法。**知道"先叫谁"比死记语法重要**：

| 方法 | 干什么 | 不干什么 |
|---|---|---|
| `simp` | 用化简规则重写 | 不归纳、不拆构造器、不做语义推理 |
| `auto` | 重写 + 拆分连接词 + 一点搜索 | 不含等式推理之外的"语义" |
| `blast` | 一阶命题/量词推理 | **完全不知道你的函数方程** |
| `force` | 重写 + 拆分 + 搜索 | 慢 |
| `metis` | 用给定事实做消解证明 | 生成物人看不懂 |

## 8.2 同一命题，不同方法

三条完全相同的命题，分别交给三个方法（实测三条的打印结果一模一样）：

```text
theorem A1: ?A \<and> ?B \<longrightarrow> ?B
```

```text
theorem A2: ?A \<and> ?B \<longrightarrow> ?B
```

```text
theorem A3: ?A \<and> ?B \<longrightarrow> ?B
```

分别对应 `by simp`、`by blast`、`by auto`。**同一件事可以有多种做法**，初学阶段先记住"能用就行"，再慢慢形成取舍直觉。

再看带量词的两条（实测）：

```text
theorem A4: (\<forall>x. ?P x \<and> ?Q x) \<longrightarrow> (\<forall>x. ?P x)
```

```text
theorem A5: ((\<exists>x. ?P x) \<and> (\<exists>x. ?Q x)) = (\<exists>x y. ?P x \<and> ?Q y)
```

这两条 `blast` 一击即中：它拆连接词、找量词实例很利落。`auto` 更像"`simp` + 拆分连接词 + 一点搜索"，能吃下多数日常目标。

## 8.3 需要等式推理时，simp 才能上场

```isabelle
fun my_rev :: "'a list \<Rightarrow> 'a list" where
  "my_rev [] = []"
| "my_rev (x # xs) = my_rev xs @ [x]"
```

```text
Found termination order: "length <*mlex*> {}"
```

```text
theorem my_rev_app: my_rev (?xs @ ?ys) = my_rev ?ys @ my_rev ?xs
```

```text
theorem my_rev (my_rev [1, 2, 3]) = [1, 2, 3]
```

最后这条来自 `by (simp add: my_rev_app)`——注意它是**具体列表**上的断言，不是全称定理。

这三条如果换成 `blast` 一定失败：**`blast` 不知道 `my_rev` 的方程**，它只看连接词与量词。经验顺序：

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
simp → auto → force → blast → metis
```

## 8.4 apply 风格 vs Isar 风格

同一件事实，两种写法：

```isabelle
lemma apply_style: "my_rev (my_rev xs) = xs"
  apply (induction xs)
   apply simp
  apply (simp add: my_rev_app)
  done

lemma isar_style: "my_rev (my_rev xs) = xs"
proof (induction xs)
  case Nil
  then show ?case by simp
next
  case (Cons a xs)
  then show ?case by (simp add: my_rev_app)
qed
```

实测两条定理：

```text
theorem apply_style: my_rev (my_rev ?xs) = ?xs
```

```text
theorem isar_style: my_rev (my_rev ?xs) = ?xs
```

Isar 版本在 `case` 里会打印目标（实测）：

```text
show my_rev (my_rev []) = []
```

```text
show my_rev (my_rev (a # xs)) = a # xs
```

这是 Isar 的核心优势：**`case` 名与当前目标摆在明面上**。apply 风格里目标必须靠脑补，维护大型理论时会非常痛苦。第 12、13 章系统讲 Isar。

## 8.5 什么时候该收手

自动化不是越猛越好：

- `blast` 在含大量等式的目标上会**指数爆炸**；
- `metis` 的证明"很好，人看不懂"，出错时无法定位。

工程上的取舍：**把关键步骤写成显式引理，最后一行留给自动化**。本教程所有示例都遵循这个模式——中间引理都是人挑的，收尾交给 `auto`/`simp`。

---

## 本章坑位清单（实测）

1. **拿 `blast` 证函数方程**：`blast` 不认识 `f.simps`，直接在含自定义函数的目标上失败。等式推理交给 `simp`/`auto`。
2. **以为 `simp` 和 `auto` 等价**：`auto` 会拆分目标并生成多个子目标，`simp` 只重写；`by simp` 剩子目标就报错，`auto` 可能留下几个让你继续。
3. **`force` 当默认选项**：它比 `auto` 慢很多，只在 `auto` 差一点时当后备。
4. **`metis` 不带事实硬用**：`by metis` 常常失败，要 `by (metis foo bar)` 给它料。
5. **`simp_all` 与 `simp` 混用**：`simp_all` 对所有子目标做化简，`simp` 只对当前第一个；`by (simp; simp)` 与 `by simp_all` 效果不同。
6. **`apply` 序列中间忘了 `apply`**：报 `Bad method` 或 `Malformed`，Isabelle 不会替你补。
7. **`apply` 后忘了 `done`**：文件仍能构建，但会留下 `1 subgoal` 警告，最终示例里不允许。
8. **`auto` 把目标拆成 8 个之后缩进全乱**：用 `\<comment> \<open>…\<close>` 标注每一步，或者直接换 Isar。
9. **以为自动化"聪明"到能替你想引理**：真正需要人做的是**选中间引理**；`auto` 只负责把最后一步填满。
10. **在 `case` 里忘了 `then`**：Isar 风格的 `case` 需要 `then show`，否则归纳前提不在上下文。

---

上一章：[07 · 化简器](07-simp.md) ｜ 下一章：[09 · 逻辑规则](09-logic-rules.md) ｜ 返回：[README](../README.md)
