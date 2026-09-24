# 11 · 转换

> 对应示例：[`examples/11_conv/11_conv.sml`](../examples/11_conv/11_conv.sml)

HOL4 里"化简""重写""决策过程"看着是三件事，底下其实是同一个接口：

```sml
conv : term -> thm      (* 返回的总是 ⊢ t = t' 形状的等式定理 *)
```

战术之所以能动目标，多半是因为内部调了转换。这一章把转换单独拿出来，
因为它比战术更容易调试（有输入项就能直接看输出定理），也更适合作工具。

## 11.1 基本转换

```text
BETA_CONV       : ⊢ (λx. x + 1) 3 = 3 + 1
REWR_CONV       : ⊢ f11 2 = 2 + 0
REWR_CONV GSYM  : ⊢ 2 + 0 = f11 2
NO_CONV         : <exception>
ALL_CONV        : <unchanged>
```

```sml
fun cr nm (c : conv) t =
  out (nm ^ " : " ^ (thm_to_string (c t)
                     handle UNCHANGED => "<unchanged>"
                          | _ => "<exception>"))

val _ = cr "BETA_CONV      " BETA_CONV ``(\x : num. x + 1) 3``
val _ = cr "REWR_CONV      " (REWR_CONV f11_def) ``f11 (2 : num)``
val _ = cr "REWR_CONV GSYM " (REWR_CONV (GSYM f11_def)) ``(2 : num) + 0``
```

`f11` 这一章的"实验对象"，就是一个只会添零的函数：

```sml
Definition f11_def:
  f11 n = n + 0
End
```

注意最后两行：**`NO_CONV` 抛异常，`ALL_CONV` 抛 `UNCHANGED`**。
这两个"失败"不是一回事，11.8 节会看到它们对证明脚本的差异。

## 11.2 组合子

```text
BETA THENC simp : ⊢ (λx. x + 1) 3 = 4
NO ORELSEC ALL  : <unchanged>
REPEATC         : ⊢ f11 (f11 2) = f11 2 + 0
TRY_CONV        : <unchanged>
CHANGED_CONV    : ⊢ f11 2 = 2 + 0
QCONV           : <exception>
```

```sml
val _ = cr "BETA THENC simp" (BETA_CONV THENC SIMP_CONV (srw_ss ()) [])
           ``(\x : num. x + 1) 3``
val _ = cr "NO ORELSEC ALL " (NO_CONV ORELSEC ALL_CONV) ``1 : num``
val _ = cr "REPEATC        " (REPEATC (REWR_CONV f11_def))
           ``f11 (f11 (2 : num))``
```

| 组合子 | 语义 |
|---|---|
| `c1 THENC c2` | 先 `c1` 再在**结果右边**上跑 `c2`；任一失败就失败 |
| `c1 ORELSEC c2` | `c1` 失败就试 `c2`（`UNCHANGED` 也算失败，会被接住） |
| `REPEATC c` | 反复跑到 `UNCHANGED` 为止（**不会失败**） |
| `TRY_CONV c` | 失败就退化为恒等（`ALL_CONV`） |
| `CHANGED_CONV c` | 反过来：没改动就抛 `UNCHANGED` |
| `QCONV c` | 只在**顶层**试一次，进不了子项 |

`REPEATC` 那一行值得多看一眼：它只跑了**一遍**，得到 `f11 (f11 2) = f11 2 + 0`。
因为 `REPEATC` 是把转换再作用在**上一次结果的右边**（`f11 2 + 0`），
而 `f11 2 + 0` 整体已经不是 `f11 _` 的形状，于是第二次就 `UNCHANGED` 停住了。
想让它一直往里钻，要配 11.3 的深度算子。

`QCONV` 那行抛异常，是因为它把 `REWR_CONV f11_def` 作用在 `(2:num) + 0` 上，
既不匹配又不许往子项里找 —— 于是把底层异常直接放出来了。

## 11.3 深入到哪一层

