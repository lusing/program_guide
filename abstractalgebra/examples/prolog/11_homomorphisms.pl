:- encoding(utf8).
% 第 11 章 · 群同态 —— Prolog 通道
%
% 映射枚举 + 同态检查 + 核/像 + |G| = |ker|·|im|（ℤ₆ → ℤ₃ 与 S₃ → ℤ₂）。

% ---------- 群件 ----------
elem(z6, X) :- between(1, 6, X).
op(z6, X, Y, Z) :- A is X - 1, B is Y - 1, C is (A + B) mod 6, Z is C + 1.
elem(z3, X) :- between(1, 3, X).
op(z3, X, Y, Z) :- A is X - 1, B is Y - 1, C is (A + B) mod 3, Z is C + 1.
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

% ---------- 同态检查：f 以 (元素-像) 对列表给出 ----------
% 注意 forall(生成, 检验) 的参数位：条件必须放在检验位！
apply_map([], _, _) :- fail.
apply_map([X-Y | _], X, Y) :- !.
apply_map([_ | T], X, Y) :- apply_map(T, X, Y).

homomorphism(G, H, F) :-
    forall((elem(G, X), elem(G, Y)),
           (op(G, X, Y, XY),
            apply_map(F, X, FX), apply_map(F, Y, FY),
            op(H, FX, FY, FXY), apply_map(F, XY, FXY))).

% ---------- 枚举全部映射 ----------
all_maps(G, H, F) :-
    findall(X, elem(G, X), Xs),
    findall(Y, elem(H, Y), Ys),
    assignments(Xs, Ys, F).

assignments([], _, []).
assignments([X | Xs], Ys, [X-Y | Rest]) :-
    member(Y, Ys),
    assignments(Xs, Ys, Rest).

% 核与像
kernel(G, H, F, K) :-
    identity(H, EH),
    findall(X, (elem(G, X), apply_map(F, X, EH)), K).

image(G, H, F, I) :-
    findall(Y, (elem(G, X), apply_map(F, X, Y)), I0),
    sort(I0, I).

main :-
    format("==== 11 群同态~n"),

    % ℤ₆ → ℤ₃：枚举 3⁶ = 729 个映射，筛同态
    aggregate_all(count,
        (all_maps(z6, z3, F), homomorphism(z6, z3, F)), N613),
    N613 == 3,
    format("ℤ₆ → ℤ₃：729 个映射中同态恰 ~d 个（f(k) = ck mod 3）✓~n", [N613]),

    % 取 c = 1 的同态：核 {0, 3}、像全 ℤ₃、|G| = |ker|·|im|
    % （注意：findall 模板不做算术求值，须经 is 辅助谓词）
    findall(X-V, (elem(z6, X), V is (X - 1) mod 3 + 1), F61),
    homomorphism(z6, z3, F61),
    kernel(z6, z3, F61, K), sort(K, Ks), Ks == [1, 4],      % 剩余类 0 与 3
    image(z6, z3, F61, Im), length(Im, 3),
    length(Ks, NK), NK * 3 =:= 6,
    format("f(k) = k mod 3：核 = {[0],[3]}，像 = ℤ₃，6 = 2×3 ✓~n"),

    % S₃ → ℤ₂：枚举 2⁶ = 64 个映射，恰 2 个同态（平凡 + sgn）
    aggregate_all(count,
        (all_maps(d3, z2, F), homomorphism(d3, z2, F)), N312),
    N312 == 2,
    format("S₃ → ℤ₂：64 个映射中同态恰 ~d 个（平凡与 sgn）✓~n", [N312]),

    % sgn 的核 = A₃ = {1, α, α²}（编号 1, 2, 3）
    sgn_map(d3, Fsgn),
    homomorphism(d3, z2, Fsgn),
    kernel(d3, z2, Fsgn, KA), sort(KA, KAs), KAs == [1, 2, 3],
    format("sgn 的核 = A₃ = {1, α, α²}（恰 3 元，|S₃| = 3×2）✓~n"),

    % 引理 2.89：f(1) = 1 与 f(x⁻¹) = f(x)⁻¹（对 sgn 抽查）
    identity(d3, E1), apply_map(Fsgn, E1, E2), identity(z2, E2),

    format("END ====~n").

% sgn 映射：元素 1,2,3（偶）↦ 1；4,5,6（奇）↦ 2
sgn_map(d3, [1-1, 2-1, 3-1, 4-2, 5-2, 6-2]).
