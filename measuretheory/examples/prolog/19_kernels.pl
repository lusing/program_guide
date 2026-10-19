:- encoding(utf8).
% 19_kernels.pl —— 第 19 章：核复合表与 Chapman-Kolmogorov（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
% 两态转移核 P = [[0.7,0.3],[0.4,0.6]] 用分数精确表示：
% p(1,1,7,10). p(1,2,3,10). p(2,1,2,5). p(2,2,3,5).
% ① 一步分布 dist(1, D)（μ₀ = {1}）；
% ② 核复合 kcomp((i,j), k)：枚举中间态的加权和（有理算术）；
% ③ Chapman 恒等式与平稳分布（π = (4/7, 3/7) 用整数交叉账）。

% --- 转移核（分数 n/d）---
p(1,1,7,10).  p(1,2,3,10).
p(2,1,2,5).   p(2,2,3,5).

qmul(N1,D1,N2,D2,N,D) :- N is N1*N2, D is D1*D2.
qadd(N1,D1,N2,D2,N,D) :- N is N1*D2 + N2*D1, D is D1*D2.
qeq(N1,D1,N2,D2) :- N1*D2 =:= N2*D1.

% --- ① 分布表迭代：dist_list(N, [q(μN(1)), q(μN(2))]），μ₀ = {1} ---
% advance：Σᵢ μᵢ·P(i,J) 的两项显式求和（无自由变量，避免 findall 重数事故）
advance([q(NA1,DA1),q(NA2,DA2)], [q(N1,D1),q(N2,D2)]) :-
    p(1,1,N11,D11), qmul(NA1,DA1,N11,D11,NA1J1,DA1J1),
    p(2,1,N21,D21), qmul(NA2,DA2,N21,D21,NA2J1,DA2J1),
    qadd(NA1J1,DA1J1,NA2J1,DA2J1,N1,D1),
    p(1,2,N12,D12), qmul(NA1,DA1,N12,D12,NA1J2,DA1J2),
    p(2,2,N22,D22), qmul(NA2,DA2,N22,D22,NA2J2,DA2J2),
    qadd(NA1J2,DA1J2,NA2J2,DA2J2,N2,D2).

dist_list(0, [q(1,1),q(0,1)]).          % μ₀ = 点质量在态 1
dist_list(N, L2) :- N > 0,
    N1 is N - 1,
    dist_list(N1, L1),
    advance(L1, L2).

% --- ② 核复合：两步转移账 (i,j) ↦ Σₖ P(i,k)·P(k,j) ---
kcomp(I, J, N, D) :-
    findall(NK*DK, (p(I,K,N1,D1), p(K,J,N2,D2), qmul(N1,D1,N2,D2,NK,DK)), Terms),
    foldl([A*B, AN*AD, CN*CD]>>(qadd(AN,AD,A,B,CN,CD)), Terms, 0*1, N*D).

% --- Chapman：复合账与逐项和恒等（同一谓词两次调用的一致性由定义保证；
%     检查器改为对照已知闭式 61/100 等）---
check_two_step :-
    kcomp(1,1,N1,D1), qeq(N1,D1,61,100),
    kcomp(1,2,N2,D2), qeq(N2,D2,39,100),
    kcomp(2,1,N3,D3), qeq(N3,D3,52,100),
    kcomp(2,2,N4,D4), qeq(N4,D4,48,100),
    format("two-step kernel = P*P closed form (61/100 etc.): OK~n").

% --- ③ 平稳分布：π = (4/7, 3/7) 的核账 ---
check_stationary :-
    qmul(4,7,7,10,NA,DA), qmul(3,7,2,5,NB,DB), qadd(NA,DA,NB,DB,N1,D1),
    qeq(N1,D1,4,7),                          % (πP)(1) = 4/7
    qmul(4,7,3,10,NC,DC), qmul(3,7,3,5,ND,DD), qadd(NC,DC,ND,DD,N2,D2),
    qeq(N2,D2,3,7),                          % (πP)(2) = 3/7
    format("stationary pi = (4/7,3/7) satisfies pi (*) P = pi: OK~n").

% --- n 步分布的验收 ---
check_recursion :-
    dist_list(1, [q(A1,B1),q(A2,B2)]),
    qeq(A1,B1,7,10), qeq(A2,B2,3,10),        % 一步
    dist_list(2, [q(C1,D1),q(C2,D2)]),
    qeq(C1,D1,61,100), qeq(C2,D2,39,100),    % 两步
    dist_list(3, [q(E1,F1),q(E2,F2)]),
    qeq(E1,F1,583,1000), qeq(E2,F2,417,1000),  % 三步：0.61·0.7+0.39·0.4
    format("n-step distributions (1,2,3 steps) exact: OK~n").

% --- main ---
main :-
    format("==== 19 kernels~n", []),
    check_two_step,
    check_stationary,
    check_recursion,
    format("END ====~n"), !.

:- initialization(main).