```text
ONCE_DEPTH      : ⊢ f11 (f11 2) + f11 0 = f11 2 + 0 + (0 + 0)
TOP_DEPTH       : ⊢ f11 (f11 2) + f11 0 = 2 + 0 + 0 + (0 + 0)
DEPTH_CONV      : ⊢ f11 (f11 2) + f11 0 = 2 + 0 + 0 + (0 + 0)
REDEPTH         : ⊢ f11 (f11 2) + f11 0 = 2 + 0 + 0 + (0 + 0)
```

```sml
val t11 = ``f11 (f11 (2 : num)) + f11 0``
val _ = cr "ONCE_DEPTH     " (ONCE_DEPTH_CONV (REWR_CONV f11_def)) t11
val _ = cr "TOP_DEPTH      " (TOP_DEPTH_CONV (REWR_CONV f11_def)) t11
val _ = cr "DEPTH_CONV     " (DEPTH_CONV (REWR_CONV f11_def)) t11
val _ = cr "REDEPTH        " (REDEPTH_CONV (REWR_CONV f11_def)) t11
```

四个算子的区别全在"改写之后**新长出来的**子项还要不要继续处理"：

| 算子 | 遍历方式 | 新出现的子项 |
|---|---|---|
| `ONCE_DEPTH_CONV` | 自上而下，每处最多一次 | 不再处理 |
| `DEPTH_CONV` | 自下而上，直到不动点 | 不回头 |
| `TOP_DEPTH_CONV` | 自上而下，直到不动点 | 会重新处理 |
| `REDEPTH_CONV` | 自下而上，直到不动点 | 会重新处理 |

`ONCE_DEPTH` 那行的输出最有信息量：`f11 (f11 2)` 只把**外层**展开成 `f11 2 + 0`，
里层的 `f11 2` 留着没动；右边 `f11 0` 展开成了 `0 + 0`。
这就是"每处最多一次、新长出来的不回头"。

这个例子里 `TOP_DEPTH / DEPTH / REDEPTH` 结果一样，是因为 `f11 n = n + 0`
展开出来的东西里没有新的 `f11`。换一个"展开后会再生 `f11`"的定义，
三者就会分岔 —— 需要**保证终止**时用 `DEPTH_CONV`（不回头），
需要**彻底展开**时用 `TOP_DEPTH_CONV`（会回头，但也可能不终止）。

## 11.4 指向子项

```text
RAND_CONV       : ⊢ f11 1 + f11 2 = f11 1 + (2 + 0)
RATOR>RAND      : ⊢ f11 1 + f11 2 = 1 + 0 + f11 2
ABS_CONV        : ⊢ (λx. f11 x) = (λx. x + 0)
```

```sml
val t12 = ``f11 1 + f11 (2 : num)``
val _ = cr "RAND_CONV      " (RAND_CONV (REWR_CONV f11_def)) t12
val _ = cr "RATOR>RAND     " (RATOR_CONV (RAND_CONV (REWR_CONV f11_def))) t12
val _ = cr "ABS_CONV       " (ABS_CONV (REWR_CONV f11_def)) ``\x : num. f11 x``
```

应用项 `f a` 里，`f` 叫 **rator**（算子），`a` 叫 **rand**（操作数）。
所以：

- `RAND_CONV c` —— 作用到**参数**上；
- `RATOR_CONV c` —— 作用到**函数**上；
- `ABS_CONV c` —— 钻进 `λx. …` 的**函数体**。

`t12` 是 `f11 1 + f11 2`，也就是 `(λ…  $+) (f11 1) (f11 2)` 的两层应用。
`RAND_CONV` 打的是最外层应用的参数 `f11 2`，输出 `f11 1 + (2 + 0)`；
`RATOR_CONV (RAND_CONV …)` 先钻到外层的 rator（也就是 `$+ (f11 1)`），
再打它的参数 `f11 1`，输出 `1 + 0 + f11 2`。

