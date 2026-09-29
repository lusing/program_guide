%% ============================================================================
%%  26_robot.pl —— 实战：给机器人造一门命令语言（REPL）
%%
%%  对照 Bramer《Logic Programming with Prolog》12.3 + 13.1：
%%  一门小命令语言，控制机器人在平面上走动 ——
%%
%%      turn 30 degrees clockwise / turn left / turn round
%%      forward 10 metres / back 5 metres
%%      goto 3 north 4 east / face 70 degrees / report / stop
%%
%%  流水线四步（与 19/24 章的解析器同一个骨架，只是终点是「执行」）：
%%
%%      一行字符 → 单词列表 → 命令项 → 白名单校验 → call/1 执行
%%
%%  三条与原书不同的工程决策，全是被「两套引擎逐字节一致」逼出来的：
%%
%%    1. 原书逐字符用 get0/name（Edinburgh 老接口），downcase_atom/code_type
%%       又是 SWI 私货（GNU 1.5 没有）→ 大小写折叠手写 C+32。
%%    2. 浮点打印位数两引擎不同（pi：SWI 3.141592653589793 / GNU
%%       3.1415926535897931）→ 坐标绝不直接打印，一律换算成整数厘米
%%       再手工拼小数点。
%%    3. 原书 findword 用 append 尾接尾攒词表，O(n²)；这里按 09 章倒攒再
%%       reverse，O(n)。
%%
%%  交互 REPL 没有键盘（批处理验证 stdin 是 /dev/null）：
%%  命令做成「脚本」—— 主循环穿列表（纯版），再用 repeat + 动态库队列
%%  写一遍对照版（17.3 的模式搬进 REPL）。
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

say(S) :- format("~s~n", [S]).

%% ---------------------------------------------------------------------------
%%  步骤 1：一行码表 → 单词列表（小写化 + 按空格切分）
%% ---------------------------------------------------------------------------

%% 'A'..'Z'（65..90）折成 'a'..'z'；其余原样。
%% 为什么不用 downcase_atom/2：GNU 1.5 没有这个谓词（SWI 私货）。
lower_code(C, L) :- C >= 65, C =< 90, !, L is C + 32.
lower_code(C, C).

%% words/2：三态递归 —— 输入耗尽（收最后一个词）、遇空格（词的分界）、
%% 普通字符（折大小写后倒攒进当前词）。倒攒 + 最后一次 reverse，避免尾接尾。
words(Codes, Words) :- words_(Codes, [], [], Words).

words_([], Cur, Acc, Words) :-
    (   Cur == []
    ->  Acc = Words                        % 行尾不是空格：没有悬着的词
    ;   reverse(Cur, W),                   % 单词本身也是倒攒的：先正过来
        reverse([W | Acc], Words)          % 词序也是倒的：再一次 reverse
    ).
words_([32 | Rest], [], Acc, Words) :- !,  % 连续空格：当前词是空的，直接跳过
    words_(Rest, [], Acc, Words).
words_([32 | Rest], Cur, Acc, Words) :- !, % 空格：封存当前词（倒攒的，先正过来）
    reverse(Cur, W),
    words_(Rest, [], [W | Acc], Words).
words_([C | Rest], Cur, Acc, Words) :-
    lower_code(C, L),
    words_(Rest, [L | Cur], Acc, Words).

demo_step1 :-
    say("---- 1. 词法：一行字符 → 单词 ----"),
    words("TURN 30 degrees CLOCKWISE", Ws1),
    words_terms(Ws1, As1),
    format("  \"TURN 30 degrees CLOCKWISE\"~n    → ~w（码表转成项的显示形式）~n", [As1]),
    words("goto   3   north 4 east", Ws2),  % 连续空格照样切干净
    words_terms(Ws2, As2),
    format("  \"goto   3   north 4 east\"~n    → ~w~n", [As2]),
    words("", Ws3),
    format("  空行 → ~w（上层负责跳过）~n", [Ws3]).

%% ---------------------------------------------------------------------------
%%  步骤 2：单词列表 → 命令项（数字词转数，然后 =.. 拼项）
%% ---------------------------------------------------------------------------

%% 数字词优先按数解析（atom_codes 得到的是原子 '42'，不是数 42！），
%% 解析不了再当原子。catch 把「转不成数」的 syntax_error 变成一次普通失败。
word_term(Word, T) :-
    (   catch(number_codes(T, Word), _, fail)
    ->  true
    ;   atom_codes(T, Word)
    ).

words_terms([], []).
words_terms([W | Ws], [T | Ts]) :- word_term(W, T), words_terms(Ws, Ts).

words_command(Ws, Cmd) :-
    words_terms(Ws, As),
    Cmd =.. As.                             % [turn,left] → turn(left)；[stop] → stop

