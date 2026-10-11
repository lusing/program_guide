:- encoding(utf8).
% 00_intro.pl —— 第 00 章：机器可查的定理依赖图（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII（mathlogic 教程同款纪律）。
% 本文件把 Conway 全书的核心定理组织成一张知识库：
%   depends_on(定理, 工具)         直接依赖
%   depends_trans(定理, 工具)      传递依赖（递归闭包）
% 查询"哪些定理最终站在 Baire 纲定理上"变成了一个 Prolog 目标。
% 这张图也是全书 48 章的导览图。

% ---------- 直接依赖事实：定理 -> 所用核心工具 ----------
depends_on(cbs,          inner_positivity).        % I.1.4
depends_on(riesz,        orthogonal_projection).   % I.3.4
depends_on(gram_schmidt, orthogonal_projection).   % I.4.6
depends_on(orthogonal_projection, closest_point).  % I.2.7（投影定理）
depends_on(closest_point, parallelogram_law).      % I.2.5 唯一性部分
depends_on(closest_point, completeness).           % I.2.5 存在性部分
depends_on(hahn_banach,  zorn).                    % III.6
depends_on(banach_limit, hahn_banach).             % III.7*
depends_on(separation,   hahn_banach).             % IV.3 几何形式
depends_on(open_mapping, baire).                   % III.12
depends_on(closed_graph, open_mapping).            % III.12
depends_on(uniform_bounded, baire).                % III.14
depends_on(alaoglu,      tychonoff).               % V.3
depends_on(krein_milman, alaoglu).                 % V.7
depends_on(stone_weierstrass, krein_milman).       % V.8
depends_on(banach_stone, krein_milman).            % VI.2*
depends_on(compact_spec, compact_operator).        % VII.7
depends_on(gelfand_duality, max_ideal_space).      % VII.8
depends_on(gns,          positive_cone).           % VIII.5*
depends_on(spectral_theorem, spectral_measure).    % IX.2
depends_on(spectral_measure, riesz).               % IX.1（谱测度积分经 Riesz 构造）
depends_on(functional_calculus, spectral_theorem). % IX.8
depends_on(multiplicity_theory, spectral_theorem). % IX.10
depends_on(stone_theorem, spectral_theorem_unbd).  % X.5
depends_on(fredholm_index, compact_operator).      % XI.3

% ---------- 基础工具自身 ----------
depends_on(baire,        completeness).
depends_on(zorn,         choice).
depends_on(tychonoff,    choice).
depends_on(max_ideal_space, zorn).

% ---------- 传递闭包 ----------
depends_trans(T, D) :- depends_on(T, D).
depends_trans(T, D) :- depends_on(T, M), depends_trans(M, D).

% ---------- 查询 1：站在 Baire 上的定理（全书三大原理的后裔） ----------
baire_descendants(Ds) :-
    findall(T, depends_trans(T, baire), Ds0),
    sort(Ds0, Ds).

% ---------- 查询 2：站在选择公理上的定理 ----------
choice_descendants(Ds) :-
    findall(T, depends_trans(T, choice), Ds0),
    sort(Ds0, Ds).

% ---------- 查询 3：一条工具养活多少定理 ----------
all_tools(Ts) :-
    findall(T, depends_on(_, T), Ts0),
    sort(Ts0, Ts).

tool_fanout(T, N) :-
    all_tools(Ts),
    member(T, Ts),
    findall(X, depends_trans(X, T), Xs),
    length(Xs, N).

main :-
    format('==== 00 prolog dependency graph START ====~n', []),
    baire_descendants(Bd),
    format('theorems ultimately on baire: ~p~n', [Bd]),
    % 三大原理的直系：开映射、闭图像、一致有界都必须在列
    memberchk(open_mapping, Bd),
    memberchk(uniform_bounded, Bd),
    memberchk(closed_graph, Bd),
    choice_descendants(Cd),
    format('theorems ultimately on choice: ~p~n', [Cd]),
    memberchk(hahn_banach, Cd),
    memberchk(alaoglu, Cd),
    findall(T-N, tool_fanout(T, N), Fans),
    sort(Fans, FansSorted),
    format('tool fanouts (ascending): ~p~n', [FansSorted]),
    % 谱定理链最深：spectral_theorem -> spectral_measure -> ... 检查深度 >= 1
    depends_trans(functional_calculus, completeness),
    format('functional_calculus reaches completeness: yes~n', []),
    format('==== 00 prolog END ====~n', []),
    !.

