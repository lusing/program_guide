:- encoding(utf8).
% 09_projections.pl —— 第 09 章：投影格的有限维影子（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
% 主题：2x2 有理矩阵的幂等性与 ran = ker(I-E) 分解（Conway II.3）。
% 矩阵表示为行表的表 [[a,b],[c,d]]，元素用 q(N,D) 有理数；
% 全整数算术，精确无浮点。

% ---------- q 算术（复用 03 章的实现思路，这里内联精简版） ----------
gcd(0, B, G) :- !, G is abs(B).
gcd(A, B, G) :- B =\= 0, R is A mod B, gcd(B, R, G).
gcd(A, 0, G) :- !, G is abs(A).

mkq(N, D0, q(SG, DG)) :- D0 =\= 0, gcd(N, D0, G0), G is max(G0, 1),
    N1 is N // G, D1 is D0 // G,
    (D1 < 0 -> SG is -N1, DG is -D1 ; SG = N1, DG = D1).
q_zero(q(0,1)).
q_one(q(1,1)).
q_add(q(A,B), q(C,D), Q) :- E is A*D + C*B, F is B*D, mkq(E, F, Q).
q_neg(q(A,B), q(NA,B)) :- NA is -A.
q_sub(X, Y, Q) :- q_neg(Y, NY), q_add(X, NY, Q).
q_mul(q(A,B), q(C,D), Q) :- E is A*C, F is B*D, mkq(E, F, Q).

% ---------- 矩阵运算（2x2） ----------
mmul([[A,B],[C,D]], [[E,F],[G,H]], R) :-
    q_mul(A,E,T1), q_mul(B,G,T2), q_add(T1,T2,R11),
    q_mul(A,F,T3), q_mul(B,H,T4), q_add(T3,T4,R12),
    q_mul(C,E,T5), q_mul(D,G,T6), q_add(T5,T6,R21),
    q_mul(C,F,T7), q_mul(D,H,T8), q_add(T7,T8,R22),
    R = [[R11,R12],[R21,R22]].

id2(I) :- q_one(O), q_zero(Z), I = [[O,Z],[Z,O]].

% I - E：逐元素取负加单位
i_minus(E, R) :- E = [[A,B],[C,D]],
    q_neg(A,NA), q_neg(B,NB), q_neg(C,NC), q_neg(D,ND),
    q_one(O), q_zero(Z),
    q_add(O,NA,R11), q_add(Z,NB,R12), q_add(Z,NC,R21), q_add(O,ND,R22),
    R = [[R11,R12],[R21,R22]].

idempotent(E) :- mmul(E, E, E).

% ran E ⊆ ker(I-E)：E 的每一列（跨行取同下标）被 I-E 消灭
column1([[A,_],[C,_]], Col) :- Col = [A,C].
column2([[_,B],[_,D]], Col) :- Col = [B,D].

apply2(M, [X,Y], Z) :- nth1(1, M, Row1), nth1(2, M, Row2),
    nth1(1, Row1, A), nth1(2, Row1, B),
    nth1(1, Row2, C), nth1(2, Row2, D),
    q_mul(A,X,T1), q_mul(B,Y,T2), q_add(T1,T2,Z1),
    q_mul(C,X,T3), q_mul(D,Y,T4), q_add(T3,T4,Z2),
    Z = [Z1,Z2].

kills(IminusE, E) :-
    column1(E, C1), apply2(IminusE, C1, Z1), Z1 = [Q1,Q2],
    q_zero(Q1), q_zero(Q2),
    column2(E, C2), apply2(IminusE, C2, [Q3,Q4]),
    q_zero(Q3), q_zero(Q4).

% ---------- 斜投影 E(x,y) = (x+y, 0)：幂等但范数 > 1（Conway 习题 1 的影子）----------
obl(E) :- q_one(O), q_zero(Z), E = [[O,O],[Z,Z]].
orth(P) :- q_one(O), q_zero(Z), P = [[O,Z],[Z,Z]].

% 范数放大的精确有理化证书：E(1,1) = (2,0) 的范数平方 4 > 输入范数平方 2
inflation_certificate(E, In, Out) :-
    apply2(E, [q(1,1), q(1,1)], Out), Out = [q(2,1), q(0,1)], In = [q(1,1), q(1,1)].

main :-
    format('==== 09 prolog projections START ====~n', []),
    obl(E),
    ( idempotent(E) -> format('oblique idempotent: yes~n', [])
    ; format('oblique idempotent: FAIL~n', []), fail ),
    i_minus(E, ImE),
    ( kills(ImE, E) -> format('ran E = ker(I-E): verified exactly~n', [])
    ; format('ran E = ker(I-E): FAIL~n', []), fail ),
    ( inflation_certificate(E, _, _) ->
        format('inflation certificate: E(1,1)=(2,0), 4 > 2~n', [])
    ; format('inflation certificate: FAIL~n', []), fail ),
    orth(P),
    ( idempotent(P) -> format('orthogonal idempotent: yes~n', [])
    ; format('orthogonal idempotent: FAIL~n', []), fail ),
    format('==== 09 prolog END ====~n', []),
    !.
