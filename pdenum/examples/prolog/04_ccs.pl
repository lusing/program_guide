:- encoding(utf8).
% 04_ccs.pl —— 第 04 章：相容性/收敛性/稳定性三问协议（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
% Lax 等价定理做成规则引擎：
%   适定线性初值问题 + 相容格式 ⟹ 收敛 ⟺ 稳定。
%   反例协议：相容 + 不稳定 ⟹ 无收敛保证（输出 not_convergent）。

% ---------- 问题库 ----------
problem(advection_ivp, linear, wellposed).
problem(diffusion_ivp, linear, wellposed).
problem(wave_ivp, linear, wellposed).
problem(navier_stokes, nonlinear, wellposed).   % 非线性：Lax 定理不适用

% ---------- 格式库 ----------
% scheme(名, 问题, 截断阶(τ), 截断阶(h), 稳定性)
scheme(ftbs,            advection_ivp, 1, 1, cond_stable(lam_le, 1)).
scheme(ftfs,            advection_ivp, 1, 1, unstable).
scheme(ftcs_advection,  advection_ivp, 1, 2, unstable).
scheme(lf,              advection_ivp, 1, 2, cond_stable(lam_le, 1)).
scheme(ftcs_heat,       diffusion_ivp,  1, 2, cond_stable(r_le, 0.5)).
scheme(btcs_heat,       diffusion_ivp,  1, 2, uncond_stable).
scheme(richardson,      diffusion_ivp,  2, 2, unstable).

consistent(S) :- scheme(S, _, P, Q, _), P > 0, Q > 0.

% ---------- Lax 协议 ----------
lax(S, convergent) :-
    scheme(S, Prob, _, _, Stab),
    problem(Prob, linear, wellposed),
    consistent(S),
    stable_kind(Stab).
lax(S, not_convergent_guaranteed) :-
    scheme(S, Prob, _, _, unstable),
    problem(Prob, linear, wellposed),
    consistent(S).

stable_kind(cond_stable(_, _)).
stable_kind(uncond_stable).

% ---------- 误差传播：书 (2.11) 二项式账 ----------
% FTBS 交替符号初值误差 ε：解在 (x_j, t_n) 的误差为
%   Σ_k C(n,k) (1+aλ)^(n-k) (-aλ)^k ε，取绝对值放大 (1+2aλ)^n
binomial_growth(Mu, N, G) :- G is (1 + 2 * Mu) ^ N.

% ---------- main ----------
main :-
    format("==== 04 ccs~n"),

    % (1) 全部格式相容
    forall(scheme(S, _, _, _, _),
           ( consistent(S), format("consistent: ~w~n", [S]) )),

    % (2) Lax 协议裁决
    lax(ftbs, convergent),
    lax(lf, convergent),
    lax(ftcs_heat, convergent),
    lax(btcs_heat, convergent),
    lax(ftcs_advection, not_convergent_guaranteed),
    lax(ftfs, not_convergent_guaranteed),
    lax(richardson, not_convergent_guaranteed),
    format("lax verdict: ftbs/lf/ftcs_heat/btcs -> convergent;~n"),
    format("             ftcs_advection/ftfs/richardson -> no convergence guarantee~n"),

    % (3) 非线性问题不适用：navier_stokes 无格式条目也查不到结论
    \+ ( scheme(_, navier_stokes, _, _, _) ),
    format("navier-stokes: nonlinear, Lax theorem does not apply~n"),

    % (4) 二项式误差传播账：aλ=0.5, n=9 → (1+1)^9 = 512
    binomial_growth(0.5, 9, G9), G9 =:= 512.0,
    binomial_growth(0.5, 20, G20), G20 > 1.0e6,
    format("alternating-error growth (1+2*lam)^n: n=9 -> ~w, n=20 -> ~w~n",
           [G9, round(G20)]),

    format("END ====~n").