demo_step2 :-
    say("---- 2. 组项：单词列表 → 命令项（=..）----"),
    words("turn left", W1), words_command(W1, C1),
    format("  \"turn left\"           → ~q~n", [C1]),
    words("goto 3 north 4 east", W2), words_command(W2, C2),
    format("  \"goto 3 north 4 east\"  → ~q（数字词已转数）~n", [C2]),
    words("stop", W3), words_command(W3, C3),
    format("  \"stop\"                → ~q（单元素表得到原子本身）~n", [C3]).

%% ---------------------------------------------------------------------------
%%  步骤 3：白名单 —— call/1 之前的安全边界
%% ---------------------------------------------------------------------------

%% 把外部文本直接 =.. 成项再 call，等于把「任意目标」交给解释器跑。
%% 命令头必须在白名单里 —— 这门语言只有这七个动词。
verify(Cmd) :-
    functor(Cmd, F, _),
    once(member(F, [forward, back, turn, goto, face, report, stop])).

demo_step3 :-
    say("---- 3. 白名单：call/1 的安全边界 ----"),
    (   verify(turn(left))
    ->  say("  verify(turn(left))          通过")
    ;   say("  verify(turn(left)) 竟然没过")
    ),
    (   verify(halt)
    ->  say("  verify(halt)                竟然通过 —— 漏洞！")
    ;   say("  verify(halt)                拒绝（halt 不在白名单）")
    ),
    (   verify(system('rm -rf /'))
    ->  say("  verify(system(...))         竟然通过 —— 漏洞！")
    ;   say("  verify(system(rm -rf /))    拒绝（头不是七个动词之一）")
    ).

%% ---------------------------------------------------------------------------
%%  步骤 4：执行 —— 位置/朝向放在动态库里读改写（17 章三件套）
%% ---------------------------------------------------------------------------

:- dynamic(position/2).      % position(北向米数, 东向米数)
:- dynamic(orientation/1).   % orientation(自东逆时针度数，0..359)

initialise :-
    retractall(position(_, _)),
    retractall(orientation(_)),
    assertz(position(0, 0)),
    assertz(orientation(90)).              % 初始面北

