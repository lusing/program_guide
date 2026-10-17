:- encoding(utf8).
/* ============================================================
   36 操作语义 —— Prolog：NB 语言的三台机器（书 ch.3/4/8）
   甲·小步机 step/2：图 3.1+3.2 全部 9 条规则的本体化身
   乙·大步机 evalv/2：练习 3.5.17 的 B- 规则（t ⇓ v）
   丙·类型机 typeof/2：图 8.1+8.2 的 8 条规则
   验证面：确定性穷举（每项至多一步去处）、小步*=大步的
   一致性（练习 3.5.17 的机器版）、良类型项不受阻且类型在
   求值下不变（progress+preservation 的穷举见证）、受阻项
   必被类型挡下、保守性反例（书 8.1）
   ============================================================ */

:- use_module(library(lists)).

/* ---- 项的语法（Prolog 项即抽象语法）----
   true / false / if(T1,T2,T3) / zero / succ(T) / pred(T) / iszero(T) */

/* ---- 数值与值 ---- */
nv(zero).
nv(succ(T)) :- nv(T).

value(true).  value(false).  value(T) :- nv(T).

/* ---- 甲·小步：9 条规则逐条对译 ---- */
step(if(true,  T2, _), T2).                     % E-IfTrue
step(if(false, _, T3), T3).                     % E-IfFalse
step(if(T1, T2, T3), if(T1p, T2, T3)) :-        % E-If
    step(T1, T1p).
step(succ(T), succ(Tp)) :- step(T, Tp).         % E-Succ
step(pred(zero), zero).                         % E-PredZero
step(pred(succ(V)), V) :- nv(V).                % E-PredSucc
step(pred(T), pred(Tp)) :- step(T, Tp).         % E-Pred
step(iszero(zero), true).                       % E-IsZeroZero
step(iszero(succ(V)), false) :- nv(V).          % E-IsZeroSucc
step(iszero(T), iszero(Tp)) :- step(T, Tp).     % E-IsZero

/* ---- 多步（自反传递闭包）与受阻 ---- */
steps(T, T).
steps(T, U) :- step(T, Tp), steps(Tp, U).

normal_form(T) :- \+ step(T, _).
stuck(T) :- normal_form(T), \+ value(T).

/* ---- 乙·大步：t ⇓ v（练习 3.5.17 的规则组）---- */
evalv(V, V) :- value(V).                        % B-Value
evalv(if(T1, T2, _), V) :- evalv(T1, true), evalv(T2, V).
evalv(if(T1, _, T3), V) :- evalv(T1, false), evalv(T3, V).
evalv(succ(T), succ(V)) :- evalv(T, V), nv(V).
evalv(pred(T), zero) :- evalv(T, zero).
evalv(pred(T), NV) :- evalv(T, succ(NV)), nv(NV).
evalv(iszero(T), true)  :- evalv(T, zero).
evalv(iszero(T), false) :- evalv(T, succ(NV)), nv(NV).

/* ---- 丙·类型：8 条规则 ---- */
typeof(true,  bool).
typeof(false, bool).
typeof(if(T1, T2, T3), T) :-
    typeof(T1, bool), typeof(T2, T), typeof(T3, T).
typeof(zero, nat).
typeof(succ(T), nat)    :- typeof(T, nat).
typeof(pred(T), nat)    :- typeof(T, nat).
typeof(iszero(T), bool) :- typeof(T, nat).

/* ---- 见证工具 ---- */
check(Name, Goal) :-
    (   call(Goal) -> format("ok   : ~w~n", [Name])
    ;   format("FAIL : ~w~n", [Name]), fail ).

/* 小项枚举：term(N, T) 生成大小恰为 N 的项（穷举验证的燃料） */
term(1, true).  term(1, false). term(1, zero).
term(N, succ(T))    :- N > 1, M is N - 1, term(M, T).
term(N, pred(T))    :- N > 1, M is N - 1, term(M, T).
term(N, iszero(T))  :- N > 1, M is N - 1, term(M, T).
term(N, if(A, B, C)) :-
    N > 3,
    K0 is N - 3, between(1, K0, K),
    L0 is N - 2 - K, between(1, L0, L),
    M is N - 1 - K - L, M >= 1,
    term(K, A), term(L, B), term(M, C).

terms_upto(N, Ts) :-
    findall(T, (between(1, N, K), term(K, T)), Ts0),
    sort(Ts0, Ts).

/* ---- 主检定 ---- */
main :-
    /* ① 书 3.2 的例子：两台机器给出同一答案 */
    check("if false then 0 else 1 ⇓ 1",
           evalv(if(false, zero, succ(zero)), succ(zero))),
    check("iszero (pred (succ 0)) ⇓ true",
           evalv(iszero(pred(succ(zero))), true)),
    check("pred (succ (pred 0)) --→ pred (succ 0)",
           step(pred(succ(pred(zero))), pred(succ(zero)))),

    /* ② 受阻目录（书 3.5.15） */
    check("succ true 受阻", stuck(succ(true))),
    check("pred false 受阻", stuck(pred(false))),
    check("if zero then … 受阻", stuck(if(zero, zero, zero))),

    /* ③ 确定性穷举：每个枚举项的「一步去处」至多一个（书 3.5.4） */
    terms_upto(5, Ts1), length(Ts1, Cnt1),
    forall((member(T, Ts1), findall(U, step(T, U), Us)),
           ( length(Us, NUs), NUs =< 1 )),
    format("ok   : 5 层内 ~w 项全部至多一步去处（3.5.4 确定性）~n", [Cnt1]),

    /* ④ 小步* = 大步（练习 3.5.17 的一致性，5 层内全枚举） */
    forall((member(T, Ts1), steps(T, V), value(V)),
           evalv(T, V)),
    forall(member(T, Ts1),
           ( evalv(T, V) -> (value(V), steps(T, V)) ; true )),
    format("ok   : 5 层内小步*与大步完全一致（3.5.17）~n"),

    /* ⑤ progress+preservation 的穷举见证（书 8.3） */
    findall(T, (member(T, Ts1), typeof(T, _)), Typed), length(Typed, CTyped),
    forall((member(T, Typed), steps(T, U)),
           ( \+ stuck(U),
             ( typeof(T, Ty) -> typeof(U, Ty) ; true ) )),
    format("ok   : ~w 个良类型项的安全求值全部无受阻且同型~n", [CTyped]),

    /* ⑥ 边界两面：受阻项被挡下；保守性反例（书 8.1） */
    check("succ true 不可类型化", \+ typeof(succ(true), _)),
    check("保守性：if true then 0 else false 可求值但无类型",
           ( steps(if(true, zero, false), zero),
             \+ typeof(if(true, zero, false), _) )),

    format("all checks passed.~n").
