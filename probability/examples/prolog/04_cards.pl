:- encoding(utf8).
% 04_cards.pl —— 第 04 章：扑克（Prolog 穷举通道）
%
% 迷你扑克：20 张牌（5 点 × 4 花）发 3 张，C(20,3) = 1140 手
% 全枚举——各牌型的精确计数 vs 公式（穷举是公式的终审法庭）。
% 迷你公式的手推：三条 = 5·C(4,3) = 20；恰一对 = 5·C(4,2)·16
% = 480；同花(非顺) = 4·(C(5,3)−3) = 28；顺子(非同花) =
% 3·(4³−4) = 180；同花顺 = 3·4 = 12；其余 = 无型。

deal3([card(Ri, Si), card(Rj, Sj), card(Rk, Sk)]) :-
    between(1, 5, Ri), between(1, 4, Si),
    Ix is (Si - 1) * 5 + Ri,
    between(1, 5, Rj), between(1, 4, Sj),
    Jx is (Sj - 1) * 5 + Rj, Jx > Ix,
    between(1, 5, Rk), between(1, 4, Sk),
    Kx is (Sk - 1) * 5 + Rk, Kx > Jx.

classify([card(R1, S1), card(R2, S2), card(R3, S3)], Type) :-
    msort([R1, R2, R3], Rs),
    ( S1 =:= S2, S2 =:= S3 -> Flush = true ; Flush = false ),
    ( consecutive(Rs) -> Straight = true ; Straight = false ),
    ( Flush, Straight -> Type = straight_flush
    ; Flush -> Type = flush
    ; Straight -> Type = straight
    ; classify_rank(Rs, Type) ),
    !.

classify_rank([A, A, A], three_kind).
classify_rank([A, A, _], pair).
classify_rank([_, A, A], pair).
classify_rank(_, nothing).

consecutive([A, B, C]) :- B =:= A + 1, C =:= B + 1.

counts(Types, Pairs) :-
    sort(Types, Unique),
    findall(U-C, (member(U, Unique),
                  include(=(U), Types, Ts), length(Ts, C)), Pairs).

check_all :-
    findall(T, (deal3(H), classify(H, T)), Types),
    length(Types, 1140),
    counts(Types, Cts),
    memberchk(three_kind-Tk, Cts), memberchk(pair-P, Cts),
    memberchk(flush-F, Cts), memberchk(straight-St, Cts),
    memberchk(straight_flush-SF, Cts), memberchk(nothing-N, Cts),
    assertion(Tk =:= 20),
    assertion(P =:= 480),
    assertion(F =:= 28),
    assertion(St =:= 180),
    assertion(SF =:= 12),
    assertion(Tk + P + F + St + SF + N =:= 1140),
    format("mini-poker C(20,3)=1140: three=20 pair=480 flush=28~n"),
    format("  straight=180 sflush=12 nothing=~w (all match formulas): OK~n", [N]).

main :-
    format("==== 04 cards~n", []),
    check_all,
    format("END ====~n"), !.

:- initialization(main).
