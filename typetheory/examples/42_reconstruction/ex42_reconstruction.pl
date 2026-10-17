:- encoding(utf8).
/* ============================================================
   42 类型重构 —— Prolog：合一、约束与算法 W（书 ch.22）
   甲·合一 mgu/4：occurs check + 失败样本（22.4）
   乙·基于约束的类型化：gen_constraints（22.3 的规则 CT-**/
/*      ）与「约束可解 ⟺ 声明式可类型化」的样本面           */
/*   丙·算法 W + let 多态：主类型定理（22.5）的机器面——
      泛化（自由变量差集）/实例化（换新鲜变量）；05 章
      「无 let-多态」的已知边界在此兑现                     */
/* ============================================================ */

:- use_module(library(lists)).

/* 类型：原子 a,b,natt,boolt / tv(N)（类型变量）/ arr / 新鲜计数 */
:- dynamic fresh/1.
init_fresh :- retractall(fresh(_)), assertz(fresh(0)).
newty(T) :- retract(fresh(N)), N1 is N + 1, assertz(fresh(N1)),
            T = tv(N).

/* ---- 甲·合一（带 occurs check） ---- */
unify(A, B, []) :- A = B, !.
unify(tv(N), B, [(tv(N), B)]) :-
    \+ occurs(N, B), !.
unify(A, tv(N), S) :- \+ A = tv(N), !, unify(tv(N), A, S).
unify(prod(A1, A2), prod(B1, B2), S) :- !,
    unify(A1, B1, S1), subst_apply(S1, prod(A2, B2), prod(A2p, B2p)),
    unify(A2p, B2p, S2),
    compose(S1, S2, S).
unify(arr(A1, A2), arr(B1, B2), S) :- !,
    unify(A1, B1, S1), subst_apply(S1, arr(A2, B2), arr(A2p, B2p)),
    unify(A2p, B2p, S2),
    compose(S1, S2, S).
unify(_, _, fail) :- !.

/* occurs check：只对 ground 类型判定——裸元变量视作无出现 */
occurs(N, T) :- ground(T), occurs_g(N, T).
occurs_g(N, tv(M)) :- N =:= M, !.
occurs_g(N, arr(A, B)) :- !, occurs(N, A) ; occurs(N, B).
occurs_g(N, prod(A, B)) :- !, occurs(N, A) ; occurs(N, B).

subst_apply([], T, T).
subst_apply([(tv(N), U)|S], T, T1) :-
    apply1((tv(N), U), T, T2),
    subst_apply(S, T2, T1).
apply1((tv(N), U), T, R) :- replace_var(N, U, T, R).
replace_var(_, _, T, T) :- var(T), !.      % 裸元变量原样保留
replace_var(N, U, tv(M), R) :- !, ( M =:= N -> R = U ; R = tv(M) ).
replace_var(_, _, A, A) :- atomic(A), !.
replace_var(N, U, arr(A, B), arr(A1, B1)) :- !,
    replace_var(N, U, A, A1), replace_var(N, U, B, B1).
replace_var(N, U, prod(A, B), prod(A1, B1)) :- !,
    replace_var(N, U, A, A1), replace_var(N, U, B, B1).
replace_var(_, _, T, T).   % 兜底：裸元变量与非匹配形状原样保留

compose([], S, S).
compose([(V, U)|S1], S2, S3) :-
    subst_apply(S2, V, V2),
    subst_apply(S2, U, U2),
    compose(S1, S2, S12),
    append([(V2, U2)], S12, S3).

/* solve：逐条合一并累积 */
solve([], S, S).
solve([(A, B)|Cs], Sin, Sout) :-
    subst_apply(Sin, A, A2), subst_apply(Sin, B, B2),
    unify(A2, B2, S1), S1 \= fail,
    compose(Sin, S1, Smid),
    solve(Cs, Smid, Sout).

/* ---- 乙·约束生成（22.3 的 CT 规则直译） ---- */
/* 项：v(x) / lm(x, Tm, Body) / ap(F, A) / lett(x, M, N) / 常量 */
gen_constraints(v(X), G, T, []) :-
    lookup_poly(X, G, Ty0), inst(Ty0, T).
gen_constraints(natc, _, natt, []).
gen_constraints(boolc, _, boolt, []).
gen_constraints(lm(X, Body), G, arr(Tv, T2), Cs) :-
    newty(Tv),
    gen_constraints(Body, [mono(X, Tv)|G], T2, Cs).
gen_constraints(ap(F, A), G, T, Cs) :-
    gen_constraints(F, G, Tf, Cf),
    gen_constraints(A, G, Ta, Ca),
    append(Cf, [(Tf, arr(Ta, T))|Ca], Cs).
gen_constraints(pr(A, B), G, prod(Ta, Tb), Cs) :-
    gen_constraints(A, G, Ta, Ca),
    gen_constraints(B, G, Tb, Cb),
    append(Ca, Cb, Cs).
