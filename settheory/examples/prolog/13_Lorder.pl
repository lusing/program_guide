:- encoding(utf8).
% 第 13 章 AC 与 GCH 在 L：<_L 比较器
%
% 出生证 birth(X, N)（层号）+ <_L 的第一坐标比较。
% 全体按（层， 结构， 字典）排序——良序的可执行化身。

% ---------- 一、出生证（12 章层级的记录版） ----------

birth('{}', 0).
birth('{{}}', 1).
birth('{{},{{}}}', 2).
birth('{{{},{{}}}}', 2).     % {{∅,{∅}}}：层 2（由 V₂ 的成员配对）
birth('{{{}}}', 2).          % {{∅}}：层 2

% ---------- 二、<_L 第一坐标 ----------

lt_L_first(X, Y) :- birth(X, NX), birth(Y, NY), NX < NY.

% 同层比结构（长度优先再字典）
structure_key(S, K) :- atom_length(S, L), K = L-S.

lt_L(X, Y) :-
    birth(X, NX), birth(Y, NY),
    (   NX < NY -> true
    ;   NX =:= NY,
        atom_length(X, LX), atom_length(Y, LY),
        (   LX < LY -> true
        ;   LX =:= LY, X @< Y
        )
    ).

% ---------- 三、全序化演示 ----------

all_sorted(Sorted) :-
    findall(S, birth(S, _), Ss),
    sort(Ss, Unique),
    predsort(ord_L, Unique, Sorted).

ord_L(<, X, Y) :- lt_L(X, Y), !.
ord_L(>, _, _).

% ---------- main ----------

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 13 AC 与 GCH 在 L：<_L~n"),
    (   lt_L_first('{}', '{{}}') -> format("  层 0 < 层 1 ✓~n") ; format("  （错误）~n") ),
    (   lt_L('{}', '{{}}') -> format("  <_L：∅ 在最前 ✓~n") ; format("  （错误）~n") ),
    all_sorted(Sorted),
    format("  <_L 全序（小层先）：~w~n", [Sorted]),
    format("  ——良序的存在即 AC（定理 33）；GCH 由 Condensation（定理 34）。~n"),
    format("END ====~n").
