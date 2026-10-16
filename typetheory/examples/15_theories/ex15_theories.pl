:- encoding(utf8).
% ============================================================
% 15 理论与模型论 —— Prolog 结构枚举机（Farmer ch.9 + 12.4）
%   · 理论 = (语言, 公理集)；模型 = 满足全部公理的结构
%   · 幺半群 MON：全表枚举（1/2/3 阶），非范畴性实指——
%     两两非同构的模型各有其位
%   · 弱偏序 WPO：2/3 阶关系枚举
%   · 单点域理论 SD：范畴性——唯一模型（推论 9.41 的引擎）
%   · PA⁺（无穷元素）：有限切片可满足 + 无标准见证——
%     紧致性论证（定理 9.35）的可执行内核
% ============================================================
:- discontiguous chk/2, cond/1.

% ============================================================
% 一、结构与理论
% ============================================================
% 域用 0..n-1；二元运算 = 长度 n*n 的表（行优先：op(X,Y) = 第 X*n+Y 项）
% 关系 = 序对集合

app1(Tab, N, X, Y, V) :- I is X * N + Y, nth0(I, Tab, V).

% 全部 n^(n^2) 张运算表
all_ops(N, Tab) :- gen_tab(N * N, N, Tab).
gen_tab(0, _, []).
gen_tab(L, M, [H | T]) :-
    L > 0, between(0, M, H), H < M, L1 is L - 1,
    gen_tab(L1, M, T).

% ---- MON 公理 ----
mon_assoc(Tab, N) :-
    \+ ( between(0, N, X), X < N, between(0, N, Y), Y < N, between(0, N, Z), Z < N,
         app1(Tab, N, X, Y, XY), app1(Tab, N, XY, Z, L),
         app1(Tab, N, Y, Z, YZ), app1(Tab, N, X, YZ, R), L \= R ).
mon_identity(Tab, N, E) :-
    between(0, N, E), E < N,
    \+ ( between(0, N, X), X < N,
         app1(Tab, N, E, X, X1), X1 \= X
       ; between(0, N, X), X < N,
         app1(Tab, N, X, E, X2), X2 \= X ).
is_monoid(Tab, N) :- mon_assoc(Tab, N), mon_identity(Tab, N, _).

% ---- WPO 公理（自反、反对称、传递） ----
rel_pairs(N, Pairs) :-
    findall(X-Y, (between(0, N, X), X < N, between(0, N, Y), Y < N), Pairs).
all_rels(N, Rs) :-
    rel_pairs(N, Pairs), ps(Pairs, Rs).
ps([], [[]]).
ps([H|T], Out) :- ps(T, Rest),
    findall([H|P], member(P, Rest), WithH),
    append(WithH, Rest, Out).

wpo(R, N) :-
    \+ ( between(0, N, X), X < N, \+ memberchk(X-X, R) ),               % 自反
    \+ ( between(0, N, X), X < N, between(0, N, Y), Y < N, X \= Y,
         memberchk(X-Y, R), memberchk(Y-X, R) ),                        % 反对称
    \+ ( between(0, N, X), X < N, between(0, N, Y), Y < N, between(0, N, Z), Z < N,
         memberchk(X-Y, R), memberchk(Y-Z, R), \+ memberchk(X-Z, R) ).  % 传递

% ---- SD：单点域 ----
sd_model(N, Op) :- N = 1, all_ops(1, Op), is_monoid(Op, 1).

% ---- 同构：置换搜索单射 ----
perm(0, []).
perm(N, P) :- N > 0, N1 is N - 1, numlist(0, N1, L), permutation(L, P).

iso_op(Tab1, Tab2, N) :-
    perm(N, P),
    \+ ( between(0, N, X), X < N, between(0, N, Y), Y < N,
         app1(Tab1, N, X, Y, V1),
         nth0(X, P, PX), nth0(Y, P, PY),
         app1(Tab2, N, PX, PY, V2),
         nth0(V1, P, PV1),
         PV1 \= V2 ).

% ============================================================
% 二、PA⁺ 紧致性引擎（定理 9.35 的可执行内核）
% ============================================================
% 公理集切片 {C ≠ m | m < K}：标准见证 c 满足它 ⟺ K ≤ c
sat_slice(C, K) :-
    \+ ( between(0, K, M), M < K, C = M ).

% ============================================================
% 三、电池
% ============================================================
chk(1, 'MON 一阶：恰 1 个幺半群').
cond(1) :- findall(T, (all_ops(1, T), is_monoid(T, 1)), Ms), length(Ms, 1).
chk(2, 'MON 二阶：恰 4 个（2 个同构类 × 2 种标号）').
cond(2) :- findall(T, (all_ops(2, T), is_monoid(T, 2)), Ms), length(Ms, 4).
chk(3, 'MON 三阶：恰 33 个（同构类 7 个——文献对表）').
cond(3) :- findall(T, (all_ops(3, T), is_monoid(T, 3)), Ms), length(Ms, 33).
chk(4, 'MON 非范畴：一阶模型与二阶模型并存（基数即异）').
cond(4) :- all_ops(1, T1), is_monoid(T1, 1), all_ops(2, T2), is_monoid(T2, 2).
chk(5, 'MON 二阶内部：循环群 Z2 与 ∧-半格非同构').
cond(5) :-
    C2 = [0,1, 1,0],                        % xor：循环群 Z2（幺元 0）
    AND = [0,0, 0,1],                       % ∧：幺元 1
    is_monoid(C2, 2), is_monoid(AND, 2),
    \+ iso_op(C2, AND, 2).
chk(6, '同构检查的阳性对照：∧ 与 ∨ 经 0↔1 换标同构').
cond(6) :-
    AND = [0,0, 0,1], OR = [0,1, 1,1],
    is_monoid(AND, 2), is_monoid(OR, 2),
    iso_op(AND, OR, 2).
chk(7, 'WPO 二阶：恰 3 个弱偏序').
cond(7) :- all_rels(2, Rs), include([R]>>(wpo(R, 2)), Rs, Ws), length(Ws, 3).
chk(8, 'WPO 三阶：恰 19 个（标号域）——与文献对表').
cond(8) :- all_rels(3, Rs), include([R]>>(wpo(R, 3)), Rs, Ws), length(Ws, 19).
chk(9, 'SD 范畴：单点域唯一结构（推论 9.41 引擎）').
cond(9) :- findall(M, sd_model(1, M), [_]).
chk(10, 'PA⁺ 切片可满足：每个有限 K 都有标准见证 c = K').
cond(10) :- forall(between(0, 6, K), sat_slice(K, K)).
chk(11, 'PA⁺ 无标准总见证：c=4 在 K=5 切片上失败').
cond(11) :- \+ sat_slice(4, 5).
chk(12, 'PA⁺ 见证性质：sat_slice(c,K) ⟺ K ≤ c（抽样）').
cond(12) :-
    sat_slice(3, 3), \+ sat_slice(2, 3),
    sat_slice(9, 4), \+ sat_slice(4, 9).

main :-
    ( between(1, 12, I), chk(I, What), \+ cond(I)
    -> format('FAIL ~d  ~w~n', [I, What]), halt(1)
    ;  true ), !,
    format('12 条全过~n'), halt.
