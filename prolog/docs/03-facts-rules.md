# 03 · 事实、规则与查询

> 对应示例：[`examples/03_facts_rules/03_facts_rules.pl`](../examples/03_facts_rules/03_facts_rules.pl)

## 3.1 一个程序就是三样东西

```prolog
parent(tom, bob).                          % 事实
father(X, Y) :- parent(X, Y), male(X).     % 规则
?- parent(tom, X).                         % 查询
```

- **事实**：无条件为真的断言。语法上就是「项 + `.`」。
- **规则**：`结论 :- 条件1, 条件2, ...`，`:-` 读作「如果」。条件是若干目标的**合取**。
- **查询**：向环境提问，只在交互式里出现。脚本里查询就是「调用一个目标」。

三个标点符号要一次记住：

| 符号 | 读作 | 含义 |
|---|---|---|
| `,` | 并且 | 合取（and） |
| `;` | 或者 | 析取（or） |
| `:-` | 如果 | 规则的定义，或 `main :- ...` 这样的子句 |

> **程序里没有「赋值语句」这个类别。** 一个子句要么是事实（只有头），要么是规则
> （头 + 体）。所谓「执行」就是不断尝试证明目标。

## 3.2 事实库

本示例的家族关系库：

```prolog
parent(tom, bob).
parent(tom, liz).
parent(bob, ann).
parent(bob, pat).
parent(pat, jim).

male(tom).      male(bob).     male(jim).
female(liz).    female(ann).   female(pat).
```

画成树：

```text
        tom
       /   \
    bob     liz
   /   \
 ann   pat
         \
         jim
```

**一个谓词的多个事实就是「或」。** `parent(tom, bob)` 和 `parent(tom, liz)` 合起来说的是
「tom 的孩子要么是 bob，要么是 liz」。这是 Prolog 里最基本的「多条子句 = 多路分支」。

## 3.3 规则

```prolog
father(X, Y)      :- parent(X, Y), male(X).
mother(X, Y)      :- parent(X, Y), female(X).
grandparent(X, Z) :- parent(X, Y), parent(Y, Z).

ancestor(X, Y)    :- parent(X, Y).
ancestor(X, Y)    :- parent(X, Z), ancestor(Z, Y).

sibling(X, Y)     :- parent(P, X), parent(P, Y), X \== Y.
```

几点值得注意：

- **`grandparent` 中间的 `Y` 是「存在某个」的意思。** 规则里写
  `parent(X, Y), parent(Y, Z)`，Kowalski 读法是「存在一个 Y 使两式皆真」。你不需要声明
  「Y 是局部变量」——**变量的作用域就是单个子句**，跨子句不共享。
- **`ancestor/2` 两条子句是标准套路**：一条基例 + 一条递归。系统自上而下试子句，第一条
  失败就试第二条。基例写在前面很重要，否则简单查询也要先钻到底（09 章细讲顺序的影响）。
- **`X \== Y` 是「不同一」**（05 章），不是「不相等」。没有它，`sibling(X, X)` 也会成立，
  即「自己是自己的兄弟姐妹」。

## 3.4 查询的三种模式

### 只问真假

```text
  parent(tom, bob)    成立
  parent(ann, tom)    不成立（事实库里没有这条）
  father(tom, bob)    成立（由规则推出来的）
  mother(tom, bob)    不成立（tom 是 male）
```

`parent(ann, tom)` 失败是因为事实库里压根没有这条；`mother(tom, bob)` 失败是因为
`male(tom)` 成立而 `female(tom)` 不成立 —— **规则把失败一路传上来了**。Prolog 不会告诉你
「为什么失败」，只会说失败。

### 带变量：让 Prolog 找绑定

```text
  tom 的一个孩子：bob
  bob 的孩子（收集全部解）：[ann,pat]
  tom 的孙辈：[ann,pat]
```

`father(tom, X)` 成功并把 `X` 绑成 `bob` —— 注意这里是**第一个解**。交互式里按 `;` 能继续
要下一个解；脚本里要全部解就用 `findall/3`（13 章细讲）。

### 枚举全部解：`forall/2` 与 `findall/3`

```text
  tom 是 ann 的祖辈
  tom 是 pat 的祖辈
  bob 是 jim 的祖辈
  bob 和 liz 是兄弟姐妹
  ann 和 pat 是兄弟姐妹
  tom 的全部后代：[bob,liz,ann,pat,jim]
```

