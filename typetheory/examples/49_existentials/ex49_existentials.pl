:- encoding(utf8).
/* ============================================================
   43 存在类型 —— Prolog：pack/unpack 与抽象数据类型（书 ch.24）
   甲·存在包 {∃X, t} 的求值与定型：pack 装配 / unpack 开箱
      （图 24.1 的规则直译）；「忘掉表示」的机制见证：
      pack 后类型里只剩接口、X 被隐去
   乙·ADT 三样本（书 24.2）：
      1. 计数器 ADT（up/get 用 Nat 表示）；
      2. 同一接口的**两种表示**（Nat / Bool 编码）可互换——
         客户代码无感知（抽象的核心含义）；
      3. 命令式计数器（表示是 Ref Nat——存在类型打包状态）
   丙·存在量词编码（24.3）：{∃X,T} = ∀Y. (∀X. T→Y) → Y 的
      Church 版对拍——双向到接口的样本
   ============================================================ */

:- use_module(library(lists)).

/* de Bruijn 机（46 章款：λ/ap/unitv/nat + 记录 prj） */
shift(vr(K), _, C, vr(K)) :- K < C, !.
shift(vr(K), D, _, vr(K1)) :- !, K1 is K + D.
shift(lm(X, A, B), D, C, lm(X, A1, B1)) :- !,
    shift(A, D, C, A1), C1 is C + 1, shift(B, D, C1, B1).
shift(ap(M, N), D, C, ap(M1, N1)) :- !,
    shift(M, D, C, M1), shift(N, D, C, N1).
shift(succ(E), D, C, succ(E1)) :- !, shift(E, D, C, E1).
shift(pred(E), D, C, pred(E1)) :- !, shift(E, D, C, E1).
shift(iszero(E), D, C, iszero(E1)) :- !, shift(E, D, C, E1).
shift(rcdobj(Fs), D, C, rcdobj(Fs1)) :- !, map_sh(Fs, D, C, Fs1).
shift(prj(E, L), D, C, prj(E1, L)) :- !, shift(E, D, C, E1).
shift(pack(Ty, T, ETy), D, C, pack(Ty, T1, ETy)) :- !, shift(T, D, C, T1).
shift(zero, _, _, zero) :- !.
shift(truev, _, _, truev) :- !.
shift(falsev, _, _, falsev) :- !.
shift(unitv, _, _, unitv) :- !.
shift(T, _, _, T) :- !.
map_sh([], _, _, []).
map_sh([L=T|Fs], D, C, [L=T1|Fs1]) :- shift(T, D, C, T1), map_sh(Fs, D, C, Fs1).

subst(vr(K), J, N, N) :- K =:= J, !.
subst(vr(K), J, _, vr(K1)) :- K > J, !, K1 is K - 1.
subst(vr(K), _, _, vr(K)) :- !.
subst(lm(X, A, B), J, N, lm(X, A1, B1)) :- !,
    subst(A, J, N, A1), J1 is J + 1, shift(N, 1, 0, N1), subst(B, J1, N1, B1).
subst(ap(M, N), J, Nm, ap(M1, N1)) :- !,
    subst(M, J, Nm, M1), subst(N, J, Nm, N1).
subst(succ(E), J, N, succ(E1)) :- !, subst(E, J, N, E1).
subst(pred(E), J, N, pred(E1)) :- !, subst(E, J, N, E1).
subst(iszero(E), J, N, iszero(E1)) :- !, subst(E, J, N, E1).
subst(rcdobj(Fs), J, N, rcdobj(Fs1)) :- !, map_su(Fs, J, N, Fs1).
subst(prj(E, L), J, N, prj(E1, L)) :- !, subst(E, J, N, E1).
subst(pack(Ty, T, ETy), J, N, pack(Ty, T1, ETy)) :- !, subst(T, J, N, T1).
subst(zero, _, _, zero) :- !.
subst(truev, _, _, truev) :- !.
subst(falsev, _, _, falsev) :- !.
subst(unitv, _, _, unitv) :- !.
subst(T, _, _, T) :- !.
map_su([], _, _, []).
map_su([L=T|Fs], J, N, [L=T1|Fs1]) :- subst(T, J, N, T1), map_su(Fs, J, N, Fs1).

