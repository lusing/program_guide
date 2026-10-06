# 23 · 实战：等式计算器 ⭐

> 对应示例：`examples/23_calculator/`（Ch23.hs + main.hs + runtests.hs）。
> 本章对应原书第 12 章〈一个简单的等式计算器〉——全书压轴工程：一个**点自由定律的
> 自动证明器**。11 章的等式推理在这里变成机器自动执行；09 章手推的
> `filter p . map f = map f . filter (p . f)` 在本章由机器完整证明。
> （书名为"等式计算器"而非算术计算器——它算的是**等式**。）

## 23.1 目标：让定律自己跑起来

11 章的每条证明都是手推的推导链。本章造一台机器替你推：

```haskell
calculate :: [Law] -> Expr -> Calculation
-- 定律集        起点     计算（起点 + 步骤链）
prove     :: [Law] -> Equation -> Calculation
--                   等式（两边）  两边殊途同归的完整证明
```

定律是"名字 + 等式"；计算是"起点表达式 + 若干步"，每步记（定律名，新表达式）。
机器只有两个自由度：**选哪条定律**、**用在哪个子表达式**——其余全由数据结构决定。
先看机器的实录（12.1 定律集，完整输出见示例 main）：

```
  filter p . map f
= {defn filter}     concat . map (box p) . map f
= {map functor}     concat . map (box p . f)
= {defn box}        concat . map (if p one nil . f)
= {if after dot}    concat . map (if (p . f) (one . f) (nil . f))
= {nil constant}    concat . map (if (p . f) (one . f) nil)
```

与 09 章 9.5 手推的推导链**逐行同构**——但这次没有人扶着笔。

## 23.2 表达式：Expr 的设计

点自由表达式只有两种原子（书 12.2）：

```haskell
newtype Expr = Compose {deCompose :: [Atom]} deriving (Eq)
data Atom = Var String | Con String [Expr] deriving (Eq)
-- f . g . h     = Compose [Var "f", Var "g", Var "h"]
-- filter p      = Compose [Con "filter" [Compose [Var "p"]]]
-- (f * g) . h   = Compose [Con "*" [f, g], Var "h"]
```

复合是**结构的顶层运算**——`f . g . h` 就是一个原子列表，结合律直接"长在"表示里，
不需要括号。命名规约：变量是单字母或字母+一位数字（`f`、`f1`）；常量两个字符起
（`map`、`lhs2tex`）；运算符是纯符号（`*`、`<+>`）。BNF：

```
expr   ::= simple [op simple]
simple ::= term ('.' term)*
term   ::= var | con arg* | '(' expr ')'
```

解析器（内嵌 21 章的组合子）逐行直译 BNF；`id` 解析为 `Compose []`——复合的单位元
在表示层就被消掉。`Show` 实例用 21 章的 `showsPrec` 手艺，三档优先级（顶层不加括 /
复合在常量参数里加括 / 应用串在参数里加括）。显示与解析互逆，runtests 断言往返。

## 23.3 定律：数据、解析与排序

```haskell
data Law = Law String Equation deriving (Show)      -- 名字 + (左端, 右端)
```

定律用文本写（名字到冒号为止），`law` 解析器认领它——定律即数据，**加定律不用改引擎**。
排序是引擎的"性格"（书 12.3 的核心决策）：

```haskell
sortLaws laws = simple ++ others ++ defns
  where (simple, nonsimple) = partition isSimple laws     -- 右端原子更少
        (defns,   others)   = partition isDefn  nonsimple -- 左端是"常量应用到变量"
```

为什么这么排？**简单定律**（`nil . f = nil`、`map f . map g = map (f . g)`——右端原子
更少）一旦适用只会让表达式变小，优先用稳赚；**定义**（`defn filter`、`defn box`）会把
短名字展开成长表达式，**垫底**——用早了中间表达式膨胀。一条硬规矩：**定律只从左到右
单向应用**——双向应用会立刻"过去又回来"地摆动。

## 23.4 匹配与代换：证明的原子操作

一步重写的本质是"模式匹配 + 代换 + 重写"（11 章手推时的动作，逐个机械化）：

**代换**（书 12.7）就是关联列表 `type Subst = [(VarName, Expr)]`：

```haskell
apply sub (Compose as) = Compose (concatMap (applyA sub) as)
applyA sub (Var v) = deCompose (binding sub v)   -- 变量原地展开摊平
applyA sub (Con k es) = [Con k (map (apply sub) es)]
```

