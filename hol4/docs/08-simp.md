# 08 · 化简器

> 对应示例：[`examples/08_simp/08_simp.sml`](../examples/08_simp/08_simp.sml)

HOL4 的日常工作里 80% 是"把式子推到可以直接看出来的形状"，干这件事的是
化简器。本章把 simp 家族逐个排开，用**残余目标**（战术做完了还剩下什么）
而不是"成功/失败"来对比它们 —— 后者信息量太少。

### 先做一个残余目标打印机（本章共用）

```sml
(* HOL4 Trindemossen 里 tactic 的类型是
     goal -> Context.t -> goal list * validation
   手工调用时要自己递一个上下文快照进去。 *)
fun try_tac (tac : tactic) (gl : goal) =
  (SOME (#1 (tac gl (Context.snapshot ()))) handle _ => NONE)
fun residual t tac =
  case try_tac tac ([], t) of
    NONE => "<tactic failed>"
  | SOME [] => "<closed>"
  | SOME gls => String.concatWith "  ‖  " (map (fn (asms, g) => …) gls)
```

> `tactic` 在 Trindemossen 里多了第二个参数 `Context.t`。
> 手工调用必须 `tac gl (Context.snapshot ())`，并取结果的 `#1`
> （结果的 `#2` 是 validation，用来把子目标的证明装回原目标）。

## 08.1 五兄弟在同一批目标上的残余

```text
-- 假设替换 : x = 1 ⇒ f x = f 1
   simp[] : <closed>
   rw[]   : <closed>
   fs[]   : <closed>
   gs[]   : <closed>
   gvs[]  : <closed>
-- 假设互推 : f x = 1 ⇒ x = 2 ⇒ f 2 = 1
   simp[] : f x = 1 ⇒ x = 2 ⇒ f 2 = 1
   rw[]   : f 2 = 1 ⊢ f 2 = 1
   fs[]   : f x = 1 ⇒ x = 2 ⇒ f 2 = 1
   gs[]   : f x = 1 ⇒ x = 2 ⇒ f 2 = 1
   gvs[]  : f x = 1 ⇒ x = 2 ⇒ f 2 = 1
-- 量词与合取 : ∀a b. a ∧ b ⇒ b ∧ a
   simp[] : <closed>
   rw[]   : <closed>
   fs[]   : <closed>
   gs[]   : <closed>
   gvs[]  : <closed>
-- 算术边界 : x ≤ y ⇒ x < y
   simp[] : x ≤ y ⇒ x < y
   rw[]   : x ≤ y ⊢ x < y
   fs[]   : x ≤ y ⇒ x < y
   gs[]   : x ≤ y ⇒ x < y
   gvs[]  : x ≤ y ⇒ x < y
-- 条件未被分裂 : ∀n. (if n = 0 then 0 else 1) ≤ 1
   simp[] : <closed>
   rw[]   : <closed>
   fs[]   : <closed>
   gs[]   : <closed>
   gvs[]  : <closed>
```

```sml
fun cmp nm g =
  (out ("-- " ^ nm ^ " : " ^ term_to_string g);
   out ("   simp[] : " ^ residual g (simp []));
   … )
```

读这张表的关键：**`rw[]` 是唯一会把 `⇒` 拆开的那个**。
"假设互推"这一行，`rw` 把 `f x = 1` 和 `x = 2` 搬进了假设集合
（`f 2 = 1 ⊢ f 2 = 1`），而其它四个都留在 `⇒` 右边没动 —— 于是它们
"看起来"没进展。

> 五兄弟的差别主要在三件事：**拆不拆 `⇒`**、**用不用假设当重写规则**、
> **用哪个 simpset**。剩下的差别是力度（`gvs` > `gs` > `rw` > `fs` > `simp`）。

## 08.2 假设是一堆重写规则：几次传球才到位

```text
目标          : x = a + 1 ⇒ a = b + 1 ⇒ b = 0 ⇒ x = 2
直接 fs[]     : <closed>
先拆再 fs[]   : <closed>
先拆再 gs[]   : <closed>
先拆再 rw[]   : <closed>
```

```sml
val g2 = ``(x : num) = a + 1 ==> (a = b + 1) ==> (b = 0) ==> x = 2``
val _ = out ("直接 fs[]     : " ^ residual g2 (fs []))
val _ = out ("先拆再 fs[]   : " ^ residual g2 (strip_tac >> fs []))
```

这一条三个假设要"传球"三次才能把 `x` 化到 `2`。`fs`/`gs`/`rw` 都能一次到位。
但在更复杂的目标里，"先 `strip_tac` 拆开、再化简"往往比直接化简稳
—— 拆开之后假设才真的进了 simpset。

## 08.3 方向性

```text
twice_def : ⊢ ∀n. twice n = n + n
默认方向  : twice 3 = 6
数字上反向 : <unchanged>
显式反向   : ⊢ 3 + 3 = twice 3
```

