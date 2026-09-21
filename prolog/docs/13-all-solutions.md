# 13 · 解集收集：`findall` / `bagof` / `setof`

> 对应示例：[`examples/13_all_solutions/13_all_solutions.pl`](../examples/13_all_solutions/13_all_solutions.pl)

## 13.1 三个谓词，一位之差

Prolog 的一个查询可能有零个、一个、或无穷多个解。把「可能多个解」变成「一个列表」，
有三个内建谓词：

| 谓词 | 无解时 | 分组 | 排序去重 |
|---|---|---|---|
| `findall(Template, Goal, List)` | **成功，`List = []`** | 从不分组 | 不做（保持求解顺序） |
| `bagof(Template, Goal, List)` | **失败** | **按自由变量分组** | 不做 |
| `setof(Template, Goal, List)` | **失败** | 同 `bagof` | **排序 + 去重** |

差别只在语义细节上，但每一条都能让程序行为完全不同。

## 13.2 `findall/3`：最常用，永不失败

```prolog
findall(X, likes(X, wine), L1).        % L1 = [mary, john]
findall(X-Y, likes(X, Y), L2).         % L2 = [mary-food, mary-wine, john-wine, john-mary, john-food]
findall(_, likes(nobody, _), L3).      % L3 = []，且整体成功
```

```text
findall(X, likes(X,wine), L)     L = [mary,john]
findall(X-Y, likes(X,Y), L)      L = [mary-food,mary-wine,john-wine,john-mary,john-food]
findall(_, likes(nobody,_), L)   L = []，且整体成功
john 喜欢 3 样东西
```

三个必须记住的性质：

1. **模板可以是任意项**，不只是一个变量。`X-Y` 是个 `-/2` 复合项，照样收。
2. **无解时成功并给 `[]`** —— 这让它最适合做统计：计数、求和、求极值都不会「因为没数据
   而整个失败」。
3. **求解顺序就是列表顺序** —— 也就是子句在数据库里的顺序（这通常是你要的）。

**计数不用 `count`，`length` 一下就行**（可移植）：

```prolog
findall(_X, likes(john, _), L), length(L, N).    % N = 3
```

**还有一条容易忽略的性质：`Goal` 里的绑定不漏到外面。**

```prolog
findall(Z, member(Z, [1,2,3]), _),
var(Z).        % 成立 —— Z 仍然是空的
```

`findall` 在内部把变量复制了一套（等价于对 `Goal` 做了一次 `copy_term`，12 章）。
这意味着**你不能用 `findall` 「顺便」得到一个绑定** —— 想要就把那个值放进模板。

## 13.3 `bagof/3`：失败语义 + 自动分组

```text
bagof(X, likes(nobody,X), L)  失败 —— 无解时 bagof 失败
likes(X,Y) 里的 X 是自由变量，bagof 会按 X 分组：
  [john-[wine,mary,food],mary-[food,wine]]
加上 X^ 之后只有一组：[food,wine,wine,mary,food]
```

```prolog
findall(X-Group, bagof(Y, likes(X, Y), Group), Groups).
% Groups = [john-[wine,mary,food], mary-[food,wine]]

bagof(Y, X^likes(X, Y), All).      % All = [food,wine,wine,mary,food]
```

**分组规则**：`Goal` 里所有「**既不在模板里、也没被 `^` 声明**」的变量都要分组。
`bagof` 会枚举这个自由变量的每一个取值，每次给出一组。

注意上面第二行 `findall(X-Group, bagof(...), Groups)` 的写法 —— **`bagof` 自己会产生多个解
（每组一个），所以要用 `findall` 把它们收起来**。这是 `bagof` 分组最常见的用法。

> **这条规则是初学者最容易踩的坑**：明明只是想收集，结果出来一堆组，还以为是引擎坏了。
>
> **经验法则**：不需要分组就用 `findall`；非要用 `bagof`/`setof` 又不想分组，就给变量加 `^`
> 把它「藏起来」。

## 13.4 `setof/3` = `bagof` + 排序去重

```prolog
setof(Y, X^likes(X, Y), L1).              % L1 = [food, mary, wine]
findall(Y, likes(_, Y), WithDup).         % [food, wine, wine, mary, food]  —— 有重复
sort(WithDup, Dedup).                     % [food, mary, wine]              —— 与 setof 相同
```

```text
setof(Y, X^likes(X,Y), L)   L = [food,mary,wine]
同样条件用 findall                  L = [food,wine,wine,mary,food]（有重复）
再 sort 一下                        L = [food,mary,wine]（与 setof 相同）
setof 无解时：失败（与 bagof 一致，与 findall 不同）
```

**排的是标准项序**（04 章），**去重也是按标准项序相等**。所以 `setof` 天然给出一份
「排好序的、无重复的」答案 —— 这正是「集合」该有的样子。

可以粗略记成 **`setof ≈ sort(findall(...))`**，但两个例外：