`apply` 对相容代换取并（`unify`），不相容则失败——空表表示，与解析器的失败同款哲学。

**匹配**（书 12.6）是最精巧的一环。`match (e1, e2)` 要给出**所有**让 e1 变成 e2 的
代换。难点：定律左端的原子和目标表达式的原子**数目不必相同**——`f . g` 匹配
`a . b . c` 时 f 可以绑 `id / a / a.b / a.b.c` 四种。解法是**对齐**（alignments）：
把目标原子序列切成 `length 左端原子数` 段（`parts`，允许空段），每段对上一个原子：

```haskell
match (e1, e2) = concatMap (combine . map matchA) (alignments (e1, e2))
alignments (Compose as, Compose bs) = [zip as (map Compose bss) | bss <- parts (length as) bs]
matchA (Var v, e)        = [unitSub v e]            -- 变量匹配一切
matchA (Con k1 es1, Compose [Con k2 es2]) | k1 == k2 = combine (map match (zip es1 es2))
matchA _                 = []                        -- 其余：死
```

书里的教诲：**不要过早承诺单个代换**——匹配 `foo (f . g) . bar g` 与
`foo (a . b . c) . bar c` 时，前半有四种切法，只有 `bar g` 对上 `bar c` 才能筛掉三种。
全枚举 + 相容合一，正确性自动到账。

## 23.5 重写：anyOne 与钻洞

`rewrites eqn e` 给出用等式重写 e 的**一切**方式。去哪重写？两个去处：
**整段**（复合序列的一段连续原子）和**洞里**（常量参数的深处）：

```haskell
rewrites eqn (Compose as) = map Compose (rewritesSeg eqn as ++ anyOne (rewritesA eqn) as)

rewritesSeg (e1, e2) as =                       -- 中段整段匹配左端
    [ as1 ++ deCompose (apply sub e2) ++ as3
    | (as1, as2, as3) <- segments as, sub <- match (e1, Compose as2) ]

rewritesA eqn (Con k es) = map (Con k) (anyOne (rewrites eqn) es)   -- 钻进参数
```

`anyOne f xs`（书 Utilities）的语义是"**恰好为一个元素**设置一次选择"——爬进洞改一处、
爬出来时重建外层表达式。不用"先枚举子表达式再回填"的路径——上下文重建的麻烦被
递归结构吞掉了。

## 23.6 calculate：两条规则定引擎

```haskell
calculate laws e = Calc e (manyStep rws e)
  where
    sorted = sortLaws laws
    rws e' = [ (name, e'') | Law name eqn <- sorted       -- ① 定律优先于子表达式
              , e'' <- rewrites eqn e', e'' /= e' ]        -- ② 自反重写不采纳
    manyStep r x = case r x of [] -> []; st:_ -> st : manyStep r (snd st)
```

①定"先试哪条定律、再钻哪个子表达式"（定律表序 + anyOne 的确定性枚举序）；
②防"重写回自己"的死循环。就这两条——没有启发式，没有搜索树。

## 23.7 prove：把两个计算粘成一个证明

**证明 = 两边各自算到底，结论相同则对接**。对接要"倒着接"——第二个计算逆序贴在
第一个后面，像一条完整的推导链从左端走到右端：

```haskell
paste calc1 calc2
  | conc1 == conc2 = Calc e1 (prune ...)         -- 结论相同：对接（还可剪掉重复尾步）
  | otherwise      = Calc e1 (steps1 ++ (gap, conc2) : rsteps2)   -- 不同：打 gap 标记
```

示例 main 的计算 2 实录（节选，完整无 gap）：

```
  filter p . map f
= …（六步化简到）… concat . map (if (p . f) (one . f) nil)
= {map after one}   …（逆序爬上另一边的推导）…
= {defn filter}     map f . filter (p . f)
```

一条链从等式左端**直达**右端——机器自动完成了 09 章的手推定律。runtests 断言
"证明无 gap"与两边结论逐字相同。

## 23.8 实测三连与"定义最后用"

示例跑的三场计算各有考点：

1. **simplify** `filter p . map f`——12.1 招牌化简（23.1 已示）。
2. **prove** `filter p . map f = map f . filter (p . f)`——证明闭环。
3. **simplify** `head . iterate f`——**终止性**的考题：

```
  head . iterate f
= {defn iterate}    head . cons . fork id (iterate . f)
= {head after cons} fst . fork id (iterate . f)
= {fst after fork}  id
```

