# 30 · 规格与正确性：归纳定律的可执行化

> 对应示例：`examples/28-correctness.sml`
> 参考书：Harper《Programming in Standard ML》第 24 章（Specifications and Correctness）、第 25 章（Induction and Recursion：25.1 Exponentiation、25.2 The GCD Algorithm）、第 26 章（Structural Induction）。

Harper 第 24 章的立场值得整段转述：程序的正确性**从来不是「跑起来像是对的」**，而是「相对于一份**规格**（specification）满足一组义务」。证明是终点，但测试是把规格写错、实现写错**当场**揪出来的手段。本章做三件事：循环不变量、可执行的归纳定律、以及一套确定性的随机测试基建。

## 30.1 循环不变量：快速幂

```sml
(* 不变量：go (b, e, acc) == acc * b^e
   e 偶：b^e = (b*b)^(e/2)，指数减半；
   e 奇：b^e = b^(e-1) * b，挪一个 b 进 acc。 *)
fun powFast (b : int, e : int, acc : int) =
    if e = 0 then acc
    else if e mod 2 = 0 then powFast (mul (b, b), e div 2, acc)
    else powFast (b, e - 1, mul (acc, b))
```

不变量 `acc · b^e` 在每次递归前后保持不变；`e` 严格递减且非负，终止；`e = 0` 时不变量就是答案。这是「由证明构造程序」的最小样本——三个分支各自对应不变式维护的一个 case。

怎么验证？**互证**：拿显然正确但慢的 `powSlow`（直接乘 e 次）当参考实现，两组输入全部一致（示例：base 2/3/7/−2 各覆盖一段指数，`all agree`）。再把代价数出来：`2^28` 慢速乘 28 次，快速**7 次**——不变量不只是正确性论证，也是性能论证（对数级的来源）。

## 30.2 gcd：不变量 + 暴力规格双重验证

```sml
fun gcd (a : int, 0) = a
  | gcd (a, b) = gcd (b, a mod b)
```

Harper 的证明（第 25.2 节）对**乘积 a×b** 做完全归纳：`a mod b` 让乘积严格变小（`(a mod b) × b = a×b − (a÷b)·b² < a×b`），故终止；「公因子集合不变」（d 整除 a、b ⟺ d 整除 b、a mod b）故正确。规格是：

> 若 a, b ≥ 0，则 `gcd (a, b)` 是 a 与 b 的最大公因子（gcd(0,0) 约定为 0）。

这份规格**本身可以当程序跑**——对每个 g，验证两件事：

```sml
fun properGcd (a, b) =
    let
        val g = gcd (a, b)
        fun divides (d, x) = x mod d = 0
        fun noLarger d = d > Int.min (a, b) orelse
                         not (divides (d, a) andalso divides (d, b))
        fun scan d = d > g orelse (noLarger d andalso scan (d + 1))
    in
        divides (g, a) andalso divides (g, b) andalso scan (g + 1)
    end
```

- **g 是公因子**（不变量的可执行版）；
- **没有更大的公因子**（「最大」的暴力枚举版——规格直译）。

示例对 1..60 的全部 1830 对验证通过。这就是「规格即参考实现」的完全体：暴力版慢，但它与被测程序**共享的只有定义**，没有共享任何代码路径。

顺带一提， Harper 25.1 节有一个漂亮的观点：**加强规格常常反而好证**——归纳假设更强，归纳步骤里能用的东西更多；编程上对应「加累积器参数」（第 11 章的尾递归）。「表面上做更多，证明上更容易」——两件事是同一个现象。

## 30.3 结构归纳定律：把证明写成测试

第 26 章的定律清单，每条都是一次结构归纳，每条也都可执行：

| 定律 | 归纳的骨架 |
|---|---|
| `rev (rev xs) = xs` | 对 xs 归纳，辅助引理 `rev (x::ys) = rev ys @ [x]` |
| `rev (xs @ ys) = rev ys @ rev xs` | 对 xs 归纳；`@` 的定义在左边递归，所以rev 必须右递归 |
| `length (xs @ ys) = length xs + length ys` | 对 xs 归纳，两边都按 `x ::` 展开 |
| `map f (map g xs) = map (f o g) xs` | **融合律**：两次遍历合一次 |
| `foldl f b xs = foldr f b (rev xs)` | f 满足结合律、b 是单位元时成立（独异点） |
| `xs @ ys = foldr (op ::) ys xs` | append 就是「把 xs 从右边折进 ys」 |

