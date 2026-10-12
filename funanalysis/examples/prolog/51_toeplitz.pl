:- encoding(utf8).
% 51_toeplitz.pl —— Toeplitz 求和矩阵正则性判据（docs/51 第九章实验）
% 通道：SWI-Prolog。运行期输出纯 ASCII。
%
% Silverman-Toeplitz 条件（Lax 11.1 定理 1 的矩阵版）：
%   (i)  行和 → 1；
%   (ii) 每个固定列的元素 → 0；
%   (iii) 行绝对和一致有界。
% 有限截断上检查 (i)(iii)，(ii) 用生成式的符号推理。

% ---------- 四类求和矩阵行的生成 ----------

% Cesàro：第 N 行 = 前 N 项等权平均
cesaro_row(N, Row) :-
    findall(W, (between(1, N, _), W is 1 rdiv N), Row).

% 加权（线性递增权）：w_j = 2j/(N(N+1))
weighted_row(N, Row) :-
    findall(W, (between(1, N, J), W is (2 * J) rdiv (N * (N + 1))), Row).

% Dirichlet 型：Fourier 部分和的行 = 长度 2N+1 的全 1 向量
% （S_N 作用于系数序列）。行和 = 2N+1 → ∞：条件 (i)(iii) 同时破坏，
% 这正是 ‖D_N‖₁ ~ log N 增长的矩阵形态。
dirichlet_row(N, Row) :-
    M is 2 * N + 1,
    length(Row, M),
    maplist(=(1), Row).

% Fejér 型：非负三角权 w_j ∝ 1 − |j − N/2|/(N/2 + 1)
fejer_row(N, Row) :-
    Half is N / 2,
    findall(W0, (between(1, N, J),
                 DJ is abs(J - 1 - Half),
                 W0 is max(1 - DJ / (Half + 1), 0)),
            RowF),
    normalize_row(RowF, Row).

normalize_row(Row, Norm) :-
    sum_list(Row, S),
    findall(W, (member(X, Row), W is X / S), Norm).

% ---------- 条件检查（有限截断） ----------

row_sum(Row, S) :- sum_list(Row, S).
row_abssum(Row, S) :- maplist(abs_value, Row, As), sum_list(As, S).
abs_value(X, A) :- A is abs(X).

% regular_row：行和 = 1（精确）且行绝对和 ≤ 1
regular_row(Row) :-
    length(Row, N), N > 0,
    row_sum(Row, S), abs(S - 1) < 1e-9,
    row_abssum(Row, AS), AS =< 1.0 + 1e-9.

% ---------- 条件 (ii) 的符号推理：固定列 j 的元素 → 0 ----------

% 列极限：family 第 j 列元素随 N 的表达式
column_limit(cesaro, _J, zero).        % 1/N → 0
column_limit(weighted, _J, zero).      % 2j/(N(N+1)) → 0
column_limit(dirichlet, _J, no).       % 第 j 列元素 = 1 恒不衰减（一旦进入支撑）
column_limit(fejer, _J, zero).         % 有界支撑/归一化权 → 0

% 条件 (iii) 的极限形态：行绝对和的 limsup
abssum_limit(cesaro, one).             % Σ|1/N| = 1
abssum_limit(weighted, one).           % 权归一
abssum_limit(fejer, one).              % 非负归一
abssum_limit(dirichlet, unbounded).    % 行和 = 2N+1 → ∞ ⟹ (i)(iii) 双破坏

verdict(Family, ok) :-
    column_limit(Family, _, zero),
    abssum_limit(Family, one).
verdict(dirichlet, broken) :- !.       % 条件 (i)(iii) 破坏（推论 1′ 的受害者）

% ---------- main ----------

main :-
    format("==== 51 toeplitz regularity (Prolog) ====~n"),
    forall(member(Name-Gen, [cesaro-cesaro_row, weighted-weighted_row,
                             fejer-fejer_row]),
           ( call(Gen, 20, Row),
             ( regular_row(Row) ->
                 format("exp1 ~w row (N=20): row sum = 1, abs sum <= 1~n", [Name])
             ; format("exp1 ~w row FAIL~n", [Name]) ) )),
    call(dirichlet_row, 20, RowD),
    sum_list(RowD, S),
    row_abssum(RowD, ASD),
    format("exp2 dirichlet-type row (N=20): row sum = ~w, abs sum = ~w~n",
           [S, ASD]),
    ( verdict(cesaro, ok) -> format("exp3 cesaro : regular (Toeplitz all ok)~n") ),
    ( verdict(fejer, ok) -> format("exp3 fejer   : regular (Fejer theorem)~n") ),
    ( verdict(dirichlet, broken) ->
        format("exp3 dirichlet: condition (iii) broken => victims exist~n") ),
    format("END ====~n"),
    !.

sum_dirichlet(Row, S) :- sum_list(Row, S).
