:- encoding(utf8).
% 第 07 章 滤子与理想：判定器与对偶计算
%
% 给定有限论域上的子集族（列表表示），判定：
%   1. 是否滤子（Jech (7.1)：S∈F、∅∉F、交封闭、超集封闭）；
%   2. 是否超滤（(7.9) 两分性）；
%   3. 对偶理想（(7.3) 补变换）。

% ---------- 一、集合表示与运算 ----------

% universe(S)：论域用固定 atom 表表示
universe([a, b, c, d]).

% subseq(X, Y)：X 是 Y 的子列（有限生成：S 的子集枚举器）
subseq([], []).
subseq([X|Xs], [X|Ys]) :- subseq(Xs, Ys).
subseq(Xs, [_|Ys]) :- subseq(Xs, Ys).

% subsum(X, Y)：X ⊆ Y（检查型；X 的成员都在 Y）
subsum([], _).
subsum([X|Xs], Y) :- member(X, Y), subsum(Xs, Y).

% inter(X, Y, Z)：交
inter([], _, []).
inter([X|Xs], Y, [X|Zs]) :- member(X, Y), !, inter(Xs, Y, Zs).
inter([_|Xs], Y, Zs) :- inter(Xs, Y, Zs).

% compl(X, S, C)：C = S - X
compl(X, S, C) :- findall(E, (member(E, S), \+ member(E, X)), C).

% ---------- 二、滤子判定 ----------

all_subsets([], _).
all_subsets([X|Xs], S) :- subsum(X, S), all_subsets(Xs, S).

contains(F, X) :- member(X, F).

filter_axioms(F) :-
    universe(S),
    all_subsets(F, S),
    contains(F, S),                  % S ∈ F
    \+ contains(F, []),              % ∅ ∉ F
    forall((member(X, F), member(Y, F)),
           (inter(X, Y, Z), contains(F, Z))),   % 交封闭
    forall((member(X, F), subseq(Y, S), subsum(X, Y)),
           contains(F, Y)).                      % 超集封闭（Y 有限生成）

% ---------- 三、超滤判定（(7.9)） ----------

is_ultra(F) :-
    filter_axioms(F),
    universe(S),
    \+ (subseq(X, S),
        \+ contains(F, X),
        \+ (compl(X, S, C), contains(F, C))).

% ---------- 四、对偶理想（(7.3)） ----------

dual_ideal(F, I) :-
    universe(S),
    findall(C, (member(X, F), compl(X, S, C)), I).

% ---------- main ----------

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 07 滤子与理想：判定器~n"),
    universe(S),
    % 主滤子：包含 {a} 的全体（在有限域上）
    findall(X, (subseq(X, S), member(a, X)), Fp),
    sort(Fp, Fprincipal),
    (   filter_axioms(Fprincipal) ->
        format("  主滤子 {{X : a ∈ X}}：滤子公理 ✓~n")
    ;   format("  主滤子判定失败（错误！）~n") ),
    (   is_ultra(Fprincipal) ->
        format("  它还是超滤：有限域上主超滤 ✓~n")
    ;   format("  非超滤（错误！）~n") ),
    % Fréchet：余有限（>2 个元素的补有限——有限域上余 ≥3）
    findall(X, (subseq(X, S), length(X, N), N >= 3), Ff),
    sort(Ff, Ffrechet),
    (   filter_axioms(Ffrechet) ->
        format("  '余小'族是滤子（不应发生）~n")
    ;   format("  {{X : |X| ≥ 3}} 不是滤子：交 {a,b,c}∩{a,b,d}={a,b} 掉出~n"),
        format("    ——余有限滤子只在无限域成立（Fréchet 的家）~n")
    ),
    dual_ideal(Fprincipal, I),
    format("  对偶理想：~w~n", [I]),
    format("要点：超滤的无限版存在性需要 Zorn（Tarski 定理 21）。~n"),
    format("END ====~n").
