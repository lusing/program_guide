:- encoding(utf8).
/* ============================================================
   40 命令式对象与轻量级 Java —— Prolog（书 ch.18/19）
   甲·命令式对象（ch.18）：引用 + 记录 + 序列导出形式合体的
      最小对象——计数器（get/inc 方法闭包共享一个 ref 单元）。
      「对象 = 记录 + 状态 + self」的三步前两步；self 的开放
      递归（18.9–18.10）走 fix 于方法记录，见文末注记。
   乙·轻量级 Java（ch.19 = Featherweight Java, FJ）：
      类表（extends 单继承 + 字段继承 + 方法覆写）、
      new/取字段/调方法/转型；小步语义 R-Field/R-Invk/R-Cast
      与同余规则；定型走类表直传的子类型。
      类型安全在样本程序上机器检定。
   ============================================================ */

:- use_module(library(lists)).

/* ---- de Bruijn 机（44 章款 + 记录 prj + unitv 值） ---- */
shift(vr(K), _, C, vr(K)) :- K < C, !.
shift(vr(K), D, _, vr(K1)) :- !, K1 is K + D.
shift(lm(A, B), D, C, lm(A1, B1)) :- !,
    shift(A, D, C, A1), C1 is C + 1, shift(B, D, C1, B1).
shift(ap(M, N), D, C, ap(M1, N1)) :- !,
    shift(M, D, C, M1), shift(N, D, C, N1).
shift(succ(E), D, C, succ(E1)) :- !, shift(E, D, C, E1).
shift(deref(E), D, C, deref(E1)) :- !, shift(E, D, C, E1).
shift(assign(M, N), D, C, assign(M1, N1)) :- !,
    shift(M, D, C, M1), shift(N, D, C, N1).
shift(rcdobj(Fs), D, C, rcdobj(Fs1)) :- !, map_shift_o(Fs, D, C, Fs1).
shift(prj(E, L), D, C, prj(E1, L)) :- !, shift(E, D, C, E1).
shift(ref(E), D, C, ref(E1)) :- !, shift(E, D, C, E1).
shift(loc(L), _, _, loc(L)) :- !.
shift(zero, _, _, zero) :- !.
shift(unitv, _, _, unitv) :- !.
shift(T, _, _, T) :- !.
map_shift_o([], _, _, []).
map_shift_o([L=T|Fs], D, C, [L=T1|Fs1]) :-
    shift(T, D, C, T1), map_shift_o(Fs, D, C, Fs1).

subst(vr(K), J, N, N) :- K =:= J, !.
subst(vr(K), J, _, vr(K1)) :- K > J, !, K1 is K - 1.
subst(vr(K), _, _, vr(K)) :- !.
subst(lm(A, B), J, N, lm(A1, B1)) :- !,
    subst(A, J, N, A1), J1 is J + 1, shift(N, 1, 0, N1), subst(B, J1, N1, B1).
subst(ap(M, N), J, Nm, ap(M1, N1)) :- !,
    subst(M, J, Nm, M1), subst(N, J, Nm, N1).
subst(succ(E), J, N, succ(E1)) :- !, subst(E, J, N, E1).
subst(deref(E), J, N, deref(E1)) :- !, subst(E, J, N, E1).
subst(assign(M, N), J, Nm, assign(M1, N1)) :- !,
    subst(M, J, Nm, M1), subst(N, J, Nm, N1).
subst(rcdobj(Fs), J, N, rcdobj(Fs1)) :- !, map_subst_o(Fs, J, N, Fs1).
subst(prj(E, L), J, N, prj(E1, L)) :- !, subst(E, J, N, E1).
subst(ref(E), J, N, ref(E1)) :- !, subst(E, J, N, E1).
subst(loc(L), _, _, loc(L)) :- !.
subst(zero, _, _, zero) :- !.
subst(unitv, _, _, unitv) :- !.
subst(T, _, _, T) :- !.
map_subst_o([], _, _, []).
map_subst_o([L=T|Fs], J, N, [L=T1|Fs1]) :-
    subst(T, J, N, T1), map_subst_o(Fs, J, N, Fs1).

isvalue(lm(_, _)).  isvalue(zero).  isvalue(loc(_)).  isvalue(unitv).
isvalue(succ(V)) :- isvalue(V).
isvalue(rcdobj(Fs)) :- maplist([_=V]>>isvalue(V), Fs).

mu_get([L-V|_], L, V) :- !.
mu_get([_|Mu], L, V) :- mu_get(Mu, L, V).

step(ap(lm(_, B), V), Mu, R, Mu) :- isvalue(V), subst(B, 0, V, R).
step(ap(M, N), Mu, ap(Mp, N), Mup) :-
    \+ isvalue(M), step(M, Mu, Mp, Mup).
step(ap(V, N), Mu, ap(V, Np), Mup) :-
    isvalue(V), step(N, Mu, Np, Mup).
step(succ(E), Mu, succ(Ep), Mup) :- step(E, Mu, Ep, Mup).
step(ref(V), Mu, loc(L), [L-V|Mu]) :-          % E-RefV
    isvalue(V), length(Mu, L).
