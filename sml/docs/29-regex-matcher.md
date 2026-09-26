# 29 · 续延风格的正则匹配器

> 对应示例：`examples/27-regex.sml`
> 参考书：Harper《Programming in Standard ML》第 1 章（A Regular Expression Package——全书开篇示例）、第 27 章（Proof-Directed Debugging）、第 30.3 节（Regular Expression Matching, Revisited）。

这一章是 CPS 的第二现场，也是 Harper 全书的招牌示例：一个**把「剩下的输入」当接力棒传递**的正则匹配器。它比第 28 章的 n 皇后更纯粹——整个匹配器里没有一处显式的栈或状态机，回溯完全发生在续延的组合里。

## 29.1 正则表达式是 datatype

```sml
datatype regexp =
    Zero                              (* 空语言：不匹配任何串 *)
  | One                               (* 空串 *)
  | CharC of char                     (* 单字符 *)
  | Times of regexp * regexp          (* 连接 *)
  | Plus of regexp * regexp           (* 并 *)
  | Star of regexp                    (* 克林星 *)
```

六个构造子对应正则语言的六种闭包运算。语言 `L(re)` 的归纳定义：`L(Zero) = ∅`，`L(One) = {ε}`，`L(CharC c) = {c}`，`L(Times) / L(Plus)` 是连接与并，而

```
L(Star re) = L(re)*    满足不动点方程   L* = 1 + L · L*
```

这个方程就是 29.4 节那场调试的主角。

## 29.2 匹配器的形状：续延接收「剩下的输入」

Harper 第 27 章给 `match` 定的规格（转述）：

> 对任意正则式 re、字符表 cs、**全**续延 k：若 cs = cs′ @ cs″ 且 cs′ ∈ L(re) 且 `k cs″` 为 true，则 `match (re, cs, k)` 为 true；否则为 false。

两个要点：

- 匹配的是 cs 的**某个前缀**，剩下的 cs″ 交给 k——`match` 不是「整串判定」，是「前缀搜索的积木」；
- k 必须是**全函数**（对任何输入都终止）。Harper 特意指出：如果允许 k 不终止，「k 永不终止时 match 也要答 false」这种规格没有任何程序能实现。

## 29.3 匹配器本体

```sml
fun match (re : regexp, cs : char list, k : char list -> bool) : bool =
    (steps := !steps + 1;
     case (re, cs) of
         (Zero, _) => false
       | (One, _) => k cs
       | (CharC c, d :: rest) => c = d andalso k rest
       | (CharC _, []) => false
       | (Times (r1, r2), _) =>
             match (r1, cs, fn rest => match (r2, rest, k))
       | (Plus (r1, r2), _) =>
             match (r1, cs, k) orelse match (r2, cs, k)
       | (Star r, _) =>
             k cs
             orelse
             match (r, cs, fn rest =>
                        if length rest < length cs
                        then match (Star r, rest, k)   (* 每轮至少吃一格 *)
                        else false))
```

逐行看续延怎么接力：

- **`Zero`**：空语言，直接 false——k 不被调用；
- **`One`**：匹配空串，什么都不吃，`k cs` 原样交棒；
- **`CharC`**：吃一个字符（`andalso` 短路：不匹配时 k 不被调用）；
- **`Times (r1, r2)`**：**续延的组合**——r1 匹配到的「剩余」不是返回给调用者，而是**喂给 r2 的匹配**，r2 的剩余才交给原来的 k。这一行是整个匹配器的灵魂；
- **`Plus`**：`orelse` 就是回溯——左边带着 k 全试一遍，不行换右边；
- **`Star r`**：先 `k cs`（这一轮到此为止），否则再吃一轮 r——但见下节。

整串判定只是把「吃光」写成续延：

```sml
fun accepts (src, text) =
    match (parse src, explode text, fn [] => true | _ => false)
```

换一个 k 就换一种语义——比如 `fn _ => true` 是前缀匹配，配合枚举起点就是子串搜索。**语义住在续延里，匹配器一行不改。**

## 29.4 Star 的死循环：由证明指导调试

不动点方程 `L* = 1 + L · L*` 诱使人直接写：

```sml
(* 有坑的写法：L* = 1 + L·L* 的字面直译 *)
| match (Star r, cs, k) =
      k cs orelse match (Times (r, Star r), cs, k)
```

Harper 第 27 章的剧本：拿它去匹配 `Star (Star (CharC #"a"))` 这类**内层能匹配空串**的表达式——**不终止**。反例的机理：内层 `Star` 可以选择匹配空串，于是 `Times (r, Star r)` 消耗零个字符就「成功」，递归 `match (Star r, cs, k)` 拿到与出发时**一模一样的 cs**——原地踏步，永不前进。

