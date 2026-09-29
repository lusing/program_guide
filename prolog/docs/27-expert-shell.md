# 27 · 实战：专家系统外壳

> 对应示例：[`examples/27_expert_shell/27_expert_shell.pl`](../examples/27_expert_shell/27_expert_shell.pl)
> 本章按 Bramer《Logic Programming with Prolog》13.2 扩充。

## 27.1 外壳：引擎与内容分离

要做一个「多选题测验」，最直接的写法是把题目写死在代码里 —— 但那样每个新测验
都要改程序。**外壳（shell）** 反过来：写一个**与内容无关的引擎**，每个具体测验
是一份数据文件。这就是「专家系统外壳」的含义 —— 医疗诊断、故障排查、测验打分，
换汤不换药。

外壳分两阶段：

| 阶段 | 做什么 | 用的机制 |
|---|---|---|
| setup | 把数据文件读进数据库，变成事实 | `see`/`read` + `assertz`（14/17 章） |
| 运行 | 自动生成答题对话、计分、给反馈 | 失败驱动循环 + 动态库计分（25/17 章） |

外壳的**通用性纪律**：不假设题数、不假设每题答案数、不假设满分 ——
全部从数据派生。判断一个外壳写得好不好，就看换一份完全不同形状的数据，
引擎要不要改。

## 27.2 先设计数据文件

书上的做法值得学：**先设计「一份具体应用的数据文件长什么样」，再想它要变成
哪些事实，最后才写读取器**。数据文件是一串 Prolog 项（用户看不见它，
所以用项、不用 CSV 之类，反而是最顺手的）：

```text
'Are you a genius? Answer our quiz and find out!'.

'What is the name of this planet?'.
'Earth'. 20. 'The Moon'. 5. 'John'. 0. end.

'What is the capital of Great Britain?'.
'America'. 0. 'Paris'. 6. 'London'. 50. 'Moscow'. 4. end.

'In which country will you find the Sydney Opera House?'.
'London'. 5. 'Toronto'. 4. 'The Moon'. 2. 'Australia'. 10. 'Germany'. 8. end.

endquestions.

0. 20. 'You are definitely not a genius'.
21. 60. 'You need to do some more reading'.
61. 80. 'You are a genius!'.
endmarkscheme.
```

三段结构：标题一项；每题「题面 + 若干（答案, 分数）对 + `end`」，以
`endquestions` 收尾；评分表若干（下限, 上限, 反馈）三元组，以 `endmarkscheme`
收尾。

目标事实三选一：`title/1`、`question/3`、`range/3` —— 其中 `question/3` 的
第三个参数「该题满分」**不写进数据文件**，从答案分数里取最大值派生：

> **单一事实来源**：满分写进数据文件，哪天改了答案分数忘了改满分，
> 数据就静默地自相矛盾。派生（`max` 折叠）虽然多算一步，但永远不会错。
> `max/2` 实测两套引擎都有 —— 但 `atom_number/2`、`term_to_atom/2` 是 SWI
> 私货，GNU 1.5 没有，别顺手用。

生成数据文件时注意 14/16 章的老坑：**项的 `.` 后面必须有空白**。
`Earth.20.` 里的 `.20` 会被词法分析器吃成浮点字面量，整个文件直接语法错误
—— 实测第一版就栽在这：

```prolog
tw(T) :- writeq(T), write('. ').   % 写一个项 + 结束符 + 空白
tn(N) :- write(N), write('. ').    % 数字项同理
```

## 27.3 setup：数据文件 → 事实

三个读取器，全是 25 章的循环形态。**题目循环**是 `repeat` + `read`，
**EOF 护栏必须有** —— `read` 在 EOF 之后永远吐 `end_of_file`，截尾的文件
（哨兵 `endquestions` 丢了）会让循环永远空转：

```prolog
readqs :-
    repeat,
        read(Qt),
        (   Qt == endquestions
        ->  !
        ;   Qt == end_of_file
        ->  say("  【护栏】EOF 先到，endquestions 没来 —— 题库被截尾，止损退出"), !
        ;   proc_question(Qt),
            fail
        ).
```

**答案表读取器**是递归（不是 repeat）：逐对读「答案. 分数.」直到 `end`，
四个参数里滚着两样东西 —— 已攒的答案表和到目前为止的最高分：

```prolog
proc_answers(AnsAcc, AnsList, MaxSoFar, Max) :-
    read(A),
    (   A == end
    ->  AnsList = AnsAcc, Max = MaxSoFar, !
    ;   A == end_of_file
    ->  say("  【护栏】EOF 先到，答案表被截尾，止损退出"),
        AnsList = AnsAcc, Max = MaxSoFar, !
    ;   read(Score),
        append(AnsAcc, [ans(A, Score)], AnsNew),
        MaxNew is max(MaxSoFar, Score),
        proc_answers(AnsNew, AnsList, MaxNew, Max)
    ).
```

初值 `-9999` 是书上的写法：比一切现实分数都小的哨兵。这里每题答案不过
个位数，`append` 尾接尾的可读性优先于 O(n²) 的理论账（26 章的教训在
长输入才要紧）—— 工程判断，不是偷懒。

**评分表循环**同款 `repeat` + 三件套读取。setup 整体先 `retractall` 清场
（26 章坑位：状态残留），再 `see` → 读 → `assertz` → `seen`。

跑完看一眼库里拿到了什么：

```text
  题库 1 读入 3 道题
    What is the name of this planet?：3 个答案，满分 20
    What is the capital of Great Britain?：4 个答案，满分 50
    In which country will you find the Sydney Opera House?：5 个答案，满分 10
  评分表区间：[0-20,21-60,61-80]
```

## 27.4 运行：失败驱动出题 + 动态库计分