两个谓词的分工：

- **`forall(Gen, Test)`**：对 `Gen` 的**每一个**解，`Test` 都要成立。它只做判定/副作用，
  **不收集解**，内部绑定也不传出来。
- **`findall(Template, Goal, List)`**：把每个解上的 `Template` 实例化结果收进 `List`。

> **`forall/2` 有个反直觉的坑**：`forall(Gen, Test)` 的语义是「每个解都得让 Test 成立」，
> 所以如果 `Test` 对**某些**解失败了，`forall` 整体就失败。示例里枚举兄弟姐妹时用的是
> `sibling(S1, S2)`，它每个关系会出两次（`sibling(bob,liz)` 和 `sibling(liz,bob)`），
> 于是必须显式处理「不是首序对」的情况：
>
> ```prolog
> forall(sibling(S1, S2),
>        ( S1 @< S2
>        -> format("  ~w 和 ~w 是兄弟姐妹~n", [S1, S2])
>        ;  true                     % 必须显式成功，否则整句失败
>        )),
> ```
>
> `S1 @< S2` 是标准项序比较（04 章），用它保证每对只打一次。

## 3.5 同一个谓词，多种用法

这是 Prolog 最强大的地方，也是新手最容易写出「只在某个方向能用」的谓词的原因：

```text
  谁是 pat 的父母：[bob]
  tom 的孩子有谁：[bob,liz]
  所有 parent 事实：[tom-bob,tom-liz,bob-ann,bob-pat,pat-jim]
  jim 的全部祖先：[pat,tom,bob]
```

同一个 `parent/2`：

- `parent(P, pat)` —— 第二个参数绑定了，**反向查父母**；
- `parent(tom, C)` —— 第一个参数绑定了，**正向查孩子**；
- `parent(X, Y)` —— **两个都自由，枚举全部事实**。

**Prolog 没有「输入参数」和「输出参数」的区别。** 谓词就是一个**关系**，谁绑定了谁没绑定
它自己会处理。你不需要为「反着查」再写一个函数 —— 这一点在 08 章看 `append/3` 时会体现得
更夸张（一个谓词四种用法）。

代价是：**你的谓词在某个方向上可能不终止，或者给出意外结果**，而编译器不会提醒你。
写可复用的谓词时，心里要过一遍「反着用会怎样」（23 章的「按调用模式分开测」就是为这个）。

## 3.6 分号 = 逻辑或

```text
  tom 或 bob 的孩子：[bob,liz,ann,pat]
  （tom 的儿子）或（liz 的孩子）：[bob]
```

```prolog
findall(Y, ( parent(tom, Y) ; parent(bob, Y) ), Anyone).
findall(Y, ( ( parent(tom, Y), male(Y) ) ; parent(liz, Y) ), Mixed).
```

注意第二行：**`;` 的优先级低于 `,`**，所以 `parent(tom,Y), male(Y) ; parent(liz,Y)` 会被
解析成 `(parent(tom,Y), male(Y)) ; parent(liz,Y)` —— 正好是想要的意思。但一旦你的意图
不是这样，就必须加括号。**规则里出现 `;` 时，一律加括号明示**。

`;` 还有一个身份：`(Cond -> Then ; Else)` 里的 `;` 是 if-then-else 的分隔符（10 章）。

## 3.7 坑位清单

1. **句末漏 `.`** → 下一个事实会被当成同一子句的一部分，报 `syntax error: operator expected`。
2. **变量作用域搞错** → 变量只在**单个子句**内有效。两个子句写同名变量是**两个不同的
   变量**，不是共享。
3. **singleton 变量** → 一个变量在子句里只出现一次，两套引擎都会警告，**警告污染 stderr
   就判定失败**。真的只用一次就写 `_X`。
4. **`sibling(X, X)` 也成立** → 忘了加 `X \== Y`（或 `X @< Y`）。
5. **基例写在递归之后** → 简单查询也要先钻到底、甚至死循环（09 章）。
6. **`forall/2` 里 `Test` 对部分解失败** → 整句静默失败，看起来像「什么都没做」。
7. **`;` 优先级踩坑** → 低于 `,`；有疑问就加括号。
8. **指望 Prolog 告诉你失败原因** → 它只会说「不成立」。定位失败要用打点（23 章）。

---

上一章：[01 · Prolog 全景](01-overview.md) · 下一章：[04 · 项](04-terms.md)
