:- encoding(utf8).
/* ============================================================
   11 居留项计数 —— Prolog 主场（Hindley ch.8 / Ben-Yelles 1979）
   甲·8B 搜索结构（长正规居留项形状注记）：
     τ = τ1→…→τm→e 时，长正规居留项 = λx1…xm. v A1…An，其中
     头变量 v 的类型尾 = e（尾匹配），参数个数 = v 的前提数
   乙·8D5 计数判定：D(τ) = |τ| × ‖τ‖（大小 × 相异原子数）
     Case I   dterms(≤D) = ∅     → # = 0
     Case II  有成员深度 > ‖τ‖    → # = ∞（拉伸引理 8D2）
     Case III 其余                 → # 有限（收缩引理 8D3）
   项用 de Bruijn（vr/lm/ap）：α-相同 = 字面相同，sort 即去重。
   逐层加燃料 + 早退（撞到深度 > ‖τ‖ 立即判 ∞），防分支爆炸。
   ============================================================ */

:- use_module(library(lists)).

/* ---- 类型解剖：premises(+T, -Ps, -Tail) ---- */
premises(arr(A, B), [A|Ps], T) :- !, premises(B, Ps, T).
premises(X, [], X).

/* ---- 度量：|τ|（结点数）与 ‖τ‖（相异原子数） ---- */
ty_size(arr(A, B), N) :- !, ty_size(A, NA), ty_size(B, NB), N is NA + NB + 1.
ty_size(X, 1) :- atomic(X).

ty_atoms(arr(A, B), S) :- !, ty_atoms(A, SA), ty_atoms(B, SB), union(SA, SB, S).
ty_atoms(X, [X]) :- atomic(X).

big_d(T, D) :- ty_size(T, N), ty_atoms(T, As), length(As, K), D is N * K.

/* ---- 8A6 深度 ---- */
depth(lm(B), D) :- !, depth(B, D).
depth(ap(F, A), D) :- !, depth(F, DF), depth(A, DA), D is max(DF, DA) + 1.
depth(vr(_), 0).

/* ---- 长正规居留项搜索（燃料 = 深度界；λ 层也计燃料——机器口径
       比书口径略紧，本批类型不受影响） ---- */
% 复合目标：λ-引入
longnf(Ctx, arr(A, B), lm(Body), F) :-
    F > 0, F1 is F - 1,
    longnf([A|Ctx], B, Body, F1).
% 原子目标：尾匹配头变量 + 满参数脊（8B2 的 (iv)(v)）
longnf(Ctx, E, Term, F) :-
    atomic(E), F > 0, F1 is F - 1,
    nth0(I, Ctx, Sig),
    premises(Sig, Qs, Tail),
    Tail == E,
    spine(Ctx, Qs, Args, F1),
    chain_app(vr(I), Args, Term).

spine(_, [], [], _).
spine(Ctx, [Q|Qs], [A|As], F) :-
    longnf(Ctx, Q, A, F),
    spine(Ctx, Qs, As, F).

chain_app(H, [], H).
chain_app(H, [A|As], T) :- chain_app(ap(H, A), As, T).

/* ---- 逐层枚举 + 早退（8D5 的机器版） ---- */
% count(+Tau, -Answer)：Answer = zero | finite(N) | infinite
count(Tau, Answer) :-
    big_d(Tau, DMax), ty_atoms(Tau, As), length(As, K),
    climb(Tau, 0, DMax, K, [], Ts),
    ( Ts == [] -> Answer = zero
    ; maplist(depth, Ts, Ds), max_list(Ds, Md),
      ( Md > K -> Answer = infinite
      ; length(Ts, N), Answer = finite(N) ) ).

climb(_, F, DMax, _, Acc, Out) :-
    F > DMax, !, sort(Acc, Out).
climb(Tau, F, DMax, K, Acc, Out) :-
    findall(T, longnf([], Tau, T, F), Ts),
    append(Acc, Ts, Acc2), sort(Acc2, Acc3),
    ( Ts == [] -> Md = 0 ; maplist(depth, Ts, Ds), max_list(Ds, Md) ),
    ( Md > K -> !, Acc3 = Out                    % 早退：撞到深成员
    ; F1 is F + 1, climb(Tau, F1, DMax, K, Acc3, Out) ).

/* ---- 检查宏 ---- */
check(Name, Goal) :-
    ( call(Goal) -> format("ok   ~w~n", [Name])
    ; format("FAIL ~w~n", [Name]), halt(1) ).

/* ---- 书中样本类型 ---- */
t_b3(T) :- T = arr(arr(a, arr(b, c)), arr(arr(a, b), arr(a, c))).   % 8B3：B 的型
t_sel2(T) :- T = arr(a, arr(a, a)).                                  % 8B4 m=2：两选择子
t_sel3(T) :- T = arr(a, arr(a, arr(a, a))).                          % 8B4 m=3
t_k(T)    :- T = arr(a, arr(b, a)).
t_s(T)    :- T = arr(arr(a, arr(b, c)), arr(arr(a, b), arr(a, c))).
t_w(T)    :- T = arr(arr(a, arr(a, b)), arr(a, b)).
t_peirce(T) :- T = arr(arr(arr(a, b), a), a).
t_skel(T) :- T = arr(arr(a, b), c).                                  % 8B5(ii) 骨架型
t_iter(T) :- T = arr(arr(a, a), arr(a, a)).                          % 迭代子：∞
t_fig(T)  :- T = arr(arr(a, arr(a, a)), arr(a, arr(a, a))).          % 8A12 的 T

main :-
    /* ① 8B3：恰一（B 自己——长且主居留项） */
    t_b3(T1), count(T1, A1), big_d(T1, D1),
    format("(a->b->c)->(a->b)->a->c : ~w  (D = ~w)~n", [A1, D1]),
    check("8B3 count = 1", A1 = finite(1)),

    /* ② 8B4 选择子家族：a→a→a 恰 2；a→a→a→a 恰 3 */
    t_sel2(T2), count(T2, A2), check("a->a->a count = 2", A2 = finite(2)),
    t_sel3(T3), count(T3, A3), check("a->a->a->a count = 3", A3 = finite(3)),

    /* ③ 名角们：K/S/W 的型都恰 1 */
    t_k(TK), count(TK, AK), check("K-type count = 1", AK = finite(1)),
    t_s(TS), count(TS, AS), check("S-type count = 1", AS = finite(1)),
    t_w(TW), count(TW, AW), check("W-type count = 1", AW = finite(1)),

    /* ④ 8B5/8B6 零居留：原子、骨架型、Peirce */
    count(a, AA), check("atomic type count = 0", AA = zero),
    t_skel(TSk), count(TSk, ASk), check("skeletal type count = 0", ASk = zero),
    t_peirce(TP), count(TP, AP), check("Peirce count = 0", AP = zero),

    /* ⑤ 无穷案例：迭代子型与 8A12 的图型（早退口吻） */
    t_iter(TI), count(TI, AI), check("(a->a)->a->a count = inf", AI = infinite),
    t_fig(TF), count(TF, AF), check("(a->a->a)->a->a->a count = inf", AF = infinite),

    /* ⑥ 样本展示：a→a→a 的两个选择子（de Bruijn 字面） */
    t_sel2(T2b),
    findall(X, (between(0, 6, F), longnf([], T2b, X, F)), Xs0),
    sort(Xs0, Xs), format("a->a->a inhabitants: ~w~n", [Xs]),

    format("all checks passed.~n").
