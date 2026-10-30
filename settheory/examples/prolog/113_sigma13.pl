:- encoding(utf8).

% 第 113 章：Σ¹₃ 与广泛贝尔——BK 序、双树互补、外延稳定性与
% 「扩张前后投影不变」的检查（与 Julia/Python 对拍；四证明通道另见）。

% ── 一、布劳威尔-克林序（引理 3.20 机制核） ──
% bk(S, T)：S <_BK T 即 T 是 S 的真前段，或首异位 S(k) < T(k)。
% 地基递归：右表先尽为真；表头相等下移；表头相异比大小。
bk([_|_], []).
bk([S0|Ss], [T0|Ts]) :-
    (   S0 =:= T0
    ->  bk(Ss, Ts)
    ;   S0 < T0
    ).

% 前缀取段：pfx(X, K, P) —— P 是 X 的前 K 段。
pfx(_, 0, []).
pfx([H|T], K, [H|R]) :- K > 0, K1 is K - 1, pfx(T, K1, R).

% 长度 D 的二元实数全集。
bits(0, []).
bits(D, X) :- D > 0, D1 is D - 1, bits(D1, Y), (X = [0|Y] ; X = [1|Y]).

% 整数到位串（地基枚举 2^D 条长度 D 序列）。
int_bits(0, 0, []).
int_bits(I, N, [B|Bs]) :-
    N > 0, N1 is N - 1, H is 1 << N1,
    (   I >= H
    ->  B = 1, I1 is I - H
    ;   B = 0, I1 = I
    ),
    int_bits(I1, N1, Bs).

% 沿实数前缀链逐对递降（树枝即递降链：k+1 段 <_BK k 段）。
branch_desc(X) :-
    length(X, N), N1 is N - 1,
    forall(between(0, N1, K),
           (K2 is K + 1, pfx(X, K2, P1), pfx(X, K, P0), bk(P1, P0))).

% ── 二、双树互补（定理 3.19 机制核） ──
% 稳定对（首位分裂）：p_t 与 p_s 对一切深度成立。
p_t([]).
p_t([0|_]).
p_s([]).
p_s([1|_]).

% caught(P, X)：X 的每一段前缀都被树 P 接住（pi[P] 的有限替身）。
caught(P, X) :-
    length(X, N),
    forall(between(0, N, K), (pfx(X, K, Q), call(P, Q))).

% 覆盖：深度 D 的每条实数被两树之一接住。
cover2(P, Q, D) :-
    forall(bits(D, X), (caught(P, X) -> true ; caught(Q, X))).

% 不相交：没有实数被两树同时接住。
disjoint2(P, Q, D) :-
    forall(bits(D, X), \+ (caught(P, X), caught(Q, X))).

% 截断对（覆盖当前宇宙不等于广泛贝尔）：T = {eps,0}，T* = {eps,1}。
tt([]).
tt([0]).
ts([]).
ts([1]).

% ── 三、外延稳定性：扩张前后投影不变 ──
% 细化一层（深度 D+1）被接住 => 截断（深度 D，旧实数）仍被同一棵树接住。
refine_stable(D) :-
    forall((bits(D + 1, Y), append(X, [_], Y)),
           ((p_t(Y) -> p_t(X) ; true), (p_s(Y) -> p_s(X) ; true))).

% 稳定对的覆盖在扩张前后（深度 D 与 D+1）都成立——「广泛」的量化面向。
stable_around(D) :-
    cover2(p_t, p_s, D), disjoint2(p_t, p_s, D),
    D1 is D + 1,
    cover2(p_t, p_s, D1), disjoint2(p_t, p_s, D1).

% 截断对的反例见证：覆盖@1 成立、@2 失守，四条路径全数落空。
trunc_witness(X) :-
    bits(2, X), \+ caught(tt, X), \+ caught(ts, X).

main :-
    % BK：样本取值与 Julia/Python 同账（0<1 定首异位；真前段定方向）。
    bk([0,1], [1,0]), \+ bk([1,0], [0,1]),
    bk([0,0,1], [0,0]), bk([0,1,1], [0,1]),
    % 16 条长度 4 序列前缀链逐对递降。
    forall(between(0, 15, I), (int_bits(I, 4, X), branch_desc(X))),
    % 稳定对：深度 1..3 覆盖 + 不相交；投影不变；扩张前后覆盖。
    forall(between(1, 3, D), stable_around(D)),
    forall(between(1, 3, D), refine_stable(D)),
    % 截断对：覆盖@1 成立、@2 失守，四条见证全数落空。
    cover2(tt, ts, 1), \+ cover2(tt, ts, 2),
    findall(W, trunc_witness(W), Ws),
    sort(Ws, [[0,0],[0,1],[1,0],[1,1]]),
    format("BK 序样本与前缀链递降；稳定对 1..3 覆盖+不相交+投影不变~n"),
    format("截断对覆盖@1 失守@2（四条见证）；扩张前后投影不变~n"),
    writeln("END ====").

% SWI 入口：build.ps1 以 -g main -t halt 调用。
