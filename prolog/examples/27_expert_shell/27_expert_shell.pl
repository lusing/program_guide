%% ============================================================================
%%  27_expert_shell.pl —— 实战：专家系统外壳（测验生成器）
%%
%%  对照 Bramer《Logic Programming with Prolog》13.2：
%%  不写死任何一个测验，而是写一个「外壳」—— 引擎与内容分离：
%%
%%    setup 阶段：把数据文件（一串 Prolog 项）读进动态库，变成事实
%%                title/1、question/3、range/3
%%    运行阶段：自动生成答题对话，计分，按评分表给反馈
%%
%%  数据文件（项序列，用户看不见）：
%%
%%      '标题'.
%%      '题目'. '答案'. 分数. '答案'. 分数. end.
%%      ...
%%      endquestions.
%%      下限. 上限. '反馈'.  ...  endmarkscheme.
%%
%%  外壳的通用性纪律：不假设题数、不假设每题答案数、不假设满分 ——
%%  全部从数据派生（每题满分 = 该题答案分数的最大值，不写进数据文件）。
%%
%%  与原书的三处不同：
%%    1. 用户答题没有键盘（stdin 是 /dev/null）：答案做成脚本，由动态库
%%       队列伺服 —— 与 26 章同一个模式。
%%    2. 原书 repeat+read 循环遇到截尾文件会死循环（read 在 EOF 之后永远
%%       给 end_of_file）：所有读循环都加了 EOF 护栏（25 章）。
%%    3. 中文题库照样过两套引擎（UTF-8 字节进、字节出）。
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

say(S) :- format("~s~n", [S]).

%% 外壳的全部状态都是动态谓词
:- dynamic(title/1).
:- dynamic(question/3).     % question(题面, [ans(答案, 分数)...], 该题满分)
:- dynamic(range/3).        % range(下限, 上限, 反馈)
:- dynamic(myscore/2).      % myscore(当前总分, 当前累计满分)
:- dynamic(answer_queue/1). % 用户答题脚本（26 章的队列模式）

%% ---------------------------------------------------------------------------
%%  数据文件：两份题库 + 一份截尾的（演示 EOF 护栏）
%% ---------------------------------------------------------------------------

%% 项结束符「.」后面必须跟空白：Earth.20 里的 .20 会被词法分析器
%% 吃成浮点字面量，整个文件直接语法错误（14/16 章的老朋友）。
tw(T) :- writeq(T), write('. ').   % 写一个项 + 结束符 + 空白
tn(N) :- write(N), write('. ').    % 数字项同理

write_quiz1(File) :-
    tell(File),
    tw('Are you a genius? Answer our quiz and find out!'), nl,
    tw('What is the name of this planet?'), nl,
    tw('Earth'), tn(20), tw('The Moon'), tn(5), tw('John'), tn(0), tw(end), nl,
    tw('What is the capital of Great Britain?'), nl,
    tw('America'), tn(0), tw('Paris'), tn(6), tw('London'), tn(50),
    tw('Moscow'), tn(4), tw(end), nl,
    tw('In which country will you find the Sydney Opera House?'), nl,
    tw('London'), tn(5), tw('Toronto'), tn(4), tw('The Moon'), tn(2),
    tw('Australia'), tn(10), tw('Germany'), tn(8), tw(end), nl,
    tw(endquestions), nl,
    tn(0), tn(20), tw('You are definitely not a genius'), nl,
    tn(21), tn(60), tw('You need to do some more reading'), nl,
    tn(61), tn(80), tw('You are a genius!'), nl,
    tw(endmarkscheme),
    told.

%% 第二份题库：题数不同、每题答案数不同、中文 —— 检验外壳不挑数据
write_quiz2(File) :-
    tell(File),
    tw('两题小测：答对有奖'), nl,
    tw('2 + 2 等于几？'), nl,
    tw('三'), tn(0), tw('4'), tn(10), tw('5'), tn(2), tw(end), nl,
    tw('Prolog 的首字母是？'), nl,
    tw('P'), tn(10), tw('Q'), tn(0), tw('R'), tn(3), tw(end), nl,
    tw(endquestions), nl,
    tn(0), tn(9), tw('再练练'), nl,
    tn(10), tn(19), tw('不错'), nl,
    tn(20), tn(20), tw('满分！边界分正好落在最后一段'), nl,
    tw(endmarkscheme),
    told.

%% 截尾题库：写了题面和答案表，但 endquestions 和后面的评分表全丢了
write_quiz_truncated(File) :-
    tell(File),
    tw('被截断的题库'), nl,
    tw('Only one question, no sentinel'), nl,
    tw('A'), tn(1), tw(end),
    told.

%% ---------------------------------------------------------------------------
%%  setup 阶段：数据文件 → 事实
%% ---------------------------------------------------------------------------

setup(File) :-
    retractall(title(_)),
    retractall(question(_, _, _)),
    retractall(range(_, _, _)),
    see(File),
    read(Title),
    assertz(title(Title)),
    readqs,
    readranges,
    seen.

