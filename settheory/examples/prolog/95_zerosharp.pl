:- encoding(utf8).
% 第 95 章：奇偶染色上的齐一三元组搜索、蓝图一致性与平移保持。

color(I, J, C) :-
    I < J, S is (I + J) mod 2,
    (   S =:= 0 -> C = red ; C = blue ).

triple_hom(X, Y, Z) :-
    between(1, 8, X), between(1, 8, Y), between(1, 8, Z),
    X < Y, Y < Z,
    color(X, Y, C), color(X, Z, C), color(Y, Z, C).

% I 的全部递增二元组同色，P 为该共同颜色（蓝图的一元观察）。
pattern(I, P) :-
    findall(C, (member2(I, X, Y), color(X, Y, C)), Cs),
    Cs \= [],
    same_color(Cs, P).

member2(L, X, Y) :-
    append(_, [X | R], L), member(Y, R).

same_color([C], C).
same_color([C | Cs], C) :- same_color(Cs, C).

main :-
    format("==== 95~n"),
    findall(X-Y-Z, (between(1,6,X), triple_hom(X,Y,Z), Y =< 6, Z =< 6), Hom6),
    length(Hom6, N6),
    member(1-3-5, Hom6), member(2-4-6, Hom6),
    pattern([1,3,5], red),
    pattern([2,4,6], red),
    pattern([3,5,7], red),
    \+ pattern([1,2,3], _),
    forall((member2([1,3,5], X, Y), X1 is X+2, Y1 is Y+2),
           (color(X,Y,C), color(X1,Y1,C))),
    format("1..6 内齐一三元组共 ~w 个，含 1-3-5 与 2-4-6~n", [N6]),
    writeln("蓝图：{1,3,5}、{2,4,6}、{3,5,7} 同为恒红；{1,2,3} 红蓝混合不齐一"),
    writeln("平移 +2 保持 {1,3,5} 的全部二元取值（嵌入无歧义的影子）"),
    writeln("END ====").
