:- encoding(utf8).
% Chapter 02 set theory: Prolog channel.
% Finite-universe union/intersection/complement and De Morgan,
% the open-interval gap at 3, and truncated indexed interval families.
% Run: swipl -q -f 02_sets.pl -g main -t halt

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

% Set operations on unordered lists (no duplicates in the inputs).
munion([], B, B).
munion([H | T], B, R) :-
    memberchk(H, B),
    !,
    munion(T, B, R).
munion([H | T], B, [H | R]) :-
    munion(T, B, R).

minter([], _, []).
minter([H | T], B, [H | R]) :-
    memberchk(H, B),
    !,
    minter(T, B, R).
minter([_ | T], B, R) :-
    minter(T, B, R).

mcomp([], _, []).
mcomp([H | T], A, R) :-
    memberchk(H, A),
    !,
    mcomp(T, A, R).
mcomp([H | T], A, [H | R]) :-
    mcomp(T, A, R).

msubset(A, B) :-
    forall(member(X, A), memberchk(X, B)).

mseteq(A, B) :-
    msubset(A, B),
    msubset(B, A).

% Elements of the open interval (A, B) intersected with a rational grid.
open_int(Grid, A, B, R) :-
    findall(X, (member(X, Grid), X > A, X < B), R).

main :-
    format("==== 02 sets ====~n", []),

    % 1. Finite universe U = {1,...,9}.
    numlist(1, 9, U),
    A = [1, 3, 5, 7],
    B = [2, 3, 4, 7],
    mcomp(U, A, CA),
    mcomp(U, B, CB),
    munion(A, B, AB),
    minter(A, B, AcapB),
    verify(msubset(A, AB)),
    verify(msubset(AcapB, A)),
    verify(msubset([], A)),
    % A is not a subset of B, so the union is not absorbed by B.
    verify_not(msubset(A, B)),
    verify_not(mseteq(AB, B)),
    % For a nested pair C subset B both absorption laws hold.
    C = [3, 7],
    verify(msubset(C, B)),
    munion(C, B, CBu),
    verify(mseteq(CBu, B)),
    minter(C, B, CcB),
    verify(mseteq(CcB, C)),
    % De Morgan, both directions.
    mcomp(U, AB, C1),
    minter(CA, CB, C2),
    verify(mseteq(C1, C2)),
    mcomp(U, AcapB, C3),
    munion(CA, CB, C4),
    verify(mseteq(C3, C4)),
    format("finite-universe De Morgan verified~n", []),

    % 2. The gap: 3 is missing from (1,3) union (3,5) on a quarter grid.
    findall(X, (between(0, 16, K), X is 1 + K rdiv 4), Grid),
    open_int(Grid, 1, 3, I1),
    open_int(Grid, 3, 5, I2),
    munion(I1, I2, Gap),
    open_int(Grid, 1, 5, Full),
    verify(\+ memberchk(3, Gap)),
    verify(memberchk(3, Full)),
    format("open intervals: point 3 is the gap~n", []),

    % 3. Truncated A_n = (-1/(n+1), 1/(n+1)), n = 0..100.
    findall(L, (between(0, 100, N), L is -(1 rdiv (N + 1))), Los),
    findall(H, (between(0, 100, N), H is 1 rdiv (N + 1)), His),
    min_list(Los, LoMin),
    max_list(His, HiMax),
    verify(LoMin =:= -1),
    verify(HiMax =:= 1),
    format("A_n truncated union bounds: (~w, ~w)~n", [LoMin, HiMax]),

    % 4. Truncated B_n = [0, 2 - 1/(n+1)]: supremum stays below 2,
    %    the truncated intersection is B_0 = [0,1].
    findall(R, (between(0, 100, N), R is 2 - 1 rdiv (N + 1)), Rights),
    max_list(Rights, Rmax),
    min_list(Rights, Rmin),
    verify(Rmax < 2),
    verify(Rmax =:= 2 - 1 rdiv 101),
    verify(Rmin =:= 1),
    format("B_n truncated sup = ~w (< 2), truncated intersection ends at ~w~n",
           [Rmax, Rmin]),

    % 5. Indexed-family De Morgan on three finite sets.
    E = [[1, 2], [2, 3], [4, 5]],
    foldl(munion, E, [], Eunion),
    mcomp(U, Eunion, D1),
    maplist(mcomp(U), E, Comps),
    foldl(minter, Comps, U, D2),
    verify(mseteq(D1, D2)),
    format("indexed-family De Morgan verified~n", []),

    format("END ====~n", []).
