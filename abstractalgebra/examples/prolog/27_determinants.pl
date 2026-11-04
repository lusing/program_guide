:- encoding(utf8).
% 27 行列式：完全展开、Laplace 展开与可逆判别（纯整数算术）
%
% 对应原书 §4.4 前半。det_perm/2 走置换完全展开（Σ sgn(σ)∏a[σ(i),i]），
% det_laplace/2 走余子式递推；两台机器加转置/乘法性/伴随（命题 4.86）/
% 整数可逆（推论 4.87）全部以精确整数断言。

% ---------- 置换与符号 ----------

% perm(+N, ?P)：P 是 [1..N] 的一个排列（select 回溯生成）。
perm(N, P) :- numlist(1, N, U), perm_sel(U, P).
perm_sel([], []).
perm_sel(U, [X|Rest]) :- select(X, U, U1), perm_sel(U1, Rest).

% inversions(+P, -I)：逆序对计数（foldl 状态 = 计数-已见元素表）。
inversions(P, I) :- foldl(pair_count, P, 0-[], I-_).
% 处理到 p[i] 时，逆序对 (j, i) 计数 = Seen 中大于 X 的元素个数：
% include(<(X), …) 保留满足 X < Y 的 Y（部分应用方向别写反）。
pair_count(X, A-Seen, A2-Seen2) :-
    include(<(X), Seen, Greater), length(Greater, G),
    A2 is A + G, Seen2 = [X|Seen].

% sgn(+P, -S)：S = (−1)^{逆序数}。
sgn(P, S) :- inversions(P, I), (I mod 2 =:= 0 -> S = 1 ; S = -1).

% ---------- 1. 完全展开 ----------

prod_entry(_, [], [], 1).
prod_entry(A, [R|Rows], [C|Cols], T) :-
    nth1(R, A, Row), nth1(C, Row, V),
    prod_entry(A, Rows, Cols, T0), T is T0 * V.

det_perm(A, D) :-
    length(A, N), findall(P, perm(N, P), Ps), numlist(1, N, Cols),
    sum_terms(A, Ps, Cols, 0, D).
sum_terms(_, [], _, D, D).
sum_terms(A, [P|Ps], Cols, Acc, D) :-
    sgn(P, S), prod_entry(A, P, Cols, T), Acc1 is Acc + S * T,
    sum_terms(A, Ps, Cols, Acc1, D).

% ---------- 2. Laplace 展开（按第 1 行） ----------

% minor(+A, +I, +J, -M)：删去第 I 行第 J 列。
minor(A, I, J, M) :-
    nth1(I, A, _, RestRows), maplist(del_col(J), RestRows, M).
del_col(J, Row, Out) :-
    J1 is J - 1, length(Before, J1),          % 长度约束必须在 append 之前定值
    append(Before, [_|After], Row), append(Before, After, Out).

det_laplace([[V]], V) :- !.
det_laplace([[A,B],[C,D]], V) :- !, V is A * D - B * C.
det_laplace(A, D) :-
    A = [Row|_], length(Row, N), J = 1,
    laplace_terms(Row, A, J, N, 0, D).
laplace_terms(_, _, J, N, D, D) :- J > N, !.
laplace_terms(Row, A, J, N, Acc, D) :-
    nth1(J, Row, V), minor(A, 1, J, M), det_laplace(M, Dm),
    Sign is (-1) ^ (1 + J), Acc1 is Acc + Sign * V * Dm,
    J1 is J + 1, laplace_terms(Row, A, J1, N, Acc1, D).

% ---------- 矩阵乘与转置 ----------

% transpose(+M, -T)：显式辅助谓词版（不依赖 yall lambda）。
row_head([H|_], H).
row_tail([_|T], T).
transpose([[]|_], []) :- !.
transpose(M, [Col|Cols]) :-
    maplist(row_head, M, Col),
    maplist(row_tail, M, Rest),
    transpose(Rest, Cols).

mat_mul(A, B, C) :- maplist(mul_row(B), A, C).
mul_row(B, Row, CRow) :- transpose(B, BT), maplist(dot(Row), BT, CRow).
dot(Row, Col, S) :- foldl(mul_add, Row, Col, 0, S).
mul_add(X, Y, A, S) :- S is A + X * Y.

% ---------- 3. 伴随（命题 4.86）与整数可逆（推论 4.87） ----------

cofactor(A, I, J, C) :-
    minor(A, I, J, M), det_laplace(M, D),
    Sign is (-1) ^ (I + J), C is Sign * D.

adjugate3(A, Adj) :-
    findall(RowJ,
            (between(1, 3, J),
             findall(C, (between(1, 3, I), cofactor(A, I, J, C)), RowJ)),
            Adj).

% ---------- 断言主流程 ----------

main :-
    format("==== 27~n"),
    Samples = [
        [[1,2],[3,4]],
        [[2,1],[1,1]],
        [[2,1,0],[1,3,1],[0,1,2]],
        [[0,1,0],[-1,0,0],[0,0,5]],
        [[1,2,0],[0,1,3],[0,0,2]]
    ],
    forall(member(A, Samples), (det_perm(A, D), det_laplace(A, D))),
    det_perm([[1,2],[3,4]], -2),
    det_perm([[2,1,0],[1,3,1],[0,1,2]], 8),
    det_laplace([[0,1,0],[-1,0,0],[0,0,5]], 5),
    format("完全展开 = Laplace：5 张样本矩阵同值；锚点 −2、8、5 ✓~n"),
    % 转置不变（式 (2)）
    forall((member(A, Samples), transpose(A, T), det_perm(A, D)),
           det_laplace(T, D)),
    format("det(Aᵀ) = det(A)：样本矩阵全过 ✓~n"),
    % 乘法性（式 (1)）：det(PM) = det(P)·det(M)
    P1 = [[1,2],[0,1]], M1 = [[2,1],[1,3]],
    mat_mul(P1, M1, PM), PM = [[4,7],[1,3]],
    det_perm(P1, 1), det_perm(M1, 5), det_perm(PM, 5),
    A3 = [[2,1,0],[1,3,1],[0,1,2]],
    mat_mul(A3, A3, A3A3), det_perm(A3, 8), det_perm(A3A3, 64),
    format("det(AB) = det(A)det(B)：[[4,7;1,3]] 与 A₃² 双例 ✓~n"),
    % 命题 4.86：A·adj(A) = det(A)·I（det = 8）
    adjugate3(A3, Adj),
    mat_mul(A3, Adj, Prod),
    Prod = [[8,0,0],[0,8,0],[0,0,8]],
    format("命题 4.86：A·adj(A) = det(A)·I = 8·I ✓~n"),
    % 推论 4.87（ℤ 侧）：det = ±1 ⟹ 整数逆
    U = [[2,1],[1,1]], det_perm(U, 1),
    mat_mul(U, [[1,-1],[-1,2]], [[1,0],[0,1]]),
    det_perm([[2,0],[0,1]], 2),
    format("推论 4.87（ℤ 侧）：det = ±1 ⟹ 整数逆（[[2,1;1,1]]）；det = 2 ⟹ ℤ 上不可逆 ✓~n"),
    format("END ====~n").
