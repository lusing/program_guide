:- encoding(utf8).
% 第 06 章 · 日期与天数 —— Prolog 通道
%
% 日历公式（命题 1.80）的纯整数实现 + 史实断言 + 星期五十三号 + 椰子问题。


% 自然月 Jan..Dec 的偏移表（原书 3 月制平移而来，推导见 docs/06）
j_offset(1, 0).  j_offset(2, 3).  j_offset(3, 2).
j_offset(4, 5).  j_offset(5, 0).  j_offset(6, 3).
j_offset(7, 5).  j_offset(8, 1).  j_offset(9, 4).
j_offset(10, 6). j_offset(11, 2). j_offset(12, 4).

% 命题 1.80：A ≡ d + j(m) + g(y) (mod 7)，0 = 星期日
dow(Y, M, D, W) :-
    (   M =< 2 -> Y1 is Y - 1 ; Y1 is Y ),
    G is Y1 + Y1 // 4 - Y1 // 100 + Y1 // 400,
    j_offset(M, J),
    W is (D + J + G) mod 7.

% 命题 1.84：康威审判日
anchor(C, A) :-
    member(C-A, [16-2, 17-0, 18-5, 19-3, 20-2, 21-0, 22-5]).

doomsday(Y, D) :-
    C is Y // 100,
    N is Y mod 100,
    anchor(C, A),
    D is (A + N + N // 4) mod 7.

days_in_month(Y, 2, DM) :- !,
    (   Y mod 4 =:= 0, ( Y mod 100 =\= 0 ; Y mod 400 =:= 0 ) -> DM = 29 ; DM = 28 ).
days_in_month(_, M, DM) :-
    member(M, [1, 3, 5, 7, 8, 10, 12]), !, DM = 31.
days_in_month(_, _, 30).

% 椰子问题（习题 1.97）：五人一猴
coconut(N) :-
    between(1, 20000, N),
    chain5(N).

chain5(N0) :- chain(N0, 5).
chain(N, 0) :- !, N mod 4 =:= 0.       % 早晨四人分得动（习题口径）
chain(N, K) :-
    K > 0,
    N1 is N - 1,
    N1 mod 5 =:= 0,                     % 余一给猴子
    N2 is 4 * (N1 // 5),                % 藏一份，剩四份
    K1 is K - 1,
    chain(N2, K1).

main :-
    format("==== 06 日期与天数~n"),

    % 史实锚点
    dow(1776, 7, 4, W1), W1 == 4,       % 星期四
    dow(2000, 2, 29, W2), W2 == 2,      % 星期二
    dow(2024, 2, 29, W3), W3 == 4,      % 星期四
    format("锚点：1776-07-04 星期四；2000-02-29 星期二；2024-02-29 星期四 ✓~n"),

    % 康威互证：审判日 = 2 月最后一天（1900–2100）
    forall(between(1900, 2100, Y),
           ( days_in_month(Y, 2, DM),
             dow(Y, 2, DM, W),
             doomsday(Y, D),
             W =:= D )),
    format("康威审判日 = 2 月最后一天的星期数：1900–2100 全部一致 ✓~n"),

    % 星期五十三号：1987 年恰 3 个（2/3/11 月）
    findall(M, (between(1, 12, M), dow(1987, M, 13, 5)), Ms87),
    Ms87 == [2, 3, 11],
    format("1987 年的星期五十三号：2 月、3 月、11 月 ✓~n"),

    % 每年 1..3 个星期五十三号（1600–2200 抽查每 97 年 + 全体计数下界）
    forall(between(1600, 2200, Y),
           ( findall(M, (between(1, 12, M), dow(Y, M, 13, 5)), Ms),
             length(Ms, Cnt),
             Cnt >= 1, Cnt =< 3 )),
    format("星期五十三号：1600–2200 每年 1–3 个 ✓~n"),

    % 椰子问题
    coconut(N),
    N == 3121,
    format("椰子问题：最小解 N = ~d = 5⁵ − 4 ✓~n", [N]),

    format("END ====~n").
