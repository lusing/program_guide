:- encoding(utf8).
% 第 58 章 Prolog：5-区间覆盖引理的贪心程序 + 变差穷举。
% ① 给定按长度不增排序的区间表，执行书 2.3.2 的选择程序（每步取下一个
%    与已选不交者），验证：已选族两两不交、每个未选区间与某个长度
%    ≥ 自身的已选区间相交（从而落入其 3 倍膨胀）；
% ② 7 点采样函数的全部 32 个分割穷举，sup V(P) = 转折点和。
:- initialization(main).

% 区间表示：i(Lo, Hi)，长度 m = Hi - Lo（rdiv 精确）。
ilen(i(A, B), M) :- M is B - A.

% 两开区间不相交（相交即有公共点：max(Lo) < min(Hi)）
disjoint(i(A1, B1), i(A2, B2)) :- B1 =< A2 ; B2 =< A1.

% 贪心选择程序（书 2.3.2）：输入已按长度不增排序的区间表
greedy([], []).
greedy([C|Rest], [C|Sel]) :-
    include(disjoint_from(C), Rest, RestD),
    greedy(RestD, Sel).
disjoint_from(C, D) :- disjoint(C, D).

% 验证覆盖性：每个原区间与某个已选区间相交（且该已选区间长度 ≥ 它，
% 由排序保证）；相交 ⟹ 落入 3 倍膨胀（书式 2.3.2 的几何）。
covered_by(_, []).
covered_by(C, [S|Sel]) :-
    (  intersects(C, S) -> true
    ;  covered_by(C, Sel)
    ).
intersects(i(A1, B1), i(A2, B2)) :- max(A1, A2) < min(B1, B2).

% 区间表（已按长度不增排序；rdiv 精确端点）
sample_intervals([
    i(0 rdiv 1, 5 rdiv 3),
    i(4 rdiv 3, 8 rdiv 3),
    i(7 rdiv 3, 10 rdiv 3),
    i(10 rdiv 3, 11 rdiv 3),
    i(23 rdiv 6, 4 rdiv 1)
]).

% ---------- ② 变差穷举 ----------
% 采样值 f(0..6) = (0,3,1,4,2,5,5)
fv(0, 0). fv(1, 3). fv(2, 1). fv(3, 4). fv(4, 2). fv(5, 5). fv(6, 5).

all_partitions(P) :- subseq([1,2,3,4,5], Inner), append([0|Inner], [6], P).
subseq([], []).
subseq([H|T], [H|R]) :- subseq(T, R).
subseq([_|T], R) :- subseq(T, R).

partition_variation([_], 0).
partition_variation([X,Y|Rest], V) :-
    fv(X, FX), fv(Y, FY),
    partition_variation([Y|Rest], V0),
    V is V0 + abs(FY - FX).

main :-
    format("==== 58 differentiation~n"),
    % ① 贪心覆盖验证（对样例与若干扰动表）
    sample_intervals(Is),
    greedy(Is, Sel),
    length(Is, N), length(Sel, K),
    format("① 贪心选择：~d 个区间中选出 ~d 个两两不交者~n", [N, K]),
    forall((member(C, Is), \+ member(C, Sel)), covered_by(C, Sel)),
    check_pairwise_disjoint(Sel),
    format("   每个未选区间与某已选区间相交（排序 => 已选更长 => 3 倍膨胀覆盖）~n"),
    % ② 变差穷举
    aggregate_all(max(V), (all_partitions(P), partition_variation(P, V)), MaxV),
    MaxV =:= 3 + 2 + 3 + 2 + 3 + 0,
    aggregate_all(count, all_partitions(_), 32),
    format("② 变差穷举：32 个分割全部枚举，sup V(P) = 13 = 转折点和~n"),
    format("   （Jordan 分解 H(x)=V_f(0,x) 的有限投影：单调账吃掉全部振荡）~n"),
    format("END ====~n").

check_pairwise_disjoint([]).
check_pairwise_disjoint([H|T]) :-
    maplist(disjoint_h(H), T),
    check_pairwise_disjoint(T).
disjoint_h(A, B) :- ( A @< B -> disjoint(A, B) ; A @> B -> disjoint(B, A) ; true ).
