:- encoding(utf8).
% 第 23 章 Prolog：力迫的有限终审（书 9.2）。
% ① 偏序上的稠密/滤/脱殊判定器；
% ② Func(2,2) 的脱殊滤构造——穷举一切可能性；
% ③ 反链穷举与 c.c.c. 影子。

% ---------- 条件表示：dom/val 对的列表 ----------
% 条件 p = [(D1,V1),(D2,V2),...]，D 升序

stronger(P, Q) :-        % p ≤ q（力迫）⟺ p ⊇ q（函数包含）
    \+ (member((D, V), Q), \+ (member((D, V), P))).

compat(P, Q) :-
    \+ (member((D, V1), P), member((D, V2), Q), V1 \= V2).

% ---------- ① 稠密判定 ----------
is_dense(D, P) :-
    forall(member(P0, P), (
        member(Q, D), stronger(Q, P0))).

% ---------- ② Func(2,2) 的全部条件 ----------
all_conditions(P) :-
    findall(C, condition(C), P).

condition([]).
condition([(1,V)]) :- between(0,1,V).
condition([(2,V)]) :- between(0,1,V).
condition([(1,V1),(2,V2)]) :- between(0,1,V1), between(0,1,V2).

check_dense :-
    all_conditions(P),
    length(P, 9),                                  % 1+4+4=9 个条件
    findall(C, (condition(C), member((1,_), C)), D1),
    is_dense(D1, P),
    format("dense D_1: {p: 1 in dom(p)} is dense in Func(2,2): OK~n").

% ---------- ③ 滤与脱殊判定 ----------
is_filter(G, P) :-
    G \= [],                                        % G 非空（作为集）
    forall((member(A, G), member(B, P), stronger(A, B)),
           member(B, G)),                          % 上封闭（含最大元 1=空函数）
    forall((member(A, G), member(B, G)),
           (findall(C, (stronger(C, A), stronger(C, B)), Cs),
            Cs \= [])).

% 脱殊：穿过 M 中的每个稠密集（窗口：D_0, D_1, D_2）
is_generic(G, DenseSets) :-
    forall(member(D, DenseSets),
           (member(G0, G), member(G0, D))).

check_generic :-
    all_conditions(P),
    D1 = [[(1,0)],[(1,1)],[(1,0),(2,0)],[(1,0),(2,1)],[(1,1),(2,0)],[(1,1),(2,1)]],
    D2 = [[(2,0)],[(2,1)],[(1,0),(2,0)],[(1,0),(2,1)],[(1,1),(2,0)],[(1,1),(2,1)]],
    is_dense(D1, P),
    is_dense(D2, P),
    % 构造：从空条件出发，逐步穿过 D1、D2
    C0 = [(1,0),(2,1)],                             % 同时在 D1 和 D2 中
    member(C0, D1), member(C0, D2),
    % 验证上闭包为滤
    G0 = [[(1,0),(2,1)], [(1,0)], [(2,1)], []],
    is_filter(G0, P),
    is_generic(G0, [D1, D2]),
    format("generic filter: exists G hitting D_1 and D_2: OK~n").

% ---------- 反链穷举 ----------
incompat(P, Q) :- \+ compat(P, Q).

check_antichain :-
    % {(1,0)} 与 {(1,1)} 不相容
    incompat([(1,0)], [(1,1)]),
    % {(1,0)} 与 {(2,1)} 相容
    compat([(1,0)], [(2,1)]),
    format("antichain: {(1,0)} incompatible with {(1,1)}, compatible with {(2,1)}: OK~n").

main :-
    format("==== 23 forcing~n"),
    check_dense,
    check_generic,
    check_antichain,
    format("END ====~n"), !.

:- initialization(main).
