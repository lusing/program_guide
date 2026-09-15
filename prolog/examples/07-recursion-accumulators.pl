% ============================================================
%  07-recursion-accumulators.pl —— 递归、累加器与尾调用
%
%  运行（SWI）: swipl -q -f examples/07-recursion-accumulators.pl -g main -t halt
%  运行（GNU）: gprolog --consult-file examples/07-recursion-accumulators.pl --entry-goal main
% ============================================================

:- set_prolog_flag(double_quotes, codes).

% ------------------------------------------------------------
%  一、朴素递归 vs 尾递归
%     朴素版：每一层都要等子调用返回才能做乘法 —— 需要栈
%     累加器版：把「已经算好的部分」往下传 —— 可优化成循环
% ------------------------------------------------------------
fact_naive(0, 1).
fact_naive(N, F) :- N > 0, N1 is N - 1, fact_naive(N1, F1), F is N * F1.

fact_tail(N, F) :- fact_tail(N, 1, F).
fact_tail(0, Acc, Acc).
fact_tail(N, Acc, F) :- N > 0, Acc1 is Acc * N, N1 is N - 1, fact_tail(N1, Acc1, F).

demo_tail :-
    format("---- 朴素递归 vs 尾递归 ----~n", []),
    fact_naive(10, A), fact_tail(10, B),
    format("  fact_naive(10) = ~w~n", [A]),
    format("  fact_tail(10)  = ~w~n", [B]),
    ( A =:= B -> format("  结果一致~n", []) ; format("  结果不一致！~n", []) ),
    format("  差别在于：朴素版在递归返回后才做乘法，~n", []),
    format("  尾递归版把中间结果放在 Acc 里一路带下去，最后一个子句直接交出 Acc。~n", []).

% ------------------------------------------------------------
%  二、累加器做反转 /  flatten / 计数
% ------------------------------------------------------------
demo_reverse :-
    format("---- 累加器经典三例 ----~n", []),
    reverse_acc([1,2,3,4], R),
    format("  反转：~w~n", [R]),
    my_flatten([1,[2,[3,[]]],4], F1),
    format("  扁平化（朴素版）：~w~n", [F1]),
    flatten_diff([1,[2,[3,[]]],4], F2),
    format("  扁平化（差异列表）：~w~n", [F2]),
    count_if([1,7,3,9,2,8], gt5, C),
    format("  统计大于 5 的个数：~w~n", [C]).

reverse_acc(L, R) :- reverse_acc(L, [], R).
reverse_acc([], Acc, Acc).
reverse_acc([H | T], Acc, R) :- reverse_acc(T, [H | Acc], R).

% 朴素版：清晰但每次都 append，长列表上是 O(n^2)
my_flatten([], []).
my_flatten([H | T], F) :-
    ( is_list(H) -> my_flatten(H, FH) ; FH = [H] ),
    my_flatten(T, FT),
    append(FH, FT, F).

% 差异列表版：用「还没确定的尾部」当累加器，整体 O(n)
% 约定：flatten_dl(输入, 结果-尾部洞)
flatten_diff(L, F) :- flatten_dl(L, F-[]).
flatten_dl(X, [X | T]-T) :- \+ is_list(X), !.
flatten_dl([], T-T) :- !.
flatten_dl([H | T], F-T0) :-
    flatten_dl(H, F-T1),
    flatten_dl(T, T1-T0).
% 注意：包装谓词必须换名字，否则 flatten_dl/2 会无限递归进自己

count_if([], _, 0).
count_if([X | Xs], Goal, N) :-
    count_if(Xs, Goal, N1),
    ( catch(call(Goal, X), _, fail) -> N is N1 + 1 ; N = N1 ).

gt5(X) :- X > 5.

% ------------------------------------------------------------
%  三、树：递归结构 + 遍历
% ------------------------------------------------------------
% 叶节点：leaf(Value)；内部节点：node(Left, Right)
sample_tree(node(leaf(1),
                 node(leaf(2),
                      node(leaf(3), leaf(4))))).

