:- encoding(utf8).
% 第 09 章 Prolog：有限良序集的判定与同构搜索。
% 约定：related(R, X, Y) 即 (X,Y) ∈ R，读作"X 在 Y 之后"（Y < X）。
% ① 良序判定：连接 + 反对称 + 传递 + 每个非空子集有最小元（穷举）；
% ② 前段：链的全部真前段恰是各 W[a]（引理 4.1.2）；
% ③ 序同构的搜索与唯一性（4.1.5(3)）；
% ④ 增函数引理 4.1.4 的穷举（全部递增映射满足 f(a) ≥ a）。

% ---------- ① 良序判定 ----------
related(R, X, Y) :- member((X, Y), R).

connex(R, U) :-
    \+ (member(X, U), member(Y, U), X \= Y,
        \+ related(R, X, Y), \+ related(R, Y, X)).

antisym(R) :- \+ (member((X, Y), R), member((Y, X), R), X \= Y).

transitive(R) :-
    \+ (member((X, Y), R), member((Y, Z), R), \+ member((X, Z), R)).

subselect([], []).
subselect([H|T], [H|S]) :- subselect(T, S).
subselect([_|T], S) :- subselect(T, S).

has_least(R, U) :-
    \+ (subselect(U, S), S \= [],
        \+ (member(Z, S), \+ (member(W, S), related(R, W, Z)))).

wellorder(R, U) :-
    connex(R, U), antisym(R), transitive(R), has_least(R, U).

check_wellorder :-
    U = [0, 1, 2],
    R = [(1, 0), (2, 1), (2, 0)],                       % 0 < 1 < 2
    wellorder(R, U),
    \+ wellorder([(1, 0)], U),                          % 缺连接：不是线序
    \+ wellorder([(1, 0), (0, 1)], [0, 1]),             % 反对称破坏
    format("wellorder check: chain 0<1<2 is wellorder, broken ones rejected: OK~n").

% ---------- ② 前段（引理 4.1.2） ----------
proper_initial(R, U, S) :-
    member(A, U),
    findall(X, (member(X, U), X \= A, related(R, A, X)), S0),
    sort(S0, S).

check_segments :-
    U = [0, 1, 2],
    R = [(1, 0), (2, 1), (2, 0)],
    findall(S, proper_initial(R, U, S), Segs),
    Segs == [[], [0], [0, 1]],                          % 真前段恰是 W[a]
    format("segments: proper initial segments are exactly W[a]: OK~n").

% ---------- ③ 同构搜索与唯一性（4.1.5(3)） ----------
pairs_of([], _, []).
pairs_of([H|T], U2, M) :-
    select(X, U2, Rest),
    pairs_of(T, Rest, M0),
    M = [H-X | M0].

order_preserving([], _, _).
order_preserving([_], _, _).
order_preserving([A-X, B-Y | Rest], R1, R2) :- !,
    (related(R1, B, A) -> related(R2, Y, X) ; true),   % B 在 A 后 ⟹ 像也在后
    order_preserving([B-Y | Rest], R1, R2).

iso_map(R1, U1, R2, U2, M) :-
    length(U1, N), length(U2, N),
    pairs_of(U1, U2, M),                                % M 本身就是一个双射
    order_preserving(M, R1, R2).

check_iso :-
    U1 = [a, b, c], R1 = [(b, a), (c, b), (c, a)],      % a < b < c
    U2 = [3, 2, 1], R2 = [(2, 3), (1, 2), (1, 3)],      % 3 < 2 < 1
    findall(M, iso_map(R1, U1, R2, U2, M), Ms),
    Ms = [[a-3, b-2, c-1]],                             % 同构存在且唯一
    \+ iso_map(R1, U1, [(9, 8)], [9, 8], _),            % 长度不同：无同构
    format("iso search: unique isomorphism, none across sizes: OK~n").

% ---------- ④ 增函数引理 4.1.4 的穷举 ----------
map_from([], _, []).
map_from([H|T], Vals, [H-V | M]) :-
    member(V, Vals), map_from(T, Vals, M).

increasing(R, M) :-
    \+ (member(A-X, M), member(B-Y, M),
        A \= B, related(R, B, A), \+ (X < Y)).          % A 在 B 前 ⟹ 值也前

check_increasing :-
    U = [0, 1, 2], R = [(1, 0), (2, 1), (2, 0)],
    findall(M, (map_from(U, [0, 1, 2, 3], M), increasing(R, M)), Ms),
    length(Ms, 4),                                      % 链源：递增映射由值组唯一决定 C(4,3)=4
    forall(member(M, Ms),
           \+ (member(A-V, M), related(R, A, V))),      % ¬(f(a) < a)
    length(Ms, Cnt),
    format("increasing maps: all ~w maps satisfy f(a) >= a: OK~n", [Cnt]).

main :-
    format("==== 09 wellorders~n"),
    check_wellorder,
    check_segments,
    check_iso,
    check_increasing,
    format("END ====~n"), !.

:- initialization(main).
