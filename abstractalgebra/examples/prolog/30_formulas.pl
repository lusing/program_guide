:- encoding(utf8).
% 第 30 章 · 经典公式 —— Prolog 通道
%
% 整数域精确验证：卡尔达诺内核恒等式、韦达定理、判别式分类、
% 费拉里恒等式（多点代入：n 次多项式恒等 ⟺ 在 n+1 个点取等）。

% ---------- 卡尔达诺内核：3uv = −p ⟹ (u+v)³ + p(u+v) = u³ + v³ ----------
kernel_ok(U, V, P) :-
    3 * U * V =:= -P,
    T is U + V,
    L is T*T*T + P*T,
    R is U*U*U + V*V*V,
    L =:= R.

% ---------- 韦达（三次）：T³ − S1·T² + S2·T − S3 在三根处为零 ----------
vieta_zero(R, S1, S2, S3) :-
    V is R*R*R - S1*R*R + S2*R - S3,
    V =:= 0.

vieta_case(R1, R2, R3) :-
    S1 is R1 + R2 + R3,
    S2 is R1*R2 + R1*R3 + R2*R3,
    S3 is R1 * R2 * R3,
    vieta_zero(R1, S1, S2, S3),
    vieta_zero(R2, S1, S2, S3),
    vieta_zero(R3, S1, S2, S3).

% ---------- 判别式符号：Δ = q²/4 + p³/27 与 27q² + 4p³ 同号 ----------
disc_sign(P, Q, Sgn) :-
    E is 27*Q*Q + 4*P*P*P,
    (E < 0 -> Sgn = neg ; E =:= 0 -> Sgn = zero ; Sgn = pos).

% 整数根暴力枚举（depressed 三次在 [−10,10] 内的整根）
int_roots(P, Q, Roots) :-
    findall(T, (between(-10, 10, T),
                V is T*T*T + P*T + Q, V =:= 0), Roots).

% ---------- 费拉里恒等式（16 倍缩放的整系数版） ----------
% 16·[(x²+s/2)² − ((s−p)x² − qx + (s²/4−r))] = 16·(x⁴+px²+qx+r)
% 左边 = (4x²+2s)² − [16(s−p)x² − 16qx + 4s² − 16r]
ferrari_lh(P, Q, R, S, X, V) :-
    A is 4*X*X + 2*S,
    B is 16*(S-P)*X*X - 16*Q*X + 4*S*S - 16*R,
    V is A*A - B.
ferrari_rh(P, Q, R, X, V) :-
    X2 is X*X, X4 is X2*X2,
    V is 16*X4 + 16*P*X2 + 16*Q*X + 16*R.

% 预解完全平方：q² = (s−p)(s²−4r)
resolvent_square(P, Q, R, S) :-
    Q*Q =:= (S-P)*(S*S - 4*R).

% 完全平方式多点核对（四次恒等式：5 点足够，取 6 点）
ferrari_identity(P, Q, R, S) :-
    forall(between(-3, 2, X),
           (ferrari_lh(P, Q, R, S, X, L),
            ferrari_rh(P, Q, R, X, Rt),
            L =:= Rt)).

% ---------- 三次恒等式多点核对 ----------
% t³ − 3t + 2 = (t−1)²(t+2)（Δ = 0 的重根案）
double_root_identity :-
    forall(between(-2, 2, T),
           (L is T*T*T - 3*T + 2,
            M is (T-1)*(T-1)*(T+2),
            L =:= M)).

% ---------- 主流程 ----------
main :-
    format("==== 30 经典公式~n"),

    % 卡尔达诺内核：u,v ∈ [−3,3] 全网格（p = −3uv 随动）
    forall((between(-3, 3, U), between(-3, 3, V), P is -3*U*V),
           kernel_ok(U, V, P)),
    format("卡尔达诺内核：3uv = −p ⟹ (u+v)³ + p(u+v) = u³+v³（49 组整数全过）✓~n"),

    % 韦达：根取自 [−3,3] 的全部 343 组
    forall((between(-3, 3, R1), between(-3, 3, R2), between(-3, 3, R3)),
           vieta_case(R1, R2, R3)),
    format("韦达定理：三次根-系数恒等式（343 组整数根全过）✓~n"),

    % t³ − 7t + 6：Δ < 0、三个整根全回收
    disc_sign(-7, 6, neg),
    int_roots(-7, 6, [-3, 1, 2]),
    format("t³−7t+6：Δ = −400/108 < 0，整根 {−3, 1, 2} 全回收（Δ<0 ⟺ 三实根）✓~n"),

    % t³ − t：Δ < 0、三实根
    disc_sign(-1, 0, neg),
    int_roots(-1, 0, [-1, 0, 1]),
    format("t³−t：Δ < 0，根 {−1, 0, 1} ✓~n"),

    % t³ − 3t + 2 = (t−1)²(t+2)：Δ = 0 的重根案
    disc_sign(-3, 2, zero),
    double_root_identity,
    D1 is 3*1*1 - 3, D1 =:= 0,          % 导数 3t²−3 在 t=1 处为零 ⟹ 重根
    format("t³−3t+2：Δ = 0，(t−1)²(t+2) 恒等 + 导数在 1 处为零（重根）✓~n"),

    % t³ + 3t + 2：Δ > 0、无整根（严格递增 ⟹ 恰一实根，见正文）
    disc_sign(3, 2, pos),
    int_roots(3, 2, []),
    format("t³+3t+2：Δ > 0 且无整根（严格递增 ⟹ 恰一实根）✓~n"),

    % 费拉里两案：x⁴−9x²+4x+12（s=7）与 x⁴−5x²+4（s=4）
    ferrari_identity(-9, 4, 12, 7),
    resolvent_square(-9, 4, 12, 7),
    format("费拉里：x⁴−9x²+4x+12 的恒等式（6 点代入）+ 预解完全平方 4² = 16·1 ✓~n"),
    ferrari_identity(-5, 0, 4, 4),
    resolvent_square(-5, 0, 4, 4),
    format("费拉里：x⁴−5x²+4（q=0 退化）恒等式 + 预解完全平方 0 = 9·0 ✓~n"),

    format("END ====~n").
