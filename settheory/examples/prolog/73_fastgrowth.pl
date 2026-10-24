:- encoding(utf8).
% 第 73 章：快速增长数论函数层次（冯琦 §1.8.4）——Prolog 通道
% 嵌套 CNF 序数 on([t(指数,系数)|…])（指数递归，走出 72 章的多项式带）：
% 基本序列（定义 1.83 四条款）、F_α 层次（定义 1.84，F₀/F₁ 闭式 + 字面
% 对拍）、古德斯坦剧场（HB 树不存基——换基=换读法，影子=同一棵树读成
% ON；G(3) 全程五步归零、G(4) 前四步值链书载对拍）。

% ---------- ON 表示与比较 ----------
oz(on([])).
nat_on(N, on([])) :- N =< 0, !.
nat_on(N, on([t(on([]),N)])).
wexp(E, on([t(E,1)])).
omega(W) :- nat_on(1, One), wexp(One, W).

olt(A, B) :- A \== B, olt_(A, B).
olt_(on([]), on([_|_])).
olt_(on([t(Ea,Ca)|Ta]), on([t(Eb,Cb)|Tb])) :-
    (  olt(Ea, Eb) -> true
    ;  olt(Eb, Ea) -> fail
    ;  Ca \== Cb -> Ca < Cb
    ;  olt_(on(Ta), on(Tb)) ).

% ---------- 加法：保留高指数前缀、等指数合并系数 ----------
splitBelow(on([]), _, [], []).
splitBelow(on([t(E,C)|T]), Eb, Keep, Rest) :-
    (  olt(Eb, E)
    -> Keep = [t(E,C)|K2], splitBelow(on(T), Eb, K2, Rest)
    ;  Keep = [], Rest = [t(E,C)|T] ).

oadd(on(A), on([]), on(A)) :- !.
oadd(on([]), on(B), on(B)) :- !.
oadd(on(A), on(B), on(R)) :-
    B = [t(Eb,Cb)|Tb],
    splitBelow(on(A), Eb, Keep, Rest),
    (  Rest = [t(Eb,Ca)|_]
    -> C is Ca + Cb
    ;  C = Cb
    ),
    append(Keep, [t(Eb,C)|Tb], R).

% ---------- 后继/极限与前驱 ----------
is_limit(on(Ts)) :- Ts \== [], last(Ts, t(E,_)), E \== on([]).

opred(on(Ts), on(Us)) :-
    last(Ts, t(on([]),C)),
    append(Init, [t(on([]),C)], Ts),
    (  C =:= 1 -> Us = Init
    ;  C1 is C - 1, append(Init, [t(on([]),C1)], Us) ).

% ---------- 基本序列（定义 1.83 四条款 + ε₀ 特例） ----------
% (c) m=1, k>1：α(n) = ω^β·(k−1) + (ω^β)(n)
fs(on([t(B,K)]), N, R) :-
    K > 1, !,
    K1 is K - 1,
    fs(on([t(B,1)]), N, R1),
    oadd(on([t(B,K1)]), R1, R).
% (b) m=1, k=1, β 极限：α(n) = ω^(β(n))
fs(on([t(B,1)]), N, R) :-
    is_limit(B), !,
    fs(B, N, BN), wexp(BN, R).
% (a) m=1, k=1, β=γ+1：α(n) = ω^γ·n（ω(n)=n 为 γ=0 特例）
fs(on([t(B,1)]), N, R) :-
    !, opred(B, G),
    (  N =:= 0 -> R = on([])
    ;  R = on([t(G,N)]) ).
% (d) m>1：头部保留，末项系数减一后接 (ω^βm)(n)
fs(on(Ts), N, R) :-
    append(Head, [t(Bm,Km)], Ts),
    (  Km > 1
    -> Km1 is Km - 1, append(Head, [t(Bm,Km1)], H1)
    ;  H1 = Head ),
    fs(on([t(Bm,1)]), N, R1),
    oadd(on(H1), R1, R).

