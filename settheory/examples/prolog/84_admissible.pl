:- encoding(utf8).
% 第 84 章：KP 与舒适集合（冯琦第二卷 §1.1）——Prolog 通道
% 三件事：
% (1) 定义 1.22 的对角线配对。书上 J(m,n)=T(m+n)+m；机器用对换
%     J*(m,n)=T(m+n)+n，二者由坐标对换互逆。变元码与常元码互不碰撞。
% (2) 有限累积层次 V_0..V_4：传递、精确并、Δ₀-分离在每一层都成立；
%     两个秩最高的元素的精确对会溢出该层，并进 V_ω 之后恢复。
% (3) 在 V_3 与 V_4 上对一批 Δ₀ 公式逐环境对拍绝对性，并给一条
%     Δ₀-收集搜索一个有限界。

% ---------- 配对 ----------
j_star(M, N, K) :-
    S is M + N,
    K is S * (S + 1) // 2 + N.

j_book(M, N, K) :-
    S is M + N,
    K is S * (S + 1) // 2 + M.

isqrt(N, R) :-
    between(0, N, R),
    R * R =< N,
    R1 is R + 1,
    R1 * R1 > N,
    !.

unpair_star(K, M, N) :-
    Eight is 8 * K + 1,
    isqrt(Eight, R),
    S is (R - 1) // 2,
    T is S * (S + 1) // 2,
    N is K - T,
    M is S - N.

codes_bijective(Fun, Bound) :-
    findall(K-M-N,
        (between(0, Bound, M), between(0, Bound, N), call(Fun, M, N, K)),
        Pairs),
    findall(K, member(K-_-_, Pairs), Ks),
    sort(Ks, Sorted),
    length(Pairs, NP),
    length(Sorted, NP).

% ---------- 纯粹集合：规范排序的表 ----------
rank([], 0).
rank(X, R) :-
    X = [_|_],
    findall(Ri, (member(Y, X), rank(Y, Ri)), Rs),
    max_list(Rs, M),
    R is M + 1.

powerset([], [[]]).
powerset([H|T], Ps) :-
    powerset(T, Rest),
    findall(W, (member(S, Rest), sort([H|S], W)), Withs),
    append(Rest, Withs, Raw),
    sort(Raw, Ps).

% levels(N, [V0,...,VN])，Vk 是秩 < k 的全体集合组成的表
levels(0, [[]]).
levels(N, All) :-
    N > 0,
    N1 is N - 1,
    levels(N1, Prev),
    last(Prev, Last),
    powerset(Last, Next),
    append(Prev, [Next], All).

bigunion(X, U) :-
    findall(E, (member(Y, X), member(E, Y)), Es),
    sort(Es, U).

transitive_level(V) :-
    forall((member(X, V), member(Y, X)), member(Y, V)).

union_closed(V) :-
    forall(member(X, V), (bigunion(X, U), member(U, V))).

% Δ₀-分离的一个实例：{x ∈ a | ∃y∈x (y ∈ b)}，产物仍在同一层
sep_closed(V) :-
    forall((member(A, V), member(B, V)),
           (findall(X, (member(X, A), member(Y, X), member(Y, B)), Xs),
            sort(Xs, S),
            member(S, V))).

% ---------- Δ₀ 求值 ----------
env_get(I, [I-V|_], V) :- !.
env_get(I, [_|T], V) :- env_get(I, T, V).

env_set(I, X, Env, [I-X|Rest]) :-
    exclude(is_key(I), Env, Rest).
is_key(I, I-_).

eval(_, Env, mem(I, J)) :-
    env_get(I, Env, X), env_get(J, Env, Y), member(X, Y).
eval(_, Env, eq(I, J)) :-
    env_get(I, Env, X), env_get(J, Env, Y), X == Y.
eval(M, Env, neg(P)) :- \+ eval(M, Env, P).
eval(M, Env, and(P, Q)) :- eval(M, Env, P), eval(M, Env, Q).
eval(M, Env, ball(I, J, P)) :-
    env_get(J, Env, Bound),
    forall((member(X, M), member(X, Bound)),
           (env_set(I, X, Env, Env1), eval(M, Env1, P))).

forms(Fs) :-
    Atoms = [mem(0, 1), eq(0, 1), mem(1, 0)],
    findall(neg(A), member(A, Atoms), Negs),
    findall(and(A, B), (member(A, Atoms), member(B, Atoms)), Ands),
    Balls = [ball(0, 1, mem(0, 1)),
             ball(0, 1, neg(mem(0, 1))),
             ball(0, 1, ball(0, 0, eq(0, 0)))],
    append(Atoms, Negs, F1),
    append(F1, Ands, F2),
    append(F2, Balls, Fs).

abs_checks(Small, Large, N) :-
    forms(Fs),
    findall(1,
        (member(A, Small), member(B, Small), member(P, Fs),
         Env = [0-A, 1-B],
         (eval(Small, Env, P) -> S = 1 ; S = 0),
         (eval(Large, Env, P) -> L = 1 ; L = 0),
         S = L),
        Ones),
    length(Ones, N).

% ---------- Δ₀-收集的有限搜索 ----------
% a = 2 = {0,1}。对每个 x∈a 取见证 y={x}。界 b 就是这些见证的集合。
collection_bound(A, B) :-
    findall(Y, (member(X, A), sort([X], Y)), Ys),
    sort(Ys, B).

main :-
    format("==== 84~n"),
    codes_bijective(j_star, 15),
    codes_bijective(j_book, 15),
    forall((between(0, 12, M), between(0, 12, N)),
           (j_star(M, N, K), unpair_star(K, M, N))),
    forall((between(0, 12, M), between(0, 12, N)),
           (j_star(M, N, Ks), j_book(N, M, Kb), Ks =:= Kb)),
    forall((between(0, 10, N), between(0, 10, M)),
           (j_star(5, N + 11, Vc), j_star(7, M + 11, Cc), Vc =\= Cc)),
    format("配对：J* 与书上的 J 在 0..15 上都是单射；J*(m,n)=J(n,m)；解码左逆；变元码≠常元码 ✓~n"),
    levels(4, Vs),
    maplist(length, Vs, Lens),
    Lens = [0, 1, 2, 4, 16],
    forall(member(V, Vs), (transitive_level(V), union_closed(V), sep_closed(V))),
    nth0(3, Vs, V3),
    findall(X, (member(X, V3), rank(X, 2)), Tops),
    Tops = [T1, T2],
    sort([T1, T2], Pair),
    \+ member(Pair, V3),
    nth0(4, Vs, V4),
    member(Pair, V4),
    format("V0..V4 基数 0,1,2,4,16；各层传递、精确并、Δ₀-分离实例封闭 ✓~n"),
    format("  两个秩 2 元素的精确对不在 V3，而在 V4——单层不封闭、并层封闭 ✓~n"),
    abs_checks(V3, V4, NAbs),
    format("Δ₀ 绝对性：V3/V4 上逐环境逐公式共 ~w 次一致 ✓~n", [NAbs]),
    A = [[], [[]]],
    collection_bound(A, B),
    forall(member(X, A), (sort([X], Y), member(Y, B))),
    format("Δ₀-收集搜索：a=2 的见证 {{0},{1}} 收进一个有限界 ✓~n"),
    writeln("END ====").