```sml
val _ = out ("默认方向  : " ^ (EVAL ``twice 3`` |> concl |> term_to_string))
val _ = convres "数字上反向" (SIMP_CONV (srw_ss ()) [Once twice_def]) ``6 : num``
val _ = convres "显式反向  " (SIMP_CONV (srw_ss ()) [GSYM twice_def]) ``3 + 3``
```

`twice_def` 的 LHS 有 `twice`，所以默认只往"消掉 twice"的方向走。
想反向用 `GSYM`；`Once` 只限制"用几次"，不改方向 —— 所以对 `6` 无效。

## 08.4 simp only

```text
simp      : ⊢ 0 + n + 0 = n
simp only : <closed>
只 minus  : <closed>
```

```sml
val _ = out ("simp      : " ^ p ``0 + n + 0 = n`` (simp []))
val _ = out ("simp only : " ^ residual ``0 + n + 0 = (n : num)`` (simp [Once ADD_0]))
```

`simp [Once ADD_0]` 只应用一次 `ADD_0`，剩下的算术靠默认 simpset 处理。
想彻底"只许用我给的"，要用 `simp only [...]` 语法（本教程没用到，
因为它一不小心就会把 `T ∧ p = p` 这种基本化简也关掉）。

## 08.5 条件分裂

```text
if : ⊢ ∀b. (if b then 1 else 2) = if b then 1 else 2
自动裂 if : ⊢ ∀n. (if n = 0 then 0 else 1) < 2
合取拆分  : ⊢ ∀a b. a ∧ b ⇒ b
```

```sml
val _ = out ("自动裂 if : " ^ p ``!n : num. (if n = 0 then 0 else 1) < 2`` (rw []))
```

`rw` 会自动把 `if` 的两个分支分别化简，靠的是 `COND_CONG` 里那两条
带前提的等式（20.5 节）。手写 `Cases_on \`b\`` 也能做，但 `rw` 自动。

## 08.6 化简器作为值

```text
⊢ (1 + 2) * 0 = 0
⊢ twice 4 + twice 0 = 8
⊢ (T ∧ p ⇔ p) ⇔ T
```

```sml
val _ = out (thm_to_string (SIMP_CONV (srw_ss ()) [] ``((1 : num) + 2) * 0``))
val _ = out (thm_to_string (SIMP_CONV (srw_ss ()) [twice_def] ``twice 4 + twice 0``))
```

`SIMP_CONV` 返回一条等式定理，可以像普通值一样传递。
它和 `simp` 用的是同一套 simpset，只是一个是转换、一个是战术。

## 08.7 状态里的 simpset

```text
加入前 : twice 1 = 2
用 nth  : <closed>
```

```sml
val _ = out ("加入前 : " ^ residual ``twice 1 = (2 : num)`` (simp []))
val _ = out ("用 nth  : " ^ residual ``twice 1 = (2 : num)`` (simp [twice_def]))
```

`twice_def` 是 ML 绑定（`Definition` 给的），直接放进 `simp [...]` 就行。
`Datatype` 生成的定理没有绑定，要 `simp [DB.fetch " Thy" "name"]`。

## 08.8 化简器的边界

```text
simp : <closed>
rw   : ⊢ x + y = y + x
rw 也救不了抽掉前提的截断减法：
把 y 卡住才行：⊢ x − x = 0
```

有意思：`simp []` 其实**能**证 `x + y = y + x`（默认 simpset 里有算术
归一化），而 `rw []` 也可以。真正的边界在非线性算术和缺前提的截断减法
（`x - y + y = x` 没有 `y ≤ x` 就不成立）。

## 08.9 坑位清单

1. **手工调 tactic 要传 `Context.snapshot ()`** → Trindemossen 里 `tactic` 是 `goal -> Context.t -> …`，只传 `gl` 类型错。
2. **`simp` 不拆 `⇒`** → 想让假设生效，先 `strip_tac` 或直接用 `rw`。
3. **`Once` 不改方向，只限制次数** → 要反向用 `GSYM`。
4. **`SIMP_CONV` 什么都没改时抛 `UNCHANGED`** → 演示代码必须 `handle UNCHANGED`（本示例的 `convres`）。
5. **`Datatype` 的定理没有 ML 绑定** → `simp [DB.fetch "Thy" "name"]`，不能直接写名字。
6. **`rw` 比 `simp` 慢** → 它多做拆 `⇒` 和用假设；能 `simp` 就别 `rw`。
7. **`EVAL` 和 `simp` 是两台机器** → `EVAL` 走计算规则，`simp` 走重写规则；`fib` 那种 `EVAL` 算不动（06.4 节）。
8. **默认 simpset 已经含算术归一化** → `x + y = y + x` 不用给 `ADD_COMM`；给了反而可能让 `rw` 跑不完（24.6 节）。
9. **截断减法缺前提就化不动** → `x - y + y = x` 需要 `y ≤ x`；这不是化简器的锅。
10. **`<<HOL warning: Context.snapshot…>>` 会出现在每个 `Termination` 块** → 一次性、两条入口一致（06 章同样）。

---

上一章：[07 · 归纳证明](07-induction.md) ·
下一章：[09 · 基本战术与目标栈](09-tactics.md)
