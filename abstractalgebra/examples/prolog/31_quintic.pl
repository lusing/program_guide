:- encoding(utf8).
% 第 31 章 · 一般五次方程的不可解性 —— Prolog 通道
%
% 置换机器：符号同态、<5-循环,换位> = S₅、A₅ 的共轭类算术（单性）、
% F₂₀ 的可解证书（正规 C₅ + 陪集分解）。

% ---------- 置换基础设施（列表形 [σ(1),…,σ(5)]） ----------
% compose(σ, τ, σ∘τ)：(σ∘τ)(i) = σ(τ(i))
compose(Sigma, Tau, Rho) :- compose_at(Tau, Sigma, Rho).
compose_at([], _, []).
compose_at([T|Ts], Sigma, [R|Rs]) :- nth1(T, Sigma, R), compose_at(Ts, Sigma, Rs).

inverse(G, Gi) :-
    length(G, N), numlist(1, N, Is),
    maplist(slot(G), Is, Gi).
slot(G, I, V) :- nth1(V, G, I).

% 奇偶性：逆序数计数，+1 偶 / −1 奇
parity(P, Sg) :-
    inversions(P, 0, C),
    Sg is 1 - 2 * (C mod 2).
inversions([], A, A).
inversions([P|Ps], A0, A) :-
    inv_head(P, Ps, A0, A1), inversions(Ps, A1, A).
inv_head(_, [], A, A).
inv_head(P, [Q|Qs], A0, A) :-
    (P > Q -> A1 is A0 + 1 ; A1 = A0),
    inv_head(P, Qs, A1, A).

conj(G, S, X) :- inverse(G, Gi), compose(G, S, H), compose(H, Gi, X).

% 闭包：乘法封闭的极小扩张（排序去重后比较到不动点）
close_set(S0, S) :-
    findall(P, (member(A, S0), member(B, S0), compose(A, B, P)), Ps),
    append(S0, Ps, C0), sort(C0, S1),
    (S1 == S0 -> S = S0 ; close_set(S1, S)).

% 3-循环判定：恰两个不动点 + 三点成环
is_3cycle(P) :-
    between(1, 5, I), nth1(I, P, J), J =\= I,
    nth1(J, P, K), K =\= I, K =\= J,
    nth1(K, P, I),
    findall(F, nth1(F, P, F), Fs), length(Fs, 2).

% A₅ 的共轭类（按 A₅ 内元素共轭）
conj_class(Group, S, Class) :-
    findall(X, (member(M, Group), conj(M, S, X)), C0),
    sort(C0, Class).

classes_loop([], _, Acc, Acc).
classes_loop([S|Ss], Group, Acc0, Acc) :-
    (member(C, Acc0), memberchk(S, C)
    -> classes_loop(Ss, Group, Acc0, Acc)
    ;  conj_class(Group, S, C), classes_loop(Ss, Group, [C|Acc0], Acc)).

% 子多重集枚举（类大小 [12,12,15,20] 的 16 种并）
selections([], []).
selections([A|As], S) :- selections(As, S0), (S = [A|S0] ; S = S0).

% 左陪集分解
cosets(_, [], []).
cosets(Sub, [R|Es0], [C|Cs]) :-
    findall(X, (member(S, Sub), compose(S, R, X)), C),
    sort(C, C0),
    subtract(Es0, C0, Es1),
    cosets(Sub, Es1, Cs).

even_perm(P) :- parity(P, 1).

% x⁵ − 6x + 3 求值
f_quintic(X, V) :- V is X*X*X*X*X - 6*X + 3.
f_sign(X, S) :- f_quintic(X, V), S is sign(V).

% ---------- 主流程 ----------
main :-
    format("==== 31 一般五次方程的不可解性~n"),

    % 全部 120 个置换与奇偶分解
    findall(P, permutation([1,2,3,4,5], P), S5all0),
    sort(S5all0, S5all),
    length(S5all, 120),
    include(even_perm, S5all, A5),
    length(A5, 60),
    format("S₅ 与 A₅：120 个置换全部生成，其中 60 个偶置换 ✓~n"),

    % 符号同态：sgn(σ∘τ) = sgn(σ)·sgn(τ)（120 × 120 全核对）
    forall((member(S, S5all), member(T, S5all)),
           (compose(S, T, ST), parity(ST, PS),
            parity(S, PU), parity(T, PV), PS =:= PU * PV)),
    format("符号同态：sgn(στ) = sgn(σ)sgn(τ) 在 14400 对置换上成立 ✓~n"),

    % 不可约 ⟹ 群传递（含 5-循环）；恰两非实根 ⟹ 复共轭给出换位；
    % 二者生成 S₅ —— x⁵−6x+3 伽罗瓦群的骨架
    close_set([[1,2,3,4,5], [2,3,4,5,1], [2,1,3,4,5]], Gen),
    length(Gen, 120),
    Gen == S5all,
    format("<5-循环, 换位> = S₅：闭包枚举恰好 120 个元素 ✓~n"),

    % 3-循环：20 个、全部偶、生成 A₅
    findall(P, (member(P, A5), is_3cycle(P)), C3d0),
    sort(C3d0, C3), length(C3, 20),
    forall(member(P, C3), parity(P, 1)),
    close_set(C3, A5gen),
    length(A5gen, 60),
    format("3-循环：20 个全在 A₅ 内，闭包生成整个 A₅（60 元）✓~n"),

    % A₅ 的共轭类算术：类大小 [1,12,12,15,20]，无类并给出 60 的真因子
    classes_loop(A5, A5, [], Classes0),
    maplist(length, Classes0, Sizes0),
    msort(Sizes0, Sizes),
    Sizes = [1, 12, 12, 15, 20],
    sum_list(Sizes, 60),
    forall((selections([12, 12, 15, 20], Sub), sum_list(Sub, S0), N is S0 + 1),
           ((N = 1 ; N = 60 ; 60 mod N =\= 0))),
    format("A₅ 单性：类大小 {1,12,12,15,20} 的 16 种并除 {1,60} 外均不整除 60 ✓~n"),

    % x⁵−6x+3：Eisenstein(p=3) + 五点符号表恰三实根
    6 mod 3 =:= 0, 1 mod 3 =\= 0, 3 mod 9 =\= 0,
    maplist(f_sign, [-2, -1, 0, 1, 2], [-1, 1, 1, -1, 1]),
    C2 is (6.0/5.0) ** 0.25,
    D is 5*C2*C2*C2*C2 - 6,
    abs(D) < 1e-9,
    format("x⁵−6x+3：Eisenstein(p=3) 成立 + 五点符号表恰三实根 ✓~n"),

    % 对照 x⁵−2：Eisenstein(p=2) + F₂₀ 可解证书
    2 mod 2 =:= 0, 1 mod 2 =\= 0, 2 mod 4 =\= 0,
    close_set([[1,2,3,4,5], [2,3,4,5,1], [1,3,5,2,4]], F20),
    length(F20, 20),
    close_set([[2,3,4,5,1]], C5), length(C5, 5),
    forall(member(G, F20), (conj(G, [2,3,4,5,1], X), memberchk(X, C5))),
    cosets(C5, F20, Fc), length(Fc, 4),
    maplist(length, Fc, [5,5,5,5]),
    format("F₂₀ 证书：20 元闭包、C₅ = <5-循环> 正规（共轭封闭）、4 陪集分解 ✓~n"),
    format("可解链 1 ⊂ C₅ ⊂ F₂₀ 的商 ℤ/5、ℤ/4 均交换 —— 与 S₅ 的断裂相对照~n"),

    format("END ====~n").
