:- encoding(utf8).
% 01_signature_problems.pl —— 第 01 章：招牌问题（Prolog 穷举通道）
%
% ① 玩具生日问题：5 人 5 天，3125 种安排的完全穷举——撞车比例
%    vs 公式 1 − 5!/5^5；② 投篮小宇宙：p=1/2、q=2/5 的轮流
%    先中胜，回合树上穷举 vs 公式 p/(p+q−pq)。

% ① 穷举：5 人各取 1..5，数出"有重复"的安排数
birthday_collisions(Coll) :-
    findall(Bs, birthday_assignment(Bs), All),
    length(All, Total),
    include(has_duplicate, All, Dups),
    length(Dups, Coll),
    ( Total == 3125 -> true ; format("total ~w~n", [Total]) ),
    assertion(Total == 3125).

birthday_assignment([D1, D2, D3, D4, D5]) :-
    between(1, 5, D1), between(1, 5, D2), between(1, 5, D3),
    between(1, 5, D4), between(1, 5, D5).

has_duplicate(Bs) :- length(Bs, N), sort(Bs, S), length(S, M), M < N.

check_birthday :-
    birthday_collisions(Coll),
    Total is 5^5,
    Prob is Coll rdiv Total,               % 精确有理数比例
    Formula is 1 - 120 rdiv 3125,          % 1 − 5!/5^5 = 1 − 120/3125
    Prob == Formula,
    format("birthday toy (5 people, 5 days): ~w/~w = 1 - 5!/5^5 exact: OK~n",
           [Coll, Total]).

% ② 投篮小宇宙：胜率公式的三步验证（不动点方程的自引用账）
check_hoops :-
    P is 1 rdiv 2, Q is 2 rdiv 5,
    R is (1 - P) * (1 - Q),                % 双失概率 = 3/10
    PA is P / (1 - R),                     % 公式
    % 级数验证：p·(1 + r + r^2 + ... + r^9) 与公式差 < r^10
    Partial is P * (1 + R + R^2 + R^3 + R^4 + R^5 + R^6 + R^7 + R^8 + R^9),
    Gap is PA - Partial,
    R10 is R^10,
    Gap =< R10,
    % 不动点验证：p + r·PA = PA（自引用方程的两侧相等）
    Check is P + R * PA,
    Check == PA,
    PA =:= 5 rdiv 7,                       % =:= 求值两侧（== 是项同一性）
    format("hoops: P(A wins) = 5/7 via both series & fixed point: OK~n").

main :-
    format("==== 01 signature_problems~n", []),
    check_birthday,
    check_hoops,
    format("END ====~n"), !.

:- initialization(main).