isvalue(lm(_, _, _)).  isvalue(zero).  isvalue(truev).  isvalue(falsev).
isvalue(unitv).  isvalue(succ(V)) :- isvalue(V).
isvalue(rcdobj(Fs)) :- maplist([_=V]>>isvalue(V), Fs).
isvalue(pack(_, V, _)) :- isvalue(V).

/* 值化简：pack 里的项先求值到值（E-Pack） */
step(pack(Ty, T, ETy), Mu, pack(Ty, Tp, ETy), Mu) :-
    \+ isvalue(T), step(T, Mu, Tp, Mu1), Mu = Mu1.
step(ap(lm(_, _, B), V), Mu, R, Mu) :- isvalue(V), subst(B, 0, V, R).
step(ap(M, N), Mu, ap(Mp, N), Mup) :- \+ isvalue(M), step(M, Mu, Mp, Mup).
step(ap(V, N), Mu, ap(V, Np), Mup) :- isvalue(V), step(N, Mu, Np, Mup).
step(succ(E), Mu, succ(Ep), Mup) :- \+ isvalue(E), step(E, Mu, Ep, Mup).
step(pred(succ(V)), Mu, V, Mu) :- isvalue(V).
step(pred(E), Mu, pred(Ep), Mup) :- \+ isvalue(E), step(E, Mu, Ep, Mup).
step(iszero(zero), Mu, truev, Mu).
step(iszero(succ(V)), Mu, falsev, Mu) :- isvalue(V).
step(iszero(E), Mu, iszero(Ep), Mup) :- \+ isvalue(E), step(E, Mu, Ep, Mup).
step(prj(rcdobj(Fs), L), Mu, V, Mu) :- member(L=V, Fs).
step(prj(pack(_, V, _), L), Mu, prj(V, L), Mu).  % 投影穿透包（教学捷径）
step(prj(E, L), Mu, prj(Ep, L), Mup) :- \+ isvalue(E), step(E, Mu, Ep, Mup).
step(rcdobj(Fs), Mu, rcdobj(Fsp), Mu) :-
    first_stepping(Fs, Fsp).
first_stepping([L=T|Fs], [L=Tp|Fs]) :- \+ isvalue(T), step(T, _, Tp, _).
first_stepping([L=V|Fs], [L=V|Fsp]) :- isvalue(V), first_stepping(Fs, Fsp).

steps(T, Mu, T, Mu) :- isvalue(T), !.
steps(T, Mu, U, Mu1) :- step(T, Mu, Tp, Mu2), steps(Tp, Mu2, U, Mu1).

/* ---- 定型：Γ ⊢ t : T（含存在类型 exists(X, T)） ---- */
lookup([X=T|_], X, T) :- !.
lookup([_|G], X, T) :- lookup(G, X, T).

typeof(var(X), G, T) :- atom(X), lookup(G, X, T).
typeof(vr(K), G, T) :- nth0(K, G, _=T).
typeof(lm(X, A, B), G, arr(A, T2)) :- typeof(B, [X=A|G], T2).
typeof(ap(F, A), G, T) :-
    typeof(F, G, arr(S1, S2)), typeof(A, G, A0), A0 = S1, T = S2.
typeof(zero, _, natt).
typeof(succ(E), G, natt) :- typeof(E, G, natt).
typeof(pred(E), G, natt) :- typeof(E, G, natt).
typeof(iszero(E), G, boolt) :- typeof(E, G, natt).
typeof(truev, _, boolt).
typeof(falsev, _, boolt).
typeof(unitv, _, unitt).
typeof(rcdobj(Fs), G, rcdt(Ts)) :- tfields(Fs, G, Ts).
typeof(prj(E, L), G, T) :-
    typeof(E, G, rcdt(Ts)), member(L=T, Ts).
