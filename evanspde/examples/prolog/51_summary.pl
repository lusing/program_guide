% Ch51 总结：全书方法选择树
%
% 把 51 章的工具装进一棵可查询的树：问题类型 → 方法 → 章号。

:- encoding(utf8).

method(P, Type, Tool, Ch) :-
    problem_method(P, Type, Tool, Ch).

problem_method('方程类型判断', Type, Tool, Ch) :- classify(Type, Tool, Ch).
classify(transport, '特征线平移（02）+ Duhamel（02）', 2).
classify(laplace, '基本解（03）→ 平均值（03/04）→ Green（04）→ 能量（05）', 3).
classify(heat, '热核卷积（06）→ 半群（07/38）→ Galerkin（34）', 6).
classify(wave, 'd''Alembert/Kirchhoff（09/10）→ Galerkin（36）', 9).
classify(hamilton_jacobi, '特征线（12/13）→ Hopf-Lax（13）→ 粘性解（45）', 13).
classify(conservation, 'RH + 熵（15）→ Lax-Oleinik（16）→ Riemann 组（47/48）', 15).
classify(nonlinear_elliptic, '变分直接法（40）→ 山路（42）→ 上下解（44）', 39).
classify(nonlinear_wave, '能量守恒（49）→ 临界指标（50）', 49).

problem_method('正则性提升', '光滑', '磨光不动点（04/07）差商（27/31）', 31).
problem_method('存在唯一', 'abstract', 'Lax-Milgram（29）Fredholm（30）不动点（43）', 29).
problem_method('谱', 'eigen', 'Rayleigh-Ritz + min-max（33）Weyl 律（33）', 33).
problem_method('长时间行为', 'asymptotic', '谱衰减（35）N 波（16）散射（50）', 35).
problem_method('数值验证', 'machine', '制造解残差 + 双通道交叉 + Lean 代数核', 0).

main :-
    format("==== 51~n"),
    forall(problem_method(P, T, Tool, Ch),
           format("  ~w | ~w -> ~w (ch ~d)~n", [P, T, Tool, Ch])),
    % 一致性：七个分类
    findall(T, classify(T, _, _), L),
    length(L, 8),
    format("classification audit: 8 equation families~n"),
    format("END ====~n").
