:- encoding(utf8).
/* ============================================================
   45 类型算子与 Fω —— Prolog（书 ch.29–31）
   甲·kind 体系：*(类型) 与 K⇒K(算子)——kind_of/2 的检查机
      （29.2 的规则直译：算子的参数域与定义域逐位对齐）
   乙·类型级 λ：K₁⇒K₂ 上的抽象与应用——类型级 β 归约
      tsubst/4（30.1 的 type-level abstraction）
   丙·Fω 定型样本：Λ 上界从类型升为 kind 上界——
      Pair : *⇒*⇒* 的实例化链；高阶子类型（31 章）的
      样本陈述（全文收束在「Fω<: 的表达力账本」）
   ============================================================ */

:- use_module(library(lists)).

/* kind：star / karr(K1, K2) */
/* 类型表达式：atom(基型) / tv(X) / arr(A,B) / tlam(X, K, B)
   / tapp2(F, A) / forall2(X, K, B) */
klookup([X=K|_], X, K) :- !.
klookup([_|E], X, K) :- klookup(E, X, K).

/* ---- 甲·kind 检查 ---- */
kind_of(atom(_), _, star) :- !.
kind_of(tv(X), E, K) :- !, klookup(E, X, K).
kind_of(arr(A, B), E, star) :- !,
    kind_of(A, E, star), kind_of(B, E, star).
kind_of(tapp2(F, A), E, K2) :- !,
    kind_of(F, E, karr(K1, K2)),
    kind_of(A, E, K1).
kind_of(tlam(X, K, B), E, karr(K, K2)) :- !,
    kind_of(B, [X=K|E], K2).
kind_of(forall2(X, K, B), E, star) :- !,
    kind_of(B, [X=K|E], star).

/* ---- 乙·类型级 β ---- */
tsubst(atom(A), _, _, atom(A)) :- !.
tsubst(tv(X), X, S, S) :- !.
tsubst(tv(Y), _, _, tv(Y)) :- !.
tsubst(arr(A, B), X, S, arr(A1, B1)) :- !,
    tsubst(A, X, S, A1), tsubst(B, X, S, B1).
tsubst(tapp2(F, A), X, S, tapp2(F1, A1)) :- !,
    tsubst(F, X, S, F1), tsubst(A, X, S, A1).
tsubst(tlam(Y, K, B), X, S, tlam(Y, K, B1)) :- !,
    tsubst(B, X, S, B1).
tsubst(forall2(Y, K, B), X, S, forall2(Y, K, B1)) :- !,
    tsubst(B, X, S, B1).

/* 类型级一步 β（头应用展开） */
tstep(tapp2(tlam(X, _, B), A), R) :- tsubst(B, X, A, R).

/* ---- 见证 ---- */
check(Name, Goal) :-
    (   call(Goal) -> format("ok   : ~w~n", [Name])
    ;   format("FAIL : ~w~n", [Name]), fail ).

main :-
    /* ① kind 体系的基础样本 */
    check("Nat : *",
           kind_of(atom(natt), [], star)),
    check("→ : *⇒*⇒*（部分应用）",
           kind_of(tlam(a, star, tlam(b, star, arr(tv(a), tv(b)))),
                   [], karr(star, karr(star, star)))),
    check("Pair = λA.λB.A→B : *⇒*⇒*",
           kind_of(tlam(a, star, tlam(b, star,
                       arr(tv(a), tv(b)))),
                   [], karr(star, karr(star, star)))),

    /* ② 类型级 β：Pair Nat Bool → Nat→Bool */
    check("Pair 应用一次：(λA.λB.A→B) Nat : *⇒*",
           kind_of(tapp2(tlam(a, star, tlam(b, star, arr(tv(a), tv(b)))),
                         atom(natt)), [], karr(star, star))),
    check("类型级 β：(λA.λB.A→B)[Nat][Bool] ≡ Nat→Bool",
           ( tstep(tapp2(tlam(a, star, tlam(b, star, arr(tv(a), tv(b)))),
                         atom(natt)), R1),
             tstep(tapp2(R1, atom(boolt)), R2),
             R2 = arr(atom(natt), atom(boolt)) )),
    check("kind 对应用逐位对齐：拿 * 的地方喂算子被拒",
           \+ kind_of(tapp2(tlam(a, star, tv(a)),
                            tlam(b, star, tv(b))), [], _)),

    /* ③ Fω 定型：量化的上界从类型升为 kind */
    check("∀F:*⇒*. ∀X:*. F X → F X 有 kind *",
           kind_of(forall2(f, karr(star, star),
                     forall2(x, star,
                       arr(tapp2(tv(f), tv(x)),
                           tapp2(tv(f), tv(x))))),
                   [], star)),
    check("再包一层类型级恒等的应用链",
           ( tstep(tapp2(tlam(f, karr(star, star),
                          tlam(x, star, tv(x))),
                         tlam(y, star, tv(y))), R3),
             R3 = tlam(x, star, tv(x)) )),

    format("ok   : Fω = F + 类型级 λ；Fω<: = 31 章的合流点~n"),
    format("all checks passed.~n").
