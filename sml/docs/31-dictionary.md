# 31 · 数据抽象实战：词典 functor 与表示独立性

> 对应示例：`examples/29-dictionary.sml`
> 参考书：Harper《Programming in Standard ML》第 32 章（Data Abstraction：32.1 Dictionaries、32.2 Binary Search Trees、32.3 Balanced Binary Search Trees、32.4 Abstraction vs. Run-Time Checking）、第 33 章（Representation Independence and ADT Correctness）。

第 16 章讲了不透明约束的机制（`:>` 藏表示、`eqtype` 保相等），第 15 章讲了 functor 的机制。这一章把两者合起来干一件完整的工程：**一个词典抽象、两套表示、一套测试证明它们行为不可区分**——Harper 第 33 章称之为**表示独立性**（representation independence）。

## 31.1 键的契约：ORDERED

Harper 32.1 的 DICT 把 `key` 写死成 `string`；要换键就得换签名。更通用的做法是把「键可比较」声明成模块契约，词典做成 **functor**：

```sml
signature ORDERED = sig
    type t
    val compare : t * t -> order
end

structure IntOrd : ORDERED = struct
    type t = int
    fun compare (a, b) = Int.compare (a, b)
end

structure StringOrd : ORDERED = struct
    type t = string
    val compare = String.compare
end
```

`order`（LESS/EQUAL/GREATER 三值）是 Basis 的标准比较结果类型——**接口里传 `order` 而不是 `bool`**，一次比较同时回答「等于吗」和「往哪边走」。

## 31.2 词典的抽象接口

```sml
signature DICTIONARY = sig
    type key
    type 'a dict
    val empty  : 'a dict
    val insert : 'a dict * key * 'a -> 'a dict
    val lookup : 'a dict * key -> 'a option
    val remove : 'a dict * key -> 'a dict
    val size   : 'a dict -> int
    val depth  : 'a dict -> int
    val toList : 'a dict -> (key * 'a) list      (* 按键升序 *)
end
```

设计决策：

- **`lookup` 返回 `'a option` 而不是抛异常**——查无此键是常规而非异常（第 12 章、第 28 章的 option 哲学）；Harper 的 DICT 用 `exception Lookup`，那是「键必须存在」的用法；
- **`toList` 承诺升序**——这让「字典序遍历」成为可观察行为的一部分，表示独立性测试才有牙齿；
- **`depth` 暴露**——它是个「性能观测窗口」，纯粹由结构决定；两套实现的 depth 必然不同，这恰好用来演示**哪些差异是抽象允许看不见的**（行为），哪些看得见（深度）。

## 31.3 实现 A：朴素 BST

```sml
functor MakeBST (O : ORDERED) :> DICTIONARY where type key = O.t = struct
    type key = O.t
    datatype 'a dict = E | T of key * 'a * 'a dict * 'a dict
    ...
end
```

二叉搜索树的不变式（Harper 32.2 的原文大意）：每个节点的键**大于左子树所有节点、小于右子树所有节点**——这是「底层结构上的表示不变式」（representation invariant），不是类型系统能查的，**只能靠实现维护**。

删除是最容易写破不变式的操作：删一个双子节点，用**右子树的最小键接班**（`splitMin`）：

```sml
fun splitMin (T (mk, mv, E, r)) = (mk, mv, r)
  | splitMin (T (k', v', l, r)) =
        let val (mk, mv, rest) = splitMin l
        in (mk, mv, T (k', v', rest, r)) end
  | splitMin E = raise Fail "unreachable"      (* 死分支，为穷尽性 *)
```

注意 `splitMin E` 这个**永不触达的分支**——SML 不给「这个模式不可能」的断言机制，死分支配 `raise Fail` 是穷尽性的标准代价（第 32 章坑 46）。

## 31.4 实现 B：尺寸平衡树

BST 的命门：**顺序插入退化成链表**。修法是给节点存子树尺寸，回填时失衡就旋转（Adams 风格的重量平衡）：

```sml
datatype 'a dict = E | T of int * key * 'a * 'a dict * 'a dict   (* int = 尺寸 *)

fun sz E = 0
  | sz (T (n, _, _, _, _)) = n
fun node (k, v, l, r) = T (sz l + sz r + 1, k, v, l, r)

fun bal (k, v, l, r) =
    if sz l > 3 * sz r + 1 then
        (case l of
             T (_, lk, lv, ll, lr) =>
                 if sz ll > 2 * sz lr
                 then node (lk, lv, ll, node (k, v, lr, r))        (* 单右旋 *)
                 else (case lr of
                           T (_, xk, xv, xl, xr) =>
                               node (xk, xv, node (lk, lv, ll, xl),
                                     node (k, v, xr, r))            (* 双旋 *)
                         | E => node (k, v, l, r))
       | E => node (k, v, l, r))
    else if sz r > 3 * sz l + 1 then (* 镜像 *)
    else node (k, v, l, r)
```

