:- encoding(utf8).
% 第 12 章 · 商群 —— Prolog 通道
%
% 正规性 + 良定义性检查 + 商表 + 表同构搜索（S₃/A₃ ≅ ℤ₂ 等）。

% ---------- 群件 ----------
elem(z12, X) :- between(1, 12, X).
op(z12, X, Y, Z) :- A is X - 1, B is Y - 1, C is (A + B) mod 12, Z is C + 1.
elem(z4, X) :- between(1, 4, X).
op(z4, X, Y, Z) :- A is X - 1, B is Y - 1, C is (A + B) mod 4, Z is C + 1.
elem(z2, X) :- between(1, 2, X).
op(z2, X, Y, Z) :- A is X - 1, B is Y - 1, C is (A + B) mod 2, Z is C + 1.

elem(d3, X) :- between(1, 6, X).
op(d3, X, Y, Z) :-
    split(X, I, J), split(Y, K, L),
    (J =:= 0 -> (R is (I + K) mod 3, S is L) ; (R is (I - K) mod 3, S is 1 - L)),
    join(R, S, Z).
split(X, I, J) :- X =< 3, !, I is X - 1, J = 0.
split(X, I, J) :- X > 3, !, I is X - 4, J = 1.
join(R, S, Z) :- S =:= 0, !, Z is R + 1.
join(R, S, Z) :- S =:= 1, Z is R + 3 + 1.

identity(G, E) :- elem(G, E),
    forall(elem(G, X), (op(G, E, X, X), op(G, X, E, X))).
inv(G, X, Y) :- identity(G, E), elem(G, Y), op(G, X, Y, E).

is_subgroup(G, H) :-
    H \= [],
    forall((member(X, H), member(Y, H), op(G, X, Y, Z)), member(Z, H)).

% ---------- 正规性：gKg⁻¹ = K ----------
is_normal(G, K) :-
    forall((elem(G, Gg), member(Kk, K), inv(G, Gg, Gi),
            op(G, Gg, Kk, GK), op(G, GK, Gi, Conj)),
           member(Conj, K)).

% ---------- 陪集与商表 ----------
left_coset(G, H, A, B) :-
    findall(P, (member(Hi, H), op(G, A, Hi, P)), B).

same_coset(G, K, A1, A2) :-
    left_coset(G, K, A1, C1), sort(C1, S1),
    left_coset(G, K, A2, C2), sort(C2, S2),
    S1 == S2.

% 良定义性：同一对陪集换代表元，乘积陪集不变
well_defined(G, K) :-
    forall((elem(G, A1), elem(G, A2), elem(G, B1), elem(G, B2),
            same_coset(G, K, A1, A2), same_coset(G, K, B1, B2),
            op(G, A1, B1, C1), op(G, A2, B2, C2)),
           same_coset(G, K, C1, C2)).

coset_blocks(G, H, Blocks) :-
    findall(X, elem(G, X), Xs),
    collect(G, H, Xs, [], [], Blocks).
collect(_, _, [], _, Acc, Blocks) :- reverse(Acc, Blocks).
collect(G, H, [A | As], Covered, Acc, Blocks) :-
    (   member(A, Covered) ->
        collect(G, H, As, Covered, Acc, Blocks)
    ;   left_coset(G, H, A, B0), sort(B0, B),
        append(B, Covered, Covered1),
        collect(G, H, As, Covered1, [B | Acc], Blocks)
    ).

% 商表：opq(Blocks, G, i, j, k)
quotient_op(G, K, Blocks, I, J, K2) :-
    nth1(I, Blocks, Bi), nth1(J, Blocks, Bj),
    Bi = [A | _], Bj = [B | _],
    op(G, A, B, C),
    (   nth1(K2, Blocks, Bk), member(C, Bk) -> true
    ).

main :-
    format("==== 12 商群~n"),

    % A₃ = {1, α, α²} 正规；⟨(12)⟩ 不正规（良定义性破产）
    is_normal(d3, [1, 2, 3]),
    \+ is_normal(d3, [1, 4]),
    well_defined(d3, [1, 2, 3]),
    \+ well_defined(d3, [1, 4]),
    format("S₃：A₃ 正规且乘法良定义；⟨(12)⟩ 两者皆破产 ✓~n"),

    % S₃/A₃ 商表 ≅ ℤ₂
    coset_blocks(d3, [1, 2, 3], BlocksA3),
    length(BlocksA3, 2),
    quotient_op(d3, [1, 2, 3], BlocksA3, 1, 2, Q12), Q12 == 2,
    quotient_op(d3, [1, 2, 3], BlocksA3, 2, 2, Q22), Q22 == 1,
    format("S₃/A₃ 商表（2 阶）：结构与 ℤ₂ 一致（[1][α] = [α]，[α][α] = [1]）✓~n"),

    % ℤ₁₂/⟨4⟩ 的商表 ≅ ℤ₄
    is_normal(z12, [1, 5, 9]),
    coset_blocks(z12, [1, 5, 9], BlocksZ),
    length(BlocksZ, 4),
    forall((between(1, 4, I), between(1, 4, J)),
           quotient_op(z12, [1, 5, 9], BlocksZ, I, J, _)),
    % 商的运算循环性：[2] 生成
    quotient_op(z12, [1, 5, 9], BlocksZ, 2, 2, Q2), Q2 == 3,
    quotient_op(z12, [1, 5, 9], BlocksZ, 3, 2, Q3), Q3 == 4,
    quotient_op(z12, [1, 5, 9], BlocksZ, 4, 2, Q4), Q4 == 1,
    format("ℤ₁₂/⟨4⟩：[2] 是 4 阶生成元（[2]²=[3],[2]³=[4],[2]⁴=[1]）⟹ ≅ ℤ₄ ✓~n"),

    format("END ====~n").