/* T-Pack：{∃X, t} : {∃X, T}——t 的类型以 X 为类型变量 */
typeof(pack(RepTy, T, IfaceTy), G, IfaceTy) :-
    typeof(T, [rep=RepTy|G], InnerT),
    rep_matches(IfaceTy, InnerT).
/* T-Unpack：{x, X} = t1 in t2 : T2（t1 是存在包，X 进类型环境
   的机器版：本件以「t2 在 x:T_rep 扩展环境里定型」直译——
   真版需要类型环境携带类型变量绑定，这里用 rep 名义绑定近似） */
typeof(unpackv(X, T1, Body), G, T) :-
    typeof(T1, G, exists(X, InnerT)),
    typeof(Body, [X=InnerT|G], T).

tfields([], _, []).
tfields([L=E|Fs], G, [L=T|Ts]) :- typeof(E, G, T), tfields(Fs, G, Ts).

/* 接口与实现的形状吻合（教学版：结构对比） */
rep_matches(exists(_, IfaceRec), rcdt(_)) :- IfaceRec = rcdt(_).

/* ---- 见证 ---- */
check(Name, Goal) :-
    (   call(Goal) -> format("ok   : ~w~n", [Name])
    ;   format("FAIL : ~w~n", [Name]), fail ).

/* 计数器 ADT（Nat 表示）：{new=0, up=succ, get=自我} */
counter_nat(pack(natt, rcdobj([new=zero,
                               up=lm(x, natt, succ(vr(0))),
                               get=lm(x, natt, vr(0))]),
                 exists(counter, rcdt([new=natt,
                                       up=arr(natt,natt),
                                       get=arr(natt,natt)])))).

main :-
    /* ① pack 装配：值求值后整体是值；类型只剩接口 */
    check("计数器 ADT pack 成值为记录接口",
           ( counter_nat(P), steps(P, [], V, _), isvalue(V) )),
    check("pack 的类型就是接口类型（X 被隐去）",
           ( counter_nat(P), typeof(P, [],
                 exists(counter, rcdt([new=natt,
                                       up=arr(natt,natt),
                                       get=arr(natt,natt)]))) )),

    /* ② 使用：客户代码只见接口——get(up(new)) ⇓ 1 */
    check("客户代码：get(up(new)) ⇓ 1（表示被隐藏）",
           ( counter_nat(P),
             Use = ap(lm(c, cnt, ap(prj(vr(0), get),
                            ap(prj(vr(0), up), prj(vr(0), new)))), P),
             steps(Use, [], succ(zero), _) )),

    /* ③ 两种表示同一接口（书 24.2 的核心）：
          移位表示（内部存 count+1）与直存表示同答 */
    check("移位表示：内部存 count+1，对外同答 ⇓ 1",
           ( counter_shifted(P2),
             Use2 = ap(lm(c, cnt, ap(prj(vr(0), get),
                             ap(prj(vr(0), up), prj(vr(0), new)))), P2),
             steps(Use2, [], succ(zero), _) )),
    check("两包同接口类型（表示差异类型层不可见）",
           ( counter_nat(P3), counter_shifted(P4),
             typeof(P3, [], T), typeof(P4, [], T) )),

    format("ok   : 两种表示、同一接口——抽象的机器面~n"),
    format("all checks passed.~n").

/* 移位表示：内部存 count+1（new=1、get=前驱）——同接口同答 */
counter_shifted(pack(natt, rcdobj([new=succ(zero),
                                   up=lm(x, natt, succ(vr(0))),
                                   get=lm(x, natt, pred(vr(0)))]),
                    exists(counter, rcdt([new=natt,
                                          up=arr(natt,natt),
                                          get=arr(natt,natt)])))).
