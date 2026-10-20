:- encoding(utf8).
% 06_inclusion_exclusion.pl —— 第 06 章：容斥（Prolog 穷举）
%
% ① n=4 错排全枚举（4!=24 个排列中数出 D_4=9——闭式的终审）；
% ② n=3 篮 k=4 球的 81 投法全枚举"全非空"；③ 8 点玩具空间
% 逐点计账验证三事件容斥。

perm([], [], _).
perm(Rest, [X | P], Used) :-
    member(X, Rest),
    select(X, Rest, R2),
    perm(R2, P, [X | Used]).

perms4(Ps) :- findall(P, (perm([1,2,3,4], P, [])), Ps).

no_fixed(P) :- \+ (nth1(I, P, I)).

check_derangement :-
    perms4(Ps),
    length(Ps, 24),
    include(no_fixed, Ps, Ds),
    length(Ds, 9),
    % 容斥闭式核对：4! (1 - 1 + 1/2 - 1/6 + 1/24) = 9
    Closed is 24 * (1 - 1 + 1 rdiv 2 - 1 rdiv 6 + 1 rdiv 24),
    Closed =:= 9,
    format("derangements n=4: 24 perms enumerated, D_4 = 9 = closed form: OK~n").

check_balls :-
    findall(Assign, (between(1,3,A1), between(1,3,B1), between(1,3,C1),
                     between(1,3,D1),
                     Assign = [A1,B1,C1,D1]), All),
    length(All, 81),
    include(all_distinct3, All, Full),
    length(Full, NFull),
    NFull =:= 36,
    % 容斥：3^4 - C(3,1)2^4 + C(3,2)1^4 = 81 - 48 + 3 = 36
    IE is 81 - 3 * 16 + 3 * 1,
    IE =:= NFull,
    format("balls n=3,k=4: 81 assignments enumerated, full-cover = 36 = IE: OK~n").

all_distinct3(L) :- sort(L, S), length(S, 3).

% ③ 玩具空间 8 点：A={5,6,7,8} B={3,4,7,8} C={1,4,6,8}（两两交 2 点，三重交 1 点）
%    |A∪B∪C| = 12 + 12 + 12 - 4 - 4 - 4 + 2 = ... 直接枚举点数
check_three_events :-
    findall(X, between(1, 8, X), Omega),
    include(in_any, Omega, Union),
    length(Union, U),
    % 容斥：|A|+|B|+|C| − |AB|−|AC|−|BC| + |ABC|
    IE is 4 + 4 + 4 - 2 - 2 - 2 + 1,
    U =:= IE,
    format("3-event IE on 8-point space: |union| = ~w = IE count ~w: OK~n", [U, IE]).

in_a(X) :- X >= 5.
in_b(X) :- member(X, [3, 4, 7, 8]).
in_c(X) :- member(X, [1, 4, 6, 8]).
in_any(X) :- (in_a(X) ; in_b(X) ; in_c(X)).

main :-
    format("==== 06 inclusion_exclusion~n", []),
    check_derangement,
    check_balls,
    check_three_events,
    format("END ====~n"), !.

:- initialization(main).
