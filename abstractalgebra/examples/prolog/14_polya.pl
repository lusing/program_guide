:- encoding(utf8).
% 第 14 章 · 用群计算：伯恩赛德与 Pólya —— Prolog 通道
%
% 旗子/项链/赌盘的 Pólya 计数 + 暴力轨道归并互证。

% ---------- 旗子：6 条纹 3 色，翻转 ----------
flag(C) :- between(0, 728, C).          % 三进制 6 位
flag_digit(C, I, D) :- D is (C // (3 ** I)) mod 3, integer(D).

flag_flip(C, F) :-
    D5 is (C // 243) mod 3, D4 is (C // 81) mod 3, D3 is (C // 27) mod 3,
    D2 is (C // 9) mod 3, D1 is (C // 3) mod 3, D0 is C mod 3,
    F is ((((D0 * 3 + D1) * 3 + D2) * 3 + D3) * 3 + D4) * 3 + D5.

flag_orbit(C, O) :- flag_flip(C, F), sort([C, F], O).

% ---------- 项链：2 色 6 珠（旋转，复用 13 章件） ----------
neck_coloring(C) :- between(0, 63, C).
bit(C, I, B) :- B is (C >> I) mod 2.
rotated(C, K, R) :- foldl_rot(5, C, K, 0, R).
foldl_rot(-1, _, _, R, R) :- !.
foldl_rot(I, C, K, Acc0, R) :-
    J is (I + K) mod 6,
    bit(C, J, B),
    Acc is Acc0 + (B << I),
    I1 is I - 1,
    foldl_rot(I1, C, K, Acc, R).
neck_orbit(C, O) :-
    findall(R, (between(0, 5, K), rotated(C, K, R)), O0),
    sort(O0, O).

% ---------- 赌盘：5 扇形 2 色（旋转） ----------
roul_coloring(C) :- between(0, 31, C).
rbit(C, I, B) :- B is (C >> I) mod 2.
rrotated(C, K, R) :- rfoldl(4, C, K, 0, R).
rfoldl(-1, _, _, R, R) :- !.
rfoldl(I, C, K, Acc0, R) :-
    J is (I + K) mod 5,
    rbit(C, J, B),
    Acc is Acc0 + (B << I),
    I1 is I - 1,
    rfoldl(I1, C, K, Acc, R).
roul_orbit(C, O) :-
    findall(R, (between(0, 4, K), rrotated(C, K, R)), O0),
    sort(O0, O).

% ---------- 轨道归并 ----------
collect_orbits(Next, _, Max, Acc, Out) :-
    Next >= Max, !,
    maplist(sort, Acc, S0), sort(S0, Out).
collect_orbits(Next, OrbitPred, Max, Acc, Out) :-
    (   member(O, Acc), member(Next, O) ->
        Acc1 = Acc
    ;   call(OrbitPred, Next, O), Acc1 = [O | Acc]
    ),
    Next1 is Next + 1,
    collect_orbits(Next1, OrbitPred, Max, Acc1, Out).

main :-
    format("==== 14 用群计算：伯恩赛德与 Pólya~n"),

    % 旗子：Pólya (3⁶ + 3³)/2 = 378；暴力互证
    collect_orbits(0, flag_orbit, 729, [], FOrbits),
    length(FOrbits, NF),
    NF == 378,
    format("6 条纹 3 色旗（翻转）：暴力轨道 = ~d = (3⁶+3³)/2 ✓~n", [NF]),

    % 项链：14
    collect_orbits(0, neck_orbit, 64, [], NOrbits),
    length(NOrbits, NN),
    NN == 14,
    format("2 色 6 珠项链（旋转）：暴力轨道 = ~d = (2⁶+2+2⁴+4+2+2)/6 ✓~n", [NN]),

    % 赌盘：(2⁵ + 4×2)/5 = 8
    collect_orbits(0, roul_orbit, 32, [], ROrbits),
    length(ROrbits, NR),
    NR == 8,
    format("5 扇形 2 色赌盘（旋转）：暴力轨道 = ~d = (2⁵+4×2)/5 ✓~n", [NR]),

    format("END ====~n").
