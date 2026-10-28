:- encoding(utf8).
% 第 96 章：覆盖证书生成与失败见证。

% L-侧族（有限影子）：inL(Y) 表示 Y ∈ L。
inL([0,1,2]).
inL([2,3]).
inL([4]).

% X 的元素事实：elts(XElem) 列出 X 的成员。
xelem(1). xelem(2). xelem(3).

% subset(X, Y)：X 的每个列出的元素都在 Y 中。
covered_by(Y) :- forall(xelem(X), member(X, Y)).

% 单片覆盖证书：存在 Y ∈ L 包住 X。
cover1(Y) :- inL(Y), covered_by(Y).

% 两片 slack 覆盖证书：L 中两个成员之并包住 X。
cover2(Y, Z) :- inL(Y), inL(Z), forall(xelem(X),
        (member(X, Y) ; member(X, Z))).

% 链式并封闭（推论 1.8(4) 的骨架）：族成员列表之并仍在证书侧可达。
chain_cover(Ys) :- member(Ys, [[[0,1,2]], [[2,3]], [[0,1,2],[2,3]], [[4]]]),
                   forall(member(Y, Ys), inL(Y)).

main :-
    format("==== 96~n"),
    \+ cover1(_),
    cover2([0,1,2], [2,3]),
    chain_cover([[0,1,2],[2,3]]),
    format("X={1,2,3}：单片覆盖失败，两片 slack 覆盖成功（{0,1,2}∪{2,3}）~n", []),
    format("链式并：[[0,1,2],[2,3]] 是合法的族成员链（推论 1.8(4) 骨架）~n", []),
    writeln("END ====").
