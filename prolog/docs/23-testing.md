# 23 · 测试

> 对应示例：[`examples/23_testing/23_testing.pl`](../examples/23_testing/23_testing.pl)

## 23.1 为什么 Prolog 特别需要测试

**其他语言里，一个函数的观察点只有「返回值」；Prolog 里同一个谓词换个调用模式就是
完全不同的东西。** 看 `lib_append/3`：

```prolog
lib_append([1,2], [3], X).              % X = [1,2,3]        —— 拼接模式
findall(P-S, lib_append(P, S, [1,2]), Splits).
% [[ ]-[1,2], [1]-[2], [1,2]-[]]                           —— 拆分模式
```

**所以「测过了」必须说清测的是哪个模式** —— 23.5 专门讲这件事。

**还有四件肉眼看不出来的事，它们的正确与否同样是 bug**：

```text
① 解的个数（多给一个解，调用方的循环就可能多跑一圈）
② 解的顺序（靠 ! 或 findall 时顺序就是语义的一部分）
③ 有没有留下多余的选择点（性能问题，甚至内存泄漏）
④ 副作用发生了几次（assertz、写文件都可能被回溯重放）
```

**再加上本教程的双引擎背景**：同一段代码在 SWI 与 GNU 上行为可能不同
（21 章的 CLP(FD)、22 章的模块）。

> **把「两边输出一致」写进测试，比事后人工比对可靠得多。**
> **这正是 `run-all.sh` 在做的事：23 个示例 × 3 条通道 × 6 条判定。**

## 23.2 迷你测试框架

**一条用例写成 `name(名字, 目标)`：目标成功算通过，失败或抛错都算不通过。**

```prolog
%% 跑一条用例，结果归一成 ok / bad(为什么)
run_one(name(_Name, Goal), Result) :-
    catch( ( call(Goal) -> Result = ok ; Result = bad(failed) ),
           Err,
           Result = bad(threw(Err)) ).

%% 跑一个套件并打报告
run_suite(Title, Cases) :-
    format("  ~s~n", [Title]),
    findall(N-R, ( member(name(N, G), Cases), run_one(name(N, G), R) ), Results),
    forall(member(N2-bad(Why), Results), report_bad(N2, Why)),
    length(Results, Total),
    findall(N3, member(N3-bad(_), Results), BadNames),
    length(BadNames, Bad),
    Ok is Total - Bad,
    format("    小结：共 ~w 例，通过 ~w，不通过 ~w~n", [Total, Ok, Bad]).

report_bad(Name, failed)     :- format("    [FAIL] ~w：目标没有成立~n", [Name]).
report_bad(Name, threw(Err)) :- functor(Err, F, _),
                                format("    [FAIL] ~w：抛了 ~w/… ~n", [Name, F]).
```

**两个设计要点**：

- **`catch` 把「抛错」也归成 `bad(threw(Err))`** —— 否则一个抛异常的用例会被
  `main/0` 的顶层 `catch` 抓走，整个套件中断。
- **`report_bad(Name, threw(Err))` 只打印 `functor`** —— 因为错误项的具体内容
  两套引擎填得不一样（20 章），打印出来会破坏字节级比对。

### 断言库

```prolog
%% 目标必须成立
expect_true(Goal) :- call(Goal).

%% 目标必须无解
expect_false(Goal) :- \+ call(Goal).

%% 解集合正好是 Expected：自动排序去重 → 忽略【解的顺序】与【重复解】
expect_set(Template, Goal, Expected) :-
    findall(Template, Goal, L), sort(L, S), sort(Expected, E), S == E.

%% 解序列正好是 Expected：保序、保留重复 → 连【解的个数与顺序】一起钉住
expect_bag(Template, Goal, Expected) :-
    findall(Template, Goal, L), L == Expected.

%% 有且仅有一个解
expect_single(Template, Goal) :- findall(Template, Goal, [_]).

%% 目标必须抛错，且错误项的 functor 是 Name
expect_throw(Goal, Name) :-
    catch( ( call(Goal), fail ),          % ← 那句 fail 是关键
           Err,
           ( functor(Err, F, _),
             ( F == Name -> true ; throw(unexpected_exception(F, Name)) ) )).
```

**`expect_set` 与 `expect_bag` 的区别就在「排不排序」**：