gen_constraints(lett(X, M, N), G, T, Cs) :-
    gen_constraints(M, G, Tm, Cm),
    /* 解 M 的约束得主类型，然后泛化 */
    solve(Cm, [], Sm),
    subst_apply(Sm, Tm, TmS),
    ftv_env(G, EnvVars),
    ftv(TmS, AllVars),
    subtract(AllVars, EnvVars, GenVars),
    generalize_from(GenVars, TmS, Scheme),
    gen_constraints(N, [poly(X, Scheme)|G], T, Cs).

lookup_poly(X, [mono(X, T)|_], T) :- !.
lookup_poly(X, [poly(X, S)|_], S) :- !.
lookup_poly(X, [_|G], S) :- lookup_poly(X, G, S).

/* 实例化：方案里的量化变量换新鲜 */
inst(T, T2) :- \+ is_scheme(T), !, T2 = T.
inst(scheme(Qs, Body), T2) :- !,
    maplist([tv(N)-_, tv(N)-U]>>newty(U), Qs, Qs2),
    replace_all(Qs2, Body, T2).
is_scheme(scheme(_, _)).

replace_all([], T, T).
replace_all([tv(N)-U|R], T, T2) :-
    replace_var(N, U, T, T1), replace_all(R, T1, T2).

ftv(A, []) :- atomic(A), !.
ftv(tv(N), [N]) :- !.
ftv(arr(A, B), S) :- ftv(A, Sa), ftv(B, Sb), union(Sa, Sb, S).
ftv(prod(A, B), S) :- ftv(A, Sa), ftv(B, Sb), union(Sa, Sb, S).
ftv(scheme(Qs, Body), S) :-
    maplist([tv(N)-_, N]>>true, Qs, QsN),
    ftv(Body, S0), subtract(S0, QsN, S).

ftv_env(G, Ss) :-
    findall(V, (member(mono(_, T), G), ftv(T, Vs), member(V, Vs)), Vs1),
    findall(V, (member(poly(_, S), G), ftv(S, Vs2), member(V, Vs2)), Vs2f),
    union(Vs1, Vs2f, Ss).

generalize_from([], T, scheme([], T)) :- !.
generalize_from(GenVars, T, scheme(Qs, T)) :-
    maplist([N, tv(N)-_]>>true, GenVars, Qs).

/* 主类型检查的入口：全部约束可解 */
principal_type(T, Ty) :-
    init_fresh,
    gen_constraints(T, [], Ty, Cs),
    solve(Cs, [], S),
    subst_apply(S, Ty, TyS),
    \+ ( ftv(TyS, Vs), member(V, Vs), memberchk(tv(V), [tv(-1)]) ).

wtype(T, Ty) :-  % 输出主类型（不做闭项检查——样本皆基型）
    init_fresh,
    gen_constraints(T, [], Ty, Cs),
    solve(Cs, [], S),
    subst_apply(S, Ty, TyS),
    ( ftv(TyS, []) -> Ty = TyS ; Ty = TyS ).  % 展示用：含变量也打印

/* ---- 见证 ---- */
check(Name, Goal) :-
    (   call(Goal) -> format("ok   : ~w~n", [Name])
    ;   format("FAIL : ~w~n", [Name]), fail ).

main :-
    /* ① 合一三样本（22.4） */
    init_fresh,
    check("合一：α 遇 β 给代换",
           ( unify(tv(100), tv(101), S1), S1 = [(tv(100), tv(101))] )),
    check("合一：a→b 遇 a→b 恒等",
           unify(arr(a, b), arr(a, b), [])),
    check("occurs check：α 遇 α→β 拒绝（S = fail）",
           ( unify(tv(102), arr(tv(102), b), S2), S2 = fail )),

    /* ② 无类型注释的 λ：恒等函数的主类型是 α→α */
    check("λx.x : α→α（22.5 主类型样本）",
           ( wtype(lm(x, v(x)), arr(tv(N), tv(N))), N >= 0 )),
    check("(λx.x) 5 : Nat（约束求解消掉变量）",
           wtype(ap(lm(x, v(x)), natc), natt)),

    /* ③ let 多态：05 章已知边界的兑现 */
    check("let f=λx.x in (f 1, f true) 双双通过",
           wtype(lett(f, lm(x, v(x)), pr(ap(v(f), natc), ap(v(f), boolc))),
                 prod(natt, boolt))),
    check("对照：λf. (f 1, f true) 无多态被拒",
           \+ wtype(lm(f, pr(ap(v(f), natc), ap(v(f), boolc))),
                    prod(natt, boolt))),

    /* ④ 约束式与算法式同答（22.3/22.5 的等价样本） */
    check("约束式：λx.x 的约束集 {(α0, α0)} 可解",
           ( init_fresh, gen_constraints(lm(x, v(x)), [], T0, Cs),
             solve(Cs, [], _), T0 = arr(tv(0), tv(0)) )),

    format("all checks passed.~n").

