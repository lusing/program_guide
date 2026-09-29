# 25 · 循环的三种写法

> 对应示例：[`examples/25_loops/25_loops.pl`](../examples/25_loops/25_loops.pl)
> 本章按 Bramer《Logic Programming with Prolog》第 6 章扩充。

## 25.1 Prolog 没有循环语句

Prolog 的语法里没有 `for`、没有 `while`、没有 `do`。但「把一段目标重复执行」
的需求一个不少，全部由三种**形态**覆盖：

| 命令语言里的循环 | Prolog 里的形态 | 已经在哪里见过 |
|---|---|---|
| `for i = 1..N` | 递归倒数，或 `between/3` | 09 章（递归） |
| `until 条件` | 递归 + 析构，或 `repeat` + `!` | 17 章（repeat+assert） |
| `foreach` | 生成器 + 副作用 + `fail` | 06 章（失败驱动） |

本章把它们并排放着对照，补齐每种的完整写法，最后给出「什么时候用哪种」的判据。

**先交代交互循环怎么教**：书上的 until 循环从键盘 `read`，而本教程的批处理验证下
stdin 是 `/dev/null` —— `get_code/1` 一上来就吐 `-1`，`read/1` 一上来就吐
`end_of_file`（两套引擎实测一致）。所以交互循环的标准做法是**把输入做成脚本**：
纯版用列表穿参（09 章累加器思路），带状态版用动态库当队列（17 章读改写）。
IO 全推到边缘，循环核心保持纯的、可测试的。

## 25.2 定数循环（for）

**倒数递归** —— 第二个子句读作「要 `loop(N)`：做 N 号的事，然后 `loop(N-1)`」；
第一个子句是终止条件：

```prolog
loop(0).
loop(N) :- N > 0, format("  倒数第 ~w 轮~n", [N]), M is N - 1, loop(M).
```

```text
loop(3)： 倒数第 3 轮 / 倒数第 2 轮 / 倒数第 1 轮
```

这里埋着本章第一个坑：**必须 `M is N-1` 换出新变量**。写 `loop(N-1)` 传的是项
`-(N,1)`，不是 4-1=3 —— 递归永远匹配不到 `loop(0)`，直到栈爆：

```text
write_canonical 眼见为实，6-1 的标准形是：
-(6,1)
```

**区间递归** —— 终止条件是「两个参数相等」：

```prolog
output_values(Last, Last) :- !, format("  ~w（终点）~n", [Last]).
output_values(First, Last) :-
    format("  ~w~n", [First]),
    N is First + 1,
    output_values(N, Last).
```

**`between/3` 是两套引擎都有的内建生成器**（实测 SWI 9 / GNU 1.5 均可用），
一行顶上面两段：

```prolog
squares_upto(N, Ss) :- findall(S, (between(1, N, I), S is I * I), Ss).
```

```text
between(1,6,I) 配合 I*I   = [1,4,9,16,25,36]
between(3,1,N) 倒着要    = []（升序生成器，倒序是空）
```

注意最后一行：**`between/3` 只会升序**，倒序循环还得手写倒数递归。

**求和的声明式重述** —— 「1..N 累加」最自然的翻译不是循环，是自指的数学定义：
前 N 项的和 = 前 N-1 项的和 + N：

```prolog
sumto(1, 1) :- !.
sumto(N, S) :- N > 1, N1 is N - 1, sumto(N1, S1), S is S1 + N.
```

```text
sumto(100) 声明式求和    = 5050
```

## 25.3 条件循环（until）

**纯递归版** —— 脚本当参数穿进去，每轮消费一个，有效就停：

```prolog
get_answer_([A | Rest], Answer) :-
    format("  尝试回答 ~w ...~n", [A]),
    (   valid_answer(A)
    ->  Answer = A
    ;   get_answer_(Rest, Answer)
    ).

valid_answer(yes).
valid_answer(no).
```