| 断言 | 顺序 | 重复 | 用途 |
|---|---|---|---|
| `expect_set/3` | 忽略 | 忽略 | 只关心「解集合」 |
| `expect_bag/3` | **保留** | **保留** | 连个数与顺序一起钉住 |

**`expect_false/3` 的注意事项**：`\+` 的语义是「按当前绑定求解不通」，
所以**被测参数应当已经绑定**。拿未绑定的变量去 `expect_false`，结论没有意义。

**`expect_throw` 里那句 `fail` 是关键**：

> **目标「没抛错」时强制整条用例失败**，否则「没抛错」会被误判成通过。
> 要是漏了它，**这条用例会静默通过，是最危险的那种假绿**（23.3 有实证）。

## 23.3 框架自检

> **搭测试框架的第一步不是测业务代码，而是「证明框架会报失败」。**
> **一个永远打绿勾的框架比没有框架更糟：它给你虚假的安全感。**

第一组用例都**应该**通过：

```text
套件：框架自检 A（预期全通过）
  小结：共 6 例，通过 6，不通过 0
```

第二组里**故意**埋了四条注定失败的用例（第 1、3、5、6 条）：

```text
套件：框架自检 B（这四条应当被报成 [FAIL]）
  [FAIL] deliberately_fails：目标没有成立
  [FAIL] set_mismatch：目标没有成立
  [FAIL] bag_order_matters：目标没有成立
  [FAIL] no_throw_expected：目标没有成立
  小结：共 6 例，通过 2，不通过 4
```

**注意第 3 与第 5 条是两种不同的失败方式**：

```text
第 3 条 set_mismatch      —— 目标成立，但解集合不对；
第 5 条 bag_order_matters —— 解集合一样，只是顺序不同。
顺序也算失败，是 expect_bag 故意的：解的顺序在 Prolog 里是语义。
```

**第 6 条 `expect_throw(真, boom)` 同样值得注意** —— 「该抛错却没抛错」必须是失败，
**靠的是 `catch` 里那句 `fail`**。

## 23.4 bug 是怎么被抓出来的

被测目标是 `lib_sign_buggy/3`（把列表拆成正数表与负数表）：

```prolog
%% 【有 bug 的版本】作者手写测试时用的数据里没有 0，
%% 于是漏掉了 H =:= 0 的那一支。
lib_sign_buggy([], [], []).
lib_sign_buggy([H|T], [H|Ps], Ns) :- H > 0, !, lib_sign_buggy(T, Ps, Ns).
lib_sign_buggy([H|T], Ps, [H|Ns]) :- H < 0, !, lib_sign_buggy(T, Ps, Ns).
%% ← 缺一支：0 既不 >0 也不 <0，递归走到 0 时一条子句都匹配不上

%% 【修好的版本】只多了第四支：0 直接丢掉。
lib_sign([], [], []).
lib_sign([H|T], [H|Ps], Ns) :- H > 0, !, lib_sign(T, Ps, Ns).
lib_sign([H|T], Ps, [H|Ns]) :- H < 0, !, lib_sign(T, Ps, Ns).
lib_sign([0|T], Ps, Ns) :- lib_sign(T, Ps, Ns).
```

**作者手写的三条用例，数据里都没有 0，于是全过**：

```text
套件：lib_sign_buggy（作者手写的三条）
  小结：共 3 例，通过 3，不通过 0
```

**补上边界用例，问题立刻现身**：

```text
套件：同一实现，补上含 0 的用例
  [FAIL] sign_with_zero：目标没有成立
  [FAIL] sign_only_zero：目标没有成立
  小结：共 3 例，通过 1，不通过 2
```

> **原因不是「算错了」，而是「少了 `H = 0` 的那一支子句」：递归走到 0 时一条子句都
> 匹配不上，谓词整个失败。**
>
> **这是 Prolog 里最典型的一类 bug：缺子句，而不是算错数。**
>
> **它有个讨厌的性质：失败会沿调用链往上传** —— 所以你看到的现象往往出现在
> **离 bug 很远的地方**。这也是为什么「靠失败」的 Prolog 调试常常比别的语言难。

**修法就是补一支**：

```text
套件：lib_sign（补上 0 那一支，同样三条用例）
  小结：共 3 例，通过 3，不通过 0
全绿了。注意最后一条：0 被【丢掉】，不归任何一组 ——
这是设计决定。测试的作用不是替你决定，而是把这个决定写下来，
以后谁想改它都得先改测试。这就是回归测试的全部价值。
```

