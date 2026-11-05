:- encoding(utf8).
% 第 57 章 Prolog：Cantor 地址树与填充侧穷举。
% ① 地址（0/2 三进制数字串）→ 区间端点（rdiv 精确）；
% ② 每阶段 2^k 段、总长 (2/3)^k 的精确账；
% ③ 有限深度成员判定；
% ④ 阶段 2 的 8 点集上，δ=1/12 时互不相交球族（独立集）穷举，
%    填充预测度 sup = 最大独立集 × 2δ（正文 57.7 的 sup 在有限世界的化身）。
:- initialization(main).

% ---------- ① 地址 → 区间 ----------
% 地址 [d1,...,dk]（di ∈ {0,2}）给出第 k 阶区间 [lo, lo+3^-k]，
% lo = Σ_{i≤k} di·3^{-i}，全程有理数（rdiv）。
addr_interval(Addr, Lo, Hi) :-
    length(Addr, K),
    foldl([D, (I0, A0), (I1, A1)]>>(
              I1 is I0 + 1,
              A1 is A0 + D rdiv 3^I1),
          Addr, (0, 0), (_, Lo)),
    Hi is Lo + 1 rdiv 3^K.

% 阶段 k 的全部 2^k 个地址
stage_addrs(K, Addrs) :-
    findall(A, (length(A, K), member_seq(K, A)), All),
    sort(All, Addrs).

member_seq(0, []) :- !.
member_seq(K, [D|Rest]) :- member(D, [0, 2]), K1 is K - 1, member_seq(K1, Rest).

% ---------- ② 阶段账：段数 2^k，总长 (2/3)^k ----------
stage_account(K, Count, Total) :-
    stage_addrs(K, As),
    length(As, Count),
    Count =:= 2^K,
    Total is Count * 1 rdiv 3^K,
    Total =:= (2^K rdiv 3^K).

% ---------- ③ 有限深度成员判定 ----------
in_cantor(X, K) :-
    stage_addrs(K, Addrs),
    member(Addr, Addrs),
    addr_interval(Addr, Lo, Hi),
    X >= Lo, X =< Hi.

% ---------- ④ 填充侧：独立集穷举 ----------
% 阶段 2 的 8 点（含端点 0 与 1），相邻距离 1/9。
stage2_points([0 rdiv 1, 1 rdiv 9, 2 rdiv 9, 3 rdiv 9, 6 rdiv 9, 7 rdiv 9, 8 rdiv 9, 9 rdiv 9]).

% δ = 1/12：两球（半径 ≤ δ）不相交 ⟺ 球心距 > 2δ = 1/6 > 1/9。
% 相邻点（距 1/9 < 1/6）不能同摆 ⇒ 摆法 = 8 点路径图上的独立集。
delta(1 rdiv 12).

compatible(P, Q) :- delta(D), Dist is abs(P - Q), Dist > 2 * D.

% 穷举所有两两兼容（可同摆）的子集
independent(Points, Sub) :-
    sub_list(Points, Sub),
    pairwise_compatible(Sub).

sub_list([], []).
sub_list([H|T], [H|R]) :- sub_list(T, R).
sub_list([_|T], R) :- sub_list(T, R).

pairwise_compatible([]).
pairwise_compatible([H|T]) :-
    maplist({H}/[Q]>>compatible(H, Q), T),
    pairwise_compatible(T).

% 填充账（s=1）：Σ 2r = |Sub|·2δ（取最大允许半径 δ 才达到 sup）
pack_sum(Sub, S) :-
    length(Sub, N),
    delta(D),
    S is N * 2 * D.

main :-
    format("==== 57 hausdorff~n"),
    % ① + ② 阶段账
    forall(member(K, [1, 2, 3, 4]),
           (stage_account(K, C, T),
            format("   阶段 ~d：~d 段，总长 ~w（= (2/3)^~d）~n", [K, C, T, K]))),
    format("① 地址树：每阶段 2^k 段、总长 (2/3)^k，rdiv 全精确~n"),
    % ③ 成员判定抽查：1/4 = 0.\overline{02}_3 ∈ C；1/2 落在中段
    in_cantor(1 rdiv 4, 6),
    \+ in_cantor(1 rdiv 2, 6),
    format("③ 成员判定：1/4 ∈ C（6 层内命中区间）；1/2 ∉ C（6 层内无命中）~n"),
    % ④ 填充侧穷举
    stage2_points(Ps),
    findall(S, (independent(Ps, Sub), pack_sum(Sub, S)), Sums),
    max_list(Sums, Max),
    Max =:= 4 * (2 * 1 rdiv 12),
    length_max_independent(Ps, MaxN),
    MaxN =:= 4,
    format("④ 填充账（δ=1/12，s=1）：独立集穷举 sup = 4×2δ = 2/3~n"),
    format("   相邻点（距 1/9 < 2δ = 1/6）互斥，摆法 = 路径独立集；~n"),
    format("   覆盖侧可用点覆盖（直径 0）清零：φ-m ≤ φ-P 的有限对照~n"),
    format("END ====~n").

% 最大独立集规模（与 pack_sum 的 sup 相互印证）
length_max_independent(Ps, N) :-
    aggregate_all(max(L), (independent(Ps, Sub), length(Sub, L)), N).
