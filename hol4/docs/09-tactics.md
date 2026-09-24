# 09 · 基本战术与目标栈

> 对应示例：[`examples/09_tactics/09_tactics.sml`](../examples/09_tactics/09_tactics.sml)

交互式开发时，证明是**目标栈**上的一个栈帧：`g` 压栈、`e` 变换栈顶、
`b` 回退、`drop` 丢弃、`top_thm` 收成品。本章把这五件套跑一遍，
然后给出在**批处理入口下看见目标**的办法。

> ⚠️ 一个实测事实：批处理入口（`hol run`）下 `p()` **不打印目标项**，
> 只打印 `OK..` / `N subgoals:` / `Goal proved.` 这类状态行。
> 想"看见目标"只能自己把目标项打印出来 —— 本章为此造了一个小工具 `step`。

## 09.1 g / e / p / drop / top_thm

```text
OK..
2 subgoals:
OK..

Goal proved.
⊢ LENGTH (REVERSE []) = LENGTH []

Remaining subgoals:
OK..

Goal proved.
⊢ ∀h. LENGTH (REVERSE (h::l)) = LENGTH (h::l)
证完：⊢ ∀l. LENGTH (REVERSE l) = LENGTH l
```

```sml
val _ = drop_all ()
val _ = g `!l : num list. LENGTH (REVERSE l) = LENGTH l`
val _ = p ()
val _ = e (Induct_on `l`)
val _ = p ()
val _ = e (simp [])
val _ = p ()
val _ = e (simp [])
val _ = out ("证完：" ^ thm_to_string (top_thm ()))
```

对照上面那堆 `OK..` 和 `Goal proved.`：**你只能看出"两个子目标 → 第一个
证完 → 第二个证完"**，看不到任何一个目标项。`e (simp [])` 只作用在**栈顶**，
所以要调两次 —— 这正是脚本式开发在批处理入口下的盲区。

| 命令 | 作用 |
|---|---|
| `g \`term\`` | 把命题压进目标栈 |
| `e tac` | 对**栈顶**目标应用战术 |
| `p ()` | 打印状态（批处理下不含目标项） |
| `b ()` / `r n` | 回退 / 旋转 |
| `restart ()` | 从头来 |
| `drop ()` / `drop_all ()` | 丢弃当前 / 全部证明 |
| `top_thm ()` | 取出成品定理 |

## 09.2 自己打印每一步的残余

```text
初始   : ∀l. LENGTH (REVERSE l) = LENGTH l
Induct : LENGTH (REVERSE []) = LENGTH []  ‖  LENGTH (REVERSE l) = LENGTH l ⊢ ∀h. LENGTH (REVERSE (h::l)) = LENGTH (h::l)
simp#1 : LENGTH (REVERSE l) = LENGTH l ⊢ ∀h. LENGTH (REVERSE (h::l)) = LENGTH (h::l)
simp#2 : <closed>
```

```sml
fun step (tac : tactic) (gl : goal) = #1 (tac gl (Context.snapshot ()))
fun top_step tac gls = if null gls then gls else step tac (hd gls) @ tl gls
val g0 : goal = ([], ``!l : num list. LENGTH (REVERSE l) = LENGTH l``)
val s1 = step (Induct_on `l`) g0
val s2 = top_step (simp []) s1
```

`‖` 分隔并列的子目标，`⊢` 左边是假设。这一下就能看清：
归纳后有两个子目标（基例 + 归纳步），第一个 `simp` 收掉基例，
第二个收掉归纳步。

> 本教程所有"对比战术"的章节都用这个套路：**自己跑 tactic、自己打印
> 残余**，而不是看 `p()` 的状态行。这既绕过了批处理的盲区，也让输出
> 可以逐字节比对。

## 09.3 六个基本战术

```text
strip_tac      : ∀b. a ∧ b ⇒ b ∧ a
rpt strip_tac  : b ∧ a ⊢ b  ‖  b ∧ a ⊢ a
conj_tac       : a  ‖  b
EXISTS_TAC     : 0 = 0
DISJ1_TAC      : a
EQ_TAC         : a ⇒ b  ‖  b ⇒ a
Cases_on       : [] = []  ‖  h::t = h::t
```

