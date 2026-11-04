:- encoding(utf8).
% 第 10 章 · 子群与拉格朗日定理 —— Prolog 通道
%
% 子群枚举（回溯天然优势）+ 陪集分解 + 拉格朗日核验。

% ---------- 群件（同 09 章口径） ----------
elem(z6, X) :- between(1, 6, X).
op(z6, X, Y, Z) :- A is X - 1, B is Y - 1, C is (A + B) mod 6, Z is C + 1.

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

order(G, X, N) :- identity(G, E), order_(G, X, E, 1, N).
order_(_, E, E, K, K) :- !.
order_(G, X, E, K0, N) :- op(G, X, E, Next), K1 is K0 + 1, order_(G, X, Next, K1, N).

pow(G, X, 0, E) :- !, identity(G, E).
pow(G, X, K, P) :- K1 is K - 1, pow(G, X, K1, P0), op(G, X, P0, P).

% ---------- 子群与陪集 ----------
is_subgroup(G, H) :-
    H \= [],
    forall((member(X, H), member(Y, H), op(G, X, Y, Z)), member(Z, H)).

all_subgroups(G, Hs) :-
    findall(X, elem(G, X), Xs),
    findall(H, (sublists(Xs, H), is_subgroup(G, H)), Hs0),
    maplist(sort, Hs0, S0),
    sort(S0, Hs).

sublists([], []).
sublists([X | Xs], H) :- sublists(Xs, H0), (H = [X | H0] ; H = H0).

left_coset(G, H, A, B) :-
    findall(P, (member(Hi, H), op(G, A, Hi, P)), B).

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

lagrange(G, H) :-
    is_subgroup(G, H),
    coset_blocks(G, H, Blocks),
    length(Blocks, Idx),
    length(H, Ord),
    findall(X, elem(G, X), Xs),
    length(Xs, N),
    N =:= Idx * Ord.

lagrange_all(G) :-
    all_subgroups(G, Hs),
    forall(member(H, Hs), lagrange(G, H)).

main :-
    format("==== 10 子群与拉格朗日定理~n"),

    all_subgroups(z6, Hz6),
    length(Hz6, N6), N6 == 4,
    format("ℤ₆ 子群恰 ~d 个 = 因子个数（命题 2.73：每因子恰一个）✓~n", [N6]),

    all_subgroups(d3, Hd3),
    length(Hd3, N3), N3 == 6,
    format("D₃ ≅ S₃ 子群恰 ~d 个（阶谱 1,2,2,2,3,6）✓~n", [N3]),

    lagrange_all(z6), lagrange_all(d3),
    format("拉格朗日定理：ℤ₆ 与 D₃ 的全部子群通过陪集分解核验 ✓~n"),

    forall((member(G, [z6, d3]), elem(G, X)),
           (findall(Xs, elem(G, Xs), All), length(All, N),
            order(G, X, K), N mod K =:= 0,
            pow(G, X, N, E), identity(G, E))),
    format("推论 2.83/2.86：元素阶 | 群阶，x^|G| = 1 ✓~n"),

    all_subgroups(z6, Hz6),
    maplist(length, Hz6, Lens),
    msort(Lens, [1, 2, 3, 6]),
    format("注：ℤ₆ 子群阶谱 = {1,2,3,6}，每因子恰一个（命题 2.73）✓~n"),

    format("END ====~n").
