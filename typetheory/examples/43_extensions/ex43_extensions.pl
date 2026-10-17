:- encoding(utf8).
/* ============================================================
   37 简单扩展 —— Prolog：fullsimple 的浓缩版（书 ch.11）
   在 λ→（de Bruijn：vr/lm/ap + Unit/unit 基）上加：
     ascribe(t as T) / let / pair+proj / record+proj /
     variant(<l=t> as <li:Ti>)+case / fix
   甲·类型机 typeof/2：图 11.2–11.12 的规则对译
   乙·求值机 step/2：按值调用、从左到右（书 11.6 的元变量纪律）
   丙·导出形式见证：seq(t1;t2) 化简为 (λx:Unit.t2) t1——
     「扩展项直接走」与「化简后走」的一致性（书 11.3.1 的样本）
   ============================================================ */

:- use_module(library(lists)).

/* ---- de Bruijn 移位与代换（21/23 章同款纪律） ---- */
shift(vr(K), _, C, vr(K)) :- K < C, !.
shift(vr(K), D, _, vr(K1)) :- !, K1 is K + D.
shift(lm(A, B), D, C, lm(A1, B1)) :- !,
    shift(A, D, C, A1), C1 is C + 1, shift(B, D, C1, B1).
shift(ap(M, N), D, C, ap(M1, N1)) :- !,
    shift(M, D, C, M1), shift(N, D, C, N1).
shift(pair(A, B), D, C, pair(A1, B1)) :- !,
    shift(A, D, C, A1), shift(B, D, C, B1).
shift(proj1(E), D, C, proj1(E1)) :- !, shift(E, D, C, E1).
shift(proj2(E), D, C, proj2(E1)) :- !, shift(E, D, C, E1).
shift(rcd(Fs), D, C, rcd(Fs1)) :- !, map_shift_f(Fs, D, C, Fs1).
shift(prj(E, L), D, C, prj(E1, L)) :- !, shift(E, D, C, E1).
shift(tg(L, E), D, C, tg(L, E1)) :- !, shift(E, D, C, E1).
shift(tga(L, E, Ts), D, C, tga(L, E1, Ts)) :- !, shift(E, D, C, E1).
shift(case(E, X, B1, Y, B2), D, C, case(E1, X, B11, Y, B21)) :- !,
    shift(E, D, C, E1),
    C1 is C + 1, shift(B1, D, C1, B11), shift(B2, D, C1, B21).
shift(fix(F), D, C, fix(F1)) :- !, shift(F, D, C, F1).
shift(asr(E, T), D, C, asr(E1, T)) :- !, shift(E, D, C, E1).
shift(letin(M, N), D, C, letin(M1, N1)) :- !,
    shift(M, D, C, M1), C1 is C + 1, shift(N, D, C1, N1).
shift(T, _, _, T) :- !.

map_shift_f([], _, _, []).
map_shift_f([L=T|Fs], D, C, [L=T1|Fs1]) :-
    shift(T, D, C, T1), map_shift_f(Fs, D, C, Fs1).

subst(vr(K), J, N, N) :- K =:= J, !.
subst(vr(K), J, _, vr(K1)) :- K > J, !, K1 is K - 1.
subst(vr(K), _, _, vr(K)) :- !.
subst(lm(A, B), J, N, lm(A1, B1)) :- !,
    subst(A, J, N, A1), J1 is J + 1, shift(N, 1, 0, N1), subst(B, J1, N1, B1).
subst(ap(M, N), J, Nm, ap(M1, N1)) :- !,
    subst(M, J, Nm, M1), subst(N, J, Nm, N1).
subst(pair(A, B), J, N, pair(A1, B1)) :- !,
    subst(A, J, N, A1), subst(B, J, N, B1).
subst(proj1(E), J, N, proj1(E1)) :- !, subst(E, J, N, E1).
subst(proj2(E), J, N, proj2(E1)) :- !, subst(E, J, N, E1).
subst(rcd(Fs), J, N, rcd(Fs1)) :- !, map_subst_f(Fs, J, N, Fs1).
subst(prj(E, L), J, N, prj(E1, L)) :- !, subst(E, J, N, E1).
subst(tg(L, E), J, N, tg(L, E1)) :- !, subst(E, J, N, E1).
subst(tga(L, E, Ts), J, N, tga(L, E1, Ts)) :- !, subst(E, J, N, E1).
subst(case(E, X, B1, Y, B2), J, N, case(E1, X, B11, Y, B21)) :- !,
    subst(E, J, N, E1),
    J1 is J + 1, shift(N, 1, 0, N1),
    subst(B1, J1, N1, B11), subst(B2, J1, N1, B21).
subst(fix(F), J, N, fix(F1)) :- !, subst(F, J, N, F1).
subst(asr(E, T), J, N, asr(E1, T)) :- !, subst(E, J, N, E1).
subst(letin(M, B), J, N, letin(M1, B1)) :- !,
    subst(M, J, N, M1), J1 is J + 1, shift(N, 1, 0, N1), subst(B, J1, N1, B1).
