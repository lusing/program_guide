:- encoding(utf8).
% 第 127 章 Prolog：划分的生成、等价闭包与序分析。
% ① 全部划分的生成器 + 规范化去重（块内排序 + 块排序——生成器本身
%    按块序产生重复；Bell 数终审：3 元素 5 个、4 元素 15 个、5 元素 52 个）；
% ② 划分 → 关系 → 商 的往返复原（书 2.3.8/2.3.9）；
% ③ 任意关系在给定全域上的等价闭包；
% ④ 有限偏序的极小/最小/最大分析：P({1,2})−{∅} 与整除序
%    （书 2.4.4/2.4.6：素数是无穷多极小元的缩影）+ 整除格 sup=lcm。

% ---------- ① 划分生成器 ----------
partition([], []).
partition([H|T], P) :-
    partition(T, P0),
    (   member(B, P0), select(B, P0, PR), P = [[H|B]|PR]   % 并入已有块
    ;   P = [[H]|P0]                                        % 或另立新块
    ).

canonical(P, C) :- maplist(sort, P, PB), sort(PB, C).      % 规范形：块内升序+块排序

bell_count(N, K) :-
    numlist(1, N, L),
    findall(C, (partition(L, P), canonical(P, C)), Cs0),
    sort(Cs0, Cs), length(Cs, K).

% ---------- ② 往返复原 ----------
rel_of(P, X, Y) :- member(B, P), member(X, B), member(Y, B).

reflexive(P, U)  :- \+ (member(X, U), \+ rel_of(P, X, X)).
symmetric(P)     :- \+ (rel_of(P, X, Y), \+ rel_of(P, Y, X)).
transitive(P)    :- \+ (rel_of(P, X, Y), rel_of(P, Y, Z), \+ rel_of(P, X, Z)).

elements_of(P, Es) :- findall(E, (member(B, P), member(E, B)), E0), sort(E0, Es).
class_of(P, X, C) :- elements_of(P, Es),
                     findall(Y, (member(Y, Es), rel_of(P, X, Y)), C0),
                     sort(C0, C).
quotient(P, Q)    :- elements_of(P, Es),
                     setof(C, X^(member(X, Es), class_of(P, X, C)), Q).

check_all :-
    numlist(1, 3, U),
    findall(Can, (partition(U, P), canonical(P, Can),
                  reflexive(P, U), symmetric(P), transitive(P),
                  quotient(P, Q), canonical(Q, Can)), Cs0),
    sort(Cs0, Cs), length(Cs, 5),                    % 5 个规范划分全部通过三律+往返
    bell_count(3, 5), bell_count(4, 15), bell_count(5, 52),
    format("partitions: Bell(3,4,5)=5,15,52; all pass eq laws + roundtrip: OK~n").

% ---------- ③ 等价闭包（全域 U 上的最小等价关系） ----------
closure_step(U, R0, R1) :-
    findall((X,Z), (member((X,Y), R0), member((Y,Z), R0)), Comp),
    findall((Y,X), member((X,Y), R0), Inv),
    findall((X,X), member(X, U), Refl),
    append([R0, Comp, Inv, Refl], All0), sort(All0, R1).

eq_closure(U, R0, C) :-
    closure_step(U, R0, R1),
    (   R1 == R0 -> C = R1
    ;   eq_closure(U, R1, C)
    ).

check_closure :-
    eq_closure([0,1,2,3,4], [(1,2),(3,4)], C),
    P = [[0],[1,2],[3,4]],
    findall((X,Y), (member(B, P), member(X, B), member(Y, B)), Rel),
    sort(Rel, RelS), C == RelS,
    format("equivalence closure: {(1,2),(3,4)} closes to classes {0},{1,2},{3,4}: OK~n").

% ---------- ④ 序分析 ----------
minimal(Pos, Le, M) :- member(M, Pos),
    \+ (member(O, Pos), O \= M, call(Le, O, M)).
maximal(Pos, Le, M) :- member(M, Pos),
    \+ (member(O, Pos), O \= M, call(Le, M, O)).
least(Pos, Le, L)   :- member(L, Pos), forall(member(O, Pos), call(Le, L, O)).

sub_le(A, B) :- subset(A, B).        % 块表 A ≤ B 即 A ⊆ B
subset([], _).
subset([H|T], S) :- member(H, S), subset(T, S).
div_le(A, B) :- B mod A =:= 0.

check_orders :-
    Subs = [[1],[2],[1,2]],
    findall(M, minimal(Subs, sub_le, M), MinS), sort(MinS, [[1],[2]]),
    \+ least(Subs, sub_le, _),
    Divs = [2,3,4,6,12],
    findall(M, minimal(Divs, div_le, M), MinD), sort(MinD, [2,3]),
    \+ least(Divs, div_le, _),
    findall(M, maximal(Divs, div_le, M), MaxD), MaxD = [12],
    format("orders: P-{{}} has 2 minimals no least; div poset minimals are primes: OK~n").

check_lattice :-
    Divs = [1,2,3,6],
    forall((member(A, Divs), member(B, Divs)),
           ( findall(U, (member(U, Divs), U mod A =:= 0, U mod B =:= 0), UBs),
             least(UBs, div_le, L), L =:= lcm(A, B) )),
    format("divisibility lattice: least upper bound = lcm audited: OK~n").

main :-
    format("==== 127 partitions~n"),
    check_all,
    check_closure,
    check_orders,
    check_lattice,
    format("END ====~n"), !.

:- initialization(main).
