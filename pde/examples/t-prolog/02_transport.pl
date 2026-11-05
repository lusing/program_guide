% Ch02 传输方程：特征线规则引擎
%
% 对应书 §2.1：特征线（方向 (b,1) 的直线）、初值公式 u(x,t)=g(x-tb)、
% 非齐次 Duhamel 结构、弱解声明。规则以符号项表达解的结构。

:- encoding(utf8).

% 特征线：过点 (X,T) 沿方向 (b,1) 的直线在 t=0 的足点
foot(X, T, B, X0) :- X0 is X - T * B.

% 特征线上的点
on_characteristic(X, T, B, S, Xs, Ts) :- Xs is X + S * B, Ts is T + S.

% 齐次解公式：solve(g, b, u) 其中解是 shift(g, -b*t)
homog_solution(g, B, shift(g, mul(-1.0, mul(B, t)))).

% 弱解规则：g 不 C^1 时公式 (3) 仍是唯一合理候选（书 p.19）
weak_candidate(g, B) :- homog_solution(g, B, _).

% 非齐次结构：homogeneous + Duhamel 积分
duhamel_structure(g, B, f,
    add(shift(g, mul(-1.0, mul(B, t))), integral(0, t, f_at(mul(-1.0, mul(B, t)))))).

% 数值内核：沿特征线的 Duhamel 积分（复化 Simpson）
duhamel_value(F, X, T, B, V) :-
    N = 512,
    H is T / N,
    simpson_sum(F, X, T, B, 0, N, H, 0.0, S),
    V is S * H / 3.

% 终止子句必须累加右端点样本（权重 1）：初版在 K=N 直接返回，
% 吞掉 f(T)，误差恰为 (h/3)·f(T)、收敛退化到 O(h)——被
% "N 加倍误差减半"的收敛表当场翻案。
simpson_sum(F, X, T, B, N, N, H, Acc, Out) :- !,
    XS is X + (N * H - T) * B,
    call(F, XS, N * H, FS),
    Out is Acc + FS.
simpson_sum(F, X, T, B, K, N, H, Acc, Out) :-
    SK is K * H,
    (  K =:= 0 -> W = 1.0
    ;  0 is K mod 2 -> W = 2.0
    ;  W = 4.0
    ),
    XS is X + (SK - T) * B,
    call(F, XS, SK, FS),
    Acc1 is Acc + W * FS,
    K1 is K + 1,
    simpson_sum(F, X, T, B, K1, N, H, Acc1, Out).

% 测试被积函数 f(x,t) = e^{-t} cos(x) 与闭式
f1(X, T, V) :- V is exp(-T) * cos(X).
f1_closed(X, T, V) :-
    A is X - T,
    V is (exp(-T) * (sin(A + T) - cos(A + T)) - (sin(A) - cos(A))) / 2.

main :-
    format("==== 02~n"),
    % 特征足点
    foot(1.0, 2.0, 0.7, X0),
    format("foot of (1.0,2.0), b=0.7: x0 = ~3f~n", [X0]),
    abs(X0 - (1.0 - 2.0 * 0.7)) < 1e-12,
    % 特征线往返
    on_characteristic(1.0, 2.0, 0.7, -2.0, Xs, Ts),
    Ts =:= 0.0,
    abs(Xs - (1.0 - 2.0 * 0.7)) < 1e-12,
    % 齐次解结构 + 弱解声明
    homog_solution(g, 0.7, U),
    format("homogeneous solution term: ~w~n", [U]),
    weak_candidate(g, 0.7),
    duhamel_structure(g, 0.7, f, D),
    format("duhamel structure: ~w~n", [D]),
    % Duhamel 数值 vs 闭式（三点对账）
    forall(member((X, T), [ (0.3, 1.0), (-0.7, 2.3), (1.5, 0.4) ]),
           ( duhamel_value(f1, X, T, 1.0, V),
             f1_closed(X, T, C),
             Dv is abs(V - C),
             format("duhamel(x=~w,t=~w): simpson ~6f  closed ~6f  |d|=~2e~n", [X, T, V, C, Dv]),
             Dv < 1e-8 )),
    format("END ====~n").