subst(T, _, _, T) :- !.

map_subst_f([], _, _, []).
map_subst_f([L=T|Fs], J, N, [L=T1|Fs1]) :-
    subst(T, J, N, T1), map_subst_f(Fs, J, N, Fs1).

/* ---- 值（按值调用：lam/unit/pair 值值/rcd 值值/tg(a) 值）---- */
isvalue(lm(_, _)).
isvalue(unit).
isvalue(pair(V1, V2)) :- isvalue(V1), isvalue(V2).
isvalue(rcd(Fs)) :- maplist([_=V]>>isvalue(V), Fs).
isvalue(tg(_, V)) :- isvalue(V).
isvalue(tga(_, V, _)) :- isvalue(V).

/* ---- 甲·类型机 ---- */
typeof(vr(K), G, T) :- nth0(K, G, T).
typeof(lm(A, B), G, arr(A, T2)) :- typeof(B, [A|G], T2).
typeof(ap(M, N), G, T) :-
    typeof(M, G, arr(A, T)), typeof(N, G, A).
typeof(unit, _, unitt).                         % T-Unit（图 11.2）
typeof(seq(M, N), G, T2) :-                     % T-Seq（外部语言规则）
    typeof(M, G, unitt), typeof(N, G, T2).
typeof(wildcard(B), G, arr(unitt, T)) :-         % 通配符绑定器
    typeof(B, [unitt|G], T).
typeof(asr(E, T), G, T) :- typeof(E, G, T).     % T-Ascribe（图 11.3）
typeof(letin(M, B), G, T2) :-                   % T-Let（图 11.4）
    typeof(M, G, T1), typeof(B, [T1|G], T2).
typeof(pair(M, N), G, prod(A, B)) :- typeof(M, G, A), typeof(N, G, B).
typeof(proj1(E), G, A) :- typeof(E, G, prod(A, _)).
typeof(proj2(E), G, B) :- typeof(E, G, prod(_, B)).
typeof(rcd(Fs), G, rcdt(Ts)) :-
    maplist([L=E, L=T]>>typeof(E, G, T), Fs, Ts).
typeof(prj(E, L), G, T) :-
    typeof(E, G, rcdt(Ts)), member(L=T, Ts).
typeof(tg(L, E), G, vart([(L, T)])) :- typeof(E, G, T).
typeof(tga(L, E, Ts), G, vart(Ts)) :-           % 带注释变式（图 11.11）
    member(L=T, Ts), typeof(E, G, T).
typeof(case(E, X, B1, Y, B2), G, T) :-          % T-Case
    typeof(E, G, vart(Ts)),
    member(X=T1, Ts), member(Y=T2, Ts),
    typeof(B1, [T1|G], T), typeof(B2, [T2|G], T).
typeof(fix(F), G, T) :- typeof(F, G, arr(T, T)).  % T-Fix（图 11.12）

/* ---- 乙·小步求值（按值调用、从左到右）---- */
step(seq(unit, N), N).                                      % E-SeqNext
step(seq(M, N), seq(Mp, N)) :- step(M, Mp).                 % E-Seq
step(ap(lm(_, B), V), R) :- isvalue(V), subst(B, 0, V, R).   % E-AppAbs
step(ap(M, N), ap(Mp, N)) :- step(M, Mp).                    % E-App1
step(ap(V, N), ap(V, Np)) :- isvalue(V), step(N, Np).        % E-App2
step(asr(V, _), V) :- isvalue(V).                            % E-Ascribe
step(asr(E, T), asr(Ep, T)) :- step(E, Ep).                  % E-Ascribe1
step(letin(V, B), R) :- isvalue(V), subst(B, 0, V, R).       % E-LetV
step(letin(M, B), letin(Mp, B)) :- step(M, Mp).              % E-Let
step(pair(M, N), pair(Mp, N)) :- step(M, Mp).                % E-Pair1
step(pair(V, N), pair(V, Np)) :- isvalue(V), step(N, Np).    % E-Pair2
step(proj1(pair(V1, _)), V1) :- isvalue(pair(V1, _)).
step(proj2(pair(_, V2)), V2).                                 % E-PairBeta
step(proj1(E), proj1(Ep)) :- step(E, Ep).                     % E-Proj1
step(proj2(E), proj2(Ep)) :- step(E, Ep).
step(rcd(Fs), rcd(Fsp)) :- step_first_field(Fs, Fsp).         % E-Rcd
step(prj(rcd(Fs), L), V) :-                                   % E-ProjRcd
    isvalue(rcd(Fs)), member(L=V, Fs), isvalue(V).
step(prj(E, L), prj(Ep, L)) :- step(E, Ep).                   % E-Proj
step(tg(L, E), tg(L, Ep)) :- step(E, Ep).                     % E-Variant
step(tga(L, E, Ts), tga(L, Ep, Ts)) :- step(E, Ep).
step(case(tga(L, V, _), X, B1, _, _), R) :-                   % E-CaseVariant
    isvalue(V), L = X, subst(B1, 0, V, R).
