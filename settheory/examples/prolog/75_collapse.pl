:- encoding(utf8).
:- use_module(library(ordsets)).
:- use_module(library(assoc)).
% 第 75 章：传递化：刚性与有秩关系（冯琦 §1.10）——Prolog 通道
% 坍缩引擎（定理 1.100：π(a) = {π(z) | z ∈ ext(a)}，assoc 记忆化）+
% HF 世界（ordset 嵌套）：像传递、保关系、单射三验收；自同一性检查
% （定义 1.99）与秩分层器（定理 1.98）；例 1.35 偶数链、刚性同像、
% 例 1.34 相撞、2-循环永不分层四个现场。

% ---------- HF 构造：冯诺伊曼数字 ----------
vn(0, []) :- !.
vn(N, S) :-
    N > 0, N1 is N - 1, vn(N1, S1),
    ord_add_element(S1, S1, S).

% ---------- 邻接查询：Ext = [节点-前驱ordset | …] ----------
node_ext(A, Ext, Zs) :-
    (memberchk(A-Zs, Ext) -> true ; Zs = []).

% ---------- 坍缩（记忆化 π） ----------
go(A, _, Pi, Pi, V) :-
    get_assoc(A, Pi, V), !.
go(A, Ext, Pi0, Pi2, V) :-
    node_ext(A, Ext, Zs),
    go_list(Zs, Ext, Pi0, Pi1, Vs),
    list_to_ord_set(Vs, V),
    put_assoc(A, Pi1, V, Pi2).
go_list([], _, Pi, Pi, []).
go_list([Z|Zs], Ext, Pi0, Pi2, [V|Vs]) :-
    go(Z, Ext, Pi0, Pi1, V),
    go_list(Zs, Ext, Pi1, Pi2, Vs).

collapse(Nodes, Ext, Pi, M) :-
    empty_assoc(Pi0),
    foldl([A, P0, P1]>>(go(A, Ext, P0, P1, _)), Nodes, Pi0, Pi),
    assoc_to_values(Pi, Vs),
    list_to_ord_set(Vs, M).

% ---------- 验收三条件（定理 1.100） ----------
check_collapse(Nodes, Ext, Pi, M) :-
    % 像传递：x ∈ y ∈ M → x ∈ M
    forall(member(Y, M), forall(member(X, Y), ord_memberchk(X, M))),
    % π 保关系（双向）
    forall((member(A, Nodes), node_ext(A, Ext, Zs), member(Z, Zs)),
           (get_assoc(A, Pi, VA), get_assoc(Z, Pi, VZ),
            ord_memberchk(VZ, VA))),
    forall((member(A, Nodes), member(Z, Nodes),
            get_assoc(A, Pi, VA), get_assoc(Z, Pi, VZ),
            ord_memberchk(VZ, VA)),
           (node_ext(A, Ext, Zs), ord_memberchk(Z, Zs))),
    % π 单射
    assoc_to_values(Pi, Vals), list_to_ord_set(Vals, SVals),
    length(Vals, N), length(SVals, N).

% ---------- 自同一（定义 1.99） ----------
is_extensional(Nodes, Ext) :-
    forall((member(A, Nodes), member(B, Nodes), A \== B),
           (node_ext(A, Ext, EA), node_ext(B, Ext, EB), EA \== EB)).

% ---------- 秩分层器（定理 1.98） ----------
rank_layers(Nodes, Ext, Rank, Leftover) :-
    rank_go(Nodes, Ext, [], 0, Rank),
    findall(A, (member(A, Nodes), \+ memberchk(A-_, Rank)), Leftover).
rank_go(Nodes, Ext, Acc, L, Rank) :-
    findall(A, (member(A, Nodes), \+ memberchk(A-_, Acc),
                node_ext(A, Ext, Zs),
                forall(member(Z, Zs), memberchk(Z-_, Acc))), New),
    (  New == [] -> Rank = Acc
    ;  maplist([A, A-L]>>true, New, NewR),
       append(Acc, NewR, Acc1), L1 is L + 1,
       rank_go(Nodes, Ext, Acc1, L1, Rank) ).

% ---------- 主检定 ----------
main :-
    format("==== 75~n"),
    % 现场一：偶数链（例 1.35 有限段）：π(2n) = n，像 = 4
    Nodes1 = [0, 2, 4, 6],
    findall(A-E, (member(N, [0,1,2,3]), A is 2*N,
                  findall(Z, (between(0, N, K), K < N, Z is 2*K), Zs),
                  list_to_ord_set(Zs, E)), Ext1),
    is_extensional(Nodes1, Ext1),
    rank_layers(Nodes1, Ext1, _Rank1, Left1), Left1 == [],
    collapse(Nodes1, Ext1, Pi1, M1),
    check_collapse(Nodes1, Ext1, Pi1, M1),
    vn(4, V4), M1 == V4,
    forall(between(0, 3, N), (A is 2*N, get_assoc(A, Pi1, V), vn(N, VN), V == VN)),
    writeln("偶数链 {0,2,4,6}：π(2n) = n，坍缩像 = 4 ✓（例 1.35）"),
    % 现场二：刚性——同构不同集同像
    Nodes2 = [1, 3, 5, 7],
    findall(A-E, (member(N, [0,1,2,3]), A is 2*N+1,
                  findall(Z, (between(0, N, K), K < N, Z is 2*K+1), Zs),
                  list_to_ord_set(Zs, E)), Ext2),
    collapse(Nodes2, Ext2, _, M2), M2 == M1,
    writeln("刚性：{0,2,4,6} 与 {1,3,5,7} 坍缩到同一 M = 4 ✓"),
    % 现场三：例 1.34 {2,3,{2}} 不自同一 → 相撞
    Nodes3 = [a2, a3, a23],
    Ext3 = [a3-[a2], a23-[a2]],
    (is_extensional(Nodes3, Ext3) -> throw(unexpected) ; true),
    collapse(Nodes3, Ext3, Pi3, _),
    get_assoc(a3, Pi3, V3), get_assoc(a23, Pi3, V23),
    V3 == V23, V3 == [[]],
    writeln("例 1.34 {2,3,{2}}：不自同一 → π(3) = π({2}) = {∅} 相撞 ✓"),
    % 现场四：外延 DAG 与 2-循环
    Nodes4 = [a, b, c, d],
    list_to_ord_set([a], EA4), list_to_ord_set([a,b], EC4), list_to_ord_set([a,c], ED4),
    Ext4 = [b-EA4, c-EC4, d-ED4],
    rank_layers(Nodes4, Ext4, Rank4, Left4),
    Left4 == [],
    memberchk(a-0, Rank4), memberchk(b-1, Rank4),
    memberchk(c-2, Rank4), memberchk(d-3, Rank4),
    collapse(Nodes4, Ext4, Pi4, M4),
    check_collapse(Nodes4, Ext4, Pi4, M4),
    get_assoc(d, Pi4, VD4), VD4 == [[], [[], [[]]]],
    writeln("外延 DAG 分层 [a:0,b:1,c:2,d:3] ✓；π(d) = {0,2} ✓"),
    Nodes5 = [x, y], list_to_ord_set([y], EY), list_to_ord_set([x], EX),
    Ext5 = [x-EY, y-EX],
    rank_layers(Nodes5, Ext5, Rank5, Left5),
    Rank5 == [], Left5 == [x, y],
    writeln("2-循环 x⇄y：分层永远漏掉它——非有秩 ⟺ 不可分层 ✓"),
    writeln("END ====").
