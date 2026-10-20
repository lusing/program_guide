:- encoding(utf8).
% 03_counting.pl —— 第 03 章：计数基础（Prolog 穷举通道）
%
% ① 4 物件的排列全枚举（4! = 24）与 4-选-2 组合全枚举
%    （C(4,2) = 6——保序选取 = 顺序去重的代码化）；
% ② Pascal 递推表（递推 vs 乘积公式）；③ 3 硬币样本空间。

perm([], []).
perm(L, [X | P]) :- select(X, L, R), perm(R, P).

% 保序组合枚举（自动去重：只生成递增位置序列）
combo(_, 0, []).
combo([X | Xs], K, [X | C]) :- K > 0, K1 is K - 1, combo(Xs, K1, C).
combo([_ | Xs], K, C) :- K > 0, combo(Xs, K, C).

check_perms :-
    findall(P, perm([1, 2, 3, 4], P), Ps),
    length(Ps, 24),
    format("4! = 24 permutations enumerated: OK~n").

check_combos :-
    findall(C, combo([1, 2, 3, 4], 2, C), Cs),
    length(Cs, 6),
    member([1, 2], Cs), member([3, 4], Cs),
    \+ member([2, 1], Cs),
    format("C(4,2) = 6 combinations, order canonical: OK~n").

fact(0, 1) :- !.
fact(N, F) :- N > 0, N1 is N - 1, fact(N1, G), F is N * G.

c_direct(N, K, C) :- fact(N, FN), fact(K, FK), NK is N - K,
    fact(NK, FNK), C is FN // (FK * FNK).

check_pascal :-
    forall((between(1, 8, N), between(0, N, K),
            Km is K - 1, N1 is N - 1,
            c_direct(N1, Km, A), c_direct(N1, K, B), c_direct(N, K, Cc),
            Cc =:= A + B),
           true),
    format("Pascal recurrence verified C(n,k)=C(n-1,k-1)+C(n-1,k), n<=8: OK~n").

check_coins :-
    findall([A, B, Cc], (member(A, [h, t]), member(B, [h, t]),
                         member(Cc, [h, t])), Ss),
    length(Ss, 8),
    include(count_heads_2, Ss, Sub),
    length(Sub, 3),
    format("coin space 8 outcomes, exactly-2-heads = 3 of 8: OK~n").

count_heads_2(S) :- include(=(h), S, Hs), length(Hs, 2).

main :-
    format("==== 03 counting~n", []),
    check_perms,
    check_combos,
    check_pascal,
    check_coins,
    format("END ====~n"), !.

:- initialization(main).
