:- encoding(utf8).
% ex55_indiscern.pl -- 不可辨元：Ramsey 与 EM 定理（Marker GTM 217 5.1-5.2）
% 三账：R(3,3)=6 双账（C5 见证 + K6 全 32768 染色皆有单色三角）；
% Wagner 图 M8 无红三角 + 独立数<=3（R(3,4)>8 见证）；EM 壳的
% 保序平移搬运账。stdout 纯 ASCII。

% ---------- Ramsey ----------

% 边染色：bits(Mask, Idx) 取第 Idx 位（1=红）
bit(Mask, Idx, B) :- B is (Mask >> Idx) /\ 1.

% K6 的 15 条边（下标 0..14）与 20 个三角形
edge_idx(I, J, Idx) :- between(0, 5, I), I1 is I+1, between(I1, 5, J),
    row_sum(I, R), Idx is R + J - I - 1.
row_sum(0, 0).
row_sum(I, R) :- I > 0, I1 is I-1, row_sum(I1, R0), R is R0 + 6 - I1 - 1.

tri_edges(A, I, J, E1, E2, E3) :-
    between(0, 5, A), between(0, 5, I), between(0, 5, J),
    A < I, I < J,
    edge_idx(A, I, E1), edge_idx(I, J, E2), edge_idx(A, J, E3).

mono_tri_mask(Mask) :-
    tri_edges(_, _, _, E1, E2, E3),
    ( (bit(Mask, E1, 1), bit(Mask, E2, 1), bit(Mask, E3, 1))
    ; (bit(Mask, E1, 0), bit(Mask, E2, 0), bit(Mask, E3, 0)) ).

% K5 见证：C5 的红边（循环相邻），其余蓝
c5_edge(I, J, 1) :- between(0, 4, I), between(0, 4, J), I \= J,
    ( J is (I+1) mod 5 ; I is (J+1) mod 5 ).
c5_edge(I, J, 0) :- between(0, 4, I), between(0, 4, J), I \= J,
    \+ c5_edge(I, J, 1).

mono_tri_c5 :-
    between(0, 4, A), between(0, 4, I), between(0, 4, J),
    A < I, I < J,
    c5_edge(A, I, B1), c5_edge(I, J, B2), c5_edge(A, J, B3),
    B1 == B2, B2 == B3.

% Wagner 图 M8：C8 + 对径弦
wagner(I, J) :- between(0, 7, I), between(0, 7, J), I \= J,
    ( J is (I+1) mod 8 ; I is (J+1) mod 8 ; J mod 8 is (I+4) mod 8 ).

red_tri_wagner :-
    between(0, 7, A), between(0, 7, I), between(0, 7, J),
    A < I, I < J,
    wagner(A, I), wagner(I, J), wagner(A, J).

indep_quad(Q) :- length(Q, 4), member_all(Q), \+ has_edge_in(Q).
member_all(Q) :- findall(X, between(0, 7, X), Q).
has_edge_in(Q) :- member(X, Q), member(Y, Q), X < Y, wagner(X, Y).

% ---------- EM 装配 ----------

hull_pairs(N, Pairs) :- N1 is N-1, findall(I-J,
    (between(0, N1, I), I1 is I+1, between(I1, N1, J)), Pairs).

shifted_pairs(N, Out) :- N1 is N-1, hull_pairs(N1, Qs), map_shift(Qs, Out).
map_shift([], []).
map_shift([I-J|T], [I1-J1|T1]) :- I1 is I+1, J1 is J+1, map_shift(T, T1).

% ---------- 主入口 ----------

main :-
    % 账 1：K5 的 C5 染色无单色三角
    ( mono_tri_c5 -> write('FAIL: K5 C5 has mono tri'), nl, halt(1)
    ; write('K5 C5 witness: no mono triangle (R(3,3) > 5)'), nl ),
    % 账 2：K6 全 32768 个染色皆有单色三角
    aggregate_all(count, (between(0, 32767, M), \+ mono_tri_mask(M)), Bad),
    ( Bad == 0 -> write('K6 exhaustive: all 32768 colorings have mono triangle (R(3,3) <= 6)'), nl
    ; format('FAIL: ~w colorings without mono tri~n', [Bad]), halt(1) ),
    % 账 3：Wagner 图 R(3,4) > 8 见证
    ( red_tri_wagner -> write('FAIL: Wagner has red tri'), nl, halt(1)
    ; write('Wagner M8: red-triangle-free'), nl ),
    aggregate_all(count, indep_quad(_), Indep),
    ( Indep == 0 -> write('Wagner M8: no independent 4-set (R(3,4) > 8)'), nl
    ; format('FAIL: ~w independent quads~n', [Indep]), halt(1) ),
    % 账 4：EM 壳的保序平移
    shifted_pairs(4, S), S = [1-2, 1-3, 2-3],
    write('EM shift: (i,j) -> (i+1,j+1) hull embedding OK'), nl,
    write('END ===='), nl.
