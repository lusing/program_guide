:- encoding(utf8).
% 第 12 章 可构造层级：def(U) 的受限公式检查器
%
% 有限传递 U（成员表）上，检查子集是否由受限公式定义：
% 原子 u∈a / u=a 的布尔组合。与 10 章的 sat 求值器同构。

% ---------- 一、论域：V₂ = {∅, {∅}} ----------
% 点 0 = ∅、点 1 = {∅}；u_member(U, A) = "U ∈ A"
u_member(0, 1).                  % 0 ∈ 1（{∅} 含 ∅）
% 0 ∈ ∅ 恒假（无事实）

% ---------- 二、原子与组合 ----------

% 原子谓词：对被测点 u 的真值
atom_val(mem(A), U, V) :- u_member(U, A), !, V = true.
atom_val(mem(_), _, false).
atom_val(eq(K), U, V) :- U =:= K, !, V = true.
atom_val(eq(_), _, false).

% 受限公式（布尔组合）
rf_val(fatom(A), U, V) :- atom_val(A, U, V).
rf_val(fnand(P, Q), U, V) :-
    rf_val(P, U, VP), rf_val(Q, U, VQ),
    nand_bool(VP, VQ, V).

nand_bool(true, _, false).
nand_bool(false, true, false).
nand_bool(false, false, true).

% ---------- 三、def 的成员：公式定义的子集 ----------

defined_subset(fatom(A), S) :- findall(U, (between(0, 1, U), rf_val(fatom(A), U, true)), S).
defined_subset(fnand(P, Q), S) :-
    findall(U, (between(0, 1, U), rf_val(fnand(P, Q), U, true)), S).

% ---------- main ----------

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 12 可构造层级：def(U)~n"),
    defined_subset(fatom(eq(0)), S0),
    format("  {u : u = 0} = ~w~n", [S0]),
    defined_subset(fatom(eq(1)), S1),
    format("  {u : u = 1} = ~w~n", [S1]),
    defined_subset(fatom(mem(1)), S2),
    format("  {u : u ∈ 1} = ~w（0 ∈ {∅}）~n", [S2]),
    defined_subset(fnand(fatom(mem(0)), fatom(mem(0))), S3),
    format("  ¬(u ∈ ∅) = ~w（恒真——全集 {0,1}）~n", [S3]),
    format("  单点 {0}、{1}、∅-补集与全集：布尔组合已覆盖 P(V₂)~n"),
    format("  的全部子集——有限层 def = P（习题 12.6）。~n"),
    format("  L 层级的官方形态：Isabelle Formula.thy 的 Lset/DPow。~n"),
    format("END ====~n").
