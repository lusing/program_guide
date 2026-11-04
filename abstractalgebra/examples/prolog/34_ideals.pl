:- encoding(utf8).
% 第 34 章 · 素理想与极大理想 —— Prolog 通道
%
% ℤ/n 的理想格（除数对应）+ 素/极大判别（商环整域/域暴力枚举）。

% ℤ/n 是整域：无非平凡零因子（1 ≤ a, b < n 时 ab mod n ≠ 0）
zn_domain(N) :-
    N > 1,
    N1 is N - 1,
    \+ (between(1, N1, A), between(1, N1, B),
        A * B mod N =:= 0).

% ℤ/n 是域：非零元均可逆
zn_field(N) :-
    zn_domain(N),
    N1 is N - 1,
    forall(between(1, N1, A),
           (between(1, N1, B), A * B mod N =:= 1)).

% ℤ/n 的理想 (d) 的元素集
zn_ideal_elems(N, D, Elems) :-
    findall(E, (between(0, N, K), E is (D * K) mod N, E \= N), E0),
    sort([0 | E0], Elems).

main :-
    format("==== 34 素理想与极大理想~n"),

    % ℤ/12：理想 ↔ 因数；(a) ⊇ (b) ⟺ a | b
    forall((between(1, 12, A), between(1, 12, B),
            12 mod A =:= 0, 12 mod B =:= 0),
           (zn_ideal_elems(12, A, EA), zn_ideal_elems(12, B, EB),
            (subset(EB, EA) -> B mod A =:= 0 ; B mod A =\= 0))),
    format("ℤ/12：6 理想 ↔ 因数；(a) ⊇ (b) ⟺ a | b ✓~n"),

    % ℤ/n 扫描：域 ⟺ 素 ⟺ 整域（引理 7.6 的数值面）
    forall(between(2, 20, N),
           (prime(N) -> zn_field(N), zn_domain(N)
            ; \+ zn_field(N), \+ zn_domain(N))),
    format("ℤ/n 扫描 2..20：域 ⟺ 素 ⟺ 整域 ✓~n"),

    % 极大 ⟹ 素（推论 7.8）：(p) ⊂ ℤ/p² 素（ab ∈ (p) ⟹ a 或 b ∈ (p)）
    forall(member(P, [2, 3, 5]),
           (P2 is P * P,
            forall((between(0, P2, A), between(0, P2, B)),
                   ((A * B) mod P =:= 0
                    -> (A mod P =:= 0 ; B mod P =:= 0)
                    ;  true)))),
    format("(p) ⊂ ℤ/p²（p=2,3,5）：素理想（极大 ⟹ 素）✓~n"),

    % GF(4) = ℤ/2[x]/(x²+x+1)：元素 c0+c1ω，ω² = ω+1
    findall([A, B], (between(0, 1, A), between(0, 1, B)), GF4),
    length(GF4, 4),
    % 乘法封闭
    forall((member(X, GF4), member(YV, GF4)),
           (gf4_mul(X, YV, Z), member(Z, GF4))),
    % 非零元可逆
    forall((member([A, B], GF4), \+ (A = 0, B = 0)),
           (member([C, D], GF4), gf4_mul([A, B], [C, D], [1, 0]))),
    format("GF(4)：乘法封闭（ω² = ω+1）、非零元可逆 ✓~n"),

    format("END ====~n").

prime(N) :-
    N >= 2,
    N1 is N - 1,
    \+ (between(2, N1, D), N mod D =:= 0).

% GF(4) 乘法：(a + bω)(c + dω) = ac + (ad+bc)ω + bdω²，ω² = ω+1
gf4_mul([A, B], [C, D], [X, Y]) :-
    X is (A * C + B * D) mod 2,
    Y is (A * D + B * C + B * D) mod 2.
