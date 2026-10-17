:- encoding(utf8).
/* ============================================================
   38 引用与异常 —— Prolog：带存储的抽象机（书 ch.13/14）
   甲·存储机：状态是 (t | μ)，单步 step/4：t|μ → t'|μ'
      （图 13.1 全部规则：E-App×3 + E-Ref/RefV + E-Deref/DerefLoc
       + E-Assign×3；位置 l 用自然数，存储 μ 用 l-V 对的列表）
   乙·存储类型机 typeof/4：Γ|Σ ⊢ t : T（T-Loc 查 Σ 表）
   丙·异常（图 14.1/14.2/14.3）：error 沿应用栈上浮、try 捕获、
      带值异常 error(v)
   验证面：书 13.1 的自增/别名程序跑通；preservation 13.5.3
   的机器面（求值全程良型、存储一致、Σ 只增不减）；
   异常上浮/捕获样本；error 的类型任意性（T-Error 破坏惟一性）
   ============================================================ */

:- use_module(library(lists)).

/* ---- de Bruijn 移位/代换（21/23/37 章同款） ---- */
shift(vr(K), _, C, vr(K)) :- K < C, !.
shift(vr(K), D, _, vr(K1)) :- !, K1 is K + D.
shift(lm(A, B), D, C, lm(A1, B1)) :- !,
    shift(A, D, C, A1), C1 is C + 1, shift(B, D, C1, B1).
shift(ap(M, N), D, C, ap(M1, N1)) :- !,
    shift(M, D, C, M1), shift(N, D, C, N1).
shift(deref(E), D, C, deref(E1)) :- !, shift(E, D, C, E1).
shift(succ(E), D, C, succ(E1)) :- !, shift(E, D, C, E1).
shift(assign(M, N), D, C, assign(M1, N1)) :- !,
    shift(M, D, C, M1), shift(N, D, C, N1).
shift(ref(E), D, C, ref(E1)) :- !, shift(E, D, C, E1).
shift(loc(L), _, _, loc(L)) :- !.
shift(unit, _, _, unit) :- !.
shift(tryw(B, H), D, C, tryw(B1, H1)) :- !,
    C1 is C + 1, shift(B, D, C1, B1), shift(H, D, C1, H1).
shift(err, _, _, err) :- !.
shift(error(V), D, C, error(V1)) :- !, shift(V, D, C, V1).
shift(T, _, _, T) :- !.

subst(vr(K), J, N, N) :- K =:= J, !.
subst(vr(K), J, _, vr(K1)) :- K > J, !, K1 is K - 1.
subst(vr(K), _, _, vr(K)) :- !.
subst(lm(A, B), J, N, lm(A1, B1)) :- !,
    subst(A, J, N, A1), J1 is J + 1, shift(N, 1, 0, N1), subst(B, J1, N1, B1).
subst(ap(M, N), J, Nm, ap(M1, N1)) :- !,
    subst(M, J, Nm, M1), subst(N, J, Nm, N1).
subst(deref(E), J, N, deref(E1)) :- !, subst(E, J, N, E1).
subst(succ(E), J, N, succ(E1)) :- !, subst(E, J, N, E1).
subst(assign(M, N), J, Nm, assign(M1, N1)) :- !,
    subst(M, J, Nm, M1), subst(N, J, Nm, N1).
subst(ref(E), J, N, ref(E1)) :- !, subst(E, J, N, E1).
subst(loc(L), _, _, loc(L)) :- !.
subst(unit, _, _, unit) :- !.
subst(tryw(B, H), J, N, tryw(B1, H1)) :- !,
    J1 is J + 1, shift(N, 1, 0, N1), subst(B, J1, N1, B1), subst(H, J1, N1, H1).
subst(err, _, _, err) :- !.
subst(error(V), J, N, error(V1)) :- !, subst(V, J, N, V1).
subst(T, _, _, T) :- !.

/* ---- 值 ---- */
isvalue(lm(_, _)).  isvalue(unit).  isvalue(loc(_)).
isvalue(zero).  isvalue(succ(V)) :- isvalue(V).

/* ---- 存储：μ 用 l-V 对的列表；Σ 用 l-T 对的列表 ---- */
new_loc(Mu, L) :- length(Mu, L).            % 新位置 = 现有单元数
mu_get([L-V|_], L, V) :- !.
mu_get([_|Mu], L, V) :- mu_get(Mu, L, V).
mu_set(Mu, L, V, [L-V|Rest]) :- select(L-_, Mu, Rest), !.
mu_set(Mu, L, V, [L-V|Mu]).
sigma_get([L-T|_], L, T) :- !.
sigma_get([_|Ss], L, T) :- sigma_get(Ss, L, T).

