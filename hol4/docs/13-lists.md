# 13 · 列表

> 对应示例：[`examples/13_lists/13_lists.sml`](../examples/13_lists/13_lists.sml)

`listTheory` 是 HOL4 里用得最多的库。这一章把它最常用的函数和定理列出来，
再用三个证明演示"先化简、再归纳"这条主线。

## 13.1 语法

```text
[1; 2; 3]
[1; 2]
类型：:num list
```

```sml
val _ = out (term_to_string ``[1; 2; 3]``)
val _ = out (term_to_string ``(1 : num) :: (2 :: [])``)
val _ = out ("类型：" ^ (type_of ``[1; 2; 3]`` |> type_to_string))
```

列表有两个构造子：`[]`（nil）和 `::`（cons）。`[1; 2; 3]` 是 `1::2::3::[]`
的语法糖，**打印**时 HOL4 会尽量折叠回分号形式（第二行）。

`;` 是列表分隔符，不是语句分隔符 —— 在 SML 里写 ``[1; 2]`` 和写
`print "a"; print "b"` 用的是同一个字符，靠引号语法区分。

## 13.2 基本函数

```text
⊢ LENGTH [1; 2; 3] = 3
⊢ [1; 2] ⧺ [3] = [1; 2; 3]
⊢ MAP (λx. x + 1) [1; 2; 3] = [2; 3; 4]
⊢ FILTER (λx. x < 3) [1; 2; 3; 4] = [1; 2]
⊢ REVERSE [1; 2; 3] = [3; 2; 1]
⊢ FOLDR $+ 0 [1; 2; 3] = 6
⊢ FOLDL $+ 0 [1; 2; 3] = 6
⊢ MEM 2 [1; 2; 3] ⇔ T
⊢ [10; 20; 30]❲1❳ = 20
⊢ ZIP ([1; 2],[3; 4]) = [(1,3); (2,4)]
⊢ FLAT [[1; 2]; [3]] = [1; 2; 3]
⊢ TAKE 2 [1; 2; 3] = [1; 2]
⊢ DROP 2 [1; 2; 3] = [3]
⊢ NULL [] ⇔ T
```

```sml
fun ev t = thm_to_string (EVAL t)
val _ = out (ev ``LENGTH [1; 2; 3]``)
val _ = out (ev ``[1; 2] ++ [3]``)
val _ = out (ev ``FOLDR ($+ ) 0 [1; 2; 3]``)
```

| 函数 | 作用 |
|---|---|
| `LENGTH` | 长度 |
| `⧺`（源码写 `++`） | 追加（APPEND） |
| `MAP` / `FILTER` | 映射 / 过滤 |
| `REVERSE` | 反转 |
| `FOLDR` / `FOLDL` | 右折叠 / 左折叠 |
| `MEM` | 成员判断（返回 `bool`） |
| `EL n l` | 取第 n 个元素（从 0 起） |
| `ZIP` | 两个列表拉成对偶列表 |
| `FLAT` | 把列表的列表压平一层 |
| `TAKE` / `DROP` | 取前 n 个 / 丢前 n 个 |
| `NULL` | 是否为空 |

两处**打印**细节值得记一下，它们经常让人以为自己写错了：

- 追加打印成 `⧺` 而不是 `++`：源码里必须写 `++`（`⧺` 只是 pretty-printer 的输出）；
- `EL 1 [10; 20; 30]` 打印成 `[10; 20; 30]❲1❳`：下标语法，值 `20`。

`FOLDR` 里那个 `$` 是"把保留的中缀算子当普通标识符用"的前缀，
`$+` 就是加法函数本身（`FOLDR $+ 0` 即求和）。详见 02 章。

## 13.3 常用定理

```text
⊢ ∀l. l ⧺ [] = l
⊢ ∀l1 l2. LENGTH (l1 ⧺ l2) = LENGTH l1 + LENGTH l2
⊢ ∀f l1 l2. MAP f (l1 ⧺ l2) = MAP f l1 ⧺ MAP f l2
⊢ ∀e l1 l2. MEM e (l1 ⧺ l2) ⇔ MEM e l1 ∨ MEM e l2
⊢ ∀P. P [] ∧ (∀t. P t ⇒ ∀h. P (h::t)) ⇒ ∀l. P l
```

```sml
val _ = out (thm_to_string (DB.fetch "list" "APPEND_NIL"))
val _ = out (thm_to_string (DB.fetch "list" "LENGTH_APPEND"))
val _ = out (thm_to_string (DB.fetch "list" "MAP_APPEND"))
val _ = out (thm_to_string (DB.fetch "list" "MEM_APPEND"))
val _ = out (thm_to_string (DB.fetch "list" "list_induction"))
```

前四条是"穿过 `⧺` 的分配律"，化简器里已经装着，所以大多数情况下
`rw []` 就能用上它们，不需要手动列进列表。

最后一条 `list_induction` 是列表的结构归纳原理，`Induct_on \`l\`` 内部就调它。
注意它的形状：`∀t. P t ⇒ ∀h. P (h::t)` —— **尾**在前、**头**在后。
手写归纳时这个顺序偶尔会绊人。

## 13.4 三个证明