> **「测试的作用不是替你决定，而是把这个决定写下来」** —— 这句话是整章的题眼。
> 0 归哪一组是**设计**问题，测试把它**固化**成契约。

## 23.5 按调用模式分开测

`lib_append/3` 的三种模式行为完全不同，要分开测：

```text
套件：lib_append 的三种模式
  小结：共 5 例，通过 5，不通过 0
前三条验「生成」，后两条验「检查」—— 同一个谓词，两套期望。
```

### 最容易忽略的一类 bug：不终止

```text
lib_len/2 的 (-,+) 模式就是活例子。这么写会永久跑下去：
  findall(L, (between(0,3,N), lib_len(L, N)), Ls)
```

`lib_len/2` 的定义是经典的「先递归再算」：

```prolog
lib_len([], 0).
lib_len([_|T], N) :- lib_len(T, N1), N is N1 + 1.
```

**给定 `N` 求 `L` 时它不会终止**：

```text
原因不是 lib_len 写错了，而是 is/2 只会【失败】，不会帮忙剪枝：
等式 N1 + 1 =:= 3 在 N1 = 2 时成立，但 Prolog 还得继续试
N1 = 3、4、5… 才能确认没有别的解 —— 而那个生成器永远不会停。
（写这个示例时我们真的被它挂住过一次，所以专门写下来。）
```

**两个可移植的解法**：

```prolog
%% 解法一：给生成器套 once/1，剪掉多余的选择点
findall(L, (between(0,3,N), once(lib_len(L, N))), Ls).      % 4 个解

%% 解法二：不用生成模式，改成「先定长度，再构造列表」
findall(L, (between(0,3,N), length(L, N)), Ls).             % 4 个解（连 once 都不用）
```

**样本的生成方式本身也必须可移植**：

> `between/3`、`length/2`、`findall/3` 两边都有而且给出**同样的序列** ——
> 换成引擎私有的随机数就没法比对了。
>
> **经验：写测试时先问「这个目标会终止吗」，再问「结果对不对」。**

## 23.6 性质测试：不写期望值，写不变量

**前面每条用例都得手算期望值。性质测试换个思路**：

> **不写具体答案，只写「不管输入是什么都必须成立的性质」，然后拿一批样本去撞。
> 撞不破就说明没找到反例。**

```prolog
%% 样本：长度 N 的整数表，用 between/3 生成，保证两边顺序一致
nlist(N, L) :- findall(I, between(1, N, I), L).

%% 带正负的样本：1..N 各减 3，于是从 N=3 开始就一定会出现 0
nlist_signed(N, L) :- findall(V, ( between(1, N, I), V is I - 3 ), L).

%% 性质 1：反转不改变长度
prop_rev_len :-
    forall(between(0, 5, N),
           ( nlist(N, L), lib_rev(L, R), lib_len(R, RL), RL =:= N )).

%% 性质 2：反转两次回到原样
prop_rev_twice :-
    forall(between(0, 5, N),
           ( nlist(N, L), lib_rev(L, R1), lib_rev(R1, R2), R2 == L )).
```

```text
套件：lib_rev 的两条性质（样本长度 0..5）
  小结：共 2 例，通过 2，不通过 0
这两条一过，lib_rev 基本就不用担心了，而且一条期望值都没手算。
加样本只要改 between 的上界 —— 对回归测试特别划算。
```

### 同一个性质撞两个实现

**这是性质测试最漂亮的用法** —— 性质写成「接受实现作为参数」：

```prolog
%% 性质 3：正数表长度 + 负数表长度 = 原表长度（元素守恒）
prop_sign_count(Lib, L, P, N) :-
    call(Lib, L, P, N),
    lib_len(P, LP), lib_len(N, LN), lib_len(L, LL),
    LP + LN =:= LL.

%% 性质 4：负数表里的元素必须真的都是负数
prop_sign_neg_only(Lib, L, _P, N) :-
    call(Lib, L, _P2, N),
    forall(member(V, N), V < 0).

%% 用一批样本去撞一条性质：任一样本不成立就失败
prop_all_samples(Lib, Prop) :-
    forall(between(0, 4, N),
           ( nlist_signed(N, L),
             call(Prop, Lib, L, _P, _Ng)
           )).
```

