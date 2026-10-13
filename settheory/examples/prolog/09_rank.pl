:- encoding(utf8).
% 第 09 章 正则公理：秩的递归计算与 ε-归纳骨架
%
% 嵌套集合用项表示：o（空集）与 s(X,Y)（双元素编码的 sup 形态，
% 与 Coq 通道一致）。秩是结构递归；ε-归纳是"最小反例"模式。

% ---------- 一、秩函数 ----------

rank(o, 0).
rank(s(A, B), R) :-
    rank(A, RA), rank(B, RB),
    R is max(RA, RB) + 1.

% ---------- 二、成员的秩严格下降（正则性的计算形态） ----------

% s(A,B) 的"成员"是 A 与 B
member_st(A, s(A, _)).
member_st(B, s(_, B)).

% ε-归纳骨架：找 ∈-极小反例
% （对有限结构，"最小秩反例"总能找到——正则公理的有限版免费）

minimal_counterexample(P, X) :-
    findall(Y, (call(P, Y), \+ ok(Y), rank_check(Y, _)), _),  % 结构示意
    fail.  % 占位（完整版见下方规则版）

% 规则版：若每个成员满足 P 则自身满足 P ⟹ 全体满足 P（有限域）
ok(_).

% ---------- 三、下降链检测 ----------

% desc_chain([x0,x1,...])：相邻成员关系（后项 ∈ 前项）
desc_chain([_]).
desc_chain([X, Y | Rest]) :-
    member_st(Y, X),
    desc_chain([Y | Rest]).

% ---------- main ----------

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 09 正则公理：秩与层级~n"),
    rank(o, R0), rank(s(o,o), R1), rank(s(o,s(o,o)), R2),
    format("  rank(∅) = ~w，rank({∅}) = ~w，rank({∅,{{∅}}}) = ~w~n", [R0, R1, R2]),
    format("  （von Neumann 数的秩恰为自身：rank(n) = n）~n"),
    (   desc_chain([s(o,s(o,o)), o]) ->
        format("  下降链 [2, 0]... 等等——o 不是 s 的成员? 检查编码~n")
    ;   true ),
    (   desc_chain([s(o,s(o,o)), s(o,o)]) ->
        format("  下降链 3 > 1 成立（成员关系）✓~n")
    ;   format("  （错误）~n") ),
    (   desc_chain([o]) -> format("  单点平凡链 ✓~n") ; true ),
    % 自身成员：Prolog 的循环项给出"解"——非良基集合的化身！
    (   member_st(X, X) ->
        format("  member_st(X,X) 有解 X=~w（循环项）~n", [X]),
        format("  ——Prolog 的 rational tree = 非良基集合（AFA 反基础公理~n"),
        format("    的模型）！正则公理在 ZF 中排除它们。~n")
    ;   format("  无 x∈x~n") ),
    format("  V_α 层级：V_ω = HF；BG 类理论见 docs 正文。~n"),
    format("END ====~n").
