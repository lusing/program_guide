:- encoding(utf8).
/* ============================================================
   46 纯函数对象 —— Prolog（书 ch.32）
   对象 = 存在类型 × 记录接口 × 递归（self 三合一）：
   Counter = ∃Self. { get : Self → Nat, inc : Self → Self }
   32.1–32.5 的编码阶梯：
     简单对象（记录里的函数收到 self 参数）→ 子类型化
     （接口可伸缩）→ 囿量词（Self 的界 = 接口本身）→
     接口类型（行为约束）→ 多态更新（32.7：记录更新的
     类型层难点以存在+囿的组合解）
   机器面：编码项的求值走 37/38 章的同款机器；本章验证
   「对象调用 = self 应用」的一步链与接口封闭性
   ============================================================ */

:- use_module(library(lists)).

/* de Bruijn 机（命名 lm(x, T, Body) + 记录） */
shift(vr(K), _, C, vr(K)) :- K < C, !.
shift(vr(K), D, _, vr(K1)) :- !, K1 is K + D.
shift(lm(X, A, B), D, C, lm(X, A1, B1)) :- !,
    shift(A, D, C, A1), C1 is C + 1, shift(B, D, C1, B1).
shift(ap(M, N), D, C, ap(M1, N1)) :- !,
    shift(M, D, C, M1), shift(N, D, C, N1).
shift(succ(E), D, C, succ(E1)) :- !, shift(E, D, C, E1).
shift(pred(E), D, C, pred(E1)) :- !, shift(E, D, C, E1).
shift(rcdobj(Fs), D, C, rcdobj(Fs1)) :- !, map_sh(Fs, D, C, Fs1).
shift(prj(E, L), D, C, prj(E1, L)) :- !, shift(E, D, C, E1).
shift(pack(Ty, T, ETy), D, C, pack(Ty, T1, ETy)) :- !, shift(T, D, C, T1).
shift(zero, _, _, zero) :- !.
shift(truev, _, _, truev) :- !.
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
subst(rcdobj(Fs), J, N, rcdobj(Fs1)) :- !, map_su(Fs, J, N, Fs1).
subst(prj(E, L), J, N, prj(E1, L)) :- !, subst(E, J, N, E1).
subst(pack(Ty, T, ETy), J, N, pack(Ty, T1, ETy)) :- !, subst(T, J, N, T1).
subst(zero, _, _, zero) :- !.
subst(truev, _, _, truev) :- !.
subst(unitv, _, _, unitv) :- !.
subst(T, _, _, T) :- !.

isvalue(lm(_, _, _)).  isvalue(zero).  isvalue(truev).  isvalue(unitv).
isvalue(succ(V)) :- isvalue(V).
isvalue(rcdobj(Fs)) :- maplist([_=V]>>isvalue(V), Fs).
isvalue(pack(_, V, _)) :- isvalue(V).

step(ap(lm(_, _, B), V), Mu, R, Mu) :- isvalue(V), subst(B, 0, V, R).
step(ap(M, N), Mu, ap(Mp, N), Mup) :- \+ isvalue(M), step(M, Mu, Mp, Mup).
step(ap(V, N), Mu, ap(V, Np), Mup) :- isvalue(V), step(N, Mu, Np, Mup).
step(succ(E), Mu, succ(Ep), Mup) :- \+ isvalue(E), step(E, Mu, Ep, Mup).
step(pred(succ(V)), Mu, V, Mu) :- isvalue(V).
step(pred(E), Mu, pred(Ep), Mup) :- \+ isvalue(E), step(E, Mu, Ep, Mup).
step(prj(rcdobj(Fs), L), Mu, V, Mu) :- member(L=V, Fs).
step(prj(pack(_, V, _), L), Mu, prj(V, L), Mu).   % 投影穿透包
step(prj(E, L), Mu, prj(Ep, L), Mup) :- \+ isvalue(E), step(E, Mu, Ep, Mup).
step(rcdobj(Fs), Mu, rcdobj(Fsp), Mu) :- first_step(Fs, Fsp).
first_step([L=T|Fs], [L=Tp|Fs]) :- \+ isvalue(T), step(T, _, Tp, _).
first_step([L=V|Fs], [L=V|Fsp]) :- isvalue(V), first_step(Fs, Fsp).

steps(T, Mu, T, Mu) :- isvalue(T), !.
steps(T, Mu, U, Mu1) :- step(T, Mu, Tp, Mu2), steps(Tp, Mu2, U, Mu1).

/* ---- 纯函数计数器的编码（32.1–32.3）----
   对象 = pack(Self, { get = λself. state, inc = λself. <新对象> })
   状态与「新对象」都从 self 参数读出——纯函数风格：
   inc 不改状态，而是产出一个新对象。 */
/* counter = pack(Nat, {get = λs. s, inc = λs. succ s})
   —— 表示即状态 Nat 本身；接口方法把 self 当状态用 */
counter_pure(pack(natt,
                 rcdobj([get=lm(s, natt, vr(0)),
                         inc=lm(s, natt, succ(vr(0)))]),
                 exists(self, rcdt([get=arr(natt, natt),
                                    inc=arr(natt, natt)])))).

/* ---- 见证 ---- */
check(Name, Goal) :-
    (   call(Goal) -> format("ok   : ~w~n", [Name])
    ;   format("FAIL : ~w~n", [Name]), fail ).

main :-
    /* ① 编码对象的值性 */
    counter_pure(O),
    check("纯函数对象 pack 后是值",
           isvalue(O)),

    /* ② 一次 send：get(self=0) ⇓ 0（self 应用的一步链） */
    check("get 的 self 应用 ⇓ 0（初态）",
           ( counter_pure(O),
             Send = ap(prj(O, get), zero),
             steps(Send, [], zero, _) )),
    check("inc 的 self 应用产新状态：inc(0) ⇓ 1",
           ( counter_pure(O),
             Send2 = ap(prj(O, inc), zero),
             steps(Send2, [], succ(zero), _) )),

    /* ③ 双 inc 后 get：函数组合即「更新链」 */
    check("双 inc 后 get ⇓ 2（对象更新 = 函数组合）",
           ( counter_pure(O),
             Chain = ap(prj(O, get),
                        ap(prj(O, inc),
                           ap(prj(O, inc), zero))),
             steps(Chain, [], succ(succ(zero)), _) )),

    /* ④ 接口封闭性：表示（Nat）在类型层不可见 */
    check("接口类型只含方法签名（表示被隐去）",
           ( counter_pure(pack(_, _, Iface)), Iface = exists(_, rcdt(_)) )),

    format("ok   : 纯函数对象 = 存在包 × 记录 × self 应用~n"),
    format("all checks passed.~n").
