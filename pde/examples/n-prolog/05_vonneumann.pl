:- encoding(utf8).
% 05_vonneumann.pl —— 第 05 章：增长因子规则引擎（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
% 增长因子 G(θ) 用复数 c(R,I) 表示，|G|² = R²+I²；
% 对 θ 网格扫描 max|G|，判稳定；格式库与判据书 §3.2/§3.3 一致。

% ---------- 复数底座 ----------
cabs2(c(R, I), V) :- V is R * R + I * I.

% ---------- 格式库：growth(Scheme, Mu, Theta, G) ----------
% FTCS-advection: G = 1 - i mu sin(theta)
growth(ftcs_advection, Mu, T, c(1.0, -I)) :- I is -Mu * sin(T).
% 迎风 FTBS: G = 1 - mu(1 - cos) - i mu sin
growth(upwind, Mu, T, c(R, I)) :-
    R is 1 - Mu * (1 - cos(T)), I is -Mu * sin(T).
% Lax-Friedrichs: G = cos(theta) - i mu sin(theta)
growth(lf, Mu, T, c(R, I)) :- R is cos(T), I is -Mu * sin(T).
% Lax-Wendroff: G = 1 - mu^2 (1-cos) - i mu sin
growth(lw, Mu, T, c(R, I)) :-
    R is 1 - Mu * Mu * (1 - cos(T)), I is -Mu * sin(T).
% FTCS 热传导: G = 1 - 4 r sin^2(theta/2)（实数）
growth(ftcs_heat, Rr, T, c(G, 0.0)) :- G is 1 - 4 * Rr * sin(T / 2) ^ 2.
% BTCS 热传导: G = 1 / (1 + 4 r sin^2(theta/2))（实数）
growth(btcs_heat, Rr, T, c(G, 0.0)) :- G is 1 / (1 + 4 * Rr * sin(T / 2) ^ 2).

% ---------- 扫描引擎 ----------
theta_grid(Ts) :-
    Ts = [0.05,0.15,0.30,0.50,0.75,1.00,1.25,1.50,1.75,2.00,
          2.25,2.50,2.75,3.00,3.10].

max_absG(Scheme, Mu, MaxG) :-
    theta_grid(Ts),
    findall(V,
            ( member(T, Ts), growth(Scheme, Mu, T, G), cabs2(G, V) ),
            Vs),
    max_list(Vs, M2),
    MaxG is sqrt(M2).

% 稳定判定（von Neumann：|G| <= 1 + O(tau)，扫描近似取 |G| <= 1）
stable(Scheme, Mu) :- max_absG(Scheme, Mu, M), M =< 1.0 + 1.0e-9.
unstable(Scheme, Mu) :- max_absG(Scheme, Mu, M), M > 1.0 + 1.0e-9.

% ---------- Richardson 规则（书例 3.4，闭式） ----------
richardson_mu2(Rr, S, Mu2) :-
    Disc is sqrt(16 * Rr * Rr * S * S + 1),
    Mu2 is -4 * Rr * S - Disc.
richardson_beyond(Rr, S) :- richardson_mu2(Rr, S, M), abs(M) > 1.0000001.

% ---------- main ----------
main :-
    format("==== 05 vonneumann~n"),

    % FTCS-advection 恒不稳
    forall(member(Mu, [0.3, 0.8, 1.0]), unstable(ftcs_advection, Mu)),
    format("ftcs_advection: unstable for mu = 0.3 / 0.8 / 1.0~n"),

    % 迎风：mu<=1 稳、mu>1 不稳
    forall(member(Mu, [0.5, 0.9, 1.0]), stable(upwind, Mu)),
    unstable(upwind, 1.5),
    format("upwind: stable for mu <= 1, unstable at mu = 1.5~n"),

    % LF 与 LW：|mu| <= 1
    forall(member(Mu, [0.5, 0.9, 1.0]), stable(lf, Mu)),
    unstable(lf, 1.1),
    forall(member(Mu, [0.5, 0.9, 1.0]), stable(lw, Mu)),
    unstable(lw, 1.1),
    format("lf / lw: stable for mu <= 1, unstable at mu = 1.1~n"),

    % FTCS 热传导：r <= 1/2；BTCS 无条件
    forall(member(R, [0.25, 0.5]), stable(ftcs_heat, R)),
    unstable(ftcs_heat, 0.6),
    forall(member(R, [0.25, 2.0, 50.0]), stable(btcs_heat, R)),
    format("ftcs_heat: stable iff r <= 1/2; btcs_heat: stable for all r~n"),

    % Richardson：s 取遍 (0,1]，r 取遍 [0.1,1]，恒有一支出界
    forall(member(R, [0.1,0.3,0.5,0.8,1.0]),
           forall(member(S, [0.05,0.25,0.5,0.75,1.0]),
                  richardson_beyond(R, S))),
    richardson_mu2(0.5, 1.0, M),
    format("richardson: |mu_-| > 1 for every r,s; at r=0.5,s=1: ~w~n", [M]),

    format("END ====~n").
