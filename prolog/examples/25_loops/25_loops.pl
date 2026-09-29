%% ============================================================================
%%  25_loops.pl —— 循环的三种写法：定数 / 条件 / 失败驱动
%%
%%  Prolog 没有循环语句。但「把一段目标重复执行」的需求一个不少，
%%  全部由三种形态覆盖（对照 Bramer《Logic Programming with Prolog》第 6 章）：
%%
%%    1. 定数循环（for）        —— 递归倒数，或 between/3
%%    2. 条件循环（until）      —— 递归 + 析构，或 repeat + !
%%    3. 失败驱动循环（foreach）—— 生成器 + 副作用 + fail
%%
%%  06 章见过失败驱动、09 章见过递归、17 章见过 repeat+assert+!；
%%  本章把它们并排放着对照，并给出「什么时候用哪种」的判据。
%%
%%  交互循环（书上从键盘 read）在本教程的批处理验证下没有键盘 ——
%%  stdin 是 /dev/null（get_code 一上来就是 -1，read 一上来就是 end_of_file）。
%%  所以本章展示可测试循环的标准做法：把输入做成「脚本」，
%%  纯版用列表穿参（09 章累加器思路），带状态版用动态库当队列。
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

say(S) :- format("~s~n", [S]).

%% ---------------------------------------------------------------------------
%%  一、定数循环：「for i = 1..N」
%% ---------------------------------------------------------------------------

%% 倒数递归：第二个子句读作「要 loop(N)：做 N 号的事，然后 loop(N-1)」；
%% 第一个子句是终止条件。注意必须 M is N-1 —— 写 loop(N-1) 传的是项 -(N,1)！
loop(0).
loop(N) :- N > 0, format("  倒数第 ~w 轮~n", [N]), M is N - 1, loop(M).

%% 区间递归：从 First 打到 Last（含两端），终止条件是两个参数相等。
output_values(Last, Last) :- !, format("  ~w（终点）~n", [Last]).
output_values(First, Last) :-
    format("  ~w~n", [First]),
    N is First + 1,
    output_values(N, Last).

%% between/3 是两套引擎都有的内建生成器（实测 SWI 9 / GNU 1.5 均可用），
%% 一行顶上面两段。但它只会升序：between(3,1,X) 一个解都没有。
squares_upto(N, Ss) :- findall(S, (between(1, N, I), S is I * I), Ss).

%% 「1..N 求和」：把过程式的「累加」重新表述成自指的声明 ——
%% 前 N 项的和 = 前 N-1 项的和 + N。递归定义比循环变量更贴近数学。
sumto(1, 1) :- !.
sumto(N, S) :- N > 1, N1 is N - 1, sumto(N1, S1), S is S1 + N.

demo_fixed :-
    say("---- 1. 定数循环（for）：倒数 / 区间 / between ----"),
    say("倒数递归 loop(3)："),
    loop(3),
    say("区间递归 output_values(5,8)："),
    output_values(5, 8),
    squares_upto(6, Ss),
    format("between(1,6,I) 配合 I*I   = ~w~n", [Ss]),
    findall(N, between(3, 1, N), Ns),
    format("between(3,1,N) 倒着要    = ~w（升序生成器，倒序是空）~n", [Ns]),
    sumto(100, S),
    format("sumto(100) 声明式求和    = ~w~n", [S]),
    say(""),
    say("  最大的坑：loop(N-1) 不求值 —— N-1 是项，不是 4-1=3。"),
    say("  write_canonical 眼见为实，6-1 的标准形是："),
    write_canonical(6 - 1),
    say(""),
    say("  （必须先 M is N-1 换出新变量，再拿 M 去递归。）").

%% ---------------------------------------------------------------------------
%%  二、条件循环：「until」
%% ---------------------------------------------------------------------------

%% until 循环的纯写法：递归 + 析构。脚本（答案列表）当参数穿进去，
%% 每轮消费一个，有效就停，无效就带着剩下的继续问。
%% 这就是「可测试的交互循环」：IO 全推到边缘，核心是纯的。
get_answer(Script, Answer) :-
    say("条件循环（纯递归版）：脚本 = [maybe,possibly,yes]，只认 yes/no"),
    get_answer_(Script, Answer).

get_answer_([A | Rest], Answer) :-
    format("  尝试回答 ~w ...~n", [A]),
    (   valid_answer(A)
    ->  Answer = A
    ;   get_answer_(Rest, Answer)
    ).

valid_answer(yes).
valid_answer(no).

%% 同一个循环的 repeat 版：答案脚本放进动态库当队列。
%% repeat 永远成功（制造无限选择点）→ 弹一条 → 有效就 ! 砍掉选择点收场，
%% 无效就 fail 回溯到 repeat 再来。
%% 【出口纪律】repeat 循环必须给自己留出口：队列为空就 ! + fail 整体失败，
%% 否则队列耗尽后 repeat ↔ retract 之间会无限空转（17.3 同款教训）。
:- dynamic(answer_queue/1).

ask_until_valid(Answer) :-
    repeat,
    (   answer_queue(_)
    ->  true
    ;   !, fail                       % 队列空了：砍掉 repeat，整体失败
    ),
    once(retract(answer_queue(A))),   % 只弹一条（retract 有选择点，12/17 章）
    (   valid_answer(A)
    ->  !, Answer = A                 % 有效：砍掉 repeat 的选择点，循环结束
    ;   format("  ~w 无效，回到 repeat 再来~n", [A]),
        fail                          % 无效：退回 repeat 重来
    ).

