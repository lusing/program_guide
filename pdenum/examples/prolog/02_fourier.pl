:- encoding(utf8).
% 02_fourier.pl —— 第 02 章：Fourier 变换表与复矩阵分类（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
% 三件事：
%   (1) 变换表 + Simpson 数值积分核对：高斯变换对、导数性质；
%   (2) 复矩阵分类引擎：Hermite / 酉 / 正规（2x2，复数 c(R,I)）；
%   (3) Richardson 增长矩阵特征值规则：恒不稳定。

% ---------- 表达式求值内核（单变量 x，与 ode 教程同款） ----------
ev_at(n(C), _, C).
ev_at(x, X, X).
ev_at(add(A, B), X, V) :- ev_at(A, X, VA), ev_at(B, X, VB), V is VA + VB.
ev_at(sub(A, B), X, V) :- ev_at(A, X, VA), ev_at(B, X, VB), V is VA - VB.
ev_at(mul(A, B), X, V) :- ev_at(A, X, VA), ev_at(B, X, VB), V is VA * VB.
ev_at(div(A, B), X, V) :- ev_at(A, X, VA), ev_at(B, X, VB), V is VA / VB.
ev_at(neg(A), X, V) :- ev_at(A, X, VA), V is -VA.
ev_at(exp(A), X, V) :- ev_at(A, X, VA), V is exp(VA).
ev_at(sin(A), X, V) :- ev_at(A, X, VA), V is sin(VA).
ev_at(cos(A), X, V) :- ev_at(A, X, VA), V is cos(VA).
ev_at(pow(A, N), X, V) :- ev_at(A, X, VA), V is VA ^ N.

