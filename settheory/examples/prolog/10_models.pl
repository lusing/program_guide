:- encoding(utf8).
% 第 10 章 模型：受限公式的可满足性检查器
%
% 深嵌入公式 + 有限结构求值（与 Julia 通道同构的 Prolog 版）。
% 验证：原子/联结词/受限量词的语义 + 绝对性的语义基线。

% ---------- 一、结构：域 0..3，成员表 ----------

member_of(X, 0) :- member(X, [1, 2]).
member_of(X, 1) :- member(X, [2]).
member_of(_, 2) :- fail.
member_of(X, 3) :- member(X, [0]).

% ---------- 二、公式求值 ----------
% env 是列表；x_i 的值 = env 的第 i 个（0 基）
env_lookup([V|_], 0, V).
env_lookup([_|E], I, V) :- I > 0, I1 is I - 1, env_lookup(E, I1, V).

% sat(F, Env)：受限公式的求值
sat(atom_in(I, J), Env) :-
    env_lookup(Env, I, X), env_lookup(Env, J, Y),
    member_of(X, Y).
sat(nand(P, Q), Env) :-
    \+ (sat(P, Env), sat(Q, Env)).
sat(rall(I, P), Env) :-
    env_lookup(Env, I, X),
    forall(member_of(U, X), sat(P, [U|Env])).
sat(rex(I, P), Env) :-
    env_lookup(Env, I, X),
    member_of(U, X),
    sat(P, [U|Env]).

% ---------- main ----------

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 10 模型：可满足性检查器~n"),
    (   sat(atom_in(1, 0), [0, 1]) -> format("  1 ∈ 0 成立 ✓（成员表 {1,2}）~n")
    ;   format("  （错误）~n") ),
    (   sat(nand(atom_in(1,0), atom_in(1,0)), [0, 1]) ->
        format("  ¬(1 ∈ 0) 成立（错误！1∈0 为真）~n")
    ;   format("  ¬(1 ∈ 0) 失败 ✓（Nand p p = ¬p，而 1∈0 成立）~n") ),
    (   sat(rall(0, nand(atom_in(0,1), atom_in(0,1))), [0]) ->
        format("  ∀u∈x₀ ¬(u∈x₀) 成立（错误！）~n")
    ;   format("  ∀u∈x₀ ¬(u∈x₀) 失败 ✓（u=1 ∈ x₀={1,2} 破坏全称）~n") ),
    (   sat(rex(0, atom_in(0, 1)), [0]) ->
        format("  ∃u∈x₀ (u ∈ x₀) 成立 ✓（u=1：1∈0）~n")
    ;   format("  （错误）~n") ),
    format("  受限量词只跑成员表——绝对性的引擎侧（引理 10.1）。~n"),
    format("END ====~n").
