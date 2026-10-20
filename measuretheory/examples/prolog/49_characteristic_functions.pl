:- encoding(utf8).
% 49_characteristic_functions.pl —— 第 49 章：特征函数（Prolog 通道）
%
% ① Euler 账：两点 ±1 的 char = (e^{it}+e^{-it})/2 = cos t；
% ② Bin(2,1/2) 的实部/虚部闭式与归一 φ(0)=1；
% ③ 矩词典：φ'(0) = i·EX（虚部差分）、-φ''(0) = EX²（实部二差）；
% ④ 独立和 = 乘积：两个两点分布之和的 cos²t 账。

% Bin(2,1/2)：P(X=k) = C(2,k)/4，支撑 {0,1,2}
% Re φ(t) = 1/4 + (1/2)cos t + (1/4)cos 2t；Im φ(t) = (1/2)sin t + (1/4)sin 2t
char_bin_re(T, Re) :- Re is 1/4 + (1/2) * cos(T) + (1/4) * cos(2 * T).
char_bin_im(T, Im) :- Im is (1/2) * sin(T) + (1/4) * sin(2 * T).

% ① 两点分布的 Euler 平均：实部核对 cos、虚部核对 0
check_euler :-
    T is 0.7,
    ReAvg is (cos(T) + cos(-T)) / 2,
    ImAvg is (sin(T) + sin(-T)) / 2,
    abs(ReAvg - cos(T)) < 1e-12,
    abs(ImAvg) < 1e-12,
    format("Euler bookkeeping: two-point char = cos(t) (imag cancels): OK~n").

% ② 归一账：φ(0) = 1（实部求和 = 1，虚部 = 0）
check_normalize :-
    char_bin_re(0, Re0), char_bin_im(0, Im0),
    Re0 =:= 1,
    abs(Im0) < 1e-15,
    format("char(0) = 1: Bin(2,1/2) real-part sum = 1 exactly: OK~n").

% ③ 矩词典（Bin(2,1/2)：EX = 1，EX^2 = 3/2）
%     φ'(0) = i·EX ⟹ Im(φ(h)-φ(0))/h → EX；
%     φ''(0) = -EX² ⟹ 实部对称二差 -2(Re(h)-Re(0))/h² → EX²。
check_moments :-
    H is 1e-4,
    char_bin_im(H, ImH), char_bin_im(0, Im0),
    D1 is (ImH - Im0) / H,
    abs(D1 - 1) < 1e-3,                        % EX = 1
    char_bin_re(H, ReH), char_bin_re(0, ReC),
    D2 is -(2 * (ReH - ReC)) / (H * H),
    abs(D2 - 3/2) < 1e-2,                       % EX^2 = Var + EX^2 = 1/2 + 1
    format("moment dictionary: Im diff -> EX=1, Re 2-diff -> EX2=3/2: OK~n").

% ④ 独立和的乘积账：X+Y（两点 ⊕ 两点）支撑 {2,0,-2} 概率 {1/4,1/2,1/4}
%     直算 φ_{X+Y}(t) = (1/4)cos 2t + 1/2 + (1/4)cos(-2t) = cos²t
check_sum_product :-
    T is 0.9,
    Direct is (1/4) * cos(2 * T) + 1/2 + (1/4) * cos(-2 * T),
    Prod is cos(T) * cos(T),
    abs(Direct - Prod) < 1e-12,
    format("independent sum = product: char of X+Y equals cos^2(t): OK~n").

main :-
    format("==== 49 characteristic_functions~n", []),
    check_euler,
    check_normalize,
    check_moments,
    check_sum_product,
    format("END ====~n"), !.

:- initialization(main).