`defn iterate` 是递归定义（右端又含 `iterate`），看似会无穷展开——但**化简定律排在
定义前**，`head after cons` 与 `fst after fork` 两步把它就地消化，`iterate . f` 从没
被展开过。定律排序不只是效率，是**终止性**的策略。这正解释了 23.3 的三桶次序。

## 23.9 计算器的边界（书 12.1 的诚实清单）

- **单向性**：定律只能左→右。书里的反例：证 `cat`（即 `++`）结合律需要"恒等律与
  双函子律**双向**使用"，本计算器无能为力——只能把要用的方向预先写成定律。
- **无归纳**：一切需要归纳法证明的性质（如 `++` 结合律本身）只能作为定律输入，
  不能由机器发现。
- **无条件定律**：带前提的等式不支持。
- **一条路走到底**：`calculate` 返回一条计算，不是所有计算的树（书里论证过：返回树
  也未必知道从哪棵枝上找目标）。

这不是玩具的缺陷清单，而是**自动证明的普遍边界**——真正的证明助手（Coq/Lean/Isabelle，
见同仓库 mathlogic 教程）用战术语言、归纳原理、条件重写把这些边界一一推开。

## 23.10 模块结构与它在教程里的位置

书里把计算器拆成九个模块（Expressions/Laws/Calculations/Rewrites/Matchings/
Substitutions/Utilities/Parsing/Main），用显式进出口关联——那是**模块系统的教学**。
我们的教学版收进一个 `Ch23.hs`，用分节注释对应九模块（每节标题即模块名），结构
一一可对照。

与 31 章 MiniLang 的分工：MiniLang 是"解析 → **求值**"的解释器（算出值）；本章是
"解析 → **重写**"的证明器（算出等式）。两章共用 21 章的解析器底座——同一套组合子，
两种引擎。

## 23.11 坑位清单

1. **`parts` 的空段语义**（实测翻车现场）：写成总揽子句 `parts _ [] = [[]]` 会让
   n>0 的空列表得到"零段划分"，`zip` 截断成空对列表，`combine [] = [emptySub]`
   **凭空匹配成功**——一切定律"处处可用"，输出全是垃圾。正解是书版三子句：
   `parts 0 [] = [[]]; parts 0 _ = []; parts n as = …`（n>0 交给递归子句）（23.4）。
2. **定律文本的 OCR 式歧义要语义校验**：`map f . one = one . f`（复合）与 `one f`
   （应用）在扫描件里几乎无法分辨——用"两边语义相等"（`[f x]`）裁决，选错则 prove
   打 gap（23.8 前实测踩过）。
3. **`parse = fst . head` 是部分函数**：书版定义会崩——教学版用 `firstParse` 返回
   `Either`（23.2）。
4. **`Law` 的模式带两个参数**：`Law (e1, e2)` 少写名字字段直接编译错（23.3）。
5. **`show` 的分隔符与解析器约定一致**：复合显示用 `" . "`（带空格）才与符号解析
   对得上——显示/解析互逆要靠同一套记号约定（23.2）。

## 23.12 练习（选自原书第 12 章习题）

**练习 23.1（何时重写回自身）**：给出一个定律与表达式，使 `rewrites` 产生与原表达式
相等的结果（提示：变量绑定到"同形"结构，或 id 的进出）。`calculate` 用 `e'' /= e'`
过滤它——不过滤会发生什么？

**练习 23.2（定律排序实验）**：把 `defn filter` 移到定律表最前（排序后仍在 defns 桶，
故无变化）与把 `isSimple` 改为恒假，分别重跑 23.1 的计算——观察步骤数与中间表达式
长度的变化，验证"简单定律优先"的价值。

**练习 23.3（cat 的结合律）**：按 23.9 的清单准备 `cat/nil/cons/(*)/assocr` 的定律集，
试让计算器证明 `cat associative`——卡在哪一步？把缺的那个方向写成定律再试。
（这正是书 12.1"进一步考虑"一节的实验复刻。）

**练习 23.4（给计算器加定律）**：给 12.1 定律集追加
`filter after map: filter p . map f = map f . filter (p . f)`，重新运行 prove——
一步即达。这说明了"定律库"与"搜索"的什么关系？

---

上一章：[22 parsec](22-parsec.md) ｜ 下一章：[24 Template Haskell](24-th.md) ｜ 返回：[README](../README.md)
