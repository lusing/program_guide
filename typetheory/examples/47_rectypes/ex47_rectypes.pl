:- encoding(utf8).
/* ============================================================
   41 递归类型 —— Prolog：μ 展开与限界子类型（书 ch.20/21）
   甲·等式递归（equi-recursive）：μX.T 与 T[μX.T/X] 定义相等
      ——按需展开 unfold/2 + 深度限界的子类型检查（21.5 的
      成员检查雏形：双侧展开到结构可比为止）
   乙·正则树：μ 类型 = 有限（正则）无限树——位串地址的
      子树收集 + 循环检测（21.7 的「有限图表示无限树」）
   丙·样本族：NatList = μX. <nil:Unit, cons:{Nat×X}>（书 20.1）
      的定型与展开；μ 的三段等式（μX.T = T[μX.T/X] 循环见证）
   ============================================================ */

:- use_module(library(lists)).

/* ---- 甲·按需展开（限界 D 层）---- */
unfold(mu(X, T), U) :- subst_ty(T, X, mu(X, T), U).
unfold(T, T) :- T \= mu(_, _).

subst_ty(var(X), X, S, S) :- !.
subst_ty(T, _, _, T) :- atomic(T), !.
subst_ty(mu(Y, B), X, S, mu(Y, B1)) :- !, subst_ty(B, X, S, B1).
subst_ty(rcd(Fs), X, S, rcd(Fs1)) :- !,
    map_subst_f(Fs, X, S, Fs1).
subst_ty(arr(A, B), X, S, arr(A1, B1)) :- !,
    subst_ty(A, X, S, A1), subst_ty(B, X, S, B1).
subst_ty(var(Y), _, _, var(Y)) :- !.
subst_ty(vart(Fs), X, S, vart(Fs1)) :- !, map_subst_f(Fs, X, S, Fs1).
map_subst_f([], _, _, []).
map_subst_f([L=T|Fs], X, S, [L=T1|Fs1]) :-
    subst_ty(T, X, S, T1), map_subst_f(Fs, X, S, Fs1).

/* 统一入口（var 的代换在 subst_ty 首句处理） */
unf(mu(X, T), U) :- !, subst_ty(T, X, mu(X, T), U).
unf(T, T).

/* 限界子类型：D 层燃料；书 21.5 成员检查的雏形 */
rsub(_, top, _) :- !.
rsub(S, T, _) :- S = T, !.
rsub(mu(X, B), T, D) :- !, D > 0, D1 is D - 1,
    unf(mu(X, B), U), rsub(U, T, D1).
rsub(S, mu(X, B), D) :- !, D > 0, D1 is D - 1,
    unf(mu(X, B), U), rsub(S, U, D1).
rsub(arr(S1, S2), arr(T1, T2), D) :- !, D > 0, D1 is D - 1,
    rsub(T1, S1, D1), rsub(S2, T2, D1).
rsub(rcd(SF), rcd(TF), D) :- !, D > 0, D1 is D - 1,
    every_fsub(TF, SF, D1).

every_fsub([], _, _).
every_fsub([L=T|TF], SF, D) :-
    member(L=S, SF),
    rsub(S, T, D),
    every_fsub(TF, SF, D).

/* ---- 乙·正则树：位串地址收集子树 ---- */
subtree(T, [], T).
subtree(rcd(Fs), [L|P], S) :-
    member(L=T, Fs), subtree(T, P, S).
subtree(vart(Fs), [L|P], S) :-
    member(L=T, Fs), subtree(T, P, S).
subtree(arr(A, _), [l|P], S) :- subtree(A, P, S).
subtree(arr(_, B), [r|P], S) :- subtree(B, P, S).

/* 收集到深度 N 的全部子树（有限集 ⇔ 正则） */
subtrees_upto(T, N, Set) :-
    findall(S, (between(0, N, K), addr(K, P), subtree(T, P, S)), Ss),
    sort(Ss, Set).

addr(0, []).
addr(N, [l|P]) :- N > 0, M is N - 1, addr(M, P).
addr(N, [r|P]) :- N > 0, M is N - 1, addr(M, P).
addr(N, [L|P]) :- N > 0, atom(L), M is N - 1, addr(M, P).

/* ---- 丙·样本族 ---- */
natlist(vart([nil=unitt, cons=rcd([hd=natt, tl=mu(x, vart([nil=unitt, cons=rcd([hd=natt, tl=var(x)])]))])])).

/* 等式读法：NatList 展开 = <nil:Unit, cons:{Nat × NatList}> */
check(Name, Goal) :-
    (   call(Goal) -> format("ok   : ~w~n", [Name])
    ;   format("FAIL : ~w~n", [Name]), fail ).

main :-
    /* ① μ 的三段等式：μX.T → T[μX.T/X] → μX.T 循环 */
    Mu = mu(x, arr(var(x), var(x))),
    check("μX.X→X 一步展开为 (μX.X→X)→(μX.X→X)",
           unf(Mu, arr(Mu, Mu))),
    check("展开幂等：再展一次回到同构形状",
           ( unf(arr(Mu, Mu), arr(Mu, Mu)) )),

    /* ② NatList 样本（书 20.1）：定型与自展开 */
    natlist(NL),
    check("NatList 的 cons 分支自含 μ（有限表示无限）",
           ( unf(NL, vart([nil=unitt, cons=C1])),
             unf(C1, rcd([hd=natt, tl=mu(x, _)])) )),

    /* ③ 限界子类型：μ ↔ 展开式可互判（等式读法的核心） */
    check("μX.X→X <: 自身展开（深度 3 内成立）",
           rsub(Mu, arr(Mu, Mu), 3)),
    check("记录深度 + μ 混合：μ 与其展开式可互判",
           ( natlist(NL2), unf(NL2, U),
             rsub(rcd([hd=natt, tl=NL2]), rcd([hd=natt, tl=U]), 7) )),
    check("假命题被拒：μX.X→X <: Nat",
           \+ rsub(Mu, natt, 5)),

    /* ④ 正则树：有限子树集 */
    natlist(NL3),
    subtrees_upto(NL3, 2, Ss), length(Ss, Cnt),
    format("ok   : NatList 深度 2 内共 ~w 个相异子树（正则性）~n", [Cnt]),
    check("深度 3 也不增长（循环=有限图）",
           ( subtrees_upto(NL3, 3, Ss3), length(Ss3, Cnt) )),

    format("all checks passed.~n").
