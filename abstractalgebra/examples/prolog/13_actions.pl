:- encoding(utf8).
% 第 13 章 · 群作用 —— Prolog 通道
%
% 项链轨道（ℤ₆ 旋转作用在 2 色 6 珠）+ 轨道大小整除群阶（推论 2.142）。

% ---------- 染色与作用 ----------
% 染色编码为 0..63（6 位二进制，每珠 1 色）
coloring(C) :- between(0, 63, C).
bit(C, I, B) :- B is (C >> I) mod 2.

% 旋转 k 步：第 i 珠的颜色 ← 第 (i−k) mod 6 珠
rotated(C, K, R) :-
    foldl_rot(5, C, K, 0, R).
foldl_rot(-1, _, _, R, R) :- !.
foldl_rot(I, C, K, Acc0, R) :-
    J is (I + K) mod 6,
    bit(C, J, B),
    Acc is Acc0 + (B << I),
    I1 is I - 1,
    foldl_rot(I1, C, K, Acc, R).

% 轨道：0..5 步旋转的像集合
orbit(C, O) :-
    findall(R, (between(0, 5, K), rotated(C, K, R)), O0),
    sort(O0, O).

% ---------- 断言 ----------
main :-
    format("==== 13 群作用~n"),

    % 全部染色的轨道归并：恰 14 条（Burnside 的暴力版）
    collect_orbits(0, [], Orbits),
    length(Orbits, N),
    N == 14,
    format("2 色 6 珠项链（旋转等价）：轨道恰 ~d 条 ✓~n", [N]),

    % 每条轨道大小整除 6（推论 2.142）
    forall(member(O, Orbits),
           (length(O, L), 6 mod L =:= 0)),
    format("推论 2.142：每条轨道大小 ∈ {1,2,3,6}，整除群阶 ✓~n"),

    % 单色轨道 2 条、全色循环轨道（大小 6）的条数
    include(size(1), Orbits, Ones), length(Ones, N1), N1 == 2,
    include(size(6), Orbits, Sixes), length(Sixes, N6),
    format("轨道谱：1 元轨道 ~d 条（全白/全黑），6 元轨道 ~d 条 ✓~n", [N1, N6]),

    format("END ====~n").

size(N, L) :- length(L, N).

collect_orbits(64, Acc, Out) :- !,
    maplist(sort, Acc, S0), sort(S0, Out).
collect_orbits(C, Acc, Out) :-
    (   member(O, Acc), member(C, O) ->
        Acc1 = Acc
    ;   orbit(C, O), Acc1 = [O | Acc]
    ),
    C1 is C + 1,
    collect_orbits(C1, Acc1, Out).
