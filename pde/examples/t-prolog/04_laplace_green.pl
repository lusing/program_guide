% Ch04 Laplace 方程 II：调和性质规则库与镜像规则
%
% 对应书 §2.2.3（极值原理/唯一性/正则性/解析性/Harnack/Liouville）
% 与 §2.2.4（Green 函数结构）。规则：
%   harmonic_property/2     —— 性质 → 一句话依据（都追溯到平均值公式）
%   reflect/3               —— 反射（平面镜像 / 球反演）
%   green_structure/2       —— G = Φ − Φ_image 的结构规则
%   harnack_bound/4         —— (1+r)/(1-r) 常数
% 数值内核：反演点计算与镜像恒等式对账（Lean 已完整证明恒等式）。

:- encoding(utf8).

harmonic_property(strong_max, 'max on boundary; interior max implies const (mean value)').
harmonic_property(uniqueness, 'difference of two solutions harmonic with zero data').
harmonic_property(smoothness, 'u = mollified u: mean value kills epsilon (Thm 6)').
harmonic_property(analyticity, 'derivative estimates (Thm 7) -> Taylor converges').
harmonic_property(liouville, 'bounded entire harmonic -> const (mean value + large balls)').
harmonic_property(harnack, 'positive harmonic: sup <= (1+r)/(1-r) inf on B_r').

% 反射规则
reflect(plane, X, Xr) :- Xr is -X.                       % 半空间镜像（1D 截面）
reflect(sphere, X, Xr) :- X \= 0, Xr is 1 / X.           % 单位圆反演（1D 半径坐标）

% Green 函数结构：G(x,y) = Phi(y-x) - Phi(image)
green_structure(U, 'G = Phi(y-x) - Phi^x(y), corrector Phi^x solves Lap=0, bdry = Phi(y-x)').
green_method(half_space, 'image across the plane: Phi(x-y) - Phi(x-y*)').
green_method(ball, 'inversion: Phi(y-x) - Phi(|x||y-x*|), x* = x/|x|^2').

% Harnack 常数
harnack_bound(R, C) :- C is (1 + R) / (1 - R), R < 1, R >= 0.

% 数值内核：2D 反演点与镜像恒等式
invert2(X1, X2, Xs1, Xs2) :- S is X1^2 + X2^2, Xs1 is X1 / S, Xs2 is X2 / S.
image_gap(X1, X2, Y1, Y2, Gap) :-
    invert2(X1, X2, Xs1, Xs2),
    LHS is (Y1 - X1)^2 + (Y2 - X2)^2,
    RHS is (X1^2 + X2^2) * ((Y1 - Xs1)^2 + (Y2 - Xs2)^2),
    Gap is abs(LHS - RHS).

main :-
    format("==== 04~n"),
    harmonic_property(P, Why), format("  ~w: ~s~n", [P, Why]), fail.
main :- continue.

continue :-
    green_method(half_space, M1), format("half-space: ~s~n", [M1]),
    green_method(ball, M2), format("ball: ~s~n", [M2]),
    % 反演对账：|x|·|x*| = 1
    invert2(0.3, 0.4, S1, S2),
    Prod is sqrt(0.3^2 + 0.4^2) * sqrt(S1^2 + S2^2),
    abs(Prod - 1) < 1e-15,
    format("inversion: |x|*|x*| = ~6f~n", [Prod]),
    % 镜像恒等式在 12 个边界点上
    worst(0.3, 0.4, W),
    W < 1e-14,
    format("image identity worst gap on boundary: ~2e~n", [W]),
    % Harnack 常数
    harnack_bound(0.6, C), abs(C - 4.0) < 1e-12,
    format("harnack constant r=0.6: ~6f (=4, saturated by u=1+x)~n", [C]),
    format("END ====~n").

worst(X1, X2, W) :- worst_(X1, X2, 0, 12, 0.0, W).
worst_(_, _, K, K, Acc, Acc) :- !.
worst_(X1, X2, K, N, Acc, Out) :-
    Th is 2 * pi * K / N,
    image_gap(X1, X2, cos(Th), sin(Th), Gap),
    Acc1 is max(Acc, Gap),
    K1 is K + 1,
    worst_(X1, X2, K1, N, Acc1, Out).
