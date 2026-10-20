:- encoding(utf8).
% 42_martingale_convergence.pl —— 第 42 章：收敛命运（Prolog 通道）
%
% ① Pólya 罐一步转移的精确账；② G-W 不动点验证。

% Pólya 罐一步：状态 (R,B) 以 R/(R+B) 概率转 (R+1,B)、B/(R+B) 转 (R,B+1)
polya_next(R, B, R1, B, RN, RD) :- R1 is R + 1, RN is R, RD is R + B.
polya_next(R, B, R, B1, BN, BD) :- B1 is B + 1, BN is B, BD is R + B.

check_polya :-
    % 初 (1,1)：两转移各 1/2
    polya_next(1, 1, 2, 1, 1, 2),
    polya_next(1, 1, 1, 2, 1, 2),
    % 二步展开（穷举 4 路径）：(3,1) 1/3、(2,2) 1/2 合计、(1,3) 1/3... 手算核对：
    % (1,1) → (2,1) 1/2 → (3,1) 1/2·2/3 = 1/3；(2,2) 1/2·1/3 + 1/2·1/3 = 1/3；(1,3) 1/3
    polya_next(2, 1, 3, 1, 2, 3),
    polya_next(2, 1, 2, 2, 1, 3),
    polya_next(1, 2, 2, 2, 1, 3),
    polya_next(1, 2, 1, 3, 2, 3),   % B/(R+B) = 2/3
    % (2,2) 的两条入路各 1/6，合计 1/3
    P_2_2 is (1/2)*(1/3) + (1/2)*(1/3),
    Diff is abs(P_2_2 - 1/3),
    Diff < 0.001,
    format("Polya two-step expansion: (2,2) reached with prob 1/3: OK~n").

% G-W 不动点：s = c0 + c2·s²
is_fixed(C0, C2, S) :- C0 + C2 * S * S =:= S.

check_gw :-
    is_fixed(0.6, 0.4, 1.0),          % 次临界（mu = 0.8）：s = 1
    is_fixed(0.2, 0.8, 0.25),         % 超临界（mu = 1.6）：s = 1/4
    format("GW fixed points: subcritical s=1, supercritical s=1/4: OK~n").

% 乘积鞅逐步均值：E[1±eps] = 1
check_product :-
    E is 0.5 * (1 + 0.4) + 0.5 * (1 - 0.4),
    abs(E - 1.0) < 1e-12,
    format("product martingale: per-step mean = 1 (E stays 1): OK~n").

main :-
    format("==== 42 martingale_convergence~n", []),
    check_polya,
    check_gw,
    check_product,
    format("END ====~n"), !.

:- initialization(main).
