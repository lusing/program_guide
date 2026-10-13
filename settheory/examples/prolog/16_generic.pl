:- encoding(utf8).
% 第 16 章 泛型扩张：偏序泛型搜索
%
% 力迫条件（有限序列）、稠密集、滤波器的谓词推理机。
% 泛型滤波器 = 滤波器 ∧ 击中一切稠密集（(16.3)）。

% ---------- 一、偏序：前缀关系 ----------

% seq(S)：有限 0/1 序列
seq([]).
seq([0|T]) :- seq(T).
seq([1|T]) :- seq(T).

% prefix(P, Q)：P 是 Q 的前缀
prefix([], _).
prefix([X|Ps], [X|Qs]) :- prefix(Ps, Qs).

% ---------- 二、稠密与滤波器 ----------

% dense(D, P)：D 在 P 中稠密（每个条件下方有 D 成员）
dense(D, P) :-
    forall(member(Q, P),
           (member(R, D), prefix(Q, R))).

% filter(F)：滤波器（非空/向上封闭/有向）
filter(F) :-
    F \= [],
    forall((member(P, F), member(Q, F)),
           (prefix(P, Q) ; prefix(Q, P))),   % 链性 ⟹ 有向
    forall((member(P, F), member(Q, F)),
           (member(R, F), prefix(R, P), prefix(R, Q))).

% generic(F, Ds)：泛型（滤波器 ∧ 击中每个稠密集）
generic(F, Ds) :-
    filter(F),
    forall(member(D, Ds),
           (member(P, F), member(P, D))).

% ---------- 三、塔构造（引理 16.1 的 Prolog 化） ----------

% first_above(P, D, Q)：Q 是 D 中延伸 P 的第一条件
first_above(P, D, Q) :- member(Q, D), prefix(P, Q), !.
first_above(P, _, P).   % 找不到时保持

% ---------- main ----------

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 16 泛型扩张：偏序搜索~n"),
    % 稠密集验证
    P4 = [[], [0], [1], [0,0], [0,1], [1,0], [1,1],
          [0,0,0], [0,0,1], [0,1,0], [0,1,1], [1,0,0], [1,0,1], [1,1,0], [1,1,1]],
    D1 = [[0,0],[0,1],[1,0],[1,1],[0,0,0],[0,0,1],[0,1,0],[0,1,1],[1,0,0],[1,0,1],[1,1,0],[1,1,1]],
    D2 = [[0,0,0],[0,0,1],[0,1,0],[0,1,1],[1,0,0],[1,0,1],[1,1,0],[1,1,1]],
    (   dense(D1, P4) -> format("  D₁（≥2 位序列）稠密 ✓~n")
    ;   format("  D₁ 不稠密（错误！）~n") ),
    (   dense(D2, P4) -> format("  D₂（3 位序列）稠密 ✓~n")
    ;   format("  D₂ 不稠密~n") ),
    % 滤波器验证
    F1 = [[], [0], [0,1]],
    (   filter(F1) -> format("  链 [∅,[0],[0,1]] 是滤波器 ✓~n")
    ;   format("  非滤波器（错误！）~n") ),
    F_bad = [[0], [1]],
    (   filter(F_bad) -> format("  [0],[1] 是滤波器（错误！）~n")
    ;   format("  [0],[1] 不相容——非滤波器 ✓~n") ),
    % 泛型
    Ds = [D1, D2],
    (   generic(F1, Ds) -> format("  F₁ 泛型 ✓（含 D₂ 的成员）~n")
    ;   format("  F₁ 非泛型（缺 D₂ 命中）~n") ),
    format("  引理 16.1（Rasiowa-Sikorski）：可数稠密集族必有泛型滤波器~n"),
    format("END ====~n").
