:- encoding(utf8).
% 71_weak_derivatives.pl —— 弱导数的规则模型（docs/71 实验）
% 通道：SWI-Prolog（gprolog 兼容：format/2 带 []、main 尾部 !）
% 内容：弱导数对表（|x|、Heaviside、多项式）、分部积分的符号转移、
%       W^{k,p} 成员资格与维数临界（ln|x| 在 n>=3）、"谁不属于 L^p"

% ---------- 弱导数对表（书 6.3.3 / 3.7.10 / 6.3.4） ----------
% weak_deriv(U, G)：U 的弱导数是 G。delta(point) 表示 Dirac 泛函（非函数）。
weak_deriv(abs_x, sign_x).            % 书 6.3.3：|x|' = sgn
weak_deriv(heaviside, delta(0)).      % 书 3.7.10：Y' = delta
weak_deriv(relu, heaviside).          % x^+ = max(x,0)：' = Y（分部积分同型）
weak_deriv(monomial(N), monomial(M)) :- integer(N), N >= 1, M is N - 1.
weak_deriv(const, zero_func).
weak_deriv(log_abs_r(D), neg_inv_r(D)) :- between(3, 4, D).   % 书 6.3.4：ln|x| 仅 n>=3

% 函数判定：delta 不是函数（不属于任何 L^p）
is_function(sign_x). is_function(heaviside). is_function(monomial(_)).
is_function(zero_func). is_function(neg_inv_r(_)).
is_function(delta(_)) :- !, fail.

% W^{1,p} 成员资格（U 本身 L^p 且弱导数为 L^p 函数）
in_wp1(U, P) :- weak_deriv(U, G), is_function(G), lp_member(U, P), lp_member(G, P).

lp_member(abs_x, _).              % 有界域上 |x| 属于一切 L^p
lp_member(sign_x, _).
lp_member(heaviside, _).
lp_member(relu, _).
lp_member(monomial(_), _).        % 有界域
lp_member(log_abs_r(_), _).       % |ln r| 在 B1 上各 L^p 均可积
lp_member(zero_func, _).
lp_member(neg_inv_r(D), 2) :- D >= 3.   % ∫r^{n-3} dr 收敛恰需 n>=3
lp_member(delta(_), _) :- !, fail.      % 测度奇异，不属于 L^p

% ---------- 分部积分的符号转移（书 6.3.1 定义的规则形态） ----------
% 转移律：配对 (U, Phi) 时求导从 U 转移到 Phi，符号翻转。
% ibp_sign(U, S)：∫ U Phi' = S * ∫ G Phi，其中 G = 弱导数、S ∈ {1,-1}。
ibp_sign(U, -1) :- weak_deriv(U, _), !.   % 定义给 -1（导数过河，负号留岸）
ibp_sign(_, 1).                            % 经典分部积分的另一侧

% 无弱导数判据：U 有跳变且候选是 delta（不是函数）⟹ 无 W 弱导数
no_functional_weak_deriv(U) :- weak_deriv(U, G), \+ is_function(G).

% ---------- 实验 ----------
main :-
    format("==== 71 weak derivatives (rule model) ====", []),

    % 实验 1：对表枚举——四类函数 + 一个维数临界
    findall(U->G, weak_deriv(U, G), Pairs),
    length(Pairs, N),
    member(abs_x->sign_x, Pairs),
    member(heaviside->delta(0), Pairs),
    member(log_abs_r(3)->neg_inv_r(3), Pairs),
    format("~nEXP1 weak-derivative table: ~d entries, e.g. |x|->sgn, Y->delta, ln|r|(n=3)->x/r^2", [N]),

    % 实验 2：分部积分符号转移检查
    ibp_sign(abs_x, -1),
    ibp_sign(heaviside, -1),
    format("~nEXP2 integration by parts sign: -1 for all weak derivations (def D u = -u Phi')", []),

    % 实验 3：W^{1,2} 成员资格推理
    in_wp1(abs_x, 2),
    in_wp1(relu, 2),
    in_wp1(log_abs_r(3), 2),
    \+ in_wp1(log_abs_r(2), 2),
    \+ in_wp1(heaviside, 2),      % 弱导数是 delta，不是 L^2 函数
    format("~nEXP3 W^{1,2} membership: |x|, x^+, ln|r|(n=3) in; ln|r|(n=2), Y out", []),

    % 实验 4：delta 不是函数的三重否决
    no_functional_weak_deriv(heaviside),
    \+ lp_member(delta(0), 2),
    \+ is_function(delta(0)),
    format("~nEXP4 delta is not a function: no L^p membership, Y has no W-derivative", []),

    format("~nEND ====", []), !.