demo_tree :-
    format("---- 树 ----~n", []),
    sample_tree(T),
    format("  树：~q~n", [T]),
    tree_sum(T, S),   format("  所有叶子之和：~w~n", [S]),
    tree_depth(T, D), format("  深度：~w~n", [D]),
    tree_leaves(T, L),format("  叶子列表：~w~n", [L]),
    tree_map(T, double, T2),
    format("  叶子翻倍后：~q~n", [T2]).

tree_sum(leaf(V), V).
tree_sum(node(L, R), S) :- tree_sum(L, A), tree_sum(R, B), S is A + B.

tree_depth(leaf(_), 1).
tree_depth(node(L, R), D) :-
    tree_depth(L, DL), tree_depth(R, DR),
    ( DL >= DR -> D is DL + 1 ; D is DR + 1 ).

tree_leaves(T, L) :- tree_leaves(T, [], L).
tree_leaves(leaf(V), Acc, [V | Acc]).
tree_leaves(node(L, R), Acc, Out) :-
    tree_leaves(R, Acc, Acc1),
    tree_leaves(L, Acc1, Out).

tree_map(leaf(V), Goal, leaf(W)) :- call(Goal, V, W), !.
tree_map(node(L, R), Goal, node(L2, R2)) :-
    tree_map(L, Goal, L2), tree_map(R, Goal, R2).

double(X, Y) :- Y is X * 2.

% ------------------------------------------------------------
%  四、互递归（奇偶判定）
% ------------------------------------------------------------
my_even(0).
my_even(N) :- N > 0, M is N - 1, my_odd(M).
my_odd(1).
my_odd(N) :- N > 1, M is N - 1, my_even(M).

demo_mutual :-
    format("---- 互递归 ----~n", []),
    forall(member(N, [0,1,2,3,4,7,10]),
           ( ( my_even(N) -> E = '偶' ; E = '奇' ),
             format("  ~w -> ~w~n", [N, E]) )).

% ------------------------------------------------------------
%  五、左递归会爆栈 —— 四种改法
% ------------------------------------------------------------
% 危险写法（不要在实际代码里这么写，这里只演示为什么）：
%   loop(X) :- loop(X).                     % 死循环
%   naive_len([_|T], N) :- naive_len(T,N1), N is N1+1.
%                                            % 朴素版在长列表上会吃很多栈
demo_pitfalls :-
    format("---- 递归的坑 ----~n", []),
    format("  1) 左递归 / 无进展递归 = 无限展开，必须保证每步都在变小~n", []),
    format("  2) 朴素递归在长列表上吃栈；用累加器改成尾递归~n", []),
    format("  3) 递归深度无限制时（如 ancestor(X,Y) 两边都是变量）会迷路，~n", []),
    format("     需要限制深度或先绑定参数（见 03 的 ancestor_d/3）~n", []),
    % 用累加器版的 length 处理长列表，验证它扛得住
    num_list(20000, Big),
    reverse_acc(Big, BigR),
    length(BigR, BigLen),
    format("  4) 实测：两万个元素的列表反转 + 取长度 -> ~w（尾递归不爆栈）~n", [BigLen]).

num_list(N, L) :- num_list(1, N, [], L).
num_list(I, N, Acc, L) :-
    (   I > N
    ->  reverse_acc(Acc, L)
    ;   I1 is I + 1, num_list(I1, N, [I | Acc], L)
    ).

run :-
    format("==== 07  递归、累加器与尾调用 ====~n", []), nl,
    demo_tail,     nl,
    demo_reverse,  nl,
    demo_tree,     nl,
    demo_mutual,   nl,
    demo_pitfalls.

main :-
    (   catch((run, nl, format("==== 07 结束 ====~n", [])),
              E, (nl, format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   nl, format(user_error, "*** 07 运行失败~n", []), halt(1)
    ).
