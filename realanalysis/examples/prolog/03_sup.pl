:- encoding(utf8).
% Chapter 03 supremum: Prolog channel.
% q-iteration toward sqrt(2) with exact rationals, finite max = sup,
% and truncated sup of {1 - 1/(n+1)}.
% Run: swipl -q -f 03_sup.pl -g main -t halt

verify(G) :-
    (   call(G)
    ->  true
    ;   format("FAILED: ~w~n", [G]),
        fail
    ).

% q = (2p+2)/(p+2). The two book identities:
%   q - p = (2 - p^2)/(p+2),  q^2 - 2 = 2(p^2 - 2)/(p+2)^2.
qstep(P, Q) :-
    Q is (2 * P + 2) rdiv (P + 2).

identities(P) :-
    qstep(P, Q),
    Q - P =:= (2 - P * P) rdiv (P + 2),
    Q * Q - 2 =:= (2 * (P * P - 2)) rdiv ((P + 2) * (P + 2)).

qstep_checked(P, Q) :-
    identities(P),
    qstep(P, Q),
    Q > P,
    Q * Q < 2.

% Dual direction: from a point with square > 2, the same q is smaller.
qstep_down(P, Q) :-
    identities(P),
    qstep(P, Q),
    Q > 0,
    Q < P,
    Q * Q > 2.

% Iterate K times from 1/1, collecting the trajectory.
qtrajectory(K, Traj) :-
    qtraj_go(K, [1 rdiv 1], Traj).

qtraj_go(0, T, T) :- !.
qtraj_go(K, [P | Rest], Traj) :-
    K > 0,
    K1 is K - 1,
    qstep_checked(P, Q),
    qtraj_go(K1, [Q, P | Rest], Traj).

% max / min of a list of rationals (fold).
rmax([X], X) :- !.
rmax([X | Xs], M) :-
    rmax(Xs, M0),
    M is max(X, M0).

rmin([X], X) :- !.
rmin([X | Xs], M) :-
    rmin(Xs, M0),
    M is min(X, M0).

% Eight downward steps from 2/1.
qdown(K, Traj) :-
    qdown_go(K, [2 rdiv 1], Traj).

qdown_go(0, T, T) :- !.
qdown_go(K, [P | Rest], Traj) :-
    K > 0,
    K1 is K - 1,
    qstep_down(P, Q),
    qdown_go(K1, [Q, P | Rest], Traj).

main :-
    format("==== 03 sup ====~n", []),

    % 1. q-iteration: 8 checked steps.
    verify(qtrajectory(8, TrajRev)),
    reverse(TrajRev, Traj),
    last(Traj, P8),
    verify(P8 * P8 < 2),
    Gap is 2 - P8 * P8,
    format("p_8^2 = ~w, gap 2-p^2 = ~w~n", [P8 * P8, Gap]),

    % 2. Finite set: sup = max, and max is an upper bound member.
    verify(rmax(Traj, M)),
    last(Traj, Last),
    verify(M =:= Last),
    verify(forall(member(T, Traj), T =< M)),
    format("finite trajectory: max = last = ~w (monotone)~n", [M]),

    % 3. Truncated sup of {1 - 1/(n+1)} at N = 100.
    findall(V, (between(0, 100, N), V is 1 - 1 rdiv (N + 1)), Vs),
    verify(rmax(Vs, Vmax)),
    verify(Vmax =:= 1 - 1 rdiv 101),
    verify(Vmax < 1),
    format("truncated sup at N=100: ~w < 1~n", [Vmax]),

    % Archimedean witness: n = floor(1/eps) + 1 makes 1-1/(n+1) > 1-eps.
    Eps = 1 rdiv 1000000,
    N0 is floor(1 / float(Eps)) + 1,
    verify(1 - 1 rdiv (N0 + 1) > 1 - Eps),
    format("archimedean witness for eps=1/10^6: n = ~w~n", [N0]),

    % 4. Dual iteration: B has no least element.
    verify(qdown(8, DownRev)),
    reverse(DownRev, Down),
    last(Down, Q8),
    GapUp is Q8 * Q8 - 2,
    format("downward p_8^2 - 2 = ~w~n", [GapUp]),

    % 5. Example 4.8: truncated {1/(n+1)}. Sup is attained (equals 1),
    %    inf of the truncation is the last term, still positive.
    findall(V, (between(0, 100, N), V is 1 rdiv (N + 1)), Ones),
    verify(rmax(Ones, Omax)),
    verify(rmin(Ones, Omin)),
    verify(Omax =:= 1 rdiv 1),
    verify(Omin =:= 1 rdiv 101),
    verify(Omin > 0),
    format("truncated {1/(n+1)}: max = ~w, min = ~w > 0~n", [Omax, Omin]),

    % Midpoint: any rational gamma < 3 fails to be an upper bound.
    Gamma = 5 rdiv 2,
    Mid is (Gamma + 3) rdiv 2,
    verify(Gamma < Mid),
    verify(Mid < 3),

    format("END ====~n", []).
