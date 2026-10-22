:- encoding(utf8).
% 第 70 章：第二递归定义定理与彻底有限集合（冯琦 §1.5-1.6）
% TC 迭代（定理 1.42）；阿克曼编码 f(N) = f(N−2^i) ∪ {f(i)}（定理 1.48）
% 与逆；非空有限集合族的 ∈-极小元（定理 1.44(3) 有限版）。

% ---------- 集合 = 规范列表包装 s/1；成员 = member ----------
flat_union(Xs, U) :-
    findall(E, (member(X, Xs), arg(1, X, Es), member(E, Es)), Es0),
    sort(Es0, U).

% ---------- 传递闭包：Xₙ₊₁ = Xₙ ∪ ⋃Xₙ 迭代到不动点 ----------
tc(X, TC) :- tc_iter([X], [], TC).
tc_iter(Xn, Y0, TC) :-
    flat_union(Xn, U1),
    ord_subtract(U1, Y0, New),
    ( New == [] -> sort(Y0, TC)
    ; append(Y0, New, Y1), sort(Y1, Y2),
      tc_iter(New, Y2, TC) ).

% ---------- 冯诺伊曼自然数 ----------
vn(0, s([])) :- !.
vn(N, s(L)) :-
    N > 0, N1 is N - 1,
    findall(V, (between(0, N1, K), vn(K, V)), L).

% ---------- 阿克曼编码（定理 1.48，以 N = n+1 改写） ----------
lg2_(0, 0) :- !.
lg2_(N, I) :- I is msb(N).

:- dynamic ack_memo/2.
ack(0, s([])) :- !.
ack(N, s(Sorted)) :-
    ( ack_memo(N, A) -> Sorted = A
    ; lg2_(N, I),
      P is 2 ^ I, R is N - P,
      ack(R, s(RS)), ack(I, IS),   % IS 是 f(i) 整体（不是其孩子表）
      sort([IS | RS], Sorted),        % f(N) = f(R) ∪ {f(I)}
      assertz(ack_memo(N, Sorted)) ).

:- dynamic inv_memo/2.
inv(s([]), 0) :- !.
inv(s(Es), V) :-
    ( inv_memo(s(Es), W) -> V = W
    ; maplist(power_code, Es, Codes),   % 每个成员贡献 2^{inv(e)}
      sum_list(Codes, V),
      assertz(inv_memo(s(Es), V)) ).

power_code(E, C) :- inv(E, C0), C is 2 ^ C0.

% ---------- ∈-极小元（定理 1.44(3) 有限版：尺寸最小者即极小） ----------
size(s(Es), S) :-
    maplist(size, Es, Ss),
    sum_list(Ss, T), S is T + 1.

list_min([A], A) :- !.
list_min([A | T], M) :-
    list_min(T, M0),
    size(A, SA), size(M0, SM),
    ( SA =< SM -> M = A ; M = M0 ).

% 极小：列表中无成员落入 Min 的成员
hf_minimal(L, Min) :-
    list_min(L, Min),
    Min = s(Ms),
    \+ ( member(s(Es), L), member(s(Es), Ms) ).

main :-
    vn(5, V5),
    tc(V5, TC5), V5 = s(L5), TC5 == L5,
    format("TC(5) = 5（自然数传递）✓~n"),
    vn(1, One),
    tc(s([One]), TC1), TC1 == [s([]), s([s([])])],
    format("TC({1}) = {0,1} ✓（定理 1.42 迭代）~n"),
    findall(N, between(0, 63, N), Ns),
    maplist(ack, Ns, Fs),
    maplist(inv, Fs, Codes),
    ( Codes == Ns -> format("阿克曼编码 0..63 往返恒等 ✓（定理 1.48+推论 1.9）~n")
    ; format("往返失败~n"), halt(1) ),
    vn(1, N1), vn(3, N3),
    L = [N1, s([]), N3, s([N1])],
    hf_minimal(L, Min), Min == s([]),
    format("集合族的 ∈-极小元 = ∅（尺寸最小者即极小，定理 1.44(3)）✓~n"),
    format("END ====~n").