这一层定位在手写转换时是刚需：想改的地方往往只占目标的一小块。

## 11.5 CONV_TAC

```text
CONV_TAC 直接打目标   : <tactic failed>
CONV_TAC SIMP_CONV    : <closed>
CONV_TAC 之后留 T     : <closed>
```

```sml
val _ = show "CONV_TAC 直接打目标  " (CONV_TAC (REWR_CONV f11_def))
             ``f11 (2 : num) = 2``
val _ = show "CONV_TAC SIMP_CONV   " (CONV_TAC (SIMP_CONV (srw_ss ()) [f11_def]))
             ``f11 (f11 (2 : num)) = 2``
```

`CONV_TAC : conv -> tactic` 把转换抬进目标：它拿目标项 `g` 跑转换得到
`⊢ g = g'`，再把目标换成 `g'`。

第一行**失败**了 —— 这正是新手最常撞的墙。原因是 `CONV_TAC` 把转换作用在
**整个目标项** `f11 2 = 2` 上，而 `f11_def` 的左边是 `f11 n`，匹配不上整个等式，
于是 `REWR_CONV` 抛 `UNCHANGED`，`CONV_TAC` 跟着失败。

`CONV_TAC` **不会**帮你钻到子项去。要么给一个本来就处理整个等式的转换
（第二行的 `SIMP_CONV` 会自己往里走），要么像 11.6 那样自己定位。

## 11.6 手写转换

```text
unfold_f11      : ⊢ f11 3 = 3
直接打整个目标  : f11 3 = 3
定位到左边再打  : <closed>
```

```sml
fun unfold_f11 (tm : term) =
  (TRY_CONV (REWR_CONV f11_def) THENC SIMP_CONV (srw_ss ()) []) tm
val _ = cr "unfold_f11     " unfold_f11 ``f11 (3 : num)``
val _ = show "直接打整个目标 " (CONV_TAC unfold_f11 >> simp []) ``f11 (3 : num) = 3``
val _ = show "定位到左边再打 " (CONV_TAC (RATOR_CONV (RAND_CONV unfold_f11)) >> simp [])
             ``f11 (3 : num) = 3``
```

`unfold_f11` 就是"展开 `f11`，然后把加法算掉"。用 `TRY_CONV` 打头是有意的：
匹配不上不当失败（见 11.8）。

第二行和第一行的对比，把 11.5 的坑说透了：
`unfold_f11` 单独作用在 `f11 3` 上给出 `⊢ f11 3 = 3`，很好；
但用 `CONV_TAC` 打整个目标 `f11 3 = 3` 时，它匹配不上**整个等式**，
`TRY_CONV` 退化成恒等，于是目标原样留着 `f11 3 = 3`。

第三行才是对的：等式 `f11 3 = 3` 是 `($= (f11 3)) 3`，
所以 `RATOR_CONV (RAND_CONV …)` 正好钻到**等式的左边**，一举 `<closed>`。

> **套路**：目标是个等式时，想改左边就用
> `CONV_TAC (RATOR_CONV (RAND_CONV c))`，想改右边就用 `CONV_TAC (RAND_CONV c)`。

## 11.7 化简器与求值器

```text
SIMP_CONV       : ⊢ f11 3 + f11 0 = 3
arith_ss        : ⊢ x < x + 1 ⇔ T
ARITH_CONV      : ⊢ 3 + 1 = 4 ⇔ T
EVAL_CONV       : ⊢ LENGTH [1; 2; 3] = 3
```

```sml
val _ = cr "SIMP_CONV      " (SIMP_CONV (srw_ss ()) [f11_def]) ``f11 3 + f11 0``
val _ = cr "arith_ss       " (SIMP_CONV arith_ss []) ``(x : num) < x + 1``
val _ = cr "ARITH_CONV     " numLib.ARITH_CONV ``(3 : num) + 1 = 4``
val _ = cr "EVAL_CONV      " computeLib.EVAL_CONV ``LENGTH [1; 2; 3]``
```

