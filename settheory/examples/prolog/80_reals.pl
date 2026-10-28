:- encoding(utf8).
% 第 80 章：有限区间族的有限交性质（FIP）与总交。
% 区间端点是整数；这只是紧致性定理的有限影子，不证明实数紧致性。

interval_intersect([A,B], [C,D], [Lo,Hi]) :-
    Lo is max(A,C), Hi is min(B,D), Lo =< Hi.

intersect_all([I], I).
intersect_all([I|Is], R) :-
    intersect_all(Is, T),
    interval_intersect(I, T, R).

nonempty_subfamily([I|_], [I]).
nonempty_subfamily([I|Is], [I|Ss]) :- nonempty_subfamily(Is, Ss).
nonempty_subfamily([_|Is], Ss) :- nonempty_subfamily(Is, Ss).

family_fip(F) :-
    forall(nonempty_subfamily(F, S), intersect_all(S, _)).

family1([[1,6],[3,8],[5,10]]).
family2([[1,3],[4,6]]).
family3([[0,4],[2,9],[3,7],[1,5]]).

main :-
    format("==== 80~n"),
    family_fip([[1,6],[3,8],[5,10]]),
    intersect_all([[1,6],[3,8],[5,10]], [5,6]),
    \+ family_fip([[1,3],[4,6]]),
    family_fip([[0,4],[2,9],[3,7],[1,5]]),
    intersect_all([[0,4],[2,9],[3,7],[1,5]], [3,4]),
    forall((family1(F); family3(F)),
           (family_fip(F), intersect_all(F, R), R = [Lo,Hi], Lo =< Hi)),
    writeln("FIP 有限实验：[1,6]∩[3,8]∩[5,10]=[5,6]；四区间总交=[3,4] ✓"),
    writeln("反例：[1,3] 与 [4,6] 已使有限子族交为空；无限族仍需紧致性论证"),
    writeln("END ====").
