:- encoding(utf8).
% 第 108 章：可数支撑迭代的有限影子——积序相容、支撑拼接与稠密集相遇搜索。

% ── 一、坐标偏序（沿 107 章）与两步积序 ──
ext_of(0, [0,1,2]) :- !.
ext_of(1, [1]) :- !.
ext_of(2, [2]) :- !.
ext_of(_, []).

% 积序条件写作 a-b；延展集是分量延展的笛卡尔积。
ext2(A-B, ES) :- ext_of(A, EA), ext_of(B, EB), prodL(EA, EB, ES).

prodL([], _, []).
prodL([X|Xs], Ys, Z) :- prod1(X, Ys, Z1), prodL(Xs, Ys, Z2), append(Z1, Z2, Z).
prod1(_, [], []).
prod1(X, [Y|Ys], [X-Y|T]) :- prod1(X, Ys, T).

compat2(P, Q) :- ext2(P, EP), ext2(Q, EQ), member(S, EP), member(S, EQ).

univ2(A-B) :- member(A, [0,1,2]), member(B, [0,1,2]).

% 稠密：一切 p 有 d ∈ D 强于 p（d ∈ ext2(p)）。
dense2(D) :- forall(univ2(P), (member(X, D), ext2(P, EP), member(X, EP))).

% d ≤ p。
le2(P, Q) :- ext2(Q, EQ), member(P, EQ).

% RS 链：递归下降，逐个稠密集取更强条件。
rsi_chain([], P, [P]).
rsi_chain([D|Ds], P, [P|Rest]) :-
    member(X, D), le2(X, P),
    rsi_chain(Ds, X, Rest).

% 滤子：两两相容 + 向上闭。
filter2(F) :-
    forall((member(P,F), member(Q,F)), compat2(P,Q)),
    forall((member(P,F), univ2(Q), le2(P,Q)), member(Q,F)).

% ── 二、支撑限制与拼接 ──
drop(0, L, L).
drop(N, [_|T], R) :- N > 0, N1 is N-1, drop(N1, T, R).

glueq(Q, R, G) :- length(Q, N), drop(N, R, RT), append(Q, RT, G).

supp_([], _, []).
supp_([C|Cs], I, S) :- C =:= 0, !, I1 is I+1, supp_(Cs, I1, S).
supp_([_|Cs], I, [I|S]) :- I1 is I+1, supp_(Cs, I1, S).
supp(Q, S) :- supp_(Q, 0, S).

subsetL([], _).
subsetL([H|T], L) :- member(H, L), subsetL(T, L).

main :-
    format("==== 108~n"),
    % 积序相容正反（反链相乘 4=2×2 的样本）。
    compat2(1-1, 1-1),
    \+ compat2(1-1, 1-2),
    \+ compat2(1-2, 2-1),
    compat2(0-0, 1-2),
    % 稠密正反。
    D12 = [1-1, 1-2, 2-1, 2-2],
    D22 = [0-0, 1-1, 1-2, 2-1, 2-2],
    dense2(D12), dense2(D22),
    \+ dense2([0-0]),
    % RS 链 + 滤子 + 相遇（PFA 引擎影子）。
    rsi_chain([D12, D22], 0-0, Chain),
    last(Chain, P),
    findall(Q, (univ2(Q), le2(P, Q)), F),
    filter2(F),
    member(X1, F), member(X1, D12),
    member(X2, F), member(X2, D22),
    % 支撑拼接（有限影子）。
    glueq([0,1,0,2], [1,1,0,0,3], [0,1,0,2,3]),
    supp([0,1,0,2,3], [1,3,4]),
    supp([0,1,0,2], SQ), supp([1,1,0,0,3], SR),
    supp([0,1,0,2,3], SG),
    append(SQ, SR, SU), subsetL(SG, SU),   % 拼接支撑 ⊆ 两段支撑之并
    format("积序相容正反；RS 链遇两稠密集得相遇滤子；支撑拼接协调~n"),
    format("RS 链：~w~n滤子：~w~n", [Chain, F]),
    writeln("END ====").
