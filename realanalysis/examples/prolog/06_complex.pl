:- encoding(utf8).
% Chapter 06 complex numbers and Euclidean space: Prolog channel.
% Complex numbers as ordered pairs c(A,B) over exact integers/rationals;
% inner product, Cauchy-Schwarz and the Lagrange identity on lists.
% Run: swipl -q -f 06_complex.pl -g main -t halt

verify(G) :-
    (   call(G)
    ->  true
    ;   format("FAILED: ~w~n", [G]),
        fail
    ).

% --- complex numbers as pairs ---------------------------------------
cmul(c(A,B), c(C,D), c(Re,Im)) :-
    Re is A*C - B*D,
    Im is A*D + B*C.
cconj(c(A,B), c(A,NB)) :- NB is -B.
cnorm2(c(A,B), N) :- N is A*A + B*B.
cinv(c(A,B), c(X,Y)) :-
    cnorm2(c(A,B), D), D =\= 0,
    X is A rdiv D,
    Y is -B rdiv D.
ceq(c(A,B), c(C,D)) :- A =:= C, B =:= D.

% --- Euclidean space on lists ---------------------------------------
dot([], [], 0).
dot([X|Xs], [Y|Ys], S) :- dot(Xs, Ys, S0), S is S0 + X*Y.
n2(X, N) :- dot(X, X, N).

% Lagrange gap: sum over i<j of (x_i y_j - x_j y_i)^2.
lagrange_gap(X, Y, G) :-
    length(X, L),
    aggregate_all(sum(T),
        ( between(1, L, I), between(1, L, J), I < J,
          nth1(I, X, XI), nth1(J, X, XJ),
          nth1(I, Y, YI), nth1(J, Y, YJ),
          T is (XI*YJ - XJ*YI)^2 ),
        G).

main :-
    format("==== 06 complex ====~n", []),

    verify((cmul(c(0,1), c(0,1), II), ceq(II, c(-1,0)))),
    format("i * i = -1~n", []),

    verify((cmul(c(1,2), c(3,4), P), ceq(P, c(-5,10)))),
    format("(1+2i)(3+4i) = -5 + 10i~n", []),

    verify((cconj(c(1,2), Zc), cmul(c(1,2), Zc, ZZ), ceq(ZZ, c(5,0)))),
    format("z * conj(z) = |z|^2 = 5~n", []),

    verify((cinv(c(1,2), Zi), cmul(c(1,2), Zi, One), ceq(One, c(1,0)))),
    format("z * (1/z) = 1~n", []),

    verify((cnorm2(c(3,4), 25))),
    format("|3+4i|^2 = 25, |3+4i| = 5~n", []),

    verify((dot([1,2], [3,4], 11), n2([1,2], 5), n2([3,4], 25))),
    verify(11*11 =< 5*25),
    verify(5*25 - 11*11 =:= (1*4 - 2*3)^2),
    format("C-S in R^2: 121 <= 125, gap 4 = (1*4 - 2*3)^2~n", []),

    U = [3,-1,4,1,-5], V = [2,7,-1,8,2],
    verify((dot(U, V, UV), n2(U, NU), n2(V, NV),
            lagrange_gap(U, V, G),
            NU*NV - UV*UV =:= G,
            UV*UV =< NU*NV)),
    format("C-S in R^5: gap equals sum of squared 2x2 minors~n", []),

    verify((maplist([A,B,S]>>(S is A+B), U, V, W),
            n2(W, NW), n2(U, NU2), n2(V, NV2),
            sqrt(NW) =< sqrt(NU2) + sqrt(NV2))),
    format("triangle inequality holds in R^5~n", []),

    format("END ====~n", []).
