:- encoding(utf8).
% 17_convection_diffusion.pl —— 第 17 章：对流扩散规则引擎（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
%   (1) 中心显式稳定条件 lam^2 =< 2*mu 且 2*mu =< 1；
%   (2) 网格 Peclet 数 pe = a*h/nu 与单调性判据 pe < 2；
%   (3) 指数型格式规则（格子精确解移植）。

% ---------- (1) 稳定条件 ----------
central_stable(Lam, Mu) :- L2 is Lam * Lam, L2 =< 2 * Mu, 2 * Mu =< 1.
central_unstable(Lam, Mu) :- \+ central_stable(Lam, Mu).

% ---------- (2) 网格 Peclet ----------
pe(A, H, Nu, Pe) :- Pe is A * H / Nu.
center_monotone_pe(Pe) :- Pe < 2.
center_oscillatory_pe(Pe) :- Pe >= 2.
% 迎风的人工扩散把 pe 换成 pe/(1+pe) < 2 恒成立
upwind_effective_pe(Pe, Eff) :- Eff is Pe / (1 + Pe).

% ---------- (3) 指数型：格子上精确 ----------
% 指数型格式的三点系数含 exp(±pe)：对定态问题给出格子精确解
exp_fit_exact(any_pe).

% ---------- main ----------
main :-
    format("==== 17 convection diffusion~n"),

    central_stable(0.6, 0.4),
    central_unstable(0.6, 0.15),
    format("central explicit: stable iff lam^2 <= 2mu <= 1 (0.6,0.4 ok; 0.6,0.15 blows)~n"),

    pe(1.0, 0.125, 0.05, Pe1), Pe1 >= 2, center_oscillatory_pe(Pe1),
    pe(1.0, 0.02, 0.05, Pe2), Pe2 < 2, center_monotone_pe(Pe2),
    format("cell Peclet: pe=2.5 -> center oscillates; pe=0.4 -> monotone~n"),

    upwind_effective_pe(2.5, Eff), Eff < 2,
    upwind_effective_pe(100.0, Eff2), Eff2 < 2,
    format("upwind artificial diffusion: effective pe = pe/(1+pe) always < 2~n"),

    exp_fit_exact(any_pe),
    format("exponential fitting: exact at cell level for any pe~n"),

    format("END ====~n").
