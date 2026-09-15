% ============================================================
%  17-constraints.pl —— 约束求解（CLP(FD) / GNU FD）
%
%  运行（SWI）: swipl -q -f examples/17-constraints.pl -g main -t halt
%  运行（GNU）: gprolog --consult-file examples/17-constraints.pl --entry-goal main
%
%  两个引擎都有有限域约束求解，但 API 完全不同：
%    SWI ：library(clpfd)，X in 1..9、all_different/1、labeling/2
%    GNU ：内建 fd_* 系列，fd_domain/3、fd_all_different/1、fd_labeling/1
%  本例用条件编译把两边统一成同一组接口。
% ============================================================

:- set_prolog_flag(double_quotes, codes).

% GNU Prolog 的 :- if 只跳过编译，读文件时仍然要能解析语法。
% 所以这里先声明 SWI clpfd 用到的两个运算符，避免 GNU 读到
% "Vars ins Lo..Hi" 时直接语法错误。（这些子句在 GNU 上会被 :- if 丢掉）
:- op(700, xfx, ins).
:- op(500, xfx, ..).

:- if(current_prolog_flag(dialect, swi)).
:- use_module(library(clpfd)).

domain_vars(Vars, Lo, Hi) :- Vars ins Lo..Hi.
all_diff(Vars)            :- all_different(Vars).
label_vars(Vars)          :- labeling([], Vars).
label_ff(Vars)            :- labeling([ff], Vars).
:- else.

domain_vars(Vars, Lo, Hi) :- fd_domain(Vars, Lo, Hi).
all_diff(Vars)            :- fd_all_different(Vars).
label_vars(Vars)          :- fd_labeling(Vars).
label_ff(Vars)            :- fd_labeling(Vars).
:- endif.

% ------------------------------------------------------------
%  一、热身：A + B + C = 15，三个数互不相同，都在 1..9
% ------------------------------------------------------------
demo_warmup :-
    format("---- 热身：A+B+C=15 ----~n", []),
    Vars = [A, B, C],
    domain_vars(Vars, 1, 9),
    all_diff(Vars),
    A + B + C #= 15,
    findall(Vars, label_vars(Vars), Sols),
    length(Sols, N),
    format("  共 ~w 组解，前三组：~n", [N]),
    ( append(First, _, Sols), length(First, 3) -> true ; First = Sols ),
    forall(member(S, First), format("    ~w~n", [S])).

% ------------------------------------------------------------
%  二、N 皇后：约束版
%     皇后放在 (列, 行)，每行一个，用行号列表表示
% ------------------------------------------------------------
queens(N, Qs) :-
    length(Qs, N),
    domain_vars(Qs, 1, N),
    all_diff(Qs),
    safe_diagonals(Qs),
    label_ff(Qs).

safe_diagonals([]).
safe_diagonals([Q | Qs]) :-
    safe_diagonals(Qs, Q, 1),
    safe_diagonals(Qs).

safe_diagonals([], _, _).
safe_diagonals([Q1 | Qs], Q0, D) :-
    Q0 - Q1 #\= D,
    Q1 - Q0 #\= D,
    D1 is D + 1,
    safe_diagonals(Qs, Q0, D1).

demo_queens :-
    format("---- N 皇后（约束版）----~n", []),
    forall(member(N, [4, 5, 6]),
           ( findall(Q, queens(N, Q), Sols),
             length(Sols, Cnt),
             format("  ~w 皇后：~w 组解~n", [N, Cnt]) )),
    ( queens(6, Q6) -> format("  6 皇后的第一组解：~w~n", [Q6]) ; true ),
    ( queens(4, Q4) -> format("  4 皇后的第一组解：~w~n", [Q4]) ; true ).

% ------------------------------------------------------------
%  三、对照：不用约束，纯 generate-and-test
% ------------------------------------------------------------
% 真正完整的朴素版：检查任意两行都不同行、不同对角线
queens_naive(N, Qs) :-
    numlist2(1, N, Rows),
    permutation(Rows, Qs),
    \+ ( nth1(I, Qs, Qi), nth1(J, Qs, Qj), I < J,
         ( Qi =:= Qj ; abs_diff(Qi, Qj, D), D =:= J - I ) ).

abs_diff(A, B, D) :- ( A > B -> D is A - B ; D is B - A ).

numlist2(Lo, Hi, []) :- Lo > Hi, !.
numlist2(Lo, Hi, [Lo | Rest]) :- Lo1 is Lo + 1, numlist2(Lo1, Hi, Rest).

demo_plain :-
    format("---- 对照：朴素 generate-and-test ----~n", []),
    forall(member(N, [4, 5, 6]),
           ( findall(Q, queens_naive(N, Q), Sols),
             length(Sols, Cnt),
             format("  ~w 皇后：~w 组解（与约束版一致）~n", [N, Cnt]) )),
    format("  差别：朴素版是「先全排列再筛」，约束版是「边传播边剪枝」。~n", []),
    format("  规模越大差距越明显（8 皇后以上朴素版会明显变慢）。~n", []).

% ------------------------------------------------------------
%  四、约束编程的核心思路
% ------------------------------------------------------------
demo_idea :-
    format("---- 约束求解在干什么 ----~n", []),
    format("  1) 声明变量和值域（domain）~n", []),
    format("  2) 加约束：约束本身不求解，只是不断「缩小值域」~n", []),
    format("  3) 枚举（labeling）：在缩小后的值域里做搜索~n", []),
    format("  顺序很重要：先把约束都加完再 labeling，效率天差地别。~n", []),
    format("  因为每加一条约束都会剪掉一批候选，越早剪越省事。~n", []).

% ------------------------------------------------------------
%  五、双引擎差异
% ------------------------------------------------------------
demo_portability :-
    format("---- 双引擎差异 ----~n", []),
    (   current_prolog_flag(dialect, swi)
    ->  format("  SWI：library(clpfd) 功能非常全，~n", []),
        format("       in/ins、#=/#\\=/#</#>/#\\/#\\/、all_different、sum、~n", []),
        format("       element、global_cardinality、cumulative、automaton...~n", []),
        format("       labeling 还能选 ff/leftmost/min/max 等策略~n", [])
    ;   format("  GNU：内建 fd_* 系列，~n", []),
        format("       fd_domain/2,3、fd_all_different/1、fd_element/3、~n", []),
        format("       fd_labeling/1,2、fd_atmost/3、fd_exactly/3 ...~n", []),
        format("       没有全局约束库，大型模型要自己传播~n", [])
    ),
    format("  两边都能用的运算符：#= #\\= #< #> #=< #>=（需要各自先声明变量域）~n", []),
    format("  注意：GNU 的 #= 要求变量已经用 fd_domain 声明过，否则就是普通 is。~n", []).

run :-
    format("==== 17  约束求解 ====~n", []), nl,
    demo_warmup,   nl,
    demo_queens,   nl,
    demo_plain,    nl,
    demo_idea,     nl,
    demo_portability.

main :-
    (   catch((run, nl, format("==== 17 结束 ====~n", [])),
              E, (nl, format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   nl, format(user_error, "*** 17 运行失败~n", []), halt(1)
    ).
