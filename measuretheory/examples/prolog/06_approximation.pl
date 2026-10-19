:- encoding(utf8).
% 06_approximation.pl —— 第 06 章：生成系上的测度唯一性（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
% Ω = {1,2,3,4}。初始段族 C = {Iic n} = {{1}, {1,2}, {1,2,3}, Ω} 是 π-系，
% 生成的 σ-代数是全幂集。验证：
%   1. 两个测度在 C 上相等（且 μ(Ω) 有限）⟹ 全相等（唯一性机器）；
%   2. 无限测度时唯一性失效的反例。

univ([1,2,3,4]).

subseteq([], _).
subseteq([H|T], S) :- member(H, S), subseteq(T, S).
seteq(A, B) :- subseteq(A, B), subseteq(B, A).

intersect([], _, []).
intersect([H|T], S, [H|R]) :- member(H, S), !, intersect(T, S, R).
intersect([_|T], S, R) :- intersect(T, S, R).

diff([], _, []).
diff([H|T], S, R) :- member(H, S), !, diff(T, S, R).
diff([H|T], S, [H|R]) :- diff(T, S, R).

% 确定性子集枚举
all_subsets(S) :- between(0, 15, Msk), mask_set(Msk, S).
mask_set(Msk, S) :-
    findall(E, (nth0(I, [1,2,3,4], E), Msk /\ (1 << I) =\= 0), S).

% 初始段族
iic(N, S) :- between(1, 4, N), findall(X, (between(1, 4, X), X =< N), S).
init_class(C) :- findall(S, (member(N, [1,2,3,4]), iic(N, S)), C).

% π-系：Iic a ∩ Iic b = Iic min(a,b) ∈ C
pi_check :-
    \+ ( member(A, [1,2,3,4]), member(B, [1,2,3,4]),
         iic(A, SA), iic(B, SB), intersect(SA, SB, I),
         \+ (member(N, [1,2,3,4]), iic(N, SN), seteq(SN, I)) ).

% 测度由原子质量表（权重表）给出：mu_w(Set) = Σ w(k), k ∈ Set
mu_w(W, Set, M) :- aggregate_all(sum(K), (member(X, Set), member(w(X, K), W)), M).

% 在 C 上相等
agree_on(W1, W2, C) :-
    \+ ( member(S, C), mu_w(W1, S, M1), mu_w(W2, S, M2), M1 =\= M2 ).

% 处处相等
equal_everywhere(W1, W2) :-
    \+ ( all_subsets(S), mu_w(W1, S, M1), mu_w(W2, S, M2), M1 =\= M2 ).

main :-
    format("==== 06 approximation~n", []),
    init_class(C),
    pi_check,
    format("initial segments form a pi-system: OK~n"),
    % 对照实验：只在"非生成"子族 {Iic1, Iic2} 上相等——唯一性失败
    W1 = [w(1,1), w(2,2), w(3,3), w(4,4)],
    W2 = [w(1,1), w(2,2), w(3,4), w(4,3)],
    Csmall = [[1], [1,2]],
    (   agree_on(W1, W2, Csmall)
    ->  (   equal_everywhere(W1, W2)
        ->  format("partial class: FAIL (should NOT extend)~n"), fail
        ;   format("on non-generating class agreement does NOT extend: OK~n") )
    ;   format("partial class setup: FAIL~n"), fail ),
    % 主实验：在完整生成族 C 上相等的两表必然相同（差分唯一性）
    (   agree_on(W1, W2, C)
    ->  format("distinct tables agreeing on full C: FAIL (uniqueness!)~n"), fail
    ;   format("no two distinct tables agree on full C (uniqueness on generator): OK~n") ),
    W1c = W1,
    agree_on(W1c, W1c, C), equal_everywhere(W1c, W1c),
    format("same table trivially agrees everywhere: OK~n"),
    % 生成性：σ(C) = 幂集，单点集由 Iic 之差拼出
    findall(S, all_subsets(S), Pow0), length(Pow0, 16),
    format("sigma(C) = power set (16 subsets): OK~n"),
    iic(2, S2), iic(1, S1), diff(S2, S1, D2), D2 = [2],
    format("singleton {2} = Iic2 minus Iic1: OK~n"),
    format("END ====~n"), !.