/* ---- 甲·带存储的小步：step(t, Mu, Tp, Mup) ---- */
step(ap(lm(_, B), V), Mu, R, Mu) :-                        % E-AppAbs
    isvalue(V), subst(B, 0, V, R).
step(ap(M, N), Mu, ap(Mp, N), Mup) :-                      % E-App1
    \+ M = err, \+ M = error(_), \+ isvalue(M),
    step(M, Mu, Mp, Mup).
step(ap(V, N), Mu, ap(V, Np), Mup) :-                      % E-App2
    isvalue(V), step(N, Mu, Np, Mup).
step(ap(err, _), Mu, err, Mu).                             % E-AppErr1
step(ap(V, err), Mu, err, Mu) :- isvalue(V).               % E-AppErr2
step(ap(error(_), _), Mu, err, Mu).                        % 带值版上浮
step(ap(V, error(_)), Mu, err, Mu) :- isvalue(V).
step(succ(E), Mu, succ(Ep), Mup) :- step(E, Mu, Ep, Mup).  % E-Succ 同余
step(ref(V), Mu, loc(L), [L-V|Mu]) :-                      % E-RefV
    isvalue(V), new_loc(Mu, L).
step(ref(E), Mu, ref(Ep), Mup) :- step(E, Mu, Ep, Mup).    % E-Ref
step(deref(loc(L)), Mu, V, Mu) :- mu_get(Mu, L, V).        % E-DerefLoc
step(deref(E), Mu, deref(Ep), Mup) :- step(E, Mu, Ep, Mup). % E-Deref
step(assign(loc(L), V), Mu, unit, Mu1) :-                  % E-Assign
    isvalue(V), mu_set(Mu, L, V, Mu1).
step(assign(M, N), Mu, assign(Mp, N), Mup) :-              % E-Assign1
    \+ M = err, \+ M = error(_), \+ isvalue(M),
    step(M, Mu, Mp, Mup).
step(assign(V, N), Mu, assign(V, Np), Mup) :-              % E-Assign2
    isvalue(V), step(N, Mu, Np, Mup).
step(tryw(V, _), Mu, V, Mu) :- isvalue(V).                 % E-TryV
step(tryw(err, H), Mu, H, Mu).                             % E-TryError
step(tryw(error(V), H), Mu, ap(H, V), Mu) :- isvalue(H).    % E-TryErrorV
step(tryw(B, H), Mu, tryw(Bp, H), Mup) :-                  % E-Try
    step(B, Mu, Bp, Mup).

/* ---- 多步：终态 = 值或 err ---- */
steps(T, Mu, T, Mu) :- ( isvalue(T) ; T = err ), !.
steps(T, Mu, U, Mu1) :- step(T, Mu, Tp, Mu2), steps(Tp, Mu2, U, Mu1).

/* ---- 乙·类型机：typeof(t, Sig, G, T) ---- */
typeof(vr(K), _, G, T) :- nth0(K, G, T).
typeof(lm(A, B), Sig, G, arr(A, T2)) :- typeof(B, Sig, [A|G], T2).
typeof(ap(M, N), Sig, G, T) :-
    typeof(M, Sig, G, arr(A, T)), typeof(N, Sig, G, A).
typeof(unit, _, _, unitt).
typeof(zero, _, _, natt).
typeof(succ(E), Sig, G, natt) :- typeof(E, Sig, G, natt).
typeof(ref(E), Sig, G, reft(T)) :- typeof(E, Sig, G, T).      % T-Ref
typeof(deref(E), Sig, G, T) :- typeof(E, Sig, G, reft(T)).   % T-Deref
typeof(assign(M, N), Sig, G, unitt) :-                        % T-Assign
    typeof(M, Sig, G, reft(T)), typeof(N, Sig, G, T).
typeof(loc(L), Sig, _, reft(T)) :- sigma_get(Sig, L, T).      % T-Loc
typeof(err, _, _, _).                                         % T-Error
typeof(error(V), Sig, G, _) :- typeof(V, Sig, G, _).
typeof(tryw(B, H), Sig, G, T) :-                              % T-Try
    typeof(B, Sig, G, T), typeof(H, Sig, G, T).

/* ---- 存储一致性（13.5.1）：Γ|Σ ⊢ μ : Σ ---- */
store_ok([], _).
store_ok([L-V|Mu], Sig) :-
    sigma_get(Sig, L, T), typeof(V, Sig, [], T), store_ok(Mu, Sig).

/* Σ 只增不减（子集） */
sigma_le([], _).
sigma_le([L-T|Ss], Sig) :- sigma_get(Sig, L, T), sigma_le(Ss, Sig).

