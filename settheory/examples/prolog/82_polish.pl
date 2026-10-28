:- encoding(utf8).
% 第 82 章：逆向归纳必胜搜索 + 有限树投影。

bit(0). bit(1).

count_ones([], 0).
count_ones([B|Bs], N) :- count_ones(Bs, M), N is M + B.

% 两个赛局：a=首位为 1（张三先手锁定）；b=1 的个数 ≥ 4（李四可全 0）。
target(a, [1|_]).
target(b, S) :- count_ones(S, N), N >= 4.

zwin(G, S) :- length(S, 6), !, target(G, S).
zwin(G, S) :- length(S, L), L < 6, L mod 2 =:= 0, !,
              bit(B), append(S, [B], S2), zwin(G, S2).
zwin(G, S) :- length(S, L), L < 6, L mod 2 =:= 1,
              \+ ( bit(B), append(S, [B], S2), \+ zwin(G, S2) ).

% 有限树（剪枝）：节点集与前缀封闭性；叶 = 无真延伸的节点。
tnode([]).
tnode([0]). tnode([1]).
tnode([0,1]). tnode([1,0]). tnode([1,1]).
tnode([0,1,1]). tnode([1,0,0]).

leaf(S) :- tnode(S), \+ (tnode(T), T \= S, append(S, _, T)).

% 投影（Suslin/解析集的有限影子）：满足条件的树叶全体。
proj(P, L) :- leaf(L), call(P, L).
at_least_two(L) :- count_ones(L, N), N >= 2.

main :-
    format("==== 82~n"),
    zwin(a, []), \+ zwin(b, []),
    ( bit(B), append([], [B], S2), zwin(a, S2) -> B = 1 ),
    \+ zwin(b, [1,0]),
    findall(L, proj(at_least_two, L), Ps), Ps = [[1,1],[0,1,1]],
    findall(L, leaf(L), Ls), sort(Ls, Sorted),
    Sorted = [[0,1,1],[1,0,0],[1,1]],
    forall((tnode(T), append(Bs, [_], T)), tnode(Bs)),
    format("赛局 a 张三稳赢（首手 1）、赛局 b 李四稳赢（[1,0] 后张三死局）~n", []),
    format("树叶全体 ~w；≥2 个 1 的投影 = ~w；前缀封闭性 forall 验证通过~n", [Sorted, Ps]),
    writeln("END ====").