step(case(E, X, B1, Y, B2), case(Ep, X, B1, Y, B2)) :- step(E, Ep).
step(fix(lm(A, B)), R) :-                                     % E-FixBeta
    subst(B, 0, fix(lm(A, B)), R).
step(fix(F), fix(Fp)) :- step(F, Fp).                         % E-Fix

step_first_field([L=T|Fs], [L=Tp|Fs]) :- step(T, Tp).
step_first_field([L=V|Fs], [L=V|Fsp]) :-
    isvalue(V), step_first_field(Fs, Fsp).

/* ---- 多步 ---- */
steps(T, T).
steps(T, U) :- step(T, Tp), steps(Tp, U).

/* ---- 丙·导出形式：seq 与通配符的化简器（书 11.3）---- */
desugar(seq(M, N), ap(lm(unitt, N), M)).
desugar(wildcard(B), lm(unitt, B)).

/* ---- 见证 ---- */
check(Name, Goal) :-
    (   call(Goal) -> format("ok   : ~w~n", [Name])
    ;   format("FAIL : ~w~n", [Name]), fail ).

run(T, V) :- steps(T, V), isvalue(V).

main :-
    /* ① Unit 与序列（书 11.2/11.3）：t1;t2 ≡ (λx:Unit.t2) t1 */
    T1 = seq(unit, unit),
    desugar(T1, D1),
    check("t1;t2 与其化简式同类型（导出形式定理的左半）",
           ( typeof(T1, [], unitt), typeof(D1, [], unitt) )),
    check("t1;t2 与其化简式求值一致（右半）",
           ( run(T1, unit), run(D1, unit) )),
    check("序列的求值次序：先 t1 后 t2",
           ( step(seq(unit, vr9), _), fail -> false ; true )),
    check("通配符 λ_:Unit.t 化简掉哑绑定",
           ( desugar(wildcard(vr(0)), lm(unitt, vr(0))),
             typeof(wildcard(vr(0)), [], arr(unitt, unitt)) )),

    /* ② 归属与 let（书 11.4/11.5） */
    check("(λx:Unit.x) unit as Unit ⇓ unit",
           run(asr(ap(lm(unitt, vr(0)), unit), unitt), unit)),
    check("let x=unit in x ⇓ unit（E-LetV 一步）",
           ( step(letin(unit, vr(0)), unit) )),
    check("let 体在扩展上下文中定型（T-Let）",
           typeof(letin(unit, vr(0)), [], unitt)),

    /* ③ 序对与记录（书 11.6/11.8）：左到右求值 + 投影 */
    check("从左到右：{run1,step2}.1 的第一步动在左分量",
           ( step(pair(ap(lm(unitt, vr(0)), unit), unit), P1),
             P1 = pair(unit, unit) )),
    check("{v,v}.1 ⇓ v", run(proj1(pair(unit, pair(unit, unit))), unit)),
    check("{a=unit,b=unit}.b ⇓ unit",
           run(prj(rcd([a=unit, b=unit]), b), unit)),
    check("记录投影类型（T-Proj 查表）",
           typeof(prj(rcd([a=unit, x=lm(unitt, vr(0))]), x), [],
                  arr(unitt, unitt))),

    /* ④ 变式与 case（书 11.10）：注释定和型 + 分支消去 */
    check("裸标记只能取单字段和型",
           typeof(tg(none, unit), [], vart([(none, unitt)]))),
    check("注释标记可取整个和型（图 11.11 的 as 注释）",
           typeof(tga(none, unit, [none=unitt, some=unitt]),
                  [], vart([none=unitt, some=unitt]))),
    check("case 命中左分支（E-CaseVariant 代换）",
           run(case(tga(none, unit, [none=unitt, some=unitt]),
                    none, unit, some, vr(0)), unit)),
    check("case 的两个分支必须同型（T-Case）",
           typeof(case(tga(none, unit, [none=unitt, some=unitt]),
                       none, unit, some, unit), [], unitt)),

    /* ⑤ 一般递归（书 11.11）：fix 的展开与发散 */
    check("fix (λx:Unit.x) 一步展开回自身（不动点）",
           ( step(fix(lm(unitt, vr(0))), R), R = fix(lm(unitt, vr(0))) )),
    check("diverger = λ_:Unit. fix (λx:T.x) 类型合法",
           typeof(lm(unitt, fix(lm(unitt, vr(0)))), [],
                  arr(unitt, unitt))),
    check("letrec 是 fix 的导出形式（书 11.11 末）",
           ( desugar_letrec(letrec(x, unitt, vr(0)), B),
             B = fix(lm(unitt, vr(0))) )),

    format("all checks passed.~n").

/* letrec x:T = t1 in t2 := fix (λx:T. t2) 应用于… 书的定义：
   letrec x:T1=t1 in t2  ≡  let x = fix (λx:T1.t1) in t2       */
desugar_letrec(letrec(_, T, Body), fix(lm(T, Body))).
