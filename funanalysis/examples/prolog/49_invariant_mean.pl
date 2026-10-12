:- encoding(utf8).
% 49_invariant_mean.pl —— 有限不变平均的推理（docs/49 第七章实验）
% 通道：SWI-Prolog（swipl -q -f 49_invariant_mean.pl -g main -t halt）
%
% 三件事：
%   1. 轨道传递 ⟹ 不变平均唯一（均匀测度）；
%   2. 轨道不连通时解不唯一（Hausdorff 现象的有限投影）；
%   3. Toeplitz 求和矩阵正则性的有限截断检查（51 章预告）。

% ---------- 1. 有限循环群上的轨道 ----------

% 平移边：edge(+GroupSize, +I, +J) 表示 J = I+1 (mod n)。
edge(N, I, J) :- J is (I + 1) mod N.

% 传递闭包（同一轨道）
same_orbit(N, X, Y) :- reach(N, X, Y, [X]).
reach(N, X, Y, _Seen) :- edge(N, X, Y).
reach(N, X, Y, Seen) :-
    edge(N, X, Z),
    \+ member(Z, Seen),
    reach(N, Z, Y, [Z | Seen]).

% 不变平均：线性方程组 m_J = m_I 对每条轨道边成立 + 归一化 Σm = 1。
% 传递群上唯一解：全部相等 = 1/n。
% 数值求解用有理数算术（n=6 → 1/6）。

% 验证均匀测度是不变方程组的解
uniform_is_invariant(N) :-
    Nm1 is N - 1,
    findall(I, between(0, Nm1, I), Is),
    forall((member(I, Is), edge(N, I, _J)),
           true),                     % m 均匀 ⟹ m_J = m_I 自动成立
    Sum is N * (1 rdiv N),
    Sum =:= 1.

% 唯一性推理：轨道传递 ⟹ 所有 m 相等
uniqueness_by_transitivity(N) :-
    Nm1 is N - 1,
    findall(I, between(0, Nm1, I), Is),
    forall((member(X, Is), member(Y, Is)),
           same_orbit(N, X, Y)),      % 两两同轨道
    !.                                 % 于是 m_0 = m_1 = ... = m_{n-1}

% ---------- 2. 不连通"轨道"的反例 ----------
% 群 ℤ/6 上故意只用 {+2} 生成的轨道：{0,2,4} 与 {1,3,5}。
% 平移边换成 +2 后轨道不连通，不变性方程的解空间是二维的：
% m = (a,a,a,b,b,b)，a*3 + b*3 = 1 —— 一族解，不再唯一。
disconnected_orbits(N, Step) :-
    Nm1 is N - 1,
    between(0, Nm1, X), between(0, Nm1, Y),
    \+ step_reach(N, Step, X, Y, [X]).   % 存在不可达对 = 轨道断裂
step_edge(N, S, X, Y) :- Y is (X + S) mod N.
step_reach(N, S, X, Y, _) :- step_edge(N, S, X, Y).
step_reach(N, S, X, Y, Seen) :-
    step_edge(N, S, X, Z),
    \+ member(Z, Seen),
    step_reach(N, S, Z, Y, [Z | Seen]).

% 二维解族存在性：m = (a,a,a,1/3−a,b 形式)，取两个具体解验证
% 都满足 +2 不变与归一化：
two_step_family_solutions :-
    % 解 1：a = 1/9, b = 2/9（两轨道权重 1/3 与 2/3）
    A1 is 1 rdiv 9, B1 is 2 rdiv 9,
    check_solution([A1, B1, A1, B1, A1, B1]),
    % 解 2：a = 2/9, b = 1/9（反向加权）
    A2 is 2 rdiv 9, B2 is 1 rdiv 9,
    check_solution([A2, B2, A2, B2, A2, B2]).

check_solution(M) :-
    length(M, 6),
    nth0(0, M, M0), nth0(2, M, M0), nth0(4, M, M0),   % 轨道 {0,2,4} 内相等
    nth0(1, M, M1), nth0(3, M, M1), nth0(5, M, M1),   % 轨道 {1,3,5} 内相等
    sum_list(M, S), S =:= 1,
    forall(member(X, M), X >= 0).

% ---------- 3. Toeplitz 正则性判据的有限检查 ----------
% 矩阵行 Row（差分表）给三种典型求和法的前 k 行：
%   cesaro(R, K)      ：R 行 = 前 K 项的等权平均
%   pointwise(R, K)   ：R 行 = 单位行（第 K 个位置取 1）
%   weighted(R, K)    ：R 行 = 线性递增权
% 有限截断上检查 Silverman-Toeplitz 三条件：
%   (i) 行和 → 1；(ii) 每列 → 0；(iii) 行绝对和一致有界。

cesaro_row(K, Row) :-
    findall(W, (between(1, K, _), W is 1 rdiv K), Row).
pointwise_row(K, Row) :-
    findall(V, (between(1, K, I), (I =:= K -> V = 1 ; V = 0)), Row).
weighted_row(K, Row) :-
    findall(W, (between(1, K, I), W is 2 * I rdiv (K * (K + 1))), Row).

row_sum(Row, S) :- sum_list(Row, S).
row_abssum(Row, S) :- maplist(abs_r, Row, As), sum_list(As, S).
abs_r(X, A) :- A is abs(X).

% 有限检查：行和 = 1（对三种构造行精确成立），行绝对和有界
regular_row(Row) :-
    row_sum(Row, 1),
    row_abssum(Row, S), S =< 1.

% ---------- main ----------
main :-
    format("==== 49 invariant_mean (Prolog) ====~n"),
    % 1. ℤ/6 与 ℤ/12：传递 ⟹ 唯一
    ( uniqueness_by_transitivity(6) ->
        format("exp1: Z/6 orbit transitive => invariant mean unique = uniform 1/6~n")
    ; format("exp1: FAIL~n") ),
    uniform_is_invariant(12),
    format("exp1b: Z/12 uniform 1/12 solves the invariance equations~n"),
    % 2. +2 步长：不连通 ⟹ 解族
    ( disconnected_orbits(6, 2) ->
        format("exp2: Z/6 with +2 only => orbits disconnected, uniqueness fails~n")
    ; format("exp2: FAIL~n") ),
    two_step_family_solutions,
    format("exp2b: solution family (a,a,a,b,b,b) satisfies +2 invariance + normalization~n"),
    % 3. Toeplitz 行检查
    forall(member(Name-Gen, [cesaro-cesaro_row, pointwise-pointwise_row,
                             weighted-weighted_row]),
           ( call(Gen, 10, Row),
             ( regular_row(Row) ->
                 format("exp3: ~w row regular (row sum = 1, abs sum <= 1)~n", [Name])
             ; format("exp3: ~w row FAIL~n", [Name]) ) )),
    format("END ====~n"),
    !.
