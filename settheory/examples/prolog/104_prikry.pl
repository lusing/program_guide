:- encoding(utf8).
% 第 104 章：Prikry 条件的序查询、泛型序列候选生成与 G(X) 判定。

% ── 一、初始段序与纯延长（Task 19 Step 2 指定件） ──
isPrefix([], _).
isPrefix([H|T], [H|S]) :- isPrefix(T, S).

% 事实 2.3.1 前半：交条件双侧纯延长（测度一集以列表表示）。
inclL([], _).
inclL([H|T], L) :- member(H, L), inclL(T, L).

ple(s(S,A), s(S,B)) :- inclL(A, B).

% 定义 2.6 全序。
prikryLe(s(S,A), s(T,B)) :-
    isPrefix(T, S),
    inclL(A, B),
    append(T, Rest, S),
    inclL(Rest, B).

% ── 二、stem 良形（严格递增）与相容判定 ──
stemOK([]).
stemOK([_]).
stemOK([A,B|T]) :- A < B, stemOK([B|T]).

% 相容：stem 可比较（有公共延展）——事实 2.3.1 的不相容来源只在 stem。
compat_stems(S, T) :- isPrefix(S, T) ; isPrefix(T, S).

% ── 三、泛型序列候选生成（Mathias 定理 2.7 影子） ──
% 测度一集 = 含尾核 [5..9]；候选 X ⟹ 递增且尾段入核。
in_core(X) :- between(5, 9, X).

tail_in_core(Xs) :-
    ( append(_, T, Xs), maplist(in_core, T), length(T, L), L >= 3 ).

prikry_candidate(Xs) :-
    stemOK(Xs),
    tail_in_core(Xs).

% G(X) 成员判定：s = X∩α ∧ X∖s ⊆ A。
prefix_at(Xs, N, S) :- length(S, N), append(S, _, Xs).

in_gx(s(S,A), Xs) :-
    length(S, N),
    prefix_at(Xs, N, S),
    append(S, Rest, Xs),
    inclL(Rest, A).

main :-
    format("==== 104~n"),
    % 初始段序样本。
    isPrefix([2,5], [2,5,7]),
    \+ isPrefix([2,6], [2,5,7]),
    isPrefix([2,5,7], [2,5,7]),
    % stem 良形与相容。
    stemOK([2,5,7]),
    \+ stemOK([2,2,5]),
    compat_stems([2,5], [2,5,7]),
    \+ compat_stems([2,5], [2,6]),
    % 纯延长与全序样本。
    ple(s([2,5],[5,6,7,8,9]), s([2,5],[4,5,6,7,8,9])),
    \+ ple(s([2,5],[4,5,6,7,8,9]), s([2,5],[5,6,7,8,9])),
    prikryLe(s([2,5,7],[5,6,7,8,9]), s([2,5],[4,5,6,7,8,9])),
    \+ prikryLe(s([2,6],[5,6,7,8,9]), s([2,5],[4,5,6,7,8,9])),
    % 泛型序列候选生成：枚举几个候选与反例。
    prikry_candidate([1,2,5,6,7,8,9]),
    prikry_candidate([3,4,5,6,7]),
    \+ prikry_candidate([5,1,6,7,8]),
    \+ prikry_candidate([1,2,3,4,6,7,8,4]),
    % G(X) 判定（定理 2.7 影子）。
    X = [1,2,5,6,7,8,9],
    in_gx(s([1,2],[5,6,7,8,9]), X),
    \+ in_gx(s([1,5],[5,6,7,8,9]), X),
    \+ in_gx(s([1,2],[6,7,8,9]), X),
    in_gx(s(X,[5,6,7,8,9]), X),
    format("初始段/纯延长/全序样本；相容=stem 可比较；候选生成与 G(X) 判定~n"),
    writeln("END ====").
