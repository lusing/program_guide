:- encoding(utf8).
% 04_independence.pl —— 第 04 章：独立性的有限穷举（SWI-Prolog 有理数）
%
% ① 9 点空间：任两位置事件独立，三个位置同时为 a 不独立；
% ② 混合模型：给定 C 后 A、B 独立，边际不独立；
% ③ XOR：A、B 边际独立，给定 C=1 后不独立；
% ④ 四点 X→X²：协方差为 0，但 Y 由 X 完全决定。

% 洪书 9 个等可能字符串（原子）。
point(aaa). point(bbb). point(ccc).
point(abc). point(bca). point(cba).
point(acb). point(bac). point(cab).

char_at(Point, Position, Char) :-
    atom_chars(Point, Chars),
    nth1(Position, Chars, Char).

count_event(Position, Count) :-
    findall(P, (point(P), char_at(P, Position, a)), Ps),
    length(Ps, Count).

count_pair(I, J, Count) :-
    findall(P, (point(P), char_at(P, I, a), char_at(P, J, a)), Ps),
    length(Ps, Count).

count_triple(Count) :-
    findall(P, (point(P),
                char_at(P, 1, a), char_at(P, 2, a), char_at(P, 3, a)),
            Ps),
    length(Ps, Count).

check_nine_points :-
    count_event(1, 3), count_event(2, 3), count_event(3, 3),
    count_pair(1, 2, 1), count_pair(1, 3, 1), count_pair(2, 3, 1),
    count_triple(1),
    (1 rdiv 9) =:= (1 rdiv 3) * (1 rdiv 3),
    (1 rdiv 9) =\= (1 rdiv 3) * (1 rdiv 3) * (1 rdiv 3),
    format("nine points: all pairs 1/9, triple 1/9 not 1/27: OK~n").

% 混合模型：mix(A,B,C,未归一权重/50)
mix(1, 1, 0, 1).  mix(1, 0, 0, 4).  mix(0, 1, 0, 4).  mix(0, 0, 0, 16).
mix(1, 1, 1, 16). mix(1, 0, 1, 4).  mix(0, 1, 1, 4).  mix(0, 0, 1, 1).

check_mixture :-
    % 给定 C=0：P(A=1)=5/25, P(B=1)=5/25, P(A=B=1)=1/25
    (1 rdiv 25) =:= (5 rdiv 25) * (5 rdiv 25),
    % 给定 C=1：P(A=1)=20/25, P(B=1)=20/25, P(A=B=1)=16/25
    (16 rdiv 25) =:= (20 rdiv 25) * (20 rdiv 25),
    findall(W, (mix(1, 0, _, W) ; mix(1, 1, _, W)), Aws),
    findall(W, (mix(0, 1, _, W) ; mix(1, 1, _, W)), Bws),
    findall(W, mix(1, 1, _, W), ABws),
    sum_list(Aws, PA), sum_list(Bws, PB), sum_list(ABws, PAB),
    (17 rdiv 50) =\= (1 rdiv 2) * (1 rdiv 2),
    PA =:= 25, PB =:= 25, PAB =:= 17,
    format("mixture: A independent of B given C, but dependent marginally: OK~n").

% XOR 四点模型
xor_point(0, 0, 0).
xor_point(1, 0, 1).
xor_point(0, 1, 1).
xor_point(1, 1, 0).

check_xor :-
    findall(A, xor_point(A, _, _), As), length(As, 4),
    findall(_, xor_point(1, _, _), Aones), length(Aones, 2),
    findall(_, xor_point(_, 1, _), Bones), length(Bones, 2),
    findall(_, xor_point(1, 1, _), ABones), length(ABones, 1),
    (1 rdiv 4) =:= (1 rdiv 2) * (1 rdiv 2),
    % 给定 C=1 只有 (1,0),(0,1)，不可能 A=B=1
    findall(_, xor_point(1, 1, 1), ABGivenC),
    length(ABGivenC, 0),
    0 =\= (1 rdiv 2) * (1 rdiv 2),
    format("XOR: marginal independence becomes dependence given C=1: OK~n").

% 四点零相关：x ∈ {-2,-1,1,2}, y=x²
xval(-2, 4). xval(-1, 1). xval(1, 1). xval(2, 4).

check_zero_covariance :-
    findall(X, xval(X, _), Xs),
    findall(Y, xval(_, Y), Ys),
    sum_list(Xs, SumX), sum_list(Ys, SumY),
    length(Xs, N),
    MeanX is SumX rdiv N,
    MeanY is SumY rdiv N,
    findall((X-MeanX)*(Y-MeanY), xval(X, Y), Terms),
    sum_list(Terms, CovNumerator),
    Cov is CovNumerator rdiv N,
    Cov =:= 0,
    % 依赖关系是确定的：每个 X 唯一对应 Y
    forall(xval(X, Y), Y =:= X*X),
    format("four points: covariance 0 while Y is exactly X^2: OK~n").

main :-
    format("==== 04 independence~n"),
    check_nine_points,
    check_mixture,
    check_xor,
    check_zero_covariance,
    format("END ====~n"), !.

:- initialization(main).
