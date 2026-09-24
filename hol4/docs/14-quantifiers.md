# 14 · 量词与一阶自动化

> 对应示例：[`examples/14_quantifiers/14_quantifiers.sml`](../examples/14_quantifiers/14_quantifiers.sml)

`simp` 管**重写**，`metis` / `PROVE_TAC` 管**一阶推理**。
这一章划清二者的分工，并把"自动化到不了的地方"是什么样子演示出来 ——
知道边界在哪，比多背几个战术有用。

## 14.1 纯命题

```text
⊢ a ∧ b ⇒ b
⊢ a ∨ ¬a
排中律也可以由 rw 证明：⊢ a ∨ ¬a
⊢ (a ⇒ b) ⇒ ¬b ⇒ ¬a
```

```sml
val _ = out (p ``(a : bool) /\ b ==> b`` (PROVE_TAC []))
val _ = out (thm_to_string (tautLib.TAUT_PROVE ``(a : bool) \/ ~a``))
val _ = out (p ``((a : bool) ==> b) ==> ~b ==> ~a`` (PROVE_TAC []))
```

三个入口都能处理纯命题（不含量词、不含未解释函数）：

| 入口 | 类型 | 说明 |
|---|---|---|
| `PROVE_TAC thms` | `tactic` | 一阶（meson），能处理全称量词 |
| `tautLib.TAUT_PROVE` | `term -> thm` | 只做命题重言式判定，**不要**战术 |
| `rw []` | `tactic` | 化简器，遇到 `a ∨ ¬a` 会分情况 |

第三行是个常被误传的点：**排中律不用 `metis` 也能证**，`rw []` 会分 `a` 的情况。
不过 `rw` 只在能"拆构造子"时有效，真碰到复杂的命题组合还是 `PROVE_TAC` 稳。

## 14.2 metis_tac

```text
⊢ (∀x. P x ⇒ Q x) ⇒ (∀x. P x) ⇒ ∀x. Q x
⊢ (∀x y z. R x y ∧ R y z ⇒ R x z) ⇒ R a b ⇒ R b c ⇒ R a c
⊢ (∃x. P x) ⇒ ∃x. P x ∨ Q x
```

```sml
val _ = out (p ``(!x : num. P x ==> Q x) ==> (!x. P x) ==> !x. Q x``
               (metis_tac []))
val _ = out (p ``(!x y z : num. R x y /\ R y z ==> R x z) ==>
                R a b ==> R b c ==> R a c`` (metis_tac []))
```

`metis_tac` 是 HOL4 的主力一阶证明器（meson 的 Metis 实现）。
`metis_tac []` 里的列表是"额外喂给它的定理"，这里三条都**不需要** ——
它们只用前提就能推出来。

第二条尤其能说明它的本事：从"R 传递"这条前提，自动实例化出
`R a b`、`R b c` 两步并合成 `R a c`。这种"找中间项"的活，
手写就是 `MP` + `SPEC`，交给 `metis` 一句话。

## 14.3 存在量词

```text
⊢ ∃n. n > 0
⊢ ∀m. ∃n. n > m
忘了 witness  : <tactic failed>
```

```sml
val _ = out (p ``?n : num. n > 0`` (qexists_tac `1` >> rw []))
val _ = out (p ``!m : num. ?n. n > m`` (strip_tac >> qexists_tac `m + 1` >> rw []))
val _ = show "忘了 witness " (metis_tac []) ``?n : num. n > 0``
```

存在量词的证明方式是**给出 witness（见证）**：

```sml
qexists_tac `1`          (* 目标是 ?n. P n 时，声称 n = 1 *)
```

第二条是全教程里最典型的形状：`!m. ?n. n > m`
先用 `strip_tac` 把 `m` 变成任意常量，再给 `witness` `m + 1`，剩下的 `rw` 收掉。

> **关键认识**：`metis_tac` 对 `?n. n > 0` **束手无策**（第三行失败）。
> 存在量词需要**构造**出一个具体的项，这不是一阶推理能做的事。
> 只要目标里有 `∃`，先想 witness。

## 14.4 分工

```text
只 simp    : <closed>
只 metis   : <tactic failed>
simp>>met  : <closed>
```

```sml
Definition step_def:
  step x = x + 1
End
val _ = show "只 simp   " (simp [step_def]) ``(step (x : num) = x + 2) ==> F``
val _ = show "只 metis  " (metis_tac []) ``(step (x : num) = x + 2) ==> F``
```

目标 `(step x = x + 2) ==> F`（也就是"证明 `step x ≠ x + 2`"）：

- **只 `simp [step_def]`** → `<closed>`：它把 `step` 展开成 `x + 1`，
  然后用算术化简判出 `x + 1 ≠ x + 2`，整条蕴含变成 `T`。
- **只 `metis_tac []`** → 失败：`metis` **不会展开定义**，它眼里
  `step x` 就是一个不可解释的项，推不出矛盾。

一句话概括分工：