% ε₀(0) = 0，ε₀(n+1) = ω^(ε₀(n))（定义 1.83(3)）
fs_eps0(0, on([])) :- !.
fs_eps0(N, R) :- N > 0, N1 is N - 1, fs_eps0(N1, R1), wexp(R1, R).

% ---------- 快速增长层次（定义 1.84；F₀/F₁ 闭式 + 字面对拍） ----------
f_lit(on([]), N, R) :- !, R is N + 1.
f_lit(A, N, R) :-
    is_limit(A), !,
    fs(A, N, AN), f_lit(AN, N, R).
f_lit(A, N, R) :-
    opred(A, B), iter_lit(B, N, N, R).
iter_lit(_, 0, X, X) :- !.
iter_lit(B, K, X, R) :-
    K > 0, f_lit(B, X, Y), K1 is K - 1, iter_lit(B, K1, Y, R).

f_alpha(on([]), N, R) :- !, R is N + 1.
f_alpha(on([t(on([]),1)]), N, R) :- !, R is 2 * N.   % F₁ 闭式
f_alpha(A, N, R) :-
    is_limit(A), !,
    fs(A, N, AN), f_alpha(AN, N, R).
f_alpha(A, N, R) :-
    opred(A, B), iter_f(B, N, N, R).
iter_f(_, 0, X, X) :- !.
iter_f(B, K, X, R) :-
    K > 0, f_alpha(B, X, Y), K1 is K - 1, iter_f(B, K1, Y, R).

% ---------- HB 遗传展开（树里不存基：换基 = 换读法） ----------
hb_of(_, 0, hb([])) :- !.
hb_of(B, M, hb([t(hb([]),M)])) :- M < B, !.   % 原子常数（<b，不换基）
hb_of(B, M, hb(Ts)) :-
    maxpow(B, M, 0, 1, E, P),
    K is M // P, R is M mod P,
    hb_of(B, E, HE), hb_of(B, R, hb(TR)),
    Ts = [t(HE,K)|TR].
maxpow(B, M, E, P, E, P) :- P * B > M, !.
maxpow(B, M, E0, P0, E, P) :-
    E1 is E0 + 1, P1 is P0 * B, maxpow(B, M, E1, P1, E, P).

hb_eval(hb([]), _, 0) :- !.
hb_eval(hb([t(E,K)|T]), B, V) :-
    hb_eval(E, B, EV), hb_eval(hb(T), B, TV),
    V is B^EV * K + TV.

hb_to_on(hb([]), on([])) :- !.
hb_to_on(hb([t(E,K)|T]), on([t(OE,K)|OT])) :-
    hb_to_on(E, OE), hb_to_on(hb(T), on(OT)).

gstep(B, M, M2) :-
    hb_of(B, M, T), B1 is B + 1, hb_eval(T, B1, V), M2 is V - 1.

% ---------- G(3) 全程与 G(4) 前段（fuel 限步：G(4) 归零物理不可行） ----------
gchain(0, _, _, [], []) :- !.
gchain(_, _, 0, [0], [on([])]) :- !.
gchain(Fuel, B, M, [M|Cs], [S|Ss]) :-
    M > 0, Fuel > 0,
    hb_of(B, M, T), hb_to_on(T, S),
    gstep(B, M, M2), B1 is B + 1, F1 is Fuel - 1,
    gchain(F1, B1, M2, Cs, Ss).

strict_dec([_]).
strict_dec([A,B|T]) :- olt(B, A), strict_dec([B|T]).

