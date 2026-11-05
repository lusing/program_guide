:- encoding(utf8).
% Chapter 04 field axioms: Prolog channel.
% Field axioms checked over exact rationals (rdiv), Z5 enumerated,
% integers shown not to be a field.
% Run: swipl -q -f 04_field.pl -g main -t halt

verify(G) :-
    (   call(G)
    ->  true
    ;   format("FAILED: ~w~n", [G]),
        fail
    ).

verify_not(G) :-
    (   call(G)
    ->  format("FAILED (expected failure): ~w~n", [G]),
        fail
    ;   true
    ).

% Field axiom check for a single rational triple.
field_ok(A, B, C) :-
    A + (B + C) =:= (A + B) + C,
    A * (B * C) =:= (A * B) * C,
    A + B =:= B + A,
    A * B =:= B * A,
    A * (B + C) =:= A * B + A * C.

z5add(A, B, R) :- R is (A + B) mod 5.
z5mul(A, B, R) :- R is (A * B) mod 5.

% Z5 field laws on all triples.
z5_laws :-
    forall((between(0, 4, A), between(0, 4, B), between(0, 4, C)),
           (   z5add(A, B, AB), z5add(AB, C, ABC1),
               z5add(B, C, BC), z5add(A, BC, ABC2),
               ABC1 =:= ABC2,
               z5mul(A, B, ABm), z5mul(ABm, C, ABCm1),
               z5mul(B, C, BCm), z5mul(A, BCm, ABCm2),
               ABCm1 =:= ABCm2,
               z5add(A, B, S1), z5add(B, A, S2), S1 =:= S2,
               z5mul(A, B, M1), z5mul(B, A, M2), M1 =:= M2,
               z5mul(A, BC, D1),
               z5mul(A, B, AB2), z5mul(A, C, AC2),
               z5add(AB2, AC2, D2),
               D1 =:= D2)).

% Every nonzero residue has an inverse.
z5_inverses :-
    forall(between(1, 4, A),
           (between(1, 4, B), z5mul(A, B, 1), !)).

main :-
    format("==== 04 field ====~n", []),

    % 1. Rationals satisfy field axioms (sampled triples).
    Qs = [1 rdiv 2, -3 rdiv 7, 22 rdiv 7, 0, 355 rdiv 113],
    verify(forall((member(A, Qs), member(B, Qs), member(C, Qs)),
                  field_ok(A, B, C))),
    verify(forall(member(A, Qs),
                  (   A + 0 =:= A,
                      A * 1 =:= A,
                      A + (-A) =:= 0,
                      (   A =:= 0
                      ->  true
                      ;   A * (1 rdiv A) =:= 1)))),
    format("rationals: field axioms verified on samples~n", []),

    % 2. Floats fail associativity: (1 - 1e100) + 1e100 = 0 but
    %    1 + (-1e100 + 1e100) = 1.
    verify_not((1.0 + -1e100) + 1e100 =:= 1.0 + (-1e100 + 1e100)),
    format("floats: associativity counterexample found~n", []),

    % 3. Z5 is a field: full enumeration.
    verify(z5_laws),
    verify(z5_inverses),
    z5add(2, 3, S), verify(S =:= 0),
    z5mul(2, 3, P), verify(P =:= 1),
    format("Z5: full enumeration passed (2+3=0, 2*3=1)~n", []),

    % 4. Z is not a field: no z with 2z = 1.
    verify_not((between(-1000, 1000, Z), 2 * Z =:= 1)),
    format("Z: no integer z with 2z = 1~n", []),

    format("END ====~n", []).
