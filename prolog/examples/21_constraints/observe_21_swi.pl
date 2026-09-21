%% ============================================================================
%%  observe_21_swi.pl —— 观察通道（只在 SWI-Prolog 上跑）
%%
%%  正文 21_constraints.pl 是【可移植子集】：只用 domain/3、labeling/1、
%%  alldiff/1 三个适配谓词，逼着两套引擎输出逐字节一致。
%%
%%  这个文件反过来，专门看 SWI 的原生能力。它不参与区间比对，
%%  只要求「跑到底、不往 stderr 写东西」。
%%
%%  看什么：
%%    1. 域的原生语法 in/2 与 ins/2
%%    2. 未标号的约束变量打印成什么样（以及为什么不能进正文）
%%    3. labeling/2 的选项：枚举顺序、首次失败、最优化
%%    4. 全局约束 all_distinct/1、element/3、sum/3
%%    5. 具体化（reification）：把约束变成 0/1 值
%%    6. 反面清单：SWI 没有 GNU 那套 fd_* 名字
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

:- use_module(library(clpfd)).

say(S) :- format("~s~n", [S]).

main :-
    (   catch(run, E, (format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   format(user_error, "*** run/0 失败~n", []),
        halt(1)
    ).

run :-
    format("==== 21 观察 开始 ====~n", []),
    say("观察通道 · SWI-Prolog · library(clpfd) 的原生写法"),
    say("（本文件只在一个引擎上跑，所以不追求跨引擎一致，只看原生能力）"),
    say(""),

    say("--- 1. 域的原生语法：in/2 与 ins/2 ---"),
    (   X in 1..9, X #> 5
    ->  format("    X in 1..9, X #> 5 声明完了。此时 write(X) 打出：~w~n", [X])
    ;   say("    失败")
    ),
    say("    那串 _ 开头的编号是 SWI【属性变量】的打印形式，每次运行都不同，"),
    say("    所以它绝不能出现在正文示例的输出里 —— 这是本章第 ① 条规矩。"),
    (   length(Vs, 4), Vs ins 1..4, label(Vs)
    ->  format("    ins 能批量声明域，label/1 给出首解：Vs ins 1..4 → ~w~n", [Vs])
    ;   say("    失败")
    ),
    say(""),

    say("--- 2. labeling(选项, 变量)：枚举顺序可以指定 ---"),
    findall(Y, (Y in 1..5, labeling([up], [Y])), LUp),
    format("    labeling([up],   ...) → ~w~n", [LUp]),
    findall(Y2, (Y2 in 1..5, labeling([down], [Y2])), LDown),
    format("    labeling([down], ...) → ~w~n", [LDown]),
    findall(Y3, (Y3 in 1..5, labeling([ff], [Y3])), LFf),
    format("    labeling([ff],   ...) → ~w~n", [LFf]),
    say("    [ff] 是 first-fail（先挑值域最小的变量）。GNU 的内建 fd 没有"),
    say("    这套选项接口，所以正文里两边都只用最基础的单参数标号。"),
    say(""),

    say("--- 3. 最优化：直接把目标写进 labeling 的选项 ---"),
    (   Z in 0..30, K in 0..10, Z #= 3 * K, Z #< 30,
        labeling([max(Z)], [Z, K])
    ->  format("    小于 30 的最大 3 的倍数：Z = ~w（K = ~w）~n", [Z, K])
    ;   say("    失败")
    ),
    (   Z2 in 0..30, K2 in 0..10, Z2 #= 3 * K2,
        labeling([min(Z2)], [Z2, K2])
    ->  format("    最小的 3 的倍数：Z = ~w（K = ~w）~n", [Z2, K2])
    ;   say("    失败")
    ),
    say("    对比一下：GNU 那侧用的是 fd_maximize/2 与 fd_minimize/2，"),
    say("    完全不同的接口。这也是为什么正文不做最优化 —— 没有公共写法。"),
    say(""),

    say("--- 4. 全局约束：all_distinct / element / sum ---"),
    (   length(Ws, 4), Ws ins 1..4, all_distinct(Ws), label(Ws)
    ->  format("    all_distinct([W1,W2,W3,W4]) 首解 → ~w~n", [Ws])
    ;   say("    失败")
    ),
    (   element(3, [10, 20, 30], E)
    ->  format("    element(3, [10, 20, 30], E) → E = ~w~n", [E])
    ;   say("    失败")
    ),
    (   [A,B,C] ins 1..9, sum([A,B,C], #=, 10), label([A,B,C])
    ->  format("    sum([A,B,C], #=, 10) 首解 → ~w~n", [[A,B,C]])
    ;   say("    失败")
    ),
    say("    all_distinct 比 all_different 更强（多了更好的传播算法）；"),
    say("    正文用的是 all_different，因为它是两边都有的那个名字。"),
    say(""),

    say("--- 5. 具体化：把约束变成 0/1 值，再用逻辑联结词组合 ---"),
    (   (5 #= 3) #<==> B, label([B])
    ->  format("    (5 #= 3) #<==> B      → B = ~w~n", [B])
    ;   say("    失败")
    ),
    (   P in 0..1, Q in 0..1, P #==> Q, P #= 1, label([P, Q])
    ->  format("    P #==> Q 且 P = 1     → Q = ~w~n", [Q])
    ;   say("    失败")
    ),
    (   R in 0..1, S in 0..1, R + S #= 1, R #= 0, label([R, S])
    ->  format("    R + S = 1 且 R = 0    → S = ~w~n", [S])
    ;   say("    失败")
    ),
    say("    GNU 的内建 fd 里没有 #<==> / #==> 这类具体化运算符，"),
    say("    所以正文里「要么是 0 要么是 1」只能用 R + S #= 1 这种算术写法。"),
    say(""),

    say("--- 6. 反面清单：SWI 没有 GNU 那套 fd_* 名字 ---"),
    (   catch(fd_domain(1, 1, 2), _, fail)
    ->  say("    fd_domain/3        存在")
    ;   say("    fd_domain/3        不存在（那是 GNU 的名字）")
    ),
    (   catch(fd_labeling([]), _, fail)
    ->  say("    fd_labeling/1      存在")
    ;   say("    fd_labeling/1      不存在（那是 GNU 的名字）")
    ),
    (   catch(fd_all_different([]), _, fail)
    ->  say("    fd_all_different/1 存在")
    ;   say("    fd_all_different/1 不存在（那是 GNU 的名字）")
    ),
    say("    所以正文那层适配不是洁癖，是必须的。"),
    say(""),

    format("==== 21 观察 结束 ====~n", []).
