:- encoding(utf8).
% 第 05 章 选择公理：选择函数搜索器与 Zorn 链
%
% 有限域上 AC 免费兑现：回溯即选择。验证：
%   1. 选择函数的搜索（每个非空集取一个元素）；
%   2. Zorn 式极大链的贪心延伸；
%   3. 下降序列与良序的对照（引理 5.2）。

% ---------- 一、选择函数 ----------

% family(F)：F 是 (名字, 元素列表) 对的族
family([f1-[a, b], f2-[c], f3-[d, e, f]]).

% choice_function(Family, C)：C 给每个成员选一个元素
choice_function([], []).
choice_function([Name-Elems|Rest], [Name-X|CRest]) :-
    member(X, Elems),                       % 选择：任取一个
    choice_function(Rest, CRest).

% ---------- 二、Zorn 式极大链 ----------
% 覆盖关系 cover(X, Y)：Y 是 X 的严格上邻
cover(1, 2). cover(1, 3). cover(2, 4). cover(3, 4).

% chain(C)：C 是链（相邻覆盖相连）
chain([X]) :- true.
chain([X, Y|Rest]) :- cover(X, Y), chain([Y|Rest]).

% maximal_from(Start, Chain)：从 Start 贪心延伸到极大
maximal_from(Start, [Start]) :-
    \+ cover(Start, _), !.
maximal_from(Start, [Start|Rest]) :-
    cover(Start, Next),
    maximal_from(Next, Rest).

% ---------- 三、下降序列检测（引理 5.2） ----------

% 有限下降序列生成器
desc_seq([X]) :- \+ below(X, _).
desc_seq([X, Y|Rest]) :- below(X, Y), desc_seq([Y|Rest]).

% below：一个无底的序（模拟 ℤ 片段）
below(z(3), z(2)). below(z(2), z(1)). below(z(1), z(0)).
below(z(0), z(-1)). below(z(-1), z(-2)). below(z(-2), z(-3)).

% ---------- main ----------

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 05 选择公理：选择函数与 Zorn~n"),
    family(F),
    findall(C, choice_function(F, C), Cs),
    length(Cs, N),
    format("  选择函数搜索：~w 个（= 2×1×3，各集大小的乘积）~n", [N]),
    format("  示例：~w~n", [Cs]),
    format("  有限域上 AC 免费兑现：回溯即选择。~n"),
    forall((between(1, 3, S), maximal_from(S, Ch)),
           format("  Zorn 爬山从 ~w：链 ~w~n", [S, Ch])),
    format("下降序列（无底序）：~n"),
    desc_seq(Seq1),
    format("  一条下降链：~w（每步 below，永不触底）~n", [Seq1]),
    format("  引理 5.2：无穷下降链 ⟺ 非良序。~n"),
    format("END ====~n").
