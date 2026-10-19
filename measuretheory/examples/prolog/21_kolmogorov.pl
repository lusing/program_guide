:- encoding(utf8).
% 21_kolmogorov.pl —— 第 21 章：有限指标集相容性检查器（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，输出纯 ASCII。
% 分布表 dist(Win, Assign, P)（分数 n/d）。窗口用列表表示（变量标号）。
% ① 边缘谓词 marg/4：对被丢坐标求和；
% ② 相容谓词 consistent/0：枚举窗口对核对共享边缘（正例通过）；
% ③ 反例族（传递断链）：边缘层面通过、联合装配（Fréchet 上确界）总质量 < 1；
% ④ 核装配：马氏链三步联合的 (2,3)-边缘 = 两步装配账。

qeq(N1,D1,N2,D2) :- N1*D2 =:= N2*D1.

% 分布表：tab(Tag, Assign, N, D)，Assign 按窗口变量顺序取值列表。
% family/2：窗口（变量标号列表）→ 该窗口的分布 Tag。
family([1,2], indep12).
family([2,3], indep12).
family_bad([1,2], perfect).
family_bad([2,3], perfect).
family_bad([1,3], indep12).

% indep12：四格均匀（1/4）；perfect：对角（1/2）
tab(indep12, [0,0], 1,4).  tab(indep12, [0,1], 1,4).
tab(indep12, [1,0], 1,4).  tab(indep12, [1,1], 1,4).
tab(perfect, [0,0], 1,2).  tab(perfect, [1,1], 1,2).

% marg_over(Tag, Win, KeepLabels, Key, N, D)：把 Tag 分布投影到 KeepLabels
% （Win 的变量标号顺序已知，KeepLabels ⊆ Win）
marg_over(Tag, Win, Keep, Key, N, D) :-
    findall(PN*PD*Key0,
            ( tab(Tag, Assign, PN, PD),
              pair_up(Win, Assign, Pairs),       % [Var-Val,...]
              include([V-_]>>(member(V, Keep)), Pairs, Kept),
              pairs_values_sorted(Keep, Kept, Key0) ),
            Bags),
    aggregate_keys(Bags, Key, N, D).

pair_up([], [], []).
pair_up([V|Vs], [A|As], [V-A|Rest]) :- pair_up(Vs, As, Rest).

pairs_values_sorted([], _, []).
pairs_values_sorted([V|Vs], Kept, [A|As]) :-
    member(V-A, Kept),
    pairs_values_sorted(Vs, Kept, As).

aggregate_keys(Bags, Key, N, D) :-
    findall(K, member(_*_*K, Bags), Keys),
    sort(Keys, Unique),
    member(Key, Unique),
    findall(PN*PD, member(PN*PD*Key, Bags), Terms),
    sum_terms(Terms, 0, 1, N, D).

sum_terms([], N, D, N, D).
sum_terms([A*B|T], AN, AD, N, D) :-
    N2 is AN*B + A*AD, D2 is AD*B,
    sum_terms(T, N2, D2, N, D).

% --- ② 相容检查：同一族下任意两窗口的共享边缘一致 ---
check_pair(FamilyPred, W1, W2) :-
    call(FamilyPred, W1, Tag1), call(FamilyPred, W2, Tag2),
    shared(W1, W2, Shared), Shared \= [],
    !,
    marg_over(Tag1, W1, Shared, K, N1, D1),
    marg_over(Tag2, W2, Shared, K, N2, D2),
    qeq(N1, D1, N2, D2).

shared([], _, []).
shared([V|Vs], W, S) :-
    (  member(V, W) -> S = [V|S2] ; S = S2 ),
    shared(Vs, W, S2).

consistent(FamilyPred) :-
    \+ ( call(FamilyPred, W1, _), call(FamilyPred, W2, _),
         W1 @< W2, shared(W1, W2, S), S \= [],
         \+ check_pair(FamilyPred, W1, W2) ).

% --- ③ 反例装配：Fréchet 上确界（每个原子的质量 = 各窗口约束的最小值）---
% 三元原子 [x1,x2,x3]；族 bad 的三个二元窗约束。
frechet_atom([X1,X2,X3], N, D) :-
    member(X1, [0,1]), member(X2, [0,1]), member(X3, [0,1]),
    tab(perfect, [X1,X2], NA, DA),
    tab(perfect, [X2,X3], NB, DB),
    tab(indep12, [X1,X3], NC, DC),
    min3(NA, DA, NB, DB, NC, DC, N, D).

leq_frac(NA,DA,NB,DB) :- NA*DB =< NB*DA.

min3(NA, DA, NB, DB, NC, DC, N, D) :-
    (  leq_frac(NA,DA,NB,DB), leq_frac(NA,DA,NC,DC) -> N = NA, D = DA
    ;  leq_frac(NB,DB,NC,DC) -> N = NB, D = DB
    ;  N = NC, D = DC ).

check_frechet :-
    findall(q(N,D), frechet_atom(_, N, D), Terms),
    foldl([q(A,B), AN*AD, CN*CD]>>(
              CN is AN*B + A*AD, CD is AD*B), Terms, 0*1, TN*TD),
    TN < TD,                                       % 总质量 < 1 ⟹ 无联合分布
    format("Frechet assembly total = ~w/~w < 1 (no joint exists): OK~n", [TN, TD]).

% --- ④ 核装配账：μ₁⊗P⊗P 的 (2,3)-边缘 = μ₂⊗P ---
p(1,1,7,10).  p(1,2,3,10).
p(2,1,2,5).   p(2,2,3,5).

joint123(X1,X2,X3, N,D) :-
    mu1(X1, MA, MB), p(X1,X2, NA,NB), p(X2,X3, NC,ND),
    N is MA*NA*NC, D is MB*NB*ND.

mu1(1, 7,10).  mu1(2, 3,10).
mu2(1, 61,100).  mu2(2, 39,100).

check_kernel_assembly :-
    forall((member(X2,[1,2]), member(X3,[1,2])),
           ( findall(N*D, (member(X1,[1,2]), joint123(X1,X2,X3,N,D)), Terms),
             sum_terms(Terms, 0, 1, SN, SD),
             mu2(X2, MA, MB), p(X2,X3, NA, NB),
             EN is MA*NA, ED is MB*NB,
             qeq(SN, SD, EN, ED) )),
    format("kernel assembly: (2,3)-marginal == mu2 (*) P (exact): OK~n").

% --- main ---
main :-
    format("==== 21 kolmogorov~n", []),
    ( consistent(family) -> format("independent family: pairwise consistent: OK~n")
    ; format("FAIL: independent family inconsistent~n") ),
    ( consistent(family_bad) -> format("bad family: pairwise marginals consistent (insufficient!): OK~n")
    ; format("bad family: caught at shared marginal~n") ),
    check_frechet,
    check_kernel_assembly,
    format("END ====~n"), !.

:- initialization(main).
