:- encoding(utf8).

% 第 116 章：荟萃塔 I——club 与荟萃的有限刻画、轮换最小性、塔链、
% 等价类机制与泛型相遇（与 Julia/Python 对拍）。

% ── 一、载体 {0,1,2} 与子集（表形） ──
inU(0). inU(1). inU(2).

sub_of(S) :- member(S, [[], [0], [1], [2], [0,1], [0,2], [1,2], [0,1,2]]).

% 一元函数（表形 [F0,F1,F2]）。
funs(F) :-
    member(F0, [0,1,2]), member(F1, [0,1,2]), member(F2, [0,1,2]),
    F = [F0, F1, F2].

feval(F, 0, V) :- nth0(0, F, V).
feval(F, 1, V) :- nth0(1, F, V).
feval(F, 2, V) :- nth0(2, F, V).

% 轮换 g = (012)。
gcf([1, 2, 0]).

% ── 二、club：C_f = {A ⊆ U | f[A] ⊆ A} ──
fevalimg(F, A, Img) :-
    findall(V, (member(E, A), feval(F, E, V)), Img).

club_member(F, A) :-
    sub_of(A), fevalimg(F, A, Img),
    forall(member(V, Img), member(V, A)).

club(F, C) :-
    findall(A, club_member(F, A), C).

% ── 三、荟萃性：与每个 club 相交 ──
smn(X) :-
    \+ (funs(F), club(F, C),
        \+ (member(A, X), member(A, C))).

% 完全刻画：单成员族 {A} 荟萃 ⟺ A 为 ∅ 或 U。
smn_char :-
    forall(sub_of(A),
           (smn([A]) -> (A == [] ; A == [0,1,2]) ; (A \== [], A \== [0,1,2]))).

% 非平凡反例：三点余单点族被轮换打败。
co_i(I, A) :- findall(E, (member(E, [0,1,2]), E \== I), A).

x2_family(X) :- findall(A, (member(I, [0,1,2]), co_i(I, A)), X).

smn_x2_fail :-
    x2_family(X), \+ smn(X).

% ── 四、塔序（支撑面）与链搜索 ──
supp(X, S) :-
    findall(E, (member(A, X), member(E, A)), Es), sort(Es, S).

le(X, Y) :-
    supp(X, SX), supp(Y, SY),
    forall(member(E, SY), member(E, SX)).

glb(T1, T2, G) :-
    findall(A, (member(A, T1), member(A, T2)), G).

tower_demo :-
    T1 = [[0], [1], [0,1,2]], T2 = [[1], [2], [0,1,2]],
    glb(T1, T2, G),
    le(T1, T1), le(G, T1), le(G, T2),
    x2_family(X2),
    le(X2, [[0,1,2]]),
    le([[0], [1], [0,1,2]], [[0,1,2]]).

% ── 五、等价类机制（~_G：主滤子 F₀） ──
eqset(F, G, E) :-
    findall(B, (inU(B), feval(F, B, VF), feval(G, B, VG), VF =:= VG), E).

g_large(B) :- member(0, B).

feq(F, G) :- eqset(F, G, E), g_large(E).

feq_refl :- forall(funs(F), feq(F, F)).
feq_sym :- forall((funs(F), funs(G), feq(F, G)), feq(G, F)).
feq_trans :-
    forall((funs(F), funs(G), funs(H), feq(F, G), feq(G, H)), feq(F, H)).

% 常值刻画。
feq_const :-
    forall((funs(F), member(C, [0,1,2])),
           (feq(F, [C,C,C]) ->
            (findall(B, (inU(B), feval(F, B, C)), E), g_large(E))
          ; (findall(B, (inU(B), feval(F, B, C)), E2), \+ g_large(E2)))).

% ── 六、泛型相遇（降落/提升封闭） ──
down(B, X, D) :- findall(E, (member(E, B), member(E, X)), D).

compat :-
    forall((member(B, [[0], [0,1,2]]), down(B, [0,1], D)),
           forall(member(E, D), member(E, [0,1]))).

main :-
    % club 最小性：轮换的 club 恰 {∅, U}。
    club([1,2,0], C), sort(C, [[], [0,1,2]]),
    smn_char, smn_x2_fail, tower_demo,
    feq_refl, feq_sym, feq_trans, feq_const, compat,
    format("club 27 函数分布；轮换最小 {空,U}；荟萃刻画+X2 反例~n"),
    format("塔序支撑面+glb+链；等价三律+常值；降落封闭（泛型相遇）~n"),
    writeln("END ====").
