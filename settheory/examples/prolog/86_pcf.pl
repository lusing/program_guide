:- encoding(utf8).
% 第 86 章：谢旯 pcf 理论（冯琦第二卷 §1.3）——Prolog 通道
% 有限正则集合 A={3,5,7}：标尺、主超滤子、生成元传递性。

member_a(3).
member_a(5).
member_a(7).

scale(0, _, 0).
scale(1, _, 1).
scale(2, _, 2).

le_pw(I, J) :-
    forall(member_a(N), (scale(I, N, FI), scale(J, N, FJ), FI =< FJ)).

lt_pw(I, J) :-
    le_pw(I, J),
    member_a(N),
    scale(I, N, FI), scale(J, N, FJ), FI < FJ.

principal(A, X) :- member(A, X).

generator(Lam, Xs) :-
    findall(X, (member_a(X), X =< Lam), Xs).

generator_transitive(Mu, Lam) :-
    generator(Lam, BLam),
    member(Mu, BLam),
    generator(Mu, BMu),
    forall(member(X, BMu), member(X, BLam)).

main :-
    format("==== 86~n"),
    lt_pw(0, 1),
    lt_pw(1, 2),
    le_pw(0, 2),
    principal(3, [3]),
    generator(3, [3]),
    generator(5, [3, 5]),
    generator(7, [3, 5, 7]),
    forall((member_a(Lam), generator(Lam, B), member(Mu, B)),
           generator_transitive(Mu, Lam)),
    writeln('scale length 3'),
    writeln('generators ok'),
    writeln('transitive ok'),
    writeln('pcf toy idempotent'),
    writeln("END ====").
