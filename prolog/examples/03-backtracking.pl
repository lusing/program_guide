% ============================================================
% 03 - 回溯与搜索树
%   运行：swipl -q -f 03-backtracking.pl -g main -t halt
%        gprolog --consult-file 03-backtracking.pl --entry-goal main
% ============================================================

parent(tom,   bob).
parent(tom,   liz).
parent(bob,   ann).
parent(bob,   pat).
parent(pat,   jim).

likes(mary, wine).
likes(mary, food).
likes(john, food).
likes(john, mary).

% ---------- 1. 合取与回溯 ----------
% Prolog 按子句顺序自上而下匹配，失败就回溯到最近的选择点重来。

demo_conjunction :-
    format("---- 合取：parent(tom,X), parent(X,Y) ----~n", []),
    forall((parent(tom, X), parent(X, Y)),
           format("  tom -> ~w -> ~w~n", [X, Y])).

% ---------- 2. 选择点数量决定答案个数 ----------
demo_choicepoints :-
    format("---- 同一个查询的所有解 ----~n", []),
    findall(X, parent(bob, X), Cs),
    format("  bob 的孩子：~w~n", [Cs]),
    findall(A-B, (likes(A, food), likes(B, mary)), Pairs),
    format("  喜欢 food 且被人喜欢 mary 的组合：~w~n", [Pairs]).

% ---------- 3. 递归搜索：祖先 ----------
ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).

demo_ancestor :-
    format("---- 递归搜索：ancestor/2 ----~n", []),
    forall(ancestor(tom, D), format("  tom 的后代：~w~n", [D])),
    ( ancestor(jim, tom) -> true ; format("  jim 不是 tom 的祖先（正确）~n", []) ).

% ---------- 4. 深度优先 + 路径记录 ----------
path(A, B, [A, B]) :- parent(A, B).
path(A, B, [A | Rest]) :- parent(A, C), path(C, B, Rest).

demo_path :-
    format("---- 带路径的搜索 ----~n", []),
    forall(path(tom, jim, P), format("  路径：~w~n", [P])).

% ---------- 5. 无限回溯与深度限制 ----------
% 左递归 ancestor 在变量未绑定时会不断展开，必须限制深度。
ancestor_d(X, Y, D) :- D > 0, parent(X, Y).
ancestor_d(X, Y, D) :- D > 1, D1 is D - 1, parent(X, Z), ancestor_d(Z, Y, D1).

demo_depth :-
    format("---- 深度限制（迭代加深的思路）----~n", []),
    forall((between(1, 4, D), ancestor_d(tom, Who, D)),
           format("  深度 ~w 可达：~w~n", [D, Who])).

% ---------- 6. 生成与测试 ----------
demo_generate_test :-
    format("---- 生成与测试（generate & test）----~n", []),
    findall(X-Y,
            (member(X, [1,2,3,4,5,6,7,8,9,10]),
             member(Y, [1,2,3,4,5,6,7,8,9,10]),
             X < Y, 0 is (X + Y) mod 7),
            Ps),
    format("  和能被 7 整除且 X<Y 的数对：~w~n", [Ps]).

run :-
    demo_conjunction,    nl,
    demo_choicepoints,   nl,
    demo_ancestor,       nl,
    demo_path,           nl,
    demo_depth,          nl,
    demo_generate_test.

main :-
    (   catch(run, E, (format(user_error, "异常: ~q~n", [E]), fail))
    ->  format("==== 03 结束 ====~n", []), halt(0)
    ;   format(user_error, "03 运行失败~n", []), halt(1)
    ).
