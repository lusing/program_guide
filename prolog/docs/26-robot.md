# 26 · 实战：给机器人造一门命令语言

> 对应示例：[`examples/26_robot/26_robot.pl`](../examples/26_robot/26_robot.pl)
> 本章按 Bramer《Logic Programming with Prolog》12.3 + 13.1 扩充。

## 26.1 目标

给一台想象的机器人造一门小命令语言：机器人从原点出发、初始面北，
位置用「向北/向东米数」表示，朝向用「自东逆时针度数」表示。命令一共七个动词：

| 命令 | 效果 |
|---|---|
| `turn n degrees anticlockwise` | 朝向加 n 度 |
| `turn n degrees clockwise` | 等价于逆时针 `-n` 度 |
| `turn right` / `turn left` / `turn round` | 逆时针 -90 / +90 / +180 度 |
| `forward n metres` | 沿当前朝向走 n 米 |
| `back n metres` | 掉头再前进 n 米 |
| `goto n north m east` | 直接置位置 |
| `face n degrees` | 直接置朝向 |
| `report` | 报位置与朝向 |
| `stop` | 收摊 |

大写小写随便混（`TURN Left` 和 `turn left` 是同一条命令），非法输入不崩、
报一句继续吃下一条。

这本质是一个 **REPL**：读一行 → 理解 → 执行 → 改状态 → 循环。它与 19/24 章
的解析器共享同一个骨架（词法 → 语法 → 语义），只是终点从「求值」换成了
「用动态库执行副作用」。

## 26.2 流水线总览

```text
一行字符 ──words/2──▶ 单词列表 ──=..──▶ 命令项 ──verify/1──▶ call/1 ──▶ 改 position/orientation
           小写化+切分        数字词转数      白名单      元调用        （动态库读改写）
```

四步各自独立，每步都能单独测试 —— 这是本章（也是 24 章）最重要的工程模式：
**流水线上每个环节是纯函数，状态和 IO 被压到两端**。

## 26.3 词法：一行字符 → 单词

书上用 `get0` + `name`（Edinburgh 老接口），大小写折叠我们手写 —— 因为
`downcase_atom/2`、`code_type/2` 都是 SWI 私货，GNU 1.5 根本没有（实测
`existence_error`）：

```prolog
lower_code(C, L) :- C >= 65, C =< 90, !, L is C + 32.   % 'A'..'Z' → 'a'..'z'
lower_code(C, C).
```

切词是三态递归：输入耗尽（收最后一个词）、遇空格（词的分界）、普通字符
（折叠后攒进当前词）。攒的方向有讲究 —— **倒攒 + 收尾 `reverse`**，因为
书上 `append(OldWord, [X], New)` 的尾接尾是 O(n²)（09 章的老教训）：

```prolog
words_([32 | Rest], [], Acc, Words) :- !,  % 连续空格：当前词是空的，跳过
    words_(Rest, [], Acc, Words).
words_([32 | Rest], Cur, Acc, Words) :- !, % 空格：封存当前词（倒攒的，先正过来）
    reverse(Cur, W),
    words_(Rest, [], [W | Acc], Words).
words_([C | Rest], Cur, Acc, Words) :-
    lower_code(C, L),
    words_(Rest, [L | Cur], Acc, Words).
```

```text
  "TURN 30 degrees CLOCKWISE"
    → [turn,30,degrees,clockwise]（码表转成项的显示形式）
  "goto   3   north 4 east"
    → [goto,3,north,4,east]
  空行 → []（上层负责跳过）
```

> 实测时这里翻过一次车：倒攒改写后忘了「空格封存点」也要 `reverse`，
> 结果只有**行尾最后一个词**是正的，前面全是反的（`turn` 变 `nrut`），
> 而单词条命令（`report`、`stop`）恰好正常 —— 最诡异的一类 bug。
> 每个攒数据的出口都要检查方向，不是只有最后一个。

## 26.4 组项：单词列表 → 命令

两步：数字词转数，然后 `=..`（univ，05/12 章）把列表拼成项：

```prolog
word_term(Word, T) :-
    (   catch(number_codes(T, Word), _, fail)   % 先试着按数解析
    ->  true                                    % 转不成的 syntax_error 变成普通失败
    ;   atom_codes(T, Word)                     % 再当原子
    ).

words_command(Ws, Cmd) :-
    words_terms(Ws, As),
    Cmd =.. As.        % [turn,left] → turn(left)；[stop] → stop
```

