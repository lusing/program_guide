:- encoding(utf8).
% 第 59 章 Prolog：路径枚举与调和方程（rdiv 精确）。
% ① 首返计数：长 2k、中途不回 0、终点回 0 的 ±1 路径数 = 2·Catalan(k−1)
%    （k = 1..5 穷举对账），概率 = 计数/2^(2k)；
% ② 赌徒破产（N=4，i=1,2,3）：深度受限枚举的"先触 N"概率从下逼近 i/N，
%    未吸收余量随深度几何衰减；
% ③ 调和方程 u_i=(u_{i−1}+u_{i+1})/2 的精确解 u_i=i/4（N=4）：
%    边界与三条调和式全过——Lean 唯一性定理的构造性孪生。
:- initialization(main).

% ---------- ① 首返路径计数 ----------
step(1). step(-1).

% partial_sums(Xs, Sums)：Sums = [S_1, ..., S_n]（正序，累加器精确）
partial_sums(Xs, Sums) :- psums(Xs, 0, Sums).
psums([], _, []).
psums([X|Xs], Acc, [S|Rest]) :- S is Acc + X, psums(Xs, S, Rest).

% first_return(Seq, K)：|Seq| = 2k，S_{2k} = 0，S_1..S_{2k-1} ≠ 0
first_return(Seq, K) :-
    N2 is 2 * K,
    length(Seq, N2),
    maplist(step, Seq),
    partial_sums(Seq, Sums),
    append(Mid, [0], Sums),        % 末位 S_{2k} = 0
    maplist(dif(0), Mid).          % 中途 S_1..S_{2k-1} 不回 0

count_first_return(K, C) :-
    N2 is 2 * K,
    findall(Seq, (length(Seq, N2), maplist(step, Seq), first_return(Seq, K)), All),
    length(All, C).

% Catalan(m) = C(2m, m)/(m+1)，整数精确
fall(_, 0, 1) :- !.
fall(N, K, F) :- K > 0, K1 is K - 1, fall(N, K1, F0), F is F0 * (N - K1).
fact(0, 1) :- !.
fact(N, F) :- N > 0, N1 is N - 1, fact(N1, F0), F is F0 * N.
comb(N, K, C) :- fall(N, K, F), fact(K, KF), C is F // KF.
catalan(M, C) :- comb(2 * M, M, B), C is B // (M + 1).

% ---------- ② 深度受限的"先触 N"概率 ----------
p_top(I, N, _, 1 rdiv 1) :- I =:= N, !.
p_top(I, _, _, 0 rdiv 1) :- I =:= 0, !.
p_top(_, _, 0, 0 rdiv 1) :- !.
p_top(I, N, D, P) :-
    D > 0,
    D1 is D - 1,
    I1 is I + 1,
    I2 is I - 1,
    p_top(I1, N, D1, P1),
    p_top(I2, N, D1, P2),
    P is (P1 + P2) / 2.

% ---------- ③ 调和方程精确解（N = 4） ----------
check_ruin4 :-
    U0 = 0 rdiv 1, U1 = 1 rdiv 4, U2 = 1 rdiv 2, U3 = 3 rdiv 4, U4 = 1 rdiv 1,
    U0 =:= 0, U4 =:= 1,
    2 * U1 =:= U0 + U2,
    2 * U2 =:= U1 + U3,
    2 * U3 =:= U2 + U4.

main :-
    format("==== 59 random_walks~n"),
    forall(member(K, [1, 2, 3, 4, 5]),
           (count_first_return(K, C),
            K1 is K - 1,
            catalan(K1, Cat),
            C =:= 2 * Cat,
            P is C rdiv 2^(2 * K),
            format("   k=~d：首返路径数 = ~d = 2·C_~d，f^(2k) = ~w~n", [K, C, K1, P]))),
    format("① 首返计数穷举 = 2·Catalan(k-1)，k=1..5 全对账~n"),
    forall(member(I, [1, 2, 3]),
           (format("   i=~d：", [I]),
            forall(member(D, [6, 12, 20]),
                   (p_top(I, 4, D, P),
                    format("深度~d → ~w  ", [D, P]))),
            format("（→ ~w = i/N）~n", [I rdiv 4]))),
    format("② 先触 N 概率从下逼近 i/N（对称游动必吸收，余量几何衰减）~n"),
    check_ruin4,
    format("③ N=4 精确解 u_i = i/4：边界与三条调和式全过（Lean 定理孪生）~n"),
    format("END ====~n").
