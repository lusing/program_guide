:- encoding(utf8).
% 07_counting_lab.pl —— 第 07 章：生日、迷你扑克、桥牌与秘书问题。

perm([], []).
perm(L, [X | P]) :- select(X, L, R), perm(R, P).

fact(0, 1) :- !.
fact(N, F) :- N > 0, N1 is N - 1, fact(N1, G), F is N * G.

choose(N, K, C) :-
    fact(N, FN), fact(K, FK), NK is N - K, fact(NK, FNK),
    C is FN // (FK * FNK).

% ① 玩具生日：5 人、5 天，5^5=3125 种安排完全枚举。
birthday_assignment([D1, D2, D3, D4, D5]) :-
    between(1, 5, D1), between(1, 5, D2), between(1, 5, D3),
    between(1, 5, D4), between(1, 5, D5).
has_duplicate(Bs) :- length(Bs, N), sort(Bs, S), length(S, M), M < N.

check_birthday :-
    findall(B, birthday_assignment(B), All),
    length(All, 3125),
    include(has_duplicate, All, Dup),
    length(Dup, Coll),
    Prob is Coll rdiv 3125,
    Prob =:= 1 - 120 rdiv 3125,
    format("toy birthday 5 people/5 days: collision = 3005/3125 = 1-5!/5^5: OK~n").

% ② 迷你扑克：20 张牌（5 点 × 4 花），C(20,3)=1140 手全枚举。
deal3([card(R1,S1), card(R2,S2), card(R3,S3)]) :-
    between(1,5,R1), between(1,4,S1), Ix is (S1-1)*5+R1,
    between(1,5,R2), between(1,4,S2), Jx is (S2-1)*5+R2, Jx > Ix,
    between(1,5,R3), between(1,4,S3), Kx is (S3-1)*5+R3, Kx > Jx.

classify([card(R1,S1), card(R2,S2), card(R3,S3)], Type) :-
    msort([R1,R2,R3], Rs),
    ( S1 =:= S2, S2 =:= S3 -> Flush = true ; Flush = false ),
    ( consecutive(Rs) -> Straight = true ; Straight = false ),
    ( Flush, Straight -> Type = straight_flush
    ; Rs = [A,A,A] -> Type = three_kind
    ; Flush -> Type = flush
    ; Straight -> Type = straight
    ; pair_rank(Rs) -> Type = pair
    ; Type = nothing), !.

pair_rank([A,A,_]).
pair_rank([_,A,A]).
consecutive([A,B,C]) :- B =:= A+1, C =:= B+1.

count_types(Pairs) :-
    findall(T, (deal3(H), classify(H,T)), Types),
    sort(Types, Unique),
    findall(U-C, (member(U, Unique),
                  include(=(U), Types, Ts), length(Ts, C)), Pairs).

check_mini_poker :-
    count_types(Cts),
    memberchk(straight_flush-SF, Cts), SF =:= 12,
    memberchk(three_kind-Tk, Cts), Tk =:= 20,
    memberchk(flush-F, Cts), F =:= 28,
    memberchk(straight-St, Cts), St =:= 180,
    memberchk(pair-P, Cts), P =:= 480,
    memberchk(nothing-N, Cts), N =:= 420,
    SF + Tk + F + St + P + N =:= 1140,
    format("mini-poker C(20,3)=1140: 12/20/28/180/480/420 partition all hands: OK~n").

% ③ 桥牌：指定花色空缺、至少一个花色空缺与 4-4-3-2 分布。
check_bridge :-
    choose(52, 13, Total), choose(39, 13, FixedVoid),
    choose(26, 13, TwoVoid), choose(13, 13, ThreeVoid),
    AnyNum is 4*FixedVoid - 6*TwoVoid + 4*ThreeVoid,
    FixedP is FixedVoid rdiv Total,
    AnyP is AnyNum rdiv Total,
    choose(13, 4, C4), choose(13, 3, C3), choose(13, 2, C2),
    PatternNum is 12 * C4 * C4 * C3 * C2,
    PatternP is PatternNum rdiv Total,
    FixedP > 1 rdiv 100, FixedP < 14 rdiv 1000,
    AnyP > FixedP, AnyP < 6 rdiv 100,
    PatternP > 1 rdiv 5, PatternP < 23 rdiv 100,
    format("bridge: fixed void, any-void by IE, and 4-4-3-2 distribution checked: OK~n").

% ④ 秘书问题 n=4：24 个排列全枚举。
wins(0, [4, _, _, _]).
wins(1, [M | Rest]) :-
    append(Before, [4 | _], Rest),
    \+ (member(X, Before), X > M).
wins(2, [A, B | Rest]) :-
    M is max(A, B),
    append(Before, [4 | _], Rest),
    \+ (member(X, Before), X > M).
wins(3, [_, _, _, 4]).

win_count(K, N) :-
    findall(P, (perm([1,2,3,4], P), wins(K, P)), Ps),
    length(Ps, N).

check_secretary :-
    win_count(0, N0), win_count(1, N1), win_count(2, N2), win_count(3, N3),
    [N0,N1,N2,N3] = [6,11,10,6],
    Closed is 1 rdiv 4 * (1 + 1 rdiv 2 + 1 rdiv 3),
    Closed =:= 11 rdiv 24,
    format("secretary n=4 counts [6,11,10,6]; best threshold k=1 gives 11/24: OK~n").

main :-
    format("==== 07 counting_lab~n", []),
    check_birthday,
    check_mini_poker,
    check_bridge,
    check_secretary,
    format("END ====~n"), !.

:- initialization(main).
