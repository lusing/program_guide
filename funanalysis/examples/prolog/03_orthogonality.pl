:- encoding(utf8).
% 03_orthogonality.pl —— 第 03 章：有限维正交几何的精确模型（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
% 主题：把 Conway I.2 的正交/投影定理在"整数向量 + 自制分数算术"的
% 有限维影子里精确执行——没有浮点，勾股定理与投影公式逐位为真。
% 有理数表示为 q(N,D)（D>0，已约简），算术全部用整数 is/2 实现，
% SWI 与 GNU Prolog 双引擎可移植。

% ---------- 整数工具 ----------
gcd(0, B, G) :- !, G is abs(B).
gcd(A, B, G) :- B =\= 0, R is A mod B, gcd(B, R, G).
gcd(A, 0, G) :- !, G is abs(A).

% ---------- 有理数算术（q(N,D)，D>0，自动约简） ----------
mkq(N, D0, q(SG, DG)) :-
    D0 =\= 0,
    gcd(N, D0, G0),
    G is max(G0, 1),
    N1 is N // G, D1 is D0 // G,
    (D1 < 0 -> SG is -N1, DG is -D1 ; SG = N1, DG = D1).

q_zero(q(0, 1)).
q_add(q(A,B), q(C,D), Q) :- E is A*D + C*B, F is B*D, mkq(E, F, Q).
q_neg(q(A,B), q(NA,B)) :- NA is -A.
q_sub(X, Y, Q) :- q_neg(Y, NY), q_add(X, NY, Q).
q_mul(q(A,B), q(C,D), Q) :- E is A*C, F is B*D, mkq(E, F, Q).

% ---------- 整数向量上的内积、范数平方、正交 ----------
dot([], [], 0).
dot([X|Xs], [Y|Ys], S) :- dot(Xs, Ys, S0), S is S0 + X*Y.

normsq(X, S) :- dot(X, X, S).
orthogonal(X, Y) :- dot(X, Y, 0).

vec_add([], [], []).
vec_add([X|Xs], [Y|Ys], [Z|Zs]) :- Z is X + Y, vec_add(Xs, Ys, Zs).
vec_sub([], [], []).
vec_sub([X|Xs], [Y|Ys], [Z|Zs]) :- Z is X - Y, vec_sub(Xs, Ys, Zs).

% ---------- 勾股定理（Conway 2.2）：正交则范数平方相加 ----------
pythagoras_holds(X, Y) :-
    orthogonal(X, Y),
    vec_add(X, Y, S),
    normsq(X, A), normsq(Y, B), normsq(S, C),
    C =:= A + B.

% ---------- 平行四边形恒等式（Conway 2.3）：任意向量 ----------
parallelogram_holds(X, Y) :-
    vec_add(X, Y, Ap), vec_sub(X, Y, Sm),
    normsq(Ap, A), normsq(Sm, B),
    normsq(X, P), normsq(Y, Q),
    A + B =:= 2 * (P + Q).

% ---------- 投影到直线 span{w}（Conway 2.6-2.7 的有限维影子） ----------
% 系数 t = <v,w>/<w,w> 是精确分数；投影 p = t*w 逐分量是分数，
% 再用分数算术验证 <v - p, w> = 0（正交刻画）。
proj_coefficient(V, W, T) :-
    dot(V, W, Num), dot(W, W, Den),
    Den =\= 0,
    mkq(Num, Den, T).

int_to_q(X, q(X, 1)).
qvec_smul(_, [], []).
qvec_smul(T, [X|Xs], [Q|Qs]) :-
    q_mul(T, q(X,1), Q),
    qvec_smul(T, Xs, Qs).
qvec_dot([], [], q(0,1)).
qvec_dot([A|As], [B|Bs], Q) :-
    qvec_dot(As, Bs, Q0),
    q_mul(A, B, P),
    q_add(P, Q0, Q).
qvec_sub([], [], []).
qvec_sub([A|As], [B|Bs], [C|Cs]) :- q_sub(A, B, C), qvec_sub(As, Bs, Cs).

projection_orthogonal(V, W) :-
    proj_coefficient(V, W, T),
    qvec_smul(T, W, Pw),
    maplist(int_to_q, V, Vq),
    maplist(int_to_q, W, Wq),
    qvec_sub(Vq, Pw, Dq),
    qvec_dot(Dq, Wq, Dot),
    q_zero(Dot).

% ---------- 主流程 ----------
main :-
    format('==== 03 prolog orthogonality START ====~n', []),
    % 勾股：正交向量对
    X = [3, 4, 0], Y = [4, -3, 1],
    dot(X, Y, D),
    format('dot([3,4,0],[4,-3,1]) = ~d~n', [D]),
    ( pythagoras_holds(X, Y) -> format('pythagoras: holds~n', [])
    ; format('pythagoras: FAIL~n', []), fail ),
    % 平行四边形：任意（含不正交）向量
    A = [2, 7, 1], B = [5, -3, 4],
    ( parallelogram_holds(A, B) -> format('parallelogram: holds~n', [])
    ; format('parallelogram: FAIL~n', []), fail ),
    % 投影：v=[1,2,3] 到 w=[1,0,1]，系数应为 4/2 = 2/1
    V = [1, 2, 3], W = [1, 0, 1],
    proj_coefficient(V, W, q(N, De)),
    format('proj coeff <v,w>/<w,w> = ~d/~d~n', [N, De]),
    ( projection_orthogonal(V, W) ->
        format('projection orthogonality: verified exactly~n', [])
    ; format('projection orthogonality: FAIL~n', []), fail ),
    % 负例：不正交向量对的勾股必不成立
    NZ = [1, 2, 3], NW = [1, 1, 1],
    dot(NZ, NW, DNZ), DNZ =\= 0,
    ( pythagoras_holds(NZ, NW) ->
        format('non-orthogonal pythagoras: FAIL (should not hold)~n', []), fail
    ; format('non-orthogonal pythagoras: correctly fails~n', []) ),
    format('==== 03 prolog END ====~n', []),
    !.

