:- encoding(utf8).
% 35_independence.pl —— 第 35 章：独立性检查器（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，输出纯 ASCII。
% 事件以原子编号表示；概率表 prob/2（分数 n/d 分子分母对）。
% ① 独立判据 indep/2（乘法账 qmul/qeq 精确分数）；
% ② 双骰两两独立但三元爆雷的现场；
% ③ 卷积表谓词 conv/3。

qmul(N1,D1,N2,D2,N,D) :- N is N1*N2, D is D1*D2.
qeq(N1,D1,N2,D2) :- N1*D2 =:= N2*D1.

% 双骰模型的账（显式事实）
prob(a, 1, 6).  prob(b, 1, 6).  prob(c, 1, 2).
prob(ab, 1, 36).  prob(ac, 3, 36).  prob(bc, 3, 36).
prob(abc, 1, 36).

check_pairwise :-
    prob(a, NA, DA), prob(b, NB, DB), qmul(NA, DA, NB, DB, N, D),
    prob(ab, NAB, DAB), qeq(NAB, DAB, N, D),
    prob(a, NA2, DA2), prob(c, NC, DC), qmul(NA2, DA2, NC, DC, N2, D2),
    prob(ac, NAC, DAC), qeq(NAC, DAC, N2, D2),
    prob(b, NB2, DB2), prob(c, NC2, DC2), qmul(NB2, DB2, NC2, DC2, N3, D3),
    prob(bc, NBC, DBC), qeq(NBC, DBC, N3, D3),
    format("pairwise independence: all three pairs satisfy product rule: OK~n").

check_triple_blowup :-
    prob(a, NA, DA), prob(b, NB, DB), prob(c, NC, DC),
    qmul(NA, DA, NB, DB, N12, D12), qmul(N12, D12, NC, DC, N, D),
    prob(abc, NABC, DABC),
    \+ qeq(NABC, DABC, N, D),          % 1/36 != 1/72：爆雷
    qeq(NABC, DABC, 1, 36),
    qeq(N, D, 1, 72),
    format("triple blow-up: P(ABC)=1/36 != 1/72 = P(A)P(B)P(C): OK~n").

% 卷积表：{0,1} 上 1/2-1/2 自卷积
mu(0, 1, 2).  mu(1, 1, 2).
conv(S, N, D) :-
    findall(Q, (mu(I, NI, DI), mu(J, NJ, DJ), I + J =:= S,
                qmul(NI, DI, NJ, DJ, QN, QD), Q = QN/QD), Terms),
    sum_q(Terms, 0, 1, N, D).

sum_q([], N, D, N, D).
sum_q([A/B|T], AN, AD, N, D) :-
    N2 is AN*B + A*AD, D2 is AD*B,
    sum_q(T, N2, D2, N, D).

check_conv :-
    conv(0, N0, D0), qeq(N0, D0, 1, 4),
    conv(1, N1, D1), qeq(N1, D1, 1, 2),
    conv(2, N2, D2), qeq(N2, D2, 1, 4),
    format("convolution: 1/4, 1/2, 1/4 = Binomial(2, 1/2): OK~n").

main :-
    format("==== 35 independence~n", []),
    check_pairwise,
    check_triple_blowup,
    check_conv,
    format("END ====~n"), !.

:- initialization(main).