% ---------- 主检定 ----------
main :-
    format("==== 73~n"),
    % 基本序列样本（引理 1.22）：ω²(n)=ω·n、ω^ω(n)=ω^n、(ω^ω+ω³·2)(n)=ω^ω+ω³+ω²·n
    nat_on(1, One), nat_on(2, Two), nat_on(3, Three),
    omega(W),
    wexp(Two, W2), wexp(W, WW), wexp(WW, WWW),
    oadd(WW, on([t(Three,2)]), S5), oadd(WWW, W2, S6),
    Samples = [W, W2, WW, WWW, S5, S6],
    forall(member(A, Samples),
           forall(between(0, 5, N),
                  (fs(A, N, X), N1 is N + 1, fs(A, N1, Y),
                   (olt(X, Y), olt(Y, A) -> true ; throw(fs_bad(A, N)))))),
    fs_eps0(3, E3), fs_eps0(4, E4), olt(E3, E4),
    writeln("基本序列 6 条样本严格递增且不越界 ✓；ε₀(3) < ε₀(4) ↗ ε₀"),
    % F 层次：闭式与字面对拍 + 解析式验证
    oz(Z),
    forall(member(K, [0,1,2]),
           (nat_on(K, NK),
            forall(between(1, 8, N),
                   (f_alpha(NK, N, R1), f_lit(NK, N, R2), R1 =:= R2)))),
    forall(between(1, 6, N),
           (f_alpha(Z, N, R0), R0 =:= N + 1,
            f_alpha(One, N, R1), R1 =:= 2 * N,
            f_alpha(Two, N, R2), R2 =:= N * 2^N)),
    f_alpha(Three, 1, F31), F31 =:= 2,
    f_alpha(Three, 2, F32), F32 =:= 2048,
    f_alpha(W, 1, FW1), FW1 =:= 2,
    f_alpha(W, 2, FW2), FW2 =:= 8,
    f_lit(W, 2, FW2L), FW2L =:= 8,
    writeln("F₀(n)=n+1、F₁(n)=2n、F₂(n)=n·2ⁿ ✓；F₃(2)=2048、F_ω(2)=8 ✓（闭式与字面对拍一致）"),
    f_alpha(Two, 24, F224), F224 =:= 402653184,
    format("F_ω(3) = F₂(~w) = ~w·2^~w——可定义而不可算~n", [F224, F224, F224]),
    % <* 见证
    forall(between(2, 30, N), (f_alpha(Z, N, A1), f_alpha(One, N, A2), A1 < A2)),
    forall(between(5, 30, N), (f_alpha(One, N, B1), f_alpha(Two, N, B2), B1 < B2)),
    forall(between(7, 30, N), (f_alpha(Two, N, C2), N^3 + N < C2)),
    writeln("<* 见证：F₀<*F₁（n≥2）、F₁<*F₂（n≥5）、n³+n <* F₂（n≥7）✓"),
    % T₂(37)：影子 = ω^{ω^ω+1}+ω^ω+1（原子 2 的影子是 ω）
    hb_of(2, 37, T37), hb_eval(T37, 2, V37), V37 =:= 37,
    hb_to_on(T37, O37),
    oadd(WW, One, WWp1),
    wexp(WWp1, WexpWWp1),
    oadd(WexpWWp1, WWp1, O37exp),
    O37 == O37exp,
    writeln("T₂(37) = 2^(2²+1)+2²+1 ✓（影子 ω^{ω^ω+1}+ω^ω+1）"),
    % G(3) 全程：值链 [3,3,3,2,1,0]，影子 ω+1 > ω > 3 > 2 > 1 > 0
    gchain(10, 2, 3, Chain3, Shadows3),
    Chain3 == [3, 3, 3, 2, 1, 0],
    strict_dec(Shadows3),
    writeln("G(3)：值链 [3, 3, 3, 2, 1, 0]（5 步归零），影子 ω+1 > ω > 3 > 2 > 1 > 0 ✓"),
    % G(4) 前四步：值链书载对拍 + 影子下降 + 起点影子 ω^ω
    gchain(4, 2, 4, Chain4, Shadows4),
    Chain4 == [4, 26, 41, 60],
    strict_dec(Shadows4),
    hb_of(2, 4, T4), hb_to_on(T4, A0), A0 == WW,
    writeln("G(4)：起点影子 ω^ω；值链前四步 [4, 26, 41, 60] 书载对拍 ✓（归零物理不可行，fuel 限步）"),
    writeln("END ====").
