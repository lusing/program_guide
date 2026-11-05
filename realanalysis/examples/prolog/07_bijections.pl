:- encoding(utf8).
% Chapter 07 bijections: Prolog channel.
% Finite-set image/preimage, inj/surj/bij, inverse and composition.
% Run: swipl -q -f 07_bijections.pl -g main -t halt

verify(G) :-
    (   call(G)
    ->  true
    ;   format("FAILED: ~w~n", [G]),
        fail
    ).

image(_, [], []).
image(F, [X|Xs], [Y|Ys]) :- call(F, X, Y), image(F, Xs, Ys).

preimage(_, [], _, []).
preimage(F, [X|Xs], G, [X|Ps]) :-
    call(F, X, Y), member(Y, G), !,
    preimage(F, Xs, G, Ps).
preimage(F, [_|Xs], G, Ps) :-
    preimage(F, Xs, G, Ps).

% All distinct images under F on list A.
injective(F, A) :-
    \+ (member(X, A), member(Y, A), X \= Y,
        call(F, X, FX), call(F, Y, FY), FX =:= FY).

surjective(F, A, B) :-
    image(F, A, Im), sort(Im, SIm), sort(B, SB), SIm == SB.

bijective(F, A, B) :- injective(F, A), surjective(F, A, B).

const1(_, 1).
sq(X, Y) :- Y is X*X.
mul2(X, Y) :- Y is 2*X.
halve(Y, X) :- X is Y/2.
sq_of_mul2(X, Y) :- mul2(X, T), sq(T, Y).

main :-
    format("==== 07 bijections ====~n", []),

    verify((image(const1, [1,2,3], Im), sort(Im, [1]))),
    format("const image of {1,2,3} = {1}~n", []),

    verify((preimage(sq, [-5,-4,-3,-2,-1,0,1,2,3,4,5], [16], P),
            sort(P, [-4,4]))),
    format("preimage of {16} under sq = {4,-4}~n", []),

    S = [-2,-1,0,1,2], T = [-4,-2,0,2,4],
    verify(injective(mul2, S)),
    verify(bijective(mul2, S, T)),
    format("x ↦ 2x bijective on sample~n", []),

    verify((\+ injective(sq, S))),
    format("x ↦ x² not injective~n", []),

    verify((surjective(const1, [1,2], [1]), \+ injective(const1, [1,2]))),
    format("{1,2}→{1} surjective not injective~n", []),

    verify((injective(const1, [1]), \+ surjective(const1, [1], [1,2]))),
    format("{1}→{1,2} injective not surjective~n", []),

    verify((maplist([X]>>(mul2(X,Y), halve(Y,X)), S))),
    verify((maplist([Y]>>(halve(Y,X), mul2(X,Y)), T))),
    format("f and g are two-sided inverses~n", []),

    verify((maplist([X]>>(sq_of_mul2(X,Y), Y =:= 4*X*X), S))),
    format("composition: (sq ∘ double)(x)=4x²~n", []),

    format("END ====~n", []).
