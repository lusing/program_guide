:- encoding(utf8).
% 第 72 章：秩序与序数算术（冯琦 §1.8.1-1.8.3）
% 康托尔范式演算器 · Prolog 面：ω^ω 以下的多项式带（指数为自然数的
% 指数-系数表），加法（等指数合并）、乘法（四情形装配线）、
% 运算律 forall 网格、带余除法的 findall 唯一性对拍（引理 1.20）、
% 自然列表的贪心生成（定义 1.71）。

% ---------- 表示：[E-C, ...] 指数 E 递降（E ∈ ℕ）；0 = [] ----------

% ---------- 比较（定理 1.50 在多项式带上的投影） ----------
olt(A, B) :- A \== B, olt_(A, B).

olt_([], [_|_]).
olt_([Ea-Ca|Ta], [Eb-Cb|Tb]) :-
    compare(Op, Ea, Eb),
    (  Op == (<) -> true
    ;  Op == (=) ->
       compare(Op2, Ca, Cb),
       (  Op2 == (<) -> true
       ;  Op2 == (=) -> olt_(Ta, Tb) ) ).

% ---------- 加法（命题 1.25）：保留高指数前缀、等指数合并系数 ----------
splitBelow([], _, [], []).
splitBelow([E-C|T], Eb, Keep, Rest) :-
    (  E > Eb
    -> Keep = [E-C|K2], splitBelow(T, Eb, K2, Rest)
    ;  Keep = [], Rest = [E-C|T] ).

oadd(A, [], A) :- !.
oadd([], B, B) :- !.
oadd(A, B, R) :-
    B = [Eb-Cb|Tb],
    splitBelow(A, Eb, Keep, Rest),
    (  Rest = [Eb-Ca|_]
    -> C is Ca + Cb                % ω+ω = ω·2：等指数项合并系数
    ;  C = Cb
    ),
    append(Keep, [Eb-C|Tb], R).

% ---------- 乘法（命题 1.26）：四情形装配线（if 链互斥，免 cut 防串） ----------
omul(_, [], []) :- !.
omul([], _, []) :- !.
omul(A, B, R) :-
    (  B == [0-1] -> R = A                       % α·1 = α
    ;  A == [0-1] -> R = B                       % 1·β = β
    ;  A = [0-Ca], B = [0-Cb] -> P is Ca * Cb, R = [0-P]   % 双方有限
    ;  A = [0-_], B = [Eb-Cb|Tb], Eb > 0 ->      % α 有限、β 无穷
       omul(A, Tb, Rest), oadd([Eb-Cb], Rest, R)
    ;  B = [0-Cb], Cb > 1 -> mul_loop(A, Cb, [], R)        % β 有限 ≥ 2
    ;  A = [Ea-_|_], B = [Eb-Cb|Tb], Ea > 0, Eb > 0 ->     % 双方无穷
       EE is Ea + Eb,
       (  Tb == []
       -> R = [EE-Cb]
       ;  omul(A, Tb, RestR), R = [EE-Cb|RestR] )
    ).

mul_loop(_, 0, Acc, Acc).
mul_loop(A, N, Acc, R) :- N > 0, N1 is N - 1, oadd(Acc, A, Acc2), mul_loop(A, N1, Acc2, R).

% ---------- ω 幂（多项式带内：指数为自然数） ----------
wexp(E, [E-1]).

% ω·x 塔：tower(N) = ω^N（多项式带内恰为 [N-1]）
tower(0, [0-1]) :- !.
tower(N, [N-1]) :- N > 0.

tower_step(N, T) :-                % 迭代一步：T = ω · tower(N-1)
    N > 0, N1 is N - 1,
    tower(N1, T1),
    omul([1-1], T1, T).

% ---------- 有限序数集的自然列表（定义 1.71）：贪心取最小 ----------
greedy([], []).
greedy(A, [M|T]) :-
    min_list(A, M),
    select(M, A, A1),
    greedy(A1, T).

rank_in(X, L, R) :-
    findall(Y, (member(Y, L), Y < X), Ys),
    length(Ys, R).