step(ref(E), Mu, ref(Ep), Mup) :- step(E, Mu, Ep, Mup).
step(deref(loc(L)), Mu, V, Mu) :- mu_get(Mu, L, V).
step(deref(E), Mu, deref(Ep), Mup) :- step(E, Mu, Ep, Mup).
step(assign(loc(L), V), Mu, unitv, Mu1) :-
    isvalue(V),
    (  select(L-_, Mu, Rest) -> Mu1 = [L-V|Rest]
    ;  Mu1 = [L-V|Mu] ).
step(assign(M, N), Mu, assign(Mp, N), Mup) :-
    \+ isvalue(M), step(M, Mu, Mp, Mup).
step(assign(V, N), Mu, assign(V, Np), Mup) :-
    isvalue(V), step(N, Mu, Np, Mup).
step(prj(rcdobj(Fs), L), Mu, V, Mu) :-    % E-ProjRcd（43 章同款）
    isvalue(rcdobj(Fs)), member(L=V, Fs).
step(prj(E, L), Mu, prj(Ep, L), Mup) :- step(E, Mu, Ep, Mup).

steps(T, Mu, T, Mu) :- isvalue(T), !.
steps(T, Mu, U, Mu1) :- step(T, Mu, Tp, Mu2), steps(Tp, Mu2, U, Mu1).

/* ---- 甲·计数器对象（书 18.2）----
   ((λr:Ref Nat.
       (λo:{get,inc}. o.inc(); o.inc(); o.get())
         {get = λ_. !r, inc = λ_. r := succ(!r)}))
    (ref 0))
   de Bruijn：λr 内 r=0；记录方法闭包里的 r=vr(0)——它们在
   λo 之下构造，故方法体里 r=vr(1)；序列的 λ_ 逐层把 o 推深 */
counter_prog(P) :-
    P = ap(lm(reft(natt), ap(lm(rcdt([get=arr(unitt,natt), inc=arr(unitt,unitt)]), Seq),
                             rcdobj([get=Get, inc=Inc]))),
            ref(zero)),
    Get = lm(unitt, deref(vr(1))),
    Inc = lm(unitt, assign(vr(1), succ(deref(vr(1))))),
    /* λo 下：o=vr(0)；三层序列/λ_ 逐层 +1 */
    Inc1 = ap(prj(vr(0), inc), unitv),
    Inc2 = ap(prj(vr(1), inc), unitv),
    Get2 = ap(prj(vr(2), get), unitv),
    Seq  = ap(lm(unitt, ap(lm(unitt, Get2), Inc2)), Inc1).

/* ---- 乙·FJ ---- */
:- dynamic classtab/1.
load_fj :-
    retractall(classtab(_)),
    assertz(classtab(class(object, none, [], []))),
    assertz(classtab(class(a, object, [], []))),
    assertz(classtab(class(b, a, [], []))),
    assertz(classtab(class(pair, object,
                          [fst-a, snd-a],
                          [m(setfst, a, newfst, a, v(newfst))]))).

superof(C, S) :- classtab(class(C, S, _, _)), S \= none.
fields(C, Fs) :- classtab(class(C, _, Fs, _)), !.
fields(C, Fs) :-
    classtab(class(C, S, CFs, _)), S \= none,
    fields(S, SFs), append(SFs, CFs, Fs).
methods(C, Ms) :-
    classtab(class(C, _, _, CMs)),
    (  CMs = [] -> Ms = []
    ;  CMs \= [] -> CMs = CMs ),
    classtab(class(C, S, _, _)),
    (  S = none -> Ms = CMs
    ;  methods(S, SMs), override_merge(CMs, SMs, Ms) ).
override_merge([], SMs, SMs).
override_merge([m(N, P, X, R, B)|CMs], SMs, Out) :-
    (  select(m(N, _, _, _, _), SMs, Rest)
    -> override_merge(CMs, [m(N, P, X, R, B)|Rest], Out)
    ;  override_merge(CMs, [m(N, P, X, R, B)|SMs], Out) ).

subcl(C, C).
subcl(C, D) :- superof(C, P), subcl(P, D).

fj_value(v(_)).
fj_value(new(C, Args)) :- atom(C), maplist(fj_value, Args).

zipf([], [], []).
zipf([L-T|Fs], [A|As], [(L-T)-A|Zs]) :- zipf(Fs, As, Zs).

fj_step(field(new(C, Args), L), Mu, V, Mu) :-    % R-Field
    fields(C, Fs), zipf(Fs, Args, Zs),
    member((L-_)-V, Zs).
fj_step(call(new(C, _), M, A), Mu, R, Mu) :-     % R-Invk
    fj_value(A),
    methods(C, Ms), member(m(M, _, X, _, B), Ms),
    subst_fj(B, X, A, R).
fj_step(field(T, L), Mu, field(Tp, L), Mu1) :-   % RC-Field
    \+ fj_value(T), fj_step(T, Mu, Tp, Mu1).