```text
条件循环（纯递归版）：脚本 = [maybe,possibly,yes]，只认 yes/no
  尝试回答 maybe ...
  尝试回答 possibly ...
  尝试回答 yes ...
  纯递归版最终采纳     = yes
```

**repeat 版** —— 同一个循环，状态放进动态库队列。`repeat` 的名字是个谎言：
它不「重复」任何东西，只是**永远成功**，从而制造一个无限的选择点。回溯到它
就再次成功，求值方向从「右到左」翻回「左到右」，如此往复：

```prolog
ask_until_valid(Answer) :-
    repeat,
    (   answer_queue(_)             % 出口纪律：队列空就砍掉 repeat
    ->  true                        % —— 少了这条，队列耗尽后
    ;   !, fail                     %    repeat ↔ retract 无限空转
    ),
    once(retract(answer_queue(A))), % 弹一条
    (   valid_answer(A)
    ->  !, Answer = A               % 有效：砍掉 repeat，循环结束
    ;   format("  ~w 无效，回到 repeat 再来~n", [A]),
        fail                        % 无效：退回 repeat 重来
    ).
```

```text
  unsure 无效，回到 repeat 再来
  possibly 无效，回到 repeat 再来
  repeat 版最终采纳    = no
```

两个必须想清楚的点：

> **`repeat` 之后的目标回溯不可达它左边** —— `repeat` 左侧的目标永远不会被
> 「重来」，所以初始化放左边、循环体放右边，正好。
>
> **成功的分支里必须有 `!`** —— 砍掉 `repeat` 留下的选择点，循环才结束；
> 忘了它就是死循环（06 章的老坑在这里最致命）。

**菜单程序** —— 书上用 repeat 写菜单，但尾递归版更直白：处理完一个选项就带着
剩余脚本调自己，`d` 分支不再递归，循环自然结束：

```prolog
menu_([d | _Rest]) :-
    !,
    format("  MENU  a/b/c/d，收到输入 d~n", []),
    say("  → 再见！").                                %% d：停止递归
menu_([Choice | Rest]) :-
    format("  MENU  a/b/c/d，收到输入 ~w~n", [Choice]),
    (   menu_action(Choice)
    ->  true
    ;   say("  请重选！")
    ),
    menu_(Rest).
```

```text
  MENU  a/b/c/d，收到输入 b
  → 选了 B
  MENU  a/b/c/d，收到输入 xxx
  请重选！
  MENU  a/b/c/d，收到输入 d
  → 再见！
```

**文件上的 until 循环** —— 重复 `read` 直到哨兵 `end`。这里必须加一条
**EOF 护栏**：`read` 在 EOF 之后永远给 `end_of_file`，文件要是被截了尾、
哨兵丢了，repeat 循环会永远吃 `end_of_file` —— 死循环：

```prolog
    repeat,
        read(X),
        (   X == end
        ->  say("  读到哨兵 end，正常收尾"), !
        ;   X == end_of_file
        ->  say("  【护栏】读到 EOF 还没见哨兵 —— 截尾文件，止损退出"), !
        ;   format("  读到项 ~w，继续~n", [X]),
            fail
        ),
    seen.
```

```text
文件上的 until 循环（完整文件）：
  读到项 first，继续
  读到项 second，继续
  读到项 third，继续
  读到哨兵 end，正常收尾
文件上的 until 循环（截尾文件，故意不写哨兵）：
  读到项 first，继续
  读到项 second，继续
  【护栏】EOF 先到，哨兵没来 —— 没有这条就是死循环
```

27 章的专家系统外壳会在真实数据文件上再用一次这条护栏。

## 25.4 失败驱动循环（foreach）

**经典两子句技巧** —— 第一条用 `fail` 逼 `dog(X)` 把所有解轮一遍；
第二条空体事实负责「最后整体成功」：

```prolog
alldogs :-
    dog(X),
    format("  ~w is a dog~n", [X]),
    fail.
alldogs.
```

