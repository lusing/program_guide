:- encoding(utf8).
% 第 31 章 · 有限阿贝尔群 —— Prolog 通道
%
% 阶档案枚举（完全不变量）+ 分类计数（分拆枚举）+ CRT 逐点核对。

% ---------- 基础 ----------
gcd_(0, B, G) :- !, G = B.
gcd_(A, 0, G) :- !, G = A.
gcd_(A, B, G) :- C is A mod B, gcd_(B, C, G).
gcd(A, M, G) :- gcd_(abs(A), abs(M), G).

lcm_(A, B, L) :- gcd(A, B, G), L is A * B // G.

% ℤ/m 中 a 的阶 = m ÷ gcd(a, m)（a = 0 时 gcd = m 得 1）
elem_order(A, M, O) :- gcd(A, M, G), O is M // G.

% 笛卡尔积：各槽位取 0..m-1（between 界必须先求值）
cartesian([], [[]]).
cartesian([M|Ms], Ts) :-
    M1 is M - 1,
    cartesian(Ms, Rest),
    findall([A|T], (between(0, M1, A), member(T, Rest)), Ts).

% 阶档案：全部元素阶（升序）
profile_component([], [], 1).
profile_component([A|As], [M|Ms], O) :-
    profile_component(As, Ms, O0),
    elem_order(A, M, OA),
    lcm_(OA, O0, O).

order_profile(Ms, Sorted) :-
    cartesian(Ms, Ts),
    maplist([T, O]>>(profile_component(T, Ms, O)), Ts, Os),
    msort(Os, Sorted).

% 分拆枚举（降序）
partitions(N, Ps) :-
    findall(P, gen_part(N, N, [], P), Ps).
gen_part(0, _, Acc, Acc).
gen_part(Rem, MaxPart, Acc0, P) :-
    Rem > 0,
    between(1, MaxPart, K),
    K =< Rem,
    Rem1 is Rem - K,
    gen_part(Rem1, K, [K|Acc0], P).

% 素分解（试除升序）
factorize(N, Pf) :- N > 1, factorize_(N, 2, Pf).
factorize_(1, _, []).
factorize_(N, P, [P-E|Rest]) :-
    N mod P =:= 0, !,
    count_div(N, P, 0, E),
    PE is P ^ E,
    N1 is N // PE,
    P1 is P + 1,
    factorize_(N1, P1, Rest).
factorize_(N, P, Pf) :-
    N mod P =\= 0, !,
    P1 is P + 1,
    factorize_(N, P1, Pf).

count_div(N, P, A0, A) :-
    (   N mod P =:= 0
    ->  N1 is N // P, A1 is A0 + 1, count_div(N1, P, A1, A)
    ;   A = A0
    ).

% n 阶阿贝尔群的全部初等因子形（逐素数分拆组合）
abelian_forms(N, Forms) :-
    factorize(N, Pf),
    foldl_prime(Pf, [[]], Forms).

foldl_prime([], Acc, Acc).
foldl_prime([P-E|Rest], Acc0, Forms) :-
    partitions(E, Ps),
    findall(New, (member(Part, Ps), member(Prev, Acc0),
                  maplist([L, PE]>>(PE is P ^ L), Part, PEs),
                  append(Prev, PEs, New)), Acc1),
    foldl_prime(Rest, Acc1, Forms).

% ---------- 辅助 ----------
all_distinct_lists([_]).
all_distinct_lists([P|Ps]) :-
    maplist(dif(P), Ps),
    all_distinct_lists(Ps).

prod_list([], 1).
prod_list([M|Ms], N) :- prod_list(Ms, N0), N is M * N0.

pairwise_coprime(Ms) :-
    forall((nth1(I, Ms, A), nth1(J, Ms, B), I < J), gcd(A, B, 1)).

max_list_([M], M).
max_list_([M|Ms], Max) :-
    max_list_(Ms, M0), (M > M0 -> Max = M ; Max = M0).

% ---------- 主流程 ----------
main :-
    format("==== 31 有限阿贝尔群~n"),

    % 8 阶三群：阶档案两两不同
    order_profile([2,2,2], P222),
    P222 == [1,2,2,2,2,2,2,2],
    order_profile([8], P8),
    P8 == [1,2,4,4,8,8,8,8],
    order_profile([4,2], P42),
    P42 == [1,2,2,2,4,4,4,4],
    P222 \== P8, P222 \== P42, P8 \== P42,
    format("8 阶三群：ℤ/8、ℤ/4×ℤ/2、ℤ/2×ℤ/2×ℤ/2 阶档案两两不同 ✓~n"),

    % 分类计数：72 = 2³·3² ⟹ 3·2 = 6 种，档案两两不同
    abelian_forms(72, F72),
    length(F72, 6),
    maplist(sort, F72, F72s),
    findall(Prof, (member(F, F72s), order_profile(F, Prof)), Profs),
    all_distinct_lists(Profs),
    format("72 阶阿贝尔群：恰 6 种（分拆 3×2），阶档案两两不同 ✓~n"),

    % 计数公式：∏ 分拆数
    abelian_forms(8, F8), length(F8, 3),
    abelian_forms(16, F16), length(F16, 5),
    abelian_forms(36, F36), length(F36, 4),
    abelian_forms(360, F360), length(F360, 6),
    format("计数公式：8→3、16→5、36→4、360→6（∏ 分拆数）✓~n"),

    % CRT：ℤ/6 ≅ ℤ/2 × ℤ/3（保加法 + 每对恰一解）
    forall((between(0, 5, X), between(0, 5, Y)),
           ((X + Y) mod 2 =:= (X mod 2 + Y mod 2) mod 2,
            (X + Y) mod 3 =:= (X mod 3 + Y mod 3) mod 3)),
    forall((between(0, 1, A), between(0, 2, B)),
           (findall(S, (between(0, 5, S),
                        S mod 2 =:= A, S mod 3 =:= B), Ss),
            length(Ss, 1))),
    format("CRT：ℤ/6 ≅ ℤ/2 × ℤ/3（模加法 + 每对恰一解）✓~n"),

    % 循环判据：两两互素 ⟺ 指数 = 阶
    forall(member(Ms, [[6],[2,3],[4,9],[2,2],[4,6],[2,3,5]]),
           (order_profile(Ms, Prof),
            max_list_(Prof, Expo),
            prod_list(Ms, N),
            (Expo =:= N -> pairwise_coprime(Ms)
            ; \+ pairwise_coprime(Ms)))),
    format("循环判据：直积循环 ⟺ 两两互素 ⟺ 指数 = 阶 ✓~n"),

    format("END ====~n").
