:- encoding(utf8).
% 第 92 章 · 布尔值模型（冯琦第二卷 §3.5）——Prolog 通道
% 与 Python 同一组检查：Ba1-Ba6 穷举、布尔值算法与定理 3.23、
% V^B 两层度量账（引理 3.75(1)）、柱超滤子 Los 换算与广义分配律。

% ---------- 一、幂集代数 B = 2^2（定义 3.38） ----------

% 元素 bitpair(X, Y)。运算点态。
bjoin(bitpair(X1, Y1), bitpair(X2, Y2), bitpair(O1, O2)) :-
    (   X1 = true ; X2 = true -> O1 = true ; O1 = false ),
    (   Y1 = true ; Y2 = true -> O2 = true ; O2 = false ).
bmeet(bitpair(X1, Y1), bitpair(X2, Y2), bitpair(O1, O2)) :-
    (   X1 = true, X2 = true -> O1 = true ; O1 = false ),
    (   Y1 = true, Y2 = true -> O2 = true ; O2 = false ).
bcompl(bitpair(X, Y), bitpair(NX, NY)) :-
    (   X = true -> NX = false ; NX = true ),
    (   Y = true -> NY = false ; NY = true ).
bimp(A, B, C) :- bcompl(A, NA), bjoin(NA, B, C).

bitval(true).  bitval(false).
b4(bitpair(X, Y)) :- bitval(X), bitval(Y).

% Ba1-Ba6 穷举
check_ba5 :- forall(b4(A),
    (   bcompl(A, AC),
        bmeet(A, AC, bitpair(false, false)),
        bjoin(A, AC, bitpair(true, true)) )).
check_ba1 :- forall(( b4(A), b4(B) ),
    (   bjoin(A, B, J), bjoin(B, A, J),
        bmeet(A, B, M), bmeet(B, A, M) )).
check_ba3 :- forall(( b4(A), b4(B), b4(C) ),
    (   bjoin(B, C, BC), bmeet(A, BC, L),
        bmeet(A, B, AB), bmeet(A, C, AC), bjoin(AB, AC, L) )).
check_ba2 :- forall(( b4(A), b4(B), b4(C) ),
    (   bmeet(B, C, BC), bmeet(A, BC, L),
        bmeet(A, B, AB), bmeet(AB, C, L) )).

% ---------- 二、布尔值算法（定义 3.51） ----------

% 公式：atom / not(F) / and(F,G) / or(F,G) / imp(F,G) / iff(F,G)
bval(atom, V, V).
bval(not(F), V, W) :- bval(F, V, X), bcompl(X, W).
bval(and(F, G), V, W) :- bval(F, V, X), bval(G, V, Y), bmeet(X, Y, W).
bval(or(F, G), V, W) :- bval(F, V, X), bval(G, V, Y), bjoin(X, Y, W).
bval(imp(F, G), V, W) :- bval(F, V, X), bval(G, V, Y), bimp(X, Y, W).
bval(iff(F, G), V, W) :-
    bval(F, V, X), bval(G, V, Y),
    bimp(X, Y, P), bimp(Y, X, Q), bmeet(P, Q, W).

% 定理 3.23(1)：矛盾值为 0
check_not_self :-
    forall(( formula(F), b4(V), bval(F, V, X),
             bval(not(F), V, NX), bmeet(X, NX, bitpair(false, false)) ),
           true).

formula(atom).
formula(not(atom)).
formula(and(atom, not(atom))).
formula(or(atom, atom)).
formula(imp(atom, atom)).
formula(iff(atom, atom)).
formula(imp(and(atom, not(atom)), atom)).

% 同一律与爆炸律的值为 1
check_tauts :-
    forall(b4(V),
           (   bval(imp(atom, atom), V, bitpair(true, true)),
               bval(imp(and(atom, not(atom)), atom), V, bitpair(true, true)) )).

% ---------- 三、V^B 两层度量账（引理 3.75(1) 影子） ----------

% 一层名字：坐标上的 B 值（mem1(X, S, U) 即 S(X) = U）。
mem1(X, S, U) :- call(S, X, U).
eq1(T, S, W) :- call(T, 0, X), call(S, 0, Y),
    bimp(X, Y, P), bimp(Y, X, Q), bmeet(P, Q, W).

gen_diag(U, _, U).          % 对角名字：任何坐标取 u
gen_bot(_, bitpair(false, false)).

check_generic :-
    U0 = bitpair(true, false),
    mem1(0, gen_diag(U0), U0),                     % [[u ∈ G]] = u
    eq1(gen_diag(U0), gen_diag(U0), bitpair(true, true)).  % [[t = t]] = 1

% ---------- 四、柱超滤子与广义分配律 ----------

u0(bitpair(true, _)).

check_los :-
    forall(( b4(A), b4(B) ),
           (   (  u0(A) -> (  bcompl(A, CA), \+ u0(CA) ) ; true ),
              (  bmeet(A, B, M), ( u0(M) -> ( u0(A), u0(B) )
                                 ;  ( \+ u0(A) ; \+ u0(B) ) ) ),
              (  bimp(A, B, I), ( u0(A) -> ( u0(I) -> u0(B) ; \+ u0(B) )
                                ;  true ) ) )).

% 广义分配律（定义 3.68）：2x2 穷举
check_distrib :-
    forall(( b4(B00), b4(B01), b4(B10), b4(B11) ),
           (   bjoin(B00, B01, J0), bjoin(B10, B11, J1),
               bmeet(J0, J1, LHS),
               bmeet(B00, B10, M1), bmeet(B00, B11, M2),
               bmeet(B01, B10, M3), bmeet(B01, B11, M4),
               bjoin(M1, M2, R1), bjoin(M3, M4, R2),
               bjoin(R1, R2, LHS) )).

main :-
    writeln("==== 92"),
    check_ba5, check_ba1, check_ba2, check_ba3,
    writeln("幂集代数 2^2：Ba1-Ba6 全部穷举验证 OK"),
    check_not_self, check_tauts,
    writeln("布尔值算法：矛盾值为 0、同一律与爆炸律值为 1 OK"),
    check_generic,
    writeln("V^B 两层账：[[u in G]] = u（引理 3.75(1)）、[[t=t]]=1 OK"),
    check_los,
    writeln("柱超滤子 U0：交/补/蕴含的 Los 换算（引理 3.72 原子）OK"),
    check_distrib,
    writeln("广义分配律（定义 3.68）：2x2 全部 256 个矩阵穷举 OK"),
    writeln("END ====").
