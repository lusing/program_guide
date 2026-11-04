:- encoding(utf8).
% 第 126 章 Prolog：关系与函数的有限终审。
% ① 关系运算 dom/ran/像/复合/逆 + 定律审计（书 2.5.2/2.5.8/2.5.9）；
% ② 函数性/单射/满射判定（书 2.2.1/2.2.5）；
% ③ 左逆 ⟹ 单射（2.5.12）；右逆不 ⟹ 可逆（常值反例）；
% ④ 相容系统：并是函数当且仅当相容（书 2.2.9/2.2.10）。

% ---------- ① 关系运算 ----------
rdom(R, D) :- setof(X, Y^(member((X,Y), R)), D).
rran(R, Rs) :- setof(Y, X^(member((X,Y), R)), Rs).
rimg(R, A, I) :- setof(Y, (member((X,Y), R), member(X, A)), I).
flip(R, FR) :- findall((Y,X), member((X,Y), R), L), sort(L, FR).
rcomp(S, R, C) :-                                     % C = S∘R：先 R 后 S
    findall((X,Z), (member((X,Y), R), member((Y,Z), S)), CL),
    sort(CL, C).
seteq(A, B) :- sort(A, As), sort(B, Bs), As == Bs.

% ---------- 定律审计 ----------
check_laws :-
    R = [(0,a),(1,a),(1,b),(2,c)],
    S = [(a,x),(b,y),(c,z)],
    T = [(x,0),(y,1)],
    A = [0,1], B = [1,2],
    % 2.5.2 并律等式
    rimg(R, A, IA), rimg(R, B, IB),
    append(A, B, AB), sort(AB, ABs), rimg(R, ABs, IAB),
    union(IA, IB, IU), sort(IU, IUs), seteq(IAB, IUs),
    % 2.5.8 结合律：T∘(S∘R) = (T∘S)∘R
    rcomp(S, R, SR), rcomp(T, SR, TSR),
    rcomp(T, S, TS), rcomp(TS, R, TSR2), seteq(TSR, TSR2),
    % 2.5.9 逆的账：(S∘R)⁻¹ = R⁻¹∘S⁻¹、逆逆还原、dom/ran 对调
    rcomp(S, R, SR2), flip(SR2, SRI),
    flip(S, SI), flip(R, RI), rcomp(RI, SI, CompInv), seteq(SRI, CompInv),
    flip(RI, RII), seteq(RII, R),
    rdom(R, RD), rran(R, RR), flip(R, RIv), rdom(RIv, RD2), seteq(RD2, RR),
    format("relation laws: union/assoc/inverse audited on samples: OK~n").

% ---------- ② 函数三性 ----------
is_function(F) :-                                     % F 是单值的关系
    \+ (member((X,Y1), F), member((X,Y2), F), Y1 \= Y2).

injective(F) :-
    \+ (member((X1,Y), F), member((X2,Y), F), X1 \= X2).

surjective(F, Y) :-
    \+ (member(V, Y), \+ member((_, V), F)).

check_functions :-
    F1 = [(0,c),(1,c),(2,d)],                         % 函数、非单、满到 {c,d}
    is_function(F1),
    \+ injective(F1),
    surjective(F1, [c,d]),
    F2 = [(0,a),(1,b),(2,c)],
    is_function(F2), injective(F2), surjective(F2, [a,b,c]),
    is_function([(0,a),(1,a)]),                       % 常值也是函数
    \+ is_function([(0,a),(0,b)]),                    % 单值性被破坏的反例
    format("function props: single-valued / injective / surjective checks: OK~n").

% ---------- ③ 左右逆的账（2.5.12） ----------
check_inverses :-
    % 左逆存在 ⟹ 单射：双射 f 与其逆 g，g∘f = id
    F = [(0,a),(1,b),(2,c)], G = [(a,0),(b,1),(c,2)],
    rcomp(G, F, GF), seteq(GF, [(0,0),(1,1),(2,2)]),
    injective(F),
    % 右逆不 ⟹ 可逆：常值 f: {p,q}->{c}，h: {c}->{p}，f∘h = id_{c}
    Cf = [(p,c),(q,c)], H = [(c,p)],
    rcomp(Cf, H, CH), seteq(CH, [(c,c)]),
    \+ injective(Cf),
    format("inverses: left inverse implies injective; right inverse does not: OK~n").

% ---------- ④ 相容系统 ----------
compatible(F, G) :-
    \+ (member((X,Y1), F), member((X,Y2), G), Y1 \= Y2).

check_compatible :-
    F1 = [(0,a),(1,b)], F2 = [(1,b),(2,c)], F3 = [(1,x)],
    compatible(F1, F2),
    \+ compatible(F1, F3),
    append(F1, F2, U0), sort(U0, U), is_function(U),   % 相容 ⟹ 并是函数
    \+ (append(F1, F3, V0), sort(V0, V), is_function(V)),
    format("compatible systems: union is function iff compatible: OK~n").

main :-
    format("==== 126 relations~n"),
    check_laws,
    check_functions,
    check_inverses,
    check_compatible,
    format("END ====~n"), !.

:- initialization(main).
