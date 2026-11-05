% Ch00 导言：方程动物园知识库（书 §1.2 名方程清单）
%
% 字段：pde(Name, Kind, Order, ScalarOrSystem, Structure)
%   Kind: linear | semilinear | quasilinear | fully_nonlinear
%   Order: 方程阶数（以最高阶导数计）
%   Structure: 主部类型一句话
% 查询：分类、按类列举、一致性审计（每条必有 kind/order）。

:- encoding(utf8).

pde(laplace,          linear, 2, scalar, 'elliptic: sum u_ij = 0').
pde(helmholtz,        linear, 2, scalar, 'eigenvalue of -Laplacian').
pde(transport,        linear, 1, scalar, 'first-order: u_t + b.Du = 0').
pde(liouville,        linear, 1, scalar, 'conservation form in x').
pde(heat,             linear, 2, scalar, 'parabolic: u_t = Lap u').
pde(schrodinger,      linear, 2, scalar, 'unitary: i u_t + Lap u = 0').
pde(kolmogorov,       linear, 2, scalar, 'backward equation of diffusion').
pde(fokker_planck,    linear, 2, scalar, 'forward equation of diffusion').
pde(wave,             linear, 2, scalar, 'hyperbolic: u_tt = Lap u').
pde(klein_gordon,     linear, 2, scalar, 'massive wave').
pde(telegraph,        linear, 2, scalar, 'damped wave').
pde(airy,             linear, 3, scalar, 'dispersive third order').
pde(beam,             linear, 4, scalar, 'fourth order in space').
pde(eikonal,          fully_nonlinear, 1, scalar, '|Du| = q(x,u): distance/geometric optics').
pde(minimal_surface,  quasilinear, 2, scalar, 'div(Du/sqrt(1+|Du|^2)) = 0').
pde(burgers,          quasilinear, 1, scalar, 'u_t + u u_x = 0: shocks').
pde(kdv,              semilinear, 3, scalar, 'u_t + u u_x + u_xxx = 0: solitons').
pde(nonlinear_wave,   semilinear, 2, scalar, 'u_tt - Lap u + f(u) = 0').
pde(semilinear_elliptic, semilinear, 2, scalar, '-Lap u = f(u)').
pde(elasticity,       linear, 2, system, 'vector displacement, 3 waves').
pde(maxwell,          linear, 1, system, 'electromagnetism, hyperbolic system').
pde(euler_incompressible, fully_nonlinear, 1, system, 'ideal fluid').
pde(navier_stokes,    semilinear, 2, system, 'viscous fluid').
pde(mhd,              quasilinear, 2, system, 'conducting fluid').
pde(harmonic_maps,    quasilinear, 2, system, 'maps into manifolds').

kind(Name, K)    :- pde(Name, K, _, _, _).
order(Name, O)    :- pde(Name, _, O, _, _).
scalar(Name)      :- pde(Name, _, _, scalar, _).
system_pde(Name)  :- pde(Name, _, _, system, _).

of_kind(K, Names) :- findall(N, kind(N, K), Names).
max_order(M)      :- aggregate_all(max(O), pde(_, _, O, _, _), M).

main :-
    format("==== 00~n"),
    findall(N, pde(N, _, _, _, _), All),
    length(All, Total),
    format("database: ~d named PDE (book 1.2 list)~n", [Total]),
    of_kind(linear, L), length(L, NL),
    of_kind(semilinear, S), length(S, NS),
    of_kind(quasilinear, Q), length(Q, NQ),
    of_kind(fully_nonlinear, F), length(F, NF),
    format("linear ~d / semilinear ~d / quasilinear ~d / fully nonlinear ~d~n",
           [NL, NS, NQ, NF]),
    NL + NS + NQ + NF =:= Total,
    format("classification audit: every PDE has exactly one kind~n"),
    findall(N, (kind(N, K), K \= linear, system_pde(N)), NonlinSys),
    format("nonlinear systems (the hard ones, book ch11): ~w~n", [NonlinSys]),
    max_order(M),
    format("highest order in zoo: ~d (beam)~n", [M]),
    M =:= 4,
    % 查询演示：一阶方程都携带非线性波前（特征线/激波/粘性解主题）
    findall(N, (order(N, 1), scalar(N)), FirstOrder),
    format("scalar first-order: ~w -> characteristics (book ch3)~n", [FirstOrder]),
    format("END ====~n").