- **「无解」时语义不同**：`findall` 给 `[]`，`setof` 失败。
- **`setof` 会分组**（继承自 `bagof`），`findall` 不会。

> **`findall` 不认 `^/2`。** `X^Goal` 对那些谓词是「把 `X` 标记为不参与分组」的特殊语法，
> 但 `findall` 不知道这回事 —— **它会把 `^` 当成一个叫 `^` 的谓词去调用，直接报错**
> （GNU 上是 `existence_error(procedure, (^)/2)`）。
>
> 所以在 `findall` 里想表达「某个变量别管」，写**通配变量** `_`（或者 `_X`），不要写 `^`。

## 13.5 可移植的聚合写法

内建的 `aggregate_all/3` **只有 SWI 有**，GNU 没有。标准套路是
**「`findall` 收值 → 对列表做普通递归」**：

```prolog
count_all(Goal, N) :-
    findall(dummy, call(Goal), L),
    length(L, N).

sum_of(Template, Goal, S) :-
    findall(V, ( call(Goal), V = Template ), Vs),   % 模板可能是个表达式，所以用 V = Template 求出来
    sum_rec(Vs, S).

max_of(Template, Goal, M) :-
    findall(V, ( call(Goal), V = Template ), [First | Rest]),   % 注意模式：头一个 + 余下
    max_rec(Rest, First, M).
```

```text
一共有 5 条 likes 事实
所有商品价格之和         = 10
商品条数                 = 3
最贵的价格               = 5
每人喜欢几样             = [mary-2,john-3]
```

`count_all` 里用 `call(Goal)` 而不是直接 `Goal` —— **`findall` 的第二个参数是个项，
传进来本来就是项，但 `call/1` 让「传闭包」和「传目标」两种写法都能工作**（11 章）。

`max_of` 用 `[First|Rest]` 直接做模式匹配：**空列表会在这里失败**（这也合理 —— 「最大值」
对空集合没有定义）。

嵌套统计也很自然 —— 模板里再做一次 `findall`：

```prolog
findall(W - N, ( member(W, [mary, john]),
                 findall(_Y, likes(W, _), Ls),
                 length(Ls, N) ), Counts).      % [mary-2, john-3]
```

> **`aggregate_all/3` 能少写几行，但换来的代码不通用。** 本教程一律手写 —— 手写版
> 还有个好处：它**是纯逻辑的**（没有非回溯副作用），能安全地放进别的回溯结构里。

## 13.6 三个必须知道的坑

```text
    正在处理 1
    正在处理 2
    正在处理 3
上面三行「正在处理」是 findall 一口气跑完全部解的结果。
findall(X-X, member(X,[1,2]))  = [1-1,2-2]
元素配下标要显式给两个变量：[0-a,1-b,2-c]
坑 3：Goal 里抛异常，异常会穿过 findall，需要自己在外面 catch
```

**坑 1 — `findall` 会一口气跑完全部解，副作用全在返回前发生。**
`findall(X, (member(X,[1,2,3]), format(...)), _)` 会先把三次打印做完，再返回列表。
**想在遍历中途做判断、甚至提前跳出，`findall` 做不到** —— 要么改用 `forall/2`（11 章），
要么在 `Goal` 里自己累积。

**坑 2 — 模板里变量写重了，语义就变了。**
`X - X` 是「同一个值配自己」，得 `[1-1, 2-2]`；**它不等于「元素配下标」**。
要下标得显式引入第二个变量：`findall(I-V, nth0(I,[a,b,c],V), L)` 得 `[0-a,1-b,2-c]`。

**坑 3 — `Goal` 抛的异常会穿过 `findall`。**
`findall` **不吞异常**，`catch` 必须写在外面：

```prolog
catch(findall(X, risky(X), L), Err, Handler).
```

## 13.7 坑位清单

1. **用 `bagof` 收集却冒出一堆组** → 自由变量在分组。加 `^` 或改 `findall`。
2. **`bagof`/`setof` 在无数据时让整个谓词失败** → 它们无解即失败，要 `[]` 请用 `findall`。
3. **`findall` 里写 `X^Goal`** → 报错（`findall` 不认 `^/2`），改通配变量 `_`。
4. **以为 `findall` 会把外部变量绑定上** → 它内部复制变量，绑定不外漏。
5. **`bagof` 的多个分组解没收集** → 它本身多解，通常要配 `findall(X-G, bagof(...), Ls)`。
6. **指望 `findall` 中途中断** → 它总是跑完全部解，副作用全在返回前。
7. **模板里 `X-X` 当「元素配下标」** → 是「值配自己」，要显式两个变量。
8. **忘了 `catch` 包住 `findall`** → `Goal` 的异常会穿出去。
9. **用 `aggregate_all/3` 或 `count/1`** → 只有 SWI 有，GNU 没有。
10. **用 `setof` 又想要原来的求解顺序** → `setof` 会排序，要原序用 `findall`。

---

上一章：[12 · 元编程](12-metaprogramming.md) · 下一章：[14 · 输入输出](14-io.md)