出题是 25 章失败驱动循环的教科书应用 —— `question/3` 的每条事实就是生成器的
一个解，`fail` 逼它把所有题轮一遍；**第二条子句收尾**，同时打总分、查评分表：

```prolog
askq :-
    question(Qtext, AnsList, Max),
    ask_and_score(Qtext, AnsList, Max),
    fail.
askq :-
    myscore(S, M),
    format("  总分 ~w / 满分 ~w~n", [S, M]),
    (   once((range(Lo, Hi, Fb), S >= Lo, S =< Hi))
    ->  format("  反馈：~w~n", [Fb])
    ;   say("  分数不落在任何区间 —— 评分表数据配错了（外壳兜底）")
    ).
```

计分靠 17 章的读改写三件套 —— `myscore/2` 一个事实就是「可变变量」：

```prolog
bump(Award, Max) :-
    once(retract(myscore(S, M))),
    S1 is S + Award,
    M1 is M + Max,
    assertz(myscore(S1, M1)).
```

注意这里**不需要**「失败时回滚」：失败驱动循环每一轮的 `assertz` 都是
幂等推进（分数只往前滚），`fail` 撤不掉它们反而是**正好**的 —— 17.2 那条
「副作用不回溯」从坑变成了特性。

用户答题是 25 章的 until 循环：书上的 `readline`（`get0` 逐字符）在批处理
验证下没有键盘，换成**答案脚本 + 动态库队列**（26 章同一个模式）—— 弹一条，
是本题合法答案就收，不是就报一句再弹：

```prolog
ask_until(AnsList, Award) :-
    repeat,
    (   answer_queue(_)
    ->  true
    ;   !, fail                       % 脚本用尽：出口纪律
    ),
    once(retract(answer_queue(A))),
    (   member(ans(A, Award), AnsList)
    ->  !                             % 有效：砍掉 repeat，Award 已由 member 绑定
    ;   format("  “~w”不是有效答案，再答一次~n", [A]),
        fail
    ).
```

完整跑一遍（脚本 `['Mars','The Moon','London','Australia']`，
第一个答案故意答错）：

```text
Are you a genius? Answer our quiz and find out!
What is the name of this planet?
  可选答案：[Earth,The Moon,John]
  “Mars”不是有效答案，再答一次
  本题得 5 / 20
What is the capital of Great Britain?
  可选答案：[America,Paris,London,Moscow]
  本题得 50 / 50
In which country will you find the Sydney Opera House?
  可选答案：[London,Toronto,The Moon,Australia,Germany]
  本题得 10 / 10
  总分 65 / 满分 80
  反馈：You are a genius!
```

## 27.5 通用性体检：换一份完全不同的数据

检验外壳不挑数据 —— 第二份题库：**中文**、两道题、每题三个答案、
评分表带单点区间：

```text
两题小测：答对有奖
2 + 2 等于几？
  可选答案：[三,4,5]
  “六”不是有效答案，再答一次
  本题得 10 / 10
Prolog 的首字母是？
  可选答案：[P,Q,R]
  本题得 10 / 10
  总分 20 / 满分 20
  反馈：满分！边界分正好落在最后一段
```

引擎一行没改。顺带验了两件事：**中文题库过两套引擎逐字节一致**（UTF-8 字节进、
字节出，15 章的结论在文件 IO 上同样成立 —— 数据文件由同一引擎写出再读回，
不存在跨引擎共享）；**边界分 20 落在 `20-20` 单点区间**（`S >= Lo, S =< Hi`
两边都取闭）。

最后把截尾文件喂给 setup，看护栏工作：

```text
  【护栏】EOF 先到，endquestions 没来 —— 题库被截尾，止损退出
  【护栏】EOF 先到，评分表被截尾，止损退出
  截尾后库里剩 1 道题（护栏让它活着回来，而不是死循环）
```

## 27.6 与书上实现的差异清单

| 原书 | 本章 | 原因 |
|---|---|---|
| `readline` 逐字符读键盘 | 答案脚本 + 动态库队列 | 批处理验证无键盘；顺带可测试 |
| `repeat`+`read` 无 EOF 防护 | 每个读循环加 EOF 护栏 | 截尾文件 = 死循环（25 章） |
| 满分 `max` 从 `-9999` 起滚 | 保留 | `max/2` 两引擎都有，实测可用 |
| `get0`/`name` Edinburgh 接口 | `see`/`read`/`tell`/`writeq` | 14 章的可移植子集 |

## 27.7 坑位清单

1. **`repeat`+`read` 不查 `end_of_file`** → 截尾文件死循环；所有读循环双哨兵。
2. **数据文件项后无空白** → `Earth.20.` 的 `.20` 被吃成浮点，整文件语法错误；
   `writeq` 后跟 `'. '`。
3. **满分写进数据文件** → 与答案分数静默不一致；从分数表派生。
4. **setup 不先 `retractall`** → 换题库时上一份的事实残留，题数翻倍。
5. **`runquiz` 不复位 `myscore`** → 二次运行分数翻倍；读改写前先清零。
6. **失败驱动 `askq` 忘了第二条子句** → 测验永远以 `false` 收场，反馈没了。
7. **计分依赖回溯回滚** → 回溯撤不掉 `assertz`；要么幂等推进，要么自己写回滚。
8. **`range` 查询用 `findall` 全捞再筛** → 直接 `range(Lo,Hi,Fb), S >= Lo, S =< Hi`
   让数据库的选择点干筛活，配 `once`。
9. **评分表区间配出空洞** → 分数落空时没反馈；兜底分支必须显式打印。
10. **拿 `atom_number/2`、`term_to_atom/2` 当标准** → SWI 私货，GNU 1.5 没有。

---

上一章：[26 · 实战：机器人命令语言](26-robot.md) · 回到 [教程总览](01-overview.md)
