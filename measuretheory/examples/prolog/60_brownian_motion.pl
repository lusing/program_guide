:- encoding(utf8).
% 第 60 章 Prolog：反射原理的路径级双射验证（n ≤ 12）。
% ① 触顶镜像：对每条"触 a 且 S_n < a"的路径，找到首触时刻，其后每步取反，
%    得到一条"S_n > a"的路径；变换为对合（两次镜像复原）；
% ② 计数对账：两侧集合大小相等 = 尾二项和；
% ③ 极大等式：#{max ≥ a} = #{S_n ≥ a} + #{S_n > a}。
:- initialization(main).

step(1). step(-1).

% 路径的部分和（正序）
partial_sums(Xs, Sums) :- psums(Xs, 0, Sums).
psums([], _, []).
psums([X|Xs], Acc, [S|Rest]) :- S is Acc + X, psums(Xs, S, Rest).

% 路径性质
touch(Seq, A) :- partial_sums(Seq, Sums), max_list([0|Sums], M), M >= A.
ends_below(Seq, A) :- partial_sums(Seq, Sums), last(Sums, S), S < A.
ends_above(Seq, A) :- partial_sums(Seq, Sums), last(Sums, S), S > A.
ends_ge(Seq, A) :- partial_sums(Seq, Sums), last(Sums, S), S >= A.

% 首触时刻（1 基）
first_hit(Seq, A, T) :-
    partial_sums(Seq, Sums),
    nth1(T, Sums, A),                % S_T = a
    T1 is T - 1,
    ( T1 == 0 -> true
    ; prefix_max_lt(Sums, T1, A) ).  % 前 T−1 步严格低于 a
prefix_max_lt(_, 0, _).
prefix_max_lt([S|Rest], K, A) :-
    K > 0, S < A, K1 is K - 1, prefix_max_lt(Rest, K1, A).

% 镜像变换：首触 a 之后每步取反
reflect(Seq, A, Refl) :-
    first_hit(Seq, A, T),
    split_at(T, Seq, Pre, Post),
    maplist(negate, Post, PostN),
    append(Pre, PostN, Refl).
negate(1, -1). negate(-1, 1).
split_at(0, L, [], L) :- !.
split_at(N, [H|T], [H|Pre], Post) :- N1 is N - 1, split_at(N1, T, Pre, Post).

% 双射验证：源集每条路径的像落在目标集，且变换为对合
check_bijection(N, A) :-
    findall(Seq, (length(Seq, N), maplist(step, Seq), touch(Seq, A),
                  ends_below(Seq, A)), Src),
    maplist([S, R]>>reflect(S, A, R), Src, Img),
    forall(member(R, Img), (ends_above(R, A), touch(R, A))),
    maplist([S, S2]>>(reflect_then_recheck(S, A, S2)), Src, SrcBack),
    forall((nth1(I, SrcBack, S2), nth1(I, Src, S1)), S1 == S2).

reflect_then_recheck(Seq, A, Back) :-
    reflect(Seq, A, R1),
    reflect(R1, A, Back0),       % R1 终点 > a，其"首触 a"同刻，再镜像复原
    !, Back = Back0.

% 计数对账
count_touch_below(N, A, C) :-
    aggregate_all(count, (length(Seq, N), maplist(step, Seq),
                          touch(Seq, A), ends_below(Seq, A)), C).
count_ends_above(N, A, C) :-
    aggregate_all(count, (length(Seq, N), maplist(step, Seq),
                          ends_above(Seq, A)), C).
count_max_ge(N, A, C) :-
    aggregate_all(count, (length(Seq, N), maplist(step, Seq), touch(Seq, A)), C).
count_ends_ge(N, A, C) :-
    aggregate_all(count, (length(Seq, N), maplist(step, Seq), ends_ge(Seq, A)), C).

main :-
    format("==== 60 brownian_motion~n"),
    forall(member((N, A), [(8, 2), (10, 2), (12, 3)]),
           (check_bijection(N, A),
            count_touch_below(N, A, C1),
            count_ends_above(N, A, C2),
            C1 =:= C2,
            format("   n=~d a=~d：镜像双射成立，两侧计数 = ~d~n", [N, A, C1]))),
    format("① 反射是路径级对合双射（触顶后终点低于 a ↔ 终点高于 a）~n"),
    forall(member((N, A), [(4, 2), (8, 2), (12, 3)]),
           (count_max_ge(N, A, CM),
            count_ends_ge(N, A, CG),
            count_ends_above(N, A, CA),
            CM =:= CG + CA,
            format("   n=~d a=~d：#(max>=a) = ~d = ~d + ~d   (#S_n>=a + #S_n>a)~n",
                   [N, A, CM, CG, CA]))),
    format("② 极大等式精确成立；连续极限（原子消失）即 P(max>=λ)=2P(B>=λ)~n"),
    format("END ====~n").
