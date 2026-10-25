:- encoding(utf8).
% 第 87 章 · 可构造宇宙 L 与一般连续统假设（冯琦第二卷 §2.1）——Prolog 通道
% 有限样品：V 层次与 L_n = V_n（引理 2.1(3)）、带参数析取定义、
% <_L 出生层秩序与末端延伸（定义 2.14/2.15）、定义闭包的生长。

% ---------- 层次：集合表示为排序去重的项列表 ----------

% 幂集：位掩码生成，全部子集经 sort/2 规范化（去重 + 标准序）。
powerset_hf(P, S) :-
    length(P, K),
    N is 1 << K,
    N1 is N - 1,
    findall(Sub, (between(0, N1, M), mask_sub(P, M, Sub)), Subs0),
    sort(Subs0, S).

mask_sub([], _, []).
mask_sub([X | Xs], M, Sub) :-
    M1 is M >> 1,
    (   M mod 2 =:= 0
    ->  Sub = Rest
    ;   Sub = [X | Rest]
    ),
    mask_sub(Xs, M1, Rest).

vlevel(0, []).
vlevel(N, L) :-
    N > 0,
    N1 is N - 1,
    vlevel(N1, Prev),
    powerset_hf(Prev, L).

% ---------- 带参数析取定义（L_n = V_n 的引擎） ----------

% 公式「x = a_1 ∨ ... ∨ x = a_k」在 M 上定义的子集恰是 B 本身。
ext_disj(M, B, X) :-
    member(X, M),
    member(X, B).

all_subsets_definable(M) :-
    powerset_hf(M, Subs),
    forall((member(B, Subs), member(X, M)),
           ((   member(X, B)
            ->  ext_disj(M, B, X)
            ;   \+ ext_disj(M, B, X)
            ))).

% ---------- <_L 出生层秩序 ----------

born(X, B) :-
    between(0, 4, N),
    vlevel(N, L),
    \+ member(X, L),
    N1 is N + 1,
    vlevel(N1, L1),
    member(X, L1),
    !,
    B is N.

% 同层内以该层规范列表中的位置为码（有限样品；正文完整版是
% 「最小公式指数 + 参数字典序」，定义 2.13/2.17）。
pos_in_level(X, P) :-
    born(X, B),
    N1 is B + 1,
    vlevel(N1, L1),
    nth0(P, L1, X).

lt_l(X, Y) :-
    X \== Y,
    born(X, BX), born(Y, BY),
    (   BX < BY
    ->  true
    ;   BX =:= BY,
        pos_in_level(X, PX), pos_in_level(Y, PY),
        PX < PY
    ).

% 层的典范序：按（出生层，层内位置）排序。
key_born_pos(X, B - P) :-
    born(X, B),
    pos_in_level(X, P).

level_order(N, Ord) :-
    vlevel(N, L),
    map_list_to_pairs(key_born_pos, L, KP),
    sort(2, @=<, KP, KPSorted),
    pairs_values(KPSorted, Ord).

strict_total_order(Ls) :-
    % 三分性：任两个不同元素恰有一向
    forall((member(A, Ls), member(B, Ls), A \== B),
           (   lt_l(A, B) -> \+ lt_l(B, A) ; lt_l(B, A) )),
    % 传递性
    forall((member(A, Ls), member(B, Ls), member(C, Ls)),
           (   (lt_l(A, B), lt_l(B, C)) -> lt_l(A, C) ; true )).

% 末端延伸（定义 2.14(b)）：L_4 序限制在 L_3 上 = L_3 序。
orders_agree(NBig, NSmall) :-
    level_order(NBig, Big),
    vlevel(NSmall, Ln),
    findall(X, (member(X, Big), member(X, Ln)), Restricted),
    level_order(NSmall, Small),
    Restricted == Small.

% ---------- 定义闭包的生长（凝聚化引理的有限影子） ----------

% 从种子出发在 <_L 后继下封闭：<_L 的后继函数是可定义的（秩序本身
% 可定义），因而是「斯科伦函数」的最小样品；闭包吞下整个层——
% 初等闭包把小集合撑满的有限形态。
nextto_(X, Y, [X, Y | _]).
nextto_(X, Y, [_ | T]) :- nextto_(X, Y, T).

succ_l(X, Y) :-
    level_order(3, Ord3),
    nextto_(X, Y, Ord3).

closure_loop(Cur, Hull) :-
    findall(Y, (member(X, Cur), succ_l(X, Y), \+ member(Y, Cur)), New),
    (   New == []
    ->  sort(Cur, Hull)
    ;   union(Cur, New, Next),
        closure_loop(Next, Hull)
    ).

% ---------- 主程序 ----------

main :-
    writeln("==== 87"),
    forall(member(N, [0, 1, 2, 3, 4]),
           (   vlevel(N, L),
               length(L, K),
               format("V_~d 层规模 ~d~n", [N, K])
           )),
    vlevel(3, V3),
    all_subsets_definable(V3),
    writeln("V_3 的 16 个子集全部由带参数析取式定义：L_3 = V_3 ✓"),
    vlevel(4, L4),
    strict_total_order(L4),
    writeln("<_L 在 L_4 上严格全序（三分 + 传递）✓"),
    orders_agree(4, 3),
    writeln("L_4 序限制在 L_3 上与 L_3 序一致：末端延伸 ✓"),
    level_order(3, L3o),
    L3o = [First | _],
    closure_loop([First], Hull3),
    length(Hull3, 4),
    writeln("单点种子的 <_L-后继闭包吞下整个 L_3：定义闭包的生长 ✓"),
    writeln("END ====").
