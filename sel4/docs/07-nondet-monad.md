# 07 · 非确定性状态单子

对应示例：`../examples/S07_nondet_monad.thy`

## 7.1 读 l4v 的第一道门槛：非确定性状态单子

seL4 的内核代码不是普通函数，而是一个**非确定性状态单子**：
给定初始状态，返回**(结果集合, 失败标志)**。
结果是个集合，因为内核里有真正的非确定性（调度器选谁、从哪个队列取）；
失败标志独立于结果集合，因为"失败"和"返回空集"是两件事。

真实定义在 `l4v/lib/Monads/nondet/Nondet_Monad.thy`
（配套 `Nondet_VCG.thy`、`Nondet_No_Fail.thy`、`Nondet_Empty_Fail.thy`）。

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
('s,'a) nondet_monad = 's ⇒ ('a × 's) set × bool
                              │         │      └─ 失败标志
                              │         └─ 非确定性：结果是个集合
                              └─ 新状态
```

本章用一组 `k` 前缀的名字把组合子重新实现了一遍（`kreturn`/`kbind`/`kfail`/`kassert`/
`kassert_opt`/`kget`/`kput`/`kgets`/`kmodify`/`kselect`/`kwhen`），
再挂到 do 记号上。要挂上去，需要 `imports "HOL-Library.Monad_Syntax"` 加一行
`adhoc_overloading bind == kbind`（**是 `==` 不是 `=`**，见坑位 2）。

## 7.2 单子三定律

```text
theorem bind_return_left: kreturn ?x \<bind> ?f = ?f ?x
```

```text
theorem local.bind_assoc: ?m \<bind> ?f \<bind> ?g = ?m \<bind> (\<lambda>x. ?f x \<bind> ?g)
```

定理名里的 `local.` 前缀是 `adhoc_overloading` 留下的痕迹：
绑定符号被重载了，定理名因此带了限定。这是**正常现象**，不是错误。

## 7.3 结合律：这一条最啰嗦，也最值得证

结合律之所以值得单独证，是因为它保证了"把一串 `bind` 怎么加括号都一样"。
内核代码里大量的 `do { x <- m; f x }` 嵌套，靠它才能重排。

## 7.4 失败与"空结果"是两件事

```text
theorem fail_fails: \<not> no_fail kfail
```

```text
theorem select_empty_does_not_fail: no_fail (kselect {})
```

```text
theorem select_empty_has_no_results: \<not> nonempty (kselect {})
```

三条是关键：**失败的程序一定不满足 `no_fail`；但"结果集为空"的程序可以是 `no_fail` 的**。
`kselect {}` 就是一个既不失败、又没有任何结果的计算。

l4v 为此专门有两个文件：`Nondet_No_Fail.thy` 与 `Nondet_Empty_Fail.thy`。
把 `no_fail` 当成"结果非空"，是这一层最常见的误解。

## 7.5 状态操作的三条等式

`kget`/`kput`/`kmodify` 满足一组等式，其中"改两次等于复合"最容易写反方向：

<!-- 节选块：每行逐字节来自 build/first/out/S07_nondet_monad.txt -->
```text
theorem modify_twice: kmodify ?f \<bind> (\<lambda>_. kmodify ?g) = kmodify (?g \<circ> ?f)
```

复合顺序是 `g ∘ f`：先写的 `f` 先作用。

## 7.6 非确定性是怎么进到内核里的

`kselect` 是唯一的非确定性来源——从一个集合里"任选一个"（实测）：

```text
theorem
  bind_select_collects:
    fst ((kselect ?A \<bind> (\<lambda>x. kreturn (x + 1))) ?s) = (\<lambda>x. x + 1) ` ?A \<times> {?s}
```

结果集合就是"每个可能的 x 都算一遍"的像。
真实内核里的非确定性来自调度（`choose_thread`）与"任选一个满足条件的槽"这类操作。

---

## 本章坑位清单（实测）

1. **ROOT 父会话写 `HOL` 就 import 不了 `Monad_Syntax`**：报 `Bad import … need to include sessions "HOL-Library" in ROOT`。父会话要写 `"HOL-Library"`（带引号）。
2. **`adhoc_overloading` 写 `=`**：必须是 `bind == kbind`，写 `=` 报错且位置不指向这一行。
3. **定理名带 `local.` 前缀以为出错**：重载绑定符号后属正常。
4. **把 `no_fail` 当"结果非空"**：两者独立，`kselect {}` 是反例。
5. **把失败标志当返回值的一部分**：它是二元组右边的 `bool`，与结果集合并列。
6. **`modify_twice` 的复合顺序写反**：是 `g ∘ f`。
7. **结果类型是集合导致等式难证**：拆成 `fst` 与 `snd` 两个分量分别证（用 `prod_eqI`）。
8. **裸写 `bind_assoc`**：重载后要写 `local.bind_assoc`。
9. **用 `auto` 直接证单子等式**：通常卡在集合相等上，先用 `ext` 或 `prod_eqI` 拆开。
10. **把 `kassert` 当普通布尔**：`kassert False = kfail`（实测），它是"不成立就失败"。

---

上一章：[06 · 回收与删除](06-revoke-delete.md) ｜ 下一章：[08 · 错误单子与解码](08-error-monad.md) ｜ 返回：[README](../README.md)
