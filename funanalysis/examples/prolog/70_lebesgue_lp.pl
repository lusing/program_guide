:- encoding(utf8).
% 70_lebesgue_lp.pl —— 勒贝格积分与 L^p 的有限模型（docs/70 实验）
% 通道：SWI-Prolog（gprolog 兼容：format/2 带 []、main 尾部 !）
% 内容：Q 的桶排列编号、epsilon/2^n 覆盖总长、Cantor 测度递减、
%       可测集运算封闭性的规则推理
%
% 本文件是"测度论入门"的有限前缀模型：把无穷对象截断成可枚举事实，
% 规则本身就是定理的体现（可数集=可编号；零测=任意小总长覆盖）。

% ---------- 工具 ----------
gcd(A, 0, A) :- !.
gcd(0, B, B) :- !.
gcd(A, B, G) :- C is A mod B, gcd(B, C, G).

% 既约分数判据：gcd 算入变量后比较（避免把答案参数钉死在递归目标上）
coprime(A, Q) :- gcd(A, Q, G), G =:= 1.

% 书 1.4.4：Q 可数——按 N = |p| + q 桶排列（每个桶有限）
rationals_by_level(N, P, Q) :-
    between(0, N, M),
    Q is N - M, Q >= 1,
    P0 is -M,
    between(P0, M, P),
    A is abs(P),
    coprime(A, Q).

% 书 1.4.11：可数集零测——第 i 个点配半径 eps/2^i 的区间
% total_cover(Eps, M, S)：前 M 项的总长（浮点截断）
total_cover(Eps, M, S) :- total_cover_(M, Eps, 0.0, S).
total_cover_(0, _, Acc, Acc) :- !.
total_cover_(I, Eps, Acc, S) :-
    I > 0,
    Acc1 is Acc + Eps / 2.0 ** I,
    I1 is I - 1,
    total_cover_(I1, Eps, Acc1, S).

% ---------- 可测集代数（书 1.4.9：sigma 封闭的规则形态） ----------
measurable(open_interval).
measurable(closed_interval).
measurable(rationals).          % 可数集可测
measurable(cantor).             % 闭集可测
measurable(complement(E)) :- measurable(E).
measurable(union(E, F)) :- measurable(E), measurable(F).
measurable(inter(E, F)) :- measurable(E), measurable(F).

% 零测判定（书 1.4.10 的有限推理版）
zero_measure(finite_set).
zero_measure(countable_set).
zero_measure(E) :- zero_measure_subset(E).
zero_measure_subset(rationals).
zero_measure_subset(cantor).

% Cantor 测度：去掉部分 2^k·3^{-(k+1)} 的前缀和（书 1.4.13）
cantor_removed(0, 0.0) :- !.
cantor_removed(K, S) :-
    K > 0,
    K1 is K - 1,
    cantor_removed(K1, S0),
    S is S0 + (2.0 ** K1) / (3.0 ** K).

% ---------- 实验 ----------
main :-
    format("==== 70 lebesgue & Lp (finite model) ====", []),

    % 实验 1：Q 的桶排列——前 N 层枚举出的互异既约分数
    findall(p_q(P, Q), rationals_by_level(4, P, Q), Rats4),
    length(Rats4, L4),
    format("~nEXP1 rationals by |p|+q<=4 level pairs: ~d (e.g. ", [L4]),
    member(p_q(1, 2), Rats4),
    format("1/2 found), countable = enumerable", []),

    % 实验 2：epsilon/2^n 覆盖总长与点数无关
    total_cover(0.001, 30, S30),
    total_cover(0.001, 100, S100),
    S30 =< 0.001 + 1e-12,
    S100 =< 0.001 + 1e-12,
    format("~nEXP2 cover totals eps=0.001: M=30 -> ~6f, M=100 -> ~6f (both <= eps)", [S30, S100]),

    % 实验 3：可测集的 sigma 封闭性推理
    measurable(union(complement(cantor), inter(rationals, open_interval))),
    format("~nEXP3 sigma-algebra closure: complement(cantor) U (rationals n open) derivable measurable", []),

    % 实验 4：Cantor 前缀去除量
    cantor_removed(10, R10),
    cantor_removed(20, R20),
    Remain10 is 1.0 - R10,
    Remain20 is 1.0 - R20,
    Remain20 < Remain10,
    Remain20 < 0.001,
    format("~nEXP4 cantor remaining measure: step10 -> ~6f, step20 -> ~8f (-> 0)", [Remain10, Remain20]),

    format("~nEND ====", []), !.