证明确认了漏洞出在哪：数学上的 `L* = 1 + L · L*` 是**最小不动点**——迭代展开必须「每一轮 L 至少贡献一个非空串」，展开才收拢到 L*。字面直译丢掉了这个进展条件。

**修法**（Harper 原话大意：显式检查每次递归调用都匹配了非空前缀）：

```sml
| match (Star r, _) =>
      k cs
      orelse
      match (r, cs, fn rest =>
                 if length rest < length cs
                 then match (Star r, rest, k)
                 else false)
```

成功续延里检查「r 这一轮真的吃掉东西了吗」：`length rest < length cs` 才继续循环，否则此路作废（外层 `k cs` 已经覆盖了「停在这里」的选项，语义无损失）。

这就是 **proof-directed debugging** 的完整闭环：

1. 从代数性质（不动点方程）推实现；
2. 实现不终止 → 反例；
3. 回到证明，找到被丢掉的前提（每轮非空）；
4. 把前提补成代码里的显式检查。

修好后，示例里专门挑了两个「内层可空」的表达式回归：`(1|a)*` 与 `(a*)*` 对 `"aaa"` 都正确返回 true 且终止。

## 29.5 迷你解析器：从字符串到 regexp

```sml
val r = parse "(a|b)*abb"
```

第 21 章（解析）的递归下降在这里轻装上阵：`pAlt`（并）→ `pCat`（连接）→ `pStar`（后缀星）→ `pAtom`（括号 / `0` / `1` / 字面量），优先级从低到高。两个细节：

- **空连接**：`pCat` 在遇到 `|` 或 `)` 时返回 `One`——`()` 与 `a|` 这类「连接项为零个」的情形是空串，不是语法错；
- **字面量集合**：任何小写字母都是字面量，`0`/`1` 是 Zero/One 的语法糖——`String.sub` 逐字符看，全程不碰 `String.index`（MLton 没有，见第 33 章差异表）。

配套的 `reToString` 永远加足括号，于是可以做**往返测试**：`parse (reToString r) = r`。regexp 是只含 char 与 datatype 的相等类型，`=` 直接可用——这是「datatype + 无函数分量 ⇒ eqtype」的免费午餐。

## 29.6 回溯的代价：数步数

`match` 入口处的 `steps` 计数器把「试了两条路」变成数字（示例第 3 节）：

```
(a|ab)c on "abc": result = true, match steps = 8
ac     on "ac": result = true, match steps = 3  (no choice point)
```

`(a|ab)c` 对 `"abc"`：先试 `a`，`c` 吃不动剩下的 `"bc"`；`orelse` 退回试 `ab`，`c` 吃 `"c"`，成功。8 步对 3 步——**选择点是付费的**。这个计数器也解释了为什么理论上的正则匹配是线性的（NFA/DFA 化），而续延匹配器是带回溯的：它换来的是**实现只有二十行**、且「匹配什么」完全由续延定制。工程上要线性，把 NFA 做成第 25 章那样的流即可——那是 Okasaki 式的习题。

## 29.7 前缀匹配与子串搜索

```sml
fun searchFrom (src, i, text) =
    if i > size text then NONE
    else if match (parse src, List.drop (explode text, i), fn _ => true)
    then SOME i
    else searchFrom (src, i + 1, text)
```

k 换成 `fn _ => true`（前缀语义），起点枚举交给外层循环——`searchFrom ("ick", 0, "the quick brown fox")` 得到 offset 4。第 28 章「语义住在续延里」在这里第二次兑现。

## 29.8 本章小结

- CPS 匹配器的全部回溯 = `orelse`（Plus）+ 续延组合（Times）+ 显式失败（Zero/CharC 不匹配）；
- `Star` 的字面直译会死循环，修法是**进展检查**——由「不动点方程的最小性」推出的前提，必须写进代码；
- 续延换成「吃光 / 吃前缀 / 报告消耗」，同一匹配器变出整串判定、前缀匹配、搜索三种工具；
- `steps` 计数器是给回溯定价的标准手法（第 24、25 章的计数器同款）。

坑位速查（详见第 32 章）：

- **Star 直译 `L* = 1 + L·L*` 不终止**——内层可空的表达式原地踏步（坑 44）；
- 解析器别用 `String.index`（MLton 没有）——`pos` ref + `String.sub` 是可移植组合；
- `andalso`/`orelse` 是短路的中止语义，别换成 `fn => bool` 装箱再拆。