```text
  "turn left"           → turn(left)
  "goto 3 north 4 east"  → goto(3,north,4,east)（数字词已转数）
  "stop"                → stop（单元素表得到原子本身）
```

两个坑藏在 `word_term` 里：

> **`atom_codes` 给你的是原子 `'42'`，不是数 `42`** —— 拿它去 `is` 会当场
> type_error，所以数字词必须走 `number_codes`。
> **`number_codes` 对非数字抛 `syntax_error`** —— 用 `catch(_, _, fail)` 把
> 异常降级成失败，`( -> ; )` 里当普通分支用（20 章的模式）。

## 26.5 白名单：`call/1` 之前的安全边界

「外部文本 → `=..` → `call`」这条链有个致命后果：**用户输入直接变成被执行的
目标**。`halt`、`system(...)`、任何谓词名都会被原样执行 —— 这不是命令语言，
是远程代码执行。所以 `call` 之前必须有白名单：

```prolog
verify(Cmd) :-
    functor(Cmd, F, _),
    once(member(F, [forward, back, turn, goto, face, report, stop])).
```

```text
  verify(turn(left))          通过
  verify(halt)                拒绝（halt 不在白名单）
  verify(system(rm -rf /))    拒绝（头不是七个动词之一）
```

执行时异常（参数个数不对等）也按无效输入处理，别让一条坏命令掀翻整个 REPL：

```prolog
    (   catch(call(Cmd), _, fail)
    ->  true
    ;   say("  无效输入（verify 过了但执行失败）")
    )
```

## 26.6 执行：状态读改写 + 打印纪律

状态就是两个动态库事实（17 章三件套：`retract` 读出 → 算新的 → `assertz` 写回）：

```prolog
:- dynamic(position/2).      % position(北向米数, 东向米数)
:- dynamic(orientation/1).   % orientation(自东逆时针度数，0..359)
```

**朝向归一化**靠 `mod` 的 floored 语义 —— 实测两套引擎一致：`-10 mod 360 = 350`，
`(330+60) mod 360 = 30`，天生把角度压回 0..359：

```prolog
turn(N, degrees, anticlockwise) :-
    once(retract(orientation(Current))),
    New is (Current + N) mod 360,
    assertz(orientation(New)),
    report_orientation.
```

六种转向全部归一到这一条子句（`right`/`left`/`round`/`clockwise` 都换算成
「逆时针加 N 度」再递归进来）—— **一个语义，一个实现**。

**走位**是三角学：朝 d 度走 n 米，北移 `n·sin(d)`、东移 `n·cos(d)`；
度化弧度用字面量 `3.14159265`（书上故意不用 `pi`，原因见下）。

**打印纪律是本章被跨引擎纪律逼出来的核心决策**。浮点直接打印，两套引擎位数
不同（实测：`pi` 在 SWI 打 `3.141592653589793`，GNU 打 `3.1415926535897931`）。
所以坐标**绝不直接打印**：一律 `round` 成整数厘米，手工拼小数点：

```prolog
write_metres(Metres) :-
    H is round(Metres * 100.0),            % 100.0 强制浮点：GNU 的 round/1 拒绝整数
    (   H < 0
    ->  H2 is -H, put_char('-')            % 负号单独补
    ;   H2 = H
    ),
    M is H2 // 100,
    Cm is H2 mod 100,
    format("~w.", [M]),
    (   Cm < 10
    ->  write(0)                           % 补零：8.06 而不是 8.6
    ;   true
    ),
    format("~w", [Cm]).
```

```text
  8.660254031861399     → 8.66
  -0.5                  → -0.50（负号单独补，不是 // 出来的）
  0                     → 0.00
  8.060000000000001     → 8.06（补零：不是 8.6）
  1.7763568394002505e-15 → 0.00（浮点尘埃抹成 0.00）
```

三个细节各自对应一条实测坑：

> **`round(Metres * 100)`** 在 GNU 上对整数参数抛 `type_error(float,0)` ——
> `round(0)` 直接炸，所以乘 `100.0` 强制转浮点。
> **负号不能靠 `//`**：-0.5 的厘米数是 -50，`-50 // 100` 得 -1（floored），
> 拼出「-1.50」—— 错一位。先 `abs` 再补负号才是「-0.50」。
> **补零要补在点后**：8.06 的厘米数是 6，直接打印成「8.6」会误读成 8 米 6。

## 26.7 REPL 主循环：两种写法