示例把每条定律跑在手工案例上（`true` × 6），再跑在随机语料上。**定律是证明义务，测试是义务的采样**——采样不能替代证明（第 32 章有一个「测试全绿但定律为假」的反例坑），但没有比「定律挂了立刻知道」更便宜的反馈。

融合律值得单独看一眼，它是编译器优化的理论基础：

```sml
fun fusion (xs : int list) =
    map2 (fn x => x + 1, map2 (fn x => x * 2, xs))
    = map2 (fn x => x * 2 + 1, xs)
```

两次 `map`（两次分配、两次遍历）合并成一次——第 19 章「快排三个实现互证」用的就是这类等价推理。

## 30.4 确定性随机测试：自己写 LCG

Basis **没有随机数**。拿时间当种子还会毁掉三通道比对（第 33 章：时间/路径/地址是输出差异的三大来源）。解法是自己写确定性生成器——Lehmer LCG：

```sml
val lcgM = 2147483647 : IntInf.int
fun lcgNext (s : IntInf.int) : IntInf.int = IntInf.mod (IntInf.* (48271, s), lcgM)

fun randLists (seed : IntInf.int, k : int) : int list list =
    if k = 0 then []
    else
        let
            val s1 = lcgNext seed
            val s2 = lcgNext s1
            val len = IntInf.toInt (IntInf.mod (s1, 13))          (* 长度 0..12 *)
            fun elems (_, 0) = []
              | elems (s, j) =
                    let val s' = lcgNext s
                    in IntInf.toInt (IntInf.mod (s', 1000)) :: elems (s', j - 1)
                    end
            val xs = elems (s2, len)
        in
            xs :: randLists (lcgNext s2, k - 1)
        end
```

两个可移植性决策：

- **乘法用 `IntInf.*` 显式点开**：`48271 * s` 这种重载写法在 IntInf 语境下不是所有实现都解析成功（第 32 章坑 45）；而 Lehmer 乘积 `48271 × (2³¹−2)` ≈ 10¹⁴，**必然超出 MLton 的 32 位 int**——所以中间量必须走 IntInf，出口再 `IntInf.toInt` 收窄；
- **种子固定**：同一份源码在三家跑出同一串「随机」数——`[886,637]`、`[683,161,505,...]` 逐字节一致。

300 个随机列表上：rev 自逆 300/300、融合 300/300、左右折叠求和一致 300/300。

## 30.5 排序的完整规格：有序 + 置换

排序是「规格驱动」的经典案例，规格是**两个谓词的合取**：

```sml
fun isSorted [] = true
  | isSorted [_] = true
  | isSorted (x :: y :: rest) = x <= y andalso isSorted (y :: rest)

fun sameMultiset (xs : int list, ys : int list) = msort xs = msort ys
```

- **有序**：输出按序排列；
- **置换**：输出与输入含同样的元素（多重集合相等）。

只有有序没有置换，返回 `[]` 就「满足」规格；只有置换没有有序，恒等函数就「满足」规格。**两个谓词单独都不够，合取才是排序**——这就是规格要写完整的原因（Harper 24.1 节的主课）。示例在 300 个随机列表上双条件验证全绿。

## 30.6 本章小结

| 手段 | 对应证明概念 | 本章实例 |
|---|---|---|
| 互证（快慢两版对答案） | 相对规格的正确性 | powFast vs powSlow |
| 不变量 + 计数器 | 归纳论证 | acc·b^e、摊还分析（第 27 章） |
| 暴力规格 | 「最大/最优」类定义直译 | properGcd 枚举更大公因子 |
| 定律测试 | 结构归纳 | rev/map/fold 六条定律 |
| 确定性随机 | 全称量词的采样 | LCG 语料 300 例 |
| 双谓词规格 | 合取规格 | sorted AND permutation |

坑位速查（详见第 32 章）：

- **Basis 没有随机数**——时间种子会毁掉逐字节比对；LCG + IntInf 是可移植组合（坑 45）；
- IntInf 的乘法写 `IntInf.*` 显式点开，别赌重载；
- 「最大」类规格的暴力版是 O(n) 扫描——只在小输入上跑，别当实现用。
