:- encoding(utf8).
% 第 106 章：SCH 账簿查询——更小节点全满足约束、GMW 形态与交织影子。

% 账簿 = 位移表（0 = GCH 点；1 = 跳档点）。
is_gmw(B) :- B \= [], append(Init, [1], B), maplist(=(0), Init).

satisfies_sch(0).

% 更小节点全部满足约束（Task 21 Step 2 指定主查询）。
below_all_satisfy(B) :- append(Init, [_], B), maplist(satisfies_sch, Init).

% 最小失败：GMW 形态 + 更小全满足 + 末位失败。
minimal_failure(B) :- is_gmw(B), below_all_satisfy(B),
                      last(B, Last), \+ satisfies_sch(Last).

% 穷举长 n 的 GMW 账簿（应恰一个）。
count_gmw(N, C) :-
    findall(B, (length(B, N), gen_bits(B), is_gmw(B)), Ls),
    length(Ls, C).

gen_bits([]).
gen_bits([0|T]) :- gen_bits(T).
gen_bits([1|T]) :- gen_bits(T).

% 交织影子：位移支配检查（有限段核查）。
shifts_above(A, B, K) :-
    between(0, 5, K),
    forall(between(K, 40, N),
           (call(B, N, BN), plus(N, K, NK), call(A, NK, ANK), BN =< ANK)).

% 序列样本（以谓词编码 n ↦ 值）。
seq_plus2(N, V) :- V is N + 2.
seq_id(N, N).
seq_double(N, V) :- V is 2 * N.
seq_nplus3(N, V) :- V is N + 3.

main :-
    format("==== 106~n"),
    % GMW 形态正反。
    is_gmw([0,0,0,1]),
    \+ is_gmw([0,1,0,1]),
    \+ is_gmw([0,0,0]),
    is_gmw([1]),
    % 最小失败与更小全满足。
    minimal_failure([0,0,0,1]),
    minimal_failure([1]),
    below_all_satisfy([0,0,0,1]),
    \+ below_all_satisfy([0,1,0,1]),
    % 穷举：每长度恰一个 GMW。
    forall(between(1, 8, N), (count_gmw(N, 1), true)),
    % 交织影子。
    shifts_above(seq_plus2, seq_id, 0),
    shifts_above(seq_double, seq_nplus3, K2), K2 >= 1,
    shifts_above(seq_id, seq_id, 0),
    format("GMW 每长度恰一（1..8）；更小节点全满足；交织位移支配（k2=~w）~n", [K2]),
    writeln("END ====").
