:- encoding(utf8).
% 34_summary.pl —— 第 34 章：方法选择树（Prolog 通道收官）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
%   (1) 问题类型 -> 推荐方法的知识库；
%   (2) 关键性质速查表（全教程一图流）。

% ---------- 问题分类 ----------
problem(hyperbolic_advection,   first_order).
problem(parabolic_diffusion,    second_order_elliptic_in_space).
problem(elliptic_poisson,       steady).
problem(eigenvalue,             spectral).
problem(nonlinear_conservation, shock).

% ---------- 推荐 ----------
recommend(hyperbolic_advection,   upwind_or_lax_wendroff,  [cfl_lambda_le_1]).
recommend(hyperbolic_advection,   leapfrog,                 [three_layer, second_order, lambda_lt_1_marginal]).
recommend(hyperbolic_conservation_system, lf_system,        [eigendecompose_a, lambda_rho_a_le_1]).
recommend(parabolic_diffusion,    crank_nicolson,           [unconditional, second_order, large_tau_oscillates]).
recommend(parabolic_diffusion,    btcs,                     [unconditional, first_order, overdamped]).
recommend(parabolic_diffusion,    saulev_ge,                [no_linear_systems]).
recommend(parabolic_multidim,     adi_lod,                  [tridiagonal_per_direction]).
recommend(elliptic_poisson,       five_point_sor,           [optimal_omega, o_h2]).
recommend(elliptic_poisson,       nine_point,               [o_h4, needs_lap_f]).
recommend(elliptic_general_domain, triangle_p1_fem,         [flexible_geometry, o_h2]).
recommend(elliptic_discontinuous_k, fem_flux_form,          [harmonic_interface]).
recommend(eigenvalue,             fem_generalized_problem,  [k_c_eq_lam_m_c, from_above]).
recommend(nonlinear_conservation, conservative_lf,          [entropy_fix, correct_shock_speed]).
recommend(obstacle_or_contact,    variational_inequality,   [projected_sor]).

% ---------- 关键性质速查 ----------
fact(lax_equivalence, [linear, wellposed, consistent] ==> stable_iff_convergent).
fact(cfl_necessary,   every_convergent_scheme_has_lambda_le_cfl).
fact(five_point_exact_on, quadratics).
fact(p1_fem_same_as,  five_point_on_uniform_grid).
fact(discrete_spectrum, approaches_from_above_o_h2).

% ---------- main ----------
main :-
    format("==== 34 summary~n"),

    problem(hyperbolic_advection, first_order),
    recommend(hyperbolic_advection, upwind_or_lax_wendroff, [cfl_lambda_le_1]),
    format("hyperbolic: upwind/LW under CFL; leapfrog faster but marginal at lam=1~n"),

    recommend(parabolic_multidim, adi_lod, _),
    format("parabolic multidim: ADI/LOD tridiagonal per direction~n"),

    recommend(elliptic_general_domain, triangle_p1_fem, _),
    recommend(elliptic_discontinuous_k, fem_flux_form, _),
    format("elliptic: FEM for curved geometry / discontinuous coefficients~n"),

    fact(lax_equivalence, _),
    fact(discrete_spectrum, _),
    format("theory: Lax equivalence; discrete spectrum from above O(h^2)~n"),

    format("END ====~n").
