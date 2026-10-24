:- encoding(utf8).
% 第 71 章：序数与累积层次（冯琦 §1.7）
% 有限序数的结构演绎：成员/三择一（1.50 有限截面）/最小元（1.51）/
% 秩恒等 RK(n) = n（命题 1.21 的谓词形态）。

% ---------- 有限冯诺伊曼序数：z / s；成员 a ∈ b+1 ⟺ a = b ∨ a ∈ b ----------

vmem(A, s(B)) :- A = B, !.
vmem(A, s(B)) :- vmem(A, B).

% ---------- 尺寸（秩）：RK = 尺寸（命题 1.21 的谓词形态） ----------

vsize(z, 0).
vsize(s(N), T) :- vsize(N, T0), T is T0 + 1.

% ---------- 三择一的三个互斥出口（定理 1.50 的有限截面） ----------

tri(a_lt_b, A, B) :- vsize(A, S1), vsize(B, S2), S1 < S2.
tri(a_eq_b, A, B) :- vsize(A, S), vsize(B, S).
tri(a_gt_b, A, B) :- vsize(A, S1), vsize(B, S2), S1 > S2.

% ---------- 最小元（定理 1.51 的有限版） ----------

vmin([A], A) :- !.
vmin([A | T], M) :-
    vmin(T, M0),
    vsize(A, SA), vsize(M0, SM),
    ( SA < SM -> M = A ; M = M0 ).

% ---------- sup = ⋃（命题 1.20）：线性链之并 = 最大者 ----------

vunion(A, B, A) :- vmem(B, A), !.
vunion(A, B, B) :- vmem(A, B).

% ---------- 数字构造子：vn(N, X) ----------

vn(0, z) :- !.
vn(N, s(X)) :- N > 0, N1 is N - 1, vn(N1, X).

main :-
    % 三择一恰一成立（0..6 全对）
    forall(between(0, 6, I), forall(between(0, 6, J),
        ( vn(I, A), vn(J, B),
          findall(K, tri(K, A, B), Ks),
          length(Ks, 1) ->
            true
        ; format("三择一失败 at ~w,~w~n", [I, J]), halt(1) ) )),
    format("0..6 全对：三择一恰一成立 ✓~n"),
    % 成员 ⟺ 更小
    ( vmem(z, s(s(z))) -> true ; format("0 ∈ 2 失败~n"), halt(1) ),
    ( \+ vmem(s(z), z) -> true ; format("1 ∈ 0 不应成立~n"), halt(1) ),
    format("成员方向：0 ∈ 2 ✓、1 ∉ 0 ✓（∈ 即 <）~n"),
    % RK 恒等
    forall(between(0, 8, N), ( vn(N, X), vsize(X, N) )),
    format("RK(n) = n 在 0..8 全对 ✓（斜率 1 的直线）~n"),
    % 最小元
    maplist(vn, [3, 1, 2], [A3, A1, A2]),
    vmin([A3, A1, A2], M), M == A1,
    format("min{3,1,2} = 1 ✓~n"),
    % 并 = 最大
    vn(2, V2), vn(4, V4), vunion(V2, V4, U), U == V4,
    format("⋃{2,4} = 4 ✓（sup = ⋃）~n"),
    format("END ====~n").
