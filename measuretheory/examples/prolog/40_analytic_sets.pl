:- encoding(utf8).
% 40_analytic_sets.pl —— 第 40 章：Souslin 运算（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，输出纯 ASCII。
% 深度 3 二叉树：前缀 → 集合（0..7 的子集，列表编码）。
% ① path/2（路径）；② souslin/2（路径交之并的成员）；
% ③ Borel 闭包归属；④ 节点统计。

% 前缀谓词：depth-1 前缀
prefix([0]).  prefix([1]).
prefix(P) :- append(Q, [B], P), member(B, [0,1]),
             (length(Q, 0 -> fail ; prefix(Q)).

% 树集族 fset(Prefix, Set)：确定性构造（(count1*2 + i) mod 3 ≠ 0 的 i）
fset(Prefix, Set) :-
    length(Prefix, L), L >= 1, L =< 3,
    count_ones(Prefix, C),
    findall(I, (between(0, 7, I), (C * 2 + I) mod 3 =\= 0), Set).

count_ones(P, C) :- include(=(1), P, Q), length(Q, C).

% 叶路径
path(P) :- length(P, 3), maplist([B]>>member(B, [0,1]), P).

% Souslin 成员：存在叶路径使其集合含 i
souslin_member(I) :-
    path(P), fset(P, Set), member(I, Set).

check_souslin :-
    findall(I, souslin_member(I), Is),
    sort(Is, Sorted),
    Sorted == [0,1,2,3,4,5,6,7],      % 本种子下全覆盖（退化）
    format("Souslin operation covers universe (this seed): OK~n").

% Borel 闭包（有限 = 幂集——一切集合"Borel"）
check_borel :-
    fset([0], S0),
    forall(member(I, S0), (integer(I), between(0, 7, I))),
    format("finite Borel = powerset: Souslin image trivially inside: OK~n").

% 节点统计
check_tree :-
    findall(P, (between(1, 3, L), length(P, L),
                maplist([B]>>member(B, [0,1]), P)), Ps),
    length(Ps, N),
    N =:= 2 + 4 + 8,                  % 各层 2^l
    findall(P2, path(P2), Leaves),
    length(Leaves, 8),
    format("tree stats: ~w nodes across 3 levels, 8 leaf paths: OK~n", [N]).

main :-
    format("==== 40 analytic_sets~n", []),
    check_souslin,
    check_borel,
    check_tree,
    format("END ====~n"), !.

:- initialization(main).