fj_step(call(T, M, A), Mu, call(Tp, M, A), Mu1) :-
    \+ fj_value(T), fj_step(T, Mu, Tp, Mu1).     % RC-Recv
fj_step(call(V, M, A), Mu, call(V, M, Ap), Mu1) :-
    fj_value(V), \+ fj_value(A), fj_step(A, Mu, Ap, Mu1). % RC-Arg
fj_step(cast(C, new(D, Args)), Mu, new(D, Args), Mu) :-
    subcl(D, C).                                  % R-Cast
fj_step(cast(C, T), Mu, cast(C, Tp), Mu1) :-
    \+ fj_value(T), fj_step(T, Mu, Tp, Mu1).      % RC-Cast-Frame

subst_fj(v(X), X, A, A) :- !.
subst_fj(v(Y), _, _, v(Y)) :- !.
subst_fj(field(T, L), X, A, field(T1, L)) :- !, subst_fj(T, X, A, T1).
subst_fj(call(T, M, Arg), X, A, call(T1, M, Arg1)) :- !,
    subst_fj(T, X, A, T1), subst_fj(Arg, X, A, Arg1).
subst_fj(new(C, Args), X, A, new(C, Args1)) :- !,
    maplist([T,T1]>>subst_fj(T, X, A, T1), Args, Args1).
subst_fj(cast(C, T), X, A, cast(C, T1)) :- !, subst_fj(T, X, A, T1).
subst_fj(T, _, _, T) :- !.

fj_type(v(X), G, T) :- member(X-T, G).
fj_type(field(T, L), G, FT) :-
    fj_type(T, G, C), atom(C), fields(C, Fs), member(L-FT, Fs).
fj_type(call(T, M, A), G, RT) :-
    fj_type(T, G, C), atom(C), methods(C, Ms),
    member(m(M, PT, _, RT, _), Ms),
    fj_type(A, G, AT), subcl(AT, PT).
fj_type(new(C, Args), G, C) :-
    atom(C), fields(C, Fs), zipf(Fs, Args, Zs),
    forall(member((_-T)-A, Zs), (fj_type(A, G, AT), subcl(AT, T))).
fj_type(cast(C, T), G, C) :- fj_type(T, G, _).

fj_steps(T, Mu, T, Mu) :- fj_value(T), !.
fj_steps(T, Mu, U, Mu1) :- fj_step(T, Mu, Tp, Mu2), fj_steps(Tp, Mu2, U, Mu1).

/* ---- 见证 ---- */
check(Name, Goal) :-
    (   call(Goal) -> format("ok   : ~w~n", [Name])
    ;   format("FAIL : ~w~n", [Name]), fail ).

main :-
    /* 甲·命令式对象 */
    check("计数器对象：两次 inc 后 get ⇓ 2（书 18.2 的共享状态）",
           ( counter_prog(P), steps(P, [], succ(succ(zero)), _) )),
    check("一次 inc 后 get ⇓ 1",
           ( counter_once(P1), steps(P1, [], succ(zero), _) )),

    /* 乙·FJ */
    load_fj,
    check("类表子类型直传：B <: A <: Object",
           ( subcl(b, a), subcl(a, object), subcl(b, object) )),
    check("字段继承 + 覆写合并的类表完备",
           ( fields(pair, [fst-a, snd-a]),
             methods(pair, [m(setfst, a, newfst, a, v(newfst))]) )),
    check("字段取用：new Pair(a,a).fst ⇓ a（R-Field）",
           fj_steps(field(new(pair, [v(x1), v(x2)]), fst), [], v(x1), _)),
    check("方法调用：new Pair(..).setfst(new B()) ⇓ new B()（R-Invk）",
           fj_steps(call(new(pair, [v(x1), v(x2)]), setfst, new(b, [])),
                    [], new(b, []), _)),
    check("向上转型成功：((A) new B()) ⇓ new B()（R-Cast）",
           fj_steps(cast(a, new(b, [])), [], new(b, []), _)),
    check("定型：new Pair(new B, new A) : Pair（子类型进参数位）",
           fj_type(new(pair, [new(b, []), new(a, [])]), [], pair)),
    check("定型：Pair(..).fst : A——B 的字段值升到 A",
           fj_type(field(new(pair, [new(b, []), new(a, [])]), fst), [], a)),
    check("良型程序要么值要么走一步（FJ 版进展的样本面）",
           ( T = cast(a, new(b, [])),
             fj_type(T, [], _),
             ( fj_value(T) ; fj_step(T, [], _, _) ) )),
    format("all checks passed.~n").

counter_once(P) :-
    P = ap(lm(reft(natt), ap(lm(rcdt([get=arr(unitt,natt), inc=arr(unitt,unitt)]), Seq),
                             rcdobj([get=Get, inc=Inc]))),
            ref(zero)),
    Get = lm(unitt, deref(vr(1))),
    Inc = lm(unitt, assign(vr(1), succ(deref(vr(1))))),
    Inc1 = ap(prj(vr(0), inc), unitv),
    Get1 = ap(prj(vr(1), get), unitv),
    Seq  = ap(lm(unitt, Get1), Inc1).