```sml
val _ = out ("strip_tac      : " ^ fmtgs (step strip_tac conjg))
val _ = out ("EXISTS_TAC     : " ^ fmtgs (step (qexists_tac `0`) (gl ``?n : num. n = 0``)))
```

| 战术 | 作用 |
|---|---|
| `strip_tac` | 拆掉一层 `∀` / `⇒` / `∧` |
| `rpt strip_tac` | 反复拆到底 |
| `conj_tac` | `a ∧ b` → 两个子目标 |
| `qexists_tac \`t\`` | 给 `∃` 一个见证 |
| `disj1_tac` / `disj2_tac` | 选析取的左 / 右支 |
| `EQ_TAC` | `a = b` → 两个蕴含 |

注意 `strip_tac` 一次只拆**一层**（`∀b. a ∧ b ⇒ b ∧ a` 只掉了 `∀a`），
`rpt strip_tac` 才拆到底。

## 09.4 目标栈上的旋转

```text
OK..
3 subgoals:
OK..

Goal proved.
⊢ 2 = 2

Remaining subgoals:
OK..
一并处理：⊢ 1 = 1 ∧ 2 = 2 ∧ 3 = 3
```

```sml
val _ = g `(1 : num) = 1 /\ (2 = 2) /\ (3 = 3)`
val _ = e (rpt conj_tac)
val _ = r 1        (* r : int -> proof，它直接改当前证明，不是战术 *)
val _ = e (simp [])
val _ = restart ()
val _ = e (simp [])
val _ = out ("一并处理：" ^ thm_to_string (top_thm ()))
```

> **`r` 的类型是 `int -> proof`，不是 `tactic`。** 它直接作用于当前证明，
> 不能写成 `e (r 1)` —— 会报类型错误。这是 `proofManagerLib` 里最常被
> 误用成战术的一个命令。

`restart ()` 之后一句 `e (simp [])` 就把三个合取一起证完了 —— 因为
`srw_ss()` 认识 `=` 的自反性，不需要先拆。

## 09.5 打印开关

```text
默认打印 : f x = 1 ⊢ x = 0 ⇒ f 0 = 1
types=1  : (f :num -> num) (x :num) = (1 :num) ⊢ (x :num) = (0 :num) ⇒ (f :num -> num) (0 :num) = (1 :num)
关回去   : f x = 1 ⊢ x = 0 ⇒ f 0 = 1
```

```sml
val _ = set_trace "types" 1
val _ = out ("types=1  : " ^ fmtgs (step strip_tac sg))
val _ = set_trace "types" 0
```

默认打印会**隐藏类型信息**（`f x = 1`）。两个不同类型的 `x` 看起来一样，
是 HOL4 新手最常遇到的"这怎么可能不相等"。调试时把 `types` 打开一秒看清楚。

## 09.6 坑位清单

1. **批处理入口下 `p()` 不打印目标项** → 只有 `OK..` / `N subgoals:` / `Goal proved.`；要自己打印。
2. **`e` 只作用在栈顶** → 有 N 个子目标就要调 N 次，或者用 `rpt` / `ALLGOALS`。
3. **`r` 不是战术** → 它是 `int -> proof`，不能写 `e (r 1)`。
4. **`strip_tac` 一次只拆一层** → 要拆到底用 `rpt strip_tac`。
5. **默认打印隐藏类型** → 用 `set_trace "types" 1` 看清楚，查完记得关回去（否则污染后续输出）。
6. **`g` 之后忘了 `drop_all`** → 上一个证明还在栈上，`e` 会作用在错误的目标。
7. **`top_thm ()` 在证明没完成时抛异常** → 先确认所有子目标都关了。
8. **`b ()` 和 `restart ()` 的粒度不同** → `b` 退一步，`restart` 回到起点。
9. **`qexists_tac` 的见证要带类型标注** → `qexists_tac \`0\`` 在上下文不清时会推成 `int`。
10. **`Cases_on` 对 `∀l` 要先拆掉全称量词** → 否则它作用在 `∀l. …` 上分不出情况。

---

上一章：[08 · 化简器](08-simp.md) ·
下一章：[10 · 战术算子](10-tacticals.md)
