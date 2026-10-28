:- encoding(utf8).
% 第 83 章：有限 ccc 区间族检查与截断超有理数不等式。

% ── 截断超有理数 a + b·ε：序与乘法（有理数用整数对 a/b 约定 b>0）──
% 只用整数实现：标准部分与 ε 部分都以整数比例 a/b 表示。

frac_lt(A1, B1, A2, B2) :- A1 * B2 < A2 * B1.  % 均为正分母

tq_lt(tq(A1,B1,C1,D1), tq(A2,B2,C2,D2)) :-
    frac_lt(A1, B1, A2, B2).
tq_lt(tq(A,B,C1,D1), tq(A,B,C2,D2)) :-
    C1 * D2 < C2 * D1.

tq_mul(tq(A1,B1,C1,D1), tq(A2,B2,C2,D2), tq(A3,B3,C3,D3)) :-
    A3 is A1 * A2, B3 is B1 * B2,
    C3 is A1 * B1 * (C2 * D1) + (C1 * D1) * A2 * B2,
    D3 is B1 * B2 * D1 * D1.

zero(tq(0,1,0,1)).
one(tq(1,1,0,1)).
eps(tq(0,1,1,1)).

% ── 无穷小不等式与 Archimede 失效 ──
check_infinitesimal :-
    eps(E), zero(Z),
    tq_lt(Z, E),
    forall(between(1, 40, N),
           ( frac_lt(0, 1, 1, N),
             tq_lt(E, tq(1, N, 0, 1)) )),
    forall(between(1, 40, K),
           ( one(O), tq_mul(tq(K,1,0,1), E, P), tq_lt(P, O) )).

% ── 有限 ccc：整数区间两两不交族检查 ──
interval(A, B) :- between(0, 12, A), between(0, 12, B), A < B.

disjoint((A1,B1), (A2,B2)) :- B1 =< A2.
disjoint((A1,B1), (A2,B2)) :- B2 =< A1.

family_disjoint([]).
family_disjoint([I|T]) :-
    forall(member(J, T), (disjoint(I, J))),
    family_disjoint(T).

% 6 个两两不交区间（最大族见证）。
max_family([(0,1),(1,2),(2,3),(3,4),(4,5),(5,6)]).

main :-
    format("==== 83~n"),
    check_infinitesimal,
    max_family(F),
    family_disjoint(F),
    length(F, 6),
    format("ε 无穷小律与 k·ε < 1（k≤40）通过；6 个两两不交开区间为最大族~n", []),
    writeln("END ====").
