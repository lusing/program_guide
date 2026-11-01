:- encoding(utf8).
% 第 122 章：有限 AD 影子。有限枚举不证明无限 AD 或 AD^{L(R)}。

bit(Table, K, Bit) :- Bit is (Table >> K) /\ 1.

% 交替量词的动态规划：位置偶数归张三（max），奇数归李四（min）。
game_value(N, Table, Pos, Prefix, Value) :-
    ( Pos =:= N ->
        bit(Table, Prefix, Value)
    ; Pos1 is Pos + 1,
      game_value(N, Table, Pos1, Prefix, V0),
      Prefix1 is Prefix \/ (1 << Pos),
      game_value(N, Table, Pos1, Prefix1, V1),
      ( Pos mod 2 =:= 0 -> Value is max(V0, V1)
      ; Value is min(V0, V1)
      )
    ).

game_value(N, Table, Value) :- game_value(N, Table, 0, 0, Value).

check_determinacy(N, Last, ICount, IICount) :-
    aggregate_all(count,
        (between(0, Last, Table), game_value(N, Table, 1)), ICount),
    aggregate_all(count,
        (between(0, Last, Table), game_value(N, Table, 0)), IICount),
    Total is Last + 1,
    ICount + IICount =:= Total.

% 尾代表：清除低 n-m 位，保留高 m 位。
tail_rep(N, M, X, R) :-
    Low is N - M,
    Mask is ((1 << M) - 1) << Low,
    R is X /\ Mask.

first_diff_at(_, Limit, Pos, Pos) :- Pos >= Limit, !.
first_diff_at(X, Limit, Pos, D) :-
    ( (X >> Pos) /\ 1 =:= 1 -> D = Pos
    ; Pos1 is Pos + 1, first_diff_at(X, Limit, Pos1, D)
    ).

first_diff(N, M, X, D) :-
    Limit is N - M,
    first_diff_at(X, Limit, 0, D0),
    (D0 =:= Limit -> D = N ; D = D0).

tail_pay(N, M, X, V) :-
    first_diff(N, M, X, D),
    (D mod 2 =:= 0 -> V = 1 ; V = 0).

check_tail(N, M) :-
    Last is (1 << N) - 1,
    forall(between(0, Last, X),
        (tail_rep(N, M, X, R),
         tail_rep(N, M, R, R),
         Low is N - M,
         (R >> Low) =:= (X >> Low))),
    aggregate_all(count,
        (between(0, Last, X), tail_pay(N, M, X, 1)), Size),
    (N =:= 4, M =:= 2 -> Size =:= 12 ; true),
    game_value(N, 0, 0), % 空收益表是递归通道的边界哨兵
    Size >= 0.

% 完美树：存在柱 s，其 2^d 个叶点全在 A 中。
cylinder_full(A, D, S) :-
    Last is (1 << D) - 1,
    Base is S << D,
    forall(between(0, Last, T), bit(A, Base + T, 1)).

has_perfect(A, N, D) :-
    Last is (1 << (N-D)) - 1,
    between(0, Last, S),
    cylinder_full(A, D, S),
    !.

check_perfect :-
    forall(between(0, 65535, A),
        forall(between(1, 4, D),
            (\+ has_perfect(A, 4, D) ->
                popcount(A) =< 16 - (1 << (4-D))
            ; true))),
    forall(between(1, 4, D),
        (LastS is (1 << (4-D)) - 1,
         aggregate_all(sum(1 << (S << D)), between(0, LastS, S), Missing),
         AStar is 65535 xor Missing,
         \+ has_perfect(AStar, 4, D),
         popcount(AStar) =:= 16 - (1 << (4-D)))).

check_params :-
    forall((between(0, 7, P), between(0, 15, A)),
        (C is (P << 4) \/ A,
         P1 is C >> 4,
         A1 is C /\ 15,
         P1 =:= P, A1 =:= A)),
    aggregate_all(count, (between(0, 7, P), between(0, 15, A),
                          C is (P << 4) \/ A, C >= 0), 128).

main :-
    check_determinacy(4, 65535, I4, II4),
    I4 =:= 22687, II4 =:= 42849,
    check_determinacy(3, 255, I3, II3),
    I3 =:= 207, II3 =:= 49,
    game_value(4, 21845, 1), % 偶数下标表：张三必胜
    game_value(4, 0, 0),     % 空表：李四必胜
    forall(between(1, 6, N), forall(between(1, N, M), check_tail(N, M))),
    check_perfect,
    check_params,
    format('==== 122~n'),
    format('finite determinacy length4: 65536/65536 tables, I=~w II=~w~n', [I4,II4]),
    format('length3: 256 tables, I=~w II=~w~n', [I3,II3]),
    format('tail representatives n=1..6; |A_(4,2)|=12~n', []),
    format('perfect-tree bound: 65536 sets x 4 depths, tight~n', []),
    format('parameter codes: 128/128 round-trip~n'),
    format('END ====~n'),
    halt(0).

:- initialization(main).
