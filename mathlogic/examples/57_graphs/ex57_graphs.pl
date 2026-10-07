:- encoding(utf8).
% ex57_graphs.pl —— 图论专题的搜索面（Jongsma ch8）
%
% 与 Coq/Lean 通道（握手引理真证明/平面性算术/Ham 圈检查器/
% 贪心着色两定理）互补，这里跑组合搜索本体：
%   euler —— Euler 回路找迹（书 §8.1.5/Ex 8.1.22 的思想：
%           反复沿未用边走）：哥尼斯堡失败（4 奇点——必要条件
%           的活标本）、K5 成功（每点度 4 偶）；
%   ham —— Hamilton 圈回溯搜索（书 §8.2）：K5 有圈、K3,3 有圈
%           （二部平衡 3=3）、K3,4 无圈（不平衡 3≠4——Ex 8.2.17：
%           K_m,n 有 Ham 圈当且仅当 m=n）、Petersen 无圈但去掉
%           任一点后都有圈（超哈密顿性 hypohamiltonian）；
%   chromatic —— 精确色数回溯（书 §8.4.6）：χ(K4)=4、χ(C5)=3
%           （2 失败=含奇圈的机器证词）、χ(K3,3)=2（二部⇔2 色
%           Thm 8.4.2 的一侧）、χ(Petersen)=3（书例 8.4.4c）。

% ---------- 图的边表表示（U-V 对；多重图的平行边如实多条） ----------

kon_edges([a-b, a-b, a-c, a-c, a-d, b-d, c-d]).

k5_edges(L) :-
    findall(U-V, (between(0, 4, U), between(0, 4, V), U < V), L).

k4_edges(L) :-
    findall(U-V, (between(0, 3, U), between(0, 3, V), U < V), L).

k33_edges(L) :-
    findall(U-V, (between(0, 2, U), between(3, 5, V)), L).

k34_edges(L) :-
    findall(U-V, (between(0, 2, U), between(3, 6, V)), L).

c5_edges([0-1, 1-2, 2-3, 3-4, 4-0]).

% Petersen：外五边形 + 辐条 i-(i+5) + 内五星
petersen_edges([
    0-1, 1-2, 2-3, 3-4, 4-0,
    0-5, 1-6, 2-7, 3-8, 4-9,
    5-7, 7-9, 9-6, 6-8, 8-5]).

adj_member(U-V, E) :- member(U-V, E).
adj_member(U-V, E) :- member(V-U, E).

% 度数（平行边逐条计）
degree(V, E, D) :-
    aggregate_all(count, (member(U-W, E), (U == V ; W == V)), D).

% ---------- Euler 回路：沿未用边走，耗尽且回到起点 ----------

ep(U-V, U, V).
ep(U-V, V, U).

euler_walk(Edges, Start, Walk) :-
    euler_go(Edges, Start, Start, [Start], W),
    reverse(W, Walk).

euler_go([], Cur, Origin, Acc, Acc) :- Cur == Origin.
euler_go(Es, Cur, Origin, Acc, Out) :-
    select(E, Es, Es2),
    ep(E, Cur, Next),
    euler_go(Es2, Next, Origin, [Next|Acc], Out).

% ---------- Hamilton 圈：顶点排列 + 相邻成边 + 首尾相接 ----------

ham_cycle_v(Edges, [V0|Rest], Cycle) :-
    perm_adj(Edges, Rest, V0, Ps),
    reverse(Ps, [Last|_]),
    adj_member(V0-Last, Edges),
    Cycle = Ps.

perm_adj(_, [], Cur, [Cur]).
perm_adj(Edges, Us, Cur, [Cur|W]) :-
    select(U, Us, Us2),
    adj_member(Cur-U, Edges),
    perm_adj(Edges, Us2, U, W).

% 去点删边（超哈密顿性检查用）
del_vertex(V, E0, Vs0, E, Vs) :-
    exclude(has_end(V), E0, E),
    delete(Vs0, V, Vs).
has_end(V, U-W) :- (U == V ; W == V).

% ---------- 精确色数：升试 k，回溯分配（累积器保存已着色侧） ----------

coloring(Edges, Vs, K, Colors) :-
    coloring_go(Edges, Vs, K, [], Colors).

coloring_go(_, [], _, _, []).
coloring_go(Edges, [V|Vs], K, Done, [V-C|As]) :-
    between(1, K, C),
    \+ (member(U-C, Done), adj_member(U-V, Edges)),
    coloring_go(Edges, Vs, K, [V-C|Done], As).

chromatic(Edges, Vs, Chi) :-
    length(Vs, Max),
    between(1, Max, K),
    coloring(Edges, Vs, K, _), !,
    Chi = K.

% ---------- main ----------

main :-
    format('==== ex51 graphs search START ====~n'),
    % Euler：哥尼斯堡（书例 8.1.1）与 K5
    kon_edges(KE),
    findall(V-D, (member(V, [a,b,c,d]), degree(V, KE, D)), KDs),
    format('konigsberg degrees     : ~w~n', [KDs]),
    ( euler_walk(KE, a, _)
    -> format('konigsberg euler       : FOUND (impossible!)~n')
    ;  format('konigsberg euler       : none (4 odd vertices)~n' ) ),
    k5_edges(K5),
    ( euler_walk(K5, 0, W)
    -> length(W, WL),
         ECount is WL - 1,
         format('K5 euler circuit       : ~w stops / ~w edges~n', [WL, ECount])
    ;  format('K5 euler circuit       : none (unexpected!)~n') ),
    % Hamilton：K5 / K3,3 / Petersen（书 §8.2）
    numlist(0, 4, V5),
    ( ham_cycle_v(K5, V5, _) -> format('K5 hamilton cycle      : yes~n')
    ; format('K5 hamilton cycle      : NO (unexpected!)~n') ),
    k33_edges(K33), numlist(0, 5, V33),
    ( ham_cycle_v(K33, V33, _)
    -> format('K3,3 hamilton cycle    : yes (parts balanced 3=3)~n')
    ;  format('K3,3 hamilton cycle    : NO (unexpected!)~n') ),
    k34_edges(K34), numlist(0, 6, V34),
    ( ham_cycle_v(K34, V34, _)
    -> format('K3,4 hamilton cycle    : yes (unexpected!)~n')
    ;  format('K3,4 hamilton cycle    : none (parts 3 vs 4)~n') ),
    petersen_edges(Pet), numlist(0, 9, V10),
    ( ham_cycle_v(Pet, V10, _)
    -> format('petersen hamilton      : yes (unexpected!)~n')
    ;  format('petersen hamilton      : none (classic)~n') ),
    forall(between(0, 9, V),
           ( del_vertex(V, Pet, V10, E2, V2),
             ham_cycle_v(E2, V2, _) )),
    format('petersen minus any v   : hamiltonian (hypohamiltonian)~n'),
    % 色数（书 §8.4.6）
    k4_edges(K4), numlist(0, 3, V4), chromatic(K4, V4, X4),
    format('chi(K4)                : ~w~n', [X4]),
    c5_edges(C5), numlist(0, 4, VC5), chromatic(C5, VC5, X5),
    format('chi(C5)                : ~w (2 fails: odd cycle)~n', [X5]),
    chromatic(K33, V33, X33),
    format('chi(K3,3)              : ~w (bipartite)~n', [X33]),
    chromatic(Pet, V10, XP),
    format('chi(petersen)          : ~w (greedy bound is tight)~n', [XP]),
    format('==== ex51 graphs search END ====~n').