```prolog
run_suite("套件：元素守恒 + 负组纯净（样本里从 N=3 起一定含 0）", [
    name(prop_count_on_fixed,  prop_all_samples(lib_sign, sign_count_ok)),
    name(prop_neg_on_fixed,    prop_all_samples(lib_sign, sign_neg_ok)),
    name(prop_count_on_buggy,  prop_all_samples(lib_sign_buggy, sign_count_ok)),
    name(prop_neg_on_buggy,    prop_all_samples(lib_sign_buggy, sign_neg_ok))
]).
```

```text
  [FAIL] prop_count_on_fixed：目标没有成立
  [FAIL] prop_neg_on_fixed：目标没有成立
  [FAIL] prop_count_on_buggy：目标没有成立
  小结：共 4 例，通过 1，不通过 3
第 3、4 条被抓住了：lib_sign_buggy 在样本 [-2,-1,0] 上直接失败。
注意这里【没有】重写一条数据、也没有手算任何期望值 ——
同一个性质、同一批样本，换个实现撞就行。这就是它的杠杆。
```

> **`call(Lib, ...)` 里的 `Lib` 是个原子 `lib_sign` / `lib_sign_buggy`** ——
> 这就是 11 章讲的高阶谓词：**把「实现」当参数传**。同一个性质、同一批样本，
> 换一个实现就能撞一次，**不需要重写任何数据或期望值**。

**代价要讲清楚**：

> **性质测试只能证明「没找到反例」，不能证明「正确」。**
> 所以它和具体用例是互补的，谁也替不了谁。
>
> **一般做法：性质测试扫大范围找反例，找到之后把那个输入固化成一条具体用例** ——
> 这样回归时既快又准。

## 23.7 测试工具的可移植性

| | SWI | GNU |
|---|---|---|
| `library(plunit)` | ✅ `begin_tests/1`、`test/1`、`end_tests/1`、`run_tests/1` | **完全没有** |
| `assertion/1` | ✅ | **没有** |
| `call_with_time_limit/2`、`time/1` | ✅ | **没有** |

```text
两边的交集就是 call/1、catch/3、findall/3、sort/2、msort/2、==/2。
本章框架只用这几个拼出来，所以三个通道都能跑。
```

**工程上怎么选**：

```text
· 只跑 SWI —— 直接用 plunit，功能齐，能和 CI 集成；
· 要跨引擎 —— 像本章这样自己搭，或者把测试当普通谓词跑。
```

**两条经验，都是被前面几章的差异逼出来的**：

> **① 断言比较「项本身」，不要比较「打印出来的文本」。**
>
> 比文本会踩到浮点位数（07 章）、约束变量打印（21 章）、错误项形状（20 章）这些差异。
> **23.4 那两个套件要是改成「把解转成字符串再比」，三通道的输出立刻就不一致了。**
>
> **② 测试数据也必须是可移植的。**
>
> 样本用 `between/3`、`length/2`、`findall/3` 生成，**别用引擎私有的随机数或时间函数** ——
> 那样连跑两次都不一致。

**最后一条，和 14 章同一个道理：测试不要往 stderr 写东西。**

> `run-all.sh` 的判定里有一条就是「**stderr 必须为空**」，
> 所以本教程所有示例（包括测试代码）的**诊断信息都往 stdout 走**，
> 并且**只在真的出错时才写 stderr**。

## 23.8 坑位清单

1. **用 `=` 比较目标的解** → 会悄悄绑定变量，写出永远通过的假测试。用 `expect_set/3`。
2. **`expect_throw` 忘了 `catch` 里的 `fail`** → 「没抛错」被判成通过，**假绿**。
3. **比「打印出来的文本」而不是「项本身」** → 破坏跨引擎一致性。
4. **`expect_bag` 与 `expect_set` 混用** → 一个管顺序，一个不管，期望值写错。
5. **`expect_false` 用未绑定变量做参数** → `\+` 按当前绑定判断，结论没意义。
6. **只测「正常数据」，不测边界**（0、空表、单元素）→ 23.4 的 bug 就是这么漏的。
7. **测试框架本身没被测试** → 永远打绿勾的框架比没有更糟。
8. **用 `is/2` 做「反向」求解的测试** → 不终止（`lib_len(L, N)` 就是例子）。
9. **样本用随机数/时间生成** → 连跑两次结果都不同，没法比对。
10. **测试代码往 stderr 写** → 违反「stderr 必须为空」的判定。

---

上一章：[22 · 模块与工程组织](22-modules.md) · 下一章：[24 · 综合项目](24-capstone.md)