| 工具 | 会做的事 | 不会做的事 |
|---|---|---|
| `simp` / `rw` | 展开定义、分构造子情况、算术化简 | 多步一阶推理、找中间项 |
| `metis_tac` | 一阶推理、自动实例化量词、找矛盾 | 展开定义、做归纳、造 witness |

所以真实脚本的标准形状是 `simp [...] >> metis_tac [...]`：
**先把定义展开干净，再让一阶推理器接手。**

## 14.5 边界

```text
metis 直上 : <tactic failed>
换成归纳  ：⊢ ∀l. LENGTH (REVERSE l) = LENGTH l
线性算术 rw 过  : <closed>
非线性 rw 不灵 : n² ≥ n
非线性项（乘法）一旦出现在归纳假设里，决策过程也接不住：
  ∀n. n * n ≥ n 需要归纳 + 单调性引理，不是一条 rw 能收掉的事。
```

```sml
val _ = show "metis 直上" (metis_tac []) ``!l : num list. LENGTH (REVERSE l) = LENGTH l``
val _ = out ("换成归纳  ：" ^ p ``!l : num list. LENGTH (REVERSE l) = LENGTH l``
               (Induct_on `l` >> rw []))
val _ = show "非线性 rw 不灵" (rw []) ``!n : num. n * n >= n``
```

两条边界，都很硬：

1. **递归定义上的全称命题需要归纳。** `LENGTH (REVERSE l) = LENGTH l`
   对任意 `l` 成立，靠的是"对所有有限列表的结构归纳"，
   这不是一阶逻辑能推出的（`metis` 直上必然失败）。
   换成 `Induct_on \`l\` >> rw []` 一步就出来。

2. **算术里的非线性项接不住。** `n + n ≥ n` 是线性，`rw` 过；
   `n * n ≥ n` 打印出来是 `n² ≥ n`，**过不了** ——
   目标原样留着（输出里那一行就是"没证出来"）。
   它需要归纳加单调性引理（`LESS_MONO_MULT` 之类）。

> 看到 `rw` 打印出目标本身（而不是 `<closed>`）时，就说明它没证出来。
> 这类"静默留下目标"的行为是调试时最该盯的信号。

## 14.6 代价

```text
把已知定理喂给 metis：⊢ ∀a b c. a ≤ b ⇒ b ≤ c ⇒ a ≤ c
什么都不喂     : <tactic failed>
rw 也能收（它内部装着传递性）：⊢ ∀a b c. a ≤ b ⇒ b ≤ c ⇒ a ≤ c
```

```sml
val _ = out ("把已知定理喂给 metis：" ^
             p ``!a b c : num. a <= b ==> b <= c ==> a <= c``
               (metis_tac [LESS_EQ_TRANS]))
val _ = show "什么都不喂    " (metis_tac [])
             ``!a b c : num. a <= b ==> b <= c ==> a <= c``
```

三行放在一起，讲清了"喂多少"这件事：

- 喂一条 `LESS_EQ_TRANS`（`≤` 的传递性）—— `metis` 一步出结果；
- **什么都不喂就失败**：`a ≤ b`、`b ≤ c` 推出 `a ≤ c` 需要传递性这一条公理，
  它不在前提里，`metis` 也不会自己发明；
- `rw` 能收，是因为**化简器里已经装着 `≤` 的传递性**作为重写规则。

代价的另一面是**时间**。`metis` 的搜索空间随"喂进去的定理数"和"项的大小"
增长很快，把一个几百条定理的理论整个塞进去，它很可能搜到天荒地老。
（本教程的验证脚本为此专门加了看门狗 —— 见 23 章。）

实践准则：**`metis_tac` 的列表里只放真正需要的那两三条定理。**
宁可多试几次，也别把整个理论倒进去。

## 14.7 坑位清单

1. **`metis_tac` 不会展开定义** → 定义相关的目标要先用 `simp [def]`（14.4）。
2. **`metis_tac` 造不出 witness** → 目标有 `∃` 就用 `qexists_tac`（14.3）。
3. **`metis_tac` 做不了归纳** → 递归结构上的全称命题上 `Induct`（14.5）。
4. **`rw` 证不出非线性算术** → `n * n ≥ n` 要归纳 + 单调性引理。
5. **`rw` 静默留下目标** → 打印出目标本身就代表"没证出来"，不是报错。
6. **`tautLib.TAUT_PROVE` 接的是项不是战术** → 它返回 `thm`，别往 `prove` 的第二个参数放。
7. **喂给 `metis` 的定理越多越慢** → 只放需要的那几条。
8. **`PROVE_TAC` 与 `metis_tac` 都不是重言式判定器** → 纯命题用 `TAUT_PROVE` 更直接。
9. **`strip_tac` 一次拆掉 `∀` 和前提** → 写 `!m. ?n. …` 时它是标准起手。
10. **排中律 `rw` 就能证** → 不必非得上 `metis`（`rw` 会分 `a` 的情况）。

---

上一章：[13 · 列表](13-lists.md) ·
下一章：[15 · 集合](15-sets.md)