% k 作为常数代入：subst_k(E, KVal, E') 把原子 k 换成数值
subst_k(n(C), _, n(C)).
subst_k(x, _, x).
subst_k(k, K, n(K)) :- !.
subst_k(add(A, B), K, add(SA, SB)) :- subst_k(A, K, SA), subst_k(B, K, SB).
subst_k(sub(A, B), K, add(SA, neg(SB))) :- subst_k(A, K, SA), subst_k(B, K, SB).
subst_k(mul(A, B), K, mul(SA, SB)) :- subst_k(A, K, SA), subst_k(B, K, SB).
subst_k(div(A, B), K, div(SA, SB)) :- subst_k(A, K, SA), subst_k(B, K, SB).
subst_k(neg(A), K, neg(SA)) :- subst_k(A, K, SA).
subst_k(pow(A, N), K, pow(SA, N)) :- subst_k(A, K, SA).
subst_k(E, K, SE) :- E =.. [F, A], opaquef(F), !, subst_k(A, K, SA), SE =.. [F, SA].
subst_k(E, _, E).
opaquef(exp). opaquef(sin). opaquef(cos). opaquef(pow).

% Simpson 复合积分（被积函数是表达式树，变量 x）
simpson_expr(E, A, B, N, V) :-
    HH is (B - A) / N,
    ev_at(E, A, FA), ev_at(E, B, FB),
    S0 is FA + FB,
    simpson_acc(E, A, HH, N, 1, S0, V0),
    V is V0 * HH / 3.
simpson_acc(_, _, _, 0, _, S, S) :- !.
simpson_acc(E, A, HH, N, I, S, R) :-
    X is A + I * HH,
    ev_at(E, X, FX),
    ( I mod 2 =:= 1 -> W = 4 ; W = 2 ),
    S1 is S + W * FX,
    I1 is I + 1,
    N1 is N - 1,                % 坑账：N-1 直接传是项不是数
    simpson_acc(E, A, HH, N1, I1, S1, R).

% ---------- (1) 变换表（对称约定 1/sqrt(2pi)） ----------
% u = exp(-x^2)  ⟺  uhat = exp(-k^2/4)/sqrt(2)
u_gauss(exp(neg(pow(x, 2)))).
uhat_gauss(mul(exp(neg(div(pow(k, 2), n(4)))), n(InvSqrt2))) :- InvSqrt2 is 1 / sqrt(2).

% 数值核对：uhat(k) 的实部 = (1/sqrt(2pi)) ∫ u cos(kx) dx
check_gauss_pair(K, Err) :-
    u_gauss(U),
    subst_k(mul(U, cos(mul(k, x))), K, Integrand),
    simpson_expr(Integrand, -8.0, 8.0, 2000, Integral),
    Factor is 1 / sqrt(2 * pi),
    uhat_gauss(Hat),
    subst_k(Hat, K, HatE), ev_at(HatE, _, HatV),
    Err is abs(Integral * Factor - HatV).

% 导数性质 F[u'](k) = ik uhat(k)，在 k 上核对实虚两部分
% u' = -2x exp(-x^2)（奇函数）
u_gauss_deriv(mul(n(-2), mul(x, exp(neg(pow(x, 2)))))).
check_deriv_rule(K, Err) :-
    u_gauss(U), u_gauss_deriv(DU),
    % 左边虚部：-(1/sqrt(2pi)) ∫ u' sin(kx)
    subst_k(mul(DU, sin(mul(k, x))), K, I1), simpson_expr(I1, -8.0, 8.0, 2000, V1),
    Factor is 1 / sqrt(2 * pi),
    % 右边虚部：k (1/sqrt(2pi)) ∫ u cos(kx)
    subst_k(mul(U, cos(mul(k, x))), K, I2), simpson_expr(I2, -8.0, 8.0, 2000, V2),
    Err is abs(-V1 * Factor - K * V2 * Factor).

% ---------- (2) 复矩阵分类（2x2，元素 c(R,I)） ----------
% 共轭转置 A^H = (conj A)^T
ct([[c(Ar,Ai),c(Br,Bi)],[c(Cr,Ci),c(Dr,Di)]],
   [[c(Ar,NAi),c(Cr,NCi)],[c(Br,NBi),c(Dr,NDi)]]) :-
    NAi is -Ai, NBi is -Bi, NCi is -Ci, NDi is -Di.

hermite(M) :- ct(M, T), meq(M, T).
cmul(c(AR,AI), c(BR,BI), c(CR,CI)) :- CR is AR*BR - AI*BI, CI is AR*BI + AI*BR.
cadd(c(AR,AI), c(BR,BI), c(CR,CI)) :- CR is AR+BR, CI is AI+BI.

% 2x2 复矩阵乘法
mm([[A,B],[C,D]], [[E,F],[G,H]], R) :- mm_entry(A,E,B,G,X11), mm_entry(A,F,B,H,X12),
    mm_entry(C,E,D,G,X21), mm_entry(C,F,D,H,X22), R = [[X11,X12],[X21,X22]].
mm_entry(A,B,C,D,S) :- cmul(A,B,AB), cmul(C,D,CD), cadd(AB,CD,S).

meq([[A,B],[C,D]], [[E,F],[G,H]]) :- ceq(A,E), ceq(B,F), ceq(C,G), ceq(D,H).
ceq(c(R1,I1), c(R2,I2)) :- abs(R1-R2) < 1.0e-12, abs(I1-I2) < 1.0e-12.

normal(M) :- ct(M,T), mm(M,T,P1), mm(T,M,P2), meq(P1,P2).

% ---------- (3) Richardson 增长矩阵规则 ----------
% G = [[-8 r s, 1],[1, 0]]，特征值 mu = -4rs ± sqrt(16 r² s² + 1)
richardson_mu(R, S, Mu1, Mu2) :-
    Disc is sqrt(16 * R * R * S * S + 1),
    Mu1 is -4 * R * S + Disc,
    Mu2 is -4 * R * S - Disc.
richardson_unstable(R, S) :-
    richardson_mu(R, S, M1, M2),
    ( abs(M1) > 1.0000001 ; abs(M2) > 1.0000001 ).

% ---------- main ----------
main :-
    format("==== 02 fourier~n"),

    % (1) 高斯变换对
    check_gauss_pair(0.0, E1), E1 < 1.0e-9,
    check_gauss_pair(1.0, E2), E2 < 1.0e-9,
    check_gauss_pair(2.5, E3), E3 < 1.0e-9,
    format("gauss pair: FT(exp(-x^2)) = exp(-k^2/4)/sqrt(2), errors ~w~n", [[E1,E2,E3]]),

    check_deriv_rule(1.0, D1), D1 < 1.0e-8,
    check_deriv_rule(2.0, D2), D2 < 1.0e-8,
    format("derivative rule imag parts agree, errors ~w~n", [[D1,D2]]),

    % (2) 复矩阵分类
    Sym = [[c(2,0),c(1,0)],[c(1,0),c(2,0)]],
    hermite(Sym), normal(Sym),
    format("symmetric [2 1; 1 2]: hermite + normal~n"),
    Rot = [[c(0.7648421872844885,0.0),c(0.6442176872376911,-0.0)],
           [c(-0.6442176872376911,0.0),c(0.7648421872844885,0.0)]],
    \+ hermite(Rot), normal(Rot),
    format("rotation(0.7 rad): not hermite but normal~n"),
    Jordan = [[c(1,0),c(1,0)],[c(0,0),c(1,0)]],
    \+ hermite(Jordan), \+ normal(Jordan),
    format("jordan block: neither hermite nor normal~n"),

    % (3) Richardson 恒不稳定
    forall(between(1, 6, I),
           ( R is I / 10.0, richardson_unstable(R, 0.5) )),
    forall(between(1, 9, I),
           ( S is I / 10.0, richardson_unstable(0.3, S) )),
    richardson_mu(0.5, 1.0, Mu1, Mu2),
    format("richardson r=0.5 s=1: eigenvalues ~w (one always beyond unit circle)~n",
           [[Mu1, Mu2]]),

    format("END ====~n").
