:- encoding(utf8).
% 第 62 章：树的机器化（Makinson Ch7）
% 树性判定 + BST + 树高/叶计数 + 遍历。

% 图 7.1 的树
link(a, b). link(a, c). link(b, d). link(d, i). link(d, j). link(d, k).
link(c, e). link(c, f). link(c, g). link(c, h). link(i, m). link(i, o).
link(k, n). link(h, l).

% 路径与可达
path1(X, Y) :- link(X, Y).
path1(X, Y) :- link(X, Z), path1(Z, Y).

% 叶子（无出边；根 a 视为可达叶位仅在单点树时）
leaf(X) :- link(_, X), \+ link(X, _).

% 祖先
ancestor(X, Y) :- path1(X, Y).

% 树高（根到叶最长链）
branch_len(a, 0).
branch_len(X, N) :- link(P, X), branch_len(P, M), N is M + 1.

tree_height(N) :- findall(L, (leaf(X), branch_len(X, L)), Ls), max_list(Ls, N).

% 叶计数
leaf_count(N) :- findall(X, leaf(X), Xs), length(Xs, N).

% BST（数值版）
bst_insert(nil, X, node(nil, X, nil)).
bst_insert(node(L, V, R), X, node(L1, V, R)) :- X < V, !, bst_insert(L, X, L1).
bst_insert(node(L, V, R), X, node(L, V, R1)) :- X > V, !, bst_insert(R, X, R1).
bst_insert(node(L, V, R), X, node(L, V, R)) :- X =:= V, !.

bst_search(node(_, X, _), X) :- !.
bst_search(node(L, V, _), X) :- X < V, !, bst_search(L, X).
bst_search(node(_, V, R), X) :- X > V, !, bst_search(R, X).

% 九词 BST（字符串版）
strcmp_insert(nil, W, node(nil, W, nil)).
strcmp_insert(node(L, V, R), W, node(L1, V, R)) :-
    W @< V, !, strcmp_insert(L, W, L1).
strcmp_insert(node(L, V, R), W, node(L, V, R1)) :-
    W @> V, !, strcmp_insert(R, W, R1).
strcmp_insert(node(L, V, R), _, node(L, V, R)) :- !.

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 62~n"),

    % 一、图 7.1 的手术
    format("  图 7.1：14 条链接的父→子（14 = 15−1 节点）~n"),
    leaf_count(LC), format("  叶子数：~d（= 分支数）~n", [LC]),
    tree_height(H), format("  树高（链长口径）：~d~n", [H]),
    ancestor(a, o), format("  a 是 o 的祖先 ✓~n"),
    \+ path1(d, a), format("  d 不可达 a（无圈）✓~n"),

    % 二、BST 数值版：搜 6 与 8（书本例）
    T0 = nil,
    build_bst([5,3,7,2,4,6,10,9], T0, TD),
    bst_search(TD, 6), format("  BST 搜 6：yes ✓~n"),
    \+ bst_search(TD, 8), format("  BST 搜 8：no ✓~n"),
    bst_insert(TD, 8, TD8),
    bst_search(TD8, 8), format("  BST 插入 8 后搜 8：yes ✓~n"),

    % 三、九词 BST（显式递归代替 foldl）
    Words = [this,is,how,to,construct,a,binary,search,tree],
    build_bst(Words, nil, TW),
    strcmp_insert(TW, zero, _TW2),
    format("  九词 BST 插入 zero 成功 ✓~n"),

    format("END ===="), nl.

build_bst([], T, T).
build_bst([W|Ws], T, TW) :-
    strcmp_insert(T, W, T1),
    build_bst(Ws, T1, TW).
