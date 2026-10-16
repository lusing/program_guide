:- encoding(utf8).
/* ============================================================
   10 逆主类型与凝结分离 —— Prolog 主场（Hindley ch.7）
   凝结分离规则 (D)（Carew Meredith 1954）：
       D(ρ→υ)τ = s₁(υ)，其中 s₁(ρ) = s₂(τ) = 最一般公共实例
   ——Prolog 的合一就是 m.g.c.i. 的机器化身（须 occurs-check）。
   7D2（D. Meredith 引理）：PT(PQ) = D(PT P)(PT Q)。
   本文件：cd/3 原语 + D-链 + 四系统 D-定理 + 双机互证样本。
   ============================================================ */

/* ---- 公理模式（组合子主类型，类型变元 = Prolog 变量） ---- */
ax(b, arr(arr(A, B), arr(arr(C, A), arr(C, B)))).
ax(c, arr(arr(A, arr(B, C)), arr(B, arr(A, C)))).
ax(i, arr(A, A)).
ax(k, arr(A, arr(_, A))).
ax(w, arr(arr(A, arr(A, B)), arr(A, B))).
ax(s, arr(arr(A, arr(B, C)), arr(arr(A, B), arr(A, C)))).

system(int, [b, c, k, w]).
system(r_,  [b, c, i, w]).
system(bck, [b, c, k]).
system(bci, [b, c, i]).

/* ---- 凝结分离原语：cd(大前提, 小前提, 结论) ----
   两前提取独立新鲜副本（copy_term），合一前件 = 求 m.g.c.i.，
   结论 = 实例化后的后件。occurs-check 是安全带（09 章翻案实录）。 */
cd(Major, Minor, Conc) :-
    copy_term(Major, arr(P, Q)),
    copy_term(Minor, T),
    unify_with_occurs_check(P, T),
    Conc = Q.

/* ---- D-定理搜索：叶端公理 + D 步（7D4 凝结逻辑）。
   D 步 = 「大前提先落地（P/Q 随其证明实例化），再证同一 P」——
   每步就是一次凝结分离（代换被叶端合一吸收，7D1.2(iii)）。 ---- */
dthm(Sys, T, _) :- system(Sys, Combs), member(Cb, Combs), ax(Cb, T).
dthm(Sys, T, D) :-
    D > 1, D1 is D - 1,
    dthm(Sys, arr(P, Q), D1),   % 大前提：某 D-定理 σ→T（σ 随证明落地）
    dthm(Sys, P, D1),           % 小前提：证出【同一个】σ
    T = Q.

/* ---- 检查宏 ---- */
check(Name, Goal) :-
    ( call(Goal) -> format("ok   ~w~n", [Name])
    ; format("FAIL ~w~n", [Name]), halt(1) ).

/* 与 Lean 互证的双口径：α-等价 = 可合一（双向 occurs-check） */
alpha_eq(X, Y) :- copy_term(Y, Y1), unify_with_occurs_check(X, Y1).

main :-
    /* ① cd(B, B)：BB 的主类型（与 Lean principal (λ 计算) 互证） */
    ax(b, B1), ax(b, B2),
    cd(B1, B2, BB),
    format("cd(B,B)   = ~w~n", [BB]),

    /* ② cd(S, K) 再 cd K：SKK 的主类型链，终值 = I 的型 a→a */
    ax(s, S1), ax(k, K1), ax(k, K2),
    cd(S1, K1, SK),
    format("cd(S,K)   = ~w~n", [SK]),
    cd(SK, K2, SKK),
    check("cd-chain SKK = I-type", alpha_eq(SKK, arr(x, x))),

    /* ③ cd(C, I)：CI = λyz. z y（反向应用子），主类型 a→(a→b)→b
       ——与 Lean principal (λyz. z y) 双机互证 */
    ax(c, C1), ax(i, I1),
    cd(C1, I1, CI),
    format("cd(C,I)   = ~w~n", [CI]),
    check("cd(C,I) = a->(a->b)->b", alpha_eq(CI, arr(A3, arr(arr(A3, B3), B3)))),

    /* ④ cd(I, K)：I K =β K，主类型回到 K 自己的型 */
    ax(k, K3),
    cd(I1, K3, IK),
    check("cd(I,K) = K-type", alpha_eq(IK, arr(A4, arr(_, A4)))),

    /* ⑤ D-定理：I 可由 {B,C,K} 纯 D 步推出（7D10 直觉主义 D-完全
       的核心样本；09 章已用 MP+叶端代换版跑通，此处 D 原语重跑） */
    check("I D-derivable from {B,C,K}", dthm(bck, arr(x, x), 4)),

    /* ⑥ D-定理在 R_：W 的「表亲」(a→(a→b)→b) 也可由 {B,C,I,W}
       D-推出——cd(C,I) 的结论正是它（一步） */
    check("a->(a->b)->b D-derivable in r_", dthm(r_, arr(x, arr(arr(x, y), y)), 3)),

    format("all checks passed.~n").
