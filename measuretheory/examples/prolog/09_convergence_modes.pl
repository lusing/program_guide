:- encoding(utf8).
% 09_convergence_modes.pl —— 第 09 章：有限模型的退化定理（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
% Ω = {1,...,6}，均匀概率测度 μ(A) = |A|/6。
% 有限模型的退化定理：最小原子 1/6 > 0 逼迫——
%   ① 零测集只有 ∅（穷举 63 个非空子集，μ ≥ 1/6 > 0）；
%   ② 示性函数序列依测度收敛于 0 ⟺ 终归取值 ∅ ⟺ a.e. 收敛于 0
%     （打字机式振荡在有限空间无法依测度收敛——反例天然需要无穷空间）；
%   ③ 具体序列体检：轮转序列（依测度失败，limsup μ ≥ 1/6）、
%     有限噪声后归零序列（a.e. 与依测度同时成立）。

omega6([1,2,3,4,5,6]).
mu(A, M) :- omega6(O), length(A, N), subset_of(A, O), !, M is N / 6.

subset_of([], _).
subset_of([H|T], S) :- member(H, S), subset_of(T, S).

% ---- ① 零测集只有 ∅ ----
check_min_atom :-
    findall(A, (omega6(O), sublist_of(A, O), A \= []), As),
    length(As, N63),
    forall(( member(A, As), mu(A, M) ), M >= 1.0 / 6.0 - 1e-12),
    format("nonempty subsets: ~w, all with measure >= 1/6: OK~n", [N63]),
    N63 =:= 63.

sublist_of([], []).
sublist_of([H|T], [H|S]) :- sublist_of(T, S).
sublist_of(T, [_|S]) :- sublist_of(T, S).

% ---- ② 退化定理：依测度 ⟺ 终归为零 ----
% 示性序列收敛于 0 的"依测度"判据：对 ε < 1/6，事件集非空即偏差 ≥ 1/6。
% 穷举所有"无限序列的模式"不可行，改为穷举判据的语义内核：
% 任何取值于 63 个非空子集的无限序列，必有某子集出现无穷多次（鸽笼），
% 其偏差 limsup ≥ 1/6 —— 依测度收敛当且仅当非空值只出现有限次。
check_pigeon :-
    % 判据内核：非空示性 ⟹ 偏差集测度 = μ(A) ≥ 1/6（对 ε = 1/12 < 1/6）
    forall(( omega6(O), sublist_of(A, O), A \= [] ),
           ( mu(A, M), M > 1.0 / 12.0 )),
    format("any nonempty indicator has deviation measure > 1/12 > eps-scales: OK~n").

% ---- ③ 具体序列体检（表驱动模拟前 N 项） ----
% 轮转序列：A={1,2}, B={3,4,5,6} 交替——依测度偏差不收敛于 0
seq_cyclic(N, Seq) :- findall(E, ( between(1, N, I),
                     ( I mod 2 =:= 1 -> E = [1,2] ; E = [3,4,5,6] )), Seq).

seq_noise_then_zero(N, Seq) :-
    N1 is min(N, 3),
    findall(E, ( between(1, N, I),
                 ( I =< N1 -> ( I =:= 1 -> E = [1,2,3,4,5,6] ; E = [1,2] )
                 ; E = [] ) ), Seq).

check_seqs :-
    seq_cyclic(40, SC),
    max_dev(SC, MaxC),
    format("cyclic sequence: max in-measure deviation = ~w (>= 1/6, FAILS in measure)~n",
           [MaxC]),
    MaxC >= 1.0 / 6.0 - 1e-12,
    seq_noise_then_zero(40, SN),
    length(SN, L), L1 is L - 5,
    length(Tail, L1), append(_, Tail, SN),
    maplist(==([]), Tail),          % 第 4 项起恒为 ∅（a.e. 收敛的有限版）
    max_dev(Tail, 0),               % 尾部依测度偏差精确为 0（整数 0：避免 0 = 0.0 项统一失败）
    format("noise-then-zero: tail empty -> deviation exactly 0, a.e. & in measure both OK~n").

max_dev(Seq, M) :- max_dev_(Seq, 0, M).
max_dev_([], M, M).
max_dev_([E|Es], Acc, M) :- ( E == [] -> A1 is Acc ; mu(E, D), A1 is max(Acc, D) ),
    max_dev_(Es, A1, M).

tail_all_zero(Seq) :- length(Seq, L), L1 is L - 5,
    length(Tail, L1), append(_, Tail, Seq), maplist(==( [] ), Tail).

% ---- main ----
main :-
    format("==== 09 convergence_modes~n", []),
    check_min_atom,
    check_pigeon,
    check_seqs,
    format("END ====~n"), !.
