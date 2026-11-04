:- encoding(utf8).
% Chapter 01 logic and proof techniques: Prolog channel.
% Truth tables, quantifier order, induction formula checks, and the
% epsilon-delta limit as a finite rational experiment.
% Run: swipl -q -f 01_logic.pl -g main -t halt

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

% Boolean connectives over numeric truth values 1/0.
bv(true, 1).
bv(false, 0).
tor(VA, VB, R) :- R is max(VA, VB).
tand(VA, VB, R) :- R is min(VA, VB).
tnot(1, 0).
tnot(0, 1).
% Implication: false only for 1 -> 0.
timpl(1, 0, 0) :- !.
timpl(_, _, 1).

% Iterative sum 1+...+N, independent of the closed formula under test.
iter_sum(0, 0) :- !.
iter_sum(N, R) :-
    N1 is N - 1,
    iter_sum(N1, R1),
    R is R1 + N.

% On the finite grid -5..4, no single Y exceeds every X.
grid_dominates(Y) :-
    numlist(-5, 4, Grid),
    member(Y, Grid),
    forall(member(X, Grid), Y > X).

% Epsilon-delta check for lim_{x->2} (3x+1) = 7, delta = eps/3.
% Sample points x = 2 + t*delta with rational t.
eps_delta_ok(E) :-
    D is E / 3,
    Ts = [-9 rdiv 10, -1 rdiv 2, 0, 3 rdiv 10, 89 rdiv 100],
    forall(member(T, Ts),
           (   X is 2 + T * D,
               abs(X - 2) < D
           ->  abs((3 * X + 1) - 7) < E
           ;   true)).

% Oversized delta = eps: there is a point inside the delta-neighbourhood
% whose image error is at least eps (the bound 1/3 is sharp).
oversized_violation(K) :-
    E = 1 rdiv 10,
    between(0, 1000, K),
    X is 2 - E + 2 * E * K rdiv 1000,
    abs(X - 2) < E,
    abs((3 * X + 1) - 7) >= E.

main :-
    format("==== 01 logic ====~n", []),

    % 1. Truth tables: De Morgan and contrapositive.
    verify(forall((member(A, [true, false]), member(B, [true, false])),
                  ( bv(A, Va), bv(B, Vb),
                    tor(Va, Vb, Or), tnot(Or, NOr),
                    tand(Va, Vb, And), tnot(And, NAnd),
                    tnot(Va, Na), tnot(Vb, Nb),
                    tand(Na, Nb, NamNb),
                    tor(Na, Nb, NaoNb),
                    timpl(Va, Vb, Imp),
                    timpl(Nb, Na, CImp),
                    NOr =:= NamNb,
                    NAnd =:= NaoNb,
                    Imp =:= CImp))),
    format("de Morgan and contrapositive: truth table verified~n", []),

    % 2. Quantifier order. Every integer has a successor y = x+1;
    %    no finite-grid element dominates all the others.
    verify(forall(between(-1000, 999, X), (Y is X + 1, Y > X))),
    verify_not(grid_dominates(_)),
    format("quantifier order: forall-exists true, exists-forall false~n", []),

    % 3. Sum formula 1+...+N = N(N+1)/2 checked for N = 1..100.
    verify(forall(between(1, 100, N),
                  (iter_sum(N, I), I =:= N * (N + 1) // 2))),
    format("sum formula checked for n = 1..100~n", []),

    % 4. Epsilon-delta with exact rational epsilons.
    Epss = [1 rdiv 10, 1 rdiv 100, 1 rdiv 1000],
    verify(forall(member(E, Epss), eps_delta_ok(E))),
    verify(oversized_violation(_)),
    format("epsilon-delta: delta = eps/3 works; delta = eps has a violation~n", []),

    % 5. Arbitrarily-close equality on a finite epsilon grid.
    X is sqrt(2),
    verify(forall(member(E, [1.0, 1e-6, 1e-12, 1e-15]),
                  abs(X - X) < E)),
    format("arbitrarily-close principle checked on finite epsilon grid~n", []),

    format("END ====~n", []).
