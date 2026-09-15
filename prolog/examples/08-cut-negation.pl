% ============================================================
%  08-cut-negation.pl —— 剪枝（!）、条件与「否定即失败」
%
%  运行（SWI）: swipl -q -f examples/08-cut-negation.pl -g main -t halt
%  运行（GNU）: gprolog --consult-file examples/08-cut-negation.pl --entry-goal main
%
%  ! 是 Prolog 里唯一一个「不是纯逻辑」的控制结构，
%  用好了是剪枝提速，用坏了就是静默丢解。
% ============================================================

:- set_prolog_flag(double_quotes, codes).

% ------------------------------------------------------------
%  一、没有 ! 会怎样：同一个查询给出多个解
% ------------------------------------------------------------
classify_age_naive(Age, child)  :- Age < 13.
classify_age_naive(Age, teen)   :- Age >= 13, Age < 20.
classify_age_naive(Age, adult)  :- Age >= 20.

% 加了 ! 之后：命中第一条就停
classify_age(Age, child) :- Age < 13, !.
classify_age(Age, teen)  :- Age >= 13, Age < 20, !.
classify_age(_,   adult).

demo_naive_vs_cut :-
    format("---- 有 ! 和没 ! 的区别 ----~n", []),
    findall(C1, classify_age_naive(8, C1), All1),
    format("  classify_age_naive(8, X)  -> ~w（三条都试，只有一条成立）~n", [All1]),
    findall(C2, classify_age(8, C2), All2),
    format("  classify_age(8, X)        -> ~w（命中即停）~n", [All2]),
    format("  关键区别在「回溯」：如果后面还有目标失败，~n", []),
    format("  朴素版会回来试下一条子句，带 ! 的版本直接放弃整个谓词。~n", []).

% ------------------------------------------------------------
%  二、if-then-else：( Cond -> Then ; Else )
%     等价于「Cond, !, Then ; Else」，但更易读，且只剪 Cond 内部
% ------------------------------------------------------------
max_of(X, Y, M) :- ( X >= Y -> M = X ; M = Y ).
sign_of(N, S) :- ( N > 0 -> S = positive ; N < 0 -> S = negative ; S = zero ).

demo_ite :-
    format("---- if-then-else ----~n", []),
    max_of(3, 7, M1), format("  max_of(3,7)   -> ~w~n", [M1]),
    max_of(9, 2, M2), format("  max_of(9,2)   -> ~w~n", [M2]),
    forall(member(N, [5, -5, 0]),
           ( sign_of(N, S), format("  sign_of(~w)    -> ~w~n", [N, S]) )),
    format("  注意：-> 会把条件里的选择点全部剪掉，只取第一个解。~n", []),
    findall(X1, (member(X1, [1,2,3]) -> true ; true), Only1),
    length(Only1, NOnly),
    format("  ( member(X,[1,2,3]) -> true ; true ) 的解个数：~w~n", [NOnly]).

% ------------------------------------------------------------
%  三、否定即失败：\+ Goal
%     含义不是「Goal 为假」，而是「无法证明 Goal 为真」
% ------------------------------------------------------------
likes(mary, wine).
likes(mary, food).
likes(john, food).

demo_negation :-
    format("---- \\+ （否定即失败）----~n", []),
    ( \+ likes(mary, beer) -> format("  \\+ likes(mary,beer)  -> 真（事实库里没有）~n", []) ; true ),
    ( \+ likes(mary, wine) -> true ; format("  \\+ likes(mary,wine)  -> 假（事实库里有）~n", []) ),
    % 经典陷阱：变量未绑定时的 \+ 含义完全不同
    findall(P, (member(P, [mary, john]), \+ likes(P, wine)), NonWine),
    format("  不喜欢 wine 的人（P 已绑定）：~w~n", [NonWine]),
    format("  写成 \\+ likes(Who, wine) 且 Who 未绑定时，意思是~n", []),
    format("  「不存在任何人喜欢 wine」——完全不同的一件事。~n", []),
    ( \+ \+ likes(mary, wine) -> format("  \\+ \\+ G 是常用惯用法：探测 G 是否可证，且不绑定变量~n", []) ; true ).

% ------------------------------------------------------------
%  四、once/1 与「确定性」
% ------------------------------------------------------------
demo_once :-
    format("---- once/1 ----~n", []),
    findall(X-_, once(member(X, [1,2,3])), One),
    format("  once(member(X,[1,2,3])) -> ~w（只要第一个解）~n", [One]),
    findall(Y-_, member(Y, [1,2,3]), Many),
    format("  member(X,[1,2,3])      -> ~w（三个解）~n", [Many]),
    format("  once/1 比 \\+ \\+ 更直观，也比写在子句里的 ! 更安全。~n", []).

% ------------------------------------------------------------
%  五、红切与绿切
%     绿切（green cut）：只剪掉「明知无解」的分支，不改变语义
%     红切（red cut）  ：改变了逻辑含义，删掉它结果就变了
% ------------------------------------------------------------
% 绿切示例：最后一个子句不需要再判断，因为前面都失败了
grade_green(S, a) :- S >= 90, !.
grade_green(S, b) :- S >= 80, !.
grade_green(S, c) :- S >= 70, !.
grade_green(_,  f).

% 红切示例：这里的 ! 承担了「否则」的语义，删掉就错
grade_red(S, G) :- S >= 90, !, G = a.
grade_red(_,  f).

demo_cut_color :-
    format("---- 绿切 vs 红切 ----~n", []),
    forall(member(S, [95, 85, 75, 50]),
           ( grade_green(S, G1), grade_red(S, G2),
             format("  ~w 分 -> 绿切 ~w，红切 ~w~n", [S, G1, G2]) )),
    format("  绿切删掉后结果不变，只是多试几次；红切删掉后 95 分会同时得到 a 和 f。~n", []),
    format("  经验：只在「互斥条件」上用切；需要 else 语义时用 -> ; 更清楚。~n", []).

% ------------------------------------------------------------
%  六、! 的作用范围（一个真实踩坑点）
% ------------------------------------------------------------
% 错误示范：! 在辅助谓词里，会剪掉调用方的选择点吗？不会 ——
% ! 只影响它所在的那个谓词。
outer(X) :- inner(X).
inner(X) :- member(X, [1,2,3]).

outer_cut(X) :- inner_cut(X).
inner_cut(X) :- member(X, [1,2,3]), !.

demo_scope :-
    format("---- ! 只作用于所在谓词 ----~n", []),
    findall(A, outer(A), LA), format("  outer(X)     所有解：~w~n", [LA]),
    findall(B, outer_cut(B), LB), format("  outer_cut(X) 所有解：~w~n", [LB]),
    format("  inner_cut 里的 ! 只剪掉了 member 的选择点，~n", []),
    format("  outer_cut 本身仍然只有一个解（因为它只有一个子句）。~n", []),
    format("  真正的坑：把 ! 写在被 maplist/findall 调用的目标里，~n", []),
    format("  「剪枝」会局限在那个小目标内部，外面的回溯照常发生。~n", []).

run :-
    format("==== 08  剪枝、条件与否定即失败 ====~n", []), nl,
    demo_naive_vs_cut, nl,
    demo_ite,          nl,
    demo_negation,     nl,
    demo_once,         nl,
    demo_cut_color,    nl,
    demo_scope.

main :-
    (   catch((run, nl, format("==== 08 结束 ====~n", [])),
              E, (nl, format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   nl, format(user_error, "*** 08 运行失败~n", []), halt(1)
    ).
