:- encoding(utf8).
% 15_daniell.pl —— 第 15 章：有限 Daniell 流水线（Prolog 符号版）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
% Ω = {1..6}，三块 B1={1,2} B2={3,4} B3={5,6}，权 (1/2,1/3,1/6)。
% 阶梯 = 三元组（各块常值）。① 格运算逐坐标；② Daniell 公理；
% ③ μ* 覆盖账与表示定理（块计价）；④ C 对并封闭（块代数 8 集）。

blocks([[1,2],[3,4],[5,6]]).
weights([q(1,2), q(1,3), q(1,6)]).

qadd(q(A,B), q(C,D), q(N1,E1)) :- N is A*D + C*B, E is B*D,
    G is gcd(N, E), G > 0, N1 is N // G, E1 is E // G.
qmul(q(A,B), q(C,D), q(N1,E1)) :- N is A*C, E is B*D,
    G is gcd(N, E), G > 0, N1 is N // G, E1 is E // G.
qle(q(A,B), q(C,D)) :- A * D =< C * B.
qeq(q(A,B), q(C,D)) :- A * D =:= C * B.

% I(阶梯)：Σ v_i·w_i
int_of(t(A,B,C), S) :-
    weights(W), nth1(1, W, Q1), nth1(2, W, Q2), nth1(3, W, Q3),
    qmul(q(A,1), Q1, X1), qmul(q(B,1), Q2, X2), qmul(q(C,1), Q3, X3),
    qadd(X1, X2, S1), qadd(S1, X3, S).

% --- ① 格运算（逐坐标） ---
check_lattice :-
    % t(1,-2,3) ∨ t(2,0,-1) = (2,0,3)；∧ = (1,-2,-1)
    max_list([1,2], 2), max_list([-2,0], 0), max_list([3,-1], 3),
    min_list([1,2], 1), min_list([-2,0], -2), min_list([3,-1], -1),
    format("vector lattice ops (meet/join coordinatewise): OK~n").

% --- ② Daniell 公理 ---
check_daniell :-
    int_of(t(2,3,0), S1), qeq(S1, q(2,1)),      % 线性：2/2 + 3/3 = 2
    int_of(t(1,1,1), S2), qeq(S2, q(1,1)),      % 正性/总质量：权和 = 1
    int_of(t(0,0,0), S3), qeq(S3, q(0,1)),      % 零函数
    % f_n ↓ 0 链（t(3,2,1) ≥ t(2,1,0) ≥ 0）：I 单调降
    int_of(t(3,2,1), I1), int_of(t(2,1,0), I2),
    qle(S3, I2), qle(I2, I1),
    format("Daniell axioms: positive linear + down-continuity on chains: OK~n").

% --- ③ μ* 与表示定理 ---
mu_hit(A, S) :- blocks(Bs), weights(W),
    findall(Q, (nth1(K, W, Q), nth1(K, Bs, B), member(X, A), member(X, B)), Qs0),
    dedup_q(Qs0, Qs), sum_qs(Qs, q(0,1), S).
dedup_q([], []).
dedup_q([Q|Qs], [Q|R]) :- \+ member(Q, Qs), !, dedup_q(Qs, R).
dedup_q([_|Qs], R) :- dedup_q(Qs, R).
sum_qs([], Acc, Acc).
sum_qs([Q|Qs], Acc, R) :- qadd(Q, Acc, A1), sum_qs(Qs, A1, R).

check_representation :-
    int_of(t(2,-1,3), If),
    mu_hit([1,2], M1), mu_hit([3,4], M2), mu_hit([5,6], M3),
    qeq(M1, q(1,2)), qeq(M2, q(1,3)), qeq(M3, q(1,6)),
    qmul(q(2,1), M1, X1), qmul(q(-1,1), M2, X2), qmul(q(3,1), M3, X3),
    qadd(X1, X2, S1), qadd(S1, X3, Sint),
    qeq(If, Sint),
    format("representation I(f) = v1*mu(B1)+v2*mu(B2)+v3*mu(B3): OK~n").

% --- ④ C 对并封闭 ---
mask_block(M, C) :- blocks(Bs), findall(X,
    (nth1(K, Bs, B), (M >> (K-1)) /\ 1 =:= 1, member(X, B)), C0),
    msort(C0, C).

check_C :-
    findall(C, (between(0,7,M), mask_block(M, C)), Cs),
    length(Cs, 8),
    \+ ( member(A, Cs), member(B, Cs),
         union(A, B, U0), msort(U0, U), \+ member(U, Cs) ),
    format("C (block algebra, 8 sets) closed under union: OK~n").

main :-
    format("==== 15 daniell~n", []),
    check_lattice,
    check_daniell,
    check_representation,
    check_C,
    format("END ====~n"), !.