%% 菜单程序：书上 6.3.2 的菜单用 repeat，这里用更直白的尾递归 ——
%% 处理完一个选项就带着剩余脚本调自己；收到 d 不再递归，循环自然结束。
%% 子句顺序当 switch 用（03/10 章），最后一条兜底「请重选」。
menu(Script) :-
    say("菜单循环：脚本 = [b,xxx,d]（b 正常项、xxx 非法项、d 退出）"),
    menu_(Script).

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
menu_([]) :- say("  脚本用尽，菜单收摊。").

menu_action(a) :- !, say("  → 选了 A").
menu_action(b) :- !, say("  → 选了 B").
menu_action(c) :- !, say("  → 选了 C").
menu_action(_) :- fail.          %% 不认识的选项：整体失败 → 走「请重选」

%% until 循环跑在文件上：书上的 readterms —— 重复 read 直到哨兵 end。
%% 【关键护栏】read 在 EOF 之后永远给 end_of_file：文件要是被截了尾、
%% 哨兵 end 丢了，repeat 循环会永远吃 end_of_file —— 死循环。
%% 所以循环条件必须同时查两个哨兵。
readterms(File) :-
    tell(File),
    write(first), write('.'), write(' '),
    write(second), write('.'), write(' '),
    write(third), write('.'), write(' '),
    write(end), write('.'),
    told,
    see(File),
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

readterms_truncated(File) :-
    tell(File),
    write(first), write('.'), write(' '),
    write(second), write('.'),
    told,
    see(File),
    repeat,
        read(X),
        (   X == end
        ->  say("  读到哨兵 end"), !
        ;   X == end_of_file
        ->  say("  【护栏】EOF 先到，哨兵没来 —— 没有这条就是死循环"), !
        ;   format("  读到项 ~w，继续~n", [X]),
            fail
        ),
    seen.

demo_until :-
    say("---- 2. 条件循环（until）：问到有效为止 ----"),
    get_answer([maybe, possibly, yes], A1),
    format("  纯递归版最终采纳     = ~w~n", [A1]),
    retractall(answer_queue(_)),
    assertz(answer_queue(unsure)),
    assertz(answer_queue(possibly)),
    assertz(answer_queue(no)),
    ask_until_valid(A2),
    format("  repeat 版最终采纳    = ~w~n", [A2]),
    say(""),
    menu([b, xxx, d]),
    say(""),
    say("文件上的 until 循环（完整文件）："),
    readterms('/tmp/prolog_tutorial_25_terms.txt'),
    say("文件上的 until 循环（截尾文件，故意不写哨兵）："),
    readterms_truncated('/tmp/prolog_tutorial_25_truncated.txt').

%% ---------------------------------------------------------------------------
%%  三、失败驱动循环：「foreach」
%% ---------------------------------------------------------------------------

dog(fido).
dog(fred).
dog(jonathan).

person(john, smith, 45, london, doctor).
person(martin, williams, 33, birmingham, teacher).
person(henry, smith, 26, manchester, plumber).
person(jane, wilson, 62, london, teacher).
person(mary, smith, 29, glasgow, surveyor).

%% 经典两子句：第一条用 fail 逼 dog(X) 把所有解轮一遍；
%% 第二条空体事实负责「最后整体成功」—— 少了它整个目标以 false 收场。
alldogs :-
    dog(X),
    format("  ~w is a dog~n", [X]),
    fail.
alldogs.

%% 反面教材：只有一条子句。三条狗照样都打出来，但目标整体失败。
alldogs_bad :-
    dog(X),
    format("  ~w is a dog~n", [X]),
    fail.

allteachers :-
    person(First, Sur, _, _, teacher),
    format("  老师：~w ~w~n", [First, Sur]),
    fail.
allteachers.

demo_foreach :-
    say("---- 3. 失败驱动循环（foreach）：fail 逼出所有解 ----"),
    alldogs,
    (   alldogs_bad
    ->  say("  alldogs_bad 成功？")
    ;   say("  alldogs_bad（少第二条子句）：逐条照打，整体却 false")
    ),
    allteachers,
    findall(F - S, person(F, S, _, _, teacher), Ts),
    format("  findall 等价收集      = ~w~n", [Ts]),
    findall(D, dog(D), Ds),
    length(Ds, N),
    format("  失败驱动没建表，但用 findall 数得出来：~w 条 dog~n", [N]),
    (   forall(member(_E, []), fail)
    ->  say("  forall(member(_,[]), fail) = true（空集上恒真，当存在量词用会错）")
    ;   say("  forall 空集竟然失败")
    ).

%% ---------------------------------------------------------------------------
%%  四、判据：什么时候用哪种
%% ---------------------------------------------------------------------------

demo_criteria :-
    say("---- 4. 选择判据 ----"),
    say("  已知次数        → between/3（内建）；要倒序/自定义步长用倒数递归"),
    say("  直到条件成立    → 递归 + 析构（纯、可测试）；repeat+! 只在状态必须进动态库时"),
    say("  遍历所有解      → 失败驱动（不建表、省内存）或 findall（要列表结果）"),
    say("  「对每个都成立」 → forall/2（注意空集恒真）"),
    say("  记住：副作用不回溯（17 章）—— 失败驱动循环里 assertz 攒下的东西不会丢。").

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
    format("==== 25 开始 ====~n", []),
    say("循环不是语法，是三种控制流的形态：递归、回溯、生成器。"),
    say(""),

    demo_fixed,    say(""),
    demo_until,    say(""),
    demo_foreach,  say(""),
    demo_criteria, say(""),

    format("==== 25 结束 ====~n", []).
