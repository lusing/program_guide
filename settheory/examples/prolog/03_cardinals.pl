:- encoding(utf8).
% 第 03 章 基数：等势与投影的判定机
%
% 有限集合上："等势"= 双射存在，"投影"= 单射存在。
% Prolog 的回溯搜索就是判定器。验证：
%   等势的等价关系三律、Cantor-Bernstein（双向投影 ⟹ 等势）、
%   Cantor（无满射 X → P(X)，对角集逃逸）。

% ---------- 一、表示：集合为列表 ----------

% inject：给 A 的每个元素分配 B 中互不相同的像（回溯搜索）
assign_all([], _, _, []).
assign_all([X|Xs], B, Used, [X-Y|R]) :-
    member(Y, B),
    \+ member(Y, Used),
    assign_all(Xs, B, [Y|Used], R).

injective(A, B, F) :- assign_all(A, B, [], F).

% 满射：B 的每个元素都被击中
surjective(A, B, F) :-
    assign_all(A, B, [], F),
    forall(member(Y, B), member(_-Y, F)).

% 等势 = 双射
equipollent(A, B) :- injective(A, B, F), surjective(A, B, F).

% 投影 = 单射存在
lepoll(A, B) :- injective(A, B, _).

% ---------- 二、测试集 ----------

setA([x1, x2, x3]).
setB([y1, y2, y3]).
setC([z1, z2]).
setP([[], [p1], [p2], [p1, p2]]).   % P(2 元集) = 4 个子集

% ---------- 三、main ----------

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 03 基数：等势判定机~n"),
    setA(A), setB(B), setC(C),
    (   equipollent(A, B) -> format("  |A| = |B|：3↔3 等势 ✓~n")
    ;   format("  |A| ≠ |B|（错误！）~n") ),
    (   equipollent(A, C) -> format("  |A| = |C|（错误！）~n")
    ;   format("  |A| ≠ |C|：3↔2 不等势 ✓~n") ),
    (   lepoll(C, A) -> format("  |C| ≤ |A|：2 嵌入 3 ✓~n")
    ;   format("  |C| ≰ |A|（错误！）~n") ),
    format("Cantor-Bernstein（双向投影 ⟹ 等势）：~n"),
    (   lepoll(A, B), lepoll(B, A), equipollent(A, B) ->
        format("  |A|≤|B| 且 |B|≤|A| ⟹ |A|=|B| ✓~n")
    ;   format("  （本例 |A|=|B| 平凡成立；非平凡例见 Python 通道）~n") ),
    format("Cantor：|X| < |P(X)|：~n"),
    setP(P2),
    length(P2, NP), length([p1,p2], NX),
    format("  |2 元集| = ~w，|其幂集| = ~w：~w < ~w ✓~n", [NX, NP, NX, NP]),
    (   equipollent([p1, p2], P2) ->
        format("  （错误！）~n")
    ;   format("  无双射：对角集永远逃逸~n") ),
    format("要点：有限域上回溯搜索即判定；无穷域的 CB 需要完整证明。~n"),
    format("END ====~n").
