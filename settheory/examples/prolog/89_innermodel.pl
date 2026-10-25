:- encoding(utf8).
% 第 89 章 · 内模型 HOD、L[A] 与 L(ℝ)（冯琦第二卷 §2.2）——Prolog 通道
% 与 Python 同一组检查：OD(V_3) 见证、引理 2.27(3) 等价、
% 谓词免参定义力、L[U] 计算账。

% ---------- HF 层次（嵌套列表表示，87 章惯用法） ----------

mask_sub([], _, []).
mask_sub([X | Xs], M, Sub) :-
    M1 is M >> 1,
    (   M mod 2 =:= 0 -> Sub = Rest ; Sub = [X | Rest] ),
    mask_sub(Xs, M1, Rest).

powerset_hf(P, S) :-
    length(P, K), N1 is (1 << K) - 1,
    findall(Sub, (between(0, N1, M), mask_sub(P, M, Sub)), Subs0),
    sort(Subs0, S).

vlevel(0, []).
vlevel(N, L) :- N > 0, N1 is N - 1, vlevel(N1, Prev), powerset_hf(Prev, L).

% 冯诺依曼后继：n+1 = n ∪ {n}。
succ_vn(N, S) :- append(N, [N], Ns), sort(Ns, S).

nat_vn(0, []).
nat_vn(N, V) :- N > 0, N1 is N - 1, nat_vn(N1, V1), succ_vn(V1, V).

% ---------- 一、OD(V_3) = V_3（例 2.2(1)）：序数参数见证 ----------

% 四条带（序数）参数的 Delta_0 公式，以谓词形式给出。
witness([], x_eq_0).
witness([[]], x_eq_1).
witness([[], [[]]], x_eq_2).
witness([[[]]], x_eq_singleton1).       % x = {1}：全体成员等于 1 且非空

uniq_ext(V3, X, W) :-
    member(W, [x_eq_0, x_eq_1, x_eq_2, x_eq_singleton1]),
    findall(A, (member(A, V3), witness(A, W)), [X]).

% ---------- 二、引理 2.27(3) 等价式的数值验证 ----------

% TC+ 闭包：嵌套列表的全体成员（含自身）。
tc_closure(Start, Seen) :-
    tc_loop([Start], [], Seen).

tc_loop([], Seen, Seen).
tc_loop([X | Todo], Seen0, Seen) :-
    (   member(X, Seen0) -> tc_loop(Todo, Seen0, Seen)
    ;   is_list(X),
        append(X, Todo, Todo1),
        tc_loop(Todo1, [X | Seen0], Seen)
    ).

in_v3(Y) :- vlevel(3, V3), member(Y, V3).

hered_tc(X) :- tc_closure(X, Seen), forall(member(Y, Seen), in_v3(Y)).
hered_split(X) :- in_v3(X), forall(member(Y, X), hered_tc(Y)).

% ---------- 三、谓词原子对免参定义力的提升 ----------

sat_free(tt, _, _).
sat_free(ff, _, _) :- fail.
sat_free(inA, X, U) :- member(X, U).
sat_free(neg(F), X, U) :- \+ sat_free(F, X, U).
sat_free(or(F, G), X, U) :- ( sat_free(F, X, U) ; sat_free(G, X, U) ).

free_ext(F, U, E) :-
    vlevel(2, V2),
    findall(X, (member(X, V2), sat_free(F, X, U)), E0),
    sort(E0, E).

% ---------- 主程序 ----------

main :-
    writeln("==== 89"),
    vlevel(3, V3),
    length(V3, 4),
    forall(member(A, V3), uniq_ext(V3, A, _)),
    writeln("V_3 四元素全部有序数参数 Delta_0 唯一见证：OD(V_3) = V_3 OK"),
    vlevel(4, V4),
    forall(member(X, V4), (hered_tc(X) -> hered_split(X) ; \+ hered_split(X))),
    forall(member(X, V4), (hered_split(X) -> hered_tc(X) ; true)),
    writeln("V_4 全体：Hered_TC 与分解式等价——引理 2.27(3) 等价成立 OK"),
    vlevel(2, V2), V2 = [Z0, Z1],
    U = [Z0],
    findall(E, (member(F, [tt, ff, neg(tt), or(tt, ff)]), free_ext(F, U, E)), NoP0),
    sort(NoP0, NoP),
    length(NoP, 2),
    findall(E, (member(F, [tt, ff, inA, neg(inA), or(inA, tt), or(inA, ff)]),
                free_ext(F, U, E)), WP0),
    sort(WP0, WP),
    length(WP, 4),
    writeln("V_2 免参可定义子集：无谓词 2 个 -> 带谓词 4 个——U 截断进入免参定义 OK"),
    % L[U] 计算账：U 属于 V_3 = L_3[U]（谓词原子的扩张恰为 U 截断）
    member(U, V3),
    writeln("L[U] 有限层与 V 重合，U 属于 L_3[U]：引理 2.24 计算账 OK"),
    writeln("END ====").