```text
  fido is a dog
  fred is a dog
  jonathan is a dog
```

**少了第二条子句会怎样** —— 三条狗照样都打出来（副作用先发生），但目标整体
以 `false` 收场。在顶层无所谓，在程序里这个失败会沿调用链上传：

```text
  fido is a dog
  fred is a dog
  jonathan is a dog
  alldogs_bad（少第二条子句）：逐条照打，整体却 false
```

这就是「副作用不回溯」（17.2）的正面舞台：**失败驱动循环里 `assertz` 攒下的
东西不会丢** —— 副作用发生在 `fail` 之前。反过来想拿「循环里算出的结果」，
循环结束后变量绑定已经被撤销，必须走副作用或 `findall`：

```text
  findall 等价收集      = [martin-williams,jane-wilson]
  失败驱动没建表，但用 findall 数得出来：3 条 dog
```

失败驱动 vs `findall` 的取舍：**不要列表结果、只要副作用（打印、写文件、
assertz）就失败驱动** —— 不建表、省内存；**要列表**就 `findall`。

最后一个语义陷阱 —— `forall(Generate, Test)` 的定义是
`\+ (Generate, \+ Test)`，**空集上恒真**：

```text
  forall(member(_,[]), fail) = true（空集上恒真，当存在量词用会错）
```

把 `forall` 当存在量词用（「有满足条件的吗」）是语义错位 —— 那是 `once(member(X, L))`
或 `\+ \+`（10 章）的活。

## 25.5 选择判据

| 需求 | 写法 | 理由 |
|---|---|---|
| 已知次数 | `between/3`（内建）；倒序/自定义步长用倒数递归 | 一行顶一段 |
| 直到条件成立 | 递归 + 析构（纯、可测试）；`repeat`+`!` 只在状态必须进动态库时 | repeat 难读且坑多 |
| 遍历所有解 + 副作用 | 失败驱动（两子句） | 不建表、省内存 |
| 遍历所有解 + 要结果 | `findall` | 列表留在变量里 |
| 「对每个都成立」 | `forall/2` | 注意空集恒真 |

三条总原则：

> **递归是默认答案** —— 它最纯、可测试、能双向（生成/消费），09 章的功夫全用得上。
> **回溯本身就是循环** —— 生成器（`between`、`member`、数据库事实）+ `fail`
> 是 Prolog 独有的「免费循环」，不用白不用。
> **repeat 是最后手段** —— 只在「状态必须放动态库、递归参数传不动」时才值得
> 承担它的坑（死循环、`!` 位置、出口纪律）。

## 25.6 坑位清单

1. **`loop(N-1)` 直接递归** → 传的是项 `-(N,1)`，永不终止；先 `M is N-1`。
2. **失败驱动循环少第二条子句** → 副作用照做、整体 `false`，失败沿调用链上传。
3. **`repeat` 循环忘 `!`** → 死循环；成功分支必须砍掉选择点。
4. **`repeat` 循环没留出口** → 队列/条件耗尽后 `repeat` ↔ 下一个目标无限空转。
5. **`repeat` 左边放循环体** → 左侧目标回溯不可达，「重来」的永远只是右边。
6. **`between(3,1,N)` 想倒序** → 空解；倒序手写倒数递归。
7. **`forall` 当存在量词用** → 空集恒真，「有吗」要用 `once(member(...))`。
8. **交互循环直接 `read` 键盘** → 批处理/测试环境 stdin 是 EOF：`read` 吐
   `end_of_file`、`get_code` 吐 `-1`；把输入做成脚本（列表穿参或动态库队列）。
9. **文件 until 循环只查哨兵不查 EOF** → 截尾文件死循环；两个哨兵都查。
10. **失败驱动循环里指望变量绑定存活** → 回溯已撤销绑定；结果走副作用或 `findall`。

---

上一章：[24 · 综合项目：一个解释器](24-capstone.md) · 下一章：[26 · 实战：机器人命令语言](26-robot.md)
