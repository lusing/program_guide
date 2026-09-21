%% ============================================================================
%%  09_recursion.pl —— 递归
%%
%%  Prolog 没有 for / while，递归就是唯一的循环。写 Prolog 的递归要抓住两点：
%%    1. 先写「出口」（base case）：什么时候不用再往下走了
%%    2. 再写「缩小」（recursive case）：问题怎么变小，以及变小的答案怎么拼回来
%%
%%  尾递归（tail recursion）决定了性能：如果递归调用是整个子句的最后一步，
%%  引擎就能把它变成循环，栈不会长。这是 Prolog 相对其他语言的杀手锏 ——
%%  在 Scheme 里要显式写尾调用，在 Prolog 里你只需要「把累加器带上」。
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

say(S) :- format("~s~n", [S]).

%% ---------------------------------------------------------------------------
%%  一、结构性递归：跟着数据形状走
%% ---------------------------------------------------------------------------
sum_list_rec([], 0).
sum_list_rec([H | T], S) :-
    sum_list_rec(T, S0),
    S is S0 + H.

max_list_rec([X], X).
max_list_rec([H | T], M) :-
    max_list_rec(T, M0),
    M is max(H, M0).

demo_structural :-
    say("---- 1. 结构性递归：数据长什么样，代码就长什么样 ----"),
    sum_list_rec([1, 2, 3, 4, 5], S),
    format("  sum_list_rec([1,2,3,4,5]) = ~w~n", [S]),
    max_list_rec([3, 9, 2, 7], M),
    format("  max_list_rec([3,9,2,7])   = ~w~n", [M]),
    say("  规律：一个子句处理 []，一个子句处理 [H|T] 并递归 T。"),
    say("  90% 的列表谓词都是这个骨架（第 08 章已经见过 append/reverse）。").

%% ---------------------------------------------------------------------------
%%  二、数值递归：问题规模怎么缩小
%% ---------------------------------------------------------------------------
fact(0, 1).
fact(N, F) :-
    N > 0,
    N1 is N - 1,
    fact(N1, F0),
    F is N * F0.

fib(0, 0).
fib(1, 1).
fib(N, F) :-
    N > 1,
    N1 is N - 1,
    N2 is N - 2,
    fib(N1, F1),
    fib(N2, F2),
    F is F1 + F2.

gcd_rec(X, 0, X) :- X > 0.
gcd_rec(X, Y, G) :-
    Y > 0,
    R is X mod Y,
    gcd_rec(Y, R, G).

demo_numeric :-
    say("---- 2. 数值递归 ----"),
    fact(10, F1),
    format("  fact(10)          = ~w~n", [F1]),
    fib(10, F2),
    format("  fib(10)           = ~w~n", [F2]),
    gcd_rec(1071, 462, G),
    format("  gcd_rec(1071,462) = ~w~n", [G]),
    say("  fib/2 有两处递归调用，调用树是二叉的 —— 指数复杂度。"),
    say("  这正好用来对照下一节的线性版本。").

%% ---------------------------------------------------------------------------
%%  三、尾递归与累加器：把「回来后拼」改成「下去时攒」
%% ---------------------------------------------------------------------------
fib_acc(N, F) :- fib_acc(N, 0, 1, F).
fib_acc(0, A, _B, A).
fib_acc(N, A, B, F) :-
    N > 0,
    N1 is N - 1,
    C is A + B,
    fib_acc(N1, B, C, F).

sum_acc(L, S) :- sum_acc(L, 0, S).
sum_acc([], Acc, Acc).
sum_acc([H | T], Acc, S) :-
    Acc1 is Acc + H,
    sum_acc(T, Acc1, S).

demo_tail :-
    say("---- 3. 尾递归：累加器版 ----"),
    fib_acc(10, F1),
    format("  fib_acc(10) = ~w~n", [F1]),
    sum_acc([1, 2, 3, 4, 5], S),
    format("  sum_acc    = ~w~n", [S]),
    say("  尾递归版本里，递归调用是子句的最后一个目标，前面没有任何"),
    say("  「等它回来还要做」的活儿。引擎于是可以复用栈帧。"),
    say("  代价：多了一个累加器参数；收益：O(1) 栈深，可以处理很长的列表。"),
    say("  判定标准很简单：递归调用后面还有别的目标吗？有就不是尾递归。").

%% ---------------------------------------------------------------------------
%%  四、互递归：两个谓词互相调用
%% ---------------------------------------------------------------------------
even_odd(0, even).
even_odd(N, R) :-
    N > 0,
    N1 is N - 1,
    even_odd(N1, R0),
    flip(R0, R).

flip(even, odd).
flip(odd, even).

