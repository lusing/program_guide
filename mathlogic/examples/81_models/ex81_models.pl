:- encoding(utf8).
% ex81_models.pl —— 算术的模型（Marker ch16）搜索面
%
% 与 Coq/Lean 通道（有限可满足+overspill 影子+R(3,3)=6 双账+
% PH(2,2) 账）互补，这里跑回溯搜索本体：
%   no_triangle/2 —— K5 三角无关染色的回溯搜索（计数：恰 12 个
%                     ——五圈边选红或选蓝的 2×C5 外加翻转）；
%   ph2_account   —— [m]^2 的 min-homogeneous 平凡成立的机制账
%                     （含 0 的齐色对即满足 |X|>min X）。

% 边染色：位置公式 pos(i,j) = i(i−1)/2 + j（i>j）
colorAt(Col, I, J, C) :- P is I*(I-1)//2 + J, nth0(P, Col, C).

pick(0). pick(1).

mono_tri(M, Col) :-
    between(0, M, I), between(0, I, J), J < I,
    between(0, J, K), K < J,
    colorAt(Col, I, J, A), colorAt(Col, I, K, B), colorAt(Col, J, K, D),
    A = B, A = D.

no_triangle(M, Col) :-
    NE is M*(M-1)//2, length(Col, NE),
    maplist(pick_variant, Col),
    \+ mono_tri(M, Col).
pick_variant(C) :- pick(C).

% [m]^2 的 min-hom：齐色对 {0,B} 即满足（|X|=2 > min=0）
minhom2_pair(M, Col) :-
    between(1, M, B),
    colorAt(Col, B, 0, _).   % 单边集合自动齐色——平凡见证

ph2_account(M) :-
    findall(_, minhom2_pair(M, _), L), length(L, N),
    format("min-hom pairs {0,B} in [~d] : ~d witnesses (trivial: |X|=2>0)~n", [M, N]).

main :-
    format("== K5 triangle-free colorings (backtracking) ==~n"),
    findall(C, no_triangle(5, C), Cs),
    length(Cs, N),
    format("K5 triangle-free 2-colorings : ~w~n", [N]),
    ( N > 0 -> format("first witness            : ~w~n", [Cs]) ; true ),
    ph2_account(5),
    format("==== ex47 models END ====~n").