- **失衡判据是尺寸比**（一侧超过另一侧的 3 倍 + 1），不是高度差——旋转决策（单/双）由内侧子树的相对大小定；
- 旋转本身只是**重建三个节点**（`node` 顺手算新尺寸），没有原地指针操作——纯函数式平衡树的标准姿势；
- `E` 的死分支同上，穷尽性。

删除的 `splitMin` 在平衡版里回填走 `bal`，于是删除也保平衡。

## 31.5 表示独立性：同一测试，两套实现

**测试也做成 functor**：

```sml
functor DictTester (D : DICTIONARY where type key = int) = struct
    fun run () : string = ...   (* 一连串 insert/remove/lookup/size/toList，
                                   把全部可观察结果拼成一个字符串 *)
end

structure TestBST = DictTester (MakeBST (IntOrd))
structure TestBal = DictTester (MakeBalanced (IntOrd))
```

实测输出：

```
BST       behavior: size=6 1:x,2:b,3:c,4:?,5:e,6:f,9:g,100:? [1=x,2=b,3=c,5=e,6=f,9=g]
Balanced  behavior: size=6 1:x,2:b,3:c,4:?,5:e,6:f,9:g,100:? [1=x,2=b,3=c,5=e,6=f,9=g]
representation independent = true
```

这就是 Harper 第 33 章的论点（转述）：**表示独立性**说的是——只要两套实现与抽象的关系一致（这里由同一测试 functor 见证），**任何客户程序在两套实现上的可观察行为都相同**。它的理论根基是 Reynolds 的参数性（parametricity）：客户只能通过签名操作词典，无法触及表示，于是表示的更换对客户不可见。

两个工程要点：

- **`where type key = int` 把键钉住**：DictTester 要打印键（`Int.toString k`），而泛型 `DICTIONARY` 的 key 是抽象类型——不钉住就没法打印（第 32 章坑 47）；
- **测试比较的是「行为字符串」**，不是内部结构——`:>` 之下你也拿不到内部结构（这正是 16 章讲的：透明约束 `:` 会泄露表示，不透明 `:>` 才有独立性可言）。

## 31.6 字符串键：换一个实例就复用

```sml
structure WordDict = MakeBalanced (StringOrd)

fun countWords (text : string) : (string * int) list =
    let
        val words = String.tokens Char.isSpace text
        val d = List.foldl (fn (w, d) =>
                               case WordDict.lookup (d, w) of
                                   SOME n => WordDict.insert (d, w, n + 1)
                                 | NONE => WordDict.insert (d, w, 1))
                           WordDict.empty words
    in
        WordDict.toList d
    end
```

`MakeBalanced (StringOrd)` 一行都没改实现——**键类型、比较函数全部来自参数**。词频输出按字典序（`toList` 的承诺）。再用「排序 + 数游程」写一个独立参考实现互证，两套算法给出的计数表完全一致。

## 31.7 平衡的用处：深度对比

```
sequential insert 1..63:
   BST      depth = 63  (degenerates to a chain)
   Balanced depth = 6   (log 63 ~ 6)
   same contents = true
```

顺序插入 63 个键：BST 深度 63（链表），平衡树深度 6（完美二叉树）——**同样的键集、同样的 toList 输出**（`same contents = true`），差别只在 depth 这个观测窗口里。这就是抽象的边界：**行为一致、性能可异**。要是有 65535 个键，BST 的 lookup 就退化成线性扫——第 27 章摊还分析之外，平衡树是「保证对数深度」的另一条路。

## 31.8 Harper 32.4：抽象 vs 运行时检查

Harper 32.4 还有一个对照值得记住：**表示不变式靠类型与模块边界静态维护**（BST 性质、平衡性质），**数据合法性靠运行时检查动态维护**（查无此键返回 NONE、坏输入抛异常）。两者的分界线画在哪，就是抽象设计的全部内容。词典这个例子把「结构不变式」（搜索树/平衡）全部关进 `:>` 后面，只留「业务规则」（键存在与否）给 option——这正是 SML 模块系统的设计意图。

## 31.9 本章小结

| 构件 | 角色 |
|---|---|
| `ORDERED` | 键的契约，`order` 三值比较 |
| `DICTIONARY` | 词典抽象：`option` 查询 + 升序 `toList` + `depth` 观测窗 |
| `MakeBST` | 表示 A：不变式靠实现维护 |
| `MakeBalanced` | 表示 B：尺寸判据 + 单/双旋，删除也平衡 |
| `DictTester` | 表示独立性的见证：行为字符串逐字符相等 |
| `where type key = int` | 让测试能打印键的签名细化 |

坑位速查（详见第 32 章）：

- **签名与实现的参数形状必须一致**（元组 vs 柯里）——`:>` 匹配检查会精确到箭头形状（坑 47）；
- **泛型 functor 里别 `Int.toString`**——抽象 key 没有打印函数，先 `where type` 钉住；
- **穷尽性的死分支**用 `raise Fail "unreachable"` 占位，别留空让编译器拒收。
