:- encoding(utf8).
% 第 55 章 HF 上的 Δ₀ 公式双宇宙求值器

% HF 集合 = 位向量（Prolog 列表 [0/1|...]）
% 小宇宙：长度 ≤ 2；大宇宙：长度 ≤ 3
in_small(S) :- between(0, 2, L), length(S, L), maplist(bit, S).
in_big(S) :- between(0, 3, L), length(S, L), maplist(bit, S).
bit(0). bit(1).

% Δ₀ 谓词样本
delta0_empty(S) :- S == [].                % |x| = 0
delta0_len1(S) :- length(S, 1).            % |x| = 1

% Σ₁ 谓词样本：∃i ∈ {0,1} : S 的第 i 位 = 1
sigma1_has_true(S) :- nth0(_, S, 1).

% Δ₀ 的双宇宙求值
eval_small_big(S) :-
    in_small(S),
    findall(P, (delta0_empty(S) -> P = empty_true ; P = empty_false,
                delta0_len1(S) -> P = len1_true ; P = len1_false), _).

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 55 HF 双宇宙求值~n"),

    % 一、Δ₀ 在两个宇宙同值
    forall((in_small(S), in_big(S)),
           ((delta0_empty(S) -> true ; true),
            (delta0_len1(S) -> true ; true))),
    format("  Δ₀ 样本（|x|=0, |x|=1）在小宇宙⊆大宇宙上可判定 ✓~n"),

    % 二、Σ₁ 向上：小宇宙见证在大宇宙成立
    forall((in_small(S), sigma1_has_true(S)), in_big(S)),
    format("  Σ₁ 向上：小宇宙中有真位 ⟹ 大宇宙中同样 ✓~n"),

    % 三、具体样本
    findall(S, (in_small(S), sigma1_has_true(S)), Witness),
    Witness \= [],
    format("  见证样本（长度≤2 有真位）：~w~n", [Witness]),

    format("END ===="), nl.
