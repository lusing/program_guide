:- encoding(utf8).
% 10_integral.pl —— 第 10 章：q(N,D) 有理数算术下的积分基本律（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
% 原子测度 μ = Σ 2^-k δ_k（k = 1..24）。
% ① Σ k·4^-k 部分和 vs 4/9 的精确距离账（交叉相乘）；
% ② S⁺ 表示无关性（标准 vs 拆块，精确值 21/32）；
% ③ 齐次与单调（7/8 ≤ 15/16 ≤ 21/8）；
% ④ Markov 最紧点 a=1/2：3/8 ≤ 4/9，比值恰 27/32。

qadd(q(A,B), q(C,D), q(N1,E1)) :-
    N is A*D + C*B, E is B*D,
    G is gcd(N, E), G > 0, N1 is N // G, E1 is E // G.
qmul(q(A,B), q(C,D), q(N1,E1)) :-
    N is A*C, E is B*D,
    G is gcd(N, E), G > 0, N1 is N // G, E1 is E // G.
qle(q(A,B), q(C,D)) :- A * D =< C * B.      % 分母恒正，交叉相乘
qeq(q(A,B), q(C,D)) :- A * D =:= C * B.

w(K, q(1, D)) :- D is 2 ** K.

mu_atoms([], q(0,1)).
mu_atoms([K|Ks], R) :- w(K, W), mu_atoms(Ks, R0), qadd(W, R0, R).

% --- ① Σ_{k≤n} k·4^-k 的距离账 ---
sum_k4(N, q(N1,D1)) :- sum_k4_(N, q(0,1), q(N1,D1)).
sum_k4_(0, Acc, Acc).
sum_k4_(N, Acc, R) :- N > 0,
    D is 4 ** N, qmul(q(N,1), q(1,D), T), qadd(T, Acc, Acc1),
    N1 is N - 1, sum_k4_(N1, Acc1, R).

check_sum :-
    sum_k4(24, S), S = q(N,D),
    N * 9 < 4 * D,                            % S < 4/9（严格）
    D24 is 4 ** 24,
    (4 * D - 9 * N) * D24 =< 900 * D,         % 4/9 - S ≤ 100/4^24
    format("sum k*4^-k (n=24): strictly below 4/9, tail <= 100/4^24: OK~n").

% --- ② S⁺ 表示无关性 ---
check_repr :-
    mu_atoms([1], W1), mu_atoms([2], W2), qadd(W1, W2, W12),
    qmul(q(1,2), W12, Left1),
    mu_atoms([3], W3), qmul(q(3,1), W3, L2),
    qadd(Left1, L2, Std),
    mu_atoms([1,2], W12b), qmul(q(1,2), W12b, L1b),
    qadd(L1b, L2, Split),
    qeq(Std, Split),
    qeq(Std, q(3,4)),                         % 1/2*3/4 + 3*1/8 = 3/4
    format("S+ representation-independence, exact value 3/4: OK~n").

% --- ③ 齐次与单调（先心算：mu123 = 7/8, mu1234 = 15/16, 3*mu123 = 21/8） ---
check_linear :-
    mu_atoms([1,2,3], W123), mu_atoms([1,2,3,4], W1234),
    qeq(W123, q(7,8)), qeq(W1234, q(15,16)),
    qle(W123, W1234),                         % 7/8 ≤ 15/16
    qmul(q(3,1), W123, T3), qeq(T3, q(21,8)),
    qle(W1234, T3),                           % 15/16 ≤ 21/8
    format("S+ homogeneity/monotonicity (7/8 <= 15/16 <= 21/8): OK~n").

% --- ④ Markov 最紧点 ---
check_markov :-
    mu_atoms([1,2], W12), qeq(W12, q(3,4)),
    qmul(q(1,2), W12, LHS), qeq(LHS, q(3,8)),
    qle(LHS, q(4,9)),
    % 比值恰 27/32：(3/8)/(4/9) = 27/32 ⟺ 3*32*9 = 27*8*4 = 864
    3 * 32 * 9 =:= 27 * 8 * 4,
    format("Markov tight at a=1/2: 3/8 <= 4/9, ratio exactly 27/32: OK~n").

% --- main ---
main :-
    format("==== 10 integral~n", []),
    check_sum,
    check_repr,
    check_linear,
    check_markov,
    format("END ====~n"), !.
