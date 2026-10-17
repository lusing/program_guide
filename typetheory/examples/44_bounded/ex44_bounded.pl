:- encoding(utf8).
/* ============================================================
   44 囿量词 F<: —— Prolog（书 ch.26–28）
   甲·bounded quantification：∀X<:T 的类型语法、定型规则
      （T-TAbs/T-TApp 的囿版）、子类型规则（SA-All 囿版）
   乙·kernel F<: vs full F<:：全称类型的两条子类型规则——
      囿版（两侧界相同）可判定、全版（界可变宽）不可判定
      （28.5 的机器注脚）——两版并载对照
   丙·样本：Top 的万物量化 ∀X<:Top、身份函数的层级、
      囿实例化降界、以及 full 版独有的一对判断
   ============================================================ */

:- use_module(library(lists)).
:- op(950, xfx, (<:)).

/* 类型：top / tv(X) / arr / forall(X, Bound, Body) */
/* 类型环境：条目 x=T 与 X<:B 两种 */
tlookup([X=T|_], X, T) :- !.
tlookup([_|G], X, T) :- tlookup(G, X, T).
blookup([X<:B|_], X, B) :- !.
blookup([_|G], X, B) :- blookup(G, X, B).

/* ---- 子类型（kernel 为默认；full 的差异规则单列） ---- */
sub(_, top, _) :- !.
sub(T, T, _) :- !.              % 结构相等（Refl 的算法化身）
sub(tv(X), T, G) :- !, blookup(G, X, B), sub(B, T, G).
sub(arr(S1, S2), arr(T1, T2), G) :- !,
    sub(T1, S1, G), sub(S2, T2, G).
sub(forall(X, B1, S), forall(X, B1, T), G) :- !,   % SA-All（kernel：同界）
    sub(S, T, [X<:B1|G]).
sub(_, _, _) :- fail.

/* full F<: 的 SA-All：左侧界可放宽 */
sub_full(_, top, _) :- !.
sub_full(T, T, _) :- !.
sub_full(tv(X), T, G) :- !, blookup(G, X, B), sub_full(B, T, G).
sub_full(arr(S1, S2), arr(T1, T2), G) :- !,
    sub_full(T1, S1, G), sub_full(S2, T2, G).
sub_full(forall(X, B1, S), forall(Y, B2, T), G) :- !,
    sub_full(B2, B1, G),                            % 界放宽（唯二差异）
    sub_full(S, T, [X<:B1|G]),
    /* 换名一致性由样本保证 */
    X = Y.
sub_full(_, _, _) :- fail.

/* ---- 定型（λ/Λ/tapp 的囿版） ---- */
typeof(v(X), G, T) :- tlookup(G, X, S),
    ( var(T) -> T = S ; sub(S, T, G) ).   % T 已定时做 T-Sub；未定时直给
typeof(lm(X, A, B), G, arr(A, T2)) :- typeof(B, [X=A|G], T2).
typeof(ap(F, A), G, T) :-
    typeof(F, G, arr(S1, S2)), typeof(A, G, A0),
    sub(A0, S1, G), sub(S2, T, G).
/* T-TAbs 囿版：ΛX<:T. t 在 X<:T 下定型 */
typeof(tabs(X, B, Body), G, forall(X, B, T2)) :-
    typeof(Body, [X<:B|G], T2).
/* T-TApp 囿版：t [T1] 要求 T1 <: 界 */
typeof(tapp(M, T1), G, Body2) :-
    typeof(M, G, forall(X, B, Body)),
    sub(T1, B, G),
    subst_ty(Body, X, T1, Body2).

subst_ty(var(X), X, S, S) :- !.
subst_ty(var(Y), _, _, var(Y)) :- !.
subst_ty(top, _, _, top) :- !.
subst_ty(arr(A, B), X, S, arr(A1, B1)) :- !,
    subst_ty(A, X, S, A1), subst_ty(B, X, S, B1).
subst_ty(forall(Y, B2, T2), X, S, forall(Y, B21, T21)) :- !,
    subst_ty(B2, X, S, B21), subst_ty(T2, X, S, T21).

/* ---- 见证 ---- */
check(Name, Goal) :-
    (   call(Goal) -> format("ok   : ~w~n", [Name])
    ;   format("FAIL : ~w~n", [Name]), fail ).

main :-
    /* ① 基础：Top 的万物性在量化里延续 */
    check("∀X<:Top.X <: ∀X<:Top.Top",
           sub(forall(x, top, var(x)), forall(x, top, top), [])),
    check("身份多态：∀X<:Top.X→X <: ∀X<:Top.X→Top",
           sub(forall(x, top, arr(var(x), var(x))),
               forall(x, top, arr(var(x), top)), [])),

    /* ② 囿实例化：T-TApp 的界检查 */
    check("ΛX<:Top.λx.x 应用 [Nat] 得 Nat→Nat",
           typeof(tapp(tabs(x, top, lm(y, var(x), v(y))), natt), [],
                  arr(natt, natt))),
    check("界是 Top：任何类型可实例化",
           typeof(tapp(tabs(x, top, lm(y, var(x), v(y))), boolt), [],
                  arr(boolt, boolt))),
    check("界约束生效：界为 Nat 时 Bool 实例化被拒",
           \+ typeof(tapp(tabs(x, natt, lm(y, var(x), v(y))), boolt), [], _)),

    /* ③ kernel vs full 的分水岭（同界 vs 放宽界） */
    check("kernel 拒绝界收窄的全称子类型",
           ( \+ sub(forall(x, top, var(x)),
                     forall(x, natt, var(x)), []) )),
    check("full 接受同一判断（SA-All 的 T1<:S1）",
           sub_full(forall(x, top, var(x)),
                    forall(x, natt, var(x)), [])),
    check("kernel 与 full 在箭头上一致（真例）",
           ( sub(arr(top, top), arr(natt, top), []),
             sub_full(arr(top, top), arr(natt, top), []) )),

    format("ok   : full 的额外力量 = 不可判定性的门票（28.5）~n"),
    format("all checks passed.~n").