**停机判定必须在「转成项之后」**：词表阶段只有码表，`[115,116,111,112]` 和原子
`stop` 永远不相等 —— 实测时 stop 判定写成 `Ws == [stop]`，结果 `stop` 被当成
普通命令送进 `call`，一头撞上 GNU 的**内建谓词 `stop/0`**（gplc 更是直接拒绝
编译：`redefining built-in predicate`）。所以命令动词不能随手落成谓词 ——
`stop` 在主循环里拦截，其余动词才交给 `call`：

```prolog
step_line(Line, Action) :-
    once(words(Line, Ws)),
    (   Ws == []
    ->  Action = skip                        % 空行：跳过
    ;   words_command(Ws, Cmd),
        (   Cmd == stop
        ->  format("  > stop~n", []),
            say("** End of Input"),
            Action = stop
        ;   execute_cmd(Cmd),
            Action = continue
        )
    ).
```

**纯版主循环** —— 脚本当参数穿进去（25 章菜单同款）：

```prolog
run_script([]).
run_script([Line | Rest]) :-
    step_line(Line, Action),
    (   Action == stop
    ->  true
    ;   run_script(Rest)
    ).
```

**repeat 版主循环** —— 书上 `control_robot` 的原味：`repeat` + 动态库队列
（17.3 模式搬进 REPL），出口纪律两条：队列空砍 `repeat`，`stop` 砍 `repeat`：

```prolog
run_script_repeat :-
    repeat,
    (   line_queue(_)
    ->  true
    ;   !, fail
    ),
    once(retract(line_queue(Line))),
    step_line(Line, Action),
    (   Action == stop
    ->  !                                    % 砍掉 repeat：REPL 收摊
    ;   fail                                 % 退回 repeat 吃下一条（skip 也走这里）
    ).
```

两种主循环跑出来的对话**逐字节一致**（三通道验证的第 6 条判定替你盯着）：

```text
主循环 = 递归穿脚本（纯版）：
** 位置：北向 0.00 米；东向 0.00 米
** 朝向：自东逆时针 90 度
  > turn(30,degrees,clockwise)
** 朝向：自东逆时针 60 度
  > forward(10,metres)
** 位置：北向 8.66 米；东向 5.00 米
  > back(10,metres)
** 朝向：自东逆时针 240 度
** 位置：北向 0.00 米；东向 0.00 米
  ...
  无效输入：bback(6,metres)
  ...
主循环 = repeat + 动态库队列（对照版，行为一致）：
  > turn(left)
** 朝向：自东逆时针 180 度
  > forward(5,metres)
** 位置：北向 0.00 米；东向 -5.00 米
  ...
```

第二段朝西走，东向坐标是 `-5.00` —— 负号打印的试金石。

> 浮点算术本身在两套引擎上是可信的（都是 C double、同样的运算顺序），
> **唯一的雷是打印**。整数量纲（厘米）+ 手工格式化是最便宜的确定性。

## 26.8 坑位清单

1. **`call/1` 之前没有白名单** → 用户输入变成任意目标执行（RCE）；`verify` 头部。
2. **命令动词撞内建谓词名** → `stop/0` 是 GNU 内建，gplc 拒绝编译；改名或在
   主循环拦截，动词表设计时先查内建清单。
3. **拿码表和原子比较** → `[115,116,111,112] \== [stop]`；停机判定放在
   `words_command` 之后。
4. **`atom_codes` 的结果当数用** → 得到原子 `'42'` 不是数；数字词走
   `number_codes`，且 `catch` 接住 `syntax_error`。
5. **打印浮点坐标** → 两引擎位数不同，逐字节比对必炸；整数厘米 + 手工小数点。
6. **GNU `round/1` 吃整数** → `type_error(float,0)`；乘 `100.0` 强制浮点。
7. **负数坐标用 `//` 拼小数点** → floored 除法把 -0.5 拼成「-1.50」；先 `abs`
   再补负号；补零补在点后。
8. **大小写折叠用 `downcase_atom`/`code_type`** → SWI 私货；手写 `C+32` 区间判断。
9. **攒字符尾接尾** → O(n²)；倒攒 + `reverse`，且每个封存出口都要转正。
10. **REPL 忘了 `initialise` 先 `retractall`** → 上一次运行的状态残留；
    带状态的循环必须先复位再跑。

---

上一章：[25 · 循环的三种写法](25-loops.md) · 下一章：[27 · 实战：专家系统外壳](27-expert-shell.md)
