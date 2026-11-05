:- encoding(utf8).
% 08_cfl_leapfrog.pl —— 第 08 章：CFL 协议与蛙跳规则（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
%   (1) CFL 条件计算器：依赖区间 [x-nh, x+nh] 包含特征线足点
%       x - a*n*tau  ⟺ |lambda| <= 1；
%   (2) CFL 必要/充分性裁决库；
%   (3) 蛙跳特征值规则与 lambda=1 退化情形。

% ---------- (1) CFL 条件计算 ----------
% 差分格式 n 步的依赖区间端点：x_j ± n*h；PDE 依赖足点 x_j - a*n*tau
% 成功/失败式判定（坑账：小写 contained 是原子不是变量）
cfl_contains(A, Tau, H, N) :-
    Half is N * H,
    Foot is abs(A * N * Tau),
    Foot =< Half.

report_cfl(A, Tau, H, N) :-
    Lam is A * Tau / H,
    ( cfl_contains(A, Tau, H, N) -> C = yes ; C = no ),
    format("lambda = ~w: |a*n*tau| vs n*h -> contained = ~w~n", [Lam, C]).

% ---------- (2) 必要/充分性裁决 ----------
% 收敛 ⟹ CFL 对一切格式成立（必要）
cfl_necessary(all_schemes).
% 充分性：逐格式
cfl_sufficient(lw).           % LW 稳定条件恰为 CFL，Lax 定理抬为收敛
cfl_not_sufficient(ftcs_advection).  % 满足 CFL 却无条件不稳定
cfl_not_sufficient(leapfrog_at_1).   % λ=1 满足 CFL 但退化不稳定

% ---------- (3) 蛙跳特征值 ----------
% μ± = −iλsinθ ± sqrt(1−λ²sin²θ)，模方 = λ²sin²θ + (1−λ²sin²θ) = 1
leapfrog_modsq(Lam, Theta, 1.0) :- B is Lam * sin(Theta), B * B =< 1.0.

% lambda = 1、kh = pi/2 退化：G^n 范数按 2^{n/2} 增长（书 §1.6）
leapfrog_degenerate_growth(N, G) :- G is 2 ^ (N / 2).

% ---------- main ----------
main :-
    format("==== 08 cfl leapfrog~n"),

    % (1) 三组参数的依赖区间检查
    report_cfl(1.0, 0.004, 0.005, 100),           % λ=0.8
    report_cfl(1.0, 0.005, 0.005, 100),           % λ=1.0
    report_cfl(1.0, 0.006, 0.005, 100),           % λ=1.2
    cfl_contains(1.0, 0.004, 0.005, 100),
    cfl_contains(1.0, 0.005, 0.005, 100),
    \+ cfl_contains(1.0, 0.006, 0.005, 100),

    % (2) 裁决表
    cfl_necessary(all_schemes),
    cfl_sufficient(lw),
    cfl_not_sufficient(ftcs_advection),
    format("verdict: CFL necessary for all; sufficient for lw; not for ftcs_advection~n"),

    % (3) 蛙跳：λ<1 特征值在单位圆上；λ=1 退化增长
    forall(member(Th, [0.3, 0.7, 1.2, 2.0]), leapfrog_modsq(0.8, Th, 1.0)),
    leapfrog_modsq(1.0, 1.5707963267948966, 1.0),
    format("leapfrog: |mu|^2 = 1 when lam*|sin(theta)| <= 1 (vN condition)~n"),
    leapfrog_degenerate_growth(20, G20), G20 > 1000,
    format("degenerate lam=1, kh=pi/2: ||G^n|| grows as 2^(n/2) (n=20 -> ~w)~n", [round(G20)]),

    format("END ====~n").