%% 题目循环：读到 endquestions 收尾；EOF 护栏防截尾死循环
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

proc_question(Qtext) :-
    proc_answers([], AnsList, -9999, Max),   % -9999：比一切分数都小的哨兵初值
    assertz(question(Qtext, AnsList, Max)).

%% 逐对读「答案. 分数.」直到 end。每题答案不过个位数，append 可读性优先
%%（26 章的 O(n²) 教训在长输入才要紧）。
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

%% 评分表循环：三件套（下限. 上限. 反馈.）直到 endmarkscheme
readranges :-
    repeat,
        read(First),
        (   First == endmarkscheme
        ->  !
        ;   First == end_of_file
        ->  say("  【护栏】EOF 先到，评分表被截尾，止损退出"), !
        ;   read(Last),
            read(Feedback),
            assertz(range(First, Last, Feedback)),
            fail
        ).

%% ---------------------------------------------------------------------------
%%  运行阶段：失败驱动出题 + 动态库计分
%% ---------------------------------------------------------------------------

runquiz :-
    retractall(myscore(_, _)),
    assertz(myscore(0, 0)),
    title(T),
    format("~w~n", [T]),
    askq.

%% 25 章的两子句技巧：第一条用 fail 把 question/3 的解全部轮一遍，
%% 第二条收尾。副作用不回溯（17.2）—— 循环里 bump 攒的分不会丢。
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

ask_and_score(Qtext, AnsList, Max) :-
    ans_texts(AnsList, Ts),
    format("~w~n  可选答案：~w~n", [Qtext, Ts]),
    ask_until(AnsList, Award),
    format("  本题得 ~w / ~w~n", [Award, Max]),
    bump(Award, Max).

%% until 循环（25 章）：弹脚本答案，无效就重弹，直到是本题的合法答案。
%% 队列空 = 脚本用尽：砍掉 repeat 整体失败（出口纪律）。
ask_until(AnsList, Award) :-
    repeat,
    (   answer_queue(_)
    ->  true
    ;   !, fail
    ),
    once(retract(answer_queue(A))),
    (   member(ans(A, Award), AnsList)
    ->  !                               % 有效：砍掉 repeat，Award 已由 member 绑定
    ;   format("  “~w”不是有效答案，再答一次~n", [A]),
        fail
    ).

%% 17.3 读改写三件套：可变变量就靠这一个事实
bump(Award, Max) :-
    once(retract(myscore(S, M))),
    S1 is S + Award,
    M1 is M + Max,
    assertz(myscore(S1, M1)).

ans_texts([], []).
ans_texts([ans(A, _) | Rest], [A | Ts]) :- ans_texts(Rest, Ts).

load_answers([]).
load_answers([A | As]) :- assertz(answer_queue(A)), load_answers(As).

%% ---------------------------------------------------------------------------
%%  演示
%% ---------------------------------------------------------------------------

demo_setup :-
    say("---- 1. setup：数据文件 → 动态库事实 ----"),
    write_quiz1('/tmp/prolog_tutorial_27_quiz1.txt'),
    setup('/tmp/prolog_tutorial_27_quiz1.txt'),
    findall(Q, question(Q, _, _), Qs),
    length(Qs, N),
    format("  题库 1 读入 ~w 道题~n", [N]),
    forall(question(Q, Anss, Max),
           (   ans_texts(Anss, Ts),
               length(Ts, K),
               format("    ~w：~w 个答案，满分 ~w~n", [Q, K, Max])
           )),
    findall(Lo-Hi, range(Lo, Hi, _), Rs),
    format("  评分表区间：~w~n", [Rs]),
    say("  （每题满分从答案分数里派生，不写进数据文件 —— 单一事实来源。）").

demo_run1 :-
    say("---- 2. 运行：答题脚本（含一次无效重答）----"),
    retractall(answer_queue(_)),
    load_answers(['Mars', 'The Moon', 'London', 'Australia']),
    runquiz.

demo_run2 :-
    say("---- 3. 换一份题库：中文、题数不同、边界分 ----"),
    write_quiz2('/tmp/prolog_tutorial_27_quiz2.txt'),
    setup('/tmp/prolog_tutorial_27_quiz2.txt'),
    retractall(answer_queue(_)),
    load_answers(['六', '4', 'P']),
    runquiz.

demo_truncated :-
    say("---- 4. 截尾题库：EOF 护栏 ----"),
    write_quiz_truncated('/tmp/prolog_tutorial_27_quiz_truncated.txt'),
    setup('/tmp/prolog_tutorial_27_quiz_truncated.txt'),
    findall(Q, question(Q, _, _), Qs),
    length(Qs, N),
    format("  截尾后库里剩 ~w 道题（护栏让它活着回来，而不是死循环）~n", [N]).

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
    format("==== 27 开始 ====~n", []),
    say("外壳 = 与内容无关的引擎；内容 = 数据文件里的项序列。"),
    say(""),

    demo_setup,     say(""),
    demo_run1,      say(""),
    demo_run2,      say(""),
    demo_truncated, say(""),

    format("==== 27 结束 ====~n", []).