```text
⊢ ∀l. LENGTH (MAP (λx. x + 1) l) = LENGTH l
⊢ ∀l. MAP (f ∘ g) l = MAP f (MAP g l)
⊢ ∀l. REVERSE (REVERSE l) = l
```

```sml
val _ = out (p ``!l : num list. LENGTH (MAP (\x. x + 1) l) = LENGTH l``
               (Induct_on `l` >> rw []))
val _ = out (p ``!l : 'a list. MAP ((f : 'b -> 'c) o (g : 'a -> 'b)) l =
                        MAP f (MAP g l)`` (Induct_on `l` >> rw []))
val _ = out (p ``!l : num list. REVERSE (REVERSE l) = l``
               (Induct_on `l` >> rw []))
```

三个证明**一模一样**：`Induct_on \`l\` >> rw []`。这就是列表证明的日常 ——
结构归纳 + 化简器就能吃掉绝大多数目标。

第二个证明里出现了类型变量 `'a` / `'b` / `'c` 和函数复合 `o`
（打印成 `∘`）。HOL4 的证明可以完全多态，这也是它比"针对具体类型写一遍"省事的地方。

第三个 `REVERSE (REVERSE l) = l` 值得单独说：它**不是**平凡的一步归纳。
`rw` 之所以能过，是因为化简器里装着 13.5 那条引理 —— 见下一节。

## 13.5 引理先行

```text
⊢ ∀l1 l2. REVERSE (l1 ⧺ l2) = REVERSE l2 ⧺ REVERSE l1
```

```sml
val _ = out (p ``!l1 l2 : num list. REVERSE (l1 ++ l2) = REVERSE l2 ++ REVERSE l1``
               (Induct_on `l1` >> rw []))
```

直接对 `REVERSE (REVERSE l) = l` 做归纳，归纳假设是
`REVERSE (REVERSE t) = t`，而目标会变成 `REVERSE (REVERSE t ⧺ [h]) = h::t`
—— 归纳假设**套不上**，因为 `REVERSE` 作用在 `⧺` 上而不是 `::` 上。

标准解法就是**先证一条更强的、关于 `⧺` 的引理**。有了
`REVERSE (l1 ⧺ l2) = REVERSE l2 ⧺ REVERSE l1`（它自己在 `l1` 上归纳很好证），
`h::t` 可以看成 `[h] ⧺ t`，原命题一步就出来了。

`listTheory` 已经装了这条引理（所以它叫"常用定理"），
`rw []` 能直接用。**但你自己定义递归函数时，这条引理得自己证。**

> **模式**：当归纳假设"长得和目标不一样"时，别硬推 ——
> 先想办法把目标改写成能用上归纳假设的形状，通常就是补一条关于
> `⧺`（或你自己的结合操作）的引理。

## 13.6 归纳假设的方向

```text
⊢ ∀l. LENGTH (FILTER P l) ≤ LENGTH l
FOLD 的左右相等要先证结合律引理 —— 这是 13.5 那条路的升级版
```

```sml
val _ = out (p ``!l : num list. LENGTH (FILTER P l) <= LENGTH l``
               (Induct_on `l` >> rw []))
```

这一节说的是"什么时候 `Induct >> rw` 会不够用"。

`LENGTH (FILTER P l) ≤ LENGTH l` 能过，是因为归纳假设
`LENGTH (FILTER P t) ≤ LENGTH t` 和目标 `LENGTH (FILTER P (h::t)) ≤ LENGTH (h::t)`
在化简之后**完全对齐**，剩下的就是算术。

反过来，像 `FOLDR f e l = FOLDL f e l` 这种命题，
化简之后归纳假设是"对 `t` 成立"，目标是"对 `h::t` 成立"，
而 `FOLDL` 的累加器让两侧形状不一致 —— 必须先证一条
`f` 的结合律 + `e` 是左右单位元的引理，再用 13.5 那条路走。

**判据**：化简完之后，看归纳假设能不能"直接代入"目标。
能就 `rw []`，不能就补引理。

## 13.7 坑位清单

1. **追加的源码写法是 `++`，打印出来才是 `⧺`** → 别照着打印结果写代码。
2. **`EL n l` 打印成 `l❲n❳`** → 从 0 起算，越界行为由定义给出（不是异常）。
3. **`$+` 的 `$` 前缀不能省** → 保留的中缀算子当值用时都要加 `$`。
4. **`;` 是列表分隔符** → 别和 SML 的语句分隔符搞混（在引号里才是列表）。
5. **`list_induction` 的量词顺序是"尾在前"** → `∀t. P t ⇒ ∀h. P (h::t)`。
6. **`REVERSE (REVERSE l) = l` 靠的是 `⧺` 上的引理** → 自己定义递归函数时要补这条。
7. **归纳假设套不上时要补引理，不是硬推** → 见 13.5。
8. **`FOLDL = FOLDR` 需要结合律 + 单位元** → 光有归纳不够。
9. **`MEM` 返回 `bool`，定理形状是 `⇔`** → 不是 `=`；`MEM_APPEND` 打印成 `⇔`。
10. **`rw []` 已经装着 `⧺` 的分配律** → 手动把 `LENGTH_APPEND` 列进去通常是多余的。

---

上一章：[12 · 算术](12-arith.md) ·
下一章：[14 · 量词与代换](14-quantifiers.md)
