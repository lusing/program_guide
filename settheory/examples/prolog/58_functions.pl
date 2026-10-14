:- encoding(utf8).
% 第 58 章：函数的机器化（Makinson Ch3）
% 单射判定、有限选择函数、三角族无穿越集、复合不交换。

% 值域（像）
image(F, Dom, Img) :-
    setof(V, A^(member(A, Dom), call(F, A, V)), Img).

% 单射判定：像与源等大
injective_on(F, Dom) :-
    image(F, Dom, Img),
    length(Dom, N), length(Img, N).

% 常值函数：不单射的见证
const5(_, 5).
sq(X, Y) :- Y is X * X.
succ1(X, Y) :- Y is X + 1.

% 复合：comp(F, G, X, Z) = 先 F 后 G
comp(F, G, X, Z) :- call(F, X, Y), call(G, Y, Z).

% 有限选择函数：取首元素
choice_first([], []).
choice_first([S|Ss], [(S,H)|R]) :- S = [H|_], choice_first(Ss, R).

% 穿越集：C 与每个族元恰交一个元素
transversal(Fam, C) :-
    include_chooses(Fam, C).
include_chooses([], _).
include_chooses([S|Ss], C) :-
    exactly_one(S, C),
    include_chooses(Ss, C).
exactly_one(S, C) :-
    intersection(S, C, I), length(I, 1).

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 58~n"),

    % 一、单射判定：平方在 0..9 单射、在 -9..9 不单射
    numlist(0, 9, Nats),
    injective_on(sq, Nats),
    format("  平方于 0..9：单射 ✓~n"),
    numlist(-9, 9, Ints),
    \+ injective_on(sq, Ints),
    format("  平方于 -9..9：不单射（9² = (−9)²）✓~n"),
    injective_on(succ1, Ints),
    format("  后继于 -9..9：单射 ✓~n"),
    \+ injective_on(const5, Nats),
    format("  常值函数于 0..9：不单射 ✓~n"),

    % 二、复合不交换：succ 与 double
    comp(succ1, double, 1, A),   % 先 succ 后 double
    comp(double, succ1, 1, B),
    format("  复合不交换：先 succ 后 double(1) = ~w；先 double 后 succ(1) = ~w~n", [A, B]),
    A = 4, B = 3,

    % 三、有限选择函数（AC 有限免费）
    choice_first([[1,2],[2,3],[1,3],[7]], Ch),
    format("  有限族的选择函数（首元素）：~w~n", [Ch]),

    % 四、三角族无穿越集（穷举 {1,2,3} 全部子集）
    (   subset_c([1,2,3], C),
        transversal([[1,2],[2,3],[1,3]], C)
    ->  format("  意外：三角族有穿越集 ~w~n", [C])
    ;   format("  三角族 {{1,2},{2,3},{1,3}}：无穿越集（不交性必要）✓~n")
    ),

    % 五、像的计算
    image(sq, [1,2,3], Img),
    format("  平方像 = ~w（值域可小于目标）~n", [Img]),

    format("END ===="), nl.

double(X, Y) :- Y is 2 * X.

% 子集枚举
subset_c([], []).
subset_c([X|Xs], [X|C]) :- subset_c(Xs, C).
subset_c([_|Xs], C) :- subset_c(Xs, C).
