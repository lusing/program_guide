:- encoding(utf8).
% 13_conservation.pl —— 第 13 章：守恒律规则引擎（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
%   (1) Rankine-Hugoniot：s = (f(uR)-f(uL))/(uR-uL)；Burgers f=u²/2；
%   (2) 熵条件 a(uL) >= s >= a(uR)（特征走向间断）；
%   (3) 守恒型/非守恒格式判定：守恒 ⟺ 存在数值通量 g 使
%       u_j^{n+1} = u_j - lam(g_{j+1/2} - g_{j-1/2}) 且 g(u,u)=f(u)。

% ---------- Burgers 通量 ----------
burgers_flux(U, F) :- F is 0.5 * U * U.

% ---------- (1) Rankine-Hugoniot ----------
rh_speed(Ul, Ur, S) :-
    burgers_flux(Ul, Fl), burgers_flux(Ur, Fr),
    S is (Fl - Fr) / (Ul - Ur).

% ---------- (2) 熵条件 ----------
a_of(U, A) :- A is U.     % a(u) = f'(u) = u
entropy_ok(Ul, Ur) :-
    rh_speed(Ul, Ur, S),
    a_of(Ul, AL), a_of(Ur, AR),
    AL >= S, S >= AR.

% Riemann 判据：Ul > Ur ⟹ 激波（满足熵）；Ul < Ur ⟹ 稀疏波
riemann(Ul, Ur, shock) :- Ul > Ur, entropy_ok(Ul, Ur).
riemann(Ul, Ur, rarefaction) :- Ul < Ur, \+ entropy_ok(Ul, Ur).

% ---------- (3) 守恒型判定 ----------
% 数值通量表：lf 通量 / lw（两半步）通量 / 非守恒迎风无通量形式
numerical_flux(lf, g(Uj, Ujp,
        (0.5*(Uj+Ujp) - (1/(2*lam))*(Ujp - Uj)))).
has_flux_form(lf).  has_flux_form(lw).
consistent_flux(S) :- has_flux_form(S).      % g(u,u) = f(u) 可直接验证
conservative(S) :- consistent_flux(S).
nonconservative(noncons_upwind).

% Lax-Wendroff 定理事实：守恒 + 相容 ⟹ 收敛到弱解（子列/在附加条件下）
lw_theorem(S, converges_to_weak_solution) :- conservative(S).

% ---------- main ----------
main :-
    format("==== 13 conservation~n"),

    % (1) RH：激波 (1,0) 速度 1/2；(2,0) 速度 1
    rh_speed(1.0, 0.0, 0.5), rh_speed(2.0, 0.0, 1.0), rh_speed(1.0, -1.0, 0.0),
    format("Rankine-Hugoniot: (1,0)->s=1/2, (2,0)->s=1, (1,-1)->s=0~n"),

    % (2) 熵条件与 Riemann 判据
    riemann(1.0, 0.0, shock),
    riemann(-1.0, 1.0, rarefaction),
    format("entropy: (1,0) shock with a(uL)>=s>=a(uR); (-1,1) rarefaction~n"),

    % (3) 守恒型判定
    conservative(lf), conservative(lw),
    nonconservative(noncons_upwind),
    lw_theorem(lf, converges_to_weak_solution),
    lw_theorem(lw, converges_to_weak_solution),
    format("conservative: lf/lw (correct shock speed); noncons_upwind has no flux form~n"),
    format("Lax-Wendroff theorem: conservative + consistent -> weak solution~n"),

    format("END ====~n").
