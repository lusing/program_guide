:- encoding(utf8).
% 第 14 章 Lévy 层级：量词链的层级推理
%
% 量词链（如 [ex, all, ex]）→ Σ₃；封闭规则的运算子。

% ---------- 一、交替深度 ----------

alternate_depth([_], 1).
alternate_depth([Q1, Q2 | Rest], N) :-
    Q1 \= Q2,
    alternate_depth([Q2 | Rest], N1),
    N is N1 + 1.
alternate_depth([Q, Q | Rest], N) :-
    alternate_depth([Q | Rest], N).

level([], delta0).
level([ex | Qs], sigma(N)) :- alternate_depth([ex | Qs], N).
level([all | Qs], pi(N)) :- alternate_depth([all | Qs], N).

% ---------- 二、对偶与提升 ----------

dual(delta0, delta0).
dual(sigma(N), pi(N)).
dual(pi(N), sigma(N)).

ex_over(delta0, sigma(1)).
ex_over(sigma(N), sigma(N)).
ex_over(pi(N), sigma(N1)) :- N1 is N + 1.

all_over(L, A) :- dual(L, D), ex_over(D, E), dual(E, A).

% ---------- main ----------

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 14 Lévy 层级：量词链推理~n"),
    level([ex, all, ex], L1), format("  ∃∀∃ → ~w~n", [L1]),
    level([all, ex], L2), format("  ∀∃ → ~w~n", [L2]),
    level([ex, ex], L3), format("  ∃∃ → ~w（同型吸收）~n", [L3]),
    level([], L4), format("  无量词 → ~w~n", [L4]),
    dual(sigma(3), D1), dual(D1, D2), format("  dual∘dual(Σ₃) = ~w~n", [D2]),
    ex_over(pi(2), E1), format("  ∃ over Π₂ → ~w~n", [E1]),
    all_over(sigma(2), A1), format("  ∀ over Σ₂ → ~w~n", [A1]),
    all_over(pi(5), A2), format("  ∀ over Π₅ → ~w（吸收）~n", [A2]),
    format("END ====~n").
