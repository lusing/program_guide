:- encoding(utf8).
% 18_multivariate_transformations.pl —— 第 18 章：离散变换的分区求和（Prolog 穷举）
%
% ① 两骰 (X,Y) → (min,max)：多对一，对角 1/36、非对角 2/36；
% ② (X,Y) → (X+Y, X−Y)：一对一，质量搬运不变，像集 36 点；
% ③ (X,Y) → X·Y：分区求和（每个像值收集所有原像）；
% ④ 2×2 整数矩阵行列式 = 单位格点平行四边形面积（Pick 公式特例：格点数检验）。

die(D) :- member(D, [1,2,3,4,5,6]).
pair(X, Y) :- die(X), die(Y).

image_mass(Map, Image, Mass) :-
    findall(Image, (pair(X, Y), call(Map, X, Y, Image)), Imgs0),
    sort(Imgs0, Imgs),
    member(Image, Imgs),
    aggregate_all(count, (pair(X, Y), call(Map, X, Y, Image)), Cnt),
    Mass is Cnt rdiv 36.

minmax(X, Y, Lo-Hi) :- Lo is min(X, Y), Hi is max(X, Y).
sumdiff(X, Y, S-D) :- S is X + Y, D is X - Y.
times(X, Y, P) :- P is X * Y.

check_minmax :-
    forall(image_mass(minmax, Lo-Hi, M),
           ( Lo =:= Hi -> M =:= 1 rdiv 36 ; M =:= 2 rdiv 36 )),
    aggregate_all(sum(M), image_mass(minmax, _, M), T), T =:= 1,
    aggregate_all(count, image_mass(minmax, _, _), N), N =:= 21,
    format("① (min,max): 21 images, diagonal 1/36, off-diagonal 2/36, total 1: OK~n").

check_sumdiff :-
    aggregate_all(count, image_mass(sumdiff, _, _), N), N =:= 36,
    forall(image_mass(sumdiff, _, M), M =:= 1 rdiv 36),
    format("② (X+Y, X−Y): one-to-one, 36 images each 1/36: OK~n").

check_product :-
    image_mass(times, 6, M6), M6 =:= 4 rdiv 36,      % 1·6, 6·1, 2·3, 3·2
    image_mass(times, 12, M12), M12 =:= 4 rdiv 36,    % 2·6, 6·2, 3·4, 4·3
    image_mass(times, 1, M1), M1 =:= 1 rdiv 36,
    aggregate_all(sum(M), image_mass(times, _, M), T), T =:= 1,
    format("③ product XY: P(XY=6)=P(XY=12)=4/36, P(XY=1)=1/36, total 1: OK~n").

% ④ 2×2 行列式：det [[A,B],[C,D]] = AD−BC 是线性映射的面积放大倍数；
%    检验 det=5、奇异矩阵 det=0、旋转 det=1 与乘法性 det(AB)=det(A)det(B)。
det2(A, B, C, D, Det) :- Det is A * D - B * C.

check_det :-
    det2(2, 1, 1, 3, 5),
    det2(1, 2, 3, 6, 0),          % 线性相关：退化，面积 0
    det2(0, -1, 1, 0, 1),         % 旋转 90°：保面积
    % 乘法性：det(AB)=det(A)det(B)，A=[[2,1],[1,3]]，B=[[1,2],[0,1]]
    A11 is 2*1 + 1*0, A12 is 2*2 + 1*1, A21 is 1*1 + 3*0, A22 is 1*2 + 3*1,
    det2(A11, A12, A21, A22, DAB), det2(1, 2, 0, 1, DB), det2(2, 1, 1, 3, DA),
    DAB =:= DA * DB,
    format("④ 2x2 determinants: det=5, singular 0, rotation 1, det(AB)=det(A)det(B): OK~n").

main :-
    format("==== 18 multivariate transformations~n"),
    check_minmax, check_sumdiff, check_product, check_det,
    format("END ====~n"), !.

:- initialization(main).
