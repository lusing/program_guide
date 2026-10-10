:- encoding(utf8).
% ex46_categoricity.pl —— 完备理论与范畴性（Marker ch5）搜索面
%
% 与 Coq/Lean 通道（F_3^2 换基排列/x^3 有限域对账/0-1 律频率）互补，
% 这里跑组合搜索本体：
%   pairsn/edge —— n 点边表（I<J 字典序），图 = 边位整数编码；
%   no_isolated —— σ₁（无孤立点：扩张公理最简特例）判定；
%   count_cond  —— n=2..5 全枚举计数：频率分子 1/2, 4/8, 41/64,
%           768/1024（递增趋 1——0-1 律的数值脚印，三通道对账）；
%   exactly3 —— 「恰好 3 条边」分子 = C(m,3) → 0 的对照句子。

% ---------- 边表与位向量 ----------

medges(N, M) :- M is N * (N - 1) // 2.

% 有序边表：[(0-1),(0-2),…,(I-J),…] 字典序——第 K 位对应第 K 条边
pairsn(N, L) :-
    N1 is N - 1,
    findall(I-J, (between(0, N1, I), between(0, N1, J), I < J), L).

edge(N, Code, I, J) :-
    pairsn(N, L), nth0(K, L, I-J), Code /\ (1 << K) > 0.

% ---------- σ₁：无孤立点 ----------

has_neighbor(N, Code, I) :-
    N1 is N - 1, between(0, N1, J), I =\= J,
    edge(N, Code, I, J), !.
has_neighbor(N, Code, I) :-
    N1 is N - 1, between(0, N1, J), I =\= J,
    edge(N, Code, J, I), !.

no_isolated(N, Code) :-
    N1 is N - 1, numlist(0, N1, Vs),
    maplist(has_neighbor(N, Code), Vs).

% ---------- 计数 ----------

count_cond(N, Cond, C) :-
    medges(N, M), Limit is 1 << M,
    aggregate_all(count,
        (between(0, Limit, Code), Code < Limit, call(Cond, N, Code)),
        C).

frac_row(N) :-
    count_cond(N, no_isolated, Num),
    medges(N, M), Den is 1 << M,
    Frac is Num rdiv Den,
    format("no_isolated n=~d        : ~d/~d = ~4f~n", [N, Num, Den, Frac]).

bitcount(0, 0) :- !.
bitcount(X, C) :- X1 is X >> 1, B is X /\ 1, bitcount(X1, C1), C is C1 + B.

exactly3(_N, Code) :- bitcount(Code, 3).

% ---------- 主 ----------

main :-
    format("== 0-1 law: fraction of graphs with no isolated vertex ==~n"),
    forall(between(2, 5, N), frac_row(N)),
    forall(between(2, 5, N),
        ( count_cond(N, exactly3, C3), medges(N, M),
          format("exactly-3-edges n=~d      : ~d of 2^~d (-> 0)~n", [N, C3, M]) )),
    format("==== ex26 categoricity END ====~n").
