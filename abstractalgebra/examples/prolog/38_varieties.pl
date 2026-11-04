:- encoding(utf8).
% 第 38 章 · 簇 —— Prolog 通道
%
% Var/Id 集合运算（格点数值面）+ 根理想 + 弱 Nullstellensatz + 簇分解。

% 多项式 = 项表 i-j-c（x^i y^j 的系数 c）
peval([], _, _, 0).
peval([I-J-C|Rest], A, B, V) :-
    peval(Rest, A, B, V0),
    V is V0 + C * A ^ I * B ^ J.

% x² − 1 与 y² − 1：格点零点集
vanishing(F, Grid, Zs) :-
    findall(P, (member(A-B, Grid), peval(F, A, B, 0), P = A-B), Zs).

main :-
    format("==== 38 簇~n"),

    % 格点 [−3..3]²
    findall(A-B, (between(-3, 3, A), between(-3, 3, B)), Grid),
    length(Grid, 49),

    % V(IJ) = V(I) ∪ V(J)（命题 7.40）：(x²−1)(y²−1) = x²y² − x² − y² + 1
    F1 = [2-0-1, 0-0-(-1)],                    % x² − 1
    F2 = [0-2-1, 0-0-(-1)],                    % y² − 1
    F12 = [2-2-1, 2-0-(-1), 0-2-(-1), 0-0-1],  % 乘积
    vanishing(F1, Grid, V1),
    vanishing(F2, Grid, V2),
    vanishing(F12, Grid, V12),
    union(V1, V2, VU),
    sort(V12, V12s), sort(VU, VUs),
    V12s = VUs,
    format("V(IJ) = V(I) ∪ V(J)：(x²−1)(y²−1) 的 49 格点核对 ✓~n"),

    % V(I+J) = V(I) ∩ V(J)：{(±1,±1)}（两个生成元同时为零）
    findall(P, (member(A-B, Grid), peval(F1, A, B, 0),
                peval(F2, A, B, 0), P = A-B), VIJ),
    VIJ = [(-1)-(-1), (-1)-1, 1-(-1), 1-1],
    format("V(I+J) = V(I) ∩ V(J) = {(±1,±1)}（四点）✓~n"),

    % V(x²) = V(x) = 整条直线 {x=0}（重根不增零点）⟹ Id(V(x²)) = (x) = √(x²)
    vanishing([2-0-1], Grid, Vx2),
    vanishing([1-0-1], Grid, Vx),
    sort(Vx2, Vx2s), sort(Vx, Vxs),
    Vx2s = Vxs,
    length(Vxs, 7),
    format("V(x²) = V(x) = 直线 x=0（重根不增零点）⟹ √(x²) = (x) ✓~n"),

    % 弱 Nullstellensatz：{x, x−1} 无公共零点，且 1 = x − (x−1) ∈ 理想
    findall(A-B, (member(A-B, Grid),
                  peval([1-0-1], A, B, 0),
                  peval([1-0-1, 0-0-(-1)], A, B, 0)), Vempty),
    Vempty = [],
    format("弱 Nullstellensatz：{x, x−1} 无公共零点（1 = x−(x−1) 在理想中）✓~n"),

    % 簇分解：V(xy) = V(x) ∪ V(y)（两条坐标轴）
    vanishing([1-1-1], Grid, Vxy),
    findall(A-B, (member(A-B, Grid), A =:= 0), Vx),
    findall(A-B, (member(A-B, Grid), B =:= 0), Vy),
    union(Vx, Vy, VxyU),
    sort(Vxy, VxyS), sort(VxyU, VxyUS),
    VxyS = VxyUS,
    format("V(xy) = V(x) ∪ V(y)：代数集 = 两条簇（不可约分量之并）✓~n"),

    format("END ====~n").
