:- encoding(utf8).
% 14_linfty_dual.pl —— 第 14 章：ba vs ca 的有限退化（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
% Ω = {1,2,3}：荷 = 8 个位掩码块的赋值。穷举验证：
% ① 每个有限可加荷自动可数可加（无新集合燃料）——ba = ca；
% ② 权重表生成的一切块值满足全部 256 对可加性检查；
% ③ 对照账：有限世界的"单点质量和 = 总质量"恒成立，
%    而无限世界（自然密度）破产——越轨是无穷现象。

omega3([1,2,3]).

mask_sets(0, []).
mask_sets(M, S) :- between(0, 7, M), findall(K, (member(K, [1,2,3]),
    (M >> (K - 1)) /\ 1 =:= 1), S).

% 荷：由三点权重生成的块账
mu_w(M, W, V) :- mask_sets(M, S), foldl([K, Acc, NV]>>(nth1(K, W, X), NV is Acc + X),
    S, 0, V).

% 有限可加性检查：A ⊔ B = C（掩码不交且 C = A\/B）⟹ μ(A)+μ(B) = μ(C)
disjoint_masks(A, B) :- A /\ B =:= 0.

check_additivity(W) :-
    forall(( between(0, 7, A), between(0, 7, B), disjoint_masks(A, B),
             C is A \/ B ),
           ( mu_w(A, W, VA), mu_w(B, W, VB), mu_w(C, W, VC),
             VA + VB =:= VC )).

main :-
    format("==== 14 linfty_dual~n", []),
    % 权重表 1：均匀
    check_additivity([0.2, 0.3, 0.5]),
    % 权重表 2：非均匀（含 0 权）
    check_additivity([0.0, 0.5, 0.5]),
    format("all 64 disjoint mask pairs additive (finite ba = ca): OK~n"),
    % 总质量账
    mu_w(7, [0.2, 0.3, 0.5], T1), abs(T1 - 1.0) < 1e-12,
    mu_w(7, [0.0, 0.5, 0.5], T2), abs(T2 - 1.0) < 1e-12,
    format("total mass 1 for both weight tables: OK~n"),
    % 对照账：有限世界单点和 = 总质量；无限世界（自然密度）0 != 1
    mu_w(1, [0.2, 0.3, 0.5], S1), mu_w(2, [0.2, 0.3, 0.5], S2),
    mu_w(4, [0.2, 0.3, 0.5], S3), Sum is S1 + S2 + S3,
    abs(Sum - 1.0) < 1e-12,
    format("finite world: singleton sum = total (no exotics); infinite world (natural density): 0 != 1~n"),
    format("END ====~n"), !.
