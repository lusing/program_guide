:- encoding(utf8).
% 第 61 章：有限概率的机器化（Makinson Ch6）
% 骰子对条件概率 + 辛普森 + 贝叶斯 + 期望。

die_pair(A, B) :- between(1, 6, A), between(1, 6, B).

count(Pred, N) :-
    findall(_, (die_pair(A, B), call(Pred, A, B)), L),
    length(L, N).

sum5(A, B) :- A + B =:= 5.
has3(A, B) :- (A =:= 3 -> true ; B =:= 3).
sum5_has3(A, B) :- A + B =:= 5, (A =:= 3 -> true ; B =:= 3).

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 61~n"),

    % 一、骰子对
    count(sum5, NB), count(has3, NA), count(sum5_has3, NAB),
    format("  骰子对：#B = ~d，#A = ~d，#A∩B = ~d~n", [NB, NA, NAB]),
    PAB is NAB rdiv NB, PBA is NAB rdiv NA, PA is NA rdiv 36,
    format("  p(A|B) = ~w > p(A) = ~w；p(B|A) = ~w（不可交换）~n", [PAB, PA, PBA]),
    NAB = 2, NB = 4, NA = 11,

    % 二、辛普森（交叉相乘）
    2*5 > 1*8, 4*8 > 6*5, 6*13 < 7*13,
    format("  辛普森：2/8>1/5 与 4/5>6/8 但 6/13<7/13（分系→合计反转）✓~n"),

    % 三、贝叶斯
    Cancer is (1 * 1) / (1 * 1 + 20 * 99 / 100),
    format("  癌症检查 p(C|P) ≈ ~f（丢基础率直觉 0.83）~n", [Cancer]),
    HIV1 is (0.9 * 0.15) / (0.9 * 0.15 + 0.03 * 0.85),
    HIV2 is (0.9 * 0.60) / (0.9 * 0.60 + 0.03 * 0.40),
    format("  HIV：先验 0.15 → ~f；先验 0.60 → ~f（先验抬后验抬）~n", [HIV1, HIV2]),
    Op is (0.9 * 0.3) / (0.6 * 0.33 + 0.7 * 0.37 + 0.9 * 0.3),
    format("  接线员：Clarice 后验 ≈ ~f~n", [Op]),

    % 四、期望三马（以 0.1 为单位）
    Mu is 12 * 1 - 3 - 6,
    format("  期望 μ = 0.~d（正 → 长期值得赌）~n", [Mu]),
    Mu = 3,

    format("END ===="), nl.