%% ---------------------------------------------------------------------------
%%  五、递归下降：表达式求值（第 19 章会把它写成 DCG）
%% ---------------------------------------------------------------------------
eval(Expr, V) :-
    eval_expr(Expr, V, []).

eval_expr(N, V, Rest) :-
    number(N),
    !,
    V = N,
    Rest = [].
eval_expr(add(A, B), V, []) :-
    !,
    eval_expr(A, VA, []),
    eval_expr(B, VB, []),
    V is VA + VB.
eval_expr(mul(A, B), V, []) :-
    !,
    eval_expr(A, VA, []),
    eval_expr(B, VB, []),
    V is VA * VB.

demo_mutual :-
    say("---- 4. 互递归 ----"),
    even_odd(7, R),
    format("  even_odd(7)  = ~w~n", [R]),
    even_odd(10, R2),
    format("  even_odd(10) = ~w~n", [R2]),
    eval(add(2, mul(3, 4)), V),
    format("  eval(add(2, mul(3,4))) = ~w~n", [V]),
    say("  互递归在语法分析里是主力：表达式 → 项 → 因子 → 表达式…（第 19 章）。").

%% ---------------------------------------------------------------------------
%%  六、树递归：递归跟着数据结构走
%% ---------------------------------------------------------------------------
%% 二叉树用 nil | t(Left, Value, Right) 表示
tree_insert(nil, X, t(nil, X, nil)).
tree_insert(t(L, V, R), X, t(L2, V, R)) :-
    X @< V,
    tree_insert(L, X, L2).
tree_insert(t(L, V, R), X, t(L, V, R2)) :-
    X @>= V,
    tree_insert(R, X, R2).

tree_from_list(L, T) :- tree_from_list(L, nil, T).
tree_from_list([], T, T).
tree_from_list([H | T], Acc, R) :-
    tree_insert(Acc, H, Acc1),
    tree_from_list(T, Acc1, R).

% 中序遍历：二叉搜索树的中序就是有序序列
tree_inorder(nil, []).
tree_inorder(t(L, V, R), Ls) :-
    tree_inorder(L, LL),
    tree_inorder(R, RL),
    append(LL, [V | RL], Ls).

tree_sum(nil, 0).
tree_sum(t(L, V, R), S) :-
    tree_sum(L, SL),
    tree_sum(R, SR),
    S is SL + SR + V.

tree_depth(nil, 0).
tree_depth(t(L, _, R), D) :-
    tree_depth(L, DL),
    tree_depth(R, DR),
    D is 1 + max(DL, DR).

demo_tree :-
    say("---- 5. 树递归 ----"),
    tree_from_list([5, 3, 8, 1, 4, 9], T),
    tree_inorder(T, Sorted),
    format("  中序遍历（应有序） = ~w~n", [Sorted]),
    tree_sum(T, S),
    format("  求和               = ~w~n", [S]),
    tree_depth(T, D),
    format("  深度               = ~w~n", [D]),
    say("  树就不是「一个子句配一个元素」了，而是「每棵子树各递归一次」。").

%% ---------------------------------------------------------------------------
%%  七、函数式写法之外：递归 + 回溯 = 搜索
%% ---------------------------------------------------------------------------
edge(a, b). edge(b, c). edge(c, d). edge(a, d).
edge(d, e). edge(e, a).

path(X, X, [X]).
path(X, Z, [X | T]) :-
    edge(X, Y),
    path(Y, Z, T).

demo_search :-
    say("---- 6. 递归 + 回溯 = 深度优先搜索 ----"),
    say("  图里有环，直接 path(a,e,L) 会无限绕下去（L 一直变长），"),
    say("  所以必须先限定路径长度 —— 这是 Prolog 搜索的常见护栏："),
    findall(L2, ( length(L2, 3), path(a, e, L2) ), Ls2),
    format("  顶点数恰好为 3 的路径：~w~n", [Ls2]),
    say("  递归负责「往前走」，回溯负责「走不通就退回来换一条」——"),
    say("  这两件事加起来就是搜索算法，不需要显式维护栈。"),
    say("  工程上还要加 visited 集合去环（第 24 章会给一个完整版）。").

%% ---------------------------------------------------------------------------
%%  入口
%% ---------------------------------------------------------------------------
main :-
    (   catch(run, E, (format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   format(user_error, "*** run/0 失败~n", []),
        halt(1)
    ).

run :-
    format("==== 09 开始 ====~n", []),
    say("Prolog 里唯一的内建循环是递归，其余全靠回溯（第 06 章）。"),
    say(""),

    demo_structural, say(""),
    demo_numeric,    say(""),
    demo_tail,       say(""),
    demo_mutual,     say(""),
    demo_tree,       say(""),
    demo_search,     say(""),

    format("==== 09 结束 ====~n", []).
