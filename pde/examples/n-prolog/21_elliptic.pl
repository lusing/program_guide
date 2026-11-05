:- encoding(utf8).
% 21_elliptic.pl —— 第 21 章：椭圆格式知识库（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
%   (1) 书 4 未知数例子的边界值与结果事实；
%   (2) 五点/九点格式的精度与模板知识；
%   (3) 极坐标格式的系数结构规则。

% ---------- (1) 书例事实 ----------
book_example_boundary(log_r2).   % u = log((x+1)^2 + y^2)，h = k = 1/3
book_solution(1, 0.634804).
book_solution(2, 1.059993).
book_solution(3, 0.798500).
book_solution(4, 1.169821).
book_grid(h, 0.3333333).

% ---------- (2) 格式知识 ----------
stencil(five_point, [n, s, e, w], order(2)).
stencil(nine_point, [n, s, e, w, ne, nw, se, sw], order(4)).
weight9(edge, -4).  weight9(corner, -1).  weight9(center, 20).
rhs9_correction(h4_over_2, laplacian_f).   % 6h²[f + (h²/12)Δf]

% 五点对二次多项式精确（00 章现象的椭圆版）
exact_for(five_point, quadratic, yes).
exact_for(five_point, harmonic_log, no).   % 书例中数值解≠解析值（差  ~w）

% ---------- (3) 极坐标 ----------
polar_coeff(r_plus,  (R + H/2)/(R*H*H)).
polar_coeff(r_minus, (R - H/2)/(R*H*H)).
polar_coeff(theta,   1/(R*R*DTH*DTH)).
polar_diag(2/(H*H) + 2/(R*R*DTH*DTH)).
% r=0 处理（书 (1.11)）：四邻平均（有限体积推导）
polar_origin(average_four_neighbors).

% ---------- main ----------
main :-
    format("==== 21 elliptic~n"),

    book_solution(1, 0.634804), book_solution(4, 1.169821),
    format("book example: alpha1 = 0.634804, alpha4 = 1.169821 (h = 1/3)~n"),

    stencil(five_point, _, order(2)),
    stencil(nine_point, _, order(4)),
    weight9(edge, -4), weight9(corner, -1), weight9(center, 20),
    rhs9_correction(h4_over_2, laplacian_f),
    format("five-point O(h^2); nine-point O(h^4) with weights 20/-4/-1 and~n"),
    format("  RHS correction 6h^2[f + (h^2/12)lap f]~n"),

    exact_for(five_point, quadratic, yes),
    exact_for(five_point, harmonic_log, no),
    format("five-point exact on quadratics; book example errs about 1e-3 (2nd order visible)~n"),

    polar_origin(average_four_neighbors),
    format("polar: conservative (r u_r)_r/r form; r=0 by FV four-neighbor average~n"),

    format("END ====~n").