这四行说明"化简"不是什么特殊机制，它就是一套**预先装好的转换**：

| 名字 | 是什么 |
|---|---|
| `SIMP_CONV ss thms` | 用 simpset `ss` 加定理 `thms` 做重写（08 章的引擎） |
| `SIMP_CONV arith_ss []` | 额外装上算术化简规则的 simpset |
| `numLib.ARITH_CONV` | Presburger 算术决策过程（12 章） |
| `computeLib.EVAL_CONV` | 把可计算的定义当程序跑（21 章的 `EVAL`） |

注意后两个返回的定理右边是 `T`：它们把**命题**判成了真，
所以形状是 `⊢ p ⇔ T` 而不是 `⊢ p`。这一点在用 `CONV_TAC` 时正好合适
（目标 `p` 会被换成 `T`），但拿去当重写定理时要注意方向。

## 11.8 失败即不动

```text
打不中就原地不动 : <exception>
所以 QCONV / TRY_CONV 才是写脚本时的常态：
TRY 兜住        : <unchanged>
```

```sml
val _ = cr "打不中就原地不动" (REWR_CONV f11_def) ``(2 : num) + 0``
val _ = cr "TRY 兜住       " (TRY_CONV (REWR_CONV f11_def)) ``(2 : num) + 0``
```

这一节把全章的"失败"语义收个口。转换有三种"没成功"：

1. **抛 `UNCHANGED`** —— 什么都没改（`ALL_CONV`、匹配不上的 `REWR_CONV`）。
   `ORELSEC` / `TRY_CONV` / `REPEATC` 把它当"失败"接住，语义上是良性的。
2. **抛别的异常** —— 真出错（`NO_CONV`、类型不对）。`TRY_CONV` **接不住**，会往外传。
3. **抛 `CHANGED`/`QCONV` 自建的条件** —— 比如 `QCONV` 不许进子项，进不去就抛。

写脚本时的默认姿势是 **外层包 `TRY_CONV` 或 `QCONV`**：
你通常想表达的是"能改就改，改不动就算了"，而不是"改不动就整个脚本挂掉"。
11.6 的 `unfold_f11` 就是这么写的。

反过来说，如果一个转换**必须**生效才对（"这里肯定能展开"），
就应当用 `CHANGED_CONV` 把它变成硬失败，让脚本在第一时间炸掉而不是悄悄漏过。

## 11.9 坑位清单

1. **`conv : term -> thm`，返回值一定是等式** → 想看结果用 `thm_to_string`，不是 `term_to_string`。
2. **`UNCHANGED` 是一个异常，不是返回值** → 演示或工具里必须 `handle UNCHANGED`。
3. **`REWR_CONV` 只匹配整个项，不钻子项** → 要钻就用 `RAND_CONV`/`RATOR_CONV`/深度算子。
4. **`CONV_TAC` 同样不钻子项** → 目标 `f a = b` 想改 `f a`，要写 `CONV_TAC (RATOR_CONV (RAND_CONV c))`。
5. **`REPEATC` 只沿"结果的右边"重复** → 想往子项里反复展开要配 `TOP_DEPTH_CONV`。
6. **`TRY_CONV` 只兜 `UNCHANGED`** → 其他异常（如 `NO_CONV` 抛的）照样往外传。
7. **`ONCE_DEPTH_CONV` 不回头处理新长出的子项** → 想要不动点用 `TOP_DEPTH`/`REDEPTH`。
8. **`TOP_DEPTH_CONV` 可能不终止** → 改写规则会"再生"时改用 `DEPTH_CONV`。
9. **`QCONV` 只在顶层试一次** → 它进不了子项，匹配不上就抛异常。
10. **`ARITH_CONV` / `EVAL_CONV` 返回 `⊢ p ⇔ T`** → 拿去重写时注意它判的是命题真假。

---

上一章：[10 · 战术算子](10-tacticals.md) ·
下一章：[12 · 算术](12-arith.md)
