:- encoding(utf8).
% 07_combinatorics.pl —— 第 07 章：高级组合（Prolog 穷举）
%
% ① Hockey-stick 的枚举现场：从 {0..6} 选 3 元子集按最大元
%    分类（Σ C(i,2) = C(7,3) = 35）；② 3 球 2 桶的 8 分配
%    全枚举 + 按桶 1 计数归并（多项式系数的现场）；
% ③ Vandermonde 玩具（m=3、n=2、k=2：10 = 1+6+3）。

combo(_, 0, []).
combo([X | Xs], K, [X | C]) :- K > 0, K1 is K - 1, combo(Xs, K1, C).
combo([_ | Xs], K, C) :- K > 0, combo(Xs, K, C).

% ① 0..6 的 3 元子集，按最大元 i 分类计数
check_hockey :-
    findall(S, combo([0,1,2,3,4,5,6], 3, S), Subs),
    length(Subs, 35),                         % C(7,3)
    findall(I-M, (between(2, 6, I),
                  findall(S, (member(S, Subs), max_list(S, I)), Ss),
                  length(Ss, M)), Counts),
    Counts = [2-1, 3-3, 4-6, 5-10, 6-15],    % C(i,2) 递增
    Total is 1 + 3 + 6 + 10 + 15,
    Total =:= 35,
    format("hockey-stick: max-class counts [1,3,6,10,15] sum to C(7,3)=35: OK~n").

% ② 3 球进 2 桶（球可辨、桶有序）：2^3 = 8 分配；桶 1 有 j 球
%    的分配数 = C(3,j)（多项式系数）
check_balls :-
    findall(A, (between(0,1,B1), between(0,1,B2), between(0,1,B3),
                A = [B1,B2,B3]), All),
    length(All, 8),
    findall(J-M, (between(0, 3, J),
                  findall(A, (member(A, All), count_ones(A, J)), As),
                  length(As, M)), Hist),
    Hist = [0-1, 1-3, 2-3, 3-1],
    format("3 balls 2 bins: bin-1 histogram [1,3,3,1] = C(3,j) row: OK~n").

count_ones(A, J) :- include(=(1), A, Ones), length(Ones, J).

% ③ Vandermonde m=3、n=2、k=2：3 人组选 j 个 × 2 人组选 2−j 个
check_vandermonde :-
    V is 1*1 + 3*2 + 3*1,
    V =:= 10,
    format("Vandermonde (3,2,2): 1*1 + 3*2 + 3*1 = 10 = C(5,2): OK~n").

main :-
    format("==== 07 combinatorics~n", []),
    check_hockey,
    check_balls,
    check_vandermonde,
    format("END ====~n"), !.

:- initialization(main).