/* ---- 见证 ---- */
check(Name, Goal) :-
    (   call(Goal) -> format("ok   : ~w~n", [Name])
    ;   format("FAIL : ~w~n", [Name]), fail ).

run(T, V) :- steps(T, [], V, _).

/* 序列导出形式（37 章）：t1;t2 = (λ_:Unit.t2) t1 */
seqc(A, B, ap(lm(unitt, B), A)).

/* 自增程序：((λr:Ref Nat. r:=succ(!r); !r) (ref 0)) ⇓ 1 */
prog_incr(ap(lm(reft(natt), Seq), ref(zero))) :-
    seqc(assign(vr(0), succ(deref(vr(0)))), deref(vr(1)), Seq).

/* 别名程序：((λr. ((λs. s:=2; !r) r)) (ref 0)) ⇓ 2
   内层 !r 在两个绑定器下是 vr(2) */
prog_alias(ap(lm(reft(natt), Outer), ref(zero))) :-
    seqc(assign(vr(0), succ(succ(zero))), deref(vr(2)), Inner),
    Outer = ap(lm(reft(natt), Inner), vr(0)).

/* 计数器程序：N 次自增后读——每层 seq 的 λ_ 绑定器把 r 的
   de Bruijn 指数 +1，故逐层带深度 K */
prog_count(N, ap(lm(reft(natt), Body), ref(zero))) :-
    incr_n(N, 0, Body).
incr_n(0, K, deref(vr(K))).
incr_n(N, K, ap(lm(unitt, Rest), assign(vr(K), succ(deref(vr(K)))))) :-
    N >= 1, M is N - 1, K1 is K + 1, incr_n(M, K1, Rest).

/* preservation 机器检：逐步核 typeof + store_ok + Σ 单调 */
steps_safe(T, Mu, Sig) :-
    (   step(T, Mu, Tp, Mup) ->
        typeof(T, Sig, [], _),
        (   typeof(Tp, Sig, [], _) -> Sigp = Sig
        ;   extend_sigma(Mu, Mup, Sig, Sigp),
            typeof(Tp, Sigp, [], _) ),
        store_ok(Mup, Sigp),
        sigma_le(Sig, Sigp),
        steps_safe(Tp, Mup, Sigp)
    ;   true ).

extend_sigma(Mu, Mup, Sig, Sigp) :-
    findall(L-T, (member(L-V, Mup), \+ member(L-_, Mu),
                  typeof(V, Sig, [], T)), New),
    append(Sig, New, Sigp).

main :-
    /* ① 基本三操作（书 13.1）：ref/!/:= */
    check("((λr:Ref Nat. !r) (ref 0)) ⇓ 0",
           run(ap(lm(reft(natt), deref(vr(0))), ref(zero)), zero)),
    check("自增：r:=succ(!r); !r ⇓ 1（序列的导出形式）",
           ( prog_incr(P1), run(P1, succ(zero)) )),

    /* ② 别名（书 13.1）：s = r 后 s:=2 经 !r 可见 */
    check("别名：let s=r in s:=2; !r ⇓ 2",
           ( prog_alias(P2), run(P2, succ(succ(zero))) )),

    /* ③ 计数器（书 13.1 共享状态）：三次自增后读得 3 */
    check("计数器：三次自增后 ⇓ 3",
           ( prog_count(3, P3), run(P3, succ(succ(succ(zero)))) )),

    /* ④ preservation 的机器面（13.5.3）：求值全程良型、
          存储一致、Σ 只增不减 */
    check("自增程序全程安全（Σ 单调扩展）",
           ( prog_incr(Q1), steps_safe(Q1, [], []) )),
    check("计数器程序全程安全",
           ( prog_count(4, Q2), steps_safe(Q2, [], []) )),

    /* ⑤ 异常（书 14.1/14.2/14.3） */
    check("error 上浮：(λx:Nat.x) error ⇓ err",
           run(ap(lm(natt, vr(0)), err), err)),
    check("左端先求值：succ((λx.x) error) 不会部分求值",
           run(ap(lm(natt, succ(vr(0))), err), err)),
    check("try 捕获：try error with 0 ⇓ 0",
           run(tryw(err, zero), zero)),
    check("try 值路：try 1 with 0 ⇓ 1",
           run(tryw(succ(zero), zero), succ(zero))),
    check("error 的类型任意（T-Error 破坏惟一性）",
           ( typeof(err, [], [], natt), typeof(err, [], [], boolt),
             typeof(err, [], [], arr(natt, natt)) )),
    check("带值异常：try error(1) with (λx.succ x) ⇓ 2（图 14.3）",
           run(tryw(error(succ(zero)), lm(natt, succ(vr(0)))),
               succ(succ(zero)))),

    format("all checks passed.~n").