% ---------- 主检定 ----------
main :-
    omega_(W), nat_(1, N1), nat_(2, N2),
    % 不可交换三见证
    ( oadd(N1, W, W)        -> true ; (format("1+ω = ω 失败~n"),        halt(1)) ),
    ( oadd(W, N1, WP1) -> true ; (format("ω+1 构造失败~n"),       halt(1)) ),
    ( olt(W, WP1)            -> true ; (format("ω < ω+1 失败~n"),       halt(1)) ),
    ( omul(N2, W, W)         -> true ; (format("2·ω = ω 失败~n"),       halt(1)) ),
    ( omul(W, N2, W2)        -> true ; (format("ω·2 构造失败~n"),       halt(1)) ),
    ( olt(W, W2)             -> true ; (format("ω < ω·2 失败~n"),       halt(1)) ),
    format("1+ω = ω < ω+1 ✓   2·ω = ω < ω·2 ✓~n"),

    % 网格池：0, 1, 2, ω, ω+1, ω·2, ω², ω²+1, ω³
    G = [[], [0-1], [0-2], [1-1], [1-1,0-1], [1-2], [2-1], [2-1,0-1], [3-1]],
    forall(member(A, G), forall(member(B, G), forall(member(C, G), (
        ( ( oadd(A, B, X1), oadd(X1, C, R1),
            oadd(B, C, X2), oadd(A, X2, R2), R1 == R2 )
          -> true ; (format("加法结合律失败~n"), halt(1)) ),
        ( ( omul(A, B, Y1), omul(Y1, C, S1),
            omul(B, C, Y2), omul(A, Y2, S2), S1 == S2 )
          -> true ; (format("乘法结合律失败~n"), halt(1)) ),
        ( ( oadd(B, C, D1), omul(A, D1, T1),
            omul(A, B, U1), omul(A, C, U2), oadd(U1, U2, T2), T1 == T2 )
          -> true ; (format("左分配律失败~n"), halt(1)) ),
        ( olt(A, B) ->
            ( ( oadd(A, C, V1), oadd(B, C, V2),
                ( V1 == V2 ; olt(V1, V2) ) )
              -> true ; (format("右弱保序失败~n"), halt(1)) )
        ; true )
    )))),
    format("9³ 网格：加法结合/乘法结合/左分配/右弱保序全对 ✓~n"),

    % 右分配律失效见证：(ω+1)·2 = ω·2+1 ≠ ω·2+1·2 = ω·2+2
    omul(WP1, N2, LHS),
    omul(W, N2, W2b), omul(N1, N2, N2b), oadd(W2b, N2b, RHS),
    ( LHS \== RHS -> true ; (format("右分配反例失败~n"), halt(1)) ),
    format("(ω+1)·2 ≠ ω·2+1·2 ✓（右分配律失效）~n"),

    % ω·ω = ω²（wexp 一致性）与 ω·x 塔
    wexp(1, W), wexp(2, W22),
    omul(W, W, WW),
    ( WW == W22 -> true ; (format("ω·ω = ω² 失败~n"), halt(1)) ),
    forall(between(1, 5, N),
           ( tower_step(N, T),
             tower(N, TN),
             ( T == TN -> true ; (format("塔失败 at ~w~n", [N]), halt(1)) ) )),
    format("ω·x 塔：ω·ω^N = ω^(N+1)，1→ω→ω²→…→ω⁵ ✓（sup = ω^ω 在带外）~n"),

    % 带余除法（引理 1.20）：候选池封闭化后 findall 唯一性对拍
    findall(X, (member(A1, G), member(B1, G), omul(A1, B1, X)), Ps),
    sort(Ps, P),
    length(P, NP),
    forall(member(D, G), forall(member(Al, G), (
        Al \== [] ->
        ( findall(Bt-Rt, (member(Bt, P), member(Rt, G),
                          omul(Al, Bt, AB), oadd(AB, Rt, D), olt(Rt, Al)),
                  Sols),
          length(Sols, 1)
        -> true ; (format("带余除法唯一性失败~n"), halt(1)) )
    ; true ))),
    format("带余除法：72 对 (δ,α) 解存在且唯一 ✓（候选池 ~w 元）~n", [NP]),

    % 自然列表：贪心 = 升序去重，名次 = 位次（雪崩映射）
    A0 = [5, 1, 3, 0, 9, 2],
    greedy(A0, L), sort(A0, L2),
    ( L == L2 -> true ; (format("贪心 ≠ 升序~n"), halt(1)) ),
    forall(nth1(I, L, X),
           ( rank_in(X, L, R),
             ( R =:= I - 1 -> true ; (format("名次 ≠ 位次 at ~w~n", [X]), halt(1)) ) )),
    format("自然列表 {0,1,2,3,5,9}：贪心 = 升序 ✓ 名次恒等于位次 ✓~n"),

    format("END ====~n").

nat_(0, []) :- !.
nat_(N, [0-N]) :- N > 0.
omega_([1-1]).
