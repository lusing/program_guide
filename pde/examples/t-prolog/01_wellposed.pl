% Ch01 适定性：Hadamard 三判据规则库
%
% wellposed(Problem) :- 存在 + 唯一 + 连续依赖（三条全真）。
% 库中给出正反例条目与"失败原因"，main 打印审计表。

:- encoding(utf8).

problem(forward_heat_dirichlet).
problem(backward_heat).
problem(laplace_dirichlet).
problem(laplace_cauchy).
problem(wave_cauchy).
problem(transport_cauchy).

exists_ok(forward_heat_dirichlet).
exists_ok(backward_heat).          % 存在（形式上）
exists_ok(laplace_dirichlet).
exists_ok(laplace_cauchy).         % 形式级数存在
exists_ok(wave_cauchy).
exists_ok(transport_cauchy).

unique_ok(forward_heat_dirichlet).
unique_ok(backward_heat).
unique_ok(laplace_dirichlet).
unique_ok(laplace_cauchy).         % 若存在则唯一
unique_ok(wave_cauchy).
unique_ok(transport_cauchy).

continuous(forward_heat_dirichlet).
continuous(laplace_dirichlet).
continuous(wave_cauchy).
continuous(transport_cauchy).

% 不适定的证据：扰动放大因子无界
illposed_reason(backward_heat, 'mode growth exp(k^2 |t|): unbounded').
illposed_reason(laplace_cauchy,  'Hadamard u_n = sin(nx)sinh(ny)/n^2: data -> 0, solution -> inf').

wellposed(P) :- exists_ok(P), unique_ok(P), continuous(P).

main :-
    format("==== 01~n"),
    forall(problem(P),
           ( wellposed(P) -> format("  ~w: WELL-POSED~n", [P])
           ; illposed_reason(P, R) -> format("  ~w: ILL-POSED  (~s)~n", [P, R])
           ; format("  ~w: ILL-POSED~n", [P]) )),
    aggregate_all(count, wellposed(_), W),
    aggregate_all(count, problem(_), T),
    format("well-posed ~d of ~d~n", [W, T]),
    \+ wellposed(backward_heat),
    \+ wellposed(laplace_cauchy),
    wellposed(forward_heat_dirichlet),
    % 多重指标计数（书习题 2 的规则版）：k 阶偏导数个数 = C(n+k-1, k)
    stars_and_bars(3, 2, 6),
    stars_and_bars(2, 3, 4),
    stars_and_bars(4, 1, 4),
    format("multiindex counting: C(n+k-1,k) audit passed~n"),
    format("END ====~n").

% stars_and_bars(N, K, C)：N 维、K 阶多重指标计数（组合数递推）
% 递推方向：C(N,k) = C(N,k-1)*(N-k+1)/k，从 k=1 端累积保证整除。
stars_and_bars(N, K, C) :- M is N + K - 1, comb2(M, K, C).
comb2(_, 0, 1) :- !.
comb2(N, K, C) :-
    K > 0,
    K1 is K - 1,
    comb2(N, K1, C1),
    C is C1 * (N - K + 1) // K.
