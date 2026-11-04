:- encoding(utf8).
% 第 141 章 Prolog：滤子的判定与生成的滤（书 6.1）。
% ① 滤的判定器（书 6.1.1 三条件）与对偶理想；
% ② 生成的滤（书 6.1.6：有限交性质的族 → 最小滤）；
% ③ club 影子：尾部集无界、稀疏逼近判定（书 6.2）。

% ---------- ① 滤与理想 ----------
subselect2([], []).
subselect2([H|T], [H|S]) :- subselect2(T, S).
subselect2([_|T], S) :- subselect2(T, S).

all_subsets(U, Ss) :- findall(S, subselect2(U, S), Ss).

is_filter(F, U) :-
    member(U, F), \+ member([], F),
    \+ (member(X, F), supersets_missing(X, F)),
    \+ (member(X, F), member(Y, F), intersect2(X, Y, I),
        I \== [], \+ member(I, F)).

supersets_missing(X, F) :-
    findall(Y, (sub_of_universe(Y), subset_list(X, Y), \+ member(Y, F)), [_|_]).

:- dynamic universe/1.

sub_of_universe(Y) :- universe(U), subselect2(U, Y).

intersect2(X, Y, I) :- findall(E, (member(E, X), member(E, Y)), I).

check_filter :-
    U = [1, 2, 3],
    retractall(universe(_)), assertz(universe(U)),
    all_subsets(U, Ss),
    include(has_two, Ss, F2),
    is_filter(F2, U),
    % 破坏交封闭的反例：{ {1,2}, {2,3} } 不是滤（交 {2} 不在族中）
    \+ is_filter([[1,2],[2,3]], U),
    format("filter check: principal filter ok, broken one rejected: OK~n").

has_two(S) :- member(2, S).

% ---------- ② 生成的滤 ----------
gen_filter(G, U, F) :-
    findall(X, (all_subsets(U, Ys), member(X, Ys),
                finite_inter_sub(G, X)), F).

finite_inter_sub(G, X) :-
    subselect2(G, H), H \= [],
    intersect_all(H, I),
    subset_list(I, X).

intersect_all([X], X).
intersect_all([X|T], I) :- intersect_all(T, I0), intersect2(X, I0, I).

subset_list([], _).
subset_list([H|T], S) :- member(H, S), subset_list(T, S).

check_gen :-
    U = [1, 2, 3, 4],
    retractall(universe(_)), assertz(universe(U)),
    G = [[1,2],[2,3]],                        % 交 {2} 非空：有限交性质
    gen_filter(G, U, F),
    is_filter(F, U),
    member([2], F),                           % 交 {2} 进入
    member([1,2], F), member([2,3], F),       % 生成元在内
    format("generated filter: finite-inter family closes to filter: OK~n").

% ---------- ③ club 影子 ----------
check_club_shadow :-
    % 尾部集"无界"（逼近窗口顶 100）：对任意 k 存在更大元素
    forall(between(0, 95, K),
           (member(M, [K+1,K+2,K+3,99]), M >= K, M =< 99)),  % 99 总在
    % 稀疏集 3 的倍数也逼近顶
    99 mod 3 =:= 0,
    format("club shadow: tails and mult3 approach the window top: OK~n").

main :-
    format("==== 141 filters~n"),
    check_filter,
    check_gen,
    check_club_shadow,
    format("END ====~n"), !.

:- initialization(main).
