:- encoding(utf8).
% 第 125 章 Prolog：悖论的有限宇宙穷举。
% ① 3 元宇宙上全部 512 个隶属图，逐一检查罗素谓词
%    "y ∉ y" 是否有代表集合——对角线论证保证永远没有；
% ② 全概括（每个子谓词都有代表）在有限宇宙内的不可能性；
% ③ 理发师悖论的小村庄穷举；
% ④ 基础公理的有限影子：无自属的图恰有 2^6 = 64 个。

% ---------- 基础件 ----------
subset([], []).
subset([H|T], [H|S]) :- subset(T, S).
subset([_|T], S) :- subset(T, S).

pairs3(Ps) :- findall(X-Y, (member(X,[a,b,c]), member(Y,[a,b,c])), Ps).

gm(G, X, Y) :- member(X-Y, G).          % X ∈ Y（图 G 中的边）

% ---------- ① 罗素谓词无代表 ----------
% 代表 X 的隶属列必须逐点等于 "y ∉ y"：
russell_rep(G, X) :-
    member(X, [a,b,c]),
    forall(member(Y, [a,b,c]),
           ((gm(G,Y,X), \+ gm(G,Y,Y)) ; (\+ gm(G,Y,X), gm(G,Y,Y)))).

check_russell :-
    pairs3(Ps),
    findall(G, (subset(Ps, G), russell_rep(G, _X1)), Hits1),
    length(Hits1, 0),
    format("russell predicate has no representative: 0 of 512 graphs: OK~n").

% ---------- ② 全概括无有限模型 ----------
% 8 个子谓词（{a,b,c} 的全部子集）都要有代表，而代表至多 3 列。
represents(G, X, P) :-
    forall(member(Y, [a,b,c]),
           ((gm(G,Y,X), member(Y,P)) ; (\+ gm(G,Y,X), \+ member(Y,P)))).

full_comp(G) :-
    forall((subset([a,b,c], Pred), ground(Pred)),
           (member(X, [a,b,c]), represents(G, X, Pred))).

check_full_comp :-
    pairs3(Ps),
    findall(G, (subset(Ps, G), full_comp(G)), Hits2),
    length(Hits2, 0),
    format("full comprehension has no finite model on 3 elements: OK~n").

% ---------- ③ 理发师悖论 ----------
% 村庄 V 的刮脸指派 S（有向图），理发师 B 满足
% "B 刮 x ⟺ x 不刮自己"。穷举一切指派：无解。
barber_ok(S, B, V) :-
    member(B, V),
    forall(member(X, V),
           ((member(B-X, S), \+ member(X-X, S))
            ; (\+ member(B-X, S), member(X-X, S)))).

check_barber :-
    V3 = [p,q,r],
    findall(S-Bs, (all_pairs(V3, Ps), subset(Ps, S),
                   findall(B, barber_ok(S, B, V3), Bs), Bs \= []), Sol),
    length(Sol, 0),
    format("barber: no consistent assignment exists in any village: OK~n").

all_pairs(V, Ps) :-
    findall(X-Y, (member(X,V), member(Y,V)), Ps).

% ---------- ④ 无自属的图（基础公理的影子） ----------
check_no_self :-
    pairs3(Ps),
    findall(G, (subset(Ps, G), \+ (member(X-Y, G), X == Y)), NoSelf),
    length(NoSelf, 64),                 % 去掉 3 条对角线后 2^6
    format("foundation shadow: exactly 64 of 512 graphs have no x in x: OK~n").

main :-
    format("==== 125 russell~n"),
    check_russell,
    check_full_comp,
    check_barber,
    check_no_self,
    format("END ====~n"), !.

:- initialization(main).