%% —— 打印纪律：坐标换算成整数厘米，手工拼小数点 ——
%% 浮点直接打印在两套引擎下位数不同（pi：SWI 3.141592653589793 / GNU
%% 3.1415926535897931），整数永远一致。符号单独处理：-0.5 的厘米数是 -50，
%% 直接 // 100 会得到 -1（floored）——"-1.50"，错。先 abs 再补负号才是"-0.50"。
write_metres(Metres) :-
    H is round(Metres * 100.0),            % 100.0 强制浮点：GNU 的 round/1 拒绝整数
    (   H < 0
    ->  H2 is -H, put_char('-')
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

report_position :-
    position(North, East),
    format("** 位置：北向 ", []),
    write_metres(North),
    format(" 米；东向 ", []),
    write_metres(East),
    format(" 米~n", []).

report_orientation :-
    orientation(Deg),
    format("** 朝向：自东逆时针 ~w 度~n", [Deg]).

report :-
    report_position,
    report_orientation.

radians(N, M) :- M is 3.14159265 * N / 180.  % 度 → 弧度（书用字面量，不用 pi）

%% 六种转向全部归一到「逆时针加 N 度」：
turn(right) :- !, turn(90, degrees, clockwise).
turn(left)  :- !, turn(90, degrees, anticlockwise).
turn(round) :- !, turn(180, degrees, anticlockwise).
turn(N, degrees, clockwise) :-
    !,
    N1 is -1 * N,
    turn(N1, degrees, anticlockwise).
turn(N, degrees, anticlockwise) :-
    once(retract(orientation(Current))),
    New is (Current + N) mod 360,           % floored mod：-10 mod 360 = 350，天然归一化
    assertz(orientation(New)),
    report_orientation.

face(N, degrees) :-
    retractall(orientation(_)),
    assertz(orientation(N)),
    report_orientation.

goto(North, north, East, east) :-
    retractall(position(_, _)),
    assertz(position(North, East)),
    report_position.

forward(N, metres) :-
    once(retract(position(North, East))),
    orientation(Degrees),
    radians(Degrees, Rads),
    North1 is North + N * sin(Rads),        % 朝 d 度走 n 米：北移 n·sin(d)，东移 n·cos(d)
    East1 is East + N * cos(Rads),
    assertz(position(North1, East1)),
    report_position.

back(N, metres) :-
    turn(180, degrees, anticlockwise),      % 「倒退」= 掉头再前进
    forward(N, metres).

%% 注意：命令表里的动词不能随手落成谓词 —— stop/0 就是 GNU Prolog 的内建
%% 谓词，gplc 直接拒绝编译（redefining built-in）。所以 stop 在主循环里
%% 拦截处理，其余动词才交给 call/1。

%% ---------------------------------------------------------------------------
%%  REPL 主循环：脚本驱动
%% ---------------------------------------------------------------------------

%% 一行 → 词表 → 命令项，然后分派：
%%   stop   → 打印收摊信息，报告 Action = stop（不落成谓词，见上）
%%   空行   → skip（原书专门写了 writeout(['']) 跳过空行）
%%   其他   → verify 白名单 → call/1；执行抛异常（参数个数不对等）也按无效处理
%% 停机判定必须在「转成项之后」：词表阶段只有码表，认不出 stop 这个原子。
step_line(Line, Action) :-
    once(words(Line, Ws)),
    (   Ws == []
    ->  Action = skip
    ;   words_command(Ws, Cmd),
        (   Cmd == stop
        ->  format("  > stop~n", []),
            say("** End of Input"),
            Action = stop
        ;   execute_cmd(Cmd),
            Action = continue
        )
    ).

execute_cmd(Cmd) :-
    (   verify(Cmd)
    ->  format("  > ~q~n", [Cmd]),
        (   catch(call(Cmd), _, fail)
        ->  true
        ;   say("  无效输入（verify 过了但执行失败）")
        )
    ;   format("  无效输入：~q~n", [Cmd])
    ).

%% 纯版：脚本列表当参数穿进去（09 章累加器思路，25 章菜单同款）。
run_script([]).
run_script([Line | Rest]) :-
    step_line(Line, Action),
    (   Action == stop
    ->  true
    ;   run_script(Rest)
    ).

%% 对照版：repeat + 动态库队列（原书 control_robot 的可移植重写）。
run_script_repeat :-
    repeat,
    (   line_queue(_)                       % 出口纪律（25 章）：队列空就砍掉 repeat
    ->  true
    ;   !, fail
    ),
    once(retract(line_queue(Line))),
    step_line(Line, Action),
    (   Action == stop
    ->  !                                   % 砍掉 repeat 的选择点：REPL 收摊
    ;   fail                                % 退回 repeat 吃下一条（skip 也走这里）
    ).

:- dynamic(line_queue/1).

%% ---------------------------------------------------------------------------
%%  打印纪律的正面演示：同一批浮点，换算成整数厘米后打印
%% ---------------------------------------------------------------------------

demo_step4 :-
    say("---- 4. 执行层的打印纪律：坐标绝不直接打印浮点 ----"),
    say("  pi 直接打印：SWI 给 3.141592653589793，GNU 给 3.1415926535897931 ——"),
    say("  所以 write_metres 一律 round 成整数厘米再手工拼小数点："),
    format("  8.660254031861399     → ", []), write_metres(8.660254031861399), say(""),
    format("  -0.5                  → ", []), write_metres(-0.5), say("（负号单独补，不是 // 出来的）"),
    format("  0                     → ", []), write_metres(0), say(""),
    format("  8.060000000000001     → ", []), write_metres(8.060000000000001), say("（补零：不是 8.6）"),
    format("  1.7763568394002505e-15 → ", []), write_metres(1.7763568394002505e-15), say("（浮点尘埃抹成 0.00）").

%% ---------------------------------------------------------------------------
%%  演示
%% ---------------------------------------------------------------------------

script_main([
    "TURN 30 degrees clockwise",
    "forward 10 metres",
    "back 10 metres",
    "turn round",
    "goto 3 north 4 east",
    "FACE 70 degrees",
    "bback 6 metres",                       % 拼错的动词：白名单拒绝
    "turn 90 degrees anticlockwise",
    "report",
    "",                                     % 空行：跳过
    "stop"
]).

script_repeat([
    "turn left",                            % 90 + 90 = 180：正西
    "forward 5 metres",                     % 朝西走：东向变负数（负号打印的试金石）
    "report",
    "stop"
]).

demo_repl :-
    say("---- 5. REPL：同一份命令语言，两种主循环 ----"),
    say("主循环 = 递归穿脚本（纯版）："),
    initialise,
    report,
    script_main(S),
    run_script(S),
    say(""),
    say("主循环 = repeat + 动态库队列（对照版，行为一致）："),
    initialise,
    retractall(line_queue(_)),
    script_repeat(S2),
    forall(member(L, S2), assertz(line_queue(L))),
    run_script_repeat.

%% ---------------------------------------------------------------------------
%%  入口
%% ---------------------------------------------------------------------------

main :-
    (   catch(run, E, (format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   format(user_error, "*** run/0 失败~n", []),
        halt(1)
    ).

run :-
    format("==== 26 开始 ====~n", []),
    say("四步流水线：字符 → 单词 → 项 → 白名单 → call。"),
    say(""),

    demo_step1, say(""),
    demo_step2, say(""),
    demo_step3, say(""),
    demo_step4, say(""),
    demo_repl,  say(""),

    format("==== 26 结束 ====~n", []).
